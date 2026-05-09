import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/simulation_service.dart';

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  final _sim = SimulationService();

  final _batteryCapacity = TextEditingController(text: '40'); // kWh
  final _batteryPercent = TextEditingController(text: '60'); // %
  final _efficiency = TextEditingController(text: '6'); // km/kWh
  final _distance = TextEditingController(text: '120'); // km

  SimulationResult? _result;

  void _run() {
    final cap = double.tryParse(_batteryCapacity.text) ?? 0;
    final pct = double.tryParse(_batteryPercent.text) ?? 0;
    final eff = double.tryParse(_efficiency.text) ?? 0;
    final dist = double.tryParse(_distance.text) ?? 0;

    if (cap <= 0 || eff <= 0 || dist <= 0) return;

    setState(() {
      _result = _sim.simulate(
        batteryCapacityKwh: cap,
        batteryPercent: pct.clamp(0, 100),
        efficiencyKmPerKwh: eff,
        tripDistanceKm: dist,
      );
    });
  }

  @override
  void dispose() {
    _batteryCapacity.dispose();
    _batteryPercent.dispose();
    _efficiency.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.t('batteryCostSimulation'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _batteryCapacity,
          decoration: InputDecoration(
            labelText: l10n.t('batteryCapacity'),
          ),
        ),
        TextField(
          controller: _batteryPercent,
          decoration: InputDecoration(labelText: l10n.t('batteryRemaining')),
        ),
        TextField(
          controller: _efficiency,
          decoration: InputDecoration(
            labelText: l10n.t('efficiency'),
          ),
        ),
        TextField(
          controller: _distance,
          decoration: InputDecoration(labelText: l10n.t('tripDistance')),
        ),

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: _run, child: Text(l10n.t('simulate'))),
        ),

        const SizedBox(height: 16),
        if (_result != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('results'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.estimatedRange(_result!.estimatedRangeKm.toStringAsFixed(1)),
                  ),
                  Text(
                    l10n.energyNeeded(_result!.energyNeededKwh.toStringAsFixed(2)),
                  ),
                  Text(
                    l10n.estimatedEvCost(_result!.estimatedCostLkr.toStringAsFixed(0)),
                  ),
                  Text(
                    l10n.petrolEquivalent(_result!.petrolEquivalentLkr.toStringAsFixed(0)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.t('simulationNote')),
        ],
      ],
    );
  }
}
