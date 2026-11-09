import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:evay_app/models/charger.dart';
import 'package:evay_app/models/range_anxiety.dart';
import 'package:evay_app/models/smart_route.dart';
import 'package:evay_app/services/range_anxiety_service.dart';
import 'package:evay_app/services/smart_route_service.dart';

void main() {
  group('Safety Enforcement & Pre-Departure Rejection Verification', () {
    const batteryCapacityKwh = 50.3; // 50.3 kWh standard pack (MG ZS EV)
    const ratedEfficiencyKwhPerKm = 0.1667; // 6.0 km/kWh
    const reserveFloorPercent = 10.0; // Strict 10% reserve threshold (5.03 kWh)
    const elevationModel = SriLankaElevationModel();

    // Corridor C3: Colombo to Nuwara Eliya (168.0 km, climbing into Central Highlands)
    final colombo = const LatLng(6.9271, 79.8612);
    final nuwaraEliya = const LatLng(6.9700, 80.7800);
    const corridorDistanceKm = 168.0;
    const numWaypoints = 55;

    final waypoints = <LatLng>[];
    for (var i = 0; i < numWaypoints; i++) {
      final t = i / (numWaypoints - 1).toDouble();
      waypoints.add(LatLng(
        colombo.latitude + (nuwaraEliya.latitude - colombo.latitude) * t,
        colombo.longitude + (nuwaraEliya.longitude - colombo.longitude) * t,
      ));
    }

    final (gainM, lossM) = elevationModel.computeGainAndLoss(waypoints);
    final netElevationKwh = elevationModel.computeElevationEnergyDelta(
      deltaElevationM: gainM - (lossM * 0.70),
      vehicleMassKg: 1800.0,
    );

    // True physical energy required for C3 climb: rolling + HVAC (5%) + elevation
    final tripEnergyDemandKwh =
        (corridorDistanceKm * ratedEfficiencyKwhPerKm * 1.05) + netElevationKwh;

    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(colombo.latitude, nuwaraEliya.latitude),
        math.min(colombo.longitude, nuwaraEliya.longitude),
      ),
      northeast: LatLng(
        math.max(colombo.latitude, nuwaraEliya.latitude),
        math.max(colombo.longitude, nuwaraEliya.longitude),
      ),
    );

    test('C3 @ 80% SoC without intermediate charging triggers reserve violation and is rejected before departure', () {
      const initialSocPercent = 80.0;
      final initialKwh = batteryCapacityKwh * (initialSocPercent / 100.0); // 40.24 kWh

      // Direct journey without intermediate charging injection
      final arrivalKwh = initialKwh - tripEnergyDemandKwh;
      final arrivalSocPercent = (arrivalKwh / batteryCapacityKwh) * 100.0;

      // Verify the simulated numerical outcome matches reported 6.5% arrival SoC
      expect(arrivalSocPercent, closeTo(6.5, 0.5));
      expect(arrivalSocPercent, lessThan(reserveFloorPercent));

      // Construct SmartRoute reflecting this unassisted trajectory
      final unassistedRoute = SmartRoute(
        origin: colombo,
        destination: nuwaraEliya,
        routePoints: waypoints,
        bounds: bounds,
        distanceText: '168 km',
        durationText: '4 hours 30 mins',
        chargingStops: const [],
        totalDistanceKm: corridorDistanceKm,
        totalElevationGainM: gainM,
        totalElevationLossM: lossM,
        arrivalBatteryPercent: arrivalSocPercent,
        totalChargingTimeMinutes: 0.0,
        totalEnergyConsumedKwh: tripEnergyDemandKwh,
        elevationEnergyPenaltyKwh: netElevationKwh,
        isFeasible: arrivalSocPercent >= reserveFloorPercent,
        hasReserveViolation: arrivalSocPercent < reserveFloorPercent,
      );

      // 1. Model level assertions
      expect(unassistedRoute.hasReserveViolation, isTrue,
          reason: 'Arrival SoC (6.5%) is below the 10.0% mandatory reserve threshold');
      expect(unassistedRoute.isFeasible, isFalse,
          reason: 'Infeasible route must be flagged as non-viable');
      expect(unassistedRoute.canInitiateNavigation, isFalse,
          reason: 'Turn-by-turn navigation must be prohibited when reserve is violated');

      // 2. Service level enforcement gate
      final isReadyForNavigation = SmartRouteService.validateNavigationReadiness(
        unassistedRoute,
        minimumReserveFloorPercent: reserveFloorPercent,
      );
      expect(isReadyForNavigation, isFalse,
          reason: 'SmartRouteService must veto navigation initiation for reserve violations');

      // 3. Pre-departure Range Anxiety Engine assessment
      const anxietyService = RangeAnxietyService();
      final report = anxietyService.buildReport(
        smartRoute: unassistedRoute,
        batteryCapacityKwh: batteryCapacityKwh,
        batteryPercent: initialSocPercent,
        efficiencyKmPerKwh: 6.0,
      );

      expect(report.isSafe, isFalse,
          reason: 'Range anxiety engine must reject unassisted mountain route as unsafe');
      expect(report.score, lessThan(70));
      expect(report.shouldChargeSoon || report.isHighRisk, isTrue);
    });

    test('C3 @ 80% SoC with planned charging stop achieves compliant arrival SoC and permits navigation initiation', () {
      const initialSocPercent = 80.0;
      final initialKwh = batteryCapacityKwh * (initialSocPercent / 100.0);

      // Intermediate charging stop at Ramboda Falls (nominal rating: 40 kW DC)
      final rambodaCharger = Charger(
        id: 'c_ram_1',
        name: 'Ramboda Falls DC',
        city: 'Ramboda',
        lat: 7.0500,
        lng: 80.7000,
        slots: 2,
        powerKw: 40.0,
      );

      // Energy accounting clarification:
      // netEnergyAddedToPackKwh = 16.0 kWh (net electrochemical energy delivered into the battery pack)
      // With charger conversion efficiency eta_c = 0.90, gross energy drawn from the station/grid is:
      // grossStationEnergyDrawnKwh = 16.0 / 0.90 = 17.78 kWh.
      // Effective charging power delivered into battery = 40.0 kW * 0.90 = 36.0 kW.
      // Required active charging duration = (16.0 kWh / 36.0 kW) * 60 = 26.67 min (~26.7 min).
      const netEnergyAddedToPackKwh = 16.0;
      const chargerEfficiency = 0.90;
      const chargingTimeMin = (netEnergyAddedToPackKwh / (40.0 * chargerEfficiency)) * 60.0; // 26.67 min
      final arrivalKwhWithStop = initialKwh + netEnergyAddedToPackKwh - tripEnergyDemandKwh;
      final compliantArrivalSoc = (arrivalKwhWithStop / batteryCapacityKwh) * 100.0;

      final chargingStop = ChargingStop(
        charger: rambodaCharger,
        distanceFromRouteKm: 1.2,
        distanceFromOriginKm: 135.0,
        score: 0.88,
        stopOrder: 1,
        arrivalSocPercent: 22.0,
        targetSocPercent: 55.0,
        chargingTimeMinutes: chargingTimeMin,
        energyAddedKwh: netEnergyAddedToPackKwh,
        elevationM: 1100.0,
      );

      final mitigatedRoute = SmartRoute(
        origin: colombo,
        destination: nuwaraEliya,
        routePoints: waypoints,
        bounds: bounds,
        distanceText: '170.4 km',
        durationText: '4 hours 58 mins',
        chargingStops: [chargingStop],
        totalDistanceKm: corridorDistanceKm + 2.4,
        totalElevationGainM: gainM,
        totalElevationLossM: lossM,
        arrivalBatteryPercent: compliantArrivalSoc,
        totalChargingTimeMinutes: chargingTimeMin,
        totalEnergyConsumedKwh: tripEnergyDemandKwh + (2.4 * ratedEfficiencyKwhPerKm * 1.05),
        elevationEnergyPenaltyKwh: netElevationKwh,
        isFeasible: compliantArrivalSoc >= reserveFloorPercent,
        hasReserveViolation: compliantArrivalSoc < reserveFloorPercent,
      );

      expect(compliantArrivalSoc, greaterThanOrEqualTo(reserveFloorPercent));
      expect(compliantArrivalSoc, closeTo(38.3, 1.0));
      expect(mitigatedRoute.hasReserveViolation, isFalse);
      expect(mitigatedRoute.isFeasible, isTrue);
      expect(mitigatedRoute.canInitiateNavigation, isTrue);

      final isReadyForNavigation = SmartRouteService.validateNavigationReadiness(
        mitigatedRoute,
        minimumReserveFloorPercent: reserveFloorPercent,
      );
      expect(isReadyForNavigation, isTrue,
          reason: 'Mitigated route with compliant arrival buffer is approved for departure');
    });
  });
}
