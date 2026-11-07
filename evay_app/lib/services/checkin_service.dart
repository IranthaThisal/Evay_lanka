import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/charger_checkin.dart';

class CheckInService {
  final _db = FirebaseFirestore.instance;

  static final Map<String, double> _scoreCache = {};
  static DateTime? _lastCacheTime;
  static const Duration _cacheTtl = Duration(minutes: 2);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('charger_checkins');

  /// Submits a driver check-in to Firestore
  Future<void> submitCheckIn(ChargerCheckIn checkIn) async {
    final ref = checkIn.id.isEmpty ? _col.doc() : _col.doc(checkIn.id);
    await ref.set(checkIn.toMap());
    // Invalidate cached score for this charger so next route uses fresh data
    _scoreCache.remove(checkIn.chargerId);
  }

  /// Real-time stream of recent check-ins for a specific charger
  Stream<List<ChargerCheckIn>> watchRecentCheckIns(
    String chargerId, {
    int limit = 10,
  }) {
    return _col
        .where('chargerId', isEqualTo: chargerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => ChargerCheckIn.fromDoc(doc.id, doc.data()))
              .toList(growable: false);
        });
  }

  /// Real-time stream calculating the live LankaScore (0-10) and reliability metrics
  Stream<ChargerReliabilitySummary> watchReliability(String chargerId) {
    return watchRecentCheckIns(chargerId, limit: 12).map((checkIns) {
      final summary = calculateReliabilitySummary(checkIns);
      _scoreCache[chargerId] = summary.score;
      return summary;
    });
  }

  /// Computes the LankaScore and reliability summary from a list of check-ins
  static ChargerReliabilitySummary calculateReliabilitySummary(
    List<ChargerCheckIn> checkIns,
  ) {
    if (checkIns.isEmpty) {
      // Default baseline for stations with no community reports yet
      return const ChargerReliabilitySummary(
        score: 9.0,
        totalCheckIns: 0,
        successCount: 0,
        failureCount: 0,
      );
    }

    var successes = 0;
    var failures = 0;
    DateTime? lastSuccess;
    CheckInIssue? lastIssue;
    DateTime? lastIssueTime;

    for (final c in checkIns) {
      if (c.outcome == CheckInOutcome.success) {
        successes++;
        if (lastSuccess == null || c.createdAt.isAfter(lastSuccess)) {
          lastSuccess = c.createdAt;
        }
      } else if (c.outcome == CheckInOutcome.couldNotCharge) {
        failures++;
        if (lastIssueTime == null || c.createdAt.isAfter(lastIssueTime)) {
          lastIssue = c.issue;
          lastIssueTime = c.createdAt;
        }
      }
    }

    final totalEvaluated = successes + failures;
    double rawScore =
        totalEvaluated > 0 ? (successes / totalEvaluated) * 10.0 : 9.0;

    // Penalty if an issue was reported within the last 4 hours
    if (lastIssueTime != null &&
        DateTime.now().difference(lastIssueTime).inHours < 4) {
      rawScore = (rawScore * 0.6).clamp(1.0, 6.0);
    }

    return ChargerReliabilitySummary(
      score: (rawScore * 10).roundToDouble() / 10.0,
      totalCheckIns: checkIns.length,
      successCount: successes,
      failureCount: failures,
      lastSuccessfulCheckIn: lastSuccess,
      lastIssue: lastIssue,
      lastIssueTime: lastIssueTime,
    );
  }

  /// Batch fetches reliability scores for smart routing with in-memory TTL caching
  Future<Map<String, double>> getReliabilityScores(
    List<String> chargerIds,
  ) async {
    final result = <String, double>{};
    if (chargerIds.isEmpty) return result;

    final now = DateTime.now();
    final cacheValid =
        _lastCacheTime != null && now.difference(_lastCacheTime!) < _cacheTtl;

    final uncachedIds = <String>[];
    for (final id in chargerIds) {
      final cached = cacheValid ? _scoreCache[id] : null;
      if (cached != null) {
        result[id] = cached;
      } else {
        uncachedIds.add(id);
      }
    }

    if (uncachedIds.isEmpty) return result;

    try {
      // Firestore whereIn supports up to 30 items per query
      final queryIds = uncachedIds.take(30).toList(growable: false);
      final snap = await _col
          .where('chargerId', whereIn: queryIds)
          .orderBy('createdAt', descending: true)
          .limit(60)
          .get();

      final grouped = <String, List<ChargerCheckIn>>{};
      for (final doc in snap.docs) {
        final c = ChargerCheckIn.fromDoc(doc.id, doc.data());
        (grouped[c.chargerId] ??= <ChargerCheckIn>[]).add(c);
      }

      for (final id in uncachedIds) {
        final list = grouped[id] ?? const <ChargerCheckIn>[];
        final score = calculateReliabilitySummary(list).score;
        result[id] = score;
        _scoreCache[id] = score;
      }
      _lastCacheTime = now;
    } catch (_) {
      // Default to 9.0 baseline if query limits or offline
      for (final id in uncachedIds) {
        result[id] = _scoreCache[id] ?? 9.0;
      }
    }

    return result;
  }
}
