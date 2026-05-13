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

  static const int slotStepMins = 30;

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
