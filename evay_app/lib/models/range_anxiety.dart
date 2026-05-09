import 'smart_route.dart';

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

  bool get isSafe => score >= 80;
  bool get shouldChargeSoon => score >= 50 && score < 80;
}
