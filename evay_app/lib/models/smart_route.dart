import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'charger.dart';

class ChargingStop {
  const ChargingStop({
    required this.charger,
    required this.distanceFromRouteKm,
    required this.distanceFromOriginKm,
    required this.score,
    this.stopOrder = 1,
    this.arrivalSocPercent = 20.0,
    this.targetSocPercent = 80.0,
    this.chargingTimeMinutes = 30.0,
    this.energyAddedKwh = 20.0,
    this.elevationM = 0.0,
  });

  final Charger charger;
  final double distanceFromRouteKm;
  final double distanceFromOriginKm;
  final double score;
  final int stopOrder;
  final double arrivalSocPercent;
  final double targetSocPercent;
  final double chargingTimeMinutes;
  final double energyAddedKwh;
  final double elevationM;
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
    this.totalElevationGainM = 0.0,
    this.totalElevationLossM = 0.0,
    this.arrivalBatteryPercent = 0.0,
    this.totalChargingTimeMinutes = 0.0,
    this.totalEnergyConsumedKwh = 0.0,
    this.elevationEnergyPenaltyKwh = 0.0,
  });

  final LatLng origin;
  final LatLng destination;
  final List<LatLng> routePoints;
  final LatLngBounds bounds;
  final String distanceText;
  final String durationText;
  final List<ChargingStop> chargingStops;
  final double totalElevationGainM;
  final double totalElevationLossM;
  final double arrivalBatteryPercent;
  final double totalChargingTimeMinutes;
  final double totalEnergyConsumedKwh;
  final double elevationEnergyPenaltyKwh;

  bool get hasChargingStops => chargingStops.isNotEmpty;
  int get stopsCount => chargingStops.length;
}
