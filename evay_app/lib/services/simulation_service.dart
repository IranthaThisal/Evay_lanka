class SimulationResult {
  final double estimatedRangeKm;
  final double energyNeededKwh;
  final double estimatedCostLkr;
  final double petrolEquivalentLkr;

  SimulationResult({
    required this.estimatedRangeKm,
    required this.energyNeededKwh,
    required this.estimatedCostLkr,
    required this.petrolEquivalentLkr,
  });
}

class SimulationService {
  // Simple demo assumptions (you can improve later):
  // efficiency: km per kWh
  // costPerKwh: LKR per kWh (demo average)
  SimulationResult simulate({
    required double batteryCapacityKwh,
    required double batteryPercent,
    required double efficiencyKmPerKwh,
    required double tripDistanceKm,
    double costPerKwh = 70.0, // demo average
    double petrolCostPerKm = 35.0, // demo guess
  }) {
    final availableKwh = batteryCapacityKwh * (batteryPercent / 100.0);
    final rangeKm = availableKwh * efficiencyKmPerKwh;
    final energyNeeded = tripDistanceKm / efficiencyKmPerKwh;
    final cost = energyNeeded * costPerKwh;
    final petrolEq = tripDistanceKm * petrolCostPerKm;

    return SimulationResult(
      estimatedRangeKm: rangeKm,
      energyNeededKwh: energyNeeded,
      estimatedCostLkr: cost,
      petrolEquivalentLkr: petrolEq,
    );
  }
}
