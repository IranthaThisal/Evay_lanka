import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteDetails {
  const RouteDetails({
    required this.points,
    required this.bounds,
    required this.distanceText,
    required this.durationText,
  });

  final List<LatLng> points;
  final LatLngBounds bounds;
  final String distanceText;
  final String durationText;
}

class RouteService {
  static const String _directionsApiKey = String.fromEnvironment(
    'GOOGLE_DIRECTIONS_API_KEY',
    defaultValue: '',
  );

  // Built-in Sri Lanka city coordinates for instant, zero-latency fallback
  static const Map<String, LatLng> _sriLankaCities = {
    'colombo': LatLng(6.9271, 79.8612),
    'kandy': LatLng(7.2906, 80.6337),
    'galle': LatLng(6.0535, 80.2210),
    'jaffna': LatLng(9.6615, 80.0255),
    'negombo': LatLng(7.2008, 79.8737),
    'nuwara eliya': LatLng(6.9497, 80.7891),
    'ella': LatLng(6.8667, 81.0466),
    'matara': LatLng(5.9549, 80.5550),
    'hambantota': LatLng(6.1246, 81.1185),
    'anuradhapura': LatLng(8.3114, 80.4037),
    'polonnaruwa': LatLng(7.9403, 81.0188),
    'trincomalee': LatLng(8.5874, 81.2152),
    'batticaloa': LatLng(7.7310, 81.6747),
    'kurunegala': LatLng(7.4818, 80.3609),
    'ratnapura': LatLng(6.7056, 80.3847),
    'badulla': LatLng(6.9934, 81.0550),
    'hatton': LatLng(6.8916, 80.5955),
    'dambulla': LatLng(7.8742, 80.6511),
    'sigiriya': LatLng(7.9570, 80.7603),
    'bentota': LatLng(6.4213, 79.9978),
    'mirissa': LatLng(5.9483, 80.4716),
    'kalutara': LatLng(6.5854, 79.9607),
    'panadura': LatLng(6.7132, 79.9026),
    'moratuwa': LatLng(6.7730, 79.8816),
    'dehiwala': LatLng(6.8511, 79.8630),
    'maharagama': LatLng(6.8480, 79.9265),
    'kottawa': LatLng(6.8412, 79.9654),
    'kaduwela': LatLng(6.9333, 79.9833),
    'gampaha': LatLng(7.0840, 80.0098),
    'chilaw': LatLng(7.5758, 79.7953),
    'puttalam': LatLng(8.0362, 79.8283),
    'vavuniya': LatLng(8.7542, 80.4982),
    'kilinochchi': LatLng(9.3803, 80.3770),
    'mannar': LatLng(8.9810, 79.9044),
    'matale': LatLng(7.4675, 80.6234),
    'kegalle': LatLng(7.2513, 80.3464),
    'avissawella': LatLng(6.9543, 80.2046),
    'balangoda': LatLng(6.6470, 80.6982),
    'monaragala': LatLng(6.8728, 81.3507),
    'ampara': LatLng(7.2975, 81.6820),
    'tangalle': LatLng(6.0244, 80.7941),
    'hikkaduwa': LatLng(6.1395, 80.1063),
    'unawatuna': LatLng(6.0174, 80.2489),
    'weligama': LatLng(5.9750, 80.4297),
    'arugam bay': LatLng(6.8404, 81.8368),
    'katunayake': LatLng(7.1699, 79.8884),
  };

  final http.Client _client;

  RouteService({http.Client? client}) : _client = client ?? http.Client();

