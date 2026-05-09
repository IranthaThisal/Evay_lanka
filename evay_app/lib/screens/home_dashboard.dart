import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.onOpenMap,
    required this.onOpenBookings,
    required this.onOpenBattery,
    required this.onOpenCommunity,
  });

  final VoidCallback onOpenMap;
  final VoidCallback onOpenBookings;
  final VoidCallback onOpenBattery;
  final VoidCallback onOpenCommunity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          // Vehicle Title Section
          Text(l10n.t('myEv'), style: Theme.of(context).textTheme.bodyMedium),

          const SizedBox(height: 4),

          Text(
            l10n.t('evayVehicle'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          // Car Image
          Center(
            child: Image.asset(
              "assets/images/ev_car.png",
              height: 200,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 16),

          // Battery + Range Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(l10n.t('battery')),
                      const SizedBox(height: 8),
                      Text(
                        "72%",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text("24 km left"),
                    ],
                  ),
                  Column(
                    children: [
                      Text(l10n.t('range')),
                      const SizedBox(height: 8),
                      Text(
                        "48 km",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(l10n.t('estimated')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nearest Charging Station Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(l10n.t('nearestChargingStation')),
              subtitle: Text(l10n.t('colomboCentralEvStation')),
              trailing: FilledButton(
                onPressed: onOpenMap,
                child: Text(l10n.t('openMap')),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(icon: Icons.map, label: l10n.t('map'), onTap: onOpenMap),
              _ActionButton(
                icon: Icons.book_online,
                label: l10n.t('bookings'),
                onTap: onOpenBookings,
              ),
              _ActionButton(
                icon: Icons.battery_full,
                label: l10n.t('battery'),
                onTap: onOpenBattery,
              ),
              _ActionButton(
                icon: Icons.group,
                label: l10n.t('community'),
                onTap: onOpenCommunity,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Reusable action button widget
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
