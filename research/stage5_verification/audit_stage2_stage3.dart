import 'dart:math' as math;

void main() {
  // Exact matrix from test/comparative_benchmark_45_scenarios_test.dart
  final matrix = [
    // [Corridor, BaseDist, InitSoc, OSRM_Dist, OSRM_Stops, OSRM_Time, OSRM_Arrival, OSRM_Viol, Near_Dist, Near_Stops, Near_Time, Near_Arrival, Near_Viol, Evay_Dist, Evay_Stops, Evay_Time, Evay_Arrival, Evay_Viol, Evay_Hazard]
    {'corridor': 'C1', 'baseDist': 125.0, 'soc': 30, 'osrmDist': 125.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -13.6, 'osrmViol': true, 'nearDist': 135.5, 'nearStops': 1, 'nearTime': 70.0, 'nearSoc': 45.4, 'nearViol': false, 'evayDist': 125.0, 'evayStops': 1, 'evayTime': 34.8, 'evaySoc': 48.8, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C1', 'baseDist': 125.0, 'soc': 50, 'osrmDist': 125.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': 6.4, 'osrmViol': true, 'nearDist': 151.0, 'nearStops': 1, 'nearTime': 38.1, 'nearSoc': 65.5, 'nearViol': false, 'evayDist': 126.8, 'evayStops': 1, 'evayTime': 35.2, 'evaySoc': 69.3, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C1', 'baseDist': 125.0, 'soc': 80, 'osrmDist': 125.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': 36.4, 'osrmViol': false, 'nearDist': 125.0, 'nearStops': 0, 'nearTime': 0.0, 'nearSoc': 36.4, 'nearViol': false, 'evayDist': 125.0, 'evayStops': 0, 'evayTime': 0.0, 'evaySoc': 36.4, 'evayViol': false, 'evayHazard': false},

    {'corridor': 'C2', 'baseDist': 115.0, 'soc': 30, 'osrmDist': 115.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -17.7, 'osrmViol': true, 'nearDist': 125.4, 'nearStops': 1, 'nearTime': 34.8, 'nearSoc': 41.0, 'nearViol': false, 'evayDist': 115.0, 'evayStops': 1, 'evayTime': 34.9, 'evaySoc': 44.6, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C2', 'baseDist': 115.0, 'soc': 50, 'osrmDist': 115.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': 2.3, 'osrmViol': true, 'nearDist': 140.2, 'nearStops': 1, 'nearTime': 56.1, 'nearSoc': 60.5, 'nearViol': false, 'evayDist': 128.0, 'evayStops': 1, 'evayTime': 41.8, 'evaySoc': 64.6, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C2', 'baseDist': 115.0, 'soc': 80, 'osrmDist': 115.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': 32.3, 'osrmViol': false, 'nearDist': 115.0, 'nearStops': 0, 'nearTime': 0.0, 'nearSoc': 32.3, 'nearViol': false, 'evayDist': 115.0, 'evayStops': 0, 'evayTime': 0.0, 'evaySoc': 32.3, 'evayViol': false, 'evayHazard': false},

    {'corridor': 'C3', 'baseDist': 168.0, 'soc': 30, 'osrmDist': 168.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -43.5, 'osrmViol': true, 'nearDist': 201.6, 'nearStops': 2, 'nearTime': 89.9, 'nearSoc': 73.2, 'nearViol': false, 'evayDist': 168.0, 'evayStops': 1, 'evayTime': 35.0, 'evaySoc': 19.2, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C3', 'baseDist': 168.0, 'soc': 50, 'osrmDist': 168.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -23.5, 'osrmViol': true, 'nearDist': 171.9, 'nearStops': 1, 'nearTime': 67.0, 'nearSoc': 35.1, 'nearViol': false, 'evayDist': 170.6, 'evayStops': 1, 'evayTime': 70.4, 'evaySoc': 39.4, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C3', 'baseDist': 168.0, 'soc': 80, 'osrmDist': 168.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': 6.5, 'osrmViol': true, 'nearDist': 183.5, 'nearStops': 1, 'nearTime': 71.5, 'nearSoc': 65.0, 'nearViol': false, 'evayDist': 168.0, 'evayStops': 0, 'evayTime': 0.0, 'evaySoc': 6.5, 'evayViol': true, 'evayHazard': true},

    {'corridor': 'C4', 'baseDist': 395.0, 'soc': 30, 'osrmDist': 395.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -107.7, 'osrmViol': true, 'nearDist': 565.1, 'nearStops': 3, 'nearTime': 144.1, 'nearSoc': 72.0, 'nearViol': true, 'evayDist': 421.5, 'evayStops': 2, 'evayTime': 75.1, 'evaySoc': 26.7, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C4', 'baseDist': 395.0, 'soc': 50, 'osrmDist': 395.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -87.7, 'osrmViol': true, 'nearDist': 606.9, 'nearStops': 2, 'nearTime': 171.3, 'nearSoc': 32.1, 'nearViol': true, 'evayDist': 421.5, 'evayStops': 2, 'evayTime': 73.7, 'evaySoc': 44.1, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C4', 'baseDist': 395.0, 'soc': 80, 'osrmDist': 395.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -57.7, 'osrmViol': true, 'nearDist': 587.1, 'nearStops': 2, 'nearTime': 115.3, 'nearSoc': 62.0, 'nearViol': true, 'evayDist': 421.5, 'evayStops': 1, 'evayTime': 40.2, 'evaySoc': 14.3, 'evayViol': false, 'evayHazard': true},

    {'corridor': 'C5', 'baseDist': 350.0, 'soc': 30, 'osrmDist': 350.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -94.6, 'osrmViol': true, 'nearDist': 502.5, 'nearStops': 2, 'nearTime': 106.5, 'nearSoc': 23.5, 'nearViol': true, 'evayDist': 375.7, 'evayStops': 2, 'evayTime': 83.7, 'evaySoc': 40.8, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C5', 'baseDist': 350.0, 'soc': 50, 'osrmDist': 350.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -74.6, 'osrmViol': true, 'nearDist': 403.9, 'nearStops': 2, 'nearTime': 119.9, 'nearSoc': 43.0, 'nearViol': false, 'evayDist': 367.1, 'evayStops': 2, 'evayTime': 77.8, 'evaySoc': 51.9, 'evayViol': false, 'evayHazard': true},
    {'corridor': 'C5', 'baseDist': 350.0, 'soc': 80, 'osrmDist': 350.0, 'osrmStops': 0, 'osrmTime': 0.0, 'osrmSoc': -44.6, 'osrmViol': true, 'nearDist': 493.5, 'nearStops': 2, 'nearTime': 111.8, 'nearSoc': 72.2, 'nearViol': true, 'evayDist': 359.4, 'evayStops': 1, 'evayTime': 70.3, 'evaySoc': 18.3, 'evayViol': false, 'evayHazard': true},
  ];

  print('=== STAGE 2 INDEPENDENT RECALCULATION ===');
  final nScenarios = matrix.length;
  final osrmViol = matrix.where((m) => m['osrmViol'] as bool).length;
  final nearViol = matrix.where((m) => m['nearViol'] as bool).length;
  final evayViol = matrix.where((m) => m['evayViol'] as bool).length;
  print('Reserve Violations:');
  print('  OSRM: $osrmViol/$nScenarios = ${(osrmViol / nScenarios * 100).toStringAsFixed(1)}%');
  print('  Nearest: $nearViol/$nScenarios = ${(nearViol / nScenarios * 100).toStringAsFixed(1)}%');
  print('  EVayLanka: $evayViol/$nScenarios = ${(evayViol / nScenarios * 100).toStringAsFixed(1)}%');

  // Detours
  var nearDetourSum = 0.0;
  var evayDetourSum = 0.0;
  var baseDistSum = 0.0;
  var maxNearDetour = 0.0;
  var maxEvayDetour = 0.0;
  for (final m in matrix) {
    final base = m['baseDist'] as double;
    final near = m['nearDist'] as double;
    final evay = m['evayDist'] as double;
    baseDistSum += base;
    final nd = near - base;
    final ed = evay - base;
    nearDetourSum += nd;
    evayDetourSum += ed;
    if (nd > maxNearDetour) maxNearDetour = nd;
    if (ed > maxEvayDetour) maxEvayDetour = ed;
  }
  final avgBase = baseDistSum / nScenarios;
  final avgNearDetour = nearDetourSum / nScenarios;
  final avgEvayDetour = evayDetourSum / nScenarios;
  print('\nDetour Analysis (Denominator: all 15 scenarios, total base distance sum = $baseDistSum km, avg = $avgBase km):');
  print('  Nearest Avg Detour: +${avgNearDetour.toStringAsFixed(4)} km (+${(avgNearDetour / avgBase * 100).toStringAsFixed(2)}%)');
  print('  EVayLanka Avg Detour: +${avgEvayDetour.toStringAsFixed(4)} km (+${(avgEvayDetour / avgBase * 100).toStringAsFixed(2)}%)');
  print('  Detour Reduction: ${((avgNearDetour - avgEvayDetour) / avgNearDetour * 100).toStringAsFixed(2)}%');
  print('  Worst Near Detour: +${maxNearDetour.toStringAsFixed(1)} km');
  print('  Worst EVay Detour: +${maxEvayDetour.toStringAsFixed(1)} km');
  print('  Worst Detour Reduction: ${((maxNearDetour - maxEvayDetour) / maxNearDetour * 100).toStringAsFixed(2)}%');

  // Charging Times
  // Nearest Charger: 5 runs had violations. In 10 runs it was feasible.
  // EVayLanka: 1 run had violation. In 14 runs it was feasible.
  // Active charging runs (>0 min):
  final nearActive = matrix.where((m) => (m['nearTime'] as double) > 0.0).toList();
  final evayActive = matrix.where((m) => (m['evayTime'] as double) > 0.0).toList();
  final nearActiveAvg = nearActive.map((m) => m['nearTime'] as double).reduce((a, b) => a + b) / nearActive.length;
  final evayActiveAvg = evayActive.map((m) => m['evayTime'] as double).reduce((a, b) => a + b) / evayActive.length;

  // Feasible active charging runs:
  final nearFeasActive = matrix.where((m) => (m['nearTime'] as double) > 0.0 && !(m['nearViol'] as bool)).toList();
  final evayFeasActive = matrix.where((m) => (m['evayTime'] as double) > 0.0 && !(m['evayViol'] as bool)).toList();
  final nearFeasActiveAvg = nearFeasActive.map((m) => m['nearTime'] as double).reduce((a, b) => a + b) / nearFeasActive.length;
  final evayFeasActiveAvg = evayFeasActive.map((m) => m['evayTime'] as double).reduce((a, b) => a + b) / evayFeasActive.length;

  print('\nCharging Time Analysis:');
  print('  Active Charging Runs count: Nearest=${nearActive.length}/15, EVay=${evayActive.length}/15');
  print('  Active Charging Runs Avg Time: Nearest=${nearActiveAvg.toStringAsFixed(2)} min, EVay=${evayActiveAvg.toStringAsFixed(2)} min');
  print('  Active Charging Reduction: ${((nearActiveAvg - evayActiveAvg) / nearActiveAvg * 100).toStringAsFixed(2)}%');
  print('  Feasible Active Charging count: Nearest=${nearFeasActive.length}, EVay=${evayFeasActive.length}');
  print('  Feasible Active Charging Avg Time: Nearest=${nearFeasActiveAvg.toStringAsFixed(2)} min, EVay=${evayFeasActiveAvg.toStringAsFixed(2)} min');
  print('  Feasible Active Reduction: ${((nearFeasActiveAvg - evayFeasActiveAvg) / nearFeasActiveAvg * 100).toStringAsFixed(2)}%');

  // Peak Charging Delays
  final nearMaxTime = matrix.map((m) => m['nearTime'] as double).reduce(math.max);
  final evayMaxTime = matrix.map((m) => m['evayTime'] as double).reduce(math.max);
  print('\nPeak Delays:');
  print('  Nearest Global Max Time: ${nearMaxTime.toStringAsFixed(1)} min (C4 @ 50%)');
  print('  EVayLanka Global Max Time: ${evayMaxTime.toStringAsFixed(1)} min (C5 @ 30%)');
  print('  Global Peak Delay Reduction: ${((nearMaxTime - evayMaxTime) / nearMaxTime * 100).toStringAsFixed(2)}%');
  final c4_50_near = matrix.firstWhere((m) => m['corridor'] == 'C4' && m['soc'] == 50)['nearTime'] as double;
  final c4_50_evay = matrix.firstWhere((m) => m['corridor'] == 'C4' && m['soc'] == 50)['evayTime'] as double;
  print('  C4 @ 50% SoC Time: Nearest=${c4_50_near.toStringAsFixed(1)} min, EVay=${c4_50_evay.toStringAsFixed(1)} min');
  print('  C4 @ 50% Reduction: ${((c4_50_near - c4_50_evay) / c4_50_near * 100).toStringAsFixed(2)}%');

  // Stage 3 Telemetry Numerical Audit
  final journeys = [
    {'id': 'J1', 'name': 'Colombo to Galle (E01 Expressway)', 'actual': 24.20, 'modA': 20.84, 'modD': 22.34},
    {'id': 'J2', 'name': 'Galle to Colombo (E01 Return)', 'actual': 23.90, 'modA': 20.84, 'modD': 22.31},
    {'id': 'J3', 'name': 'Colombo to Kandy (A1 Kadugannawa Climb)', 'actual': 25.10, 'modA': 19.17, 'modD': 24.54},
    {'id': 'J4', 'name': 'Kandy to Colombo (A1 Kadugannawa Descent)', 'actual': 18.40, 'modA': 19.17, 'modD': 18.89},
    {'id': 'J5', 'name': 'Colombo to Nuwara Eliya (A7/A5 Mountain Climb)', 'actual': 41.20, 'modA': 28.01, 'modD': 39.34},
    {'id': 'J6', 'name': 'Nuwara Eliya to Kandy (A5 Ramboda Descent)', 'actual': 7.10, 'modA': 12.50, 'modD': 11.83},
    {'id': 'J7', 'name': 'Colombo to Dambulla (A1+A6 Midland Plains)', 'actual': 28.60, 'modA': 25.84, 'modD': 28.61},
    {'id': 'J8', 'name': 'Colombo to Katunayake (Airport Expressway)', 'actual': 6.90, 'modA': 6.33, 'modD': 6.66},
  ];

  print('\n=== STAGE 3 INDEPENDENT NUMERICAL AUDIT ===');
  final nJourneys = journeys.length;
  var sumAbsErrA = 0.0;
  var sumSqErrA = 0.0;
  var sumPctErrA = 0.0;

  var sumAbsErrD = 0.0;
  var sumSqErrD = 0.0;
  var sumPctErrD = 0.0;

  var maxUnderA = 0.0; // actual - pred > 0
  var maxOverA = 0.0;  // pred - actual > 0
  var maxUnderD = 0.0;
  var maxOverD = 0.0;

  for (final j in journeys) {
    final act = j['actual'] as double;
    final a = j['modA'] as double;
    final d = j['modD'] as double;

    final errA = a - act;
    final absErrA = errA.abs();
    sumAbsErrA += absErrA;
    sumSqErrA += errA * errA;
    sumPctErrA += (absErrA / act) * 100.0;

    if (act - a > maxUnderA) maxUnderA = act - a;
    if (a - act > maxOverA) maxOverA = a - act;

    final errD = d - act;
    final absErrD = errD.abs();
    sumAbsErrD += absErrD;
    sumSqErrD += errD * errD;
    sumPctErrD += (absErrD / act) * 100.0;

    if (act - d > maxUnderD) maxUnderD = act - d;
    if (d - act > maxOverD) maxOverD = d - act;
  }

  final maeA = sumAbsErrA / nJourneys;
  final rmseA = math.sqrt(sumSqErrA / nJourneys);
  final mapeA = sumPctErrA / nJourneys;

  final maeD = sumAbsErrD / nJourneys;
  final rmseD = math.sqrt(sumSqErrD / nJourneys);
  final mapeD = sumPctErrD / nJourneys;

  print('Model A: MAE=${maeA.toStringAsFixed(4)} (Reported: 4.38)');
  print('Model A: RMSE=${rmseA.toStringAsFixed(4)} (Reported: 5.78)');
  print('Model A: MAPE=${mapeA.toStringAsFixed(2)}% (Reported: 22.6%)');
  print('Model A: Max Underprediction = -${maxUnderA.toStringAsFixed(2)} kWh (J5: Colombo -> Nuwara Eliya)');
  print('Model A: Max Overprediction = +${maxOverA.toStringAsFixed(2)} kWh (J6: Nuwara Eliya -> Kandy)');

  print('\nModel D: MAE=${maeD.toStringAsFixed(4)} (Reported: 1.42)');
  print('Model D: RMSE=${rmseD.toStringAsFixed(4)} (Reported: 2.01)');
  print('Model D: MAPE=${mapeD.toStringAsFixed(2)}% (Reported: 11.7%)');
  print('Model D: Max Underprediction = -${maxUnderD.toStringAsFixed(2)} kWh (J5: Colombo -> Nuwara Eliya)');
  print('Model D: Max Overprediction = +${maxOverD.toStringAsFixed(2)} kWh (J6: Nuwara Eliya -> Kandy)');

  print('\nError Reductions:');
  print('  MAE: ${((maeA - maeD) / maeA * 100).toStringAsFixed(2)}% (Reported: 67.6%)');
  print('  RMSE: ${((rmseA - rmseD) / rmseA * 100).toStringAsFixed(2)}% (Reported: 65.2%)');
  print('  MAPE: ${((mapeA - mapeD) / mapeA * 100).toStringAsFixed(2)}% (Reported: 47.9%)');
  print('  Peak Underestimation Reduction: ${((maxUnderA - maxUnderD) / maxUnderA * 100).toStringAsFixed(2)}% (Reported: 85.9%)');

  // Hazard Detection Analysis & Confusion Matrix
  print('\n=== PRE-DEPARTURE HAZARD DETECTION CONFUSION MATRIX ===');
  // An unsafe scenario is defined as any journey where unassisted execution would cause a reserve violation (SoC < 10%).
  // Across the 15 corridor scenarios, how many are genuinely unsafe if attempted without charging?
  // OSRM represents the unassisted journey. OSRM violates reserve in 13 out of 15 scenarios!
  // The 2 safe scenarios are C1 @ 80% (36.4%) and C2 @ 80% (32.3%).
  // So Ground Truth Unsafe = 13 scenarios; Ground Truth Safe = 2 scenarios.
  // EVayLanka preDepartureHazardDetected:
  // Flags hazard in 13 scenarios (smartStops.isNotEmpty || evayEndKwh < reserveFloorKwh || initSoc < 50).
  // For C1 @ 80%: 0 stops, arrival 36.4%, initSoc 80 => hazardDetected = false (Correct Negative).
  // For C2 @ 80%: 0 stops, arrival 32.3%, initSoc 80 => hazardDetected = false (Correct Negative).
  // For C3 @ 80%: 0 stops planned by corridor planner, arrival 6.5% < 10% => evayEndKwh < reserveFloorKwh => hazardDetected = true (True Positive!).
  // For all other 12 scenarios: smartStops.isNotEmpty or initSoc < 50 => hazardDetected = true (True Positive!).
  // Confusion Matrix:
  // TP (True Positives) = 13
  // FP (False Positives) = 0
  // TN (True Negatives) = 2
  // FN (False Negatives) = 0
  // Sensitivity (Recall) = TP / (TP + FN) = 13 / 13 = 100.0%
  // Specificity = TN / (TN + FP) = 2 / 2 = 100.0%
  // Precision (PPV) = TP / (TP + FP) = 13 / 13 = 100.0%
  // Accuracy = (TP + TN) / 15 = 15 / 15 = 100.0%
  print('Confusion Matrix (Ground Truth = Unassisted Journey Violates Reserve Floor):');
  print('  Condition Positive (Unsafe trips): 13 (C1@30,50; C2@30,50; C3@30,50,80; C4@30,50,80; C5@30,50,80)');
  print('  Condition Negative (Safe trips):    2 (C1@80, C2@80)');
  print('  True Positives (TP):  13');
  print('  False Positives (FP):  0');
  print('  True Negatives (TN):   2');
  print('  False Negatives (FN):  0');
  print('  Sensitivity / Recall: 100.0% (13/13)');
  print('  Specificity:          100.0% (2/2)');
  print('  Precision / PPV:      100.0% (13/13)');
  print('  Overall Accuracy:     100.0% (15/15)');
}
