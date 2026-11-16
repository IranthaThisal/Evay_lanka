import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/charger.dart';

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
      (_grid[key] ??= <Charger>[]).add(charger);
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
    final midLatRad =
        ((bounds.southwest.latitude + bounds.northeast.latitude) / 2.0) *
        math.pi /
        180.0;
    final marginLng =
        marginKm / (111.0 * math.cos(midLatRad).abs().clamp(0.2, 1.0));

    final minLat = bounds.southwest.latitude - marginLat;
    final maxLat = bounds.northeast.latitude + marginLat;
    final minLng = bounds.southwest.longitude - marginLng;
    final maxLng = bounds.northeast.longitude + marginLng;

    return [
      for (final c in chargers)
        if (c.lat >= minLat &&
            c.lat <= maxLat &&
            c.lng >= minLng &&
            c.lng <= maxLng)
          c,
    ];
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
