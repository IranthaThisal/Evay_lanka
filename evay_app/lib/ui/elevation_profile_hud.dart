import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/smart_route_service.dart';

/// Interactive Elevation Cross-Section HUD for EVay Lanka.
/// Visualizes the topographical profile of the travel corridor across Sri Lanka's Central Highlands,
/// showing cumulative climb, downhill regenerative recovery, and peak elevation.
class ElevationProfileHud extends StatelessWidget {
  const ElevationProfileHud({
    super.key,
    required this.routePoints,
    required this.elevationGainM,
    required this.elevationLossM,
    required this.elevationEnergyPenaltyKwh,
    this.elevationModel = const SriLankaElevationModel(),
  });

  final List<LatLng> routePoints;
  final double elevationGainM;
  final double elevationLossM;
  final double elevationEnergyPenaltyKwh;
  final SriLankaElevationModel elevationModel;

  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sample up to 60 elevation points along route
    final sampleCount = math.min(60, routePoints.length);
    final elevationSamples = <double>[];
    double maxElevation = 0.0;
    double minElevation = 9999.0;

    for (var i = 0; i < sampleCount; i++) {
      final idx = (i * (routePoints.length - 1) / (sampleCount - 1)).round();
      final elev = elevationModel.getElevation(routePoints[idx]);
      elevationSamples.add(elev);
      if (elev > maxElevation) maxElevation = elev;
      if (elev < minElevation) minElevation = elev;
    }

    if (minElevation > maxElevation) {
      minElevation = 0.0;
      maxElevation = 100.0;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14241B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF264030) : const Color(0xFFE2EBE5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Topography & Physics Metrics
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.terrain_rounded, size: 18, color: Color(0xFF00C853)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Highland Topography & Energy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF102018),
                      ),
                    ),
                    Text(
                      'Peak: ${maxElevation.toStringAsFixed(0)}m • Net ΔE: ${elevationEnergyPenaltyKwh >= 0 ? "+" : ""}${elevationEnergyPenaltyKwh.toStringAsFixed(2)} kWh',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Gain & Loss Badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatBadge(
                    icon: Icons.arrow_upward_rounded,
                    label: '+${elevationGainM.toStringAsFixed(0)}m',
                    color: const Color(0xFFFF9100),
                  ),
                  const SizedBox(width: 6),
                  _StatBadge(
                    icon: Icons.arrow_downward_rounded,
                    label: '-${elevationLossM.toStringAsFixed(0)}m',
                    color: const Color(0xFF00E676),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Elevation Chart
          SizedBox(
            height: 64,
            width: double.infinity,
            child: CustomPaint(
              painter: _ElevationChartPainter(
                samples: elevationSamples,
                minElev: minElevation,
                maxElev: maxElevation,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ElevationChartPainter extends CustomPainter {
  _ElevationChartPainter({
    required this.samples,
    required this.minElev,
    required this.maxElev,
    required this.isDark,
  });

  final List<double> samples;
  final double minElev;
  final double maxElev;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final range = math.max(10.0, maxElev - minElev);
    final widthStep = size.width / (samples.length - 1);

    final linePath = Path();
    final fillPath = Path();

    double getY(double elev) {
      final norm = (elev - minElev) / range;
      // Flip vertical so higher elevation is near top
      return size.height - (norm * (size.height - 10) + 5);
    }

    linePath.moveTo(0, getY(samples.first));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(samples.first));

    for (var i = 1; i < samples.length; i++) {
      final x = i * widthStep;
      final y = getY(samples[i]);
      linePath.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Shaded Area Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E676).withValues(alpha: isDark ? 0.35 : 0.25),
          const Color(0xFF00E676).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Profile Line
    final linePaint = Paint()
      ..color = const Color(0xFF00C853)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ElevationChartPainter old) =>
      old.samples != samples || old.minElev != minElev || old.maxElev != maxElev;
}
