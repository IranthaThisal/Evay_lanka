import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'charger.dart';

class ChargingStop {
  const ChargingStop({
    required this.charger,
    required this.distanceFromRouteKm,
    required this.distanceFromOriginKm,
    required this.score,
  });

  final Charger charger;
  final double distanceFromRouteKm;
  final double distanceFromOriginKm;
  final double score;
}

class SmartRoute {
  const SmartRoute({
    required this.origin,
    required this.destination,
    required this.routePoints,
    required this.bounds,
    required this.distanceText,
    required this.durationText,
    required this.chargingStops,
  });

  final LatLng origin;
  final LatLng destination;
  final List<LatLng> routePoints;
  final LatLngBounds bounds;
  final String distanceText;
  final String durationText;
  final List<ChargingStop> chargingStops;

  bool get hasChargingStops => chargingStops.isNotEmpty;
}
