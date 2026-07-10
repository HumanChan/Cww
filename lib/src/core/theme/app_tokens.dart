import 'package:flutter/material.dart';

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
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 6,
        spreadRadius: -1,
        offset: const Offset(0, 2),
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
        color: Colors.black.withValues(alpha: elevated ? 0.10 : 0.05),
        blurRadius: elevated ? 30 : 20,
        spreadRadius: -4,
        offset: Offset(0, elevated ? 8 : 4),
      ),
    ];
  }
}
