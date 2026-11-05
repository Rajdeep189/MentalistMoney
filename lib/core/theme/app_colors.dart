import 'package:flutter/material.dart';

/// Raw colour tokens for MoneyMan — a warm, metallic, editorial palette:
/// bone-white paper, graphite ink, liquid lime accent, champagne gold and a
/// sunset gradient reserved for the navigation pill.
class AppColors {
  AppColors._();

  // Brand
  static const Color accent = Color(0xFFC9F24C);
  static const Color accentPressed = Color(0xFFB4E02F);
  static const Color accentShift = Color(0xFF88E15A);
  static const Color accentLight = Color(0xFFF0FBD2);
  static const Color accentOnDark = Color(0xFFD8FF6E);

  // Metallics
  static const Color gold = Color(0xFFC9A96A);
  static const Color goldSoft = Color(0xFFF3E4C4);
  static const Color silver = Color(0xFFC7C9D1);
  static const Color chrome = Color(0xFFE9EAEE);
  static const Color graphite = Color(0xFF23242A);

  // Neutrals (light) — warm paper
  static const Color ink = Color(0xFF0C0C0E);
  static const Color sub = Color(0xFF55555C);
  static const Color tertiary = Color(0xFF8B8B92);
  static const Color divider = Color(0xFFE7E3DA);
  static const Color surface = Color(0xFFF4F2ED);
  static const Color surfaceAlt = Color(0xFFEBE8E1);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = Color(0xFFF7F5F0);

  // Neutrals (dark) — obsidian
  static const Color darkSurface = Color(0xFF08080A);
  static const Color darkSurfaceAlt = Color(0xFF0E0E11);
  static const Color darkCard = Color(0xFF131317);
  static const Color darkCardAlt = Color(0xFF1A1A1F);
  static const Color darkDivider = Color(0xFF26262D);
  static const Color darkSub = Color(0xFFA8A8B0);
  static const Color darkTertiary = Color(0xFF74747D);

  // Semantic
  static const Color income = Color(0xFF1FB573);
  static const Color expense = Color(0xFFE8483C);
  static const Color transfer = Color(0xFF4C7DF0);
  static const Color warning = Color(0xFFE0A03A);

  static const Color incomeBg = Color(0xFFE4F7ED);
  static const Color expenseBg = Color(0xFFFCEAE7);
  static const Color warningBg = Color(0xFFFBF1DF);
  static const Color infoBg = Color(0xFFE8EFFD);

  static const Color darkIncome = Color(0xFF3EDC93);
  static const Color darkExpense = Color(0xFFFF6F61);
  static const Color darkTransfer = Color(0xFF7FA2FF);
  static const Color darkWarning = Color(0xFFF5C066);

  // Signature gradient stops
  static const Color limeA = Color(0xFFD9FF63);
  static const Color limeB = Color(0xFF8EE04F);
  static const Color tangerine = Color(0xFFFF8A45);
  static const Color sunset = Color(0xFFFF3B30);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetSoft = Color(0xFFB79CFF);
  static const Color sky = Color(0xFF5AA9FF);
  static const Color cyan = Color(0xFF4FD6D0);
  static const Color pink = Color(0xFFF25CA2);

