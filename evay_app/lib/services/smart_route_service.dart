import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/charger.dart';
import '../models/smart_route.dart';
import 'route_service.dart';

class SmartRouteService {
  SmartRouteService({RouteService? routeService})
    : _routeService = routeService ?? RouteService();

  static const double defaultMaxDistanceFromRouteKm = 15;
  static const int defaultMaxStops = 8;

  final RouteService _routeService;

  Future<SmartRoute> planFastestRouteWithChargers({
    required LatLng origin,
    required LatLng destination,
    required List<Charger> chargers,
    double maxDistanceFromRouteKm = defaultMaxDistanceFromRouteKm,
    int maxStops = defaultMaxStops,
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
  }) {
    if (routePoints.isEmpty || chargers.isEmpty) return const [];

    final stops = <ChargingStop>[];

    for (final charger in chargers) {
      final chargerLocation = LatLng(charger.lat, charger.lng);
      final distanceFromRouteKm = _distanceFromRoute(
        routePoints,
        chargerLocation,
      );
      if (distanceFromRouteKm > maxDistanceFromRouteKm) continue;

      final distanceFromOriginKm = _distanceBetween(origin, chargerLocation);
      stops.add(
        ChargingStop(
          charger: charger,
          distanceFromRouteKm: distanceFromRouteKm,
          distanceFromOriginKm: distanceFromOriginKm,
          score: _scoreCharger(
            charger: charger,
            distanceFromRouteKm: distanceFromRouteKm,
            distanceFromOriginKm: distanceFromOriginKm,
          ),
        ),
      );
    }

    stops.sort((a, b) => b.score.compareTo(a.score));
    return stops.take(maxStops).toList();
  }

  double _scoreCharger({
    required Charger charger,
    required double distanceFromRouteKm,
    required double distanceFromOriginKm,
  }) {
    final powerScore = math.min(charger.powerKw ?? 20, 150) / 150;
    final slotScore = math.min(charger.slots, 6) / 6;
    final routeCloseness =
        1 - (distanceFromRouteKm / defaultMaxDistanceFromRouteKm);
    final progressScore = math.min(distanceFromOriginKm, 250) / 250;

    return (routeCloseness * 0.45) +
        (slotScore * 0.25) +
        (powerScore * 0.20) +
        (progressScore * 0.10);
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
        1000;
  }
}
