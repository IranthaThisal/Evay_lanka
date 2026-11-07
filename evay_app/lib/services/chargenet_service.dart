import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/charger.dart';

class ChargeNetService {
  ChargeNetService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _endpoint = Uri.parse(
    'https://api.chargenet.lk:13100/ChargerHandler.asmx/ShowAllChargePointData',
  );
  static final RegExp _powerRegex = RegExp(
    r'(\d+(?:\.\d+)?)\s*kW',
    caseSensitive: false,
  );

  final http.Client _client;

  Future<List<Charger>> fetchChargers() async {
    final response = await _client
        .get(_endpoint)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('ChargeNet returned ${response.statusCode}');
    }

    final body = utf8.decode(response.bodyBytes);
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];

    final rawPoints = decoded['listOfChargePoints'];
    if (rawPoints is! List) return const [];

    return rawPoints
        .whereType<Map<String, dynamic>>()
        .map(_chargerFromChargeNet)
        .whereType<Charger>()
        .toList(growable: false);
  }

  Charger? _chargerFromChargeNet(Map<String, dynamic> data) {
    final reference = _text(data['reference']);
    final lat = _doubleFrom(data['latitude']);
    final lng = _doubleFrom(data['longitude']);
    if (reference.isEmpty || lat == null || lng == null) return null;

    final type = _text(data['type']);
    final protocol = _text(data['protocol']);
    final location = _text(data['location']);
    final address = _text(data['address']);
    final status = _text(data['availability_status']).toUpperCase();

    return Charger(
      id: 'chargenet-$reference',
      name: location.isEmpty ? 'ChargeNet $reference' : location,
      city: _cityFromAddress(address),
      lat: lat,
      lng: lng,
      slots: status == 'AVAILABLE' ? 1 : 0,
      powerKw: _powerFrom(type: type, name: location),
      connectorTypes: [
        if (type.isNotEmpty) type,
        if (protocol.isNotEmpty) protocol.replaceAll('_', ' '),
      ],
    );
  }

  String _cityFromAddress(String address) {
    if (address.isEmpty) return 'ChargeNet';

    final parts =
        address
            .split(',')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList(growable: false);
    if (parts.isEmpty) return 'ChargeNet';

    return parts.length >= 2 ? parts[parts.length - 2] : parts.last;
  }

  double? _powerFrom({required String type, required String name}) {
    final match = _powerRegex.firstMatch(name);
    if (match != null) return double.tryParse(match.group(1)!);

    return switch (type.toUpperCase()) {
      'L3' => 50,
      'L2' => 6.6,
      _ => null,
    };
  }

  double? _doubleFrom(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  String _text(Object? value) => value?.toString().trim() ?? '';
}
