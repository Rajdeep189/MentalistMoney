import 'package:flutter/material.dart';

/// Paisa-inspired palette: warm espresso paper, toasted cocoa cards, peach
/// accents and soft pastel tints — with a cream-and-peach light mode.
class AppColors {
  AppColors._();

  // Brand
  static const Color accent = Color(0xFFFFB49B);
  static const Color accentPressed = Color(0xFFFF9C7D);
  static const Color accentShift = Color(0xFFFFD3C2);
  static const Color accentLight = Color(0xFFFFE7DD);
  static const Color accentOnDark = Color(0xFFFFC6AE);
  static const Color espresso = Color(0xFF1B110E);

  // Metallics / decorative
  static const Color gold = Color(0xFFE0B27A);
  static const Color goldSoft = Color(0xFFF6E3CD);
  static const Color silver = Color(0xFFD9CFC9);
  static const Color chrome = Color(0xFFF3ECE7);
  static const Color graphite = Color(0xFF2A1B16);

  // Neutrals (dark) — chocolate
  static const Color ink = Color(0xFFF8EEE8);
  static const Color sub = Color(0xFFCDB6AA);
  static const Color tertiary = Color(0xFF9C8579);
  static const Color divider = Color(0xFF3A2A24);
  static const Color surface = Color(0xFF1B110E);
  static const Color surfaceAlt = Color(0xFF241713);
  static const Color card = Color(0xFF2A1B16);
  static const Color cardAlt = Color(0xFF33221C);

