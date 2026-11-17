import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/smart_route.dart';
import '../services/smart_route_service.dart';

/// Interactive Elevation & SoC Cross-Section HUD for EVay Lanka.
/// Visualizes the topographical profile and projected State of Charge (SoC) across
/// Sri Lanka's Central Highlands, supporting touch scrubbing to inspect km, altitude, and SoC.
class ElevationProfileHud extends StatefulWidget {
  const ElevationProfileHud({
    super.key,
    required this.routePoints,
    required this.elevationGainM,
    required this.elevationLossM,
    required this.elevationEnergyPenaltyKwh,
    this.elevationModel = const SriLankaElevationModel(),
    this.totalDistanceKm = 0.0,
    this.initialSocPercent = 70.0,
    this.arrivalSocPercent = 25.0,
    this.chargingStops = const [],
    this.pnrDistanceKm,
  });

  final List<LatLng> routePoints;
  final double elevationGainM;
  final double elevationLossM;
  final double elevationEnergyPenaltyKwh;
  final SriLankaElevationModel elevationModel;
  final double totalDistanceKm;
  final double initialSocPercent;
  final double arrivalSocPercent;
  final List<ChargingStop> chargingStops;
  final double? pnrDistanceKm;

  @override
  State<ElevationProfileHud> createState() => _ElevationProfileHudState();
}

class _ElevationProfileHudState extends State<ElevationProfileHud> {
  int? _scrubIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.routePoints.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sample up to 60 elevation & SoC points along route
    final sampleCount = math.min(60, widget.routePoints.length);
    final elevationSamples = <double>[];
    final socSamples = <double>[];
    double maxElevation = 0.0;
    double minElevation = 9999.0;

    final startSoc = widget.initialSocPercent.clamp(5.0, 100.0);
    final endSoc = widget.arrivalSocPercent.clamp(0.0, 100.0);
    final totalDist =
        widget.totalDistanceKm > 0 ? widget.totalDistanceKm : 100.0;

    for (var i = 0; i < sampleCount; i++) {
      final frac = sampleCount > 1 ? i / (sampleCount - 1) : 0.0;
      final idx = (frac * (widget.routePoints.length - 1)).round();
      final elev = widget.elevationModel.getElevation(widget.routePoints[idx]);
      elevationSamples.add(elev);
      if (elev > maxElevation) maxElevation = elev;
      if (elev < minElevation) minElevation = elev;

      // Interpolate SoC along corridor with step boosts at planned charging stops
      final distAtSample = frac * totalDist;
      double soc = startSoc - (startSoc - endSoc) * frac;
      for (final stop in widget.chargingStops) {
        if (totalDist > 0 && distAtSample < stop.distanceFromOriginKm) {
          final preStopFrac =
              (distAtSample / math.max(1.0, stop.distanceFromOriginKm)).clamp(
                0.0,
                1.0,
              );
          soc =
              startSoc -
              (startSoc - stop.arrivalSocPercent) * preStopFrac;
          break;
        }
      }
      socSamples.add(soc.clamp(0.0, 100.0));
    }

    if (minElevation > maxElevation) {
      minElevation = 0.0;
      maxElevation = 100.0;
    }

