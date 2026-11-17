import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/chargenet_seed.dart';
import '../models/charger.dart';
import 'chargenet_service.dart';

enum ChargerDataSourceStatus {
  seedSnapshot('Offline Seed (315 Stations)'),
  liveChargeNet('Live ChargeNET Sync'),
  hybridSynced('Live ChargeNET + Cloud');

  const ChargerDataSourceStatus(this.label);
  final String label;
}

/// Hybrid Charging Station Provider.
///
/// Ensures uninterrupted, zero-latency station discovery by:
/// 1. Immediately emitting the 315 verified Sri Lankan charging stations from local seed data.
/// 2. Asynchronously & periodically querying the live ChargeNET API (ShowAllChargePointData)
///    to update real-time slot availability (AVAILABLE vs OCCUPIED).
/// 3. Merging with Cloud Firestore for crowdsourced LankaScore check-ins and custom stations.
class ChargerService {
  ChargerService({
    FirebaseFirestore? firestore,
    ChargeNetService? chargeNetService,
    this.pollInterval = const Duration(seconds: 90),
  })  : _db = firestore,
        _chargeNetService = chargeNetService ?? ChargeNetService();

  final FirebaseFirestore? _db;
  final ChargeNetService _chargeNetService;
  final Duration pollInterval;

  final ValueNotifier<ChargerDataSourceStatus> statusNotifier =
      ValueNotifier<ChargerDataSourceStatus>(
        ChargerDataSourceStatus.seedSnapshot,
      );

  DateTime? _lastLiveSyncAt;
  DateTime? get lastLiveSyncAt => _lastLiveSyncAt;

  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  /// Returns a stream of charging stations, starting immediately with local seed data
  /// and refreshing periodically as live ChargeNET and Firestore updates arrive.
  Stream<List<Charger>> watchChargers() {
    late StreamController<List<Charger>> controller;
    StreamSubscription? firestoreSub;
    Timer? pollTimer;
    var hasLiveSync = false;
    var hasFirestoreSync = false;

    // In-memory indexed cache by unique station ID
    final Map<String, Charger> chargerMap = {
      for (final c in kChargeNetSeedChargers) c.id: c,
    };

    void updateStatus() {
      if (hasLiveSync && hasFirestoreSync) {
        statusNotifier.value = ChargerDataSourceStatus.hybridSynced;
      } else if (hasLiveSync) {
        statusNotifier.value = ChargerDataSourceStatus.liveChargeNet;
      } else {
        statusNotifier.value = ChargerDataSourceStatus.seedSnapshot;
      }
    }

    void emitMerged() {
      if (!controller.isClosed) {
        controller.add(chargerMap.values.toList(growable: false));
      }
    }

    Future<void> pollChargeNet() async {
      try {
        final liveChargers = await _chargeNetService.fetchChargers();
        if (liveChargers.isNotEmpty) {
          for (final c in liveChargers) {
            chargerMap[c.id] = c;
          }
          hasLiveSync = true;
          _lastLiveSyncAt = DateTime.now();
          updateStatus();
          emitMerged();
        }
      } catch (_) {
        // Offline or unreachable: seed & cached state continue serving seamlessly.
      }
    }

    controller = StreamController<List<Charger>>(
      onListen: () {
        // Step 1: Immediately emit local seed dataset (315 stations)
        emitMerged();

        // Step 2: Query live ChargeNET API immediately & schedule periodic polling
        pollChargeNet();
        pollTimer = Timer.periodic(pollInterval, (_) => pollChargeNet());

        // Step 3: Listen to Firestore collection for crowdsourced / community updates
        try {
          firestoreSub = _firestore.collection('chargers').snapshots().listen(
            (snapshot) {
              final firestoreChargers = snapshot.docs
                  .map((d) => Charger.tryFromDoc(d))
                  .whereType<Charger>();
              var updated = false;
              for (final c in firestoreChargers) {
                chargerMap[c.id] = c;
                updated = true;
              }
              hasFirestoreSync = true;
              updateStatus();
              if (updated) {
                emitMerged();
              }
            },
            onError: (_) {
              // Ignore Firestore connection errors; seed and live ChargeNET data continue to serve.
            },
          );
        } catch (_) {
          // Firestore not initialized or unavailable in unit test environment
        }
      },
      onCancel: () {
        pollTimer?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }
}
