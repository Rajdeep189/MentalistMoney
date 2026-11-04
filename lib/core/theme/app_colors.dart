import 'package:flutter/material.dart';

/// Raw colour tokens for MoneyMan.
///
/// Every screen must read colours from [AppPalette] (available through the
/// `context.c` extension) so light and dark mode stay consistent.
class AppColors {
  AppColors._();

  // Brand
  static const Color accent = Color(0xFF916CFF);
  static const Color accentPressed = Color(0xFF7A55F0);
  static const Color accentLight = Color(0xFFEDE7FF);
  static const Color accentOnDark = Color(0xFFA78BFF);

  // Neutrals (light)
  static const Color ink = Color(0xFF0B0B0F);
  static const Color sub = Color(0xFF5A5A66);
  static const Color tertiary = Color(0xFF8A8A96);
  static const Color divider = Color(0xFFECECF2);
  static const Color surface = Color(0xFFF7F7FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = Color(0xFFF2F2F7);

  // Neutrals (dark)
  static const Color darkSurface = Color(0xFF121218);
  static const Color darkCard = Color(0xFF1B1B23);
  static const Color darkCardAlt = Color(0xFF22222B);
  static const Color darkDivider = Color(0xFF2A2A33);
  static const Color darkSub = Color(0xFFA5A5B2);
  static const Color darkTertiary = Color(0xFF7A7A88);

  // Semantic
  static const Color income = Color(0xFF12B76A);
  static const Color expense = Color(0xFFF04438);
  static const Color transfer = Color(0xFF2E90FA);
  static const Color warning = Color(0xFFF79009);

  static const Color incomeBg = Color(0xFFE8F8F0);
  static const Color expenseBg = Color(0xFFFEECEB);
  static const Color warningBg = Color(0xFFFFF6E6);
  static const Color infoBg = Color(0xFFEAF3FF);

  static const Color darkIncome = Color(0xFF34D399);
  static const Color darkExpense = Color(0xFFF87171);
  static const Color darkTransfer = Color(0xFF60A5FA);
  static const Color darkWarning = Color(0xFFFBBF24);

  /// Accent presets shown in Appearance settings.
  static const Map<String, Color> accentPresets = <String, Color>{
    'Violet': Color(0xFF916CFF),
    'Indigo': Color(0xFF5B67F1),
    'Blue': Color(0xFF2E90FA),
    'Teal': Color(0xFF11B4A0),
    'Green': Color(0xFF12B76A),
    'Orange': Color(0xFFF79009),
    'Pink': Color(0xFFE4559C),
    'Red': Color(0xFFF04438),
    'Mono': Color(0xFF3A3A44),
  };

  /// Muted chart palette – violet is reserved for the highlighted category.
  static const List<Color> chartPalette = <Color>[
    Color(0xFF916CFF),
    Color(0xFF5B67F1),
    Color(0xFF2E90FA),
    Color(0xFF11B4A0),
    Color(0xFF12B76A),
    Color(0xFFF79009),
    Color(0xFFE4559C),
    Color(0xFF8B8B98),
    Color(0xFFB08968),
    Color(0xFF6B7280),
  ];

  static const List<Color> categoryPalette = <Color>[
    Color(0xFFF79009),
    Color(0xFF2E90FA),
    Color(0xFFE4559C),
    Color(0xFF916CFF),
    Color(0xFF12B76A),
    Color(0xFF11B4A0),
    Color(0xFFF04438),
    Color(0xFF5B67F1),
    Color(0xFFB08968),
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFF64748B),
  ];

  static Color fromHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return Color(parsed ?? 0xFF916CFF);
  }

  static String toHex(Color color) {
    final v = color.value;
    return '#${v.toRadixString(16).substring(2).toUpperCase()}';
  }
}

