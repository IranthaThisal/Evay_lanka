import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/charger.dart';
import '../models/range_anxiety.dart';
import '../models/smart_route.dart';
import 'route_service.dart';
import 'spatial/spatial_charger_index.dart';
import 'topography/elevation_model.dart';

export 'spatial/spatial_charger_index.dart';
export 'topography/elevation_model.dart';

/// Smart Route Service:
/// Supports Multi-Stop Corridor Planning, Sri Lanka Topography & Elevation Modeling,
/// Spatial Bounding-Box Indexing, Connector-Type Filtering, Round-Trip Return Simulation,
/// and Crowdsourced Station Reliability ("LankaScore").
class SmartRouteService {
  SmartRouteService({
    RouteService? routeService,
    SriLankaElevationModel? elevationModel,
  })  : _routeService = routeService ?? RouteService(),
        _elevationModel = elevationModel ?? const SriLankaElevationModel();

  static const double defaultMaxDistanceFromRouteKm = 15.0;
  static const int defaultMaxStops = 6;
  static const double defaultClimateFactor = 1.05;

  // Normalized cost function weights (alpha + beta + gamma = 1.0)
  static const double alpha = 0.35; // Normalized detour weight
  static const double beta = 0.45;  // Normalized power & energy weight
  static const double gamma = 0.20; // Normalized slot/queue weight

  /// Validates whether a generated SmartRoute meets all strict safety criteria
  /// before active turn-by-turn navigation guidance can be initiated.
  /// Rejects routes that are marked infeasible, have reserve violations, or
  /// have an arrival SoC below the mandatory safety reserve floor (default 10%).
  static bool validateNavigationReadiness(
    SmartRoute route, {
    double minimumReserveFloorPercent = 10.0,
  }) {
    if (!route.isFeasible || route.hasReserveViolation) return false;
    if (route.arrivalBatteryPercent < minimumReserveFloorPercent) return false;
    return true;
  }

  /// Checks whether a charger is compatible with the vehicle's preferred connector types.
  static bool isChargerConnectorCompatible(
    Charger charger,
    Set<String> preferredConnectors,
  ) {
    if (preferredConnectors.isEmpty || charger.connectorTypes.isEmpty) {
      return true;
    }
    final normalizedPreferred = preferredConnectors
        .map((c) => c.trim().toUpperCase())
        .where((c) => c.isNotEmpty)
        .toSet();
    if (normalizedPreferred.isEmpty) return true;

    for (final raw in charger.connectorTypes) {
      final upper = raw.trim().toUpperCase();
      if (normalizedPreferred.contains(upper)) return true;
      for (final pref in normalizedPreferred) {
        if (upper.contains(pref) || pref.contains(upper)) return true;
      }
    }
    return false;
  }

  final RouteService _routeService;
  final SriLankaElevationModel _elevationModel;

