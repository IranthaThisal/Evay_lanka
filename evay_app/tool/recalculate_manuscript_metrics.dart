import 'dart:math' as math;

void main() {
  // 15 Scenarios Data extracted directly from comparative_benchmark_45_scenarios_test.dart
  final scenarios = [
    // [Corridor, InitSoc, OSRM_dist, OSRM_time, OSRM_soc, OSRM_viol, Near_dist, Near_time, Near_soc, Near_viol, Evay_dist, Evay_time, Evay_soc, Evay_viol]
    {'corridor': 'C1', 'baseDist': 125.0, 'soc': 30, 'osrmDist': 125.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 135.5, 'nearTime': 70.0, 'nearViol': false, 'evayDist': 125.0, 'evayTime': 34.8, 'evayViol': false},
    {'corridor': 'C1', 'baseDist': 125.0, 'soc': 50, 'osrmDist': 125.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 151.0, 'nearTime': 38.1, 'nearViol': false, 'evayDist': 126.8, 'evayTime': 35.2, 'evayViol': false},
    {'corridor': 'C1', 'baseDist': 125.0, 'soc': 80, 'osrmDist': 125.0, 'osrmTime': 0.0, 'osrmViol': false, 'nearDist': 125.0, 'nearTime': 0.0, 'nearViol': false, 'evayDist': 125.0, 'evayTime': 0.0, 'evayViol': false},

    {'corridor': 'C2', 'baseDist': 115.0, 'soc': 30, 'osrmDist': 115.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 125.4, 'nearTime': 34.8, 'nearViol': false, 'evayDist': 115.0, 'evayTime': 34.9, 'evayViol': false},
    {'corridor': 'C2', 'baseDist': 115.0, 'soc': 50, 'osrmDist': 115.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 140.2, 'nearTime': 56.1, 'nearViol': false, 'evayDist': 128.0, 'evayTime': 41.8, 'evayViol': false},
    {'corridor': 'C2', 'baseDist': 115.0, 'soc': 80, 'osrmDist': 115.0, 'osrmTime': 0.0, 'osrmViol': false, 'nearDist': 115.0, 'nearTime': 0.0, 'nearViol': false, 'evayDist': 115.0, 'evayTime': 0.0, 'evayViol': false},

    {'corridor': 'C3', 'baseDist': 168.0, 'soc': 30, 'osrmDist': 168.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 201.6, 'nearTime': 89.9, 'nearViol': false, 'evayDist': 168.0, 'evayTime': 35.0, 'evayViol': false},
    {'corridor': 'C3', 'baseDist': 168.0, 'soc': 50, 'osrmDist': 168.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 171.9, 'nearTime': 67.0, 'nearViol': false, 'evayDist': 170.6, 'evayTime': 70.4, 'evayViol': false},
    {'corridor': 'C3', 'baseDist': 168.0, 'soc': 80, 'osrmDist': 168.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 183.5, 'nearTime': 71.5, 'nearViol': false, 'evayDist': 168.0, 'evayTime': 0.0, 'evayViol': true}, // Reserve violation

    {'corridor': 'C4', 'baseDist': 395.0, 'soc': 30, 'osrmDist': 395.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 565.1, 'nearTime': 144.1, 'nearViol': true, 'evayDist': 421.5, 'evayTime': 75.1, 'evayViol': false},
    {'corridor': 'C4', 'baseDist': 395.0, 'soc': 50, 'osrmDist': 395.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 606.9, 'nearTime': 171.3, 'nearViol': true, 'evayDist': 421.5, 'evayTime': 73.7, 'evayViol': false},
    {'corridor': 'C4', 'baseDist': 395.0, 'soc': 80, 'osrmDist': 395.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 587.1, 'nearTime': 115.3, 'nearViol': true, 'evayDist': 421.5, 'evayTime': 40.2, 'evayViol': false},

    {'corridor': 'C5', 'baseDist': 350.0, 'soc': 30, 'osrmDist': 350.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 502.5, 'nearTime': 106.5, 'nearViol': true, 'evayDist': 375.7, 'evayTime': 83.7, 'evayViol': false},
    {'corridor': 'C5', 'baseDist': 350.0, 'soc': 50, 'osrmDist': 350.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 403.9, 'nearTime': 119.9, 'nearViol': false, 'evayDist': 367.1, 'evayTime': 77.8, 'evayViol': false},
    {'corridor': 'C5', 'baseDist': 350.0, 'soc': 80, 'osrmDist': 350.0, 'osrmTime': 0.0, 'osrmViol': true, 'nearDist': 493.5, 'nearTime': 111.8, 'nearViol': true, 'evayDist': 359.4, 'evayTime': 70.3, 'evayViol': false},
  ];

  print('================================================================================');
  print('INDEPENDENT MATHEMATICAL RECALCULATION & CONSISTENCY VERIFICATION');
  print('================================================================================\n');

  // 1. Reserve Violations
  final osrmViol = scenarios.where((s) => s['osrmViol'] as bool).length;
  final nearViol = scenarios.where((s) => s['nearViol'] as bool).length;
  final evayViol = scenarios.where((s) => s['evayViol'] as bool).length;

  print('1. Reserve Violations (out of 15):');
  print('   - OSRM:           $osrmViol/15 (${(osrmViol / 15 * 100).toStringAsFixed(1)}%)');
  print('   - Nearest Charger: $nearViol/15 (${(nearViol / 15 * 100).toStringAsFixed(1)}%)');
  print('   - EVayLanka:       $evayViol/15 (${(evayViol / 15 * 100).toStringAsFixed(1)}%)');
  print('   - Reduction vs Nearest Charger: ${((nearViol - evayViol) / nearViol * 100).toStringAsFixed(1)}%\n');

  // 2. Detour Distances
  var nearDetourSum = 0.0;
  var evayDetourSum = 0.0;
  var maxNearDetour = 0.0;
  var maxEvayDetour = 0.0;
  var nearMaxDist = 0.0;
  var evayMaxDist = 0.0;

  for (final s in scenarios) {
    final base = (s['baseDist'] as num).toDouble();
    final nearD = (s['nearDist'] as num).toDouble() - base;
    final evayD = (s['evayDist'] as num).toDouble() - base;

    nearDetourSum += nearD;
    evayDetourSum += evayD;

    if (nearD > maxNearDetour) {
      maxNearDetour = nearD;
      nearMaxDist = (s['nearDist'] as num).toDouble();
    }
    if (evayD > maxEvayDetour) {
      maxEvayDetour = evayD;
      evayMaxDist = (s['evayDist'] as num).toDouble();
    }
  }

  final avgNearDetour = nearDetourSum / scenarios.length;
  final avgEvayDetour = evayDetourSum / scenarios.length;
  final baseDistSum = scenarios.map((s) => s['baseDist'] as double).reduce((a, b) => a + b);
  final avgBaseDist = baseDistSum / scenarios.length;

  print('2. Detour Distances across all 15 scenarios:');
  print('   - Nearest Charger Avg Detour: +${avgNearDetour.toStringAsFixed(1)} km (+${(avgNearDetour / avgBaseDist * 100).toStringAsFixed(1)}%)');
  print('   - EVayLanka Avg Detour:       +${avgEvayDetour.toStringAsFixed(1)} km (+${(avgEvayDetour / avgBaseDist * 100).toStringAsFixed(1)}%)');
  print('   - Detour Overhead Reduction:  ${((avgNearDetour - avgEvayDetour) / avgNearDetour * 100).toStringAsFixed(1)}%');
  print('   - Worst Single Detour:');
  print('     * Nearest: +${maxNearDetour.toStringAsFixed(1)} km (Total: ${nearMaxDist.toStringAsFixed(1)} km)');
  print('     * EVay:    +${maxEvayDetour.toStringAsFixed(1)} km (Total: ${evayMaxDist.toStringAsFixed(1)} km)');
  print('     * Reduction in Worst Detour: ${((maxNearDetour - maxEvayDetour) / maxNearDetour * 100).toStringAsFixed(1)}%\n');

  // 3. Charging Times for Feasible EV Routing Runs
  // Nearest Charger was feasible in 10 runs; EVayLanka was feasible in 14 runs (and safely completed 15).
  // Let's compute average charging time for both across runs that required charging stops:
  final nearFeasible = scenarios.where((s) => !(s['nearViol'] as bool)).toList();
  final evayFeasible = scenarios.where((s) => !(s['evayViol'] as bool)).toList();

  final nearFeasibleTime = nearFeasible.map((s) => s['nearTime'] as double).reduce((a, b) => a + b) / nearFeasible.length;
  final evayFeasibleTime = evayFeasible.map((s) => s['evayTime'] as double).reduce((a, b) => a + b) / evayFeasible.length;

  // Runs where charging occurred (> 0 min):
  final nearChargingOnly = scenarios.where((s) => (s['nearTime'] as double) > 0.0 && !(s['nearViol'] as bool)).toList();
  final evayChargingOnly = scenarios.where((s) => (s['evayTime'] as double) > 0.0 && !(s['evayViol'] as bool)).toList();

  final nearChargeAvg = nearChargingOnly.map((s) => s['nearTime'] as double).reduce((a, b) => a + b) / nearChargingOnly.length;
  final evayChargeAvg = evayChargingOnly.map((s) => s['evayTime'] as double).reduce((a, b) => a + b) / evayChargingOnly.length;

  print('3. Charging Time Synthesis:');
  print('   - Nearest Charger Feasible Avg Time: ${nearFeasibleTime.toStringAsFixed(1)} min');
  print('   - EVayLanka Feasible Avg Time:       ${evayFeasibleTime.toStringAsFixed(1)} min');
  print('   - Reduction in Charging Time:        ${((nearFeasibleTime - evayFeasibleTime) / nearFeasibleTime * 100).toStringAsFixed(1)}%');
  print('   - When charging is required (>0 min):');
  print('     * Nearest: ${nearChargeAvg.toStringAsFixed(1)} min');
  print('     * EVay:    ${evayChargeAvg.toStringAsFixed(1)} min');
  print('     * Reduction: ${((nearChargeAvg - evayChargeAvg) / nearChargeAvg * 100).toStringAsFixed(1)}%\n');

  // 4. Energy Model Recalculations (Stage 2 vs Stage 3 on C3/J5)
  const d = 168.0;
  const rated = 0.1667;
  const hvac = 1.05;
  const deltaH = 1359.0;
  const g = 9.80665;
  const etaDrive = 0.88;

  // Stage 2: 3 occupants (150 kg payload), Heavy Monsoon (1.10)
  final mTotal2 = 1800.0 + 150.0;
  final kPayload2 = 1.0 + (150.0 / 1800.0 * 0.45); // 1.0375
  final kEnv2 = 1.10 * kPayload2; // 1.14125
  final eRolling2 = d * rated * hvac * kEnv2;
  final eElev2 = (mTotal2 * g * deltaH) / (3.6e6 * etaDrive);
  final eTotal2 = eRolling2 + eElev2;

  // Stage 3: 2 occupants (75 kg payload), Light Rain (1.05)
  final mTotal3 = 1800.0 + 75.0;
  final kPayload3 = 1.0 + (75.0 / 1800.0 * 0.45); // 1.01875
  final kEnv3 = 1.05 * kPayload3; // 1.0696875
  final eRolling3 = d * rated * hvac * kEnv3;
  final eElev3 = (mTotal3 * g * deltaH) / (3.6e6 * etaDrive);
  final eTotal3 = eRolling3 + eElev3;

  print('4. Energy Model Exact Decimal Verification (Colombo - Nuwara Eliya):');
  print('   - Stage 2:');
  print('     * Rolling:   ${eRolling2.toStringAsFixed(4)} kWh');
  print('     * Elevation: ${eElev2.toStringAsFixed(4)} kWh');
  print('     * Total:     ${eTotal2.toStringAsFixed(4)} kWh (Rounded: ${eTotal2.toStringAsFixed(2)} kWh)');
  print('   - Stage 3:');
  print('     * Rolling:   ${eRolling3.toStringAsFixed(4)} kWh');
  print('     * Elevation: ${eElev3.toStringAsFixed(4)} kWh');
  print('     * Total:     ${eTotal3.toStringAsFixed(4)} kWh (Rounded: ${eTotal3.toStringAsFixed(2)} kWh)');
  print('================================================================================');
}
