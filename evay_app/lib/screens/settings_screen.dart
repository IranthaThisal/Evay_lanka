import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/locale_controller.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailAlerts = false;

  @override
  Widget build(BuildContext context) {
    final controller = EvayThemeScope.read(context);
    final localeController = EvayLocaleScope.read(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(l10n.t('settings')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            _SettingsSectionLabel(label: l10n.t('language')),
            const SizedBox(height: 14),
            ValueListenableBuilder<Locale?>(
              valueListenable: localeController,
              builder: (context, locale, _) {
                final selected = locale?.languageCode ?? 'system';
                return _SettingsGroup(
                  children: [
                    _LanguageChoiceTile(
                      title: l10n.t('systemDefault'),
                      selected: selected == 'system',
                      onTap: () => localeController.update(null),
                    ),
                    _SettingsDivider(color: cs.outlineVariant),
                    _LanguageChoiceTile(
                      title: l10n.t('english'),
                      selected: selected == 'en',
                      onTap: () => localeController.update(const Locale('en')),
                    ),
                    _SettingsDivider(color: cs.outlineVariant),
                    _LanguageChoiceTile(
                      title: l10n.t('sinhala'),
                      selected: selected == 'si',
                      onTap: () => localeController.update(const Locale('si')),
                    ),
                    _SettingsDivider(color: cs.outlineVariant),
                    _LanguageChoiceTile(
                      title: l10n.t('tamil'),
                      selected: selected == 'ta',
                      onTap: () => localeController.update(const Locale('ta')),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            _SettingsSectionLabel(label: l10n.t('appearance')),
            const SizedBox(height: 14),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: controller,
              builder: (context, themeMode, _) {
                return _SettingsGroup(
                  children: [
                    _ThemeChoiceTile(
                      icon: Icons.desktop_windows_outlined,
                      title: l10n.t('systemDefault'),
                      selected: themeMode == ThemeMode.system,
                      onTap: () => controller.update(ThemeMode.system),
                    ),
                    _SettingsDivider(color: cs.outlineVariant),
                    _ThemeChoiceTile(
                      icon: Icons.light_mode_outlined,
                      title: l10n.t('lightTheme'),
                      selected: themeMode == ThemeMode.light,
                      onTap: () => controller.update(ThemeMode.light),
                    ),
                    _SettingsDivider(color: cs.outlineVariant),
                    _ThemeChoiceTile(
                      icon: Icons.dark_mode_outlined,
                      title: l10n.t('darkTheme'),
                      selected: themeMode == ThemeMode.dark,
                      onTap: () => controller.update(ThemeMode.dark),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              l10n.t('themeDescription'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            _SettingsSectionLabel(label: l10n.t('notifications')),
            const SizedBox(height: 14),
            _SettingsGroup(
              children: [
                _SwitchTile(
                  title: l10n.t('pushNotifications'),
                  subtitle: l10n.t('pushNotificationsSubtitle'),
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                  },
                ),
                _SettingsDivider(color: cs.outlineVariant),
                _SwitchTile(
                  title: l10n.t('emailAlerts'),
                  subtitle: l10n.t('emailAlertsSubtitle'),
                  value: _emailAlerts,
                  onChanged: (value) {
                    setState(() => _emailAlerts = value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChoiceTile extends StatelessWidget {
  const _LanguageChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? cs.primary : cs.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  const _ThemeChoiceTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(icon, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 14,
      endIndent: 14,
      color: color,
    );
  }
}