  Future<SmartRoute> planFastestRouteWithChargers({
    required LatLng origin,
    required LatLng destination,
    required List<Charger> chargers,
    double maxDistanceFromRouteKm = defaultMaxDistanceFromRouteKm,
    int maxStops = defaultMaxStops,
    double? batteryCapacityKwh,
    double? batteryPercent,
    double? efficiencyKmPerKwh,
    EvTripConditions conditions = const EvTripConditions(),
    Map<String, double> reliabilityScores = const {},
    double climateFactor = defaultClimateFactor,
    double reserveThresholdPercent = 18.0,
    double targetChargePercent = 80.0,
    Set<String> preferredConnectors = const {},
    bool includeReturnTrip = false,
  }) async {
    final route = await _routeService.fetchRoute(
      origin: origin,
      destination: destination,
    );

    final basePoints = route.points;
    final List<LatLng> points;
    if (includeReturnTrip && basePoints.length > 1) {
      points = [
        ...basePoints,
        ...basePoints.reversed.skip(1),
      ];
    } else {
      points = basePoints;
    }

    final n = points.length;
    final cumulativeDistances = List<double>.filled(n, 0.0);
    final elevations = List<double>.filled(n, 0.0);

    if (n > 0) {
      elevations[0] = _elevationModel.getElevation(points[0]);
      for (var i = 1; i < n; i++) {
        cumulativeDistances[i] =
            cumulativeDistances[i - 1] + _distanceBetween(points[i - 1], points[i]);
        elevations[i] = _elevationModel.getElevation(points[i]);
      }
    }

    final (gainM, lossM) = _elevationModel.computeGainAndLoss(
      points,
      precomputedElevations: elevations,
    );
    final elevationEnergyPenaltyKwh = _elevationModel.computeElevationEnergyDelta(
      deltaElevationM: gainM - (lossM * 0.70),
      vehicleMassKg: conditions.totalVehicleMassKg,
    );

    final stops = recommendChargingStops(
      origin: origin,
      routePoints: points,
      routeBounds: route.bounds,
      chargers: chargers,
      maxDistanceFromRouteKm: maxDistanceFromRouteKm,
      maxStops: maxStops,
      batteryCapacityKwh: batteryCapacityKwh,
      batteryPercent: batteryPercent,
      efficiencyKmPerKwh: efficiencyKmPerKwh,
      conditions: conditions,
      reliabilityScores: reliabilityScores,
      climateFactor: climateFactor,
      reserveThresholdPercent: reserveThresholdPercent,
      targetChargePercent: targetChargePercent,
      preferredConnectors: preferredConnectors,
      precomputedDistances: cumulativeDistances,
      precomputedElevations: elevations,
    );

    double totalChargingTime = 0.0;
    double totalEnergyInjectedKwh = 0.0;
    for (final stop in stops) {
      totalChargingTime += stop.chargingTimeMinutes;
      totalEnergyInjectedKwh += stop.energyAddedKwh;
    }

    final capacity = batteryCapacityKwh ?? 55.0;
    final ratedEfficiency = (efficiencyKmPerKwh != null && efficiencyKmPerKwh > 0) ? (1.0 / efficiencyKmPerKwh) : 0.18;
    final effectiveRate = ratedEfficiency * climateFactor * conditions.compositeEnvironmentalMultiplier;
    final totalTripDist = cumulativeDistances.isEmpty ? 0.0 : cumulativeDistances.last;
    final totalTripDemand = (totalTripDist * effectiveRate) + elevationEnergyPenaltyKwh;
    final startKwh = capacity * ((batteryPercent ?? 70.0).clamp(5.0, 100.0) / 100.0);
    final finalKwh = startKwh + totalEnergyInjectedKwh - totalTripDemand;
    final arrivalSocPercent = (finalKwh / capacity) * 100.0;
    final hasReserveViolation = arrivalSocPercent < reserveThresholdPercent;
    final isFeasible = !hasReserveViolation;

    final distanceLabel = includeReturnTrip
        ? '${totalTripDist.toStringAsFixed(1)} km (Round Trip)'
        : route.distanceText;
    final durationLabel = includeReturnTrip
        ? '${route.durationText} × 2'
        : route.durationText;

    return SmartRoute(
      origin: origin,
      destination: destination,
      routePoints: points,
      bounds: route.bounds,
      distanceText: distanceLabel,
      durationText: durationLabel,
      chargingStops: stops,
      totalDistanceKm: totalTripDist,
      totalElevationGainM: gainM,
      totalElevationLossM: lossM,
      arrivalBatteryPercent: arrivalSocPercent,
      totalChargingTimeMinutes: totalChargingTime,
      totalEnergyConsumedKwh: totalTripDemand,
      elevationEnergyPenaltyKwh: elevationEnergyPenaltyKwh,
      isFeasible: isFeasible,
      hasReserveViolation: hasReserveViolation,
      includeReturnTrip: includeReturnTrip,
    );
  }

