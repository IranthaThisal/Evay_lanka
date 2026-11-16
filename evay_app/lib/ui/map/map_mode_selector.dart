import 'package:flutter/material.dart';

/// Item representing a selectable mode in [MapModeSelector].
class MapModeItem {
  const MapModeItem({required this.label, required this.value});

  final String label;
  final String value;
}

/// Responsive segmented mode selector for switching between nearby, on-route, and all chargers.
class MapModeSelector extends StatelessWidget {
  const MapModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
    required this.items,
    required this.accentColor,
    required this.panelColor,
    required this.panelBorderColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
  });

  final String currentMode;
  final ValueChanged<String> onModeSelected;
  final List<MapModeItem> items;
  final Color accentColor;
  final Color panelColor;
  final Color panelBorderColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _buildChip(items[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(MapModeItem item) {
    final selected = currentMode == item.value;
    return GestureDetector(
      onTap: () {
        if (!selected) {
          onModeSelected(item.value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? accentColor : panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : panelBorderColor,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? selectedTextColor : unselectedTextColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}
