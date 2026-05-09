import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'bookings_screen.dart';
import 'charge_screen.dart';
import 'map_screen.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'vehicle_add_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onChangeTab});

  final ValueChanged<int>? onChangeTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _vehiclePromptShownThisSession = false;

  @override
  void initState() {
    super.initState();

    // Run after first frame so Home UI renders first (then popup can show)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowVehiclePrompt();
    });
  }

  Future<void> _maybeShowVehiclePrompt() async {
    if (_vehiclePromptShownThisSession) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();

    final hasVehicle =
        data != null &&
        data['vehicleMake'] != null &&
        data['vehicleModel'] != null &&
        data['batteryKwh'] != null;

    if (!hasVehicle && mounted) {
      _vehiclePromptShownThisSession = true;

      showDialog(
        context: context,
        barrierDismissible: true, // ✅ user can dismiss by tapping outside
        builder:
            (_) => _VehicleInfoDialog(
              onAdd: () {
                Navigator.pop(context); // close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleAddScreen()),
                );
              },
              onLater: () => Navigator.pop(context),
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // ✅ This is the REAL Home UI (always shows)
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          Text(l10n.t('appTitle'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            l10n.t('homeWelcome'),
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 16),

          // Quick actions (demo-ready)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickCard(
                icon: Icons.map_outlined,
                title: l10n.t('findChargers'),
                subtitle: l10n.t('searchNearbyStations'),
                onTap: () {
                  if (widget.onChangeTab != null) {
                    widget.onChangeTab!(1);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  );
                },
              ),
              _QuickCard(
                icon: Icons.book_online_outlined,
                title: l10n.t('bookings'),
                subtitle: l10n.t('viewUpcomingSlots'),
                onTap: () {
                  if (widget.onChangeTab != null) {
                    widget.onChangeTab!(2);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingsScreen()),
                  );
                },
              ),
              _QuickCard(
                icon: Icons.flash_on_outlined,
                title: l10n.t('charge'),
                subtitle: l10n.t('enterReferenceCode'),
                onTap: () {
                  if (widget.onChangeTab != null) {
                    widget.onChangeTab!(3);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChargeScreen()),
                  );
                },
              ),
              _QuickCard(
                icon: Icons.directions_car_outlined,
                title: l10n.t('vehicle'),
                subtitle: l10n.t('addOrUpdateDetails'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VehicleAddScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.t('vehicleTip'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _VehicleInfoDialog extends StatelessWidget {
  const _VehicleInfoDialog({required this.onAdd, required this.onLater});

  final VoidCallback onAdd;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final palette = context.evayPalette;
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.t('vehicleInformation'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: palette.heroGradient,
                ),
                child: Center(
                  child: Icon(
                    Icons.electric_car,
                    size: 70,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('vehicleInfoPrompt'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAdd,
                  child: Text(l10n.t('addVehicle')),
                ),
              ),
              TextButton(onPressed: onLater, child: Text(l10n.t('addLater'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(
                context,
              ).dividerColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
