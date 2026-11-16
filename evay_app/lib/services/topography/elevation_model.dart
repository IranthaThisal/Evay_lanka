import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Topographical elevation anchor point representing key relief features in Sri Lanka.
class ElevationAnchor {
  const ElevationAnchor(this.lat, this.lng, this.elevationM, this.radiusKm)
      : invTwoSigmaSq = -1.0 / (2.0 * radiusKm * radiusKm),
        // Cutoff at weight = 1e-4 => -ln(1e-4) * 2 * sigma^2 = 18.42068 * sigma^2
        cutoffDistSqKm = 18.420680743952367 * radiusKm * radiusKm;

  final double lat;
  final double lng;
  final double elevationM;
  final double radiusKm;
  final double invTwoSigmaSq;
  final double cutoffDistSqKm;
}

/// Sri Lanka Topographical & Elevation Modeling Service.
/// Models the distinct central highland massif (Nuwara Eliya, Kandy, Hatton, Ella)
/// transitioning into midland plateaus and coastal lowlands.
/// Calculates gravitational potential energy penalties and regenerative braking recovery.
class SriLankaElevationModel {
  const SriLankaElevationModel();

  // Equirectangular scale factors at Sri Lanka's mean latitude (~7.87° N)
  static const double _kmPerDegLat = 110.574;
  static const double _kmPerDegLng = 110.250;

  // Reference topography anchors across Sri Lanka's geographical zones
  static const List<ElevationAnchor> anchors = [
    // Central Highlands Massif (High Altitude 1,000m - 2,500m)
    ElevationAnchor(6.97, 80.78, 1950.0, 22.0), // Nuwara Eliya / Pidurutalagala Base
    ElevationAnchor(6.80, 80.80, 2130.0, 16.0), // Horton Plains / World's End
    ElevationAnchor(6.81, 80.50, 1850.0, 14.0), // Adam's Peak (Sri Pada)
    ElevationAnchor(6.89, 80.60, 1270.0, 16.0), // Hatton / Dikoya / Talawakele
    ElevationAnchor(6.85, 81.04, 1040.0, 18.0), // Ella / Bandarawela
    ElevationAnchor(6.77, 80.96, 1430.0, 15.0), // Haputale ridge
    ElevationAnchor(7.40, 80.78, 1450.0, 20.0), // Knuckles Mountain Range
    ElevationAnchor(7.05, 80.72, 1100.0, 15.0), // Ramboda Pass

    // Midland Plateaus & Foothills (300m - 700m)
    ElevationAnchor(7.29, 80.63, 500.0, 20.0),  // Kandy Valley / Peradeniya
    ElevationAnchor(7.25, 80.52, 520.0, 12.0),  // Kadugannawa Pass
    ElevationAnchor(7.12, 80.57, 560.0, 15.0),  // Gampola / Nawalapitiya
    ElevationAnchor(6.99, 81.05, 680.0, 16.0),  // Badulla Valley
    ElevationAnchor(7.47, 80.62, 364.0, 16.0),  // Matale
    ElevationAnchor(6.65, 80.70, 530.0, 18.0),  // Balangoda
    ElevationAnchor(6.68, 80.40, 130.0, 22.0),  // Ratnapura foothills
    ElevationAnchor(7.48, 80.36, 116.0, 25.0),  // Kurunegala
    ElevationAnchor(7.87, 80.65, 175.0, 25.0),  // Dambulla / Sigiriya
    ElevationAnchor(6.87, 81.35, 180.0, 25.0),  // Monaragala / Wellawaya

    // Lowland Plains & Coastal Belt (0m - 80m)
    ElevationAnchor(6.93, 79.86, 10.0, 35.0),   // Colombo / Western Coast
    ElevationAnchor(7.21, 79.84, 5.0, 30.0),    // Negombo
    ElevationAnchor(6.03, 80.22, 12.0, 35.0),   // Galle / Southern Coast
    ElevationAnchor(6.12, 81.12, 15.0, 35.0),   // Hambantota / Mattala
    ElevationAnchor(8.58, 81.23, 10.0, 40.0),   // Trincomalee / Eastern Bay
    ElevationAnchor(7.71, 81.70, 8.0, 35.0),    // Batticaloa
    ElevationAnchor(8.33, 80.41, 81.0, 35.0),   // Anuradhapura
    ElevationAnchor(7.94, 81.00, 60.0, 30.0),   // Polonnaruwa
    ElevationAnchor(8.75, 80.50, 45.0, 35.0),   // Vavuniya
    ElevationAnchor(9.38, 80.40, 15.0, 35.0),   // Kilinochchi
    ElevationAnchor(9.66, 80.01, 5.0, 40.0),    // Jaffna Peninsula
    ElevationAnchor(8.98, 79.91, 5.0, 35.0),    // Mannar Island
  ];

