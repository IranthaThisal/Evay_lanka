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

  // Intelligent Recommendation State
  double _batteryCapacityKwh = 50.0;
  double _currentBatteryPercent = 25.0;
  int? _recommendedDurationMins;
  int? _recommendedStepMins;

  static const int _slotStepMins = 30;
  static const int _openHour = 8;
  static const int _closeHour = 20;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtTime(DateTime d) =>
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndCalculateRecommendation();
    // Automatic Expired Slot Recycling on screen entry
    _bookingService.recycleExpiredSlots(chargerId: widget.charger.id);
  }

  Future<void> _loadUserProfileAndCalculateRecommendation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data() ?? {};
        final cap = (data['batteryKwh'] as num?)?.toDouble() ??
            (data['batteryCapacityKwh'] as num?)?.toDouble();
        final pct = (data['batteryPercent'] as num?)?.toDouble();

        if (cap != null && cap > 0) _batteryCapacityKwh = cap;
        if (pct != null && pct > 0) _currentBatteryPercent = pct;
      } catch (_) {}
    }

    _calculateRecommendation();
  }

  void _calculateRecommendation() {
    final power = widget.charger.powerKw ?? 50.0;
    final rawMins = BookingService.calculateRecommendedDurationMins(
      batteryCapacityKwh: _batteryCapacityKwh,
      currentBatteryPercent: _currentBatteryPercent,
      stationPowerKw: power,
    );
    final stepMins = BookingService.roundToSlotStep(rawMins);

    if (mounted) {
      setState(() {
        _recommendedDurationMins = rawMins;
        _recommendedStepMins = stepMins;
        _durationMins = stepMins;
      });
    }
  }

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

      // Clean up waitlist entry if user booked this slot
      await _bookingService.leaveWaitlist(
        chargerId: widget.charger.id,
        slotStartTime: start,
        userId: user.uid,
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

  Future<void> _handleSlotTap({
    required DateTime slot,
    required int availability,
    required Set<String> waitlistedKeys,
  }) async {
    if (availability > 0) {
      setState(() => _selectedStart = slot);
      return;
    }

    // Slot is full: prompt for Smart Waitlist
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final key = BookingService.slotKey(widget.charger.id, slot);
    final isWaitlisted = waitlistedKeys.contains(key);

    if (isWaitlisted) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave Waitlist?'),
          content: Text(
            'You are currently queued for ${_fmtTime(slot)}. Do you want to cancel your alert?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave Queue'),
            ),
          ],
        ),
      );

      if (leave == true) {
        await _bookingService.leaveWaitlist(
          chargerId: widget.charger.id,
          slotStartTime: slot,
          userId: user.uid,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed from waitlist for ${_fmtTime(slot)}.')),
          );
        }
      }
      return;
    }

    final join = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.queue, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Smart Waitlist'),
          ],
        ),
        content: Text(
          'Slot at ${_fmtTime(slot)} is currently full.\n\nJoin the Smart Waitlist? Evay Lanka will immediately alert you when a booking is cancelled or expired slots are recycled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.notifications_active),
            label: const Text('Join Waitlist'),
          ),
        ],
      ),
    );

    if (join == true) {
      await _bookingService.joinWaitlist(
        chargerId: widget.charger.id,
        chargerName: widget.charger.name,
        city: widget.charger.city,
        slotStartTime: slot,
        userId: user.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Joined waitlist for ${_fmtTime(slot)}. You will be alerted when a slot opens up!',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _buildSlots(_day);
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final user = FirebaseAuth.instance.currentUser;

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
            /// 🔥 CHARGER CARD
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
                          "${widget.charger.city} - ${l10n.slotsCount(widget.charger.slots)} (${widget.charger.powerKw?.toStringAsFixed(0) ?? '50'} kW DC)",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// ⚡ INTELLIGENT SLOT DURATION RECOMMENDATION CARD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Duration Recommendation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (_recommendedDurationMins != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '~${_recommendedDurationMins}m to 80%',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Auto-calculated for ${_batteryCapacityKwh.toStringAsFixed(0)} kWh capacity at ${_currentBatteryPercent.toStringAsFixed(0)}% SoC charging at ${widget.charger.powerKw?.toStringAsFixed(0) ?? '50'} kW (90% efficiency).',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Battery: ${_currentBatteryPercent.toInt()}%',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _currentBatteryPercent,
                          min: 5,
                          max: 85,
                          divisions: 16,
                          label: '${_currentBatteryPercent.toInt()}%',
                          onChanged: (val) {
                            setState(() {
                              _currentBatteryPercent = val;
                              _calculateRecommendation();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// 🔥 DATE + DURATION
            Column(
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
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

                const SizedBox(height: 10),

                SegmentedButton<int>(
                  segments: [
                    if (_recommendedStepMins != null &&
                        _recommendedStepMins != 30 &&
                        _recommendedStepMins != 60 &&
                        _recommendedStepMins != 90)
                      ButtonSegment(
                        value: _recommendedStepMins!,
                        label: Text('Auto (${_recommendedStepMins}m)'),
                      ),
                    ButtonSegment(
                      value: 30,
                      label: Text(
                        _recommendedStepMins == 30 ? '30m (Auto)' : '30m',
                      ),
                    ),
                    ButtonSegment(
                      value: 60,
                      label: Text(
                        _recommendedStepMins == 60 ? '60m (Auto)' : '60m',
                      ),
                    ),
                    ButtonSegment(
                      value: 90,
                      label: Text(
                        _recommendedStepMins == 90 ? '90m (Auto)' : '90m',
                      ),
                    ),
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

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.t('availableTimeSlots'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            /// 🔥 SMART WAITLIST & GRID
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream:
                    user == null
                        ? const Stream.empty()
                        : _bookingService.watchUserWaitlist(user.uid),
                builder: (context, waitlistSnap) {
                  final waitlistEntries = waitlistSnap.data ?? [];
                  final waitlistedKeys = {
                    for (final w in waitlistEntries)
                      if (w['status'] == 'waiting' && w['slotKey'] != null)
                        w['slotKey'].toString(),
                  };

                  // Check if any slot for this charger is freed for user
                  DateTime? freedSlotTime;
                  for (final w in waitlistEntries) {
                    if (w['status'] == 'available' &&
                        w['chargerId'] == widget.charger.id &&
                        w['slotStartTime'] != null) {
                      freedSlotTime = (w['slotStartTime'] as Timestamp).toDate();
                      break;
                    }
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

                      return Column(
                        children: [
                          if (freedSlotTime != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF16A34A,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active,
                                    color: Color(0xFF16A34A),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'A queued slot at ${_fmtTime(freedSlotTime)} just opened up! Tap to book now.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: GridView.builder(
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
                                final slotKeyStr = BookingService.slotKey(
                                  widget.charger.id,
                                  slot,
                                );
                                final isWaitlisted = waitlistedKeys.contains(
                                  slotKeyStr,
                                );

                                return _SlotTile(
                                  label: _fmtTime(slot),
                                  selected: _selectedStart == slot,
                                  availability: availability,
                                  isWaitlisted: isWaitlisted,
                                  onTap: () => _handleSlotTap(
                                    slot: slot,
                                    availability: availability,
                                    waitlistedKeys: waitlistedKeys,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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

/// 🔥 SLOT TILE WITH WAITLIST SUPPORT
class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.label,
    required this.selected,
    required this.availability,
    required this.onTap,
    this.isWaitlisted = false,
  });

  final String label;
  final bool selected;
  final int availability;
  final VoidCallback? onTap;
  final bool isWaitlisted;

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

    if (isWaitlisted) {
      bg = palette.warningBackground;
      text = const Color(0xFF9A6A00);
      border = palette.warningBorder;
    } else if (isFull) {
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
              isWaitlisted
                  ? 'Queued'
                  : isFull
                  ? 'Waitlist'
                  : isLow
                  ? l10n.t('oneLeft')
                  : l10n.freeCount(availability),
              style: TextStyle(
                fontSize: 10,
                color: text,
                fontWeight: isWaitlisted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
