import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/charger.dart';
import '../models/smart_route.dart';
import 'route_service.dart';

/// Topographical elevation anchor point representing key relief features in Sri Lanka.
class ElevationAnchor {
  const ElevationAnchor(this.lat, this.lng, this.elevationM, this.radiusKm);

  final double lat;
  final double lng;
  final double elevationM;
  final double radiusKm;
}

/// Sri Lanka Topographical & Elevation Modeling Service.
/// Models the distinct central highland massif (Nuwara Eliya, Kandy, Hatton, Ella)
/// transitioning into midland plateaus and coastal lowlands.
/// Calculates gravitational potential energy penalties and regenerative braking recovery.
class SriLankaElevationModel {
  const SriLankaElevationModel();

  // Reference topography anchors across Sri Lanka's geographical zones
  static const List<ElevationAnchor> anchors = [
    // Central Highlands Massif (High Altitude 1,000m - 2,500m)
    ElevationAnchor(6.97, 80.78, 1950.0, 22.0), // Nuwara Eliya / Pidurutalagala Base
    ElevationAnchor(6.80, 80.80, 2130.0, 16.0), // Horton Plains / World's End
    ElevationAnchor(6.81, 80.50, 1850.0, 14.0), // Adam's Peak (Sri Pada)
    ElevationAnchor(6.89, 80.60, 1270.0, 16.0), // Hatton / Dikoya / Talawakele
    ElevationAnchor(6.85, 81.04, 1040.0, 18.0), // Ella / Bandarawela
    ElevationAnchor(6.77, 80.96, 1430.0, 15.0), // Haputale ridge
    ElevationAnchor(7.40, 80.78, 1450.0, 20.0), // Knuckles Mountain Range
    ElevationAnchor(7.05, 80.72, 1100.0, 15.0), // Ramboda Pass

    // Midland Plateaus & Foothills (300m - 700m)
    ElevationAnchor(7.29, 80.63, 500.0, 20.0),  // Kandy Valley / Peradeniya
    ElevationAnchor(7.25, 80.52, 520.0, 12.0),  // Kadugannawa Pass
    ElevationAnchor(7.12, 80.57, 560.0, 15.0),  // Gampola / Nawalapitiya
    ElevationAnchor(6.99, 81.05, 680.0, 16.0),  // Badulla Valley
    ElevationAnchor(7.47, 80.62, 364.0, 16.0),  // Matale
    ElevationAnchor(6.65, 80.70, 530.0, 18.0),  // Balangoda
    ElevationAnchor(6.68, 80.40, 130.0, 22.0),  // Ratnapura foothills
    ElevationAnchor(7.48, 80.36, 116.0, 25.0),  // Kurunegala
    ElevationAnchor(7.87, 80.65, 175.0, 25.0),  // Dambulla / Sigiriya
    ElevationAnchor(6.87, 81.35, 180.0, 25.0),  // Monaragala / Wellawaya

    // Lowland Plains & Coastal Belt (0m - 80m)
    ElevationAnchor(6.93, 79.86, 10.0, 35.0),   // Colombo / Western Coast
    ElevationAnchor(7.21, 79.84, 5.0, 30.0),    // Negombo
    ElevationAnchor(6.03, 80.22, 12.0, 35.0),   // Galle / Southern Coast
    ElevationAnchor(6.12, 81.12, 15.0, 35.0),   // Hambantota / Mattala
    ElevationAnchor(8.58, 81.23, 10.0, 40.0),   // Trincomalee / Eastern Bay
    ElevationAnchor(7.71, 81.70, 8.0, 35.0),    // Batticaloa
    ElevationAnchor(8.33, 80.41, 81.0, 35.0),   // Anuradhapura
    ElevationAnchor(7.94, 81.00, 60.0, 30.0),   // Polonnaruwa
    ElevationAnchor(8.75, 80.50, 45.0, 35.0),   // Vavuniya
    ElevationAnchor(9.38, 80.40, 15.0, 35.0),   // Kilinochchi
    ElevationAnchor(9.66, 80.01, 5.0, 40.0),    // Jaffna Peninsula
    ElevationAnchor(8.98, 79.91, 5.0, 35.0),    // Mannar Island
  ];

