import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        colors: AppColors.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        colors: AppColors.dark,
      );

  static const _subThemes = FlexSubThemesData(
    defaultRadius: AppRadii.lg,
    inputDecoratorRadius: AppRadii.md,
    filledButtonRadius: AppRadii.full,
    outlinedButtonRadius: AppRadii.full,
    segmentedButtonRadius: AppRadii.full,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
  }) {
    final seed = brightness == Brightness.light
        ? FlexThemeData.light(
            scheme: FlexScheme.brandBlue,
            useMaterial3: true,
            subThemesData: _subThemes,
          )
        : FlexThemeData.dark(
            scheme: FlexScheme.deepBlue,
            useMaterial3: true,
            subThemesData: _subThemes,
          );

    final colorScheme = seed.colorScheme.copyWith(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: colors.onBrand,
      primaryContainer: colors.brandSoft,
      onPrimaryContainer: colors.textPrimary,
      secondary: colors.info,
      onSecondary: colors.textInverse,
      secondaryContainer: colors.infoSoft,
      onSecondaryContainer: colors.textPrimary,
      tertiary: colors.warning,
      onTertiary: colors.textInverse,
      tertiaryContainer: colors.warningSoft,
      onTertiaryContainer: colors.textPrimary,
      error: colors.loss,
      onError: colors.textInverse,
      errorContainer: colors.lossSoft,
      onErrorContainer: colors.textPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainerLowest: colors.surface,
      surfaceContainerLow: colors.canvasMuted,
      surfaceContainer: colors.surfaceInteractive,
      surfaceContainerHigh: colors.surfaceRaised,
      surfaceContainerHighest: colors.surfaceInteractive,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.borderStrong,
      outlineVariant: colors.border,
      shadow: const Color(0xFF000000),
      scrim: colors.overlay,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.textInverse,
      inversePrimary: colors.brandHover,
      surfaceTint: colors.brand,
    );

    final textTheme = seed.textTheme.apply(
      fontFamily: AppTypographyTokens.fontFamily,
      fontFamilyFallback: AppTypographyTokens.fontFamilyFallback,
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );
    final primaryTextTheme = seed.primaryTextTheme.apply(
      fontFamily: AppTypographyTokens.fontFamily,
      fontFamilyFallback: AppTypographyTokens.fontFamilyFallback,
      bodyColor: colors.onBrand,
      displayColor: colors.onBrand,
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.full),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      side: BorderSide(color: colors.borderSubtle),
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: colors.border),
    );

    return seed.copyWith(
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      cardColor: colors.surface,
      dividerColor: colors.borderSubtle,
      disabledColor: colors.textTertiary.withValues(alpha: 0.50),
      shadowColor: Colors.black.withValues(
        alpha: brightness == Brightness.light ? 0.12 : 0.36,
      ),
      splashColor: colors.brand.withValues(alpha: 0.10),
      highlightColor: colors.brand.withValues(alpha: 0.06),
      hoverColor: colors.brand.withValues(alpha: 0.06),
      focusColor: colors.focusRing.withValues(alpha: 0.14),
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppControlSizes.regular),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
          shape: WidgetStatePropertyAll(controlShape),
          animationDuration: AppDurations.standard,
          overlayColor: _buttonOverlay(colors),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppControlSizes.regular),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
          shape: WidgetStatePropertyAll(controlShape),
          elevation: const WidgetStatePropertyAll(0),
          animationDuration: AppDurations.standard,
          overlayColor: _buttonOverlay(colors),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppControlSizes.regular),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
          shape: WidgetStatePropertyAll(controlShape),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(
              color: states.contains(WidgetState.focused)
                  ? colors.focusRing
                  : colors.border,
              width: states.contains(WidgetState.focused) ? 1.5 : 1,
            );
          }),
          animationDuration: AppDurations.standard,
          overlayColor: _buttonOverlay(colors),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppControlSizes.regular),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          shape: WidgetStatePropertyAll(controlShape),
          animationDuration: AppDurations.standard,
          overlayColor: _buttonOverlay(colors),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppControlSizes.regular),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.textTertiary.withValues(alpha: 0.50);
            }
            if (states.contains(WidgetState.hovered)) return colors.brand;
            return colors.textSecondary;
          }),
          shape: const WidgetStatePropertyAll(CircleBorder()),
          overlayColor: _buttonOverlay(colors),
          animationDuration: AppDurations.fast,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceInteractive,
        hoverColor: colors.brandSoft.withValues(alpha: 0.45),
        iconColor: colors.textTertiary,
        prefixIconColor: colors.textTertiary,
        suffixIconColor: colors.textTertiary,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: colors.brand,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: colors.focusRing, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: colors.loss),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: colors.loss, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(
          alpha: brightness == Brightness.light ? 0.08 : 0.28,
        ),
        shape: cardShape,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: colors.borderSubtle),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: colors.surfaceRaised,
        modalBackgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        dragHandleColor: colors.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: brightness == Brightness.light
            ? colors.textPrimary
            : colors.surfaceRaised,
        actionTextColor: colors.brand,
        disabledActionTextColor: colors.textTertiary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: brightness == Brightness.light
              ? colors.textInverse
              : colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        interactive: true,
        minThumbLength: AppControlSizes.large,
        mainAxisMargin: AppSpacing.xs,
        crossAxisMargin: 2,
        radius: const Radius.circular(AppRadii.full),
        thickness: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.hovered) ? 8 : 5;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          final opacity = states.contains(WidgetState.hovered) ? 0.72 : 0.42;
          return colors.textTertiary.withValues(alpha: opacity);
        }),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 420),
        showDuration: const Duration(seconds: 3),
        preferBelow: false,
        verticalOffset: AppSpacing.sm,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
        textStyle: textTheme.labelMedium?.copyWith(
          color: colors.textInverse,
          fontWeight: FontWeight.w600,
        ),
        decoration: BoxDecoration(
          color: colors.textPrimary.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textTertiary,
        textColor: colors.textPrimary,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colors.textTertiary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.brand,
        linearTrackColor: colors.brandSoft,
        circularTrackColor: colors.brandSoft,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.brand,
        selectionColor: colors.brand.withValues(alpha: 0.24),
        selectionHandleColor: colors.brand,
      ),
    );
  }

  static WidgetStateProperty<Color?> _buttonOverlay(AppColors colors) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return colors.brand.withValues(alpha: 0.14);
      }
      if (states.contains(WidgetState.focused)) {
        return colors.focusRing.withValues(alpha: 0.14);
      }
      if (states.contains(WidgetState.hovered)) {
        return colors.brand.withValues(alpha: 0.08);
      }
      return null;
    });
  }
}
