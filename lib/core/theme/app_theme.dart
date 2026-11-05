import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Premium theme packs available to Premium users.
class ThemePack {
  const ThemePack({
    required this.id,
    required this.name,
    required this.accent,
    this.surfaceOverride,
    this.darkOverride,
    this.premium = false,
  });

  final String id;
  final String name;
  final Color accent;
  final Color? surfaceOverride;
  final Color? darkOverride;
  final bool premium;

  static const List<ThemePack> packs = <ThemePack>[
    ThemePack(id: 'default', name: 'MoneyMan', accent: AppColors.accent),
    ThemePack(id: 'mono', name: 'Chrome', accent: Color(0xFF3A3A44)),
    ThemePack(
      id: 'midnight',
      name: 'Obsidian',
      accent: Color(0xFF9C7BFF),
      darkOverride: Color(0xFF06060A),
      premium: true,
    ),
    ThemePack(
      id: 'ocean',
      name: 'Ocean',
      accent: Color(0xFF2E90FA),
      surfaceOverride: Color(0xFFF1F6FC),
      premium: true,
    ),
    ThemePack(
      id: 'forest',
      name: 'Emerald',
      accent: Color(0xFF12B76A),
      surfaceOverride: Color(0xFFF1FAF4),
      premium: true,
    ),
    ThemePack(
      id: 'sunset',
      name: 'Sunset',
      accent: Color(0xFFFF6A3D),
      surfaceOverride: Color(0xFFFDF3EE),
      premium: true,
    ),
    ThemePack(
      id: 'neon',
      name: 'Neon',
      accent: Color(0xFFF25CA2),
      premium: true,
    ),
  ];

  static ThemePack byId(String id) =>
      packs.firstWhere((p) => p.id == id, orElse: () => packs.first);
}

/// Central theme factory.
class AppTheme {
  AppTheme._();

  static ThemeData light({Color accent = AppColors.accent, ThemePack? pack}) {
    var palette = AppPalette.light(accent);
    if (pack?.surfaceOverride != null) {
      palette = palette.copyWith(surface: pack!.surfaceOverride);
    }
    return _build(palette, Brightness.light);
  }

  static ThemeData dark({Color accent = AppColors.accent, ThemePack? pack}) {
    var palette = AppPalette.dark(accent);
    if (pack?.darkOverride != null) {
      palette = palette.copyWith(
        surface: pack!.darkOverride,
        card: pack.darkOverride!.lighten(6),
        navBar: pack.darkOverride!.lighten(3),
      );
    }
    return _build(palette, Brightness.dark);
  }

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final textTheme = AppTextStyles.textTheme(p.ink, p.sub);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.surface,
      canvasColor: p.surface,
      fontFamily: AppTextStyles.family,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.accent,
        onPrimary: p.onAccent,
        primaryContainer: p.accentSoft,
        onPrimaryContainer: p.ink,
        secondary: p.ink,
        onSecondary: p.card,
        error: p.expense,
        onError: Colors.white,
        errorContainer: p.expenseBg,
        onErrorContainer: p.expense,
        surface: p.surface,
        onSurface: p.ink,
        surfaceContainerHighest: p.cardAlt,
        onSurfaceVariant: p.sub,
        outline: p.divider,
        outlineVariant: p.divider,
        shadow: p.shadow,
        inverseSurface: p.ink,
        onInverseSurface: p.surface,
        tertiary: p.transfer,
        onTertiary: Colors.white,
      ),
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      extensions: <ThemeExtension<dynamic>>[p],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        iconTheme: IconThemeData(color: p.ink, size: 22),
        titleTextStyle: AppTextStyles.h2(p.ink),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: p.divider,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? p.cardAlt : p.ink,
        contentTextStyle: AppTextStyles.body(p.isDark ? p.ink : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.x4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.isDark ? p.cardAlt : p.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x4,
        ),
        hintStyle: AppTextStyles.body(p.tertiary),
        labelStyle: AppTextStyles.body(p.sub),
        prefixIconColor: p.sub,
        suffixIconColor: p.sub,
        border: _fieldBorder(p.divider),
        enabledBorder: _fieldBorder(p.divider),
        focusedBorder: _fieldBorder(p.accent, width: 1.6),
        errorBorder: _fieldBorder(p.expense),
        focusedErrorBorder: _fieldBorder(p.expense, width: 1.6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.isDark ? p.cardAlt : p.card,
        selectedColor: p.accentSoft,
        side: BorderSide(color: p.divider),
        labelStyle: AppTextStyles.label(p.ink),
        secondaryLabelStyle: AppTextStyles.label(p.accent),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onAccent : p.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : p.divider,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.divider,
        thumbColor: p.accent,
        overlayColor: p.accentSoft,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.divider,
        circularTrackColor: p.divider,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.isDark ? p.cardAlt : p.ink,
        foregroundColor: p.isDark ? p.accent : Colors.white,
        elevation: 6,
        highlightElevation: 10,
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.navBar,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: AppSpacing.navBarHeight,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyles.label(
            states.contains(WidgetState.selected) ? p.accent : p.tertiary,
          ).copyWith(fontSize: 11),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected) ? p.accent : p.tertiary,
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.ink,
        headerForegroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.card,
        dialBackgroundColor: p.isDark ? p.cardAlt : p.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.sub,
        textColor: p.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.isDark ? p.cardAlt : p.ink,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: AppTextStyles.caption(Colors.white),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withOpacity(0.25),
        selectionHandleColor: p.accent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// System chrome styling that follows the palette.
  static SystemUiOverlayStyle overlayFor(AppPalette p) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: p.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: p.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: p.navBar,
      systemNavigationBarIconBrightness:
          p.isDark ? Brightness.light : Brightness.dark,
    );
  }
}

extension ColorShade on Color {
  Color lighten(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount / 100).clamp(0.0, 1.0).toDouble()).toColor();
  }

  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount / 100).clamp(0.0, 1.0).toDouble()).toColor();
  }

}
