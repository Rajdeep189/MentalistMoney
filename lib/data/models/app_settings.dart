import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Identifiers for the re-orderable dashboard cards.
class DashboardCard {
  DashboardCard._();

  static const String safeToSpend = 'safe_to_spend';
  static const String monthSummary = 'month_summary';
  static const String budgets = 'budgets';
  static const String recent = 'recent';
  static const String donut = 'donut';
  static const String bills = 'bills';
  static const String netWorth = 'net_worth';
  static const String quickActions = 'quick_actions';
  static const String insights = 'insights';

  static const List<String> all = <String>[
    safeToSpend,
    monthSummary,
    budgets,
    recent,
    donut,
    bills,
    netWorth,
    quickActions,
    insights,
  ];

  static String label(String id) {
    switch (id) {
      case safeToSpend:
        return 'Safe to Spend';
      case monthSummary:
        return 'Month summary';
      case budgets:
        return 'Budget progress';
      case recent:
        return 'Recent transactions';
      case donut:
        return 'Spending donut';
      case bills:
        return 'Upcoming bills';
      case netWorth:
        return 'Net worth';
      case quickActions:
        return 'Quick actions';
      case insights:
        return 'Smart insights';
      default:
        return id;
    }
  }
}

/// All persisted preferences keyed by their SQLite setting key.
class SettingsKeys {
  SettingsKeys._();

  static const String userName = 'user_name';
  static const String currencyCode = 'currency_code';
  static const String currencySymbol = 'currency_symbol';
  static const String themeMode = 'theme_mode';
  static const String accentColor = 'accent_color';
  static const String themePack = 'theme_pack';
  static const String fontScale = 'font_scale';
  static const String density = 'density';
  static const String showCategoryColors = 'show_category_colors';
  static const String showAccountColors = 'show_account_colors';
  static const String amountStyle = 'amount_style';
  static const String decimalDigits = 'decimal_digits';
  static const String symbolBefore = 'symbol_before';
  static const String firstDayOfWeek = 'first_day_of_week';
  static const String dateFormat = 'date_format';
  static const String startOfMonth = 'start_of_month';
  static const String defaultAccountId = 'default_account_id';
  static const String defaultCategoryId = 'default_category_id';
  static const String defaultTxnType = 'default_txn_type';
  static const String defaultPaymentMethod = 'default_payment_method';
  static const String language = 'language';
  static const String haptics = 'haptics';
  static const String sounds = 'sounds';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String budgetAlerts = 'budget_alerts';
  static const String billReminders = 'bill_reminders';
  static const String goalReminders = 'goal_reminders';
  static const String dailyReminder = 'daily_reminder';
  static const String weeklyReport = 'weekly_report';
  static const String reminderHour = 'reminder_hour';
  static const String reminderMinute = 'reminder_minute';
  static const String biometricLock = 'biometric_lock';
  static const String pinLock = 'pin_lock';
  static const String autoLockMinutes = 'auto_lock_minutes';
  static const String privacyHideDashboard = 'privacy_hide_dashboard';
  static const String privacyHideBalances = 'privacy_hide_balances';
  static const String blockScreenshots = 'block_screenshots';
  static const String onboardingDone = 'onboarding_done';
  static const String dashboardCards = 'dashboard_cards';
  static const String dashboardOrder = 'dashboard_order';
  static const String premium = 'premium';
  static const String demoData = 'demo_data_seeded';
  static const String autoBackupFrequency = 'auto_backup_frequency';
  static const String lastBackupAt = 'last_backup_at';
  static const String reportsOpened = 'reports_opened';
  static const String splitGroupsCreated = 'split_groups_created';
  static const String hideAmountsGlobal = 'hide_amounts_global';
}

class AppSettings {
  const AppSettings(this.raw);

  final Map<String, String> raw;

  static const AppSettings empty = AppSettings(<String, String>{});

