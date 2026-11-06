import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/charger.dart';
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
    EvTripConditions conditions = const EvTripConditions(),
    double climateFactor = defaultClimateFactor,
    List<Charger> availableChargers = const [],
  }) {
    final routeDistanceKm = _routeDistanceKm(smartRoute.routePoints);
    final normalizedBatteryPercent = batteryPercent.clamp(0.0, 100.0).toDouble();
    final availableKwh = batteryCapacityKwh * (normalizedBatteryPercent / 100.0);
    final ratedEfficiencyKwhPerKm = efficiencyKmPerKwh <= 0 ? 0.18 : 1.0 / efficiencyKmPerKwh;

    // Environmental consumption factor: tropical climate + driver mode + rain + payload
    final totalEnvironmentalFactor = climateFactor * conditions.compositeEnvironmentalMultiplier;
    final effectiveEfficiencyKwhPerKm = ratedEfficiencyKwhPerKm * totalEnvironmentalFactor;
    
    // Total estimated route energy including HVAC, driver/payload, weather, and topography
    final routeEnergyDemandKwh = (routeDistanceKm * effectiveEfficiencyKwhPerKm) +
        smartRoute.elevationEnergyPenaltyKwh;
    final estimatedRangeKm = availableKwh / effectiveEfficiencyKwhPerKm;

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
    final double effectiveRangeKm = totalEffectiveKwh / effectiveEfficiencyKwhPerKm;
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

    // Dynamic Safety Margin: Replaces static 1.15-1.25 multiplier with responsive environmental formula
    final dynamicSafetyMargin = computeDynamicSafetyMargin(
      conditions: conditions,
      hasCorridorChargers: smartRoute.chargingStops.isNotEmpty,
      elevationGainM: smartRoute.totalElevationGainM,
    );

    // Composite RAI Formula (Eq. 6)
    final double compositeRai = (wb * mb) + (wr * mr) + (wc * mc);
    final int score = (compositeRai * 100).round().clamp(0, 100);

    final requiredDistanceKm = routeDistanceKm * dynamicSafetyMargin;
    final bufferKm = effectiveRangeKm - requiredDistanceKm;

    // Round-Trip & Point of No Return calculation
    final pointOfNoReturn = computePointOfNoReturn(
      smartRoute: smartRoute,
      batteryCapacityKwh: batteryCapacityKwh,
      availableKwh: availableKwh,
      effectiveEfficiencyKwhPerKm: effectiveEfficiencyKwhPerKm,
      safetyMargin: dynamicSafetyMargin,
      availableChargers: availableChargers,
    );

    final (label, summary) = _statusFor(
      score: score,
      bufferKm: bufferKm,
      stops: smartRoute.chargingStops,
      elevationGainM: smartRoute.totalElevationGainM,
      conditions: conditions,
      pnr: pointOfNoReturn,
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
      safetyMargin: dynamicSafetyMargin,
      recommendedStop: recommendedStop,
      chargingStops: smartRoute.chargingStops,
      totalElevationGainM: smartRoute.totalElevationGainM,
      elevationEnergyPenaltyKwh: smartRoute.elevationEnergyPenaltyKwh,
      conditions: conditions,
      pointOfNoReturn: pointOfNoReturn,
    );
  }

  /// Dynamically computes safety multiplier based on environment, weather, payload, and relief.
  /// Replaces the legacy fixed 1.15 - 1.25 constant.
  double computeDynamicSafetyMargin({
    required EvTripConditions conditions,
    required bool hasCorridorChargers,
    required double elevationGainM,
  }) {
    double margin = 1.06; // Baseline 6% emergency reserve

    // 1. Corridor charger backup reserve
    if (!hasCorridorChargers) {
      margin += 0.12; // Extra 12% buffer if corridor has no backup chargers
    } else {
      margin += 0.04;
    }

    // 2. Weather / Rain factor (wet tarmac rolling resistance & braking safety)
    margin += switch (conditions.weather) {
      WeatherCondition.dry => 0.00,
      WeatherCondition.lightRain => 0.03,
      WeatherCondition.heavyMonsoon => 0.08,
    };

    // 3. Driving Mode factor
    margin += switch (conditions.drivingMode) {
      DrivingMode.eco => 0.00,
      DrivingMode.normal => 0.02,
      DrivingMode.sport => 0.05,
    };

    // 4. Payload factor (heavy passenger/cargo weight requires larger braking/acceleration margin)
    if (conditions.addedPayloadMassKg > 150.0) {
      margin += 0.03;
    }

    // 5. Elevation climb factor (steep hill country ascents like Kandy/Nuwara Eliya)
    if (elevationGainM > 400.0) {
      margin += 0.04;
    }

    return margin; // Dynamically spans ~1.10x up to ~1.38x
  }

  /// Computes Point of No Return (PNR) and whether driver can safely return
  /// to the last known reliable DC charger if destination charging is unavailable.
  PointOfNoReturnInfo? computePointOfNoReturn({
    required SmartRoute smartRoute,
    required double batteryCapacityKwh,
    required double availableKwh,
    required double effectiveEfficiencyKwhPerKm,
    required double safetyMargin,
    required List<Charger> availableChargers,
  }) {
    if (smartRoute.routePoints.isEmpty) return null;

    final destination = smartRoute.destination;

    // Identify last reliable DC charger prior to destination
    Charger? lastReliableCharger;
    double distToLastChargerKm = 0.0;

    if (smartRoute.chargingStops.isNotEmpty) {
      final lastStop = smartRoute.chargingStops.last;
      lastReliableCharger = lastStop.charger;
      distToLastChargerKm = Geolocator.distanceBetween(
            destination.latitude,
            destination.longitude,
            lastReliableCharger.lat,
            lastReliableCharger.lng,
          ) /
          1000.0;
    } else if (availableChargers.isNotEmpty) {
      // Find closest charger along the route behind or near destination
      double minDistance = double.infinity;
      for (final charger in availableChargers) {
        final d = Geolocator.distanceBetween(
              destination.latitude,
              destination.longitude,
              charger.lat,
              charger.lng,
            ) /
            1000.0;
        if (d < minDistance) {
          minDistance = d;
          lastReliableCharger = charger;
        }
      }
      distToLastChargerKm = minDistance;
    }

    if (lastReliableCharger == null) return null;

    // Energy needed to return from destination to last reliable charger
    final energyNeededToReturnKwh = distToLastChargerKm * effectiveEfficiencyKwhPerKm * safetyMargin;

    // Estimated battery remaining upon arriving at destination
    final totalTripDistanceKm = _routeDistanceKm(smartRoute.routePoints);
    final tripEnergyUsedKwh = (totalTripDistanceKm * effectiveEfficiencyKwhPerKm) +
        smartRoute.elevationEnergyPenaltyKwh;

    double arrivalKwhAtDest = availableKwh;
    for (final stop in smartRoute.chargingStops) {
      arrivalKwhAtDest += stop.energyAddedKwh;
    }
    arrivalKwhAtDest = math.max(0.0, arrivalKwhAtDest - tripEnergyUsedKwh);

    // Remaining battery after returning from destination to last charger
    final returnBatteryRemainingKwh = arrivalKwhAtDest - energyNeededToReturnKwh;
    final returnBatteryPercent = (returnBatteryRemainingKwh / batteryCapacityKwh) * 100.0;

    // Determine return confidence classification
    final ReturnConfidence confidence;
    final String warning;

    if (returnBatteryPercent >= 12.0) {
      confidence = ReturnConfidence.safeReturn;
      warning = 'Safe turnaround guaranteed. You can safely return to ${lastReliableCharger.name} '
          '(${distToLastChargerKm.toStringAsFixed(1)} km back) with ${returnBatteryPercent.toStringAsFixed(0)}% battery remaining.';
    } else if (returnBatteryPercent >= 0.0) {
      confidence = ReturnConfidence.destinationDependent;
      warning = 'Caution: Returning to ${lastReliableCharger.name} will deplete battery to ${returnBatteryPercent.toStringAsFixed(0)}%. '
          'Destination charging is strongly advised.';
    } else {
      confidence = ReturnConfidence.pointOfNoReturnExceeded;
      final arrivalPct = (arrivalKwhAtDest / batteryCapacityKwh) * 100.0;
      warning = '⚠️ Point of No Return exceeded! Battery at destination (${arrivalPct.toStringAsFixed(0)}%) '
          'cannot reach ${lastReliableCharger.name} (${distToLastChargerKm.toStringAsFixed(1)} km back). Destination charging is mandatory!';
    }

    // Calculate Point of No Return (distance from origin where vehicle commits)
    final pnrDistanceKm = math.max(
      0.0,
      totalTripDistanceKm - (distToLastChargerKm * (arrivalKwhAtDest > 0 ? 0.85 : 0.5)),
    );

    return PointOfNoReturnInfo(
      lastReliableCharger: lastReliableCharger,
      distanceToLastChargerKm: distToLastChargerKm,
      energyNeededToReturnKwh: energyNeededToReturnKwh,
      returnBatteryPercentRemaining: returnBatteryPercent,
      confidence: confidence,
      pointOfNoReturnKmFromOrigin: pnrDistanceKm,
      warningMessage: warning,
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
    required EvTripConditions conditions,
    required PointOfNoReturnInfo? pnr,
  }) {
    final conditionNotes = <String>[];
    if (conditions.weather != WeatherCondition.dry) {
      conditionNotes.add(conditions.weather.label);
    }
    if (conditions.drivingMode != DrivingMode.normal) {
      conditionNotes.add('${conditions.drivingMode.label} Mode');
    }
    if (conditions.addedPayloadMassKg > 0) {
      conditionNotes.add('+${conditions.addedPayloadMassKg.toStringAsFixed(0)}kg payload');
    }
    if (elevationGainM > 300) {
      conditionNotes.add('+${elevationGainM.toStringAsFixed(0)}m climb');
    }

    final envSuffix = conditionNotes.isNotEmpty ? ' [${conditionNotes.join(', ')}]' : '';

    if (score >= 70) {
      if (stops.isEmpty) {
        return (
          'Safe trip',
          'You can complete this route comfortably on your current charge.$envSuffix',
        );
      } else if (stops.length == 1) {
        return (
          'Safe trip (1 Stop)',
          'Route is fully secured with 1 planned charging stop (~${stops.first.chargingTimeMinutes.toStringAsFixed(0)} min charge).$envSuffix',
        );
      } else {
        return (
          'Safe trip (${stops.length} Stops)',
          'Corridor planned with ${stops.length} consecutive charging stops to prevent battery depletion.$envSuffix',
        );
      }
    }

    if (score >= 40) {
      if (stops.isEmpty) {
        return (
          'Charge recommended',
          'Battery margin is tight for this distance.$envSuffix A charging stop along the corridor is advised.',
        );
      } else {
        return (
          'Charge recommended',
          '${stops.length} charging stops identified. Monitor battery levels closely.$envSuffix',
        );
      }
    }

    return (
      'High risk',
      stops.isEmpty
          ? 'Route distance exceeds current range.$envSuffix No accessible corridor chargers found before battery depletion.'
          : 'High risk of battery exhaustion before reaching planned stops.$envSuffix Charge vehicle before departure.',
    );
  }
}
