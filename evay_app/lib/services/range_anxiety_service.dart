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
    
    // Total estimated route energy including HVAC climate factor and Sri Lanka elevation penalty
    final routeEnergyDemandKwh = (routeDistanceKm * ratedEfficiencyKwhPerKm * climateFactor) +
        smartRoute.elevationEnergyPenaltyKwh;
    final estimatedRangeKm = availableKwh * efficiencyKmPerKwh;

    final recommendedStop =
        smartRoute.chargingStops.isEmpty
            ? null
            : smartRoute.chargingStops.first;

    // Additional energy injected across all planned charging stops (multi-hop corridor)
    double totalInjectedKwh = 0.0;
    for (final stop in smartRoute.chargingStops) {
      totalInjectedKwh += stop.energyAddedKwh;
    }
    final double totalEffectiveKwh = availableKwh + totalInjectedKwh;

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
    final double chargerFactor = _averageChargerFactor(smartRoute.chargingStops);
    final int nStations = smartRoute.chargingStops.length;
    // Calculate required number of charging stops based on trip energy demand
    final int nRequired = math.max(0, (routeEnergyDemandKwh / math.max(1.0, availableKwh * 0.75)).ceil() - 1);
    final double stationRatio = nRequired == 0
        ? 1.0
        : math.min(1.0, nStations / nRequired);
    final double mc = (stationRatio * chargerFactor).clamp(0.0, 1.0);

    // Composite RAI Formula (Eq. 6)
    final double compositeRai = (wb * mb) + (wr * mr) + (wc * mc);
    final int score = (compositeRai * 100).round().clamp(0, 100);

    // Safety margin buffer
    final safetyMargin = smartRoute.chargingStops.isEmpty ? 1.25 : 1.15;
    final requiredDistanceKm = routeDistanceKm * safetyMargin;
    final bufferKm = effectiveRangeKm - requiredDistanceKm;

    final (label, summary) = _statusFor(
      score: score,
      bufferKm: bufferKm,
      stops: smartRoute.chargingStops,
      elevationGainM: smartRoute.totalElevationGainM,
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
      chargingStops: smartRoute.chargingStops,
      totalElevationGainM: smartRoute.totalElevationGainM,
      elevationEnergyPenaltyKwh: smartRoute.elevationEnergyPenaltyKwh,
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

  double _averageChargerFactor(List<ChargingStop> stops) {
    if (stops.isEmpty) return 0.55;

    double totalFactor = 0.0;
    for (final stop in stops) {
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

      final factor = ((availabilityScore * 0.50) +
              (detourScore * 0.30) +
              (powerScore * 0.20))
          .clamp(0.55, 1.0);
      totalFactor += factor;
    }

    return totalFactor / stops.length;
  }

  (String, String) _statusFor({
    required int score,
    required double bufferKm,
    required List<ChargingStop> stops,
    required double elevationGainM,
  }) {
    final elevNote = elevationGainM > 300
        ? ' Includes +${elevationGainM.toStringAsFixed(0)}m elevation climb.'
        : '';

    if (score >= 70) {
      if (stops.isEmpty) {
        return (
          'Safe trip',
          'You can complete this route comfortably on your current charge.$elevNote',
        );
      } else if (stops.length == 1) {
        return (
          'Safe trip (1 Stop)',
          'Route is fully secured with 1 planned charging stop (~${stops.first.chargingTimeMinutes.toStringAsFixed(0)} min charge).$elevNote',
        );
      } else {
        return (
          'Safe trip (${stops.length} Stops)',
          'Corridor planned with ${stops.length} consecutive charging stops to prevent battery depletion.$elevNote',
        );
      }
    }

    if (score >= 40) {
      if (stops.isEmpty) {
        return (
          'Charge recommended',
          'Battery margin is tight for this distance.$elevNote A charging stop along the corridor is advised.',
        );
      } else {
        return (
          'Charge recommended',
          '${stops.length} charging stops identified. Monitor battery levels, especially on steep ascents.$elevNote',
        );
      }
    }

    return (
      'High risk',
      stops.isEmpty
          ? 'Route distance exceeds current range.$elevNote No accessible corridor chargers found before battery depletion.'
          : 'High risk of battery exhaustion before reaching planned stops.$elevNote Charge vehicle before starting this trip.',
    );
  }
}
