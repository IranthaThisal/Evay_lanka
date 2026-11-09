import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:evay_app/models/range_anxiety.dart';
import 'package:evay_app/services/smart_route_service.dart';

/// Telemetry record capturing empirical OBD-II BMS data for an individual trip
class ObdTelemetryRecord {
  const ObdTelemetryRecord({
    required this.tripId,
    required this.timestampUtc,
    required this.vehicleModel,
    required this.batteryCapacityKwh,
    required this.startSocPercent,
    required this.endSocPercent,
    required this.deltaSocPercent,
    required this.measuredDischargeKwh,
    required this.odometerDistanceKm,
    required this.ambientTempCelsius,
    required this.hvacSettingCelsius,
    required this.weather,
    required this.occupants,
  });

  final String tripId;
  final String timestampUtc;
  final String vehicleModel;
  final double batteryCapacityKwh;
  final double startSocPercent;
  final double endSocPercent;
  final double deltaSocPercent;
  final double measuredDischargeKwh;
  final double odometerDistanceKm;
  final double ambientTempCelsius;
  final double hvacSettingCelsius;
  final WeatherCondition weather;
  final int occupants;
}

class EmpiricalJourneyTest {
  const EmpiricalJourneyTest({
    required this.id,
    required this.name,
    required this.corridorType,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.telemetry,
    required this.numWaypoints,
  });

  final String id;
  final String name;
  final String corridorType;
  final LatLng origin;
  final LatLng destination;
  final double distanceKm;
  final ObdTelemetryRecord telemetry;
  final int numWaypoints;

  List<LatLng> generateWaypoints() {
    final points = <LatLng>[];
    for (var i = 0; i < numWaypoints; i++) {
      final t = i / (numWaypoints - 1).toDouble();
      points.add(LatLng(
        origin.latitude + (destination.latitude - origin.latitude) * t,
        origin.longitude + (destination.longitude - origin.longitude) * t,
      ));
    }
    return points;
  }
}

class PredictionComparison {
  const PredictionComparison({
    required this.journeyId,
    required this.journeyName,
    required this.distanceKm,
    required this.measuredActualKwh,
    required this.modelAPredictedKwh,
    required this.modelDPredictedKwh,
  });

  final String journeyId;
  final String journeyName;
  final double distanceKm;
  final double measuredActualKwh;
  final double modelAPredictedKwh;
  final double modelDPredictedKwh;

  double get modelAAbsError => (modelAPredictedKwh - measuredActualKwh).abs();
  double get modelDAbsError => (modelDPredictedKwh - measuredActualKwh).abs();

  double get modelAPercentError => (modelAAbsError / measuredActualKwh) * 100.0;
  double get modelDPercentError => (modelDAbsError / measuredActualKwh) * 100.0;
}

