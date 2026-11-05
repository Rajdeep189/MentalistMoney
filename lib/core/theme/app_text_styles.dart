import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography — a warm geometric sans (Poppins) with a heavier display weight
/// for headings and hero amounts, and tabular numerals for money.
class AppTextStyles {
  AppTextStyles._();

  static const String family = 'Poppins';
  static const String serifFamily = 'Poppins';

  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static TextStyle base({
    required double size,
    FontWeight weight = FontWeight.w400,
    double height = 1.35,
    double? letterSpacing,
    bool tabularFigures = false,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: tabularFigures ? tabular : null,
    );
  }

  /// Display face used for titles and big numbers.
  static TextStyle serif({
    required double size,
    required Color color,
    double height = 1.15,
    double? letterSpacing,
    bool tabularFigures = false,
    FontWeight weight = FontWeight.w700,
  }) {
    return base(
      size: size,
      weight: weight,
      height: height,
      letterSpacing: letterSpacing ?? -0.2,
      tabularFigures: tabularFigures,
      fontFamily: serifFamily,
    ).copyWith(color: color);
  }

  // Display XL – hero amounts
  static TextStyle displayXL(Color color) => serif(
        size: 40,
        color: color,
        height: 1.05,
        letterSpacing: -0.6,
        tabularFigures: true,
      );

  // Display L – page titles / report totals
  static TextStyle displayL(Color color) => serif(
        size: 30,
        color: color,
        height: 1.1,
        letterSpacing: -0.3,
        tabularFigures: true,
      );

  static TextStyle h1(Color color) => serif(
        size: 26,
        color: color,
        height: 1.18,
        letterSpacing: -0.2,
      );

  static TextStyle h2(Color color) => serif(
        size: 21,
        color: color,
        height: 1.22,
      );

  static TextStyle h3(Color color) => serif(
        size: 18,
        color: color,
        height: 1.28,
      );

  /// Wordmark used in the home header and splash.
  static TextStyle wordmark(Color color, {double size = 26}) => serif(
        size: size,
        color: color,
        height: 1.0,
        letterSpacing: 0.4,
      );

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
        size: 10.5,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.4,
      ).copyWith(color: color);

  /// Money amount. Hero sizes use the serif face, dense rows use tabular sans.
  static TextStyle money(
    double size, {
    required Color color,
    FontWeight weight = FontWeight.w600,
    double? letterSpacing,
    bool? serifFace,
  }) {
    final useSerif = serifFace ?? size >= 18;
    if (useSerif) {
      return AppTextStyles.serif(
        size: size,
        color: color,
        height: 1.08,
        letterSpacing: letterSpacing ?? -0.2,
        tabularFigures: true,
      );
    }
    return base(
      size: size,
      weight: weight,
      height: 1.12,
      letterSpacing: letterSpacing,
      tabularFigures: true,
    ).copyWith(color: color);
  }

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
  TextStyle get serif => AppTextStyles.serif(size: 22, color: c.ink);
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
