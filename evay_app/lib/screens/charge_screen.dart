import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ChargeScreen extends StatefulWidget {
  const ChargeScreen({super.key});

  @override
  State<ChargeScreen> createState() => _ChargeScreenState();
}

class _ChargeScreenState extends State<ChargeScreen>
    with SingleTickerProviderStateMixin {
  static const _glowAssetPath = 'assets/images/energy-icon.png';
  int _tab = 0; // 0 recent, 1 history
  final _ref = TextEditingController();
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

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

  @override
  Widget build(BuildContext context) {
    final palette = context.evayPalette;
    final l10n = context.l10n;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),

          Center(
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(l10n.t('recent'))),
                ButtonSegment(value: 1, label: Text(l10n.t('history'))),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),

          const SizedBox(height: 16),

          if (_tab == 0) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.t('enterScanReference'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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

            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.t('recentChargeReferences'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: Center(child: Text(l10n.t('emptyReference'))),
            ),
          ] else ...[
            SizedBox(
              height: 220,
              child: Center(child: Text(l10n.t('historyComingSoon'))),
            ),
          ],
        ],
      ),
    );
  }
}
