import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/range_anxiety.dart';
import '../models/smart_route.dart';

class RangeAnxietyService {
  const RangeAnxietyService();

  RangeAnxietyReport buildReport({
    required SmartRoute smartRoute,
    required double batteryCapacityKwh,
    required double batteryPercent,
    required double efficiencyKmPerKwh,
  }) {
    final routeDistanceKm = _routeDistanceKm(smartRoute.routePoints);
    final normalizedBatteryPercent = batteryPercent.clamp(0, 100).toDouble();
    final availableKwh = batteryCapacityKwh * (normalizedBatteryPercent / 100);
    final estimatedRangeKm = availableKwh * efficiencyKmPerKwh;
    final recommendedStop =
        smartRoute.chargingStops.isEmpty
            ? null
            : smartRoute.chargingStops.first;

    final chargerFactor = _chargerFactor(recommendedStop);
    final safetyMargin = recommendedStop == null ? 1.25 : 1.15;
    final requiredDistanceKm = routeDistanceKm * safetyMargin;
    final bufferKm = estimatedRangeKm - requiredDistanceKm;
    final baseConfidence =
        requiredDistanceKm <= 0 ? 0.0 : estimatedRangeKm / requiredDistanceKm;

    final rawScore = (baseConfidence * chargerFactor * 100).round();
    final score = rawScore.clamp(0, 100);

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

    return totalMeters / 1000;
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
    final detourScore = (1 - (stop.distanceFromRouteKm / 20)).clamp(0.55, 1.0);
    final powerScore =
        charger.powerKw == null
            ? 0.75
            : (charger.powerKw! / 120).clamp(0.55, 1.0);

    return ((availabilityScore * 0.5) +
            (detourScore * 0.3) +
            (powerScore * 0.2))
        .clamp(0.55, 1.0);
  }

  (String, String) _statusFor({
    required int score,
    required double bufferKm,
    required ChargingStop? stop,
  }) {
    if (score >= 80) {
      return (
        'Safe trip',
        bufferKm >= 0
            ? 'You should be able to complete this route without much stress.'
            : 'A charger is available on route if you want extra confidence.',
      );
    }

    if (score >= 50) {
      return (
        'Charge recommended',
        stop == null
            ? 'Your battery is usable, but this trip would feel safer with a charging stop.'
            : 'You can likely make the trip, but planning a stop will reduce risk.',
      );
    }

    return (
      'High risk',
      stop == null
          ? 'This trip looks risky with the current battery and no clear charger backup.'
          : 'Your current battery looks tight for this route. Plan to charge before or during the trip.',
    );
  }
}
