import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _contactNumber = TextEditingController();
  final _country = TextEditingController();
  final _company = TextEditingController();
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _batteryKwh = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _contactNumber.dispose();
    _country.dispose();
    _company.dispose();
    _vehicleMake.dispose();
    _vehicleModel.dispose();
    _batteryKwh.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data() ?? <String, dynamic>{};

      final fullName = (user.displayName ?? '').trim();
      final names =
          fullName.isEmpty ? <String>[] : fullName.split(RegExp(r'\s+'));
      final fallbackFirst = names.isNotEmpty ? names.first : '';
      final fallbackLast = names.length > 1 ? names.skip(1).join(' ') : '';

      _firstName.text =
          (data['firstName'] as String?)?.trim().isNotEmpty == true
              ? (data['firstName'] as String).trim()
              : fallbackFirst;
      _lastName.text =
          (data['lastName'] as String?)?.trim().isNotEmpty == true
              ? (data['lastName'] as String).trim()
              : fallbackLast;
      _contactNumber.text = (data['contactNumber'] as String?) ?? '';
      _country.text = (data['country'] as String?) ?? '';
      _company.text = (data['company'] as String?) ?? '';
      _vehicleMake.text = (data['vehicleMake'] as String?) ?? '';
      _vehicleModel.text = (data['vehicleModel'] as String?) ?? '';
      _batteryKwh.text = data['batteryKwh']?.toString() ?? '';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) return;

    FocusScope.of(context).unfocus();

    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    final contactNumber = _contactNumber.text.trim();
    final country = _country.text.trim();
    final company = _company.text.trim();
    final vehicleMake = _vehicleMake.text.trim();
    final vehicleModel = _vehicleModel.text.trim();
    final batteryText = _batteryKwh.text.trim();
    final batteryKwh =
        batteryText.isEmpty ? null : double.tryParse(batteryText);

    if (firstName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('firstNameRequired'))));
      return;
    }

    final hasAnyVehicleDetail =
        vehicleMake.isNotEmpty ||
        vehicleModel.isNotEmpty ||
        batteryText.isNotEmpty;
    final hasCompleteVehicle =
        vehicleMake.isNotEmpty && vehicleModel.isNotEmpty && batteryKwh != null;

    if (hasAnyVehicleDetail && !hasCompleteVehicle) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('vehicleCompleteRequired')),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final displayName = [
        firstName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' ');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'contactNumber': contactNumber,
        'country': country,
        'company': company,
        if (hasCompleteVehicle) ...{
          'vehicleMake': vehicleMake,
          'vehicleModel': vehicleModel,
          'batteryKwh': batteryKwh,
        } else ...{
          'vehicleMake': FieldValue.delete(),
          'vehicleModel': FieldValue.delete(),
          'batteryKwh': FieldValue.delete(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('profileUpdated'))));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? context.l10n.t('couldNotUpdateProfile'))),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? context.l10n.t('couldNotSaveProfile'))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('noEmailLinked'))),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.passwordResetSent(email))),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? context.l10n.t('couldNotSendReset'))),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final user = _user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.l10n.t('deleteAccount')),
            content: Text(context.l10n.t('deleteAccountBody')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.t('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.t('delete')),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final uid = user.uid;
      await user.delete();
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (_) {
        // The auth account is already removed; ignore profile cleanup failures.
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('accountDeleted'))));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message =
          e.code == 'requires-recent-login'
              ? context.l10n.t('loginAgainDelete')
              : (e.message ?? context.l10n.t('couldNotDeleteAccount'));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(l10n.t('editProfile')),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _saveProfile,
            icon:
                _saving
                    ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                    : const Icon(Icons.save_outlined, size: 18),
            label: Text(_saving ? l10n.t('savingShort') : l10n.t('save')),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.person_outline,
                            title: l10n.t('personalInformation'),
                            color: cs.primary,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileField(
                                  controller: _firstName,
                                  label: l10n.t('firstName'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ProfileField(
                                  controller: _lastName,
                                  label: l10n.t('lastName'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            controller: _contactNumber,
                            label: l10n.t('contactNumber'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileField(
                                  controller: _country,
                                  label: l10n.t('country'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ProfileField(
                                  controller: _company,
                                  label: l10n.t('companyOptional'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Divider(color: cs.outlineVariant),
                          const SizedBox(height: 22),
                          _SectionTitle(
                            icon: Icons.directions_car_outlined,
                            title: l10n.t('vehicleDetails'),
                            color: cs.secondary,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileField(
                                  controller: _vehicleMake,
                                  label: l10n.t('make'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ProfileField(
                                  controller: _vehicleModel,
                                  label: l10n.t('model'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            controller: _batteryKwh,
                            label: l10n.t('batteryCapacityShort'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Divider(color: cs.outlineVariant),
                          const SizedBox(height: 22),
                          _SectionTitle(
                            icon: Icons.shield_outlined,
                            title: l10n.t('accountSecurity'),
                            color: cs.error,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _sendPasswordReset,
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                foregroundColor: cs.onSurface,
                                side: BorderSide(color: cs.outlineVariant),
                              ),
                              child: Text(l10n.t('changePassword')),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _deleteAccount,
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                foregroundColor: cs.error,
                                backgroundColor: cs.errorContainer.withValues(
                                  alpha: 0.18,
                                ),
                                side: BorderSide(color: cs.error),
                              ),
                              child: Text(l10n.t('deleteAccountPermanently')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