  /// Interpolates the topographical elevation in meters at a given coordinate.
  /// Uses fast planar squared-distance with radial cutoff to avoid trig/sqrt overhead.
  double getElevation(LatLng point) {
    double totalWeight = 0.0;
    double weightedElevation = 0.0;
    final lat = point.latitude;
    final lng = point.longitude;

    for (var i = 0; i < anchors.length; i++) {
      final anchor = anchors[i];
      final dLatKm = (lat - anchor.lat) * _kmPerDegLat;
      final dLngKm = (lng - anchor.lng) * _kmPerDegLng;
      final distSqKm = (dLatKm * dLatKm) + (dLngKm * dLngKm);

      if (distSqKm < anchor.cutoffDistSqKm) {
        final weight = math.exp(distSqKm * anchor.invTwoSigmaSq);
        weightedElevation += weight * anchor.elevationM;
        totalWeight += weight;
      }
    }

    if (totalWeight <= 1e-4) {
      return 10.0; // Baseline coastal elevation
    }

    return weightedElevation / totalWeight;
  }

  /// Calculates the cumulative ascent (gain) and descent (loss) in meters along route waypoints.
  (double gainM, double lossM) computeGainAndLoss(
    List<LatLng> points, {
    List<double>? precomputedElevations,
  }) {
    if (points.length < 2) return (0.0, 0.0);

    double totalGain = 0.0;
    double totalLoss = 0.0;
    double prevElev = precomputedElevations != null
        ? precomputedElevations.first
        : getElevation(points.first);

    // Sample every 2nd or 3rd waypoint for elevation profile smoothing
    final step = math.max(1, (points.length / 100).ceil());
    for (var i = step; i < points.length; i += step) {
      final currElev = precomputedElevations != null
          ? precomputedElevations[i]
          : getElevation(points[i]);
      final delta = currElev - prevElev;
      if (delta > 0) {
        totalGain += delta;
      } else {
        totalLoss += -delta;
      }
      prevElev = currElev;
    }

    // Include last waypoint
    final lastElev = precomputedElevations != null
        ? precomputedElevations.last
        : getElevation(points.last);
    final finalDelta = lastElev - prevElev;
    if (finalDelta > 0) {
      totalGain += finalDelta;
    } else {
      totalLoss += -finalDelta;
    }

    return (totalGain, totalLoss);
  }

  /// Evaluates net gravitational energy impact (kWh) for an elevation difference deltaElevationM.
  /// Driving uphill consumes +30% to +45% energy via gravitational potential energy (m * g * h / eta_drive).
  /// Driving downhill recovers 15% to 20% energy via regenerative braking (m * g * |h| * eta_regen).
  double computeElevationEnergyDelta({
    required double deltaElevationM,
    double vehicleMassKg = 1800.0,
    double driveEfficiency = 0.88,
    double regenEfficiency = 0.65,
  }) {
    if (deltaElevationM == 0.0) return 0.0;

    const g = 9.80665; // m/s^2
    const joulesToKwh = 1.0 / 3600000.0;

    final potentialEnergyKwh =
        (vehicleMassKg * g * deltaElevationM.abs()) * joulesToKwh;

    if (deltaElevationM > 0) {
      // Uphill ascent penalty: extra motor energy needed to gain gravitational potential
      return potentialEnergyKwh / driveEfficiency;
    } else {
      // Downhill descent recovery: kinetic/potential conversion through regenerative braking
      return -potentialEnergyKwh * regenEfficiency;
    }
  }
}
