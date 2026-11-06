import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/charger.dart';
import '../models/charger_checkin.dart';
import '../services/checkin_service.dart';

class CheckInSheet extends StatefulWidget {
  const CheckInSheet({super.key, required this.charger});

  final Charger charger;

  static Future<void> show(BuildContext context, Charger charger) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckInSheet(charger: charger),
    );
  }

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  final CheckInService _checkInService = CheckInService();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _peakPowerController = TextEditingController();

  CheckInOutcome _outcome = CheckInOutcome.success;
  CheckInIssue _issue = CheckInIssue.none;
  String? _userVehicle;
  String _userName = 'EV Driver';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserVehicle();
    if (widget.charger.powerKw != null) {
      _peakPowerController.text = widget.charger.powerKw!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _peakPowerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserVehicle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : 'EV Driver';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};
      final make = (data['vehicleMake'] as String?)?.trim() ?? '';
      final model = (data['vehicleModel'] as String?)?.trim() ?? '';
      if (make.isNotEmpty || model.isNotEmpty) {
        setState(() {
          _userVehicle = '$make $model'.trim();
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit a check-in.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final power = double.tryParse(_peakPowerController.text.trim());
      final checkIn = ChargerCheckIn(
        id: '',
        chargerId: widget.charger.id,
        chargerName: widget.charger.name,
        userId: user.uid,
        userName: _userName,
        outcome: _outcome,
        issue: _outcome == CheckInOutcome.couldNotCharge ? _issue : CheckInIssue.none,
        peakPowerKw: _outcome == CheckInOutcome.success ? power : null,
        vehicleModel: _userVehicle,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _checkInService.submitCheckIn(checkIn);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Check-in posted! Thank you for helping the community.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit check-in: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.how_to_reg, color: Color(0xFF16A34A), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check In at Station',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.charger.name} • ${widget.charger.city}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Outcome Selector Cards
            Text(
              'How did it go?',
              style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _outcomeCard(
                    title: 'Charged',
                    subtitle: 'Success',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF16A34A),
                    selected: _outcome == CheckInOutcome.success,
                    onTap: () => setState(() => _outcome = CheckInOutcome.success),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _outcomeCard(
                    title: 'Problem',
                    subtitle: 'Could not charge',
                    icon: Icons.error_outline,
                    color: const Color(0xFFDC2626),
                    selected: _outcome == CheckInOutcome.couldNotCharge,
                    onTap: () => setState(() {
                      _outcome = CheckInOutcome.couldNotCharge;
                      if (_issue == CheckInIssue.none) {
                        _issue = CheckInIssue.noPower;
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _outcomeCard(
                    title: 'Comment',
                    subtitle: 'Status update',
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF0284C7),
                    selected: _outcome == CheckInOutcome.commentOnly,
                    onTap: () => setState(() => _outcome = CheckInOutcome.commentOnly),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Conditional Fields based on Outcome
            if (_outcome == CheckInOutcome.couldNotCharge) ...[
              Text(
                'What was the issue?',
                style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _issueChip(CheckInIssue.noPower),
                  _issueChip(CheckInIssue.brokenConnector),
                  _issueChip(CheckInIssue.bayBlocked),
                  _issueChip(CheckInIssue.paymentFailed),
                  _issueChip(CheckInIssue.stationClosed),
                  _issueChip(CheckInIssue.other),
                ],
              ),
              const SizedBox(height: 16),
            ] else if (_outcome == CheckInOutcome.success) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _peakPowerController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Peak Power (kW)',
                        hintText: 'e.g. 45',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(
                        _userVehicle ?? 'Vehicle: EV',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 3. Comment Field
            TextField(
              controller: _commentController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Add a note for other drivers (optional)',
                hintText: _outcome == CheckInOutcome.success
                    ? 'e.g. Clean site, fast charge, coffee shop nearby'
                    : 'e.g. MCB tripped, guard informed us power returns at 2pm',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),

            // 4. Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _outcome == CheckInOutcome.couldNotCharge
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Submitting...' : 'Post Check-In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outcomeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: selected ? color : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _issueChip(CheckInIssue issue) {
    final selected = _issue == issue;
    return ChoiceChip(
      label: Text(issue.label),
      selected: selected,
      selectedColor: const Color(0xFFDC2626).withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? const Color(0xFFDC2626) : null,
      ),
      onSelected: (val) {
        if (val) setState(() => _issue = issue);
      },
    );
  }
}
