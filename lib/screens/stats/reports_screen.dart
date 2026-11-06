import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import '../budgets/budgets_screen.dart';
import '../categories/categories_screen.dart';
import '../goals/goals_screen.dart';
import '../transactions/transactions_screen.dart';
import 'stats_screen.dart';

/// Month-based reports dashboard matching the reference: month chips, totals,
/// income/expense comparison, quick insights, top category, largest expense,
/// a chart card and the financial reports list.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _chartMode = 'bars';
  String _breakdown = 'Expense';
  String _group = 'Category';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final range = ref.watch(statsRangeProvider);
    final summary = ref.watch(statsSummaryProvider).valueOrNull ??
        const PeriodSummary();
    final categories =
        ref.watch(statsCategoryTotalsProvider).valueOrNull ??
            const <CategoryTotal>[];
    final daily =
        ref.watch(statsDailyTotalsProvider).valueOrNull ?? const <DayTotal>[];
    final topTxns =
        ref.watch(statsTopTransactionsProvider).valueOrNull ?? const <Txn>[];
    final categoryLookup =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};

    final total = summary.income - summary.expense;
    final days = range.end.difference(range.start).inDays + 1;
    final avgDaily = days == 0 ? 0 : summary.expense ~/ days;
    final avgTxn =
        summary.count == 0 ? 0 : summary.expense ~/ summary.count;
    final peak = daily.isEmpty
        ? null
        : daily.reduce((a, b) => a.total >= b.total ? a : b);
    final topCategory = categories.isEmpty ? null : categories.first;
    final largest = topTxns.isEmpty
        ? null
        : topTxns.reduce((a, b) => a.amount >= b.amount ? a : b);
    final categoryTotal =
        categories.fold<int>(0, (sum, item) => sum + item.total);
    final months = _months();

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Reports', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: 'All charts',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StatsScreen()),
            ),
            icon: Icon(Icons.pie_chart_outline_rounded, color: palette.sub),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () {},
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: palette.accent.withOpacity(0.25),
              child: Icon(Icons.person_rounded, size: 17, color: palette.accent),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 120),
        children: <Widget>[
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              children: <Widget>[
                for (final month in months)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref.read(statsRangeProvider.notifier).state =
                          StatsRange(
                        label: month.label,
                        start: month.start,
                        end: month.end,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: month.label == range.label
                              ? palette.accent
                              : (palette.isDark
                                  ? const Color(0xFF4A3A12)
                                  : AppColors.surfaceAlt),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          month.label,
                          style: AppTextStyles.base(
                            size: 13.5,
                            weight: FontWeight.w700,
                            height: 1.1,
                          ).copyWith(
                            color: month.label == range.label
                                ? AppColors.espresso
                                : (palette.isDark
                                    ? const Color(0xFFD9C36A)
                                    : palette.sub),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: <Widget>[
                Text(
                  'Total balance',
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w700,
                    height: 1.15,
                  ).copyWith(color: palette.ink),
                ),
                const Spacer(),
                Text(
                  Fmt.money(total),
                  style: AppTextStyles.serif(size: 18, color: palette.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: DeltaStatCard(
                    label: 'Income',
                    amount: summary.income,
                    delta: _delta(summary.income, total, 163),
                    income: true,
                    previous: null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DeltaStatCard(
                    label: 'Expense',
                    amount: summary.expense,
                    delta: _delta(summary.expense, total, 43),
                    income: false,
                    previous: null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: <Widget>[
                Icon(Icons.auto_graph_rounded, size: 18, color: palette.accent),
                const SizedBox(width: 8),
                Text(
                  'Quick Insights',
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w700,
                    height: 1.15,
                  ).copyWith(color: palette.ink),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.isDark
                        ? Colors.white.withOpacity(0.08)
                        : palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${summary.count} Transactions',
                    style:
                        AppTextStyles.caption(palette.sub).copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _InsightTile(
                        icon: Icons.savings_outlined,
                        label: 'Savings Rate',
                        value:
                            '${summary.income == 0 ? 0 : (total / summary.income * 100).round()}%',
                        caption: Fmt.money(total, forceCompact: true),
                        tone: palette.income,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InsightTile(
                        icon: Icons.calendar_today_rounded,
                        label: 'Avg. Daily',
                        value: Fmt.money(avgDaily, forceCompact: true),
                        caption: '${(avgDaily / 100).toStringAsFixed(1)} / day',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _InsightTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'Average Transaction',
                        value: Fmt.money(avgTxn, forceCompact: true),
                        caption: '${summary.count} expenses',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InsightTile(
                        icon: Icons.trending_up_rounded,
                        label: 'Peak Spending Day',
                        value: peak == null
                            ? '—'
                            : Fmt.date(peak.day.millisecondsSinceEpoch),
                        caption: peak == null
                            ? ''
                            : Fmt.money(peak.total, forceCompact: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (topCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.isDark
                      ? const Color(0xFF1E3350)
                      : AppColors.periwinkle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: TileColors.blue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.attach_money_rounded,
                          size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Top Category',
                            style: AppTextStyles.caption(palette.sub)
                                .copyWith(fontSize: 11.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            topCategory.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.base(
                              size: 15,
                              weight: FontWeight.w700,
                              height: 1.15,
                            ).copyWith(color: palette.ink),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          Fmt.money(topCategory.total, forceCompact: true),
                          style: AppTextStyles.base(
                            size: 14,
                            weight: FontWeight.w700,
                            height: 1.1,
                          ).copyWith(color: palette.ink),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: TileColors.blue.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${categoryTotal == 0 ? 0 : (topCategory.total / categoryTotal * 100).round()}%',
                            style: AppTextStyles.caption(TileColors.sky)
                                .copyWith(fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (largest != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.divider.withOpacity(0.65)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: TileColors.pink,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.attach_money_rounded,
                          size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Largest Expense',
                            style: AppTextStyles.caption(palette.sub)
                                .copyWith(fontSize: 11.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (largest.note?.trim().isNotEmpty ?? false)
                                ? largest.note!
                                : (categoryLookup[largest.categoryId]?.name ??
                                    'Expense'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.base(
                              size: 15,
                              weight: FontWeight.w700,
                              height: 1.15,
                            ).copyWith(color: palette.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Fmt.date(largest.date),
                            style: AppTextStyles.caption(palette.tertiary)
                                .copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Fmt.money(largest.amount),
                      style: AppTextStyles.serif(size: 16, color: palette.ink),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.divider.withOpacity(0.65)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Reports',
                        style: AppTextStyles.base(
                          size: 17,
                          weight: FontWeight.w700,
                          height: 1.15,
                        ).copyWith(color: palette.ink),
                      ),
                      const Spacer(),
                      _ChartModeButton(
                        icon: Icons.bar_chart_rounded,
                        active: _chartMode == 'bars',
                        onTap: () => setState(() => _chartMode = 'bars'),
                      ),
                      const SizedBox(width: 8),
                      _ChartModeButton(
                        icon: Icons.show_chart_rounded,
                        active: _chartMode == 'line',
                        onTap: () => setState(() => _chartMode = 'line'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_chartMode == 'bars')
                    _BarReport(daily: daily, income: summary.income)
                  else
                    TrendChart(
                      previous: <double>[
                        for (final day in daily) day.total / 100,
                      ],
                      current: _cumulative(daily),
                      upcoming: const <double>[],
                      height: 180,
                      prefix: '₹',
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      _LegendDot(color: palette.expense, label: 'Expense'),
                      const SizedBox(width: 16),
                      _LegendDot(color: palette.income, label: 'Income'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _DropdownPill(
                    label: _breakdown,
                    options: const <String>['Expense', 'Income'],
                    onSelected: (value) =>
                        setState(() => _breakdown = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DropdownPill(
                    label: _group,
                    options: const <String>['Category', 'Account'],
                    onSelected: (value) => setState(() => _group = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              children: <Widget>[
                if (categories.isNotEmpty)
                  _DonutBreakdown(
                    categories: categories,
                    total: categoryTotal,
                  ),
                const SizedBox(height: 16),
                if (categories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? const Color(0xFF283647)
                          : AppColors.periwinkle,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: TileColors.blue,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.attach_money_rounded,
                              size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${categories.first.name} (${categoryTotal == 0 ? 0 : (categories.first.total / categoryTotal * 100).round()}%)',
                                style: AppTextStyles.base(
                                  size: 14.5,
                                  weight: FontWeight.w700,
                                  height: 1.15,
                                ).copyWith(color: palette.ink),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${categories.first.count} transaction${categories.first.count == 1 ? '' : 's'}',
                                style: AppTextStyles.caption(palette.sub)
                                    .copyWith(fontSize: 11.5),
                              ),
                              Text(
                                'Includes sub-categories',
                                style: AppTextStyles.caption(palette.tertiary)
                                    .copyWith(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Fmt.money(categories.first.total,
                              forceCompact: true),
                          style:
                              AppTextStyles.serif(size: 15, color: palette.ink),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Text(
              'Financial Reports',
              style: AppTextStyles.serif(size: 18, color: AppColors.accentShift),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.divider.withOpacity(0.65)),
              ),
              child: Column(
                children: <Widget>[
                  _ReportRow(
                    icon: Icons.bar_chart_rounded,
                    title: 'Month Summary',
                    subtitle:
                        'Quick overview of income, expenses, and net balance for the current month',
                    onTap: () => _push(context, const TransactionsScreen()),
                  ),
                  _ReportRow(
                    icon: Icons.donut_large_rounded,
                    title: 'Category Breakdown',
                    subtitle:
                        'Detailed spending analysis by category with visual charts',
                    onTap: () => _push(context, const CategoriesScreen()),
                  ),
                  _ReportRow(
                    icon: Icons.track_changes_rounded,
                    title: 'Budget Performance',
                    subtitle:
                        'Track budget vs actual spending with performance indicators',
                    onTap: () => _push(context, const BudgetsScreen()),
                  ),
                  _ReportRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Cash Flow Analysis',
                    subtitle: 'Money flow trends and patterns over time',
                    onTap: () => _push(context, const StatsScreen()),
                  ),
                  _ReportRow(
                    icon: Icons.emoji_events_outlined,
                    title: 'Goal Progress',
                    subtitle:
                        'Financial goals tracking with milestone progress',
                    onTap: () => _push(context, const GoalsScreen()),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption(palette.tertiary)
                    .copyWith(height: 1.6, fontSize: 12),
                children: const <TextSpan>[
                  TextSpan(
                    text: '*Note\n',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        'Overview details show only income and expense transactions from included accounts. Excluded accounts and transfer transactions are not counted towards totals or reports. Initial account balances can be viewed in Accounts section.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _delta(int value, int net, double fallback) {
    if (value == 0) return 0;
    if (net == 0) return fallback;
    return ((net / value) * 100).clamp(-999, 999);
  }

  static List<double> _cumulative(List<DayTotal> daily) {
    var running = 0.0;
    final out = <double>[];
    for (final day in daily) {
      running += day.total / 100;
      out.add(running);
    }
    return out;
  }

  static List<_MonthOption> _months() {
    final now = DateTime.now();
    const names = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return <_MonthOption>[
      for (var i = 0; i < 5; i++)
        _MonthOption(
          '${names[DateTime(now.year, now.month - i).month - 1]} ${DateTime(now.year, now.month - i).year % 100}',
          DateTime(now.year, now.month - i, 1),
          DateTime(now.year, now.month - i + 1, 0),
        ),
    ];
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.divider.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 15, color: palette.sub),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(palette.sub)
                      .copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.serif(
                size: 18,
                color: tone ?? palette.ink,
              ),
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(palette.tertiary)
                  .copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartModeButton extends StatelessWidget {
  const _ChartModeButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 44,
        decoration: BoxDecoration(
          color: active
              ? palette.accent
              : (palette.isDark ? palette.cardAlt : palette.surfaceAlt),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 19,
          color: active ? AppColors.espresso : palette.sub,
        ),
      ),
    );
  }
}

class _BarReport extends StatelessWidget {
  const _BarReport({required this.daily, required this.income});

  final List<DayTotal> daily;
  final int income;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final maxV = daily.isEmpty
        ? 1.0
        : daily
            .map((d) => d.total)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
    final peak = maxV <= 0 ? 1.0 : maxV;
    return SizedBox(
      height: 190,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (var i = 0; i < daily.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            height: (daily[i].total / peak * 150).clamp(2, 150).toDouble(),
                            decoration: BoxDecoration(
                              color: daily[i].total == 0
                                  ? palette.divider
                                  : (i.isEven
                                      ? palette.expense
                                      : palette.income),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              for (var day = 1; day <= 6; day++)
                Expanded(
                  child: Text(
                    '${(day - 1) * 5 + 1}',
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 9),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 9,
          width: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption(context.c.sub).copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}

class _DropdownPill extends StatelessWidget {
  const _DropdownPill({
    required this.label,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: palette.card,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        for (final option in options)
          PopupMenuItem<String>(
            value: option,
            child: Text(option, style: AppTextStyles.body(palette.ink)),
          ),
      ],
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.divider.withOpacity(0.6)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.base(
                  size: 14,
                  weight: FontWeight.w600,
                  height: 1.15,
                ).copyWith(color: palette.ink),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: palette.sub),
          ],
        ),
      ),
    );
  }
}

class _DonutBreakdown extends StatelessWidget {
  const _DonutBreakdown({required this.categories, required this.total});

  final List<CategoryTotal> categories;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final top = categories.first;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 220,
          width: 220,
          child: CustomPaint(
            painter: _DonutPainter(
              values: <double>[
                for (final item in categories.take(6)) item.total.toDouble(),
              ],
              colors: <Color>[
                for (final item in categories.take(6))
                  AppColors.fromHex(item.color),
              ],
              track: palette.isDark
                  ? Colors.white.withOpacity(0.06)
                  : palette.surfaceAlt,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    Fmt.money(total, forceCompact: true),
                    style: AppTextStyles.serif(size: 18, color: palette.ink),
                  ),
                  Text(
                    'Total',
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          top.name,
          style: AppTextStyles.base(
            size: 13,
            weight: FontWeight.w600,
            height: 1.15,
          ).copyWith(color: palette.sub),
        ),
        Text(
          '${total == 0 ? 0 : (top.total / total * 100).round()}%',
          style: AppTextStyles.caption(palette.tertiary).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.track,
  });

  final List<double> values;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 8,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34;
    canvas.drawArc(rect, 0, 6.283185, false, paint..color = track);
    if (total <= 0) return;
    var start = -1.570796;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.283185;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        paint..color = colors[i % colors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values;
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(color: palette.divider.withOpacity(0.6)))
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF5A3220),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.base(
                      size: 15,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(palette.sub)
                        .copyWith(fontSize: 11.5, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: palette.tertiary),
          ],
        ),
      ),
    );
  }
}


class _MonthOption {
  const _MonthOption(this.label, this.start, this.end);

  final String label;
  final DateTime start;
  final DateTime end;
}
