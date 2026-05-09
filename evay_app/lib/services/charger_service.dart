import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/charger.dart';

class ChargerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Charger>> watchChargers() {
    return _db.collection('chargers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) => Charger.tryFromDoc(d))
          .whereType<Charger>()
          .toList();
    });
  }
}
