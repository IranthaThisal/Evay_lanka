import 'dart:async';
import 'package:flutter/material.dart';

enum CebTariffWindow {
  offPeak(
    name: 'Off-Peak',
    rateLkr: 25.00,
    timeRange: '22:30 – 05:30',
    color: Color(0xFF00C853),
    tag: 'Optimal Charging Window',
    description: 'Cheapest grid power. Save up to 61% vs Peak tariff.',
  ),
  day(
    name: 'Day Rate',
    rateLkr: 40.00,
    timeRange: '05:30 – 18:30',
    color: Color(0xFF2979FF),
    tag: 'Standard Grid Rate',
    description: 'Standard tariff for daytime top-ups and transit.',
  ),
  peak(
    name: 'Peak Hours',
    rateLkr: 65.00,
    timeRange: '18:30 – 22:30',
    color: Color(0xFFFF5252),
    tag: 'High Demand Window',
    description: 'Highest grid demand. Avoid heavy charging if possible.',
  );

  const CebTariffWindow({
    required this.name,
    required this.rateLkr,
    required this.timeRange,
    required this.color,
    required this.tag,
    required this.description,
  });

  final String name;
  final double rateLkr;
  final String timeRange;
  final Color color;
  final String tag;
  final String description;

  static CebTariffWindow currentWindow([DateTime? nowTime]) {
    final now = nowTime ?? DateTime.now();
    final mins = now.hour * 60 + now.minute;

    // 05:30 is 330 mins, 18:30 is 1110 mins, 22:30 is 1350 mins
    if (mins >= 330 && mins < 1110) {
      return CebTariffWindow.day;
    } else if (mins >= 1110 && mins < 1350) {
      return CebTariffWindow.peak;
    } else {
      return CebTariffWindow.offPeak;
    }
  }
}

/// Real-time Ceylon Electricity Board (CEB) Time-Of-Use (TOU) Tariff Ticker
class CebTariffCard extends StatefulWidget {
  const CebTariffCard({super.key});

  @override
  State<CebTariffCard> createState() => _CebTariffCardState();
}

class _CebTariffCardState extends State<CebTariffCard> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late CebTariffWindow _window;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _window = CebTariffWindow.currentWindow();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _window = CebTariffWindow.currentWindow();
        });
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = _window;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14241B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: w.color.withValues(alpha: isDark ? 0.35 : 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: w.color.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: w.color,
                      boxShadow: [
                        BoxShadow(
                          color: w.color.withValues(alpha: 0.4 + 0.4 * _pulseAnimation.value),
                          blurRadius: 4 + 4 * _pulseAnimation.value,
                          spreadRadius: 1 + 1 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'CEB Grid Tariff: ${w.name}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF102018),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: w.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LKR ${w.rateLkr.toStringAsFixed(2)} / kWh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: w.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black45),
              const SizedBox(width: 4),
              Text(
                'Window: ${w.timeRange}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  w.tag,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: w.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
