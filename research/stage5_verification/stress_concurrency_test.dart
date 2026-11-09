import 'dart:async';
import 'dart:math' as math;

class InMemoryReservationEngine {
  InMemoryReservationEngine({required this.chargerBayCapacity});

  final Map<String, int> chargerBayCapacity;
  final Map<String, int> slotBookedCount = {};
  final Map<String, List<String>> waitlists = {};
  final List<Map<String, dynamic>> bookings = [];

  int totalAttempts = 0;
  int successfulBookings = 0;
  int conflictRejections = 0;

  Future<bool> bookSlot({
    required String bookingId,
    required String userId,
    required String chargerId,
    required DateTime slotStart,
    required int durationMins,
  }) async {
    totalAttempts++;
    final capacity = chargerBayCapacity[chargerId] ?? 1;
    final slotKey = '${chargerId}_${slotStart.toIso8601String()}';

    // Simulate jitter (0-5ms)
    await Future.delayed(Duration(milliseconds: math.Random().nextInt(6)));

    // Atomic section
    final currentCount = slotBookedCount[slotKey] ?? 0;
    if (currentCount >= capacity) {
      conflictRejections++;
      throw Exception('BookingConflictException');
    }

    slotBookedCount[slotKey] = currentCount + 1;
    bookings.add({
      'id': bookingId,
      'userId': userId,
      'chargerId': chargerId,
      'slotKey': slotKey,
      'startTime': slotStart,
      'endTime': slotStart.add(Duration(minutes: durationMins)),
      'status': 'booked',
    });
    successfulBookings++;
    return true;
  }
}

void main() async {
  print('=== REPEATED MULTI-RUN CONCURRENCY STRESS AUDIT ===');
  const numRuns = 100;
  var zeroToleranceViolations = 0;
  var totalSuccesses = 0;
  var totalRejections = 0;

  for (var run = 1; run <= numRuns; run++) {
    final engine = InMemoryReservationEngine(
      chargerBayCapacity: {'station_1': 2},
    );
    final slotTime = DateTime(2026, 11, 10, 14, 0);
    const concurrentUsers = 50;

    final futures = <Future<String>>[];
    for (var i = 1; i <= concurrentUsers; i++) {
      final userId = 'driver_$i';
      futures.add(
        engine
            .bookSlot(
              bookingId: 'bk_${run}_$i',
              userId: userId,
              chargerId: 'station_1',
              slotStart: slotTime,
              durationMins: 30,
            )
            .then((_) => 'SUCCESS')
            .catchError((_) => 'REJECTED'),
      );
    }

    final results = await Future.wait(futures);
    final successes = results.where((r) => r == 'SUCCESS').length;
    final rejections = results.where((r) => r == 'REJECTED').length;

    totalSuccesses += successes;
    totalRejections += rejections;

    if (successes != 2 || rejections != 48) {
      zeroToleranceViolations++;
    }
  }

  print('Total Experimental Runs: $numRuns');
  print('Runs with exactly 2 successes and 48 rejections: ${numRuns - zeroToleranceViolations}/$numRuns');
  print('Overbooking / Double-Booking Violations: $zeroToleranceViolations');
  print('Total Successes across all runs: $totalSuccesses (Expected: ${numRuns * 2})');
  print('Total Rejections across all runs: $totalRejections (Expected: ${numRuns * 48})');
  print('Compliance Rate: ${((numRuns - zeroToleranceViolations) / numRuns * 100).toStringAsFixed(1)}%');
}
