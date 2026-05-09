import 'dart:convert';

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
    defaultValue: 'AIzaSyCypxUIgv01ZTGmFksc7VdoSqEPkEfwock',
  );

  final http.Client _client;

  RouteService({http.Client? client}) : _client = client ?? http.Client();

  Future<RouteDetails> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (_directionsApiKey.trim().isEmpty) {
      throw Exception(
        'Directions are not configured. Start the app with '
        '--dart-define=GOOGLE_DIRECTIONS_API_KEY=your_server_key.',
      );
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'key': _directionsApiKey,
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Directions API request failed (${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status']?.toString() ?? 'UNKNOWN';
    if (status != 'OK') {
      final rawError = data['error_message']?.toString();
      throw Exception(_messageForStatus(status, rawError: rawError));
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

  LatLng _latLngFromJson(Map<String, dynamic> json) {
    return LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    );
  }

  String _messageForStatus(String status, {String? rawError}) {
    final normalizedError = rawError?.toLowerCase() ?? '';
    return switch (status) {
      'ZERO_RESULTS' => 'No driving route found for this destination.',
      'REQUEST_DENIED' =>
        normalizedError.contains('not authorized')
            ? 'This Google Directions key is not authorized for this app. '
                'Use a valid Directions API key with '
                '--dart-define=GOOGLE_DIRECTIONS_API_KEY=...'
            : 'Directions are not enabled for this Google Maps API key.',
      'OVER_QUERY_LIMIT' => 'Directions are busy right now. Try again shortly.',
      _ => 'Directions request failed. Please try another destination.',
    };
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