  /// Resolves a destination query in Sri Lanka using OpenStreetMap Nominatim
  /// and built-in city coordinates (no Google API key required).
  Future<LatLng?> geocodeAddress(String query) async {
    final cleaned =
        query
            .trim()
            .toLowerCase()
            .replaceAll(', sri lanka', '')
            .replaceAll(' sri lanka', '')
            .trim();
    if (cleaned.isEmpty) return null;

    // 1. Check exact or prefix match in built-in Sri Lanka cities
    if (_sriLankaCities.containsKey(cleaned)) {
      return _sriLankaCities[cleaned];
    }

    // 2. Query OpenStreetMap Nominatim API
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$query, Sri Lanka',
        'format': 'json',
        'limit': '1',
        'countrycodes': 'lk',
      });
      final response = await _client
          .get(
            uri,
            headers: const {
              'User-Agent': 'EVayLanka/1.0 (lk.evaylanka.app)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (_) {
      // Fall through to partial city match
    }

    // 3. Partial match in built-in Sri Lanka city dictionary
    for (final entry in _sriLankaCities.entries) {
      if (cleaned.contains(entry.key) || entry.key.contains(cleaned)) {
        return entry.value;
      }
    }

    return null;
  }

  Future<RouteDetails> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // 1. Primary: Free OpenStreetMap OSRM Driving Router (no API key needed)
    try {
      final osrmRoute = await _fetchOsrmRoute(
        origin: origin,
        destination: destination,
      );
      if (osrmRoute != null) {
        return osrmRoute;
      }
    } catch (_) {
      // Fall back if OSRM is temporarily unreachable
    }

    // 2. Secondary: Google Directions API if a valid key was explicitly provided
    if (_directionsApiKey.trim().isNotEmpty) {
      try {
        return await _fetchGoogleRoute(
          origin: origin,
          destination: destination,
        );
      } catch (_) {
        // Fall through to geometric road estimation
      }
    }

    // 3. Offline / Failsafe fallback: Geodesic road-adjusted route
    return _buildFallbackRoute(origin: origin, destination: destination);
  }

  Future<RouteDetails?> _fetchOsrmRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final coords =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coords',
      {'overview': 'full', 'geometries': 'polyline'},
    );

    final response = await _client
        .get(
          uri,
          headers: const {'User-Agent': 'EVayLanka/1.0 (lk.evaylanka.app)'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code']?.toString() != 'Ok') return null;

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry']?.toString() ?? '';
    final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
    final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;

    final points =
        geometry.isNotEmpty
            ? _decodePolyline(geometry)
            : <LatLng>[origin, destination];

    final distanceKm = distanceMeters / 1000.0;
    final durationMinutes = (durationSeconds / 60.0).round();

    return RouteDetails(
      points: points,
      bounds: _boundsFromPoints(points),
      distanceText: _formatDistance(distanceKm),
      durationText: _formatDuration(durationMinutes),
    );
  }

  Future<RouteDetails> _fetchGoogleRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'key': _directionsApiKey,
    });

    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception(
        'Directions API request failed (${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status']?.toString() ?? 'UNKNOWN';
    if (status != 'OK') {
      throw Exception('Directions status: $status');
    }

    final routes = data['routes'] as List<dynamic>;
    if (routes.isEmpty) {
      throw Exception('No route found for the selected destination.');
    }

    final route = routes.first as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>;
    final leg = legs.first as Map<String, dynamic>;
    final overview = route['overview_polyline'] as Map<String, dynamic>;
    final bounds = route['bounds'] as Map<String, dynamic>;

    return RouteDetails(
      points: _decodePolyline(overview['points'] as String),
      bounds: LatLngBounds(
        southwest: _latLngFromJson(bounds['southwest'] as Map<String, dynamic>),
        northeast: _latLngFromJson(bounds['northeast'] as Map<String, dynamic>),
      ),
      distanceText:
          (leg['distance'] as Map<String, dynamic>)['text']?.toString() ?? '-',
      durationText:
          (leg['duration'] as Map<String, dynamic>)['text']?.toString() ?? '-',
    );
  }

  RouteDetails _buildFallbackRoute({
    required LatLng origin,
    required LatLng destination,
  }) {
    final straightMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    // Sri Lanka road tortuosity factor (~1.28x straight line)
    final roadKm = math.max(0.5, (straightMeters / 1000.0) * 1.28);
    // Average speed ~45 km/h on Sri Lanka A/B roads
    final durationMins = math.max(2, ((roadKm / 45.0) * 60.0).round());

    const steps = 32;
    final points = <LatLng>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add(
        LatLng(
          origin.latitude + (destination.latitude - origin.latitude) * t,
          origin.longitude + (destination.longitude - origin.longitude) * t,
        ),
      );
    }

    return RouteDetails(
      points: points,
      bounds: _boundsFromPoints(points),
      distanceText: _formatDistance(roadKm),
      durationText: _formatDuration(durationMins),
    );
  }

  static LatLngBounds _boundsFromPoints(List<LatLng> points) {
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

  static String _formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static String _formatDuration(int totalMinutes) {
    final mins = math.max(1, totalMinutes);
    if (mins < 60) {
      return '$mins mins';
    }
    final hours = mins ~/ 60;
    final remMins = mins % 60;
    if (remMins == 0) {
      return '$hours ${hours == 1 ? 'hr' : 'hrs'}';
    }
    return '$hours ${hours == 1 ? 'hr' : 'hrs'} $remMins mins';
  }

  LatLng _latLngFromJson(Map<String, dynamic> json) {
    return LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      while (true) {
        final byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }

      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;

      while (true) {
        final byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }

      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
