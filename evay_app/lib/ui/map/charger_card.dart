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
      width: 245,
      padding: const EdgeInsets.all(16),
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
                  Text(
                    charger.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: onPanelColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    charger.city.isEmpty ? l10n.t('sriLanka') : charger.city,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: onPanelMutedColor),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
          const SizedBox(height: 12),
          Text(
            meta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: goodColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onDirections,
                  style: FilledButton.styleFrom(
                    backgroundColor: isLight ? accentColor : Colors.white,
                    foregroundColor:
                        isLight ? buttonOnAccentColor : const Color(0xFF08141D),
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(l10n.t('directions')),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 42,
                height: 42,
                child: IconButton(
                  onPressed: onDetails,
                  style: IconButton.styleFrom(
                    backgroundColor: panelSoftColor,
                    foregroundColor: onPanelColor,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.ev_station, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
