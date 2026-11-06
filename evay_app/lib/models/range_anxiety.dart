import 'dart:math' as math;

import '../models/charger.dart';
import 'smart_route.dart';

enum DrivingMode {
  eco,
  normal,
  sport;

  /// Driving mode consumption multiplier
  double get consumptionMultiplier => switch (this) {
    DrivingMode.eco => 0.93,     // -7% consumption (smooth throttle, high regen)
    DrivingMode.normal => 1.00,  // Baseline
    DrivingMode.sport => 1.15,   // +15% consumption (aggressive acceleration, lower coasting)
  };

  String get label => switch (this) {
    DrivingMode.eco => 'Eco',
    DrivingMode.normal => 'Normal',
    DrivingMode.sport => 'Sport',
  };
}

enum WeatherCondition {
  dry,
  lightRain,
  heavyMonsoon;

  /// Rain increases tire rolling resistance due to water pooling and hydrodynamic drag
  double get rollingResistanceMultiplier => switch (this) {
    WeatherCondition.dry => 1.00,
    WeatherCondition.lightRain => 1.05,     // +5% rolling resistance
    WeatherCondition.heavyMonsoon => 1.10,  // +10% rolling resistance in tropical monsoon
  };

  String get label => switch (this) {
    WeatherCondition.dry => 'Dry',
    WeatherCondition.lightRain => 'Light Rain',
    WeatherCondition.heavyMonsoon => 'Monsoon Rain',
  };
}

class EvTripConditions {
  const EvTripConditions({
    this.drivingMode = DrivingMode.normal,
    this.weather = WeatherCondition.dry,
    this.passengerCount = 1,
    this.cargoWeightKg = 0.0,
    this.baselineVehicleMassKg = 1800.0,
  });

  final DrivingMode drivingMode;
  final WeatherCondition weather;
  final int passengerCount;
  final double cargoWeightKg;
  final double baselineVehicleMassKg;

  /// Added payload mass: passengers (75kg each after driver) + cargo
  double get addedPayloadMassKg =>
      math.max(0, (passengerCount - 1) * 75.0) + math.max(0, cargoWeightKg);

  /// Effective total vehicle mass
  double get totalVehicleMassKg => baselineVehicleMassKg + addedPayloadMassKg;

  /// Payload factor: each 100kg adds ~1.8% rolling & acceleration energy demand
  double get payloadMultiplier {
    final payloadRatio = addedPayloadMassKg / baselineVehicleMassKg;
    return 1.0 + (payloadRatio * 0.45);
  }

  /// Composite environmental & driver multiplier
  double get compositeEnvironmentalMultiplier {
    return drivingMode.consumptionMultiplier *
        weather.rollingResistanceMultiplier *
        payloadMultiplier;
  }
}

enum ReturnConfidence {
  safeReturn,              // Can reach destination and safely return to last DC charger
  destinationDependent,    // Low return margin; destination charging strongly advised
  pointOfNoReturnExceeded, // Cannot return without destination charging
}

class PointOfNoReturnInfo {
  const PointOfNoReturnInfo({
    required this.lastReliableCharger,
    required this.distanceToLastChargerKm,
    required this.energyNeededToReturnKwh,
    required this.returnBatteryPercentRemaining,
    required this.confidence,
    required this.pointOfNoReturnKmFromOrigin,
    required this.warningMessage,
  });

  final Charger lastReliableCharger;
  final double distanceToLastChargerKm;
  final double energyNeededToReturnKwh;
  final double returnBatteryPercentRemaining;
  final ReturnConfidence confidence;
  final double pointOfNoReturnKmFromOrigin;
  final String warningMessage;

  bool get isSafeToReturn => confidence == ReturnConfidence.safeReturn;
}

class RangeAnxietyReport {
  const RangeAnxietyReport({
    required this.score,
    required this.label,
    required this.summary,
    required this.estimatedRangeKm,
    required this.routeDistanceKm,
    required this.requiredDistanceKm,
    required this.bufferKm,
    required this.chargerFactor,
    required this.safetyMargin,
    this.recommendedStop,
    this.chargingStops = const [],
    this.totalElevationGainM = 0.0,
    this.elevationEnergyPenaltyKwh = 0.0,
    this.conditions = const EvTripConditions(),
    this.pointOfNoReturn,
  });

  final int score;
  final String label;
  final String summary;
  final double estimatedRangeKm;
  final double routeDistanceKm;
  final double requiredDistanceKm;
  final double bufferKm;
  final double chargerFactor;
  final double safetyMargin;
  final ChargingStop? recommendedStop;
  final List<ChargingStop> chargingStops;
  final double totalElevationGainM;
  final double elevationEnergyPenaltyKwh;
  final EvTripConditions conditions;
  final PointOfNoReturnInfo? pointOfNoReturn;

  bool get isSafe => score >= 70;
  bool get shouldChargeSoon => score >= 40 && score < 70;
  bool get isHighRisk => score < 40;
  bool get hasPointOfNoReturnWarning =>
      pointOfNoReturn != null &&
      pointOfNoReturn!.confidence != ReturnConfidence.safeReturn;
}
