import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../core/l10n/l10n.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/luxe.dart';
import '../../widgets/luxe_account_card.dart';
import '../../widgets/shimmer.dart';
import '../accounts/accounts_screen.dart';
import '../accounts/transfer_screen.dart';
import '../bills/bill_form_screen.dart';
import '../bills/bills_screen.dart';
import '../budgets/budget_detail_screen.dart';
import '../categories/categories_screen.dart';
import '../io/data_backup_screen.dart';
import '../notifications/notifications_screen.dart';
import '../premium/premium_screen.dart';
import '../profile/profile_screen.dart';
import '../achievements/achievements_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/search_screen.dart';
import '../transactions/transaction_detail_screen.dart';
import 'home_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);
    final safe = ref.watch(safeToSpendProvider);
    final summary = ref.watch(monthSummaryProvider);
    final lastSummary = ref.watch(lastMonthSummaryProvider);
    final budgets = ref.watch(budgetsProvider);
    final recent = ref.watch(recentTransactionsProvider);
    final categoryTotals = ref.watch(monthCategoryTotalsProvider);
    final bills = ref.watch(upcomingBillsProvider);
    final netWorth = ref.watch(netWorthProvider);
    final insights = ref.watch(insightsProvider);
    final accounts = ref.watch(accountLookupProvider);
    final categories = ref.watch(categoryLookupProvider);

    final cards = <String>[
      for (final id in settings.visibleCards)
        if (id != DashboardCard.quickActions) id,
    ];

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: () async {
            ref.invalidate(settingsProvider);
            ref.invalidate(safeToSpendProvider);
            ref.invalidate(monthSummaryProvider);
            ref.invalidate(recentTransactionsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 350));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              _HomeHeader(settings: settings),
              const SizedBox(height: AppSpacing.x5),
              const _AccountsCarousel(),
              const SizedBox(height: AppSpacing.x5),

              // Visible cards, in the user's order.
              for (final id in cards) ...<Widget>[
                if (id == DashboardCard.safeToSpend)
                  safe.when(
                    loading: () => const ShimmerBox(height: 150, radius: AppRadius.cardLarge),
                    error: (e, _) => _ErrorCard(message: '$e'),
                    data: (value) => SafeToSpendCard(
                      safe: value,
                      hidden: settings.privacyHideDashboard,
                      onTap: () => _openBudgets(context, ref),
                    ),
                  ),
                if (id == DashboardCard.monthSummary)
                  summary.when(
                    loading: () => const ShimmerBox(height: 120),
                    error: (e, _) => _ErrorCard(message: '$e'),
                    data: (value) => MonthSummaryCard(
                      summary: value,
                      previous: lastSummary.valueOrNull ?? const PeriodSummary(),
                      onTap: () => ref.read(navIndexProvider.notifier).state = 4,
                    ),
                  ),
                if (id == DashboardCard.budgets)
                  budgets.when(
                    loading: () => const ShimmerBox(height: 120),
                    error: (e, _) => _ErrorCard(message: '$e'),
                    data: (value) => BudgetMiniCard(
                      budgets: value,
                      onTapBudget: (progress) => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BudgetDetailScreen(budgetId: progress.budget.id!),
                        ),
                      ),
                      onSeeAll: () => ref.read(navIndexProvider.notifier).state = 2,
                    ),
                  ),
                if (id == DashboardCard.recent)
                  recent.when(
                    loading: () => const ShimmerBox(height: 140),
                    error: (e, _) => _ErrorCard(message: '$e'),
                    data: (value) => RecentTransactionsCard(
                      transactions: value,
                      accounts: accounts.valueOrNull ?? const <int, Account>{},
                      categories: categories.valueOrNull ?? const <int, Category>{},
                      onTapTransaction: (txn) => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TransactionDetailScreen(transactionId: txn.id!),
                        ),
                      ),
                      onSeeAll: () {
                        ref.read(navIndexProvider.notifier).state = 1;
                      },
                    ),
                  ),
                if (id == DashboardCard.donut)
                  categoryTotals.when(
                    loading: () => const ShimmerBox(height: 160),
                    error: (e, _) => _ErrorCard(message: '$e'),
                    data: (value) => SpendingDonutCard(
                      totals: value,
                      onTapCategory: (total) {
                        ref.read(navIndexProvider.notifier).state = 4;
                      },
                      onSeeAll: () => ref.read(navIndexProvider.notifier).state = 4,
                    ),
                  ),
                if (id == DashboardCard.bills)
                  bills.when(
                    loading: () => const ShimmerBox(height: 110),
                    error: (e, _) => _ErrorCard(message: '$e'),
                    data: (value) => UpcomingBillsCard(
                      bills: value,
                      onMarkPaid: (bill) => _markBillPaid(context, ref, bill),
                      onSeeAll: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const BillsScreen()),
                      ),
                    ),
                  ),
                if (id == DashboardCard.netWorth)
                  netWorth.when(
                    loading: () => const ShimmerBox(height: 120),
                    error: (e, _) => _ErrorCard(message: '$e'),
                    data: (value) => NetWorthCard(
                      assets: value['assets'] ?? 0,
                      liabilities: value['liabilities'] ?? 0,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const AccountsScreen()),
                      ),
                    ),
                  ),
                if (id == DashboardCard.insights)
                  insights.when(
                    loading: () => const ShimmerBox(height: 100),
                    error: (e, _) => _ErrorCard(message: '$e'),
                    data: (value) => InsightsCard(insights: value),
                  ),
                const SizedBox(height: AppSpacing.cardGap),
              ],

              if (settings.visibleCards.contains(DashboardCard.quickActions))
                QuickActionsCard(
                  onExpense: () => showAddTransactionSheet(
                    context,
                    ref,
                    initialType: kTypeExpense,
                  ),
                  onIncome: () => showAddTransactionSheet(
                    context,
                    ref,
                    initialType: kTypeIncome,
                  ),
                  onTransfer: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TransferScreen()),
                  ),
                  onBill: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const BillFormScreen()),
                  ),
                  onStats: () => ref.read(navIndexProvider.notifier).state = 4,
                ),
              const SizedBox(height: AppSpacing.x5),
              Center(
                child: Column(
                  children: <Widget>[
                    const MetallicMark(size: 34, animated: false),
                    const SizedBox(height: 8),
                    Text(
                      'MoneyMan',
                      style: AppTextStyles.wordmark(palette.tertiary, size: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.lock_outline_rounded,
                            size: 11, color: palette.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Offline-first · your data never leaves this device',
                          style: AppTextStyles.caption(palette.tertiary)
                              .copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBudgets(BuildContext context, WidgetRef ref) {
    ref.read(navIndexProvider.notifier).state = 2;
  }

  Future<void> _markBillPaid(BuildContext context, WidgetRef ref, Bill bill) async {
    final confirmed = await confirmAction(
      context,
      title: 'Mark "${bill.name}" as paid?',
      message: bill.autoCreateTxn
          ? 'An expense of ${Fmt.money(bill.amount)} will be added to your ledger.'
          : 'No transaction will be created.',
      confirmLabel: 'Mark paid',
      destructive: false,
    );
    if (!confirmed) return;
    await ref.read(billRepositoryProvider).markPaid(bill, paidOn: DateTime.now());
    if (context.mounted) showSnack(context, '${bill.name} marked as paid');
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final name = settings.userName;
    final initial = name.trim().isEmpty ? 'M' : name.trim()[0].toUpperCase();
    final display = name.trim().isEmpty || name == 'there' ? 'Welcome back' : name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LuxeWordmark(
          subtitle: 'Track every Money. Own your money.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleIconButton(
                icon: Icons.search_rounded,
                tooltip: 'Search',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
                ),
              ),
              const SizedBox(width: 6),
              CircleIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Reminders',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Eyebrow('${tr(context, DateX.greeting())} · ${_monthLabel()}'),
                  const SizedBox(height: 6),
                  ShineSweep(
                    period: const Duration(milliseconds: 6000),
                    opacity: 0.35,
                    child: Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displayL(palette.ink),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here is how your money is moving.',
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showMainMenu(context, ref),
              child: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.metalGradient,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: AppTextStyles.serif(
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showMainMenu(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context,
      (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SheetHeader(
              title: 'MoneyMan',
              subtitle: 'Track every Money. Own your money.',
            ),
            _menuTile(sheetContext, Icons.person_outline_rounded, 'Profile',
                () => const ProfileScreen()),
            _menuTile(sheetContext, Icons.emoji_events_outlined, 'Achievements',
                () => const AchievementsScreen()),
            _menuTile(sheetContext, Icons.workspace_premium_outlined, 'Premium',
                () => const PremiumScreen()),
            _menuTile(sheetContext, Icons.settings_outlined, 'Settings',
                () => const SettingsScreen()),
            _menuTile(sheetContext, Icons.shield_outlined, 'Privacy & Security',
                () => const SettingsScreen(initialSection: 'security')),
            Divider(color: context.c.divider, height: 20),
            _menuTile(sheetContext, Icons.account_balance_wallet_outlined, 'Accounts',
                () => const AccountsScreen()),
            _menuTile(sheetContext, Icons.receipt_long_outlined, 'Bills & reminders',
                () => const BillsScreen()),
            _menuTile(sheetContext, Icons.category_outlined, 'Categories',
                () => const CategoriesScreen()),
            _menuTile(sheetContext, Icons.cloud_upload_outlined, 'Backup & export',
                () => const DataBackupScreen()),
            const SizedBox(height: AppSpacing.x4),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String label, Widget Function() builder) {
    final palette = context.c;
    return ListTile(
      leading: Icon(icon, color: palette.accent, size: 21),
      title: Text(label, style: AppTextStyles.body(palette.ink)),
      trailing: Icon(Icons.chevron_right_rounded, color: palette.tertiary, size: 20),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => builder()));
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: context.c.expenseBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(message, style: AppTextStyles.caption(context.c.expense)),
    );
  }
}


/// Horizontally paged wallet of account cards.
class _AccountsCarousel extends ConsumerWidget {
  const _AccountsCarousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final accountsAsync = ref.watch(allAccountsProvider);
    return accountsAsync.when(
      loading: () => const SizedBox(height: 212),
      error: (error, _) => const SizedBox(height: 212),
      data: (accounts) {
        final active = accounts.where((a) => !a.archived).toList();
        if (active.isEmpty) {
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AccountsScreen()),
            ),
            child: Container(
              height: 168,
              padding: const EdgeInsets.all(AppSpacing.x5),
              decoration: BoxDecoration(
                gradient: AppColors.graphiteGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Eyebrow('Your wallet', color: Color(0xFF9C9CA6)),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first account',
                          style: AppTextStyles.h3(Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cash, bank, cards and wallets — all in one place.',
                          style: AppTextStyles.caption(const Color(0xFF9C9CA6)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 46,
                    width: 46,
                    decoration: const BoxDecoration(
                      gradient: AppColors.limeGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 24, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 224,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.94),
            padEnds: false,
            physics: const BouncingScrollPhysics(),
            itemCount: active.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: LuxeAccountCard(
                  account: active[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const AccountsScreen()),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


String _monthLabel() {
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final now = DateTime.now();
  return '${months[now.month - 1]} ${now.year}';
}
