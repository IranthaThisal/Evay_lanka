import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String chargerId;
  final String chargerName;
  final String city;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMins;
  final String status;
  final List<String> slotKeys;

  Booking({
    required this.id,
    required this.userId,
    required this.chargerId,
    required this.chargerName,
    required this.city,
    required this.startTime,
    required this.endTime,
    required this.durationMins,
    required this.status,
    this.slotKeys = const [],
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'chargerId': chargerId,
    'chargerName': chargerName,
    'city': city,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'durationMins': durationMins,
    'status': status,
    'slotKeys': slotKeys,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static Booking fromDoc(String id, Map<String, dynamic> data) => Booking(
    id: id,
    userId: data['userId'] as String,
    chargerId: data['chargerId'] as String,
    chargerName: data['chargerName'] as String,
    city: (data['city'] ?? '') as String,
    startTime: (data['startTime'] as Timestamp).toDate(),
    endTime: (data['endTime'] as Timestamp).toDate(),
    durationMins: (data['durationMins'] as num?)?.toInt() ?? 0,
    status: data['status'] as String,
    slotKeys:
        (data['slotKeys'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .toList() ??
        const [],
  );
}