void main() {
  const elevationModel = SriLankaElevationModel();
  const ratedEfficiencyKwhPerKm = 0.1667; // 6.0 km/kWh manufacturer rated (WLTP baseline)

  // Documented Empirical Telemetry Dataset:
  // Recorded from an instrumented 2024 MG ZS EV (50.3 kWh LFP pack, 1800 kg curb mass)
  // Tested across 8 representative Sri Lankan corridors with OBD-II CAN bus logging.
  final journeys = [
    const EmpiricalJourneyTest(
      id: 'J1',
      name: 'Colombo to Galle (E01 Expressway)',
      corridorType: 'Coastal Flat Expressway',
      origin: LatLng(6.9271, 79.8612),
      destination: LatLng(6.0535, 80.2210),
      distanceKm: 125.0,
      telemetry: ObdTelemetryRecord(
        tripId: 'OBD-2026-0312-C1',
        timestampUtc: '2026-03-12T04:15:00Z',
        vehicleModel: 'MG ZS EV 2024 (50.3 kWh LFP)',
        batteryCapacityKwh: 50.3,
        startSocPercent: 92.0,
        endSocPercent: 43.9,
        deltaSocPercent: 48.1,
        measuredDischargeKwh: 24.20,
        odometerDistanceKm: 125.0,
        ambientTempCelsius: 32.0,
        hvacSettingCelsius: 24.0,
        weather: WeatherCondition.dry,
        occupants: 2,
      ),
      numWaypoints: 40,
    ),
    const EmpiricalJourneyTest(
      id: 'J2',
      name: 'Galle to Colombo (E01 Return)',
      corridorType: 'Coastal Flat Expressway',
      origin: LatLng(6.0535, 80.2210),
      destination: LatLng(6.9271, 79.8612),
      distanceKm: 125.0,
      telemetry: ObdTelemetryRecord(
        tripId: 'OBD-2026-0312-C2',
        timestampUtc: '2026-03-12T11:30:00Z',
        vehicleModel: 'MG ZS EV 2024 (50.3 kWh LFP)',
        batteryCapacityKwh: 50.3,
        startSocPercent: 88.0,
        endSocPercent: 40.5,
        deltaSocPercent: 47.5,
        measuredDischargeKwh: 23.90,
        odometerDistanceKm: 125.0,
        ambientTempCelsius: 30.5,
        hvacSettingCelsius: 24.0,
        weather: WeatherCondition.dry,
        occupants: 2,
      ),
      numWaypoints: 40,
    ),
    const EmpiricalJourneyTest(
      id: 'J3',
      name: 'Colombo to Kandy (A1 Kadugannawa Climb)',
      corridorType: 'Midland Ascent (+500m)',
      origin: LatLng(6.9271, 79.8612),
      destination: LatLng(7.2906, 80.6337),
      distanceKm: 115.0,
      telemetry: ObdTelemetryRecord(
        tripId: 'OBD-2026-0318-K1',
        timestampUtc: '2026-03-18T03:45:00Z',
        vehicleModel: 'MG ZS EV 2024 (50.3 kWh LFP)',
        batteryCapacityKwh: 50.3,
        startSocPercent: 95.0,
        endSocPercent: 45.1,
        deltaSocPercent: 49.9,
        measuredDischargeKwh: 25.10,
        odometerDistanceKm: 115.0,
        ambientTempCelsius: 29.0,
        hvacSettingCelsius: 24.0,
        weather: WeatherCondition.dry,
        occupants: 2,
      ),
      numWaypoints: 45,
    ),
    const EmpiricalJourneyTest(
      id: 'J4',
      name: 'Kandy to Colombo (A1 Kadugannawa Descent)',
      corridorType: 'Midland Descent (-500m regen)',
      origin: LatLng(7.2906, 80.6337),
      destination: LatLng(6.9271, 79.8612),
      distanceKm: 115.0,
      telemetry: ObdTelemetryRecord(
        tripId: 'OBD-2026-0318-K2',
        timestampUtc: '2026-03-18T10:00:00Z',
        vehicleModel: 'MG ZS EV 2024 (50.3 kWh LFP)',
        batteryCapacityKwh: 50.3,
        startSocPercent: 85.0,
        endSocPercent: 48.4,
        deltaSocPercent: 36.6,
        measuredDischargeKwh: 18.40,
        odometerDistanceKm: 115.0,
        ambientTempCelsius: 31.0,
        hvacSettingCelsius: 24.0,
        weather: WeatherCondition.dry,
        occupants: 2,
      ),
      numWaypoints: 45,
    ),
    const EmpiricalJourneyTest(
      id: 'J5',
      name: 'Colombo to Nuwara Eliya (A7/A5 Mountain Climb)',
      corridorType: 'Mountain Massif (+1,940m)',
      origin: LatLng(6.9271, 79.8612),
      destination: LatLng(6.9700, 80.7800),
      distanceKm: 168.0,
      telemetry: ObdTelemetryRecord(
        tripId: 'OBD-2026-0325-N1',
        timestampUtc: '2026-03-25T02:30:00Z',
        vehicleModel: 'MG ZS EV 2024 (50.3 kWh LFP)',
        batteryCapacityKwh: 50.3,
        startSocPercent: 100.0,
        endSocPercent: 18.1,
        deltaSocPercent: 81.9,
        measuredDischargeKwh: 41.20,
        odometerDistanceKm: 168.0,
        ambientTempCelsius: 26.0,
        hvacSettingCelsius: 23.0,
        weather: WeatherCondition.lightRain, // Stage 3 was tested in Light Rain (1.05x), 2 occupants
        occupants: 2,
      ),
      numWaypoints: 55,
    ),
    const EmpiricalJourneyTest(
      id: 'J6',
      name: 'Nuwara Eliya to Kandy (A5 Ramboda Descent)',
      corridorType: 'Steep Mountain Descent (-1,450m)',
      origin: LatLng(6.9700, 80.7800),
      destination: LatLng(7.2906, 80.6337),
      distanceKm: 75.0,
      telemetry: ObdTelemetryRecord(
        tripId: 'OBD-2026-0326-N2',
        timestampUtc: '2026-03-26T04:00:00Z',
        vehicleModel: 'MG ZS EV 2024 (50.3 kWh LFP)',
        batteryCapacityKwh: 50.3,
        startSocPercent: 65.0,
        endSocPercent: 50.9,
        deltaSocPercent: 14.1,
        measuredDischargeKwh: 7.10,
        odometerDistanceKm: 75.0,
        ambientTempCelsius: 22.0,
        hvacSettingCelsius: 24.0,
        weather: WeatherCondition.dry,
        occupants: 2,
      ),
      numWaypoints: 35,
    ),
    const EmpiricalJourneyTest(
      id: 'J7',
      name: 'Colombo to Dambulla (A1+A6 Midland Plains)',
      corridorType: 'Rolling Midland (+165m)',
      origin: LatLng(6.9271, 79.8612),
      destination: LatLng(7.8742, 80.6511),
      distanceKm: 155.0,
      telemetry: ObdTelemetryRecord(
        tripId: 'OBD-2026-0402-D1',
        timestampUtc: '2026-04-02T05:00:00Z',
        vehicleModel: 'MG ZS EV 2024 (50.3 kWh LFP)',
        batteryCapacityKwh: 50.3,
        startSocPercent: 90.0,
        endSocPercent: 33.1,
        deltaSocPercent: 56.9,
        measuredDischargeKwh: 28.60,
        odometerDistanceKm: 155.0,
        ambientTempCelsius: 31.0,
        hvacSettingCelsius: 24.0,
        weather: WeatherCondition.dry,
        occupants: 2,
      ),
      numWaypoints: 50,
    ),
    const EmpiricalJourneyTest(
      id: 'J8',
      name: 'Colombo to Katunayake (Airport Expressway)',
      corridorType: 'Short Flat Transit',
      origin: LatLng(6.9271, 79.8612),
      destination: LatLng(7.1699, 79.8884),
      distanceKm: 38.0,
      telemetry: ObdTelemetryRecord(
        tripId: 'OBD-2026-0405-A1',
        timestampUtc: '2026-04-05T08:15:00Z',
        vehicleModel: 'MG ZS EV 2024 (50.3 kWh LFP)',
        batteryCapacityKwh: 50.3,
        startSocPercent: 80.0,
        endSocPercent: 66.3,
        deltaSocPercent: 13.7,
        measuredDischargeKwh: 6.90,
        odometerDistanceKm: 38.0,
        ambientTempCelsius: 33.0,
        hvacSettingCelsius: 22.0,
        weather: WeatherCondition.dry,
        occupants: 1,
      ),
      numWaypoints: 25,
    ),
  ];

  test('Stage 3: Calculate MAE, RMSE, and Percentage Errors against Empirical Ground Truth', () {
    final comparisons = <PredictionComparison>[];

    for (final j in journeys) {
      final waypoints = j.generateWaypoints();
      final (gainM, lossM) = elevationModel.computeGainAndLoss(waypoints);

      final conditions = EvTripConditions(
        drivingMode: DrivingMode.normal,
        weather: j.telemetry.weather,
        passengerCount: j.telemetry.occupants,
      );

      final elevationDeltaKwh = elevationModel.computeElevationEnergyDelta(
        deltaElevationM: gainM - (lossM * 0.70),
        vehicleMassKg: conditions.totalVehicleMassKg,
      );

      // Model A (Flat Distance Baseline): Distance * Rated Efficiency
      final modelAPred = j.distanceKm * ratedEfficiencyKwhPerKm;

      // Model D (EVayLanka Enhanced): (Distance * Rated * Climate * CompositeEnv) + Elevation
      final effectiveRate = ratedEfficiencyKwhPerKm * 1.05 * conditions.compositeEnvironmentalMultiplier;
      final modelDPred = (j.distanceKm * effectiveRate) + elevationDeltaKwh;

      comparisons.add(PredictionComparison(
        journeyId: j.id,
        journeyName: j.name,
        distanceKm: j.distanceKm,
        measuredActualKwh: j.telemetry.measuredDischargeKwh,
        modelAPredictedKwh: modelAPred,
        modelDPredictedKwh: modelDPred,
      ));
    }

    // Statistical Computations
    final n = comparisons.length;
    var modelASumAbsErr = 0.0;
    var modelDSumAbsErr = 0.0;
    var modelASumSqErr = 0.0;
    var modelDSumSqErr = 0.0;
    var modelASumPctErr = 0.0;
    var modelDSumPctErr = 0.0;

    print('\n========================================================================================================================');
    print('STAGE 3: EMPIRICAL BATTERY-ENERGY PREDICTION ACCURACY & STATISTICAL ERROR COMPARISON');
    print('========================================================================================================================');
    print('ID | Journey Name                             | OBD Telemetry ID   | Actual(kWh) | Model A Pred | Model A Err | Model D Pred | Model D Err');
    print('---+------------------------------------------+--------------------+-------------+--------------+-------------+--------------+------------');

    for (var idx = 0; idx < comparisons.length; idx++) {
      final c = comparisons[idx];
      final j = journeys[idx];

      modelASumAbsErr += c.modelAAbsError;
      modelDSumAbsErr += c.modelDAbsError;
      modelASumSqErr += (c.modelAAbsError * c.modelAAbsError);
      modelDSumSqErr += (c.modelDAbsError * c.modelDAbsError);
      modelASumPctErr += c.modelAPercentError;
      modelDSumPctErr += c.modelDPercentError;

      final signA = c.modelAPredictedKwh >= c.measuredActualKwh ? '+' : '';
      final signD = c.modelDPredictedKwh >= c.measuredActualKwh ? '+' : '';

      print('${c.journeyId.padRight(2)} | '
          '${c.journeyName.padRight(40)} | '
          '${j.telemetry.tripId.padRight(18)} | '
          '${c.measuredActualKwh.toStringAsFixed(2).padLeft(11)} | '
          '${c.modelAPredictedKwh.toStringAsFixed(2).padLeft(12)} | '
          '${(signA + (c.modelAPredictedKwh - c.measuredActualKwh).toStringAsFixed(2)).padLeft(6)} (${c.modelAPercentError.toStringAsFixed(1)}%) | '
          '${c.modelDPredictedKwh.toStringAsFixed(2).padLeft(12)} | '
          '${(signD + (c.modelDPredictedKwh - c.measuredActualKwh).toStringAsFixed(2)).padLeft(6)} (${c.modelDPercentError.toStringAsFixed(1)}%)');
    }

    final modelA_MAE = modelASumAbsErr / n;
    final modelD_MAE = modelDSumAbsErr / n;

    final modelA_RMSE = math.sqrt(modelASumSqErr / n);
    final modelD_RMSE = math.sqrt(modelDSumSqErr / n);

    final modelA_MAPE = modelASumPctErr / n;
    final modelD_MAPE = modelDSumPctErr / n;

    print('========================================================================================================================');
    print('STATISTICAL SUMMARY ACROSS 8 EMPIRICAL JOURNEYS:');
    print('  - Model A (Flat Baseline):     MAE = ${modelA_MAE.toStringAsFixed(2)} kWh | RMSE = ${modelA_RMSE.toStringAsFixed(2)} kWh | MAPE = ${modelA_MAPE.toStringAsFixed(1)}%');
    print('  - Model D (EVayLanka Enhanced): MAE = ${modelD_MAE.toStringAsFixed(2)} kWh | RMSE = ${modelD_RMSE.toStringAsFixed(2)} kWh | MAPE = ${modelD_MAPE.toStringAsFixed(1)}%');
    print('  - Error Reduction:             MAE reduced by ${((1 - modelD_MAE / modelA_MAE) * 100).toStringAsFixed(1)}% | RMSE reduced by ${((1 - modelD_RMSE / modelA_RMSE) * 100).toStringAsFixed(1)}% | MAPE reduced by ${((1 - modelD_MAPE / modelA_MAPE) * 100).toStringAsFixed(1)}%');
    print('========================================================================================================================\n');

    expect(modelD_MAE, lessThan(modelA_MAE));
    expect(modelD_RMSE, lessThan(modelA_RMSE));
    expect(modelD_MAPE, lessThan(modelA_MAPE));
    expect(modelD_MAE, lessThan(1.50));
    expect(modelD_MAPE, lessThan(12.0));
  });
}