/// Theme-aware palette exposed through `context.c`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.accent,
    required this.accentPressed,
    required this.accentSoft,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.cardAlt,
    required this.ink,
    required this.sub,
    required this.tertiary,
    required this.divider,
    required this.income,
    required this.expense,
    required this.transfer,
    required this.warning,
    required this.incomeBg,
    required this.expenseBg,
    required this.warningBg,
    required this.infoBg,
    required this.shadow,
    required this.navBar,
  });

  final bool isDark;
  final Color accent;
  final Color accentPressed;
  final Color accentSoft;
  final Color surface;
  final Color surfaceAlt;
  final Color card;
  final Color cardAlt;
  final Color ink;
  final Color sub;
  final Color tertiary;
  final Color divider;
  final Color income;
  final Color expense;
  final Color transfer;
  final Color warning;
  final Color incomeBg;
  final Color expenseBg;
  final Color warningBg;
  final Color infoBg;
  final Color shadow;
  final Color navBar;

  factory AppPalette.light(Color accent) {
    return AppPalette(
      isDark: false,
      accent: accent,
      accentPressed: _darken(accent, 0.12),
      accentSoft: _tint(accent, 0.90),
      surface: AppColors.surface,
      surfaceAlt: const Color(0xFFEFEFF6),
      card: AppColors.card,
      cardAlt: AppColors.cardAlt,
      ink: AppColors.ink,
      sub: AppColors.sub,
      tertiary: AppColors.tertiary,
      divider: AppColors.divider,
      income: AppColors.income,
      expense: AppColors.expense,
      transfer: AppColors.transfer,
      warning: AppColors.warning,
      incomeBg: AppColors.incomeBg,
      expenseBg: AppColors.expenseBg,
      warningBg: AppColors.warningBg,
      infoBg: AppColors.infoBg,
      shadow: const Color(0x0F0B0B0F),
      navBar: const Color(0xFFFFFFFF),
    );
  }

  factory AppPalette.dark(Color accent) {
    final bright = _isLight(accent) ? accent : _lighten(accent, 0.18);
    return AppPalette(
      isDark: true,
      accent: bright,
      accentPressed: _lighten(accent, 0.30),
      accentSoft: _tint(accent, 0.16),
      surface: AppColors.darkSurface,
      surfaceAlt: const Color(0xFF17171E),
      card: AppColors.darkCard,
      cardAlt: AppColors.darkCardAlt,
      ink: const Color(0xFFFFFFFF),
      sub: AppColors.darkSub,
      tertiary: AppColors.darkTertiary,
      divider: AppColors.darkDivider,
      income: AppColors.darkIncome,
      expense: AppColors.darkExpense,
      transfer: AppColors.darkTransfer,
      warning: AppColors.darkWarning,
      incomeBg: const Color(0xFF10281F),
      expenseBg: const Color(0xFF2A1616),
      warningBg: const Color(0xFF2A2213),
      infoBg: const Color(0xFF14243A),
      shadow: const Color(0x33000000),
      navBar: const Color(0xFF16161D),
    );
  }

  static bool _isLight(Color c) => c.computeLuminance() > 0.6;

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0).toDouble()).toColor();
  }

  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0).toDouble()).toColor();
  }

  static Color _tint(Color c, double lightness) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness(lightness)
        .withSaturation((hsl.saturation * 0.65).clamp(0.0, 1.0).toDouble())
        .toColor();
  }

  Color toneFor(String type) {
    switch (type) {
      case 'income':
        return income;
      case 'transfer':
        return transfer;
      default:
        return expense;
    }
  }

  Color toneBgFor(String type) {
    switch (type) {
      case 'income':
        return incomeBg;
      case 'transfer':
        return infoBg;
      default:
        return expenseBg;
    }
  }

  @override
  AppPalette copyWith({
    bool? isDark,
    Color? accent,
    Color? accentPressed,
    Color? accentSoft,
    Color? surface,
    Color? surfaceAlt,
    Color? card,
    Color? cardAlt,
    Color? ink,
    Color? sub,
    Color? tertiary,
    Color? divider,
    Color? income,
    Color? expense,
    Color? transfer,
    Color? warning,
    Color? incomeBg,
    Color? expenseBg,
    Color? warningBg,
    Color? infoBg,
    Color? shadow,
    Color? navBar,
  }) {
    return AppPalette(
      isDark: isDark ?? this.isDark,
      accent: accent ?? this.accent,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      card: card ?? this.card,
      cardAlt: cardAlt ?? this.cardAlt,
      ink: ink ?? this.ink,
      sub: sub ?? this.sub,
      tertiary: tertiary ?? this.tertiary,
      divider: divider ?? this.divider,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      warning: warning ?? this.warning,
      incomeBg: incomeBg ?? this.incomeBg,
      expenseBg: expenseBg ?? this.expenseBg,
      warningBg: warningBg ?? this.warningBg,
      infoBg: infoBg ?? this.infoBg,
      shadow: shadow ?? this.shadow,
      navBar: navBar ?? this.navBar,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      accent: mix(accent, other.accent),
      accentPressed: mix(accentPressed, other.accentPressed),
      accentSoft: mix(accentSoft, other.accentSoft),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      card: mix(card, other.card),
      cardAlt: mix(cardAlt, other.cardAlt),
      ink: mix(ink, other.ink),
      sub: mix(sub, other.sub),
      tertiary: mix(tertiary, other.tertiary),
      divider: mix(divider, other.divider),
      income: mix(income, other.income),
      expense: mix(expense, other.expense),
      transfer: mix(transfer, other.transfer),
      warning: mix(warning, other.warning),
      incomeBg: mix(incomeBg, other.incomeBg),
      expenseBg: mix(expenseBg, other.expenseBg),
      warningBg: mix(warningBg, other.warningBg),
      infoBg: mix(infoBg, other.infoBg),
      shadow: mix(shadow, other.shadow),
      navBar: mix(navBar, other.navBar),
    );
  }
}
