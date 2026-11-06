import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';

class BookingConflictException implements Exception {
  const BookingConflictException();

  @override
  String toString() => 'BookingConflictException';
}

class BookingService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _capacityCol =>
      _db.collection('booking_capacity');
  CollectionReference<Map<String, dynamic>> get _waitlistCol =>
      _db.collection('booking_waitlist');

  static const int slotStepMins = 30;

  /// Intelligent Slot Duration Recommendation:
  /// Auto-calculates the exact minutes needed to reach 80% charge based on:
  /// Charging Time (mins) = (((80% - Current%) * Battery Capacity kWh) / (Station Power kW * 0.90 efficiency)) * 60
  static int calculateRecommendedDurationMins({
    required double batteryCapacityKwh,
    required double currentBatteryPercent,
    required double stationPowerKw,
    double targetPercent = 80.0,
    double chargingEfficiency = 0.90,
  }) {
    if (stationPowerKw <= 0 || batteryCapacityKwh <= 0) return 30;

    final clampedCurrent = currentBatteryPercent.clamp(0.0, 100.0);
    if (clampedCurrent >= targetPercent) {
      return 15; // Minimum top-up session
    }

    final energyNeededKwh =
        ((targetPercent - clampedCurrent) / 100.0) * batteryCapacityKwh;
    final chargingHours =
        energyNeededKwh / (stationPowerKw * chargingEfficiency);
    final exactMinutes = chargingHours * 60.0;

    return exactMinutes.round().clamp(15, 180);
  }

  /// Rounds duration to the nearest practical booking increment (e.g. 15, 30, 45, 60 mins)
  static int roundToSlotStep(int rawMinutes, {int stepMins = 15}) {
    final steps = (rawMinutes / stepMins).ceil();
    return math.max(stepMins, steps * stepMins);
  }

  static DateTime normalizeSlotStart(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      (value.minute ~/ slotStepMins) * slotStepMins,
    );
  }

  static List<DateTime> slotTimesForRange(DateTime start, DateTime end) {
    final normalizedStart = normalizeSlotStart(start);
    final slots = <DateTime>[];

    for (
      var time = normalizedStart;
      time.isBefore(end);
      time = time.add(const Duration(minutes: slotStepMins))
    ) {
      slots.add(time);
    }

    return slots;
  }

  static String slotKey(String chargerId, DateTime slotStart) {
    final utc = slotStart.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    return [chargerId, '$year$month$day', '$hour$minute'].join('_');
  }

  /// Automatic Expired Slot Recycling:
  /// Background cleanup of past slots in Firestore to prevent stale lockouts.
  Future<int> recycleExpiredSlots({String? chargerId}) async {
    try {
      final now = DateTime.now();
      final nowTs = Timestamp.fromDate(now);
      var recycledCount = 0;

      // 1. Recycle bookings that have passed their endTime
      var bookingsQuery = _col
          .where('status', isEqualTo: 'booked')
          .where('endTime', isLessThan: nowTs);
      if (chargerId != null) {
        bookingsQuery = bookingsQuery.where('chargerId', isEqualTo: chargerId);
      }

      final expiredBookings = await bookingsQuery.limit(50).get();
      final batch = _db.batch();

      for (final doc in expiredBookings.docs) {
        batch.update(doc.reference, {
          'status': 'completed',
          'recycledAt': FieldValue.serverTimestamp(),
        });
        recycledCount++;
      }

      // 2. Clean up stale capacity records older than 2 hours to avoid stale locks
      final staleThreshold =
          Timestamp.fromDate(now.subtract(const Duration(hours: 2)));
      var capacityQuery = _capacityCol.where(
        'slotStartTime',
        isLessThan: staleThreshold,
      );
      if (chargerId != null) {
        capacityQuery = capacityQuery.where('chargerId', isEqualTo: chargerId);
      }

      final staleCapacity = await capacityQuery.limit(50).get();
      for (final doc in staleCapacity.docs) {
        batch.delete(doc.reference);
      }

      if (expiredBookings.docs.isNotEmpty || staleCapacity.docs.isNotEmpty) {
        await batch.commit();
      }

      return recycledCount;
    } catch (_) {
      // Best-effort background cleanup; do not interrupt user operations
      return 0;
    }
  }

  /// Smart Waitlist: Join queue for a full slot
  Future<void> joinWaitlist({
    required String chargerId,
    required String chargerName,
    required String city,
    required DateTime slotStartTime,
    required String userId,
  }) async {
    final key = slotKey(chargerId, slotStartTime);
    final docRef = _waitlistCol.doc('${userId}_$key');

    await docRef.set({
      'userId': userId,
      'chargerId': chargerId,
      'chargerName': chargerName,
      'city': city,
      'slotStartTime': Timestamp.fromDate(slotStartTime),
      'slotKey': key,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Leave waitlist
  Future<void> leaveWaitlist({
    required String chargerId,
    required DateTime slotStartTime,
    required String userId,
  }) async {
    final key = slotKey(chargerId, slotStartTime);
    await _waitlistCol.doc('${userId}_$key').delete();
  }

  /// Watch user's waitlist entries
  Stream<List<Map<String, dynamic>>> watchUserWaitlist(String userId) {
    return _waitlistCol
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['waiting', 'available'])
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  /// Alert waitlisted drivers when an occupied slot frees up
  Future<void> notifyWaitlistOnSlotFreed({
    required String chargerId,
    required DateTime slotStartTime,
  }) async {
    try {
      final key = slotKey(chargerId, slotStartTime);
      final snap = await _waitlistCol
          .where('slotKey', isEqualTo: key)
          .where('status', isEqualTo: 'waiting')
          .orderBy('createdAt')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({
          'status': 'available',
          'notifiedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<void> createBooking(
    Booking booking, {
    required int slotCapacity,
  }) async {
    final bookingRef = booking.id.isEmpty ? _col.doc() : _col.doc(booking.id);
    final slotStarts = slotTimesForRange(booking.startTime, booking.endTime);
    final slotKeys =
        slotStarts
            .map((slotStart) => slotKey(booking.chargerId, slotStart))
            .toList();
    final bookingWithSlots = Booking(
      id: bookingRef.id,
      userId: booking.userId,
      chargerId: booking.chargerId,
      chargerName: booking.chargerName,
      city: booking.city,
      startTime: booking.startTime,
      endTime: booking.endTime,
      durationMins: booking.durationMins,
      status: booking.status,
      slotKeys: slotKeys,
    );

    try {
      await _db.runTransaction((transaction) async {
        final capacityDocs = <_CapacityReservation>[];

        for (final slotStart in slotStarts) {
          final key = slotKey(booking.chargerId, slotStart);
          final ref = _capacityCol.doc(key);
          final snap = await transaction.get(ref);
          final bookedCount =
              (snap.data()?['bookedCount'] as num?)?.toInt() ?? 0;

          if (bookedCount >= slotCapacity) {
            throw const BookingConflictException();
          }

          capacityDocs.add(
            _CapacityReservation(
              ref: ref,
              slotStart: slotStart,
              bookedCount: bookedCount,
            ),
          );
        }

        for (final capacity in capacityDocs) {
          transaction.set(capacity.ref, {
            'chargerId': booking.chargerId,
            'slotStartTime': Timestamp.fromDate(capacity.slotStart),
            'bookedCount': capacity.bookedCount + 1,
            'capacity': slotCapacity,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        transaction.set(bookingRef, bookingWithSlots.toMap());
      });
    } on FirebaseException catch (error) {
      if (!_shouldFallbackToDirectBooking(error)) rethrow;
      await _createBookingWithoutCapacityTracking(
        bookingRef: bookingRef,
        booking: bookingWithSlots,
        slotCapacity: slotCapacity,
      );
    }
  }

  bool _shouldFallbackToDirectBooking(FirebaseException error) {
    return error.code == 'permission-denied' ||
        error.code == 'failed-precondition' ||
        error.code == 'not-found';
  }

  Future<void> _createBookingWithoutCapacityTracking({
    required DocumentReference<Map<String, dynamic>> bookingRef,
    required Booking booking,
    required int slotCapacity,
  }) async {
    final dayStart = DateTime(
      booking.startTime.year,
      booking.startTime.month,
      booking.startTime.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));
    final slotStarts = slotTimesForRange(booking.startTime, booking.endTime);

    final snapshot =
        await _col
            .where('chargerId', isEqualTo: booking.chargerId)
            .where(
              'startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
            )
            .where('startTime', isLessThan: Timestamp.fromDate(dayEnd))
            .get();

    for (final slotStart in slotStarts) {
      final slotEnd = slotStart.add(const Duration(minutes: slotStepMins));
      var overlapCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bookedStart = (data['startTime'] as Timestamp?)?.toDate();
        final bookedEnd = (data['endTime'] as Timestamp?)?.toDate();
        if (bookedStart == null || bookedEnd == null) continue;

        final overlaps =
            slotStart.isBefore(bookedEnd) && slotEnd.isAfter(bookedStart);
        if (overlaps) {
          overlapCount++;
        }
      }

      if (overlapCount >= slotCapacity) {
        throw const BookingConflictException();
      }
    }

    await bookingRef.set(booking.toMap());
  }
}

class _CapacityReservation {
  const _CapacityReservation({
    required this.ref,
    required this.slotStart,
    required this.bookedCount,
  });

  final DocumentReference<Map<String, dynamic>> ref;
  final DateTime slotStart;
  final int bookedCount;
}