  // Neutrals (light) — cream
  static const Color lightSurface = Color(0xFFFFF7F2);
  static const Color lightSurfaceAlt = Color(0xFFFDEDE4);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFFFF1E9);
  static const Color darkSurface = Color(0xFF1B110E);
  static const Color darkSurfaceAlt = Color(0xFF241713);
  static const Color darkCard = Color(0xFF2A1B16);
  static const Color darkCardAlt = Color(0xFF33221C);
  static const Color darkDivider = Color(0xFF3A2A24);
  static const Color darkSub = Color(0xFFCDB6AA);
  static const Color darkTertiary = Color(0xFF9C8579);

  // Semantic
  static const Color income = Color(0xFF3DDC97);
  static const Color expense = Color(0xFFFB6B6B);
  static const Color transfer = Color(0xFF8E9BFF);
  static const Color warning = Color(0xFFF2C14E);

  static const Color incomeBg = Color(0xFF123A28);
  static const Color expenseBg = Color(0xFF3D1A18);
  static const Color warningBg = Color(0xFF3A2F13);
  static const Color infoBg = Color(0xFF1E2340);

  static const Color lightIncome = Color(0xFF0F8A57);
  static const Color lightExpense = Color(0xFFC2372F);
  static const Color lightTransfer = Color(0xFF5B6BF0);
  static const Color lightWarning = Color(0xFFB07A12);

  static const Color darkIncome = Color(0xFF3DDC97);
  static const Color darkExpense = Color(0xFFFF7A75);
  static const Color darkTransfer = Color(0xFF9AA5FF);
  static const Color darkWarning = Color(0xFFF2C14E);

  // Pastel tints used by summary tiles, budget cards and goal cards.
  static const Color periwinkle = Color(0xFFDCDCFB);
  static const Color periwinkleDeep = Color(0xFF4C4C9E);
  static const Color mint = Color(0xFFCBEBD9);
  static const Color mintDeep = Color(0xFF1F6B4A);
  static const Color tan = Color(0xFFF0D6B8);
  static const Color tanDeep = Color(0xFF7A4A1E);
  static const Color lilac = Color(0xFFE7D3F2);
  static const Color lilacDeep = Color(0xFF67398A);
  static const Color blush = Color(0xFFF9DDD5);
  static const Color blushDeep = Color(0xFF9A4A32);
  static const Color butter = Color(0xFFF6EAB9);
  static const Color butterDeep = Color(0xFF7C6516);

  // Legacy aliases kept so older widgets keep the warm palette.
  static const Color limeA = Color(0xFFFFC6AE);
  static const Color limeB = Color(0xFFFFB49B);
  static const Color sunset = Color(0xFFFB6B6B);
  static const Color sky = Color(0xFF8E9BFF);
  static const Color violet = Color(0xFFB6A6F0);
  static const Color tangerine = Color(0xFFF2C14E);

  // Signature gradients
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFC3A6), Color(0xFFFF9C7D)],
  );

  static const LinearGradient limeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFBFF3D7), Color(0xFF7FE0B4)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF6E3CD), Color(0xFFE0B27A)],
  );

  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFC3A6), Color(0xFFE7D3F2), Color(0xFF8E9BFF)],
  );

  static const LinearGradient metalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFF3EC), Color(0xFFF3D8C8), Color(0xFFE7B79C)],
  );

  static const LinearGradient graphiteGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF6B3B26), Color(0xFF4A2718), Color(0xFF33190F)],
  );

  /// Accent presets shown in Appearance settings.
  static const Map<String, Color> accentPresets = <String, Color>{
    'Peach': accent,
    'Terracotta': Color(0xFFE0785A),
    'Rose': Color(0xFFF08AA8),
    'Sand': Color(0xFFE8C9A0),
    'Sage': Color(0xFF9CC5A1),
    'Sky': Color(0xFF8FBBE8),
    'Lavender': Color(0xFFB6A6F0),
    'Cocoa': Color(0xFFB07A5A),
  };

  /// Chart palette — peach, sage, lavender, sky, butter, rose.
  static const List<Color> chartPalette = <Color>[
    Color(0xFFFFB49B),
    Color(0xFF9CD9B4),
    Color(0xFFB6A6F0),
    Color(0xFF8FBBE8),
    Color(0xFFF2D785),
    Color(0xFFF08AA8),
    Color(0xFFE0B27A),
    Color(0xFF9C8579),
  ];

  static const List<Color> categoryPalette = <Color>[
    Color(0xFFFFB49B),
    Color(0xFF9CD9B4),
    Color(0xFFB6A6F0),
    Color(0xFF8FBBE8),
    Color(0xFFF2D785),
    Color(0xFFF08AA8),
    Color(0xFFE0B27A),
    Color(0xFF6FD3C7),
    Color(0xFFE8887A),
    Color(0xFF9C8579),
  ];

  static Color fromHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return Color(parsed ?? 0xFFFFB49B);
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
    required this.onAccent,
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
    required this.glass,
    required this.glassBorder,
    required this.violet,
    required this.gold,
    required this.heroTop,
    required this.heroBottom,
  });

  final bool isDark;
  final Color accent;
  final Color accentPressed;
  final Color accentSoft;
  final Color onAccent;
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

  /// Translucent surface used by the floating navigation bar.
  final Color glass;
  final Color glassBorder;
  final Color violet;
  final Color gold;

  /// Warm hero card gradient endpoints.
  final Color heroTop;
  final Color heroBottom;

  /// Readable foreground for accent-tinted surfaces.
  Color get onSoft => isDark ? accent : ink;

  /// Neutral text tone that works on both pastel and dark tiles.
  Color get pastelInk => isDark ? AppColors.ink : AppColors.espresso;

  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[accent, Color.lerp(accent, AppColors.accentShift, 0.55)!],
      );

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[heroTop, heroBottom],
      );

  LinearGradient get sunsetGradient => AppColors.sunsetGradient;

  LinearGradient get auroraGradient => AppColors.auroraGradient;

  LinearGradient get metalGradient => AppColors.metalGradient;

  factory AppPalette.light(Color accent) {
    final ink = AppColors.espresso;
    return AppPalette(
      isDark: false,
      accent: accent,
      accentPressed: _darken(accent, 0.06),
      accentSoft: _tint(accent, 0.62),
      onAccent: _isLight(accent) ? const Color(0xFF3A1B0E) : Colors.white,
      surface: AppColors.lightSurface,
      surfaceAlt: AppColors.lightSurfaceAlt,
      card: AppColors.lightCard,
      cardAlt: AppColors.lightCardAlt,
      ink: ink,
      sub: const Color(0xFF7A5F52),
      tertiary: const Color(0xFFA4877A),
      divider: const Color(0xFFF1E2D8),
      income: AppColors.lightIncome,
      expense: AppColors.lightExpense,
      transfer: AppColors.lightTransfer,
      warning: AppColors.lightWarning,
      incomeBg: const Color(0xFFE7F6EE),
      expenseBg: const Color(0xFFFDECEA),
      warningBg: const Color(0xFFFCF3DD),
      infoBg: const Color(0xFFEDF0FE),
      shadow: const Color(0x14583220),
      navBar: const Color(0xFFFFF6F0),
      glass: const Color(0xF7FFF6F0),
      glassBorder: const Color(0x1A3A1B0E),
      violet: const Color(0xFF8E80E8),
      gold: AppColors.gold,
      heroTop: const Color(0xFFFFD8C5),
      heroBottom: const Color(0xFFFFC2A8),
    );
  }

  factory AppPalette.dark(Color accent) {
    final bright = _isLight(accent) ? accent : _lighten(accent, 0.20);
    return AppPalette(
      isDark: true,
      accent: bright,
      accentPressed: _lighten(accent, 0.26),
      accentSoft: _tint(accent, 0.18),
      onAccent: _isLight(bright) ? const Color(0xFF3A1B0E) : Colors.white,
      surface: AppColors.darkSurface,
      surfaceAlt: AppColors.darkSurfaceAlt,
      card: AppColors.darkCard,
      cardAlt: AppColors.darkCardAlt,
      ink: AppColors.ink,
      sub: AppColors.darkSub,
      tertiary: AppColors.darkTertiary,
      divider: AppColors.darkDivider,
      income: AppColors.darkIncome,
      expense: AppColors.darkExpense,
      transfer: AppColors.darkTransfer,
      warning: AppColors.darkWarning,
      incomeBg: AppColors.incomeBg,
      expenseBg: AppColors.expenseBg,
      warningBg: AppColors.warningBg,
      infoBg: AppColors.infoBg,
      shadow: const Color(0x66000000),
      navBar: const Color(0xFF1F1512),
      glass: const Color(0xF21F1512),
      glassBorder: const Color(0x1AFFFFFF),
      violet: const Color(0xFFB6A6F0),
      gold: AppColors.gold,
      heroTop: const Color(0xFF6B3B26),
      heroBottom: const Color(0xFF3F2115),
    );
  }

  static Color _tint(Color color, double amount) {
    return Color.lerp(color, const Color(0xFFFFF7F2), amount)!;
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0).toDouble())
        .toColor();
  }

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0).toDouble())
        .toColor();
  }

  static bool _isLight(Color color) => color.computeLuminance() > 0.55;

  @override
  AppPalette copyWith({
    bool? isDark,
    Color? accent,
    Color? accentPressed,
    Color? accentSoft,
    Color? onAccent,
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
    Color? glass,
    Color? glassBorder,
    Color? violet,
    Color? gold,
    Color? heroTop,
    Color? heroBottom,
  }) {
    return AppPalette(
      isDark: isDark ?? this.isDark,
      accent: accent ?? this.accent,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
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
      glass: glass ?? this.glass,
      glassBorder: glassBorder ?? this.glassBorder,
      violet: violet ?? this.violet,
      gold: gold ?? this.gold,
      heroTop: heroTop ?? this.heroTop,
      heroBottom: heroBottom ?? this.heroBottom,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      accent: mix(accent, other.accent),
      accentPressed: mix(accentPressed, other.accentPressed),
      accentSoft: mix(accentSoft, other.accentSoft),
      onAccent: mix(onAccent, other.onAccent),
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
      glass: mix(glass, other.glass),
      glassBorder: mix(glassBorder, other.glassBorder),
      violet: mix(violet, other.violet),
      gold: mix(gold, other.gold),
      heroTop: mix(heroTop, other.heroTop),
      heroBottom: mix(heroBottom, other.heroBottom),
    );
  }
}
