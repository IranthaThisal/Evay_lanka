class SimulationResult {
  final double estimatedRangeKm;
  final double energyNeededKwh;
  final double estimatedCostLkr;
  final double petrolEquivalentLkr;
  final double savingsLkr;
  final double co2SavedKg;
  final double chargingTimeMinutes;

  SimulationResult({
    required this.estimatedRangeKm,
    required this.energyNeededKwh,
    required this.estimatedCostLkr,
    required this.petrolEquivalentLkr,
    required this.savingsLkr,
    required this.co2SavedKg,
    required this.chargingTimeMinutes,
  });
}

enum CebTariffBand {
  offPeak, // 22:30 - 05:30 (approx LKR 35 / kWh domestic)
  day,     // 05:30 - 18:30 (approx LKR 60 / kWh domestic)
  peak,    // 18:30 - 22:30 (approx LKR 115 / kWh domestic)
  commercialDcFast, // Public Fast Chargers (approx LKR 95 - 120 / kWh)
}

class SimulationService {
  // Climate factor for tropical Sri Lankan conditions (28-34C + A/C load)
  static const double defaultClimateFactor = 1.05;

  SimulationResult simulate({
    required double batteryCapacityKwh,
    required double batteryPercent,
    required double efficiencyKmPerKwh,
    required double tripDistanceKm,
    double chargerPowerKw = 50.0,
    double chargerEfficiency = 0.90, // eta_c in Eq. 5
    double climateFactor = defaultClimateFactor,
    CebTariffBand tariffBand = CebTariffBand.commercialDcFast,
    double petrolCostPerKm = 35.0, // Based on LKR 370/L petrol at ~10.5 km/L
  }) {
    // k_climate applied consistently across energy and range equations (Eqs. 3-4)
    final availableKwh = batteryCapacityKwh * (batteryPercent.clamp(0.0, 100.0) / 100.0);
    final rangeKm = (availableKwh * efficiencyKmPerKwh) / climateFactor;
    
    // Total energy required including climate HVAC penalty
    final ratedEfficiencyKwhPerKm = efficiencyKmPerKwh > 0 ? (1.0 / efficiencyKmPerKwh) : 0.18;
    final energyNeeded = tripDistanceKm * ratedEfficiencyKwhPerKm * climateFactor;

    // Sri Lanka CEB Tariff structure
    final double costPerKwh = switch (tariffBand) {
      CebTariffBand.offPeak => 35.0,
      CebTariffBand.day => 60.0,
      CebTariffBand.peak => 115.0,
      CebTariffBand.commercialDcFast => 95.0,
    };

    final cost = energyNeeded * costPerKwh;
    final petrolEq = tripDistanceKm * petrolCostPerKm;
    final savings = (petrolEq - cost).clamp(0.0, double.infinity);
    final co2Cut = tripDistanceKm * 0.15; // 0.15 kg CO2 per km offset

    // Eq. 5: Charging time in minutes to 80% SoC with charger efficiency
    final targetSoC = 80.0;
    final deltaSoC = (targetSoC - batteryPercent).clamp(0.0, 100.0);
    final energyToCharge = (deltaSoC / 100.0) * batteryCapacityKwh;
    final chargeTimeHours = energyToCharge / (chargerPowerKw * chargerEfficiency);
    final chargeTimeMins = (chargeTimeHours * 60.0).clamp(0.0, 360.0);

    return SimulationResult(
      estimatedRangeKm: rangeKm,
      energyNeededKwh: energyNeeded,
      estimatedCostLkr: cost,
      petrolEquivalentLkr: petrolEq,
      savingsLkr: savings,
      co2SavedKg: co2Cut,
      chargingTimeMinutes: chargeTimeMins,
    );
  }
}
