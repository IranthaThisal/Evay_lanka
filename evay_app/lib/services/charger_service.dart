import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/chargenet_seed.dart';
import '../models/charger.dart';
import 'chargenet_service.dart';

/// Hybrid Charging Station Provider.
///
/// Ensures uninterrupted, zero-latency station discovery by:
/// 1. Immediately emitting the 315 verified Sri Lankan charging stations from local seed data.
/// 2. Asynchronously querying the live ChargeNET API (ShowAllChargePointData) to update
///    real-time slot availability (AVAILABLE vs OCCUPIED).
/// 3. Merging with Cloud Firestore for crowdsourced LankaScore check-ins and custom stations.
class ChargerService {
  ChargerService({
    FirebaseFirestore? firestore,
    ChargeNetService? chargeNetService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _chargeNetService = chargeNetService ?? ChargeNetService();

  final FirebaseFirestore _db;
  final ChargeNetService _chargeNetService;

  /// Returns a stream of charging stations, starting immediately with local seed data
  /// and refreshing as live ChargeNET and Firestore updates arrive.
  Stream<List<Charger>> watchChargers() {
    late StreamController<List<Charger>> controller;
    StreamSubscription? firestoreSub;

    // In-memory indexed cache by unique station ID
    final Map<String, Charger> chargerMap = {
      for (final c in kChargeNetSeedChargers) c.id: c,
    };

    void emitMerged() {
      if (!controller.isClosed) {
        controller.add(chargerMap.values.toList(growable: false));
      }
    }

    controller = StreamController<List<Charger>>(
      onListen: () {
        // Step 1: Immediately emit local seed dataset (315 stations)
        emitMerged();

        // Step 2: Query live ChargeNET API for real-time status and power updates
        _chargeNetService.fetchChargers().then((liveChargers) {
          if (liveChargers.isNotEmpty) {
            for (final c in liveChargers) {
              chargerMap[c.id] = c;
            }
            emitMerged();
          }
        }).catchError((_) {
          // If network is offline or ChargeNET API is unreachable,
          // the local 315 seed stations continue serving seamlessly.
        });

        // Step 3: Listen to Firestore collection for crowdsourced / community updates
        try {
          firestoreSub = _db.collection('chargers').snapshots().listen(
            (snapshot) {
              final firestoreChargers = snapshot.docs
                  .map((d) => Charger.tryFromDoc(d))
                  .whereType<Charger>();
              var updated = false;
              for (final c in firestoreChargers) {
                chargerMap[c.id] = c;
                updated = true;
              }
              if (updated) {
                emitMerged();
              }
            },
            onError: (_) {
              // Ignore Firestore connection errors; seed and live ChargeNET data continue to serve.
            },
          );
        } catch (_) {
          // Firestore not initialized or unavailable
        }
      },
      onCancel: () {
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }
}
