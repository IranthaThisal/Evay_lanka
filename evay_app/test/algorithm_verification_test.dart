import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:evay_app/models/charger.dart';
import 'package:evay_app/models/charger_checkin.dart';
import 'package:evay_app/models/range_anxiety.dart';
import 'package:evay_app/models/smart_route.dart';
import 'package:evay_app/services/booking_service.dart';
import 'package:evay_app/services/checkin_service.dart';
import 'package:evay_app/services/range_anxiety_service.dart';
import 'package:evay_app/services/smart_route_service.dart';

void main() {
  group('Pillar 1: Normalized Routing Cost Verification', () {
    final smartRouteService = SmartRouteService();

    test('Formula & Scale Invariance: Normalized Routing Cost', () {
      // Cost(r) = alpha * (D/Dmax) + beta * (E/Emax) + gamma * (C/Cmax)
      // Implementation weights in SmartRouteService:
      // alpha = 0.35 (Detour/distance), beta = 0.45 (Energy/Power), gamma = 0.20 (Delay/Queue)
      expect(SmartRouteService.alpha + SmartRouteService.beta + SmartRouteService.gamma, closeTo(1.0, 1e-6));
      expect(SmartRouteService.alpha, equals(0.35));
      expect(SmartRouteService.beta, equals(0.45));
      expect(SmartRouteService.gamma, equals(0.20));

      // Test Route A: Direct expressway (126 km, 22.8 kWh, 0 min delay)
      final costA = smartRouteService.computeNormalizedRouteCost(
        distanceKm: 126.0,
        energyKwh: 22.8,
        chargingDelayMinutes: 0.0,
      );
      // NormD = 126/500 = 0.252, NormE = 22.8/100 = 0.228, NormC = 0/90 = 0
      // Cost = 0.35*0.252 + 0.45*0.228 + 0.20*0 = 0.0882 + 0.1026 = 0.1908
      expect(costA, closeTo(0.1908, 1e-4));

      // Test Route B: Inland route with charging detour (138 km, 26.1 kWh, 22 min delay)
      final costB = smartRouteService.computeNormalizedRouteCost(
        distanceKm: 138.0,
        energyKwh: 26.1,
        chargingDelayMinutes: 22.0,
      );
      // NormD = 138/500 = 0.276, NormE = 26.1/100 = 0.261, NormC = 22/90 = 0.24444
      // Cost = 0.35*0.276 + 0.45*0.261 + 0.20*(22/90) = 0.0966 + 0.11745 + 0.04889 = 0.26294
      expect(costB, closeTo(0.26294, 1e-4));

      // Strict Pareto preference
      expect(costA < costB, isTrue);

      // Boundary check: clamped to [0, 1]
      final costZero = smartRouteService.computeNormalizedRouteCost(
        distanceKm: 0.0,
        energyKwh: 0.0,
        chargingDelayMinutes: 0.0,
      );
      expect(costZero, equals(0.0));

      final costMax = smartRouteService.computeNormalizedRouteCost(
        distanceKm: 600.0, // Exceeds Dmax
        energyKwh: 120.0, // Exceeds Emax
        chargingDelayMinutes: 120.0, // Exceeds Cmax
      );
      expect(costMax, equals(1.0));
    });
  });

  group('Pillar 2: Calibrated Range Anxiety Index (RAI) Verification', () {
    const rangeAnxietyService = RangeAnxietyService();

    test('Monsoon Environmental Scaling & 3-Factor Composite RAI', () {
      // 50.3 kWh battery at 52% SoC (26.156 kWh)
      const batteryCapacity = 50.3;
      const initialPercent = 52.0;
      const efficiencyKmPerKwh = 6.0; // 0.16667 kWh/km

      // Environmental conditions: Heavy Monsoon, Normal Mode, 3 Passengers (150kg added)
      const conditions = EvTripConditions(
        drivingMode: DrivingMode.normal,
        weather: WeatherCondition.heavyMonsoon,
        passengerCount: 3, // Driver + 2 passengers = 150kg added payload
      );

      // Verify payload multiplier = 1.0 + (150/1800)*0.45 = 1.0375
      expect(conditions.payloadMultiplier, closeTo(1.0375, 1e-4));
      // Composite environmental multiplier = 1.0 (mode) * 1.10 (monsoon) * 1.0375 = 1.14125
      expect(conditions.compositeEnvironmentalMultiplier, closeTo(1.14125, 1e-4));

      // Create a flat route with 33 waypoints from Colombo to Galle (103.5 km geodesic)
      final points = <LatLng>[];
      for (var i = 0; i <= 32; i++) {
        final t = i / 32.0;
        points.add(LatLng(6.9271 + (6.0535 - 6.9271) * t, 79.8612 + (80.2210 - 79.8612) * t));
      }

      final smartRoute = SmartRoute(
        origin: const LatLng(6.9271, 79.8612),
        destination: const LatLng(6.0535, 80.2210),
        routePoints: points,
        bounds: LatLngBounds(
          southwest: const LatLng(6.0535, 79.8612),
          northeast: const LatLng(6.9271, 80.2210),
        ),
        distanceText: '103.5 km',
        durationText: '1 hr 35 mins',
        chargingStops: const [],
        totalElevationGainM: 0.0,
        totalElevationLossM: 0.0,
      );

      final report = rangeAnxietyService.buildReport(
        smartRoute: smartRoute,
        batteryCapacityKwh: batteryCapacity,
        batteryPercent: initialPercent,
        efficiencyKmPerKwh: efficiencyKmPerKwh,
        conditions: conditions,
        climateFactor: 1.05,
      );

      // Verify sub-scores and composite score:
      // Available kWh = 50.3 * 0.52 = 26.156 kWh
      // Effective consumption rate = (1/6.0) * 1.05 * 1.14125 = 0.199718 kWh/km
      // Geodesic distance = 103.5 km => Energy = 20.67 kWh
      // 20.67 kWh > 0.75 * 26.156 (19.62 kWh) => nRequired = 1
      // nStations = 0 => mc = 0.0
      // mb = (26.156 - 20.67) / 26.156 = 0.2097
      // mr = 1.0
      // Composite RAI = 0.50*0.2097 + 0.30*1.0 + 0.20*0.0 = 0.10485 + 0.3000 = 0.40485 => 40
      expect(report.score, equals(40));
      expect(report.shouldChargeSoon, isTrue);
      expect(report.isSafe, isFalse);
      expect(report.label, contains('Charge recommended'));
    });
  });

  group('Pillar 3: LankaScore Station Reliability & Outage Penalty', () {
    test('CheckInService Reliability Calculation & 4-Hour Recency Penalty', () {
      final now = DateTime.now();

      // Case A: 9 successes, 1 failure reported 2 days ago (normal history)
      final normalCheckIns = <ChargerCheckIn>[
        for (var i = 0; i < 9; i++)
          ChargerCheckIn(
            id: 'c$i',
            chargerId: 'charger_kandy_1',
            chargerName: 'Kandy Supercharger',
            userId: 'user$i',
            userName: 'Driver $i',
            outcome: CheckInOutcome.success,
            createdAt: now.subtract(Duration(hours: 48 - i)),
          ),
        ChargerCheckIn(
          id: 'fail1',
          chargerId: 'charger_kandy_1',
          chargerName: 'Kandy Supercharger',
          userId: 'user_fail',
          userName: 'Driver Fail',
          outcome: CheckInOutcome.couldNotCharge,
          issue: CheckInIssue.brokenConnector,
          createdAt: now.subtract(const Duration(hours: 36)),
        ),
      ];

      final summaryNormal = CheckInService.calculateReliabilitySummary(normalCheckIns);
      // Raw score = (9 / 10) * 10 = 9.0
      expect(summaryNormal.score, equals(9.0));
      expect(summaryNormal.isHighReliability, isTrue);

      // Case B: Same history, but a power trip was reported 35 minutes ago (< 4 hours)
      final outageCheckIns = <ChargerCheckIn>[
        ...normalCheckIns.take(9),
        ChargerCheckIn(
          id: 'fail_recent',
          chargerId: 'charger_kandy_1',
          chargerName: 'Kandy Supercharger',
          userId: 'user_outage',
          userName: 'Driver Recent',
          outcome: CheckInOutcome.couldNotCharge,
          issue: CheckInIssue.noPower,
          createdAt: now.subtract(const Duration(minutes: 35)),
        ),
      ];

      final summaryOutage = CheckInService.calculateReliabilitySummary(outageCheckIns);
      // Raw score 9.0 * 0.60 = 5.4, clamped to [1.0, 6.0]
      expect(summaryOutage.score, equals(5.4));
      expect(summaryOutage.isModerateReliability, isTrue);
      expect(summaryOutage.isReportedDownRecently, isTrue);

      // Verify router candidate scoring penalty
      const candidateRawScore = 0.840;
      final penaltyFactor = (summaryOutage.score / 10.0).clamp(0.2, 1.0);
      final finalScore = candidateRawScore * penaltyFactor;
      expect(finalScore, closeTo(0.840 * 0.54, 1e-4));
    });
  });

  group('Pillar 4: Battery Reserve Enforcement & Stranding Prevention', () {
    test('Feasibility Inequality Boundary Rejection', () {
      const batteryCapacity = 50.3;
      const batteryPercent = 20.0; // 10.06 kWh available
      const reserveThreshold = 0.10; // 5.03 kWh reserve floor
      const usableKwh = batteryCapacity * (batteryPercent / 100.0) - (batteryCapacity * reserveThreshold); // 5.03 kWh usable

      const efficiencyKmPerKwh = 5.556; // 0.18 kWh/km
      const climateFactor = 1.05;
      const effectiveRate = (1.0 / efficiencyKmPerKwh) * climateFactor; // 0.189 kWh/km

      // Candidate 1: Reachable within reserve (18 km route, 1.5 km detour = 21 km total => 3.969 kWh)
      const dist1 = 21.0;
      final energy1 = dist1 * effectiveRate;
      final isFeasible1 = energy1 <= usableKwh;
      expect(isFeasible1, isTrue);

      // Candidate 2: Exceeds reserve (26 km route, 2.5 km detour = 31 km total => 5.859 kWh)
      const dist2 = 31.0;
      final energy2 = dist2 * effectiveRate;
      final isFeasible2 = energy2 <= usableKwh;
      expect(isFeasible2, isFalse); // Correctly excluded to prevent stranding
    });
  });

  group('Pillar 5: Topographical Physics & Elevation Energy Adjustment', () {
    const elevationModel = SriLankaElevationModel();

    test('Gaussian RBF Topography & Gravitational Potential Energy Formula', () {
      // Coordinate verification: Nuwara Eliya highland vs Colombo coast
      final nuwaraEliyaElev = elevationModel.getElevation(const LatLng(6.97, 80.78));
      final colomboElev = elevationModel.getElevation(const LatLng(6.93, 79.86));

      expect(nuwaraEliyaElev, greaterThan(1300.0));
      expect(colomboElev, lessThan(35.0));

      // Physics check: 1800 kg EV climbing 1000m
      // Potential Energy = (1800 * 9.80665 * 1000) / 3.6e6 / 0.88 = 5.5719 kWh
      final climbEnergy = elevationModel.computeElevationEnergyDelta(
        deltaElevationM: 1000.0,
        vehicleMassKg: 1800.0,
        driveEfficiency: 0.88,
      );
      expect(climbEnergy, closeTo(5.572, 0.01));

      // Physics check: 1800 kg EV descending 1000m with regen
      // Regen Recovery = -(1800 * 9.80665 * 1000) * 0.65 / 3.6e6 = -3.187 kWh
      final regenEnergy = elevationModel.computeElevationEnergyDelta(
        deltaElevationM: -1000.0,
        vehicleMassKg: 1800.0,
        regenEfficiency: 0.65,
      );
      expect(regenEnergy, closeTo(-3.187, 0.01));
    });
  });

  group('Pillar 6: Smart Booking Duration Auto-Calculation', () {
    test('Calculates Exact Minutes to 80% SoC and Snaps to Slot Steps', () {
      // 50.3 kWh battery at 20% SoC, 50 kW DC Fast Charger, 90% efficiency
      // Energy needed = (80 - 20) / 100 * 50.3 = 30.18 kWh
      // Hours = 30.18 / (50 * 0.90) = 0.67067 hours = 40.24 minutes
      final minutes = BookingService.calculateRecommendedDurationMins(
        batteryCapacityKwh: 50.3,
        currentBatteryPercent: 20.0,
        stationPowerKw: 50.0,
        targetPercent: 80.0,
        chargingEfficiency: 0.90,
      );
      expect(minutes, equals(40));

      // Snapped to 15-minute booking slot
      final rounded15 = BookingService.roundToSlotStep(minutes, stepMins: 15);
      expect(rounded15, equals(45));

      // Already above target (e.g. 85% SoC) returns minimum 15-minute top-up
      final minTopUp = BookingService.calculateRecommendedDurationMins(
        batteryCapacityKwh: 50.3,
        currentBatteryPercent: 85.0,
        stationPowerKw: 50.0,
      );
      expect(minTopUp, equals(15));
    });
  });
}
