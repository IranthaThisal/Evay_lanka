import 'package:flutter/material.dart';

import '../models/range_anxiety.dart';
import '../models/smart_route.dart';

/// Range Anxiety Index (RAI) & Battery Reserve Safety HUD
/// Highlights the 10% mandatory reserve floor, pre-departure veto status,
/// Point of No Return (PNR), and environmental physics multipliers.
class RaiSafetyHud extends StatelessWidget {
  const RaiSafetyHud({
    super.key,
    required this.report,
    required this.route,
    this.minimumReserveFloorPercent = 10.0,
    this.onTapMitigate,
  });

  final RangeAnxietyReport report;
  final SmartRoute route;
  final double minimumReserveFloorPercent;
  final VoidCallback? onTapMitigate;

  Color _scoreColor(int score) {
    if (score >= 70) return const Color(0xFF00E676);
    if (score >= 40) return const Color(0xFFFFB300);
    return const Color(0xFFFF3D00);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = report.score;
    final scoreColor = _scoreColor(score);
    final arrivalSoc = route.arrivalBatteryPercent;
    final isReserveViolated = route.hasReserveViolation || arrivalSoc < minimumReserveFloorPercent;
    final canNavigate = route.canInitiateNavigation && !isReserveViolated;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14241B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isReserveViolated
              ? const Color(0xFFFF3D00).withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF264030) : const Color(0xFFE2EBE5)),
          width: isReserveViolated ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isReserveViolated ? const Color(0xFFFF3D00) : scoreColor)
                .withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Composite RAI Score & Feasibility Status
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withValues(alpha: 0.15),
                  border: Border.all(color: scoreColor, width: 2.2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Range Anxiety Index: ${report.label}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF102018),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Buffer: ${report.bufferKm >= 0 ? "+" : ""}${report.bufferKm.toStringAsFixed(0)} km • Safety Margin: ${(report.safetyMargin * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (canNavigate ? const Color(0xFF00E676) : const Color(0xFFFF3D00))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  canNavigate ? 'APPROVED' : 'VETOED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: canNavigate ? const Color(0xFF00C853) : const Color(0xFFFF3D00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Battery Journey Bar & Reserve Floor
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Arrival SoC: ${arrivalSoc.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isReserveViolated ? const Color(0xFFFF3D00) : const Color(0xFF00C853),
                    ),
                  ),
                  Text(
                    'Reserve Floor: ${minimumReserveFloorPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Dual-Track Progress Bar
              Stack(
                children: [
                  // Background
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Active arrival bar
                  FractionallySizedBox(
                    widthFactor: (arrivalSoc.clamp(0.0, 100.0) / 100.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: isReserveViolated ? const Color(0xFFFF3D00) : const Color(0xFF00E676),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  // Reserve floor indicator line (10%)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: const Alignment(-0.80, 0), // (10% - 50%) * 2 = -0.80
                      child: Container(
                        width: 2.5,
                        height: 14,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Safety Warning Banner (for C3 unassisted or reserve breaches)
          if (isReserveViolated) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3D00).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF3D00).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFFF3D00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Turn-by-turn navigation vetoed before departure. Mountain ascent projected to breach safety reserve.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFFB71C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 4. Environmental Physics Badges
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (report.pointOfNoReturn != null)
                _Chip(
                  icon: Icons.replay_rounded,
                  label: report.pointOfNoReturn!.isReturnSafe
                      ? 'Return Verified Safe'
                      : 'PNR Alert @ ${report.pointOfNoReturn!.pointOfNoReturnKmFromOrigin.toStringAsFixed(0)}km',
                  color: report.pointOfNoReturn!.isReturnSafe
                      ? const Color(0xFF00C853)
                      : const Color(0xFFFF9100),
                ),
              if (route.chargingStops.isNotEmpty)
                _Chip(
                  icon: Icons.ev_station_rounded,
                  label: '${route.chargingStops.length} Planned Stop${route.chargingStops.length > 1 ? "s" : ""}',
                  color: const Color(0xFF2979FF),
                ),
              if (report.totalElevationGainM > 300)
                _Chip(
                  icon: Icons.terrain_rounded,
                  label: '+${report.totalElevationGainM.toStringAsFixed(0)}m Climb',
                  color: const Color(0xFFFF9100),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
