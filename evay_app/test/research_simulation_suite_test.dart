import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:evay_app/models/charger.dart';
import 'package:evay_app/models/charger_checkin.dart';
import 'package:evay_app/models/range_anxiety.dart';
import 'package:evay_app/models/smart_route.dart';
import 'package:evay_app/services/checkin_service.dart';
import 'package:evay_app/services/smart_route_service.dart';

class CorridorScenario {
  const CorridorScenario({
    required this.name,
    required this.origin,
    required this.destination,
    required this.roadDistanceKm,
    required this.numWaypoints,
  });

  final String name;
  final LatLng origin;
  final LatLng destination;
  final double roadDistanceKm;
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

void main() {
  const elevationModel = SriLankaElevationModel();

  // Reference Sri Lanka Corridors
  final corridors = [
    const CorridorScenario(
      name: 'Colombo to Galle (Coastal Flat)',
      origin: LatLng(6.9271, 79.8612),
      destination: LatLng(6.0535, 80.2210),
      roadDistanceKm: 125.0,
      numWaypoints: 40,
    ),
    const CorridorScenario(
      name: 'Colombo to Kandy (Midland Ascent)',
      origin: LatLng(6.9271, 79.8612),
      destination: LatLng(7.2906, 80.6337),
      roadDistanceKm: 115.0,
      numWaypoints: 45,
    ),
    const CorridorScenario(
      name: 'Colombo to Nuwara Eliya (Central Massif)',
      origin: LatLng(6.9271, 79.8612),
      destination: LatLng(6.9700, 80.7800),
      roadDistanceKm: 168.0,
      numWaypoints: 55,
    ),
    const CorridorScenario(
      name: 'Colombo to Jaffna (Northern Long-Distance)',
      origin: LatLng(6.9271, 79.8612),
      destination: LatLng(9.6615, 80.0255),
      roadDistanceKm: 395.0,
      numWaypoints: 70,
    ),
    const CorridorScenario(
      name: 'Hambantota to Trincomalee (Cross-Country)',
      origin: LatLng(6.1246, 81.1185),
      destination: LatLng(8.5874, 81.2152),
      roadDistanceKm: 350.0,
      numWaypoints: 65,
    ),
  ];

  group('Research Experiment 1: Multi-Corridor Topography & Physics Profile', () {
    test('Calculates Topographical Profile and Energy Penalties for All Corridors', () {
      print('\n================================================================================');
      print('TABLE I: SRI LANKAN CORRIDOR TOPOGRAPHICAL & ENERGY PROFILE (VEHICLE: 1800 KG)');
      print('================================================================================');
      print('Corridor Name                       | Dist(km) | Climb(m) | Desc(m) | ElevNet(kWh) | AvgElev(m)');
      print('------------------------------------+----------+----------+---------+--------------+-----------');

      for (final corridor in corridors) {
        final wps = corridor.generateWaypoints();
        final (gainM, lossM) = elevationModel.computeGainAndLoss(wps);
        final netElevKwh = elevationModel.computeElevationEnergyDelta(
          deltaElevationM: gainM - (lossM * 0.70),
          vehicleMassKg: 1800.0,
        );

        var sumElev = 0.0;
        for (final p in wps) {
          sumElev += elevationModel.getElevation(p);
        }
        final avgElev = sumElev / wps.length;

        print('${corridor.name.padRight(35)} | '
            '${corridor.roadDistanceKm.toStringAsFixed(1).padLeft(8)} | '
            '${gainM.toStringAsFixed(0).padLeft(8)} | '
            '${lossM.toStringAsFixed(0).padLeft(7)} | '
            '${netElevKwh.toStringAsFixed(2).padLeft(12)} | '
            '${avgElev.toStringAsFixed(0).padLeft(9)}m');

        expect(gainM, greaterThanOrEqualTo(0.0));
        expect(lossM, greaterThanOrEqualTo(0.0));
      }
      print('================================================================================\n');
    });
  });

  group('Research Experiment 2: Battery Energy Model Ablation Study', () {
    test('Compares Model A (Flat) vs B (+Climate) vs C (+Elevation) vs D (Full)', () {
      const batteryCapacityKwh = 50.3; // Standard 50.3 kWh EV Pack
      const ratedEfficiencyKwhPerKm = 0.1667; // 6.0 km/kWh

      // Conditions for Model D
      const fullConditions = EvTripConditions(
        drivingMode: DrivingMode.normal,
        weather: WeatherCondition.heavyMonsoon, // +10%
        passengerCount: 3, // Driver + 2 passengers (+150kg => +3.75%)
      );

      print('\n====================================================================================================');
      print('TABLE II: 4-TIER MODEL ENERGY ABLATION STUDY (50.3 KWH PACK @ 80% SOC = 40.24 KWH)');
      print('====================================================================================================');
      print('Corridor Name                       | Model A(kWh) | Model B(kWh) | Model C(kWh) | Model D(kWh) | Delta(D-A)');
      print('------------------------------------+--------------+--------------+--------------+--------------+-----------');

      var falseSafePredictionsCount = 0;

      for (final corridor in corridors) {
        final wps = corridor.generateWaypoints();
        final (gainM, lossM) = elevationModel.computeGainAndLoss(wps);
        final elevationKwh = elevationModel.computeElevationEnergyDelta(
          deltaElevationM: gainM - (lossM * 0.70),
          vehicleMassKg: fullConditions.totalVehicleMassKg,
        );

        // Model A: Flat Distance Only
        final modelA_Kwh = corridor.roadDistanceKm * ratedEfficiencyKwhPerKm;

        // Model B: Flat + Climate HVAC (1.05x)
        final modelB_Kwh = corridor.roadDistanceKm * ratedEfficiencyKwhPerKm * 1.05;

        // Model C: Flat + Climate + Elevation / Regen
        final modelC_Kwh = modelB_Kwh + elevationKwh;

        // Model D: Full EVayLanka (Climate + Elevation + Heavy Monsoon + Payload)
        final effectiveRateD = ratedEfficiencyKwhPerKm * 1.05 * fullConditions.compositeEnvironmentalMultiplier;
        final modelD_Kwh = (corridor.roadDistanceKm * effectiveRateD) + elevationKwh;

        final deltaKwh = modelD_Kwh - modelA_Kwh;
        final deltaPercent = (deltaKwh / modelA_Kwh) * 100.0;

        print('${corridor.name.padRight(35)} | '
            '${modelA_Kwh.toStringAsFixed(2).padLeft(12)} | '
            '${modelB_Kwh.toStringAsFixed(2).padLeft(12)} | '
            '${modelC_Kwh.toStringAsFixed(2).padLeft(12)} | '
            '${modelD_Kwh.toStringAsFixed(2).padLeft(12)} | '
            '+${deltaKwh.toStringAsFixed(2)} (+${deltaPercent.toStringAsFixed(1)}%)');

        // False Safe Check: Does Model A predict arrival on 40.24 kWh, while Model D exceeds capacity?
        if (modelA_Kwh <= 40.24 && modelD_Kwh > 40.24) {
          falseSafePredictionsCount++;
          print('  ⚠️ [CRITICAL HAZARD DETECTED]: Model A predicts trip is safe without charging, '
              'but Model D proves battery exhaustion (+${(modelD_Kwh - 40.24).toStringAsFixed(1)} kWh deficit)!');
        }

        expect(modelD_Kwh, greaterThan(modelA_Kwh));
      }
      print('====================================================================================================');
      print('Total False-Safe Stranding Hazards Prevented by Enhanced Model: $falseSafePredictionsCount');
      print('====================================================================================================\n');
    });
  });

  group('Research Experiment 3: Grid Outage & LankaScore Rerouting Simulation', () {
    test('Simulates Outage Injection, Time-Decay Recovery, and Candidate Switching', () {
      final now = DateTime.now();

      // Test Station 1 baseline: 18 success, 2 failure
      final baseCheckIns = <ChargerCheckIn>[
        for (var i = 0; i < 18; i++)
          ChargerCheckIn(
            id: 'ok_$i',
            chargerId: 'station_1',
            chargerName: 'Station 1 (High Power)',
            userId: 'u$i',
            userName: 'Driver $i',
            outcome: CheckInOutcome.success,
            createdAt: now.subtract(Duration(hours: 48 - i)),
          ),
      ];

      print('\n================================================================================');
      print('TABLE III: LANKASCORE RECOVERY DYNAMICS FOLLOWING GRID OUTAGE INJECTION');
      print('================================================================================');
      print('Elapsed Time Since Outage | LankaScore | Status Class | Candidate Routing Multiplier');
      print('--------------------------+------------+--------------+-----------------------------');

      final elapsedHours = [0.25, 1.0, 2.5, 3.75, 4.25, 8.0, 24.0];

      for (final h in elapsedHours) {
        final checkIns = [
          ...baseCheckIns,
          ChargerCheckIn(
            id: 'outage',
            chargerId: 'station_1',
            chargerName: 'Station 1 (High Power)',
            userId: 'u_outage',
            userName: 'Outage Reporter',
            outcome: CheckInOutcome.couldNotCharge,
            issue: CheckInIssue.noPower,
            createdAt: now.subtract(Duration(minutes: (h * 60).round())),
          ),
        ];

        final summary = CheckInService.calculateReliabilitySummary(checkIns);
        final multiplier = (summary.score / 10.0).clamp(0.2, 1.0);
        final statusLabel = summary.isReportedDownRecently ? 'DOWN (Penalty)' : (summary.isHighReliability ? 'HIGH' : 'MODERATE');

        final timeStr = h < 1.0 ? '${(h * 60).round()} mins' : '${h.toStringAsFixed(1)} hrs';
        print('${timeStr.padRight(25)} | '
            '${summary.score.toStringAsFixed(1).padLeft(10)} | '
            '${statusLabel.padRight(12)} | '
            '${multiplier.toStringAsFixed(3).padLeft(26)}x');

        if (h < 4.0) {
          expect(summary.isReportedDownRecently, isTrue);
          expect(summary.score, lessThanOrEqualTo(6.0));
        } else {
          expect(summary.isReportedDownRecently, isFalse);
          expect(summary.score, greaterThan(8.0));
        }
      }
      print('================================================================================\n');
    });
  });
}
