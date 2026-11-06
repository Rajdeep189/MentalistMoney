import '../../core/theme/app_colors.dart';

class SeedCategory {
  const SeedCategory({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isFavorite = false,
  });

  final String name;
  final String type;
  final String icon;
  final String color;
  final bool isFavorite;
}

/// Default categories created on first launch.
const List<SeedCategory> kSeedCategories = <SeedCategory>[
  SeedCategory(name: 'Food & Drinks', type: 'expense', icon: 'restaurant', color: '#F79009', isFavorite: true),
  SeedCategory(name: 'Groceries', type: 'expense', icon: 'shopping_basket', color: '#12B76A', isFavorite: true),
  SeedCategory(name: 'Transport', type: 'expense', icon: 'directions_car', color: '#2E90FA', isFavorite: true),
  SeedCategory(name: 'Shopping', type: 'expense', icon: 'shopping_bag', color: '#E4559C', isFavorite: true),
  SeedCategory(name: 'Bills & Utilities', type: 'expense', icon: 'receipt_long', color: '#916CFF'),
  SeedCategory(name: 'Rent', type: 'expense', icon: 'home', color: '#5B67F1'),
  SeedCategory(name: 'Health', type: 'expense', icon: 'medical_services', color: '#11B4A0'),
  SeedCategory(name: 'Education', type: 'expense', icon: 'school', color: '#0EA5E9'),
  SeedCategory(name: 'Entertainment', type: 'expense', icon: 'movie', color: '#F04438'),
  SeedCategory(name: 'Travel', type: 'expense', icon: 'flight', color: '#7C3AED'),
  SeedCategory(name: 'Personal Care', type: 'expense', icon: 'spa', color: '#B08968'),
  SeedCategory(name: 'Gifts', type: 'expense', icon: 'card_giftcard', color: '#E4559C'),
  SeedCategory(name: 'Subscriptions', type: 'expense', icon: 'subscriptions', color: '#8B8B98'),
  SeedCategory(name: 'Home', type: 'expense', icon: 'house', color: '#64748B'),
  SeedCategory(name: 'Pets', type: 'expense', icon: 'pets', color: '#B08968'),
  SeedCategory(name: 'Savings', type: 'expense', icon: 'savings', color: '#12B76A'),
  SeedCategory(name: 'Salary', type: 'income', icon: 'work', color: '#12B76A', isFavorite: true),
  SeedCategory(name: 'Freelance', type: 'income', icon: 'business_center', color: '#2E90FA'),
  SeedCategory(name: 'Business', type: 'income', icon: 'business_center', color: '#5B67F1'),
  SeedCategory(name: 'Investment', type: 'income', icon: 'trending_up', color: '#11B4A0'),
  SeedCategory(name: 'Gift', type: 'income', icon: 'redeem', color: '#E4559C'),
  SeedCategory(name: 'Refund', type: 'income', icon: 'undo', color: '#F79009'),
  SeedCategory(name: 'Other Income', type: 'income', icon: 'attach_money', color: '#8B8B98'),
];

class SeedAchievement {
  const SeedAchievement({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.target,
  });

  final String key;
  final String name;
  final String description;
  final String icon;
  final int target;
}

const List<SeedAchievement> kSeedAchievements = <SeedAchievement>[
  SeedAchievement(key: 'first_transaction', name: 'First Transaction', description: 'Log your very first transaction.', icon: 'emoji_events', target: 1),
  SeedAchievement(key: 'streak_7', name: '7-Day Streak', description: 'Log a transaction 7 days in a row.', icon: 'local_fire_department', target: 7),
  SeedAchievement(key: 'streak_30', name: '30-Day Streak', description: 'Log a transaction 30 days in a row.', icon: 'local_fire_department', target: 30),
  SeedAchievement(key: 'txn_100', name: '100 Transactions', description: 'Log 100 transactions.', icon: 'stars', target: 100),
  SeedAchievement(key: 'first_budget', name: 'First Budget', description: 'Create your first budget.', icon: 'percent', target: 1),
  SeedAchievement(key: 'first_goal', name: 'Goal Getter', description: 'Complete your first savings goal.', icon: 'verified', target: 1),
  SeedAchievement(key: 'saved_10k', name: 'Saved ₹10,000', description: 'Put ₹10,000 aside in goals.', icon: 'savings', target: 1000000),
  SeedAchievement(key: 'under_budget', name: 'Stayed Under Budget', description: 'Finish a month within budget.', icon: 'workspace_premium', target: 1),
  SeedAchievement(key: 'three_months', name: '3 Months Disciplined', description: 'Stay under budget three months in a row.', icon: 'calendar_month', target: 3),
  SeedAchievement(key: 'reports_10', name: 'Data Explorer', description: 'Open reports 10 times.', icon: 'insights', target: 10),
  SeedAchievement(key: 'premium_explorer', name: 'Premium Explorer', description: 'Try a premium feature.', icon: 'workspace_premium', target: 1),
];

/// Default settings written on first launch.
Map<String, String> defaultSettings() => <String, String>{
      'user_name': 'there',
      'currency_code': 'INR',
      'currency_symbol': '₹',
      'theme_mode': 'system',
      'accent_color': AppColors.toHex(AppColors.accent),
      'theme_pack': 'default',
      'font_scale': '1.0',
      'density': 'comfortable',
      'show_category_colors': 'true',
      'show_account_colors': 'true',
      'amount_style': 'full',
      'decimal_digits': '2',
      'symbol_before': 'true',
      'first_day_of_week': '7',
      'date_format': 'dd/MM/yyyy',
      'start_of_month': '1',
      'default_txn_type': 'expense',
      'default_payment_method': 'UPI',
      'language': 'en',
      'haptics': 'true',
      'sounds': 'false',
      'notifications_enabled': 'true',
      'budget_alerts': 'true',
      'bill_reminders': 'true',
      'goal_reminders': 'true',
      'daily_reminder': 'false',
      'weekly_report': 'false',
      'reminder_hour': '20',
      'reminder_minute': '0',
      'biometric_lock': 'false',
      'auto_lock_minutes': '1',
      'privacy_hide_dashboard': 'false',
      'privacy_hide_balances': 'false',
      'block_screenshots': 'false',
      'onboarding_done': 'false',
      'premium': 'false',
      'auto_backup_frequency': 'manual',
      'reports_opened': '0',
    };