  /// Interpolates the topographical elevation in meters at a given coordinate.
  double getElevation(LatLng point) {
    double totalWeight = 0.0;
    double weightedElevation = 0.0;

    for (final anchor in anchors) {
      final distanceKm = Geolocator.distanceBetween(
            point.latitude,
            point.longitude,
            anchor.lat,
            anchor.lng,
          ) /
          1000.0;

      // Gaussian radial basis weighting
      final sigma = anchor.radiusKm;
      final weight = math.exp(-(distanceKm * distanceKm) / (2.0 * sigma * sigma));

      if (weight > 1e-4) {
        weightedElevation += weight * anchor.elevationM;
        totalWeight += weight;
      }
    }

    if (totalWeight <= 1e-4) {
      return 10.0; // Baseline coastal elevation
    }

    return weightedElevation / totalWeight;
  }

  /// Calculates the cumulative ascent (gain) and descent (loss) in meters along route waypoints.
  (double gainM, double lossM) computeGainAndLoss(List<LatLng> points) {
    if (points.length < 2) return (0.0, 0.0);

    double totalGain = 0.0;
    double totalLoss = 0.0;
    double prevElev = getElevation(points.first);

    // Sample every 2nd or 3rd waypoint for elevation profile smoothing
    final step = math.max(1, (points.length / 100).ceil());
    for (var i = step; i < points.length; i += step) {
      final currElev = getElevation(points[i]);
      final delta = currElev - prevElev;
      if (delta > 0) {
        totalGain += delta;
      } else {
        totalLoss += -delta;
      }
      prevElev = currElev;
    }

    // Include last waypoint
    final lastElev = getElevation(points.last);
    final finalDelta = lastElev - prevElev;
    if (finalDelta > 0) {
      totalGain += finalDelta;
    } else {
      totalLoss += -finalDelta;
    }

    return (totalGain, totalLoss);
  }

  /// Evaluates net gravitational energy impact (kWh) for an elevation difference deltaElevationM.
  /// Driving uphill consumes +30% to +45% energy via gravitational potential energy (m * g * h / eta_drive).
  /// Driving downhill recovers 15% to 20% energy via regenerative braking (m * g * |h| * eta_regen).
  double computeElevationEnergyDelta({
    required double deltaElevationM,
    double vehicleMassKg = 1800.0,
    double driveEfficiency = 0.88,
    double regenEfficiency = 0.65,
  }) {
    const g = 9.80665; // m/s^2
    const joulesToKwh = 1.0 / 3600000.0;

    final potentialEnergyKwh = (vehicleMassKg * g * deltaElevationM.abs()) * joulesToKwh;

    if (deltaElevationM > 0) {
      // Uphill ascent penalty: extra motor energy needed to gain gravitational potential
      return potentialEnergyKwh / driveEfficiency;
    } else if (deltaElevationM < 0) {
      // Downhill descent recovery: kinetic/potential conversion through regenerative braking
      return -potentialEnergyKwh * regenEfficiency;
    }

    return 0.0;
  }
}

/// Spatial Bounding-Box and 2D Hash Grid Index for O(1) charger lookups.
class SpatialChargerIndex {
  SpatialChargerIndex({
    required List<Charger> chargers,
    this.cellSizeDeg = 0.05, // ~5.5 km grid cell
  }) {
    for (final charger in chargers) {
      final cellX = (charger.lat / cellSizeDeg).floor();
      final cellY = (charger.lng / cellSizeDeg).floor();
      final key = _hashKey(cellX, cellY);
      _grid.putIfAbsent(key, () => []).add(charger);
    }
  }

  final double cellSizeDeg;
  final Map<int, List<Charger>> _grid = {};

  static int _hashKey(int x, int y) {
    return (x * 73856093) ^ (y * 19349663);
  }

  /// Fast Bounding-Box Pre-filter:
  /// Discards chargers outside the expanded route envelope in O(N) simple comparisons,
  /// avoiding expensive Haversine geodesic math for distant stations.
  static List<Charger> filterByRouteEnvelope({
    required List<Charger> chargers,
    required LatLngBounds bounds,
    required double marginKm,
  }) {
    final marginLat = marginKm / 111.0;
    final midLatRad = ((bounds.southwest.latitude + bounds.northeast.latitude) / 2.0) * math.pi / 180.0;
    final marginLng = marginKm / (111.0 * math.cos(midLatRad).abs().clamp(0.2, 1.0));

    final minLat = bounds.southwest.latitude - marginLat;
    final maxLat = bounds.northeast.latitude + marginLat;
    final minLng = bounds.southwest.longitude - marginLng;
    final maxLng = bounds.northeast.longitude + marginLng;

    return chargers.where((c) {
      return c.lat >= minLat && c.lat <= maxLat && c.lng >= minLng && c.lng <= maxLng;
    }).toList();
  }