    final activeIdx =
        _scrubIndex != null
            ? _scrubIndex!.clamp(0, elevationSamples.length - 1)
            : null;
    final scrubbedKm =
        activeIdx != null && sampleCount > 1
            ? (activeIdx / (sampleCount - 1)) * totalDist
            : null;
    final scrubbedElev =
        activeIdx != null ? elevationSamples[activeIdx] : null;
    final scrubbedSoc = activeIdx != null ? socSamples[activeIdx] : null;

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
                child: const Icon(
                  Icons.terrain_rounded,
                  size: 18,
                  color: Color(0xFF00C853),
                ),
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
                      scrubbedKm != null &&
                              scrubbedElev != null &&
                              scrubbedSoc != null
                          ? 'At ${scrubbedKm.toStringAsFixed(1)} km: ${scrubbedElev.toStringAsFixed(0)}m alt • ~${scrubbedSoc.toStringAsFixed(0)}% SoC'
                          : 'Peak: ${maxElevation.toStringAsFixed(0)}m • Net ΔE: ${widget.elevationEnergyPenaltyKwh >= 0 ? "+" : ""}${widget.elevationEnergyPenaltyKwh.toStringAsFixed(2)} kWh (Drag to inspect)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            scrubbedKm != null
                                ? FontWeight.w700
                                : FontWeight.w500,
                        color:
                            scrubbedKm != null
                                ? const Color(0xFF00C853)
                                : (isDark ? Colors.white60 : Colors.black54),
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
                    label: '+${widget.elevationGainM.toStringAsFixed(0)}m',
                    color: const Color(0xFFFF9100),
                  ),
                  const SizedBox(width: 6),
                  _StatBadge(
                    icon: Icons.arrow_downward_rounded,
                    label: '-${widget.elevationLossM.toStringAsFixed(0)}m',
                    color: const Color(0xFF00E676),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive Elevation & SoC Scrubber Chart
          LayoutBuilder(
            builder: (context, constraints) {
              void updateScrub(Offset localPosition) {
                if (elevationSamples.isEmpty || constraints.maxWidth <= 0) {
                  return;
                }
                final ratio = (localPosition.dx / constraints.maxWidth).clamp(
                  0.0,
                  1.0,
                );
                final nextIdx =
                    (ratio * (elevationSamples.length - 1)).round();
                if (_scrubIndex != nextIdx) {
                  HapticFeedback.selectionClick();
                  setState(() => _scrubIndex = nextIdx);
                }
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => updateScrub(d.localPosition),
                onHorizontalDragStart: (d) => updateScrub(d.localPosition),
                onHorizontalDragUpdate: (d) => updateScrub(d.localPosition),
                onHorizontalDragEnd: (_) => setState(() => _scrubIndex = null),
                onTapUp: (_) => Future.delayed(
                  const Duration(seconds: 2),
                  () {
                    if (mounted) setState(() => _scrubIndex = null);
                  },
                ),
                child: SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ElevationChartPainter(
                      samples: elevationSamples,
                      socSamples: socSamples,
                      minElev: minElevation,
                      maxElev: maxElevation,
                      isDark: isDark,
                      scrubIndex: activeIdx,
                      stopFractions: [
                        if (totalDist > 0)
                          for (final s in widget.chargingStops)
                            (s.distanceFromOriginKm / totalDist).clamp(
                              0.0,
                              1.0,
                            ),
                      ],
                      pnrFraction:
                          (widget.pnrDistanceKm != null && totalDist > 0)
                              ? (widget.pnrDistanceKm! / totalDist).clamp(
                                0.0,
                                1.0,
                              )
                              : null,
                    ),
                  ),
                ),
              );
            },
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
    required this.socSamples,
    required this.minElev,
    required this.maxElev,
    required this.isDark,
    this.scrubIndex,
    this.stopFractions = const [],
    this.pnrFraction,
  });

  final List<double> samples;
  final List<double> socSamples;
  final double minElev;
  final double maxElev;
  final bool isDark;
  final int? scrubIndex;
  final List<double> stopFractions;
  final double? pnrFraction;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final range = math.max(10.0, maxElev - minElev);
    final widthStep = size.width / (samples.length - 1);

    final linePath = Path();
    final fillPath = Path();
    final socPath = Path();

    double getY(double elev) {
      final norm = (elev - minElev) / range;
      return size.height - (norm * (size.height - 12) + 6);
    }

    double getSocY(double soc) {
      final norm = (soc.clamp(0.0, 100.0)) / 100.0;
      return size.height - (norm * (size.height - 12) + 6);
    }

    linePath.moveTo(0, getY(samples.first));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(samples.first));
    if (socSamples.length == samples.length) {
      socPath.moveTo(0, getSocY(socSamples.first));
    }

    for (var i = 1; i < samples.length; i++) {
      final x = i * widthStep;
      final y = getY(samples[i]);
      linePath.lineTo(x, y);
      fillPath.lineTo(x, y);
      if (socSamples.length == samples.length) {
        socPath.lineTo(x, getSocY(socSamples[i]));
      }
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

    // Projected SoC overlay curve
    if (socSamples.length == samples.length) {
      final socPaint = Paint()
        ..color = const Color(0xFF2979FF).withValues(alpha: 0.55)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(socPath, socPaint);
    }

    // Profile Line
    final linePaint = Paint()
      ..color = const Color(0xFF00C853)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw PNR indicator line if present
    if (pnrFraction != null) {
      final pnrX = pnrFraction! * size.width;
      final pnrPaint = Paint()
        ..color = const Color(0xFFFF9100).withValues(alpha: 0.7)
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(pnrX, 0), Offset(pnrX, size.height), pnrPaint);
    }

    // Draw planned charging stop dots along elevation curve
    for (final frac in stopFractions) {
      final idx = (frac * (samples.length - 1)).round().clamp(
        0,
        samples.length - 1,
      );
      final cx = frac * size.width;
      final cy = getY(samples[idx]);
      canvas.drawCircle(
        Offset(cx, cy),
        4.5,
        Paint()..color = const Color(0xFF2979FF),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        2.0,
        Paint()..color = Colors.white,
      );
    }

    // Draw active scrub cursor
    if (scrubIndex != null &&
        scrubIndex! >= 0 &&
        scrubIndex! < samples.length) {
      final sx = scrubIndex! * widthStep;
      final sy = getY(samples[scrubIndex!]);
      final cursorPaint = Paint()
        ..color = isDark ? Colors.white70 : Colors.black54
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height), cursorPaint);
      canvas.drawCircle(
        Offset(sx, sy),
        5.0,
        Paint()..color = const Color(0xFF00C853),
      );
      canvas.drawCircle(
        Offset(sx, sy),
        2.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ElevationChartPainter old) =>
      old.samples != samples ||
      old.minElev != minElev ||
      old.maxElev != maxElev ||
      old.scrubIndex != scrubIndex ||
      old.pnrFraction != pnrFraction;
}
