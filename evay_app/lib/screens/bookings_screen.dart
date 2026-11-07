import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  static final DateFormat _dateTimeFormat = DateFormat('EEE, MMM d • HH:mm');
  static final DateFormat _timeOnlyFormat = DateFormat('HH:mm');

  late final Stream<User?> _authStream =
      FirebaseAuth.instance.authStateChanges();
  String? _cachedUid;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _bookingsStream;

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamForUser(String uid) {
    if (_cachedUid != uid || _bookingsStream == null) {
      _cachedUid = uid;
      _bookingsStream =
          FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: uid)
              .snapshots();
    }
    return _bookingsStream!;
  }

  static DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = authSnap.data;
        if (user == null) {
          return Center(child: Text(context.l10n.t('pleaseLoginBookings')));
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _streamForUser(user.uid),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text(context.l10n.errorWithMessage(snap.error!)),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Text(
                  context.l10n.t('noBookingsYet'),
                  textAlign: TextAlign.center,
                ),
              );
            }

            // Pre-extract timestamps once and sort (newest first)
            final decorated = <
              (
                QueryDocumentSnapshot<Map<String, dynamic>> doc,
                DateTime start,
                DateTime end,
              )
            >[
              for (final d in docs)
                (
                  d,
                  _asDate(d.data()['startTime']),
                  _asDate(d.data()['endTime']),
                ),
            ]..sort((a, b) => b.$2.compareTo(a.$2));

            final now = DateTime.now();

            final upcoming = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final history = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            for (final item in decorated) {
              if (item.$3.isAfter(now)) {
                upcoming.add(item.$1);
              } else {
                history.add(item.$1);
              }
            }

            return DefaultTabController(
              length: 2,
              child: SafeArea(
                top: true,
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: TabBar(
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            ),
                            insets: const EdgeInsets.symmetric(horizontal: 32),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor:
                              Theme.of(context).colorScheme.onSurface,
                          tabs: [
                            Tab(text: context.l10n.t('upcoming')),
                            Tab(text: context.l10n.t('history')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _BookingsList(
                            docs: upcoming,
                            df: _dateTimeFormat,
                            timeFormat: _timeOnlyFormat,
                            emptyText: context.l10n.t('noUpcomingBookings'),
                          ),
                          _BookingsList(
                            docs: history,
                            df: _dateTimeFormat,
                            timeFormat: _timeOnlyFormat,
                            emptyText: context.l10n.t('noBookingHistory'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BookingsList extends StatelessWidget {
  const _BookingsList({
    required this.docs,
    required this.df,
    required this.timeFormat,
    required this.emptyText,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final DateFormat df;
  final DateFormat timeFormat;
  final String emptyText;

  static DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.evayPalette;
    final l10n = context.l10n;

    if (docs.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final data = docs[i].data();

        final chargerName =
            (data['chargerName'] ?? l10n.t('unknownCharger')).toString();
        final city = (data['city'] ?? '').toString();
        final status = (data['status'] ?? 'booked').toString();
        final statusLabel =
            status == 'booked'
                ? l10n.t('booked')
                : status == 'cancelled'
                ? l10n.t('cancelled')
                : status;

        final start = _asDate(data['startTime']);
        final end = _asDate(data['endTime']);

        final timeText = '${df.format(start)} → ${timeFormat.format(end)}';

        final statusColor =
            status == 'booked'
                ? palette.success
                : status == 'cancelled'
                ? palette.danger
                : palette.neutral;

        return Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.ev_station),
            title: Text(chargerName),
            subtitle: Text(city.isEmpty ? timeText : '$city\n$timeText'),
            isThreeLine: city.isNotEmpty,
            trailing: Text(
              statusLabel,
              style: TextStyle(fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        );
      },
    );
  }
}
