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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
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
                height: 140,
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
                _ActionButton(
                  icon: Icons.map,
                  label: l10n.t('map'),
                  onTap: onOpenMap,
                ),
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
            const SizedBox(height: 28),

            Text(
              'EV insights',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _InsightCard(
                    icon: Icons.bolt_rounded,
                    title: 'Best time to charge',
                    body:
                        'Top up in the evening to keep tomorrow\'s ride ready.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InsightCard(
                    icon: Icons.route_rounded,
                    title: 'Trip ready',
                    body: 'Your current range looks fine for short city trips.',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _TipBanner(
              title: 'Vehicle checklist',
              body:
                  'Keep tyre pressure, battery level, and your nearest charger in check before heading out.',
            ),
          ],
        ),
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
