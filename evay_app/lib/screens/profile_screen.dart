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

        return SafeArea(
          child: Padding(
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
                    context, Icons.description, l10n.t('termsAndConditions'),
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsConditionsScreen(),
                    ),
                  );
                }),
                _tile(context, Icons.privacy_tip, l10n.t('policies'), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                  );
                }),
                const Spacer(),

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
}
