import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A futuristic glowing radial battery gauge for EVay Lanka.
/// Features smooth gradient arc rendering, animated glowing sweep,
/// battery level status colors, and optional touch-drag adjustment.
class RadialBatteryGauge extends StatelessWidget {
  const RadialBatteryGauge({
    super.key,
    required this.batteryPercent,
    this.estimatedRangeKm,
    this.availableKwh,
    this.totalKwh,
    this.onChanged,
    this.size = 220.0,
    this.interactive = false,
  });

  final double batteryPercent;
  final double? estimatedRangeKm;
  final double? availableKwh;
  final double? totalKwh;
  final ValueChanged<double>? onChanged;
  final double size;
  final bool interactive;

  Color _getSoCColor(double percent, BuildContext context) {
    if (percent >= 50) return const Color(0xFF00E676); // High-voltage emerald
    if (percent >= 25) return const Color(0xFFFFB300); // Amber warning
    return const Color(0xFFFF3D00); // Deep coral alert
  }

  @override
  Widget build(BuildContext context) {
    final clampedPercent = batteryPercent.clamp(0.0, 100.0);
    final socColor = _getSoCColor(clampedPercent, context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Custom Painted Radial Glow & Arc
            CustomPaint(
              size: Size(size, size),
              painter: _RadialGaugePainter(
                percent: clampedPercent / 100.0,
                color: socColor,
                trackColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),

            // 2. Center Telemetry Display
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clampedPercent.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: size * 0.22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1.0,
                        color: isDark ? Colors.white : const Color(0xFF102018),
                      ),
                    ),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: size * 0.09,
                        fontWeight: FontWeight.w600,
                        color: socColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (estimatedRangeKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: socColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.electric_bolt_rounded, size: 14, color: socColor),
                        const SizedBox(width: 4),
                        Text(
                          '~${estimatedRangeKm!.toStringAsFixed(0)} km',
                          style: TextStyle(
                            fontSize: size * 0.065,
                            fontWeight: FontWeight.w700,
                            color: socColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (availableKwh != null && totalKwh != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${availableKwh!.toStringAsFixed(1)} / ${totalKwh!.toStringAsFixed(0)} kWh',
                    style: TextStyle(
                      fontSize: size * 0.052,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  _RadialGaugePainter({
    required this.percent,
    required this.color,
    required this.trackColor,
  });

  final double percent;
  final Color color;
  final Color trackColor;

  static const double _startAngle = 135.0 * (math.pi / 180.0);
  static const double _sweepAngle = 270.0 * (math.pi / 180.0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final strokeWidth = size.width * 0.085;
    final radius = (size.width - strokeWidth) / 2.0;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle,
      false,
      trackPaint,
    );

    if (percent <= 0.0) return;

    // Active illuminated arc with gradient
    final activeSweep = _sweepAngle * percent.clamp(0.0, 1.0);
    final gradient = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + _sweepAngle,
      colors: [
        color.withValues(alpha: 0.6),
        color,
      ],
      stops: const [0.0, 1.0],
    );

    final activePaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // Glowing head dot
    final headAngle = _startAngle + activeSweep;
    final headX = center.dx + radius * math.cos(headAngle);
    final headY = center.dy + radius * math.sin(headAngle);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.8, glowPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.32, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter old) =>
      old.percent != percent || old.color != color || old.trackColor != trackColor;
}
