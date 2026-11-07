import 'package:flutter/material.dart';

@immutable
class EvayPalette extends ThemeExtension<EvayPalette> {
  const EvayPalette({
    required this.heroGradient,
    required this.heroAccent,
    required this.mapBackground,
    required this.mapPanel,
    required this.mapPanelSoft,
    required this.mapAccent,
    required this.mapGood,
    required this.newsCard,
    required this.newsBorder,
    required this.newsChip,
    required this.warningBackground,
    required this.warningBorder,
    required this.success,
    required this.danger,
    required this.neutral,
  });

  final Gradient heroGradient;
  final Color heroAccent;
  final Color mapBackground;
  final Color mapPanel;
  final Color mapPanelSoft;
  final Color mapAccent;
  final Color mapGood;
  final Color newsCard;
  final Color newsBorder;
  final Color newsChip;
  final Color warningBackground;
  final Color warningBorder;
  final Color success;
  final Color danger;
  final Color neutral;

  @override
  EvayPalette copyWith({
    Gradient? heroGradient,
    Color? heroAccent,
    Color? mapBackground,
    Color? mapPanel,
    Color? mapPanelSoft,
    Color? mapAccent,
    Color? mapGood,
    Color? newsCard,
    Color? newsBorder,
    Color? newsChip,
    Color? warningBackground,
    Color? warningBorder,
    Color? success,
    Color? danger,
    Color? neutral,
  }) {
    return EvayPalette(
      heroGradient: heroGradient ?? this.heroGradient,
      heroAccent: heroAccent ?? this.heroAccent,
      mapBackground: mapBackground ?? this.mapBackground,
      mapPanel: mapPanel ?? this.mapPanel,
      mapPanelSoft: mapPanelSoft ?? this.mapPanelSoft,
      mapAccent: mapAccent ?? this.mapAccent,
      mapGood: mapGood ?? this.mapGood,
      newsCard: newsCard ?? this.newsCard,
      newsBorder: newsBorder ?? this.newsBorder,
      newsChip: newsChip ?? this.newsChip,
      warningBackground: warningBackground ?? this.warningBackground,
      warningBorder: warningBorder ?? this.warningBorder,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  EvayPalette lerp(ThemeExtension<EvayPalette>? other, double t) {
    if (other is! EvayPalette) return this;

    return EvayPalette(
      heroGradient:
          LinearGradient.lerp(
            heroGradient as LinearGradient,
            other.heroGradient as LinearGradient,
            t,
          ) ??
          heroGradient,
      heroAccent: Color.lerp(heroAccent, other.heroAccent, t) ?? heroAccent,
      mapBackground:
          Color.lerp(mapBackground, other.mapBackground, t) ?? mapBackground,
      mapPanel: Color.lerp(mapPanel, other.mapPanel, t) ?? mapPanel,
      mapPanelSoft:
          Color.lerp(mapPanelSoft, other.mapPanelSoft, t) ?? mapPanelSoft,
      mapAccent: Color.lerp(mapAccent, other.mapAccent, t) ?? mapAccent,
      mapGood: Color.lerp(mapGood, other.mapGood, t) ?? mapGood,
      newsCard: Color.lerp(newsCard, other.newsCard, t) ?? newsCard,
      newsBorder: Color.lerp(newsBorder, other.newsBorder, t) ?? newsBorder,
      newsChip: Color.lerp(newsChip, other.newsChip, t) ?? newsChip,
      warningBackground:
          Color.lerp(warningBackground, other.warningBackground, t) ??
          warningBackground,
      warningBorder:
          Color.lerp(warningBorder, other.warningBorder, t) ?? warningBorder,
      success: Color.lerp(success, other.success, t) ?? success,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
    );
  }
}

class AppTheme {
  static const _lightSeed = Color(0xFF7FD4A3);
  static const _darkSeed = Color(0xFF72C5F8);

  static final ThemeData _lightTheme = _createLightTheme();
  static final ThemeData _darkTheme = _createDarkTheme();

  static ThemeData light() => _lightTheme;
  static ThemeData dark() => _darkTheme;

  static ThemeData _createLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _lightSeed,
      brightness: Brightness.light,
      primary: const Color(0xFF53B97A),
      secondary: const Color(0xFF9AE2B7),
      surface: const Color(0xFFF6FCF8),
    );

    return _buildTheme(
      scheme,
      const EvayPalette(
        heroGradient: LinearGradient(
          colors: [Color(0xFFDCF7E5), Color(0xFFB8EBCB), Color(0xFFA7E0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        heroAccent: Color(0xFF3D9E67),
        mapBackground: Color(0xFFFFFFFF),
        mapPanel: Color(0xFFFFFFFF),
        mapPanelSoft: Color(0xFFF1F8F3),
        mapAccent: Color(0xFF9BE7B2),
        mapGood: Color(0xFF53B97A),
        newsCard: Color(0xFFF7FBF8),
        newsBorder: Color(0xFFD7E7DC),
        newsChip: Color(0xFFE2F0E8),
        warningBackground: Color(0xFFFFF7E6),
        warningBorder: Color(0xFFFFD78A),
        success: Color(0xFF288B57),
        danger: Color(0xFFCF4B5A),
        neutral: Color(0xFF8A96A3),
      ),
    );
  }

  static ThemeData _createDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _darkSeed,
      brightness: Brightness.dark,
      primary: const Color(0xFF7DD1FF),
      secondary: const Color(0xFF4FA6D9),
      surface: const Color(0xFF101C26),
    );

    return _buildTheme(
      scheme,
      const EvayPalette(
        heroGradient: LinearGradient(
          colors: [Color(0xFF0D2231), Color(0xFF15354A), Color(0xFF214C66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        heroAccent: Color(0xFF72C5F8),
        mapBackground: Color(0xFF08141D),
        mapPanel: Color(0xFF132430),
        mapPanelSoft: Color(0xFF1B3342),
        mapAccent: Color(0xFF72C5F8),
        mapGood: Color(0xFF69D59C),
        newsCard: Color(0xFF132430),
        newsBorder: Color(0xFF244154),
        newsChip: Color(0xFF1B3342),
        warningBackground: Color(0xFF35280E),
        warningBorder: Color(0xFF9E7D2A),
        success: Color(0xFF69D59C),
        danger: Color(0xFFFF7B86),
        neutral: Color(0xFF8696A6),
      ),
    );
  }

  static ThemeData _buildTheme(ColorScheme scheme, EvayPalette palette) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: scheme.onPrimary,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),
    );
  }
}

extension EvayThemeX on BuildContext {
  EvayPalette get evayPalette => Theme.of(this).extension<EvayPalette>()!;
}
