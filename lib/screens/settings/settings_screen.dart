import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/luxe.dart';
import '../../widgets/settings_tiles.dart';
import '../accounts/accounts_screen.dart';
import '../achievements/achievements_screen.dart';
import '../bills/bills_screen.dart';
import '../categories/categories_screen.dart';
import '../io/data_backup_screen.dart';
import '../premium/premium_screen.dart';
import '../profile/profile_screen.dart';
import '../splits/splits_screen.dart';
import '../transactions/recurring_screen.dart';
import 'about_screen.dart';
import 'appearance_settings_screen.dart';
import 'general_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'security_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.initialSection});

  final String? initialSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);
    final premium = settings.isPremium;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            const MetallicMark(size: 30, animated: false),
            const SizedBox(width: 10),
            Text('Settings', style: AppTextStyles.h2(palette.ink)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          if (initialSection != null) _InitialSectionOpener(section: initialSection!),
          const SizedBox(height: AppSpacing.x2),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: settings.userName == 'there' ? 'Your profile' : settings.userName,
                subtitle: '${settings.currencyCode} · ${premium ? 'Premium' : 'Free'} plan',
                icon: Icons.person_outline_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                ),
              ),
              SettingsTile(
                title: 'Upgrade to Premium',
                subtitle: premium ? 'You have all features unlocked' : 'Unlimited budgets, goals and analytics',
                icon: Icons.workspace_premium_outlined,
                premium: !premium,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
                ),
              ),
            ],
          ),
          const SettingsSectionTitle('Personalise'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Appearance',
                subtitle: 'Theme, accent, font size, dashboard',
                icon: Icons.palette_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AppearanceSettingsScreen()),
                ),
              ),
              SettingsTile(
                title: 'General',
                subtitle: 'Currency, language, formats, defaults',
                icon: Icons.tune_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const GeneralSettingsScreen()),
                ),
              ),
            ],
          ),
          const SettingsSectionTitle('Money'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Accounts',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AccountsScreen()),
                ),
              ),
              SettingsTile(
                title: 'Categories',
                icon: Icons.category_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
                ),
              ),
              SettingsTile(
                title: 'Bills & reminders',
                icon: Icons.receipt_long_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const BillsScreen()),
                ),
              ),
              SettingsTile(
                title: 'Recurring transactions',
                icon: Icons.autorenew_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const RecurringScreen()),
                ),
              ),
              SettingsTile(
                title: 'Bill splitting',
                subtitle: 'Share expenses with friends',
                icon: Icons.groups_outlined,
                premium: !premium,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SplitsScreen()),
                ),
              ),
            ],
          ),
          const SettingsSectionTitle('Alerts'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Notifications',
                subtitle: settings.notificationsEnabled ? 'Enabled' : 'Disabled',
                icon: Icons.notifications_none_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NotificationsSettingsScreen()),
                ),
              ),
            ],
          ),
          const SettingsSectionTitle('Security & data'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Privacy & security',
                subtitle: settings.biometricLock
                    ? 'Biometric lock on'
                    : settings.pinLock != null
                        ? 'PIN lock on'
                        : 'App is unlocked',
                icon: Icons.shield_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SecuritySettingsScreen()),
                ),
              ),
              SettingsTile(
                title: 'Data & backup',
                subtitle: 'Export, import, backup and restore',
                icon: Icons.cloud_upload_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DataBackupScreen()),
                ),
              ),
              SettingsTile(
                title: 'Achievements',
                subtitle: 'Your money milestones',
                icon: Icons.emoji_events_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
                ),
              ),
            ],
          ),
          const SettingsSectionTitle('About'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'About MoneyMan',
                icon: Icons.info_outline_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          Center(
            child: Text(
              'MoneyMan · Track every Money. Own your money.',
              style: AppTextStyles.caption(palette.tertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          const MadeBySuperman(),
          const SizedBox(height: AppSpacing.x4),
          Center(
            child: Text(
              'Version 1.0.0 · Built for India',
              style: AppTextStyles.caption(palette.tertiary)
                  .copyWith(fontSize: 10, letterSpacing: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
      ),
    );
  }
}

/// Small helper so other screens can flip a boolean setting quickly.
Future<void> toggleSetting(WidgetRef ref, String key, bool value) async {
  await ref.read(settingsRepositoryProvider).setBool(key, value);
}

/// Convenience for showing the reset-data confirmation.
Future<bool> confirmReset(BuildContext context) {
  return confirmAction(
    context,
    title: 'Delete all data?',
    message:
        'Every transaction, account, budget and goal will be erased from this device. Export a backup first if you might need it.',
  );
}

/// Keeps the settings key list discoverable for feature screens.
class SettingsShortcuts {
  SettingsShortcuts._();

  static const String premium = SettingsKeys.premium;
  static const String language = SettingsKeys.language;
}

/// Opens a settings sub-page on first build when the caller asked for a
/// specific section (for example the lock icon in the home app bar).
class _InitialSectionOpener extends StatefulWidget {
  const _InitialSectionOpener({required this.section});

  final String section;

  @override
  State<_InitialSectionOpener> createState() => _InitialSectionOpenerState();
}

class _InitialSectionOpenerState extends State<_InitialSectionOpener> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _opened) return;
      _opened = true;
      final WidgetBuilder? builder = switch (widget.section) {
        'security' => (_) => const SecuritySettingsScreen(),
        'notifications' => (_) => const NotificationsSettingsScreen(),
        'appearance' => (_) => const AppearanceSettingsScreen(),
        'general' => (_) => const GeneralSettingsScreen(),
        'data' => (_) => const DataBackupScreen(),
        'premium' => (_) => const PremiumScreen(),
        'profile' => (_) => const ProfileScreen(),
        'achievements' => (_) => const AchievementsScreen(),
        _ => null,
      };
      if (builder == null) return;
      Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
