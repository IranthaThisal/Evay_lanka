import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/charger.dart';
import '../models/smart_route.dart';
import 'route_service.dart';

class SmartRouteService {
  SmartRouteService({RouteService? routeService})
    : _routeService = routeService ?? RouteService();

  static const double defaultMaxDistanceFromRouteKm = 15.0;
  static const int defaultMaxStops = 8;
  static const double defaultClimateFactor = 1.05;

  // Normalized cost function weights satisfying alpha + beta + gamma = 1.0 (Eq. 1)
  static const double alpha = 0.35; // Normalized distance weight
  static const double beta = 0.45;  // Normalized energy weight
  static const double gamma = 0.20; // Normalized charging delay weight

  final RouteService _routeService;

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
  }) async {
    final route = await _routeService.fetchRoute(
      origin: origin,
      destination: destination,
    );
    final stops = recommendChargingStops(
      origin: origin,
      routePoints: route.points,
      chargers: chargers,
      maxDistanceFromRouteKm: maxDistanceFromRouteKm,
      maxStops: maxStops,
      batteryCapacityKwh: batteryCapacityKwh,
      batteryPercent: batteryPercent,
      efficiencyKmPerKwh: efficiencyKmPerKwh,
      climateFactor: climateFactor,
    );

    return SmartRoute(
      origin: origin,
      destination: destination,
      routePoints: route.points,
      bounds: route.bounds,
      distanceText: route.distanceText,
      durationText: route.durationText,
      chargingStops: stops,
    );
  }

  List<ChargingStop> recommendChargingStops({
    required LatLng origin,
    required List<LatLng> routePoints,
    required List<Charger> chargers,
    double maxDistanceFromRouteKm = defaultMaxDistanceFromRouteKm,
    int maxStops = defaultMaxStops,
    double? batteryCapacityKwh,
    double? batteryPercent,
    double? efficiencyKmPerKwh,
    double climateFactor = defaultClimateFactor,
  }) {
    if (routePoints.isEmpty || chargers.isEmpty) return const [];

    final stops = <ChargingStop>[];
    final ratedEfficiencyKwhPerKm = (efficiencyKmPerKwh != null && efficiencyKmPerKwh > 0)
        ? (1.0 / efficiencyKmPerKwh)
        : 0.18; // Default ~18 kWh/100km

    final availableKwh = (batteryCapacityKwh != null && batteryPercent != null)
        ? batteryCapacityKwh * (batteryPercent.clamp(0.0, 100.0) / 100.0)
        : double.infinity;
    
    // 10% reserve capacity to prevent stranding
    final reserveKwh = (batteryCapacityKwh != null) ? batteryCapacityKwh * 0.10 : 0.0;

    for (final charger in chargers) {
      final chargerLocation = LatLng(charger.lat, charger.lng);
      final distanceFromRouteKm = _distanceFromRoute(
        routePoints,
        chargerLocation,
      );
      if (distanceFromRouteKm > maxDistanceFromRouteKm) continue;

      final distanceFromOriginKm = _distanceBetween(origin, chargerLocation);

      // Detour distance (round-trip off highway: 2x detour)
      final roundTripDetourKm = distanceFromRouteKm * 2.0;
      final segment1DistanceKm = distanceFromOriginKm + roundTripDetourKm;
      final segment1EnergyKwh = segment1DistanceKm * ratedEfficiencyKwhPerKm * climateFactor;

      // Segment-level feasibility constraint
      // A charger is only viable if the EV can reach it without depleting reserve
      if (segment1EnergyKwh > (availableKwh - reserveKwh) && availableKwh != double.infinity) {
        continue;
      }

      stops.add(
        ChargingStop(
          charger: charger,
          distanceFromRouteKm: distanceFromRouteKm,
          distanceFromOriginKm: distanceFromOriginKm,
          score: _scoreCharger(
            charger: charger,
            distanceFromRouteKm: distanceFromRouteKm,
            distanceFromOriginKm: distanceFromOriginKm,
            segmentEnergyKwh: segment1EnergyKwh,
          ),
        ),
      );
    }

    // Rank candidate charging stops by composite optimization score
    stops.sort((a, b) => b.score.compareTo(a.score));
    return stops.take(maxStops).toList();
  }

  /// Evaluates normalized candidate station cost
  double _scoreCharger({
    required Charger charger,
    required double distanceFromRouteKm,
    required double distanceFromOriginKm,
    required double segmentEnergyKwh,
  }) {
    // Normalization to [0, 1]
    final powerScore = math.min(charger.powerKw ?? 20.0, 150.0) / 150.0;
    final slotScore = math.min(charger.slots, 6) / 6.0;
    final routeCloseness = (1.0 - (distanceFromRouteKm / defaultMaxDistanceFromRouteKm)).clamp(0.0, 1.0);
    final progressScore = (math.min(distanceFromOriginKm, 350.0) / 350.0);

    // Multi-criteria normalized weight
    return (routeCloseness * 0.40) +
        (slotScore * 0.25) +
        (powerScore * 0.20) +
        (progressScore * 0.15);
  }

  /// Calculates normalized composite routing cost (Eq. 1)
  /// Cost(ri) = alpha * (Di / Dmax) + beta * (Ei / Emax) + gamma * (Ci / Cmax)
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

  double _distanceFromRoute(List<LatLng> routePoints, LatLng target) {
    double minKm = double.infinity;

    for (var i = 0; i < routePoints.length; i += 4) {
      minKm = math.min(minKm, _distanceBetween(routePoints[i], target));
    }

    return math.min(minKm, _distanceBetween(routePoints.last, target));
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
