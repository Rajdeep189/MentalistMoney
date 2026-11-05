import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/luxe.dart';
import '../../widgets/nav_bar.dart';
import '../achievements/achievements_screen.dart';
import '../accounts/accounts_screen.dart';
import '../bills/bills_screen.dart';
import '../budgets/budgets_screen.dart';
import '../common/lock_gate.dart';
import '../goals/goals_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../premium/premium_screen.dart';
import '../settings/settings_screen.dart';
import '../splits/splits_screen.dart';
import '../stats/stats_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transactions_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final List<Widget> _screens = const <Widget>[
    HomeScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    GoalsScreen(),
    StatsScreen(),
  ];

  static const List<LuxeNavItem> _items = <LuxeNavItem>[
    LuxeNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    LuxeNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Ledger'),
    LuxeNavItem(icon: Icons.pie_chart_outline_rounded, activeIcon: Icons.pie_chart_rounded, label: 'Budget'),
    LuxeNavItem(icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded, label: 'Goals'),
    LuxeNavItem(icon: Icons.insights_outlined, activeIcon: Icons.insights_rounded, label: 'Insights'),
  ];

  Future<void> _openAddTransaction() async {
    await showAddTransactionSheet(context, ref);
  }

  void _openQuickMenu() {
    final palette = context.c;
    final entries = <MapEntry<String, IconData>>[
      const MapEntry<String, IconData>('Accounts', Icons.account_balance_wallet_outlined),
      const MapEntry<String, IconData>('Bills & reminders', Icons.event_note_outlined),
      const MapEntry<String, IconData>('Split expenses', Icons.call_split_rounded),
      const MapEntry<String, IconData>('Notifications', Icons.notifications_none_rounded),
      const MapEntry<String, IconData>('Achievements', Icons.emoji_events_outlined),
      const MapEntry<String, IconData>('MoneyMan Pro', Icons.workspace_premium_outlined),
      const MapEntry<String, IconData>('Settings', Icons.tune_rounded),
    ];
    final routes = <Widget Function()>[
      () => const AccountsScreen(),
      () => const BillsScreen(),
      () => const SplitsScreen(),
      () => const NotificationsScreen(),
      () => const AchievementsScreen(),
      () => const PremiumScreen(),
      () => const SettingsScreen(),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: GlassPanel(
            radius: AppRadius.cardLarge,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            tint: palette.isDark
                ? palette.card.withOpacity(0.96)
                : Colors.white.withOpacity(0.94),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const MetallicMark(size: 34, animated: false),
                      const SizedBox(width: 10),
                      Text('Shortcuts', style: AppTextStyles.h3(palette.ink)),
                      const Spacer(),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: palette.tertiary),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  for (var i = 0; i < entries.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: palette.isDark
                              ? palette.cardAlt
                              : palette.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(entries[i].value,
                            size: 18, color: palette.ink),
                      ),
                      title: Text(entries[i].key,
                          style: AppTextStyles.label(palette.ink)
                              .copyWith(fontWeight: FontWeight.w500)),
                      trailing: Icon(Icons.arrow_outward_rounded,
                          size: 16, color: palette.tertiary),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => routes[i]()),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);
    final palette = context.c;

    final safeBottom = MediaQuery.of(context).padding.bottom;
    return LockGate(
      child: Scaffold(
        backgroundColor: palette.surface,
        extendBody: true,
        body: IndexedStack(index: index, children: _screens),
        floatingActionButton: index <= 3
            ? Padding(
                padding: const EdgeInsets.only(bottom: 92),
                child: SizedBox(
                  height: AppSpacing.fabSize,
                  width: AppSpacing.fabSize,
                  child: FloatingActionButton(
                    onPressed: _openAddTransaction,
                    elevation: 8,
                    backgroundColor: palette.ink,
                    shape: const CircleBorder(),
                    child: ShineSweep(
                      period: const Duration(milliseconds: 2600),
                      opacity: 0.35,
                      borderRadius: BorderRadius.circular(999),
                      child: Icon(Icons.add_rounded,
                          size: 30,
                          color: palette.isDark ? palette.accent : Colors.white),
                    ),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: LuxeNavBar(
          index: index,
          items: _items,
          onMenu: _openQuickMenu,
          bottomInset: safeBottom > 0 ? 8 : 14,
          onSelected: (value) {
            HapticFeedback.selectionClick();
            ref.read(navIndexProvider.notifier).state = value;
          },
        ),
      ),
    );
  }
}

/// Reusable app-bar action that hides / shows every amount in the app.
class PrivacyToggle extends ConsumerWidget {
  const PrivacyToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final hidden = ref.watch(amountsHiddenProvider);
    return IconButton(
      tooltip: hidden ? 'Show amounts' : 'Hide amounts',
      onPressed: () {
        ref.read(amountsHiddenProvider.notifier).state = !hidden;
      },
      icon: Icon(
        hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 20,
        color: palette.sub,
      ),
    );
  }
}

/// Small helper chip showing the current month.
class MonthChip extends StatelessWidget {
  const MonthChip({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.cardAlt : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.calendar_today_rounded, size: 11, color: palette.sub),
          const SizedBox(width: 5),
          Text(
            FmtMonth.label(),
            style: AppTextStyles.caption(palette.sub),
          ),
        ],
      ),
    );
  }
}

class FmtMonth {
  FmtMonth._();

  static String label() {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}
