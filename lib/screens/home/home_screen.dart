import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import '../achievements/achievements_screen.dart';
import '../accounts/accounts_screen.dart';
import '../accounts/assets_screen.dart';
import '../accounts/loans_screen.dart';
import '../budgets/budgets_screen.dart';
import '../categories/categories_screen.dart';
import '../goals/goals_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../splits/splits_screen.dart';
import '../stats/reports_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/recurring_screen.dart';
import '../transactions/transactions_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);
    final netWorth = ref.watch(netWorthProvider).valueOrNull ??
        const <String, int>{'assets': 0, 'liabilities': 0};
    final summary = ref.watch(monthSummaryProvider).valueOrNull ??
        const PeriodSummary();
    final previous = ref.watch(lastMonthSummaryProvider).valueOrNull ??
        const PeriodSummary();
    final accounts = ref.watch(allAccountsProvider).valueOrNull ??
        const <Account>[];
    final budgets = ref.watch(budgetsProvider).valueOrNull ??
        const <BudgetProgress>[];
    final goals = ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
    final recurring = ref.watch(recurringRulesProvider).valueOrNull ??
        const <RecurringRule>[];
    final achievements = ref.watch(achievementsProvider).valueOrNull ??
        const <Achievement>[];
    final groups = ref.watch(splitGroupsProvider).valueOrNull ??
        const <SplitGroup>[];
    final bills = ref.watch(billsProvider).valueOrNull ?? const <Bill>[];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ??
        const <Category>[];
    final categoryTotals = ref.watch(monthCategoryTotalsProvider).valueOrNull ??
        const <CategoryTotal>[];
    final daily = ref.watch(monthDailyTotalsProvider).valueOrNull ??
        const <DayTotal>[];
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const <String>[];
    final recent =
        ref.watch(recentTransactionsProvider).valueOrNull ?? const <Txn>[];
    final accountLookup =
        ref.watch(accountLookupProvider).valueOrNull ?? const <int, Account>{};
    final categoryLookup =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};
    final hidden = ref.watch(amountsHiddenProvider);

    final assets = netWorth['assets'] ?? 0;
    final liabilities = netWorth['liabilities'] ?? 0;
    final balance = assets - liabilities;

    final incomeDelta = previous.income == 0
        ? 0.0
        : (summary.income - previous.income) / previous.income * 100;
    final expenseDelta = previous.expense == 0
        ? 0.0
        : (summary.expense - previous.expense) / previous.expense * 100;

    final totalBudget = budgets.fold<int>(0, (a, b) => a + b.amount);
    final spentBudget = budgets.fold<int>(0, (a, b) => a + b.spent);
    final budgetPct = totalBudget == 0 ? 0.0 : spentBudget / totalBudget;

    final activeGoals = goals.where((g) => !g.isCompleted).length;
    final doneGoals = goals.where((g) => g.isCompleted).length;
    final goalTarget = goals.fold<int>(0, (a, g) => a + g.targetAmount);
    final goalSaved = goals.fold<int>(0, (a, g) => a + g.savedAmount);

    final activeRecurring = recurring.where((r) => r.active).length;
    final monthlyRecurring = recurring
        .where((r) => r.active && r.type == kTypeExpense)
        .fold<int>(0, (a, r) => a + r.amount);

    final unlocked = achievements.where((a) => a.unlocked).length;
    final lending = accounts
        .where((a) => a.type == kAccountInvestment || a.type == kAccountLoan)
        .length;
    final loans = accounts.where((a) => a.isLiability).length;
    final topCats = categoryTotals.take(3).toList();
    final weekDays = _lastSeven(daily);
    final monthSpend = summary.expense;

    final name = settings.userName.trim().isEmpty ? 'there' : settings.userName;

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            8,
            AppSpacing.screen,
            130,
          ),
          children: <Widget>[
            _Header(
              name: name,
              notifications: bills.where((b) => b.isOverdue).length,
              onBell: () => _push(context, const NotificationsScreen()),
              onSettings: () => _push(context, const SettingsScreen()),
            ),
            const SizedBox(height: 16),
            _BalanceHero(
              balance: balance,
              income: summary.income,
              expense: summary.expense,
              incomeDelta: incomeDelta,
              expenseDelta: expenseDelta,
              hidden: hidden,
              onToggle: () => ref
                  .read(amountsHiddenProvider.notifier)
                  .state = !hidden,
            ),
            const SizedBox(height: 22),
            Text(
              'Overview',
              style: AppTextStyles.base(
                size: 20,
                weight: FontWeight.w600,
                height: 1.15,
              ).copyWith(color: palette.ink),
            ),
            const SizedBox(height: 12),
            _TileRow(
              children: <Widget>[
                OverviewTile(
                  title: 'Accounts',
                  icon: Icons.account_balance_outlined,
                  minHeight: 168,
                  onTap: () => _push(context, const AccountsScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _TileValue('${accounts.length} accounts'),
                      const SizedBox(height: 4),
                      Text(
                        hidden ? '••••' : Fmt.money(assets, forceCompact: true),
                        style: AppTextStyles.base(
                          size: 24,
                          weight: FontWeight.w700,
                          height: 1.1,
                        ).copyWith(color: palette.accent),
                      ),
                    ],
                  ),
                ),
                OverviewTile(
                  title: 'Reports',
                  icon: Icons.insights_rounded,
                  minHeight: 168,
                  onTap: () => _openTab(ref, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _TileValue('${summary.count} transactions'),
                      const SizedBox(height: 4),
                      Text(
                        hidden ? '••••' : Fmt.money(monthSpend, forceCompact: true),
                        style: AppTextStyles.base(
                          size: 24,
                          weight: FontWeight.w700,
                          height: 1.1,
                        ).copyWith(color: palette.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TileRow(
              children: <Widget>[
                OverviewTile(
                  title: 'Budgets',
                  icon: Icons.pie_chart_outline_rounded,
                  minHeight: 178,
                  onTap: () => _push(context, const BudgetsScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CountValue('${budgets.length}', 'Budgets'),
                      const SizedBox(height: 10),
                      _ProgressLine(value: budgetPct),
                      const SizedBox(height: 8),
                      _TileValue(
                        '${(budgetPct * 100).round()}% of total budget spent',
                      ),
                      const SizedBox(height: 2),
                      _TileValue(
                        Fmt.money(spentBudget, forceCompact: true),
                        size: 12,
                      ),
                    ],
                  ),
                ),
                OverviewTile(
                  title: 'Loans',
                  icon: Icons.account_balance_wallet_outlined,
                  minHeight: 178,
                  onTap: () => _push(context, const LoansScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CountValue('$lending', 'Lending'),
                      _CountValue('$loans', 'Borrowing'),
                      const SizedBox(height: 6),
                      Text(
                        Fmt.money(liabilities, forceCompact: true),
                        style: AppTextStyles.base(
                          size: 22,
                          weight: FontWeight.w700,
                          height: 1.1,
                        ).copyWith(color: palette.expense),
                      ),
                      _TileValue('Loan Balance'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TileRow(
              children: <Widget>[
                OverviewTile(
                  title: 'Bill Splitter',
                  icon: Icons.call_split_rounded,
                  minHeight: 160,
                  onTap: () => _push(context, const SplitsScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CountValue('${bills.length}', 'Bills'),
                      _CountValue('${groups.length}', 'Active'),
                      const SizedBox(height: 6),
                      _TileValue(
                        'Shared ${Fmt.money(bills.fold<int>(0, (a, b) => a + b.amount), forceCompact: true)}',
                      ),
                    ],
                  ),
                ),
                OverviewTile(
                  title: 'Goals',
                  icon: Icons.track_changes_rounded,
                  minHeight: 160,
                  onTap: () => _push(context, const GoalsScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CountValue('$activeGoals', 'Active'),
                      _CountValue('$doneGoals', 'Completed'),
                      const SizedBox(height: 6),
                      _ProgressLine(
                        value: goalTarget == 0 ? 0 : goalSaved / goalTarget,
                      ),
                      const SizedBox(height: 6),
                      _TileValue(
                        'Progress: ${Fmt.money(goalSaved, forceCompact: true)} / ${Fmt.money(goalTarget, forceCompact: true)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TileRow(
              children: <Widget>[
                OverviewTile(
                  title: 'Assets',
                  icon: Icons.savings_outlined,
                  minHeight: 148,
                  onTap: () => _push(context, const AssetsScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CountValue('$assets', 'Total Assets'),
                      const SizedBox(height: 6),
                      _TileValue(
                        '${accounts.where((a) => a.type == kAccountInvestment).length} investments',
                      ),
                      _TileValue(
                        '${accounts.where((a) => a.type == kAccountBank).length} bank accounts',
                      ),
                    ],
                  ),
                ),
                OverviewTile(
                  title: 'Labels',
                  icon: Icons.sell_outlined,
                  minHeight: 148,
                  onTap: () => _push(context, const CategoriesScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CountValue('${tags.length}', 'Labels'),
                      const SizedBox(height: 8),
                      if (tags.isEmpty)
                        _TileValue('Tag transactions to group them')
                      else
                        for (final tag in tags.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '#$tag',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(AppColors.accentShift)
                                  .copyWith(fontSize: 11.5),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TileRow(
              children: <Widget>[
                OverviewTile(
                  title: 'Analytics',
                  icon: Icons.show_chart_rounded,
                  minHeight: 158,
                  onTap: () => _openTab(ref, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _TileValue('This month spending'),
                      const SizedBox(height: 2),
                      Text(
                        Fmt.money(monthSpend, forceCompact: true),
                        style: AppTextStyles.base(
                          size: 24,
                          weight: FontWeight.w700,
                          height: 1.1,
                        ).copyWith(color: palette.accent),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Icon(
                            expenseDelta <= 0
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 13,
                            color: expenseDelta <= 0
                                ? palette.income
                                : palette.expense,
                          ),
                          Text(
                            '${expenseDelta.abs().toStringAsFixed(1)}% vs last month',
                            style: AppTextStyles.caption(
                              expenseDelta <= 0
                                  ? palette.income
                                  : palette.expense,
                            ).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OverviewTile(
                  title: 'Recurring',
                  icon: Icons.event_repeat_rounded,
                  minHeight: 158,
                  onTap: () => _push(context, const RecurringScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CountValue('$activeRecurring', 'Active'),
                      const SizedBox(height: 6),
                      Text(
                        Fmt.money(monthlyRecurring, forceCompact: true),
                        style: AppTextStyles.serif(
                          size: 21,
                          color: palette.onSoft,
                        ),
                      ),
                      _TileValue('Monthly Payment'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TileRow(
              children: <Widget>[
                OverviewTile(
                  title: 'Categories',
                  icon: Icons.category_outlined,
                  minHeight: 186,
                  onTap: () => _push(context, const CategoriesScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CountValue('${categories.length}', 'Categories'),
                      const SizedBox(height: 8),
                      for (final cat in topCats)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.subdirectory_arrow_right_rounded,
                                size: 13,
                                color: AppColors.fromHex(cat.color),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption(palette.sub)
                                      .copyWith(fontSize: 11.5),
                                ),
                              ),
                              Text(
                                Fmt.money(cat.total, forceCompact: true),
                                style: AppTextStyles.caption(palette.ink)
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                OverviewTile(
                  title: 'Weekly',
                  icon: Icons.bar_chart_rounded,
                  minHeight: 186,
                  onTap: () => _openTab(ref, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _TileValue('This Week'),
                              Text(
                                Fmt.money(weekDays.fold<int>(0, (a, b) => a + b),
                                    forceCompact: true),
                                style: AppTextStyles.caption(palette.ink)
                                    .copyWith(fontSize: 11.5),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              _TileValue('Last Week'),
                              Text(
                                Fmt.money(previous.expense ~/ 4,
                                    forceCompact: true),
                                style: AppTextStyles.caption(palette.tertiary)
                                    .copyWith(fontSize: 11.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _WeekBars(values: weekDays),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          for (final d in const <String>[
                            'M', 'T', 'W', 'T', 'F', 'S', 'S',
                          ])
                            Text(
                              d,
                              style: AppTextStyles.caption(palette.tertiary)
                                  .copyWith(fontSize: 9),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TileRow(
              children: <Widget>[
                OverviewTile(
                  title: 'Last 30 Days',
                  icon: Icons.trending_up_rounded,
                  minHeight: 176,
                  onTap: () => _openTab(ref, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            Fmt.money(monthSpend, forceCompact: true),
                            style: AppTextStyles.serif(
                              size: 21,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.show_chart_rounded,
                            size: 14,
                            color: palette.income,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 62,
                        child: CustomPaint(
                          size: const Size(double.infinity, 62),
                          painter: _AreaSparkPainter(
                            values: <double>[
                              for (final d in daily) d.total.toDouble(),
                            ],
                            line: palette.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OverviewTile(
                  title: 'Achievements',
                  icon: Icons.emoji_events_outlined,
                  minHeight: 176,
                  onTap: () => _push(context, const AchievementsScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CountValue('$unlocked', '/ ${achievements.length} unlocked'),
                      const SizedBox(height: 6),
                      _TileValue(
                        '${achievements.isEmpty ? 0 : (unlocked / achievements.length * 100).round()}% completed',
                      ),
                      const SizedBox(height: 8),
                      _ProgressLine(
                        value: achievements.isEmpty
                            ? 0
                            : unlocked / achievements.length,
                        color: palette.income,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            PaisaSectionTitle(
              title: 'Templates',
              color: palette.accent,
              action: 'See all',
              onAction: () => _push(context, const CategoriesScreen()),
            ),
            SizedBox(
              height: 152,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _TemplateCard(
                    label: 'Morning Coffee',
                    amount: 450,
                    icon: Icons.local_cafe_rounded,
                    tint: const Color(0xFF8A6A5C),
                    onTap: () => _quickAdd(context, ref, 450, 'Morning coffee'),
                  ),
                  _TemplateCard(
                    label: 'Grocery Run',
                    amount: 6500,
                    icon: Icons.shopping_basket_rounded,
                    tint: const Color(0xFF2FBF7A),
                    onTap: () async => _quickAdd(context, ref, 6500, 'Grocery run'),
                  ),
                  _TemplateCard(
                    label: 'Metro Card',
                    amount: 20000,
                    icon: Icons.account_balance_rounded,
                    tint: const Color(0xFF2F9BF2),
                    onTap: () => _quickAdd(context, ref, 20000, 'Metro card'),
                  ),
                  _TemplateCard(
                    label: 'Salary',
                    amount: 7500000,
                    icon: Icons.payments_rounded,
                    tint: const Color(0xFFB0785A),
                    onTap: () => _quickAdd(
                      context,
                      ref,
                      7500000,
                      'Monthly salary',
                      type: kTypeIncome,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PaisaSectionCard(
              title: 'Calendar heatmap',
              icon: Icons.calendar_month_rounded,
              onTap: () => _push(context, const ReportsScreen()),
              child: MonthHeatmap(
                month: DateTime.now(),
                totals: <int, int>{
                  for (final day in daily) day.day.day: day.total,
                },
                onDay: (_) => _push(context, const ReportsScreen()),
              ),
            ),
            PaisaSectionCard(
              title: 'Trend',
              icon: Icons.show_chart_rounded,
              onTap: () => _push(context, const ReportsScreen()),
              child: TrendChart(
                previous: _series(daily, previous.expense, DateTime.now().day),
                current: _series(daily, summary.expense, DateTime.now().day),
                upcoming: _projection(daily, summary.expense),
                startDay: 1,
                endDay: DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day,
                prefix: '₹',
              ),
            ),
            PaisaSectionTitle(
              title: 'Track budgets',
              action: 'See all',
              onAction: () => _push(context, const BudgetsScreen()),
            ),
            if (budgets.isEmpty)
              PaisaCard(
                child: Text(
                  'Set a spending limit and track it here.',
                  style: AppTextStyles.body(palette.tertiary),
                ),
              )
            else
              _TrackBudgetsCarousel(
                budgets: budgets,
                onOpen: () => _push(context, const BudgetsScreen()),
                onInfo: () => _howBudgetsWork(context),
              ),
            const SizedBox(height: 18),
            PaisaSectionTitle(
              title: 'Upcoming transactions',
              color: palette.accent,
              action: 'See All',
              onAction: () => _push(context, const TransactionsScreen()),
            ),
            if (recent.isEmpty)
              PaisaCard(
                child: Text(
                  'Nothing scheduled yet.',
                  style: AppTextStyles.body(palette.tertiary),
                ),
              )
            else
              for (final txn in recent.take(6))
                PaisaTxnCard(
                  txn: txn,
                  category: categoryLookup[txn.categoryId],
                  accountName: accountLookup[txn.accountId]?.name,
                  toAccountName: txn.toAccountId == null
                      ? null
                      : accountLookup[txn.toAccountId]?.name,
                  onTap: () => _push(context, const TransactionsScreen()),
                ),
          ],
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  static void _openTab(WidgetRef ref, int index) {
    ref.read(navIndexProvider.notifier).state = index;
  }

  static List<double> _series(List<DayTotal> daily, int total, int uptoDay) {
    final perDay = <int, int>{for (final d in daily) d.day.day: d.total};
    var running = 0.0;
    final out = <double>[];
    final days = uptoDay.clamp(1, 31);
    final step = (total / days).clamp(1, double.infinity);
    for (var day = 1; day <= days; day++) {
      running += perDay[day]?.toDouble() ?? step / 6;
      out.add(running);
    }
    return out;
  }

  static List<double> _projection(List<DayTotal> daily, int total) {
    final day = DateTime.now().day;
    final perDay = total <= 0 ? 0.0 : total / day;
    final out = <double>[];
    var running = 0.0;
    for (var i = 0; i < day; i++) {
      running += perDay;
      out.add(running);
    }
    final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    for (var i = day; i < daysInMonth; i++) {
      running += perDay;
      out.add(running);
    }
    return out;
  }

  static Future<void> _howBudgetsWork(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Budgets Work',
        intro:
            'Budgets help you set spending limits and track your expenses. Here\'s how to get started.',
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.swap_vert_rounded,
            title: 'Budget For',
            body:
                'Expense Budget: Set limits on how much you spend.\nIncome Budget: Set goals for how much you earn.',
          ),
          InfoSection(
            icon: Icons.category_outlined,
            title: 'Budget Type',
            body:
                'Category Budget: Track spending for specific categories (e.g., Food, Transport).\nOverall Budget: Track your total spending, optionally excluding certain categories.',
          ),
          InfoSection(
            icon: Icons.tune_rounded,
            title: 'Budget Mode',
            body:
                'Automatic: MoneyMan automatically matches transactions to your budget based on categories.\nManual: You choose which transactions count toward the budget.',
          ),
          InfoSection(
            icon: Icons.calendar_today_rounded,
            title: 'Budget Period',
            body:
                'Choose Daily, Weekly, Monthly, Yearly, or a Custom date range.\nMonthly budgets can start on a custom day (e.g., 25th for salary cycles).',
          ),
          InfoSection(
            icon: Icons.label_outline_rounded,
            title: 'Categories',
            body:
                'For Category budgets: select which categories to track.\nFor Overall budgets: select which categories to exclude.\nYou can also include subcategories.',
          ),
          InfoSection(
            icon: Icons.autorenew_rounded,
            title: 'Rolling Budget',
            body:
                'Unused budget carries over to the next period. Overspending reduces next period\'s available budget.',
          ),
          InfoSection(
            icon: Icons.bar_chart_rounded,
            title: 'Tracking',
            body:
                'Your budget card shows spent amount, remaining amount, and a progress bar. Status indicators show whether you\'re on track, approaching your limit, or have exceeded it.',
          ),
        ],
      ),
    );
  }

  static List<int> _lastSeven(List<DayTotal> daily) {
    final map = <int, int>{
      for (final d in daily) DateTime(d.day.year, d.day.month, d.day.day).hashCode: d.total,
    };
    final now = DateTime.now();
    return <int>[
      for (var i = 6; i >= 0; i--)
        map[DateTime(now.year, now.month, now.day)
                .subtract(Duration(days: i))
                .hashCode] ??
            0,
    ];
  }

  static void _quickAdd(
    BuildContext context,
    WidgetRef ref,
    int amount,
    String note, {
    String type = kTypeExpense,
  }) {
    showAddTransactionSheet(
      context,
      ref,
      initialType: type,
      initialAmount: amount,
      initialNote: note,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.notifications,
    required this.onBell,
    required this.onSettings,
  });

  final String name;
  final int notifications;
  final VoidCallback onBell;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <TextSpan>[
                TextSpan(text: '${DateX.greeting()} '),
                TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      '. You have $notifications notification${notifications == 1 ? '' : 's'} ',
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(Icons.notifications_rounded,
                        size: 15, color: palette.accent),
                  ),
                ),
              ],
            ),
            style: AppTextStyles.base(size: 15, weight: FontWeight.w500, height: 1.4)
                .copyWith(color: palette.sub),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onBell,
          child: Icon(Icons.notifications_none_rounded,
              size: 22, color: palette.ink),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onSettings,
          child: Icon(Icons.settings_outlined, size: 22, color: palette.ink),
        ),
        const SizedBox(width: 8),
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.metalGradient,
            border: Border.all(color: palette.accent, width: 1.4),
          ),
          alignment: Alignment.center,
          child: Text(
            name.isEmpty ? 'P' : name.substring(0, 1).toUpperCase(),
            style: AppTextStyles.serif(size: 14, color: AppColors.espresso),
          ),
        ),
      ],
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.balance,
    required this.income,
    required this.expense,
    required this.incomeDelta,
    required this.expenseDelta,
    required this.hidden,
    required this.onToggle,
  });

  final int balance;
  final int income;
  final int expense;
  final double incomeDelta;
  final double expenseDelta;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final fg = palette.isDark ? Colors.white : const Color(0xFF3A1B0E);
    final soft = fg.withOpacity(0.72);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? const <Color>[Color(0xFF7A4028), Color(0xFF612F1B)]
              : const <Color>[Color(0xFFFFD9C6), Color(0xFFFFC1A5)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Total balance',
                style: AppTextStyles.base(
                  size: 16.5,
                  weight: FontWeight.w500,
                  height: 1.1,
                ).copyWith(color: soft),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                  color: soft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hidden ? '••••••' : Fmt.money(balance),
              style: AppTextStyles.base(
                size: 38,
                weight: FontWeight.w700,
                height: 1.05,
                letterSpacing: -0.6,
              ).copyWith(color: fg),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroColumn(
                  label: 'Income',
                  amount: income,
                  delta: incomeDelta,
                  tone: palette.isDark
                      ? const Color(0xFF9BE8C0)
                      : const Color(0xFF146B45),
                  fg: fg,
                  soft: soft,
                  hidden: hidden,
                  positiveIsGood: true,
                ),
              ),
              Expanded(
                child: _HeroColumn(
                  label: 'Expense',
                  amount: expense,
                  delta: expenseDelta,
                  tone: palette.isDark
                      ? const Color(0xFFFF9E97)
                      : const Color(0xFFA52A22),
                  fg: fg,
                  soft: soft,
                  hidden: hidden,
                  positiveIsGood: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroColumn extends StatelessWidget {
  const _HeroColumn({
    required this.label,
    required this.amount,
    required this.delta,
    required this.tone,
    required this.fg,
    required this.soft,
    required this.hidden,
    required this.positiveIsGood,
  });

  final String label;
  final int amount;
  final double delta;
  final Color tone;
  final Color fg;
  final Color soft;
  final bool hidden;
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final good = positiveIsGood ? delta >= 0 : delta <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: AppTextStyles.caption(soft).copyWith(fontSize: 11.5)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            hidden ? '••••' : Fmt.money(amount, forceCompact: true),
            style: AppTextStyles.serif(size: 17, color: fg),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: <Widget>[
            Icon(
              delta >= 0
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 12,
              color: good ? tone : const Color(0xFFFF8A80),
            ),
            Text(
              '${delta.abs().toStringAsFixed(1)}%',
              style: AppTextStyles.caption(
                good ? tone : const Color(0xFFFF8A80),
              ).copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _TileValue extends StatelessWidget {
  const _TileValue(this.text, {this.size = 12});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.base(size: size + 2, height: 1.25)
          .copyWith(color: context.c.sub),
    );
  }
}

class _CountValue extends StatelessWidget {
  const _CountValue(this.count, this.label);

  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          count,
          style: AppTextStyles.base(
            size: 22,
            weight: FontWeight.w700,
            height: 1.1,
          ).copyWith(color: palette.accent),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.base(
              size: 14.5,
              weight: FontWeight.w400,
              height: 1.2,
            ).copyWith(color: palette.sub),
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.value, this.color});

  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return WavyProgress(
      value: value,
      height: 16,
      color: color ?? palette.accent,
      trackColor: palette.divider,
      waves: 5,
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final maxV = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: 12 + (values[i] / (maxV == 0 ? 1 : maxV)) * 44,
                  decoration: BoxDecoration(
                    color: i == 4
                        ? palette.ink
                        : palette.accent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AreaSparkPainter extends CustomPainter {
  _AreaSparkPainter({required this.values, required this.line});

  final List<double> values;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV <= 0) return;
    final step = size.width / (values.length - 1 == 0 ? 1 : values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * step;
      final y = size.height - (values[i] / maxV) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[line.withOpacity(0.35), line.withOpacity(0.02)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = line,
    );
    canvas.drawCircle(
      Offset(size.width, size.height - (values.last / maxV) * (size.height - 8) - 4),
      3,
      Paint()..color = line,
    );
  }

  @override
  bool shouldRepaint(covariant _AreaSparkPainter old) => old.values != values;
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 246,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.divider.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 23, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  Fmt.money(amount),
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w600,
                    height: 1.1,
                  ).copyWith(color: palette.ink),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.base(
                size: 18.5,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: palette.ink),
            ),
            const SizedBox(height: 3),
            Text(
              'Expense',
              style: AppTextStyles.base(
                size: 14,
                weight: FontWeight.w400,
                height: 1.2,
              ).copyWith(color: palette.tertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally paged budget cards with the reference ring + figures layout.
class _TrackBudgetsCarousel extends StatefulWidget {
  const _TrackBudgetsCarousel({
    required this.budgets,
    required this.onOpen,
    required this.onInfo,
  });

  final List<BudgetProgress> budgets;
  final VoidCallback onOpen;
  final VoidCallback onInfo;

  @override
  State<_TrackBudgetsCarousel> createState() => _TrackBudgetsCarouselState();
}

class _TrackBudgetsCarouselState extends State<_TrackBudgetsCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final budgets = widget.budgets.take(5).toList();
    return Column(
      children: <Widget>[
        SizedBox(
          height: 210,
          child: PageView.builder(
            padEnds: false,
            controller: PageController(viewportFraction: 0.9),
            itemCount: budgets.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final progress = budgets[index];
              final tint = index.isEven
                  ? const Color(0xFF123B36)
                  : const Color(0xFF3B2A12);
              final accent = index.isEven
                  ? const Color(0xFF2ED3B7)
                  : const Color(0xFFF6B93B);
              return GestureDetector(
                onTap: widget.onOpen,
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.isDark ? tint : AppColors.mint,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              AppIcons.byName(progress.budget.icon),
                              size: 25,
                              color: palette.isDark
                                  ? const Color(0xFF0B1512)
                                  : AppColors.espresso,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  progress.budget.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.base(
                                    size: 19,
                                    weight: FontWeight.w600,
                                    height: 1.1,
                                  ).copyWith(color: palette.ink),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      progress.budget.period[0].toUpperCase() +
                                          progress.budget.period.substring(1),
                                      style: AppTextStyles.base(
                                        size: 14,
                                        weight: FontWeight.w400,
                                        height: 1.1,
                                      ).copyWith(color: palette.sub),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '·',
                                      style: AppTextStyles.base(
                                        size: 14,
                                        height: 1.1,
                                      ).copyWith(color: palette.tertiary),
                                    ),
                                    const SizedBox(width: 6),
                                    PaisaChip(
                                      label:
                                          progress.isOver ? 'Over' : 'Within',
                                      color: progress.isOver
                                          ? palette.expense
                                          : accent,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          RingGauge(
                            value: progress.ratio,
                            size: 104,
                            strokeWidth: 11,
                            color: accent,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  '${progress.percent.toStringAsFixed(0)}%',
                                  style: AppTextStyles.base(
                                    size: 21,
                                    weight: FontWeight.w700,
                                    height: 1.05,
                                  ).copyWith(color: palette.ink),
                                ),
                                Text(
                                  'used',
                                  style: AppTextStyles.base(
                                    size: 13,
                                    weight: FontWeight.w400,
                                    height: 1.2,
                                  ).copyWith(color: palette.sub),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                _MiniFigure(
                                  icon: Icons.account_balance_outlined,
                                  label: 'Budget',
                                  value: Fmt.money(progress.amount),
                                ),
                                _MiniFigure(
                                  icon: Icons.shopping_cart_outlined,
                                  label: 'Spent',
                                  value: Fmt.money(progress.spent),
                                ),
                                _MiniFigure(
                                  icon: Icons.savings_outlined,
                                  label: 'Remaining',
                                  value: Fmt.money(progress.remaining),
                                  tone: accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (var i = 0; i < budgets.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 7,
                width: 7,
                decoration: BoxDecoration(
                  color: i == _page ? palette.accent : palette.divider,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: widget.onInfo,
              child: Icon(Icons.info_outline_rounded,
                  size: 16, color: palette.tertiary),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniFigure extends StatelessWidget {
  const _MiniFigure({
    required this.icon,
    required this.label,
    required this.value,
    this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final color = tone ?? palette.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: color.withOpacity(0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.base(
                size: 15,
                weight: FontWeight.w400,
                height: 1.2,
              ).copyWith(color: palette.sub),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.base(
              size: 15.5,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