  /// Multi-Stop Journey Corridor Planner:
  /// Sequentially tracks EV State of Charge (SoC) along route waypoints.
  /// Automatically inserts 1st, 2nd, and 3rd charging stops when SoC approaches 15-20%.
  List<ChargingStop> recommendChargingStops({
    required LatLng origin,
    required List<LatLng> routePoints,
    required List<Charger> chargers,
    LatLngBounds? routeBounds,
    double maxDistanceFromRouteKm = defaultMaxDistanceFromRouteKm,
    int maxStops = defaultMaxStops,
    double? batteryCapacityKwh,
    double? batteryPercent,
    double? efficiencyKmPerKwh,
    EvTripConditions conditions = const EvTripConditions(),
    Map<String, double> reliabilityScores = const {},
    double climateFactor = defaultClimateFactor,
    double reserveThresholdPercent = 18.0,
    double targetChargePercent = 80.0,
    Set<String> preferredConnectors = const {},
    List<double>? precomputedDistances,
    List<double>? precomputedElevations,
  }) {
    if (routePoints.isEmpty || chargers.isEmpty) return const [];

    // Filter by vehicle connector compatibility if specified (fallback to all if none match)
    final compatibleChargers = preferredConnectors.isEmpty
        ? chargers
        : chargers
            .where((c) => isChargerConnectorCompatible(c, preferredConnectors))
            .toList(growable: false);
    final pool = compatibleChargers.isNotEmpty ? compatibleChargers : chargers;

    // Step 1: Spatial Bounding-Box Pre-filtering
    final effectiveBounds = routeBounds ?? _calculateBounds(routePoints);
    final corridorChargers = SpatialChargerIndex.filterByRouteEnvelope(
      chargers: pool,
      bounds: effectiveBounds,
      marginKm: maxDistanceFromRouteKm,
    );

    if (corridorChargers.isEmpty) return const [];

    // Step 2: Build O(1) Spatial Hash Grid Index for corridor
    final spatialIndex = SpatialChargerIndex(chargers: corridorChargers);

    // EV Specifications
    final capacity = batteryCapacityKwh ?? 55.0; // Default ~55 kWh battery
    final ratedEfficiencyKwhPerKm =
        (efficiencyKmPerKwh != null && efficiencyKmPerKwh > 0)
            ? (1.0 / efficiencyKmPerKwh)
            : 0.18; // Default ~18 kWh/100km

    // Environmental consumption factor: tropical climate + driver mode + rain + payload
    final totalEnvironmentalFactor =
        climateFactor * conditions.compositeEnvironmentalMultiplier;
    final effectiveRateKwhPerKm =
        ratedEfficiencyKwhPerKm * totalEnvironmentalFactor;
    final totalMassKg = conditions.totalVehicleMassKg;

    double currentSocKwh =
        capacity * ((batteryPercent ?? 70.0).clamp(5.0, 100.0) / 100.0);
    double currentSocPercent = (currentSocKwh / capacity) * 100.0;
    final reserveFloorKwh = capacity * (reserveThresholdPercent / 100.0);

    final stops = <ChargingStop>[];
    final visitedChargerIds = <String>{};

    // Reuse pre-calculated cumulative waypoint distances and elevations if available
    final n = routePoints.length;
    final List<double> cumulativeDistances;
    final List<double> elevations;

    if (precomputedDistances != null &&
        precomputedElevations != null &&
        precomputedDistances.length == n &&
        precomputedElevations.length == n) {
      cumulativeDistances = precomputedDistances;
      elevations = precomputedElevations;
    } else {
      cumulativeDistances = List<double>.filled(n, 0.0);
      elevations = List<double>.filled(n, 0.0);
      elevations[0] = _elevationModel.getElevation(routePoints[0]);
      for (var i = 1; i < n; i++) {
        final segKm = _distanceBetween(routePoints[i - 1], routePoints[i]);
        cumulativeDistances[i] = cumulativeDistances[i - 1] + segKm;
        elevations[i] = _elevationModel.getElevation(routePoints[i]);
      }
    }

    final totalRouteDistanceKm = cumulativeDistances.last;
    int lastStopWaypointIndex = 0;

    // Step 3: Multi-Hop Dynamic State of Charge Simulation along Waypoints
    for (var i = 1; i < n; i++) {
      final segDistanceKm = cumulativeDistances[i] - cumulativeDistances[i - 1];
      final deltaElevationM = elevations[i] - elevations[i - 1];

      // Base energy consumption (environmental scaled) + Sri Lanka topography energy factor
      final baseEnergyKwh = segDistanceKm * effectiveRateKwhPerKm;
      final elevationEnergyKwh = _elevationModel.computeElevationEnergyDelta(
        deltaElevationM: deltaElevationM,
        vehicleMassKg: totalMassKg,
      );
      final segmentEnergyKwh = baseEnergyKwh + elevationEnergyKwh;

      currentSocKwh -= segmentEnergyKwh;
      currentSocPercent = (currentSocKwh / capacity) * 100.0;

      // Project next step to prevent stranding below critical reserve
      final isNearReserve = currentSocPercent <= reserveThresholdPercent;

      if ((isNearReserve || currentSocKwh < reserveFloorKwh) &&
          stops.length < maxStops) {
        // Battery has dropped into the 15-20% window! Search for corridor charger
        // Look back over recent corridor waypoints (where SoC was still between 15% - 35%)
        final lookbackStart = math.max(lastStopWaypointIndex, i - 25);
        final candidateMap = <String, (Charger, double, int)>{};

        for (var j = i; j >= lookbackStart; j--) {
          final pt = routePoints[j];
          final nearby = spatialIndex.queryNearbyChargers(
            pt,
            maxDistanceFromRouteKm,
          );
          for (var k = 0; k < nearby.length; k++) {
            final c = nearby[k];
            if (visitedChargerIds.contains(c.id)) continue;
            final distToWp = _distanceBetween(pt, LatLng(c.lat, c.lng));
            if (distToWp <= maxDistanceFromRouteKm) {
              final existing = candidateMap[c.id];
              if (existing == null || distToWp < existing.$2) {
                candidateMap[c.id] = (c, distToWp, j);
              }
            }
          }
        }

        if (candidateMap.isNotEmpty) {
          // Score all candidate chargers and rank them for primary + alternative carousel
          final scoredCandidates = <(Charger, double, int, double)>[];

          for (final entry in candidateMap.values) {
            final charger = entry.$1;
            final detourKm = entry.$2;
            final wpIdx = entry.$3;
            final distFromOriginKm = cumulativeDistances[wpIdx];
            final reliability = reliabilityScores[charger.id] ?? 9.0;

            final score = _scoreCandidateCharger(
              charger: charger,
              detourDistanceKm: detourKm,
              progressDistanceKm: distFromOriginKm,
              totalRouteDistanceKm: totalRouteDistanceKm,
              maxDetourKm: maxDistanceFromRouteKm,
              reliabilityScore: reliability,
            );

            scoredCandidates.add((charger, detourKm, wpIdx, score));
          }

          scoredCandidates.sort((a, b) => b.$4.compareTo(a.$4));

          if (scoredCandidates.isNotEmpty) {
            final arrivalSoc = currentSocPercent.clamp(8.0, 35.0);
            final targetSoc = targetChargePercent.clamp(60.0, 90.0);
            final energyNeededKwh =
                ((targetSoc - arrivalSoc) / 100.0) * capacity;
            final nextStopOrder = stops.length + 1;

            ChargingStop buildStopFromTuple(
              (Charger, double, int, double) item, {
              List<ChargingStop> alternatives = const [],
            }) {
              final c = item.$1;
              final detourKm = item.$2;
              final wpIdx = item.$3;
              final sc = item.$4;
              final chargerPower = (c.powerKw ?? 30.0).clamp(10.0, 150.0);
              final chargingTimeMinutes =
                  (energyNeededKwh / (chargerPower * 0.90)) * 60.0;
              return ChargingStop(
                charger: c,
                distanceFromRouteKm: detourKm,
                distanceFromOriginKm: cumulativeDistances[wpIdx],
                score: sc,
                stopOrder: nextStopOrder,
                arrivalSocPercent: arrivalSoc,
                targetSocPercent: targetSoc,
                chargingTimeMinutes: chargingTimeMinutes,
                energyAddedKwh: energyNeededKwh,
                elevationM: elevations[wpIdx],
                alternatives: alternatives,
              );
            }

            final altList = scoredCandidates
                .skip(1)
                .take(3)
                .map((alt) => buildStopFromTuple(alt))
                .toList(growable: false);

            final bestTuple = scoredCandidates.first;
            final stop = buildStopFromTuple(
              bestTuple,
              alternatives: altList,
            );

            stops.add(stop);
            visitedChargerIds.add(bestTuple.$1.id);

            // EV recharged to target SoC (80%) and resumes corridor journey
            currentSocKwh = capacity * (targetSoc / 100.0);
            currentSocPercent = targetSoc;
            lastStopWaypointIndex = i;
          }
        }
      }
    }

    return stops;
  }

