import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale – Poppins (Circular-Std-like geometric sans) with
/// tabular figures for every numeric value.
class AppTextStyles {
  AppTextStyles._();

  static const String family = 'Poppins';

  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static TextStyle base({
    required double size,
    FontWeight weight = FontWeight.w400,
    double height = 1.35,
    double? letterSpacing,
    bool tabularFigures = false,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: tabularFigures ? tabular : null,
    );
  }

  // Display XL – total balance / safe to spend
  static TextStyle displayXL(Color color) => base(
        size: 34,
        weight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.8,
        tabularFigures: true,
      ).copyWith(color: color);

  // Display L – page titles / report totals
  static TextStyle displayL(Color color) => base(
        size: 28,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        tabularFigures: true,
      ).copyWith(color: color);

  static TextStyle h1(Color color) => base(
        size: 24,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.3,
      ).copyWith(color: color);

  static TextStyle h2(Color color) => base(
        size: 20,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
      ).copyWith(color: color);

  static TextStyle h3(Color color) => base(
        size: 18,
        weight: FontWeight.w600,
        height: 1.3,
      ).copyWith(color: color);

  static TextStyle bodyLarge(Color color) => base(
        size: 16,
        height: 1.45,
      ).copyWith(color: color);

  static TextStyle body(Color color) => base(
        size: 14,
        height: 1.45,
      ).copyWith(color: color);

  static TextStyle label(Color color) => base(
        size: 13,
        weight: FontWeight.w500,
        height: 1.3,
      ).copyWith(color: color);

  static TextStyle caption(Color color) => base(
        size: 12,
        height: 1.35,
      ).copyWith(color: color);

  static TextStyle overline(Color color) => base(
        size: 11,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.5,
      ).copyWith(color: color);

  /// Money amount with tabular figures.
  static TextStyle money(
    double size, {
    required Color color,
    FontWeight weight = FontWeight.w600,
    double? letterSpacing,
  }) =>
      base(
        size: size,
        weight: weight,
        height: 1.12,
        letterSpacing: letterSpacing,
        tabularFigures: true,
      ).copyWith(color: color);

  /// Builds the Material [TextTheme] wiring the scale above.
  static TextTheme textTheme(Color ink, Color sub) {
    return TextTheme(
      displayLarge: displayXL(ink),
      displayMedium: displayL(ink),
      displaySmall: h1(ink),
      headlineLarge: h1(ink),
      headlineMedium: h2(ink),
      headlineSmall: h3(ink),
      titleLarge: h3(ink),
      titleMedium: label(ink),
      titleSmall: label(sub),
      bodyLarge: bodyLarge(ink),
      bodyMedium: body(ink),
      bodySmall: caption(sub),
      labelLarge: label(ink),
      labelMedium: label(sub),
      labelSmall: caption(sub),
    );
  }
}

/// Shorthand typography + colour access used across the widget layer.
extension AppThemeContext on BuildContext {
  AppPalette get c => Theme.of(this).extension<AppPalette>()!;

  TextTheme get tt => Theme.of(this).textTheme;

  TextStyle get displayXL => AppTextStyles.displayXL(c.ink);
  TextStyle get displayL => AppTextStyles.displayL(c.ink);
  TextStyle get h1 => AppTextStyles.h1(c.ink);
  TextStyle get h2 => AppTextStyles.h2(c.ink);
  TextStyle get h3 => AppTextStyles.h3(c.ink);
  TextStyle get bodyL => AppTextStyles.bodyLarge(c.ink);
  TextStyle get body => AppTextStyles.body(c.ink);
  TextStyle get bodyMuted => AppTextStyles.body(c.sub);
  TextStyle get label => AppTextStyles.label(c.ink);
  TextStyle get labelMuted => AppTextStyles.label(c.sub);
  TextStyle get caption => AppTextStyles.caption(c.tertiary);
  TextStyle get overline => AppTextStyles.overline(c.tertiary);

  TextStyle money(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w600,
    double? letterSpacing,
  }) =>
      AppTextStyles.money(
        size,
        color: color ?? c.ink,
        weight: weight,
        letterSpacing: letterSpacing,
      );
}
