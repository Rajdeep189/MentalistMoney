import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/premium_badge.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/settings_tiles.dart';
import '../achievements/achievements_screen.dart';
import '../premium/premium_screen.dart';
import '../settings/security_settings_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);
    final summary = ref.watch(monthSummaryProvider).valueOrNull ?? const PeriodSummary();
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final netWorth = ref.watch(netWorthProvider).valueOrNull ?? const <String, int>{};
    final goals = ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
    final achievements =
        ref.watch(achievementsProvider).valueOrNull ?? const <Achievement>[];
    final saved = ref.watch(totalSavedProvider).valueOrNull ?? 0;
    final unlocked = achievements.where((a) => a.unlocked).length;

    final initials = settings.userName.trim().isEmpty
        ? 'M'
        : settings.userName
            .trim()
            .split(' ')
            .take(2)
            .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
            .join();

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x2,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                Container(
                  height: 78,
                  width: 78,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[palette.accent, palette.accentPressed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTextStyles.h1(Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(settings.userName, style: context.h2),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(Icons.edit_rounded, size: 16, color: palette.tertiary),
                      onPressed: () => _editName(context, ref, settings),
                    ),
                  ],
                ),
                Text(
                  '${settings.currencyCode} · ${settings.language == 'hi' ? 'हिन्दी' : 'English'}',
                  style: context.caption,
                ),
                const SizedBox(height: 6),
                if (settings.isPremium)
                  const PremiumBadge(dense: true)
                else
                  Text('Free plan', style: context.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          AppCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _stat(context, 'Net worth',
                      Fmt.money(netWorth['net'] ?? 0, forceCompact: true)),
                ),
                _divider(context),
                Expanded(
                  child: _stat(context, 'Saved this month',
                      Fmt.money(summary.net, forceCompact: true)),
                ),
                _divider(context),
                Expanded(
                  child: _stat(context, 'Accounts', '${accounts.length}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          AppCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text('Goal progress', style: context.bodyL)),
                    Text('${goals.length} goals', style: context.caption),
                  ],
                ),
                const SizedBox(height: 10),
                ProgressBar(
                  value: goals.isEmpty
                      ? 0
                      : goals.fold<double>(0, (sum, goal) => sum + goal.progress) /
                          goals.length,
                  height: 10,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text('Total saved ${Fmt.money(saved, forceCompact: true)}',
                        style: context.caption),
                    const Spacer(),
                    Text('$unlocked badges unlocked', style: context.caption),
                  ],
                ),
              ],
            ),
          ),
          const SettingsSectionTitle('Your money'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Account settings',
                subtitle: 'Currency, language and defaults',
                icon: Icons.tune_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                ),
              ),
              SettingsTile(
                title: 'Achievements',
                subtitle: '$unlocked of ${achievements.length} unlocked',
                icon: Icons.emoji_events_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
                ),
              ),
              SettingsTile(
                title: settings.isPremium ? 'Premium is active' : 'Go Premium',
                subtitle: settings.isPremium
                    ? 'Thank you for the support'
                    : 'Unlimited budgets, goals and splits',
                icon: Icons.workspace_premium_outlined,
                premium: !settings.isPremium,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
                ),
              ),
            ],
          ),
          const SettingsSectionTitle('Privacy'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Security & lock',
                subtitle: settings.biometricLock ? 'Biometric lock on' : 'No app lock',
                icon: Icons.shield_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SecuritySettingsScreen(),
                  ),
                ),
              ),
              SettingsTile(
                title: 'Hide amounts everywhere',
                icon: Icons.visibility_off_outlined,
                trailing: Switch(
                  value: settings.hideAmountsGlobal,
                  activeColor: palette.accent,
                  onChanged: (value) => ref
                      .read(settingsRepositoryProvider)
                      .setBool(SettingsKeys.hideAmountsGlobal, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          SecondaryButton(
            label: 'Back to settings',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(
        height: 34,
        width: 1,
        color: context.c.divider,
      );

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      children: <Widget>[
        Text(label, style: context.caption, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.money(14, color: context.c.ink, weight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final controller = TextEditingController(text: settings.userName);
    final name = await showAppSheet<String>(
      context,
      (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SheetHeader(title: 'Your name'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
              child: Column(
                children: <Widget>[
                  AppTextField(
                    controller: controller,
                    label: 'Name',
                    hint: 'What should we call you?',
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  PrimaryButton(
                    label: 'Save',
                    onPressed: () => Navigator.of(sheetContext).pop(
                      controller.text.trim().isEmpty ? 'there' : controller.text.trim(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (name == null) return;
    await ref.read(settingsRepositoryProvider).set(SettingsKeys.userName, name);
    if (context.mounted) showSnack(context, 'Profile updated');
  }
}
