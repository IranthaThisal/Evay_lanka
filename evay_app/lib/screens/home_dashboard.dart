import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.onOpenMap,
    required this.onOpenBookings,
    required this.onOpenBattery,
    required this.onOpenCommunity,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenMap;
  final VoidCallback onOpenBookings;
  final VoidCallback onOpenBattery;
  final VoidCallback onOpenCommunity;
  final VoidCallback onOpenProfile;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  double? _draftBatteryPercent;
  bool _savingBatteryPercent = false;
  String? _cachedUid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userDocStream;

  User? get _user => FirebaseAuth.instance.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _getUserDocStream(String uid) {
    if (_cachedUid != uid || _userDocStream == null) {
      _cachedUid = uid;
      _userDocStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }
    return _userDocStream!;
  }

  Future<void> _saveBatteryPercent(double value) async {
    final user = _user;
    if (user == null) return;

    setState(() => _savingBatteryPercent = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'batteryPercent': value.round(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) {
        setState(() => _savingBatteryPercent = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = _user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in again.')));
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _getUserDocStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data?.data() ?? <String, dynamic>{};
            final vehicleMake = (data['vehicleMake'] as String?)?.trim() ?? '';
            final vehicleModel =
                (data['vehicleModel'] as String?)?.trim() ?? '';
            final vehicleName = [
              vehicleMake,
              vehicleModel,
            ].where((part) => part.isNotEmpty).join(' ');
            final batteryKwh = (data['batteryKwh'] as num?)?.toDouble();
            final storedBatteryPercent =
                (data['batteryPercent'] as num?)?.toDouble();
            final efficiencyKmPerKwh =
                (data['efficiencyKmPerKwh'] as num?)?.toDouble() ?? 6.0;
            final batteryPercent = _draftBatteryPercent ?? storedBatteryPercent;
            final hasVehicle = batteryKwh != null && vehicleName.isNotEmpty;
            final hasBatteryStatus = hasVehicle && batteryPercent != null;
            final availableKwh =
                hasBatteryStatus ? batteryKwh * (batteryPercent / 100) : null;
            final estimatedRangeKm =
                availableKwh == null ? null : availableKwh * efficiencyKmPerKwh;
            final currentBatteryPercent = batteryPercent ?? 0.0;
            final chargeSummary = switch (batteryPercent) {
              null => 'Set battery level to calculate live range.',
              >= 75 => 'Healthy charge for most city and daily trips.',
              >= 40 => 'Usable charge. Plan a top-up before a longer trip.',
              _ => 'Low charge. A charging stop is recommended soon.',
            };

            if (_draftBatteryPercent != null &&
                storedBatteryPercent != null &&
                (_draftBatteryPercent! - storedBatteryPercent).abs() < 0.5) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _draftBatteryPercent = null);
                }
              });
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                Text(
                  l10n.t('myEv'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  vehicleName.isEmpty ? l10n.t('evayVehicle') : vehicleName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Image.asset(
                    'assets/images/ev_car.png',
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                _VehicleStatusCard(
                  batteryPercent: batteryPercent,
                  estimatedRangeKm: estimatedRangeKm,
                  availableKwh: availableKwh,
                  efficiencyKmPerKwh: efficiencyKmPerKwh,
                  batteryKwh: batteryKwh,
                  savingBatteryPercent: _savingBatteryPercent,
                  hasVehicle: hasVehicle,
                  onOpenProfile: widget.onOpenProfile,
                  onBatteryPercentChanged: (value) {
                    setState(() => _draftBatteryPercent = value);
                  },
                  onBatteryPercentChangeEnd: _saveBatteryPercent,
                  chargeSummary: chargeSummary,
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(l10n.t('nearestChargingStation')),
                    subtitle: Text(l10n.t('colomboCentralEvStation')),
                    trailing: FilledButton(
                      onPressed: widget.onOpenMap,
                      child: Text(l10n.t('openMap')),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ActionButton(
                      icon: Icons.map,
                      label: l10n.t('map'),
                      onTap: widget.onOpenMap,
                    ),
                    _ActionButton(
                      icon: Icons.book_online,
                      label: l10n.t('bookings'),
                      onTap: widget.onOpenBookings,
                    ),
                    _ActionButton(
                      icon: Icons.battery_full,
                      label: l10n.t('battery'),
                      onTap: widget.onOpenBattery,
                    ),
                    _ActionButton(
                      icon: Icons.group,
                      label: l10n.t('community'),
                      onTap: widget.onOpenCommunity,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'EV insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.bolt_rounded,
                        title: 'Best time to charge',
                        body:
                            hasBatteryStatus && currentBatteryPercent < 35
                                ? 'Charge soon to avoid range stress on the next trip.'
                                : 'Top up in the evening to keep tomorrow\'s ride ready.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.route_rounded,
                        title: 'Trip ready',
                        body:
                            estimatedRangeKm == null
                                ? 'Add battery status to unlock live trip guidance.'
                                : estimatedRangeKm >= 80
                                ? 'Your current range looks good for daily travel.'
                                : 'Your range is limited right now, so plan charging ahead.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _TipBanner(
                  title: 'Vehicle checklist',
                  body:
                      'Keep tyre pressure, battery level, and your nearest charger in check before heading out.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  const _VehicleStatusCard({
    required this.batteryPercent,
    required this.estimatedRangeKm,
    required this.availableKwh,
    required this.efficiencyKmPerKwh,
    required this.batteryKwh,
    required this.savingBatteryPercent,
    required this.hasVehicle,
    required this.onOpenProfile,
    required this.onBatteryPercentChanged,
    required this.onBatteryPercentChangeEnd,
    required this.chargeSummary,
  });

  final double? batteryPercent;
  final double? estimatedRangeKm;
  final double? availableKwh;
  final double efficiencyKmPerKwh;
  final double? batteryKwh;
  final bool savingBatteryPercent;
  final bool hasVehicle;
  final VoidCallback onOpenProfile;
  final ValueChanged<double> onBatteryPercentChanged;
  final ValueChanged<double> onBatteryPercentChangeEnd;
  final String chargeSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sliderValue = (batteryPercent ?? 50).clamp(0.0, 100.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current vehicle status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!hasVehicle)
                  TextButton(
                    onPressed: onOpenProfile,
                    child: const Text('Complete vehicle'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (!hasVehicle)
              Text(
                'Add your vehicle make, model, and battery size in Profile to show real battery and range values here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _StatusMetric(
                      label: 'Battery',
                      value:
                          batteryPercent == null
                              ? 'Not set'
                              : '${batteryPercent!.round()}%',
                      helper:
                          availableKwh == null
                              ? 'Update charge level'
                              : '${availableKwh!.toStringAsFixed(1)} kWh available',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatusMetric(
                      label: 'Range',
                      value:
                          estimatedRangeKm == null
                              ? '--'
                              : '${estimatedRangeKm!.round()} km',
                      helper:
                          estimatedRangeKm == null
                              ? 'Needs battery level'
                              : 'using ${efficiencyKmPerKwh.toStringAsFixed(1)} km/kWh',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: sliderValue / 100,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    sliderValue >= 50
                        ? cs.primary
                        : sliderValue >= 25
                        ? const Color(0xFFF59E0B)
                        : cs.error,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Current charge level',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (savingBatteryPercent)
                    Text(
                      'Saving...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                ],
              ),
              Slider(
                value: sliderValue,
                min: 0,
                max: 100,
                divisions: 100,
                label: '${sliderValue.round()}%',
                onChanged: onBatteryPercentChanged,
                onChangeEnd: onBatteryPercentChangeEnd,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  chargeSummary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (batteryKwh != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Battery pack: ${batteryKwh!.toStringAsFixed(batteryKwh!.truncateToDouble() == batteryKwh ? 0 : 1)} kWh',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(helper, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [IconButton(icon: Icon(icon), onPressed: onTap), Text(label)],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.12),
            cs.tertiary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
