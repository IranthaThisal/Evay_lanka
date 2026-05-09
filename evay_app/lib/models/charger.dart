import 'package:cloud_firestore/cloud_firestore.dart';

class Charger {
  final String id;
  final String name;
  final String city;
  final double lat;
  final double lng;
  final int slots;
  final double? powerKw;
  final List<String> connectorTypes;

  Charger({
    required this.id,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
    required this.slots,
    this.powerKw,
    this.connectorTypes = const [],
  });

  static Charger? tryFromDoc(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw == null) return null;
    final data = raw as Map<String, dynamic>;

    double? lat;
    double? lng;

    // ✅ Case 1: location: GeoPoint
    final loc = data['location'];
    if (loc is GeoPoint) {
      lat = loc.latitude;
      lng = loc.longitude;
    }

    // ✅ Case 2: lat is GeoPoint (your current data!)
    final latField = data['lat'];
    if (lat == null && latField is GeoPoint) {
      lat = latField.latitude;
      lng = latField.longitude;
    }

    // ✅ Case 3: lng is GeoPoint (your current data too)
    final lngField = data['lng'];
    if (lat == null && lngField is GeoPoint) {
      lat = lngField.latitude;
      lng = lngField.longitude;
    }

    // ✅ Case 4: lat/lng are numbers
    if (lat == null && data['lat'] is num && data['lng'] is num) {
      lat = (data['lat'] as num).toDouble();
      lng = (data['lng'] as num).toDouble();
    }

    // If still missing, skip doc (prevents crash)
    if (lat == null || lng == null) return null;

    final availabilityStatus =
        (data['availabilityStatus'] ?? data['availability_status'])
            ?.toString()
            .toUpperCase();
    final slotsFromStatus =
        availabilityStatus == null
            ? null
            : availabilityStatus == 'AVAILABLE'
            ? 1
            : 0;

    return Charger(
      id: (data['id'] ?? doc.id).toString(),
      name: (data['name'] ?? 'Charging Station').toString(),
      city: (data['city'] ?? '').toString(),
      lat: lat,
      lng: lng,
      slots:
          slotsFromStatus ??
          ((data['slots'] is int)
              ? data['slots']
              : int.tryParse('${data['slots']}') ?? 1),
      powerKw:
          data['powerKw'] is num ? (data['powerKw'] as num).toDouble() : null,
      connectorTypes:
          (data['connectorTypes'] is List)
              ? List<String>.from(
                (data['connectorTypes'] as List).map((e) => e.toString()),
              )
              : const [],
    );
  }
}