  /// Multi-criteria normalized scoring function for corridor charger selection
  double _scoreCandidateCharger({
    required Charger charger,
    required double detourDistanceKm,
    required double progressDistanceKm,
    required double totalRouteDistanceKm,
    required double maxDetourKm,
    double reliabilityScore = 10.0,
  }) {
    // 1. Closeness to corridor (closer = higher score)
    final closenessScore = (1.0 - (detourDistanceKm / maxDetourKm)).clamp(0.0, 1.0);

    // 2. Power rating (prefer >= 50kW fast DC chargers)
    final powerScore = ((charger.powerKw ?? 25.0).clamp(10.0, 120.0)) / 120.0;

    // 3. Port redundancy / slots
    final slotScore = (math.min(charger.slots, 6) / 6.0).clamp(0.1, 1.0);

    // 4. Progress along route corridor
    final progressScore = totalRouteDistanceKm > 0
        ? (progressDistanceKm / totalRouteDistanceKm).clamp(0.0, 1.0)
        : 0.5;

    // 5. LankaScore reliability weighting (penalize stations reported with issues/power cuts)
    final reliabilityFactor = (reliabilityScore / 10.0).clamp(0.2, 1.0);

    final rawScore = (closenessScore * 0.35) +
        (powerScore * 0.30) +
        (slotScore * 0.20) +
        (progressScore * 0.15);

    return rawScore * reliabilityFactor;
  }

  /// Calculates normalized composite routing cost (Eq. 1)
  double computeNormalizedRouteCost({
    required double distanceKm,
    required double energyKwh,
    required double chargingDelayMinutes,
    double maxDistanceKm = 500.0,
    double maxEnergyKwh = 100.0,
    double maxDelayMinutes = 90.0,
  }) {
    final normDistance = (distanceKm / maxDistanceKm).clamp(0.0, 1.0);
    final normEnergy = (energyKwh / maxEnergyKwh).clamp(0.0, 1.0);
    final normDelay = (chargingDelayMinutes / maxDelayMinutes).clamp(0.0, 1.0);

    return (alpha * normDistance) + (beta * normEnergy) + (gamma * normDelay);
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  double _distanceBetween(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
          a.latitude,
          a.longitude,
          b.latitude,
          b.longitude,
        ) /
        1000.0;
  }
}
