import 'package:flutter/material.dart';

/// Draft values holder for charger filters.
class FilterDraft {
  const FilterDraft({
    required this.availableOnly,
    required this.minPowerKw,
    required this.selectedConnectors,
  });

  final bool availableOnly;
  final double minPowerKw;
  final Set<String> selectedConnectors;
}

/// Reusable modal filter bottom sheet for MapScreen chargers.
class ChargerFilterSheet extends StatefulWidget {
  const ChargerFilterSheet({
    super.key,
    required this.availableOnly,
    required this.minPowerKw,
    required this.selectedConnectors,
    required this.allConnectors,
    required this.panelColor,
    required this.onPanelColor,
    required this.onPanelMutedColor,
    required this.panelSoftColor,
    required this.accentColor,
    required this.buttonOnAccentColor,
    required this.goodColor,
  });

  final bool availableOnly;
  final double minPowerKw;
  final Set<String> selectedConnectors;
  final List<String> allConnectors;
  final Color panelColor;
  final Color onPanelColor;
  final Color onPanelMutedColor;
  final Color panelSoftColor;
  final Color accentColor;
  final Color buttonOnAccentColor;
  final Color goodColor;

  static Future<FilterDraft?> show({
    required BuildContext context,
    required bool availableOnly,
    required double minPowerKw,
    required Set<String> selectedConnectors,
    required List<String> allConnectors,
    required Color panelColor,
    required Color onPanelColor,
    required Color onPanelMutedColor,
    required Color panelSoftColor,
    required Color accentColor,
    required Color buttonOnAccentColor,
    required Color goodColor,
  }) {
    return showModalBottomSheet<FilterDraft>(
      context: context,
      backgroundColor: panelColor,
      showDragHandle: true,
      builder: (context) => ChargerFilterSheet(
        availableOnly: availableOnly,
        minPowerKw: minPowerKw,
        selectedConnectors: selectedConnectors,
        allConnectors: allConnectors,
        panelColor: panelColor,
        onPanelColor: onPanelColor,
        onPanelMutedColor: onPanelMutedColor,
        panelSoftColor: panelSoftColor,
        accentColor: accentColor,
        buttonOnAccentColor: buttonOnAccentColor,
        goodColor: goodColor,
      ),
    );
  }

  @override
  State<ChargerFilterSheet> createState() => _ChargerFilterSheetState();
}

class _ChargerFilterSheetState extends State<ChargerFilterSheet> {
  late bool _availableOnly;
  late double _minPower;
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _availableOnly = widget.availableOnly;
    _minPower = widget.minPowerKw;
    _selected = {...widget.selectedConnectors};
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Chargers',
            style: TextStyle(
              color: widget.onPanelColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile.adaptive(
            value: _availableOnly,
            activeColor: widget.goodColor,
            title: Text(
              'Available slots only',
              style: TextStyle(color: widget.onPanelColor),
            ),
            onChanged: (value) {
              setState(() => _availableOnly = value);
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Minimum power: ${_minPower.round()} kW',
            style: TextStyle(color: widget.onPanelMutedColor),
          ),
          Slider(
            value: _minPower,
            min: 0,
            max: 350,
            divisions: 14,
            activeColor: widget.accentColor,
            label: '${_minPower.round()} kW',
            onChanged: (value) {
              setState(() => _minPower = value);
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Connector Types',
            style: TextStyle(color: widget.onPanelMutedColor),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.allConnectors.map((connector) {
              final selectedNow = _selected.contains(connector);
              return FilterChip(
                selected: selectedNow,
                label: Text(connector),
                labelStyle: TextStyle(
                  color: selectedNow
                      ? widget.buttonOnAccentColor
                      : widget.onPanelColor,
                ),
                selectedColor: widget.accentColor,
                backgroundColor: widget.panelSoftColor,
                checkmarkColor: widget.buttonOnAccentColor,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selected.add(connector);
                    } else {
                      _selected.remove(connector);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  FilterDraft(
                    availableOnly: _availableOnly,
                    minPowerKw: _minPower,
                    selectedConnectors: _selected,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: widget.buttonOnAccentColor,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