  // Gradients used by hero cards, charts and the navigation bar.
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFA14D), Color(0xFFFF6A3D), Color(0xFFFF2D55)],
  );

  static const LinearGradient limeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[limeA, limeB],
  );

  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[limeB, cyan, sky, violetSoft],
  );

  static const LinearGradient metalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFDFDFF), Color(0xFFD9DBE3), Color(0xFFA9ADB8), Color(0xFFF2F3F6)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF6E3B8), Color(0xFFC9A96A), Color(0xFF8A6E3D)],
  );

  static const LinearGradient graphiteGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF2B2C33), Color(0xFF141418), Color(0xFF08080A)],
  );

  /// Accent presets shown in Appearance settings.
  static const Map<String, Color> accentPresets = <String, Color>{
    'Lime': accent,
    'Gold': gold,
    'Violet': Color(0xFF8B5CF6),
    'Indigo': Color(0xFF5B67F1),
    'Ocean': Color(0xFF2E90FA),
    'Mint': Color(0xFF11B4A0),
    'Sunset': Color(0xFFFF5A3C),
    'Rose': Color(0xFFE4559C),
    'Graphite': Color(0xFF3A3A44),
  };

  /// Chart palette — lime, gold, violet, ocean, coral.
  static const List<Color> chartPalette = <Color>[
    Color(0xFFC9F24C),
    Color(0xFFC9A96A),
    Color(0xFF8B5CF6),
    Color(0xFF2E90FA),
    Color(0xFFFF6A3D),
    Color(0xFF11B4A0),
    Color(0xFFF25CA2),
    Color(0xFF8B8B98),
  ];

  static const List<Color> categoryPalette = <Color>[
    Color(0xFFC9F24C),
    Color(0xFFFF8A45),
    Color(0xFF8B5CF6),
    Color(0xFF2E90FA),
    Color(0xFF11B4A0),
    Color(0xFFF25CA2),
    Color(0xFFC9A96A),
    Color(0xFFE8483C),
    Color(0xFF4FD6D0),
    Color(0xFF8B8B98),
  ];

  static Color fromHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return Color(parsed ?? 0xFFC9F24C);
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

  /// Translucent surface used by the floating navigation capsule.
  final Color glass;
  final Color glassBorder;
  final Color violet;
  final Color gold;

  /// Dark metallic hero card gradient endpoints.
  final Color heroTop;
  final Color heroBottom;

  /// Readable foreground for accent-tinted surfaces.
  Color get onSoft => isDark ? accent : ink;

  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[accent, Color.lerp(accent, AppColors.accentShift, 0.65)!],
      );

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[heroTop, heroBottom],
      );

  LinearGradient get sunsetGradient => AppColors.sunsetGradient;

  LinearGradient get auroraGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[accent, AppColors.cyan, AppColors.sky, violet],
      );

  LinearGradient get metalGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF3A3B42), Color(0xFF1B1C21), Color(0xFF2E2F36)],
        )
      : AppColors.metalGradient;

  factory AppPalette.light(Color accent) {
    return AppPalette(
      isDark: false,
      accent: accent,
      accentPressed: _darken(accent, 0.10),
      accentSoft: _tint(accent, 0.92),
      onAccent: _isLight(accent) ? AppColors.ink : Colors.white,
      surface: AppColors.surface,
      surfaceAlt: AppColors.surfaceAlt,
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
      shadow: const Color(0x120C0C0E),
      navBar: const Color(0xFFFFFFFF),
      glass: const Color(0xF2FFFFFF),
      glassBorder: const Color(0x1A0C0C0E),
      violet: AppColors.violet,
      gold: AppColors.gold,
      heroTop: const Color(0xFF22232A),
      heroBottom: const Color(0xFF0B0B0E),
    );
  }

  factory AppPalette.dark(Color accent) {
    final bright = _isLight(accent) ? accent : _lighten(accent, 0.22);
    return AppPalette(
      isDark: true,
      accent: bright,
      accentPressed: _lighten(accent, 0.32),
      accentSoft: _tint(accent, 0.16),
      onAccent: _isLight(bright) ? AppColors.ink : Colors.white,
      surface: AppColors.darkSurface,
      surfaceAlt: AppColors.darkSurfaceAlt,
      card: AppColors.darkCard,
      cardAlt: AppColors.darkCardAlt,
      ink: const Color(0xFFF7F7F9),
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
      shadow: const Color(0x66000000),
      navBar: const Color(0xFF111115),
      glass: const Color(0xE617171C),
      glassBorder: const Color(0x14FFFFFF),
      violet: AppColors.violetSoft,
      gold: const Color(0xFFDCC28C),
      heroTop: const Color(0xFF1C1D23),
      heroBottom: const Color(0xFF060608),
    );
  }

  static bool _isLight(Color c) => c.computeLuminance() > 0.55;

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
        .withSaturation((hsl.saturation * 0.55).clamp(0.0, 1.0).toDouble())
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
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      accent: mix(accent, other.accent),
      accentPressed: mix(accentPressed, other.accentPressed),
      accentSoft: mix(accentSoft, other.accentSoft),
      onAccent: t < 0.5 ? onAccent : other.onAccent,
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
