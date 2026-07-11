import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.canvasMuted,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceInteractive,
    required this.surfaceGlass,
    required this.overlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.borderSubtle,
    required this.border,
    required this.borderStrong,
    required this.focusRing,
    required this.brand,
    required this.brandHover,
    required this.brandSoft,
    required this.onBrand,
    required this.gain,
    required this.gainSoft,
    required this.loss,
    required this.lossSoft,
    required this.flat,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.chartGrid,
    required this.chartAxis,
    required this.ma5,
    required this.ma10,
    required this.ma20,
    required this.ma30,
    required this.ma60,
  });

  static const light = AppColors(
    canvas: Color(0xFFF6F8FC),
    canvasMuted: Color(0xFFEDF2FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceInteractive: Color(0xFFF1F5FA),
    surfaceGlass: Color(0xEFFFFFFF),
    overlay: Color(0x990F172A),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF64748B),
    textInverse: Color(0xFFF8FAFC),
    borderSubtle: Color(0xFFE8EDF5),
    border: Color(0xFFD7DFEA),
    borderStrong: Color(0xFF94A3B8),
    focusRing: Color(0xFF60A5FA),
    brand: Color(0xFF2563EB),
    brandHover: Color(0xFF1D4ED8),
    brandSoft: Color(0xFFE8F0FF),
    onBrand: Color(0xFFFFFFFF),
    gain: Color(0xFFE5484D),
    gainSoft: Color(0xFFFFEEEE),
    loss: Color(0xFF079455),
    lossSoft: Color(0xFFE8F8F0),
    flat: Color(0xFF64748B),
    warning: Color(0xFFD97706),
    warningSoft: Color(0xFFFFF4D6),
    info: Color(0xFF0891B2),
    infoSoft: Color(0xFFE6F7FA),
    chartGrid: Color(0xFFE5EAF2),
    chartAxis: Color(0xFF64748B),
    ma5: Color(0xFFD97706),
    ma10: Color(0xFF2563EB),
    ma20: Color(0xFF9333EA),
    ma30: Color(0xFF15803D),
    ma60: Color(0xFF64748B),
  );

  static const dark = AppColors(
    canvas: Color(0xFF070B14),
    canvasMuted: Color(0xFF0C1322),
    surface: Color(0xFF111827),
    surfaceRaised: Color(0xFF172033),
    surfaceInteractive: Color(0xFF1C2638),
    surfaceGlass: Color(0xEB111827),
    overlay: Color(0xB3000000),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textTertiary: Color(0xFF94A3B8),
    textInverse: Color(0xFF0F172A),
    borderSubtle: Color(0xFF202B3D),
    border: Color(0xFF334155),
    borderStrong: Color(0xFF64748B),
    focusRing: Color(0xFF60A5FA),
    brand: Color(0xFF60A5FA),
    brandHover: Color(0xFF93C5FD),
    brandSoft: Color(0xFF172A4D),
    onBrand: Color(0xFF07111F),
    gain: Color(0xFFFF7479),
    gainSoft: Color(0xFF3A1D22),
    loss: Color(0xFF34D399),
    lossSoft: Color(0xFF12352A),
    flat: Color(0xFF94A3B8),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF3A2B12),
    info: Color(0xFF67E8F9),
    infoSoft: Color(0xFF12343D),
    chartGrid: Color(0xFF263246),
    chartAxis: Color(0xFF94A3B8),
    ma5: Color(0xFFFBBF24),
    ma10: Color(0xFF60A5FA),
    ma20: Color(0xFFC084FC),
    ma30: Color(0xFF4ADE80),
    ma60: Color(0xFF94A3B8),
  );

  final Color canvas;
  final Color canvasMuted;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceInteractive;
  final Color surfaceGlass;
  final Color overlay;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color borderSubtle;
  final Color border;
  final Color borderStrong;
  final Color focusRing;
  final Color brand;
  final Color brandHover;
  final Color brandSoft;
  final Color onBrand;
  final Color gain;
  final Color gainSoft;
  final Color loss;
  final Color lossSoft;
  final Color flat;
  final Color warning;
  final Color warningSoft;
  final Color info;
  final Color infoSoft;
  final Color chartGrid;
  final Color chartAxis;
  final Color ma5;
  final Color ma10;
  final Color ma20;
  final Color ma30;
  final Color ma60;

  @override
  AppColors copyWith({
    Color? canvas,
    Color? canvasMuted,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceInteractive,
    Color? surfaceGlass,
    Color? overlay,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? borderSubtle,
    Color? border,
    Color? borderStrong,
    Color? focusRing,
    Color? brand,
    Color? brandHover,
    Color? brandSoft,
    Color? onBrand,
    Color? gain,
    Color? gainSoft,
    Color? loss,
    Color? lossSoft,
    Color? flat,
    Color? warning,
    Color? warningSoft,
    Color? info,
    Color? infoSoft,
    Color? chartGrid,
    Color? chartAxis,
    Color? ma5,
    Color? ma10,
    Color? ma20,
    Color? ma30,
    Color? ma60,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      canvasMuted: canvasMuted ?? this.canvasMuted,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceInteractive: surfaceInteractive ?? this.surfaceInteractive,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      overlay: overlay ?? this.overlay,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      focusRing: focusRing ?? this.focusRing,
      brand: brand ?? this.brand,
      brandHover: brandHover ?? this.brandHover,
      brandSoft: brandSoft ?? this.brandSoft,
      onBrand: onBrand ?? this.onBrand,
      gain: gain ?? this.gain,
      gainSoft: gainSoft ?? this.gainSoft,
      loss: loss ?? this.loss,
      lossSoft: lossSoft ?? this.lossSoft,
      flat: flat ?? this.flat,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      chartGrid: chartGrid ?? this.chartGrid,
      chartAxis: chartAxis ?? this.chartAxis,
      ma5: ma5 ?? this.ma5,
      ma10: ma10 ?? this.ma10,
      ma20: ma20 ?? this.ma20,
      ma30: ma30 ?? this.ma30,
      ma60: ma60 ?? this.ma60,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      canvasMuted: Color.lerp(canvasMuted, other.canvasMuted, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceInteractive:
          Color.lerp(surfaceInteractive, other.surfaceInteractive, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandHover: Color.lerp(brandHover, other.brandHover, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      gain: Color.lerp(gain, other.gain, t)!,
      gainSoft: Color.lerp(gainSoft, other.gainSoft, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      lossSoft: Color.lerp(lossSoft, other.lossSoft, t)!,
      flat: Color.lerp(flat, other.flat, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartAxis: Color.lerp(chartAxis, other.chartAxis, t)!,
      ma5: Color.lerp(ma5, other.ma5, t)!,
      ma10: Color.lerp(ma10, other.ma10, t)!,
      ma20: Color.lerp(ma20, other.ma20, t)!,
      ma30: Color.lerp(ma30, other.ma30, t)!,
      ma60: Color.lerp(ma60, other.ma60, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get appColors {
    return Theme.of(this).extension<AppColors>() ?? AppColors.light;
  }
}

class AppPalette {
  const AppPalette._();

  static const shell = Color(0xFF020617);
  static const phoneFrame = Color(0xFF1E293B);
  static const phoneNotch = Color(0xFF0F172A);
  static const screen = Color(0xFFF8FAFC);
  static const surface = Colors.white;

  static const text = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);

  static const blue600 = Color(0xFF2563EB);
  static const blue500 = Color(0xFF3B82F6);
  static const blue50 = Color(0xFFEFF6FF);
  static const cyan600 = Color(0xFF0891B2);
}

class AppSpacing {
  const AppSpacing._();

  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const huge = 48.0;
}

class AppRadii {
  const AppRadii._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const shell = 36.0;
  static const full = 999.0;
}

class AppControlSizes {
  const AppControlSizes._();

  static const compact = 32.0;
  static const small = 40.0;
  static const regular = 44.0;
  static const touch = 48.0;
  static const large = 56.0;
}

class AppDurations {
  const AppDurations._();

  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 180);
  static const emphasized = Duration(milliseconds: 260);
  static const route = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 360);
}

class AppMotionCurves {
  const AppMotionCurves._();

  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
  static const decelerate = Curves.decelerate;
}

class AppBreakpoints {
  const AppBreakpoints._();

  static const medium = 600.0;
  static const desktop = 900.0;
  static const expanded = 1024.0;
  static const maxContentWidth = 1180.0;
}

class AppTypographyTokens {
  const AppTypographyTokens._();

  static const fontFamily = 'Segoe UI';
  static const fontFamilyFallback = [
    'Microsoft YaHei',
    'PingFang SC',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> control() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 10,
        spreadRadius: -2,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> pill({
    required bool selected,
    Color selectedColor = AppPalette.blue600,
  }) {
    return [
      BoxShadow(
        color: selected
            ? selectedColor.withValues(alpha: 0.20)
            : Colors.black.withValues(alpha: 0.05),
        blurRadius: selected ? 10 : 8,
        spreadRadius: selected ? -1 : -2,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> card({bool elevated = false}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: elevated ? 0.13 : 0.075),
        blurRadius: elevated ? 34 : 24,
        spreadRadius: elevated ? -7 : -6,
        offset: Offset(0, elevated ? 12 : 7),
      ),
    ];
  }
}
