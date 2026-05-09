import 'package:flutter/material.dart';

class LocaleController extends ValueNotifier<Locale?> {
  LocaleController() : super(null);

  void update(Locale? locale) => value = locale;
}

class EvayLocaleScope extends InheritedWidget {
  const EvayLocaleScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final LocaleController controller;

  static LocaleController read(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EvayLocaleScope>();
    assert(scope != null, 'EvayLocaleScope not found in context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(EvayLocaleScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
