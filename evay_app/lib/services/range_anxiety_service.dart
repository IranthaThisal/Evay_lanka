import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/range_anxiety.dart';
import '../models/smart_route.dart';

class RangeAnxietyService {
  const RangeAnxietyService();

  // Climate coefficient for Sri Lanka tropical ambient (28-34C + A/C load)
  static const double defaultClimateFactor = 1.05;

  // Calibrated weights satisfying wb + wr + wc = 1.0 (Eq. 6)
  static const double wb = 0.50; // Battery margin weight
  static const double wr = 0.30; // Route feasibility weight
  static const double wc = 0.20; // Charger accessibility weight

  RangeAnxietyReport buildReport({
    required SmartRoute smartRoute,
    required double batteryCapacityKwh,
    required double batteryPercent,
    required double efficiencyKmPerKwh,
    double climateFactor = defaultClimateFactor,
  }) {
    final routeDistanceKm = _routeDistanceKm(smartRoute.routePoints);
    final normalizedBatteryPercent = batteryPercent.clamp(0.0, 100.0).toDouble();
    final availableKwh = batteryCapacityKwh * (normalizedBatteryPercent / 100.0);
    final ratedEfficiencyKwhPerKm = efficiencyKmPerKwh <= 0 ? 0.18 : 1.0 / efficiencyKmPerKwh;
    
    // Total estimated route energy with climate factor
    final routeEnergyDemandKwh = routeDistanceKm * ratedEfficiencyKwhPerKm * climateFactor;
    final estimatedRangeKm = availableKwh * efficiencyKmPerKwh;

    final recommendedStop =
        smartRoute.chargingStops.isEmpty
            ? null
            : smartRoute.chargingStops.first;

    // Additional energy injected if an optimal charging stop is included
    final double injectedKwh = recommendedStop == null
        ? 0.0
        : math.min(
            (batteryCapacityKwh * 0.80) - math.max(0.0, availableKwh - (recommendedStop.distanceFromOriginKm * ratedEfficiencyKwhPerKm)),
            batteryCapacityKwh * 0.70,
          );
    final double totalEffectiveKwh = availableKwh + injectedKwh;

    // Sub-score 1: Battery Margin Score mb = max(0, (SoCavail - Eroute)/SoCavail)
    final double mb = totalEffectiveKwh <= 0
        ? 0.0
        : math.max(0.0, (totalEffectiveKwh - routeEnergyDemandKwh) / totalEffectiveKwh);

    // Sub-score 2: Route Feasibility Score mr = min(1, Rrem / D)
    final double effectiveRangeKm = totalEffectiveKwh * efficiencyKmPerKwh;
    final double mr = routeDistanceKm <= 0
        ? 1.0
        : math.min(1.0, effectiveRangeKm / routeDistanceKm);

    // Sub-score 3: Charger Accessibility Score mc = min(1, nstations / nrequired) * chargerFactor
    final double chargerFactor = _chargerFactor(recommendedStop);
    final int nStations = smartRoute.chargingStops.length;
    final int nRequired = routeEnergyDemandKwh > availableKwh ? 1 : 0;
    final double stationRatio = nRequired == 0
        ? 1.0
        : math.min(1.0, nStations / nRequired);
    final double mc = (stationRatio * chargerFactor).clamp(0.0, 1.0);

    // Composite RAI Formula (Eq. 6)
    final double compositeRai = (wb * mb) + (wr * mr) + (wc * mc);
    final int score = (compositeRai * 100).round().clamp(0, 100);

    // Safety margin buffer
    final safetyMargin = recommendedStop == null ? 1.25 : 1.15;
    final requiredDistanceKm = routeDistanceKm * safetyMargin;
    final bufferKm = estimatedRangeKm - requiredDistanceKm;

    final (label, summary) = _statusFor(
      score: score,
      bufferKm: bufferKm,
      stop: recommendedStop,
    );

    return RangeAnxietyReport(
      score: score,
      label: label,
      summary: summary,
      estimatedRangeKm: estimatedRangeKm,
      routeDistanceKm: routeDistanceKm,
      requiredDistanceKm: requiredDistanceKm,
      bufferKm: bufferKm,
      chargerFactor: chargerFactor,
      safetyMargin: safetyMargin,
      recommendedStop: recommendedStop,
    );
  }

  double _routeDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0;

    var totalMeters = 0.0;
    for (var i = 1; i < points.length; i++) {
      totalMeters += Geolocator.distanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }

    return totalMeters / 1000.0;
  }

  double _chargerFactor(ChargingStop? stop) {
    if (stop == null) return 0.55;

    final charger = stop.charger;
    final availabilityScore = switch (charger.slots) {
      <= 0 => 0.45,
      1 => 0.72,
      2 => 0.85,
      _ => 1.0,
    };
    final detourScore = (1.0 - (stop.distanceFromRouteKm / 20.0)).clamp(0.55, 1.0);
    final powerScore = charger.powerKw == null
        ? 0.75
        : (charger.powerKw! / 120.0).clamp(0.55, 1.0);

    return ((availabilityScore * 0.50) +
            (detourScore * 0.30) +
            (powerScore * 0.20))
        .clamp(0.55, 1.0);
  }

  // Exact 70 / 40 thresholds specified in Section IV and Abstract
  (String, String) _statusFor({
    required int score,
    required double bufferKm,
    required ChargingStop? stop,
  }) {
    if (score >= 70) {
      return (
        'Safe trip',
        bufferKm >= 0
            ? 'You should be able to complete this route without range anxiety.'
            : 'Charging is available along the corridor to ensure high confidence.',
      );
    }

    if (score >= 40) {
      return (
        'Charge recommended',
        stop == null
            ? 'Your battery is usable, but this trip would feel safer with a planned charging stop.'
            : 'A charging stop has been planned to keep battery levels within a safe buffer.',
      );
    }

    return (
      'High risk',
      stop == null
          ? 'This trip is at high risk of depletion with no accessible charging backup.'
          : 'Your current battery is critically tight for this route. Charge before departure.',
    );
  }
}
