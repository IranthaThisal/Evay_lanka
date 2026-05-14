import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../l10n/app_localizations.dart';
import 'edit_profile_screen.dart';
import 'policies_screen.dart';
import 'settings_screen.dart';
import 'terms_conditions_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = FirebaseAuth.instance.currentUser;
    final userDoc =
        user == null
            ? null
            : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final profileName = _profileName(context, user, data);
        final subtitle = user?.email ?? '-';
        final initial = _initial(profileName, subtitle);
        final vehicleInfo = _vehicleInfo(data);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 42,
                  child: Text(initial, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(height: 10),
                Text(
                  profileName,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 20),
                _profileSummaryCard(
                  context,
                  title: 'Profile Overview',
                  actionLabel: 'Edit',
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: _ProfileOverviewGrid(
                    contact: _readValue(data['contactNumber']),
                    country: _readValue(data['country']),
                    company: _readValue(data['company']),
                  ),
                ),
                const SizedBox(height: 14),
                _profileSummaryCard(
                  context,
                  title: 'My Vehicle',
                  actionLabel: vehicleInfo == null ? 'Add vehicle' : null,
                  onAction:
                      vehicleInfo == null
                          ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          }
                          : null,
                  child: _VehicleOverviewCard(
                    vehicleInfo: vehicleInfo,
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _tile(context, Icons.edit, l10n.t('editProfile'), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                }),
                _tile(context, Icons.settings, l10n.t('settings'), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }),
                _tile(
                  context,
                  Icons.description,
                  l10n.t('termsAndConditions'),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                ),
                _tile(context, Icons.privacy_tip, l10n.t('policies'), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                  );
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await GoogleSignIn().signOut();
                      await FirebaseAuth.instance.signOut();
                    },
                    child: Text(l10n.t('logout')),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "v 1.0.0",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _profileName(
    BuildContext context,
    User? user,
    Map<String, dynamic> data,
  ) {
    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final lastName = (data['lastName'] as String?)?.trim() ?? '';
    final firestoreName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');

    if (firestoreName.isNotEmpty) return firestoreName;

    final authName = user?.displayName?.trim() ?? '';
    if (authName.isNotEmpty) return authName;

    final emailName = user?.email?.split('@').first.trim() ?? '';
    if (emailName.isNotEmpty) return emailName;

    return AppLocalizations.of(context).t('evayUser');
  }

  String _initial(String profileName, String subtitle) {
    final source = profileName.trim().isNotEmpty ? profileName : subtitle;
    return source.trim().isEmpty ? 'U' : source.trim()[0].toUpperCase();
  }

  String _readValue(Object? value) {
    final text = (value as String?)?.trim() ?? '';
    return text.isEmpty ? 'Not added yet' : text;
  }

  _VehicleInfo? _vehicleInfo(Map<String, dynamic> data) {
    final make = (data['vehicleMake'] as String?)?.trim() ?? '';
    final model = (data['vehicleModel'] as String?)?.trim() ?? '';
    final batteryKwh = (data['batteryKwh'] as num?)?.toDouble();
    final batteryPercent = (data['batteryPercent'] as num?)?.toDouble();
    final efficiencyKmPerKwh =
        (data['efficiencyKmPerKwh'] as num?)?.toDouble() ?? 6.0;
    final parts = [make, model].where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty && batteryKwh == null) return null;

    final displayName = parts.isEmpty ? 'Saved vehicle' : parts.join(' ');
    final rangeKm =
        batteryKwh != null && batteryPercent != null
            ? batteryKwh * (batteryPercent / 100) * efficiencyKmPerKwh
            : null;

    return _VehicleInfo(
      displayName: displayName,
      modelSuffix: parts.length > 1 ? parts.last : null,
      batteryKwh: batteryKwh,
      batteryPercent: batteryPercent,
      estimatedRangeKm: rangeKm,
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _profileSummaryCard(
    BuildContext context, {
    required String title,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProfileOverviewGrid extends StatelessWidget {
  const _ProfileOverviewGrid({
    required this.contact,
    required this.country,
    required this.company,
  });

  final String contact;
  final String country;
  final String company;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProfileStatCard(
            icon: Icons.phone_outlined,
            label: 'Contact',
            value: contact,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ProfileStatCard(
            icon: Icons.public_outlined,
            label: 'Country',
            value: country,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ProfileStatCard(
            icon: Icons.apartment_outlined,
            label: 'Company',
            value: company,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EEF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF9F0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF34A853)),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFA0A9B8),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  value == 'Not added yet'
                      ? const Color(0xFF98A2B3)
                      : const Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleOverviewCard extends StatelessWidget {
  const _VehicleOverviewCard({
    required this.vehicleInfo,
    required this.onEdit,
  });

  final _VehicleInfo? vehicleInfo;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = vehicleInfo;

    if (info == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A4A3A), Color(0xFF1F3A2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              color: Color(0xFFB5EBC8),
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              'No vehicle added yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your EV details to show battery size, live battery level, and estimated driving range here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFD6EBDD),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x66FFFFFF)),
              ),
              child: const Text('Add vehicle'),
            ),
          ],
        ),
      );
    }

    final batteryPercent = info.batteryPercent?.clamp(0.0, 100.0).toDouble();
    final progress = batteryPercent == null ? 0.0 : batteryPercent / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A4A3A), Color(0xFF1F3A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(
              Icons.directions_car_filled_outlined,
              size: 88,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MY VEHICLE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xB3B5EBC8),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      info.displayName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (info.modelSuffix != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        info.modelSuffix!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xCCB5EBC8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              if (info.batteryKwh != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.battery_5_bar_rounded,
                        size: 15,
                        color: Color(0xFF8EE4A2),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${info.batteryKwh!.toStringAsFixed(info.batteryKwh!.truncateToDouble() == info.batteryKwh ? 0 : 1)} kWh battery',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              Container(
                height: 7,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF35D17D),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.estimatedRangeKm == null
                          ? 'Set battery level on Home to show live range'
                          : 'Range ~ ${info.estimatedRangeKm!.round()} km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xCCDCF3E3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    batteryPercent == null ? '--' : '${batteryPercent.round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleInfo {
  const _VehicleInfo({
    required this.displayName,
    required this.modelSuffix,
    required this.batteryKwh,
    required this.batteryPercent,
    required this.estimatedRangeKm,
  });

  final String displayName;
  final String? modelSuffix;
  final double? batteryKwh;
  final double? batteryPercent;
  final double? estimatedRangeKm;
}