  String str(String key, String fallback) {
    final value = raw[key];
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  bool flag(String key, {bool fallback = false}) {
    final value = raw[key];
    if (value == null) return fallback;
    return value == 'true' || value == '1';
  }

  int integer(String key, int fallback) {
    final value = raw[key];
    if (value == null) return fallback;
    return int.tryParse(value) ?? fallback;
  }

  double dbl(String key, double fallback) {
    final value = raw[key];
    if (value == null) return fallback;
    return double.tryParse(value) ?? fallback;
  }

  int? optionalInt(String key) {
    final value = raw[key];
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  // ------------------------------------------------------------------ typed

  String get userName => str(SettingsKeys.userName, 'there');

  String get currencyCode => str(SettingsKeys.currencyCode, 'INR');

  String get currencySymbol => str(SettingsKeys.currencySymbol, '₹');

  ThemeMode get themeMode {
    switch (str(SettingsKeys.themeMode, 'system')) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get themeModeName => str(SettingsKeys.themeMode, 'system');

  String get themePack => str(SettingsKeys.themePack, 'default');

  ThemePack get pack => ThemePack.byId(themePack);

  Color get accentColor => AppColors.fromHex(str(SettingsKeys.accentColor, '#916CFF'));

  double get fontScale => dbl(SettingsKeys.fontScale, 1.0);

  bool get compactDensity => str(SettingsKeys.density, 'comfortable') == 'compact';

  bool get showCategoryColors => flag(SettingsKeys.showCategoryColors, fallback: true);

  bool get showAccountColors => flag(SettingsKeys.showAccountColors, fallback: true);

  String get amountStyle => str(SettingsKeys.amountStyle, 'full');

  int get decimalDigits => integer(SettingsKeys.decimalDigits, 2);

  bool get symbolBefore => flag(SettingsKeys.symbolBefore, fallback: true);

  int get firstDayOfWeek => integer(SettingsKeys.firstDayOfWeek, 7);

  String get dateFormat => str(SettingsKeys.dateFormat, 'dd/MM/yyyy');

  int get startOfMonth => integer(SettingsKeys.startOfMonth, 1);

  int? get defaultAccountId => optionalInt(SettingsKeys.defaultAccountId);

  int? get defaultCategoryId => optionalInt(SettingsKeys.defaultCategoryId);

  String get defaultTxnType => str(SettingsKeys.defaultTxnType, 'expense');

  String get defaultPaymentMethod => str(SettingsKeys.defaultPaymentMethod, 'UPI');

  String get language => str(SettingsKeys.language, 'en');

  bool get haptics => flag(SettingsKeys.haptics, fallback: true);

  bool get sounds => flag(SettingsKeys.sounds, fallback: false);

  bool get notificationsEnabled =>
      flag(SettingsKeys.notificationsEnabled, fallback: true);

  bool get budgetAlerts => flag(SettingsKeys.budgetAlerts, fallback: true);

  bool get billReminders => flag(SettingsKeys.billReminders, fallback: true);

  bool get goalReminders => flag(SettingsKeys.goalReminders, fallback: true);

  bool get dailyReminder => flag(SettingsKeys.dailyReminder);

  bool get weeklyReport => flag(SettingsKeys.weeklyReport);

  int get reminderHour => integer(SettingsKeys.reminderHour, 20);

  int get reminderMinute => integer(SettingsKeys.reminderMinute, 0);

  bool get biometricLock => flag(SettingsKeys.biometricLock);

  String? get pinLock {
    final pin = raw[SettingsKeys.pinLock];
    return (pin == null || pin.isEmpty) ? null : pin;
  }

  int get autoLockMinutes => integer(SettingsKeys.autoLockMinutes, 1);

  bool get privacyHideDashboard => flag(SettingsKeys.privacyHideDashboard);

  bool get privacyHideBalances => flag(SettingsKeys.privacyHideBalances);

  bool get blockScreenshots => flag(SettingsKeys.blockScreenshots);

  bool get onboardingDone => flag(SettingsKeys.onboardingDone);

  bool get isPremium => flag(SettingsKeys.premium);

  bool get hideAmountsGlobal => flag(SettingsKeys.hideAmountsGlobal);

  String get autoBackupFrequency => str(SettingsKeys.autoBackupFrequency, 'manual');

  int? get lastBackupAt => optionalInt(SettingsKeys.lastBackupAt);

  int get reportsOpened => integer(SettingsKeys.reportsOpened, 0);

  bool get demoDataSeed => flag(SettingsKeys.demoData);

  List<String> get dashboardOrder {
    final rawOrder = raw[SettingsKeys.dashboardOrder];
    if (rawOrder == null || rawOrder.isEmpty) return DashboardCard.all;
    final ids = rawOrder.split(',').where((e) => e.isNotEmpty).toList();
    final valid = ids.where(DashboardCard.all.contains).toList();
    for (final id in DashboardCard.all) {
      if (!valid.contains(id)) valid.add(id);
    }
    return valid;
  }

  Set<String> get hiddenCards {
    final rawHidden = raw[SettingsKeys.dashboardCards];
    if (rawHidden == null || rawHidden.isEmpty) return <String>{};
    return rawHidden.split(',').where((e) => e.isNotEmpty).toSet();
  }

  List<String> get visibleCards => <String>[
        for (final id in dashboardOrder)
          if (!hiddenCards.contains(id)) id,
      ];

  String dashboardCardLabel(String id) => DashboardCard.label(id);
}
