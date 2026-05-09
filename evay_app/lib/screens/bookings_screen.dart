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
  final df = DateFormat('EEE, MMM d • HH:mm');

  DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = authSnap.data;
        if (user == null) {
          return Center(child: Text(context.l10n.t('pleaseLoginBookings')));
        }

        // ✅ IMPORTANT: No orderBy here → avoids composite index requirement
        final query = FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text(context.l10n.errorWithMessage(snap.error!)));
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

            // Client-side sort by startTime (newest first)
            final sorted = [...docs];
            sorted.sort((a, b) {
              final aStart = _asDate(a.data()['startTime']);
              final bStart = _asDate(b.data()['startTime']);
              return bStart.compareTo(aStart);
            });

            final now = DateTime.now();

            final upcoming = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final history = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            for (final d in sorted) {
              final data = d.data();
              final end = _asDate(data['endTime']);
              if (end.isAfter(now)) {
                upcoming.add(d);
              } else {
                history.add(d);
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
                            df: df,
                            emptyText: context.l10n.t('noUpcomingBookings'),
                          ),
                          _BookingsList(
                            docs: history,
                            df: df,
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
    required this.emptyText,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final DateFormat df;
  final String emptyText;

  DateTime _asDate(dynamic v) {
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

        final timeText =
            '${df.format(start)} → ${DateFormat('HH:mm').format(end)}';

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
