import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/charger.dart';

/// Reusable horizontal card widget for the charging station carousel on MapScreen.
class ChargerCard extends StatelessWidget {
  const ChargerCard({
    super.key,
    required this.charger,
    required this.meta,
    required this.onDirections,
    required this.onDetails,
    required this.panelColor,
    required this.onPanelColor,
    required this.onPanelMutedColor,
    required this.panelSoftColor,
    required this.accentColor,
    required this.buttonOnAccentColor,
    required this.goodColor,
    required this.isLight,
    this.onBookAtEta,
    this.onSwapAlternative,
    this.alternativeCount = 0,
  });

  final Charger charger;
  final String meta;
  final VoidCallback onDirections;
  final VoidCallback onDetails;
  final Color panelColor;
  final Color onPanelColor;
  final Color onPanelMutedColor;
  final Color panelSoftColor;
  final Color accentColor;
  final Color buttonOnAccentColor;
  final Color goodColor;
  final bool isLight;
  final VoidCallback? onBookAtEta;
  final VoidCallback? onSwapAlternative;
  final int alternativeCount;

  Widget _metricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: panelSoftColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: onPanelColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: 265,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          charger.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: onPanelColor,
                          ),
                        ),
                      ),
                      if (onSwapAlternative != null && alternativeCount > 0)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onSwapAlternative,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 13,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Alt ($alternativeCount)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    charger.city.isEmpty ? l10n.t('sriLanka') : charger.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: onPanelMutedColor, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _metricChip(l10n.slotsCount(charger.slots)),
                      if (charger.powerKw != null)
                        _metricChip(
                          '${charger.powerKw!.toStringAsFixed(0)} kW',
                        ),
                      if (charger.connectorTypes.isNotEmpty)
                        _metricChip(charger.connectorTypes.first),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: goodColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onDirections,
                  style: FilledButton.styleFrom(
                    backgroundColor: isLight ? accentColor : Colors.white,
                    foregroundColor:
                        isLight ? buttonOnAccentColor : const Color(0xFF08141D),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    l10n.t('directions'),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
              if (onBookAtEta != null) ...[
                const SizedBox(width: 6),
                FilledButton.tonalIcon(
                  onPressed: onBookAtEta,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.schedule_send_rounded, size: 15),
                  label: const Text(
                    'Book ETA',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  onPressed: onDetails,
                  style: IconButton.styleFrom(
                    backgroundColor: panelSoftColor,
                    foregroundColor: onPanelColor,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.ev_station, size: 19),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
