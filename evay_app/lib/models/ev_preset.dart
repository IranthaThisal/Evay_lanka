/// Preset specifications for common Electric Vehicles operating in Sri Lanka.
class EvPreset {
  const EvPreset({
    required this.id,
    required this.make,
    required this.model,
    required this.batteryKwh,
    required this.efficiencyKmPerKwh,
    required this.curbWeightKg,
    required this.connectors,
  });

  final String id;
  final String make;
  final String model;
  final double batteryKwh;
  final double efficiencyKmPerKwh;
  final double curbWeightKg;
  final List<String> connectors;

  String get displayName => '$make $model';
  String get shortSpec =>
      '${batteryKwh.toStringAsFixed(1)} kWh • ${efficiencyKmPerKwh.toStringAsFixed(1)} km/kWh';
}

const List<EvPreset> kSriLankaEvPresets = [
  EvPreset(
    id: 'mg_zs_ev_50',
    make: 'MG',
    model: 'ZS EV',
    batteryKwh: 50.3,
    efficiencyKmPerKwh: 6.0,
    curbWeightKg: 1650,
    connectors: ['CCS2', 'Type 2', 'L3', 'L2'],
  ),
  EvPreset(
    id: 'byd_atto3_std',
    make: 'BYD',
    model: 'Atto 3 (Standard)',
    batteryKwh: 49.9,
    efficiencyKmPerKwh: 6.4,
    curbWeightKg: 1680,
    connectors: ['CCS2', 'Type 2', 'L3', 'L2'],
  ),
  EvPreset(
    id: 'byd_atto3_ext',
    make: 'BYD',
    model: 'Atto 3 (Extended)',
    batteryKwh: 60.5,
    efficiencyKmPerKwh: 6.3,
    curbWeightKg: 1750,
    connectors: ['CCS2', 'Type 2', 'L3', 'L2'],
  ),
  EvPreset(
    id: 'byd_dolphin',
    make: 'BYD',
    model: 'Dolphin',
    batteryKwh: 44.9,
    efficiencyKmPerKwh: 6.8,
    curbWeightKg: 1450,
    connectors: ['CCS2', 'Type 2', 'L3', 'L2'],
  ),
  EvPreset(
    id: 'nissan_leaf_40',
    make: 'Nissan',
    model: 'Leaf (ZE1 40kWh)',
    batteryKwh: 40.0,
    efficiencyKmPerKwh: 6.2,
    curbWeightKg: 1580,
    connectors: ['CHAdeMO', 'Type 1', 'Type 2', 'L3', 'L2'],
  ),
  EvPreset(
    id: 'nissan_leaf_24',
    make: 'Nissan',
    model: 'Leaf (AZE0 24kWh)',
    batteryKwh: 24.0,
    efficiencyKmPerKwh: 6.0,
    curbWeightKg: 1475,
    connectors: ['CHAdeMO', 'Type 1', 'L3', 'L2'],
  ),
  EvPreset(
    id: 'hyundai_kona_39',
    make: 'Hyundai',
    model: 'Kona Electric',
    batteryKwh: 39.2,
    efficiencyKmPerKwh: 6.6,
    curbWeightKg: 1535,
    connectors: ['CCS2', 'Type 2', 'L3', 'L2'],
  ),
];
