import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/ev_preset.dart';
import '../theme/app_theme.dart';

class VehicleAddScreen extends StatefulWidget {
  const VehicleAddScreen({
    super.key,
    this.initialMake,
    this.initialModel,
    this.initialBatteryKwh,
    this.submitLabel,
  });

  final String? initialMake;
  final String? initialModel;
  final num? initialBatteryKwh;
  final String? submitLabel;

  static Future<void> showPopup(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _VehicleAddDialog(),
    );
  }

  @override
  State<VehicleAddScreen> createState() => _VehicleAddScreenState();
}

class _VehicleAddScreenState extends State<VehicleAddScreen> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _battery = TextEditingController();
  double _efficiencyKmPerKwh = 6.0;
  List<String> _connectors = const ['CCS2', 'Type 2'];
  String? _selectedPresetId;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _make.text = widget.initialMake ?? '';
    _model.text = widget.initialModel ?? '';
    _battery.text = widget.initialBatteryKwh?.toString() ?? '';
  }

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _battery.dispose();
    super.dispose();
  }

  void _applyPreset(EvPreset preset) {
    setState(() {
      _selectedPresetId = preset.id;
      _make.text = preset.make;
      _model.text = preset.model;
      _battery.text = preset.batteryKwh.toStringAsFixed(1);
      _efficiencyKmPerKwh = preset.efficiencyKmPerKwh;
      _connectors = preset.connectors;
    });
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final make = _make.text.trim();
    final model = _model.text.trim();
    final battery = double.tryParse(_battery.text.trim());

    if (make.isEmpty || model.isEmpty || battery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('vehicleRequired')),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'vehicleMake': make,
        'vehicleModel': model,
        'batteryKwh': battery,
        'efficiencyKmPerKwh': _efficiencyKmPerKwh,
        'connectorTypes': _connectors,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('vehicleSaved'))));
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _VehicleAddCard(
                make: _make,
                model: _model,
                battery: _battery,
                saving: _saving,
                onSave: _save,
                showHeader: true,
                submitLabel: widget.submitLabel,
                selectedPresetId: _selectedPresetId,
                onSelectPreset: _applyPreset,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleAddDialog extends StatefulWidget {
  const _VehicleAddDialog();

  @override
  State<_VehicleAddDialog> createState() => _VehicleAddDialogState();
}

class _VehicleAddDialogState extends State<_VehicleAddDialog> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _battery = TextEditingController();
  double _efficiencyKmPerKwh = 6.0;
  List<String> _connectors = const ['CCS2', 'Type 2'];
  String? _selectedPresetId;

  bool _saving = false;

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _battery.dispose();
    super.dispose();
  }

  void _applyPreset(EvPreset preset) {
    setState(() {
      _selectedPresetId = preset.id;
      _make.text = preset.make;
      _model.text = preset.model;
      _battery.text = preset.batteryKwh.toStringAsFixed(1);
      _efficiencyKmPerKwh = preset.efficiencyKmPerKwh;
      _connectors = preset.connectors;
    });
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final make = _make.text.trim();
    final model = _model.text.trim();
    final battery = double.tryParse(_battery.text.trim());

    if (make.isEmpty || model.isEmpty || battery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('vehicleRequired')),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'vehicleMake': make,
        'vehicleModel': model,
        'batteryKwh': battery,
        'efficiencyKmPerKwh': _efficiencyKmPerKwh,
        'connectorTypes': _connectors,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('vehicleSaved'))));
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: _VehicleAddCard(
            make: _make,
            model: _model,
            battery: _battery,
            saving: _saving,
            onSave: _save,
            showHeader: false,
            submitLabel: null,
            selectedPresetId: _selectedPresetId,
            onSelectPreset: _applyPreset,
          ),
        ),
      ),
    );
  }
}

class _VehicleAddCard extends StatelessWidget {
  const _VehicleAddCard({
    required this.make,
    required this.model,
    required this.battery,
    required this.saving,
    required this.onSave,
    required this.showHeader,
    required this.submitLabel,
    this.selectedPresetId,
    this.onSelectPreset,
  });

  final TextEditingController make;
  final TextEditingController model;
  final TextEditingController battery;
  final bool saving;
  final VoidCallback onSave;
  final bool showHeader;
  final String? submitLabel;
  final String? selectedPresetId;
  final ValueChanged<EvPreset>? onSelectPreset;

  @override
  Widget build(BuildContext context) {
    final palette = context.evayPalette;
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Center(
              child: Text(
                l10n.t('vehicleInformation'),
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            gradient: palette.heroGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                l10n.t('vehicleInsightPrompt'),
                style: TextStyle(color: cs.onSurface, height: 1.35),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Image.asset(
                'assets/images/ev_car.png',
                height: 84,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        if (onSelectPreset != null) ...[
          const SizedBox(height: 12),
          Text(
            'Quick EV Presets (Sri Lanka)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kSriLankaEvPresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final preset = kSriLankaEvPresets[index];
                final isSelected = selectedPresetId == preset.id;
                return ChoiceChip(
                  label: Text(
                    '${preset.displayName} (${preset.batteryKwh.toStringAsFixed(0)}kWh)',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onSelectPreset!(preset),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: make,
          decoration: InputDecoration(
            labelText: l10n.t('make'),
            hintText: l10n.t('makeHint'),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: model,
          decoration: InputDecoration(
            labelText: l10n.t('model'),
            hintText: l10n.t('modelHint'),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: battery,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.t('batteryCapacity'),
            hintText: l10n.t('batteryHint'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(saving ? l10n.t('saving') : (submitLabel ?? l10n.t('addVehicle'))),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: Text(l10n.t('addLater')),
          ),
        ),
      ],
    );
  }
}
