import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/booking.dart';
import '../models/charger.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.charger});

  final Charger charger;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  DateTime _day = DateTime.now();
  int _durationMins = 30;
  DateTime? _selectedStart;
  bool _submittingBooking = false;

  static const int _slotStepMins = 30;
  static const int _openHour = 8;
  static const int _closeHour = 20;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtTime(DateTime d) =>
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  List<DateTime> _buildSlots(DateTime day) {
    final d0 = _startOfDay(day);
    final start = DateTime(d0.year, d0.month, d0.day, _openHour);
    final end = DateTime(d0.year, d0.month, d0.day, _closeHour);
    final lastStart = end.subtract(Duration(minutes: _durationMins));

    final slots = <DateTime>[];
    for (
      var t = start;
      !t.isAfter(lastStart);
      t = t.add(const Duration(minutes: _slotStepMins))
    ) {
      slots.add(t);
    }
    return slots;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month + 6, 0),
    );
    if (picked != null) {
      setState(() {
        _day = picked;
        _selectedStart = null;
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookingsForDay() {
    final d0 = _startOfDay(_day);
    final d1 = d0.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('chargerId', isEqualTo: widget.charger.id)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(d0))
        .where('startTime', isLessThan: Timestamp.fromDate(d1))
        .snapshots();
  }

  bool _overlaps(
    DateTime slotStart,
    int durationMins,
    DateTime bookedStart,
    DateTime bookedEnd,
  ) {
    final slotEnd = slotStart.add(Duration(minutes: durationMins));
    return slotStart.isBefore(bookedEnd) && slotEnd.isAfter(bookedStart);
  }

  Future<void> _confirmBooking(Map<DateTime, int> availabilityMap) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _selectedStart == null) return;

    final remaining = availabilityMap[_selectedStart!] ?? 0;

    if (remaining <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('slotAlreadyFull'))));
      return;
    }

    final start = _selectedStart!;
    final end = start.add(Duration(minutes: _durationMins));

    setState(() => _submittingBooking = true);

    try {
      await _bookingService.createBooking(
        Booking(
          id: '',
          userId: user.uid,
          chargerId: widget.charger.id,
          chargerName: widget.charger.name,
          city: widget.charger.city,
          startTime: start,
          endTime: end,
          durationMins: _durationMins,
          status: 'booked',
        ),
        slotCapacity: widget.charger.slots,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on BookingConflictException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('slotAlreadyFull'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('couldNotConfirmBooking'))),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _buildSlots(_day);
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('bookASlot')), centerTitle: true),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              _selectedStart == null || _submittingBooking
                  ? null
                  : () async {
                    final snap = await _bookingsForDay().first;
                    final bookings = snap.docs.map((d) => d.data()).toList();

                    final availabilityMap = <DateTime, int>{};

                    for (final slot in slots) {
                      int overlaps = 0;

                      for (final b in bookings) {
                        final bStart = (b['startTime'] as Timestamp).toDate();
                        final bEnd = (b['endTime'] as Timestamp).toDate();

                        if (_overlaps(slot, _durationMins, bStart, bEnd)) {
                          overlaps++;
                        }
                      }

                      availabilityMap[slot] = widget.charger.slots - overlaps;
                    }

                    await _confirmBooking(availabilityMap);
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child:
              _submittingBooking
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(l10n.t('confirmBooking')),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔥 CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.ev_station),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.charger.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${widget.charger.city} - ${l10n.slotsCount(widget.charger.slots)}",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🔥 DATE + DURATION
            Column(
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "${_day.year}-${_day.month.toString().padLeft(2, '0')}-${_day.day.toString().padLeft(2, '0')}",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 30, label: Text("30m")),
                    ButtonSegment(value: 60, label: Text("60m")),
                    ButtonSegment(value: 90, label: Text("90m")),
                  ],
                  selected: {_durationMins},
                  onSelectionChanged: (s) {
                    setState(() {
                      _durationMins = s.first;
                      _selectedStart = null;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.t('availableTimeSlots')),
            ),

            const SizedBox(height: 10),

            /// 🔥 GRID
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _bookingsForDay(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookings =
                      snap.data!.docs.map((d) => d.data()).toList();

                  final availabilityMap = <DateTime, int>{};

                  for (final slot in slots) {
                    int overlaps = 0;

                    for (final b in bookings) {
                      final bStart = (b['startTime'] as Timestamp).toDate();
                      final bEnd = (b['endTime'] as Timestamp).toDate();

                      if (_overlaps(slot, _durationMins, bStart, bEnd)) {
                        overlaps++;
                      }
                    }

                    availabilityMap[slot] = widget.charger.slots - overlaps;
                  }

                  return GridView.builder(
                    itemCount: slots.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.3,
                        ),
                    itemBuilder: (context, i) {
                      final slot = slots[i];
                      final availability = availabilityMap[slot]!;

                      return _SlotTile(
                        label: _fmtTime(slot),
                        selected: _selectedStart == slot,
                        availability: availability,
                        onTap:
                            availability <= 0
                                ? null
                                : () {
                                  setState(() => _selectedStart = slot);
                                },
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

/// 🔥 SLOT TILE
class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.label,
    required this.selected,
    required this.availability,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final int availability;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = context.evayPalette;
    final l10n = context.l10n;

    final isFull = availability <= 0;
    final isLow = availability == 1;

    Color bg;
    Color text;
    Color border;

    if (isFull) {
      bg = cs.surfaceContainerHighest;
      text = palette.neutral;
      border = cs.outlineVariant;
    } else if (selected) {
      bg = cs.primary;
      text = cs.onPrimary;
      border = cs.primary;
    } else if (isLow) {
      bg = palette.warningBackground;
      text = const Color(0xFF9A6A00);
      border = palette.warningBorder;
    } else {
      bg = palette.success.withValues(alpha: 0.15);
      text = palette.success;
      border = palette.success;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: text),
            ),
            Text(
              isFull
                  ? l10n.t('full')
                  : isLow
                  ? l10n.t('oneLeft')
                  : l10n.freeCount(availability),
              style: TextStyle(fontSize: 10, color: text),
            ),
          ],
        ),
      ),
    );
  }
}
