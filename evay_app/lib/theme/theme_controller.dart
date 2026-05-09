import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  void update(ThemeMode mode) {
    if (value == mode) return;
    value = mode;
  }
}

class EvayThemeScope extends InheritedNotifier<ThemeController> {
  const EvayThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EvayThemeScope>();
    assert(scope != null, 'EvayThemeScope not found in widget tree.');
    return scope!.notifier!;
  }

  static ThemeController read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<EvayThemeScope>();
    final scope = element?.widget as EvayThemeScope?;
    assert(scope != null, 'EvayThemeScope not found in widget tree.');
    return scope!.notifier!;
  }
}