  /// Queries chargers within radiusKm in O(1) average time by scanning local grid neighborhood.
  List<Charger> queryNearbyChargers(LatLng point, double radiusKm) {
    final cellRadius = (radiusKm / (111.0 * cellSizeDeg)).ceil();
    final centerCellX = (point.latitude / cellSizeDeg).floor();
    final centerCellY = (point.longitude / cellSizeDeg).floor();

    final results = <Charger>[];
    for (var dx = -cellRadius; dx <= cellRadius; dx++) {
      for (var dy = -cellRadius; dy <= cellRadius; dy++) {
        final key = _hashKey(centerCellX + dx, centerCellY + dy);
        final bucket = _grid[key];
        if (bucket != null) {
          results.addAll(bucket);
        }
      }
    }
    return results;
  }
}

/// Smart Route Service:
/// Supports Multi-Stop Corridor Planning, Sri Lanka Topography & Elevation Modeling,
/// and Spatial Bounding-Box Indexing for high-performance EV routing.
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
    double climateFactor = defaultClimateFactor,
    double reserveThresholdPercent = 18.0,
    double targetChargePercent = 80.0,
  }) async {
    final route = await _routeService.fetchRoute(
      origin: origin,
      destination: destination,
    );

    final (gainM, lossM) = _elevationModel.computeGainAndLoss(route.points);
    final elevationEnergyPenaltyKwh = _elevationModel.computeElevationEnergyDelta(
      deltaElevationM: gainM - (lossM * 0.70),
    );

    final stops = recommendChargingStops(
      origin: origin,
      routePoints: route.points,
      routeBounds: route.bounds,
      chargers: chargers,
      maxDistanceFromRouteKm: maxDistanceFromRouteKm,
      maxStops: maxStops,
      batteryCapacityKwh: batteryCapacityKwh,
      batteryPercent: batteryPercent,
      efficiencyKmPerKwh: efficiencyKmPerKwh,
      climateFactor: climateFactor,
      reserveThresholdPercent: reserveThresholdPercent,
      targetChargePercent: targetChargePercent,
    );

    double totalChargingTime = 0.0;
    for (final stop in stops) {
      totalChargingTime += stop.chargingTimeMinutes;
    }

    return SmartRoute(
      origin: origin,
      destination: destination,
      routePoints: route.points,
      bounds: route.bounds,
      distanceText: route.distanceText,
      durationText: route.durationText,
      chargingStops: stops,
      totalElevationGainM: gainM,
      totalElevationLossM: lossM,
      totalChargingTimeMinutes: totalChargingTime,
      elevationEnergyPenaltyKwh: elevationEnergyPenaltyKwh,
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
    double climateFactor = defaultClimateFactor,
    double reserveThresholdPercent = 18.0,
    double targetChargePercent = 80.0,
  }) {
    if (routePoints.isEmpty || chargers.isEmpty) return const [];

    // Step 1: Spatial Bounding-Box Pre-filtering
    final effectiveBounds = routeBounds ?? _calculateBounds(routePoints);
    final corridorChargers = SpatialChargerIndex.filterByRouteEnvelope(
      chargers: chargers,
      bounds: effectiveBounds,
      marginKm: maxDistanceFromRouteKm,
    );

    if (corridorChargers.isEmpty) return const [];

    // Step 2: Build O(1) Spatial Hash Grid Index for corridor
    final spatialIndex = SpatialChargerIndex(chargers: corridorChargers);

    // EV Specifications
    final capacity = batteryCapacityKwh ?? 55.0; // Default ~55 kWh battery
    final ratedEfficiencyKwhPerKm = (efficiencyKmPerKwh != null && efficiencyKmPerKwh > 0)
        ? (1.0 / efficiencyKmPerKwh)
        : 0.18; // Default ~18 kWh/100km

    double currentSocKwh = capacity * ((batteryPercent ?? 70.0).clamp(5.0, 100.0) / 100.0);
    double currentSocPercent = (currentSocKwh / capacity) * 100.0;
    final reserveFloorKwh = capacity * (reserveThresholdPercent / 100.0);

    final stops = <ChargingStop>[];
    final visitedChargerIds = <String>{};

    // Pre-calculate cumulative waypoint distances and elevations
    final n = routePoints.length;
    final cumulativeDistances = List<double>.filled(n, 0.0);
    final elevations = List<double>.filled(n, 0.0);

    elevations[0] = _elevationModel.getElevation(routePoints[0]);
    for (var i = 1; i < n; i++) {
      final segKm = _distanceBetween(routePoints[i - 1], routePoints[i]);
      cumulativeDistances[i] = cumulativeDistances[i - 1] + segKm;
      elevations[i] = _elevationModel.getElevation(routePoints[i]);
    }

    final totalRouteDistanceKm = cumulativeDistances.last;
    int lastStopWaypointIndex = 0;

    // Step 3: Multi-Hop Dynamic State of Charge Simulation along Waypoints
    for (var i = 1; i < n; i++) {
      final segDistanceKm = cumulativeDistances[i] - cumulativeDistances[i - 1];
      final deltaElevationM = elevations[i] - elevations[i - 1];

      // Base energy consumption + Sri Lanka topography energy factor
      final baseEnergyKwh = segDistanceKm * ratedEfficiencyKwhPerKm * climateFactor;
      final elevationEnergyKwh = _elevationModel.computeElevationEnergyDelta(
        deltaElevationM: deltaElevationM,
      );
      final segmentEnergyKwh = baseEnergyKwh + elevationEnergyKwh;

      currentSocKwh -= segmentEnergyKwh;
      currentSocPercent = (currentSocKwh / capacity) * 100.0;

      // Project next step to prevent stranding below critical 12% reserve
      final isNearReserve = currentSocPercent <= reserveThresholdPercent;
      final isEndOfTrip = i == n - 1;

      if ((isNearReserve && stops.length < maxStops) ||
          (currentSocKwh < reserveFloorKwh && stops.length < maxStops)) {
        // Battery has dropped into the 15-20% window! Search for corridor charger
        // Look back over recent corridor waypoints (where SoC was still between 15% - 35%)
        final lookbackStart = math.max(lastStopWaypointIndex, i - 25);
        final candidateMap = <String, (Charger, double, int)>{};

        for (var j = i; j >= lookbackStart; j--) {
          final pt = routePoints[j];
          final nearby = spatialIndex.queryNearbyChargers(pt, maxDistanceFromRouteKm);
          for (final c in nearby) {
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
          // Score candidate chargers using normalized multi-criteria function
          Charger? bestCharger;
          double bestScore = -1.0;
          double bestDetourKm = double.infinity;
          int bestWpIndex = i;

          for (final entry in candidateMap.values) {
            final charger = entry.$1;
            final detourKm = entry.$2;
            final wpIdx = entry.$3;
            final distFromOriginKm = cumulativeDistances[wpIdx];

            final score = _scoreCandidateCharger(
              charger: charger,
              detourDistanceKm: detourKm,
              progressDistanceKm: distFromOriginKm,
              totalRouteDistanceKm: totalRouteDistanceKm,
              maxDetourKm: maxDistanceFromRouteKm,
            );

            if (score > bestScore) {
              bestScore = score;
              bestCharger = charger;
              bestDetourKm = detourKm;
              bestWpIndex = wpIdx;
            }
          }

          if (bestCharger != null) {
            final arrivalSoc = currentSocPercent.clamp(8.0, 35.0);
            final targetSoc = targetChargePercent.clamp(60.0, 90.0);
            final energyNeededKwh = ((targetSoc - arrivalSoc) / 100.0) * capacity;
            final chargerPower = (bestCharger.powerKw ?? 30.0).clamp(10.0, 150.0);
            
            // Standard DC Fast Charger taper curve efficiency (eta ~0.90)
            final chargingTimeMinutes = (energyNeededKwh / (chargerPower * 0.90)) * 60.0;

            final stop = ChargingStop(
              charger: bestCharger,
              distanceFromRouteKm: bestDetourKm,
              distanceFromOriginKm: cumulativeDistances[bestWpIndex],
              score: bestScore,
              stopOrder: stops.length + 1,
              arrivalSocPercent: arrivalSoc,
              targetSocPercent: targetSoc,
              chargingTimeMinutes: chargingTimeMinutes,
              energyAddedKwh: energyNeededKwh,
              elevationM: elevations[bestWpIndex],
            );

            stops.add(stop);
            visitedChargerIds.add(bestCharger.id);

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

    return (closenessScore * 0.35) +
        (powerScore * 0.30) +
        (slotScore * 0.20) +
        (progressScore * 0.15);
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
