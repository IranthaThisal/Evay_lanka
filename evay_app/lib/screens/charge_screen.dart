import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/simulation_service.dart';
import '../theme/app_theme.dart';

class ChargeScreen extends StatefulWidget {
  const ChargeScreen({super.key});

  @override
  State<ChargeScreen> createState() => _ChargeScreenState();
}

class _ChargeScreenState extends State<ChargeScreen>
    with SingleTickerProviderStateMixin {
  static const _glowAssetPath = 'assets/images/energy-icon.png';
  final _ref = TextEditingController();
  final _sim = SimulationService();
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
  double _batteryCapacity = 60;
  double _batteryPercent = 47;
  double _efficiency = 6;
  double _distance = 120;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _ref.dispose();
    super.dispose();
  }

  SimulationResult get _result => _sim.simulate(
    batteryCapacityKwh: _batteryCapacity,
    batteryPercent: _batteryPercent.clamp(0.0, 100.0).toDouble(),
    efficiencyKmPerKwh: _efficiency,
    tripDistanceKm: _distance,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.evayPalette;
    final result = _result;
    final availableKwh = _batteryCapacity * (_batteryPercent / 100);
    final projectedRemainingPct =
        ((_batteryPercent / 100) - (result.energyNeededKwh / _batteryCapacity)) *
        100;
    final clampedProjectedPct =
        projectedRemainingPct.clamp(0.0, 100.0).toDouble();
    final tripFits = result.energyNeededKwh <= availableKwh;
    final projectedRangeKm =
        (result.estimatedRangeKm - _distance)
            .clamp(0.0, double.infinity)
            .toDouble();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              final t = _glowAnimation.value;
              return SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.18 + (t * 0.12),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 10 + (t * 8),
                          sigmaY: 10 + (t * 8),
                        ),
                        child: Transform.scale(
                          scale: 1.18 + (t * 0.08),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              palette.heroAccent,
                              BlendMode.srcATop,
                            ),
                            child: Image.asset(
                              _glowAssetPath,
                              width: 72,
                              height: 72,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.14 + (t * 0.10),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 6 + (t * 4),
                          sigmaY: 6 + (t * 4),
                        ),
                        child: Transform.scale(
                          scale: 1.08 + (t * 0.06),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              palette.heroAccent,
                              BlendMode.srcATop,
                            ),
                            child: Image.asset(
                              _glowAssetPath,
                              width: 70,
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.98 + (t * 0.04),
                      child: Image.asset(
                        _glowAssetPath,
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.bolt_rounded,
                            size: 40,
                            color: palette.heroAccent,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('chargeYourEv'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Use a station reference to begin a charging flow, or estimate your trip cost below.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('enterScanReference'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ref,
                        decoration: InputDecoration(
                          hintText: l10n.t('enterReference'),
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.t('qrScanComingSoon'))),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.t('startChargeDemo'))),
                      );
                    },
                    child: Text(l10n.t('startCharge')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.t('batteryCostSimulation'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Adjust values to estimate your trip.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.neutral,
            ),
          ),
          const SizedBox(height: 18),
          _SimulationBatteryCard(
            currentPercent: _batteryPercent,
            projectedPercent: clampedProjectedPct,
            tripFits: tripFits,
            energyShortfall:
                (result.energyNeededKwh - availableKwh)
                    .clamp(0.0, double.infinity)
                    .toDouble(),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
            children: [
              _SimulationMetricCard(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBackground: const Color(0xFFFFF5DB),
                label: 'Energy needed',
                value: '${result.energyNeededKwh.toStringAsFixed(1)} kWh',
              ),
              _SimulationMetricCard(
                icon: Icons.attach_money_rounded,
                iconColor: const Color(0xFF10B981),
                iconBackground: const Color(0xFFE8FBF3),
                label: 'Estimated cost',
                value: 'LKR ${result.estimatedCostLkr.toStringAsFixed(0)}',
              ),
              _SimulationMetricCard(
                icon: Icons.map_outlined,
                iconColor: const Color(0xFF3B82F6),
                iconBackground: const Color(0xFFEFF5FF),
                label: 'Range available',
                value: '${result.estimatedRangeKm.round()} km',
              ),
              _SimulationMetricCard(
                icon: Icons.navigation_outlined,
                iconColor: const Color(0xFF6366F1),
                iconBackground: const Color(0xFFEEF0FF),
                label: 'Range after trip',
                value: '${projectedRangeKm.round()} km',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SimulationPanel(
            child: Column(
              children: [
                _SimulationSlider(
                  label: 'Battery capacity',
                  value: _batteryCapacity,
                  min: 20,
                  max: 100,
                  divisions: 80,
                  unit: 'kWh',
                  onChanged: (value) {
                    setState(() => _batteryCapacity = value);
                  },
                ),
                const SizedBox(height: 18),
                _SimulationSlider(
                  label: 'Battery remaining',
                  value: _batteryPercent,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  unit: '%',
                  onChanged: (value) {
                    setState(() => _batteryPercent = value);
                  },
                ),
                const SizedBox(height: 18),
                _SimulationSlider(
                  label: 'Efficiency',
                  value: _efficiency,
                  min: 3,
                  max: 10,
                  divisions: 70,
                  unit: 'km/kWh',
                  fractionDigits: 1,
                  onChanged: (value) {
                    setState(() => _efficiency = value);
                  },
                ),
                const SizedBox(height: 18),
                _SimulationSlider(
                  label: 'Trip distance',
                  value: _distance,
                  min: 0,
                  max: 500,
                  divisions: 100,
                  unit: 'km',
                  onChanged: (value) {
                    setState(() => _distance = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.t('simulationNote'))),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: palette.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Save simulation'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationBatteryCard extends StatelessWidget {
  const _SimulationBatteryCard({
    required this.currentPercent,
    required this.projectedPercent,
    required this.tripFits,
    required this.energyShortfall,
  });

  final double currentPercent;
  final double projectedPercent;
  final bool tripFits;
  final double energyShortfall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.evayPalette;
    final consumedPercent =
        (currentPercent - projectedPercent).clamp(0.0, 100.0).toDouble();

    return Column(
      children: [
        Container(
          width: 222,
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC8CDD8), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final greenWidth = width * (projectedPercent / 100);
                  final amberWidth = width * (consumedPercent / 100);

                  return Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F8FC),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      if (greenWidth > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: greenWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: palette.success,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                bottomLeft: const Radius.circular(14),
                                topRight: Radius.circular(amberWidth == 0 ? 14 : 0),
                                bottomRight: Radius.circular(
                                  amberWidth == 0 ? 14 : 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (amberWidth > 0)
                        Positioned(
                          left: greenWidth,
                          top: 0,
                          bottom: 0,
                          width:
                              amberWidth
                                  .clamp(0.0, width - greenWidth)
                                  .toDouble(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: tripFits
                                  ? const Color(0xFFFBBF24)
                                  : palette.danger,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(
                                  (greenWidth + amberWidth) >= width ? 14 : 0,
                                ),
                                bottomRight: Radius.circular(
                                  (greenWidth + amberWidth) >= width ? 14 : 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              Positioned(
                right: -11,
                top: 28,
                child: Container(
                  width: 12,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8CDD8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${currentPercent.round()}%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '${tripFits ? '-' : '+'}${(currentPercent - projectedPercent).abs().round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!tripFits) ...[
          const SizedBox(height: 10),
          Text(
            'Need ${energyShortfall.toStringAsFixed(1)} more kWh for this trip.',
            style: theme.textTheme.bodySmall?.copyWith(color: palette.danger),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _SimulationMetricCard extends StatelessWidget {
  const _SimulationMetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationPanel extends StatelessWidget {
  const _SimulationPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SimulationSlider extends StatelessWidget {
  const _SimulationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.onChanged,
    this.fractionDigits = 0,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final ValueChanged<double> onChanged;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value.toStringAsFixed(fractionDigits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: displayValue,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF22C17B),
            inactiveTrackColor: const Color(0xFFE5E7EB),
            trackHeight: 6,
            thumbColor: Colors.white,
            overlayColor: const Color(0x3322C17B),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
