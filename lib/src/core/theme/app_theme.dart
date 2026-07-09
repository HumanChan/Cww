import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  static const _lightScaffold = Color(0xFFF8FAFC);
  static const _darkScaffold = Color(0xFF020617);
  static const _darkSurface = Color(0xFF111827);

  static ThemeData get light {
    final theme = FlexThemeData.light(
      scheme: FlexScheme.brandBlue,
      useMaterial3: true,
      scaffoldBackground: _lightScaffold,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      subThemesData: _subThemes,
    );

    final scheme = theme.colorScheme.copyWith(surface: Colors.white);
    return _base(theme.copyWith(colorScheme: scheme)).copyWith(
      scaffoldBackgroundColor: _lightScaffold,
      cardTheme: _cardTheme(scheme),
    );
  }

  static ThemeData get dark {
    final theme = FlexThemeData.dark(
      scheme: FlexScheme.deepBlue,
      useMaterial3: true,
      scaffoldBackground: _darkScaffold,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      subThemesData: _subThemes,
    );

    final scheme = theme.colorScheme.copyWith(surface: _darkSurface);
    return _base(theme.copyWith(colorScheme: scheme)).copyWith(
      scaffoldBackgroundColor: _darkScaffold,
      cardTheme: _cardTheme(scheme),
    );
  }

  static const _subThemes = FlexSubThemesData(
    defaultRadius: 20,
    inputDecoratorRadius: 18,
    filledButtonRadius: 999,
    outlinedButtonRadius: 999,
    segmentedButtonRadius: 999,
  );

  static ThemeData _base(ThemeData theme) {
    final scheme = theme.colorScheme;
    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static CardThemeData _cardTheme(ColorScheme scheme) {
    return CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
    );
  }
}
