import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/stats_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/fields.dart';
import '../../widgets/luxe.dart';
import '../../widgets/luxe_charts.dart';
import '../../widgets/pickers.dart';
import '../../widgets/premium_badge.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_tile.dart';
import '../io/export_screen.dart';
import '../transactions/transaction_detail_screen.dart';
import 'custom_report_screen.dart';
import 'stats_charts.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final range = ref.watch(statsRangeProvider);
    final type = ref.watch(statsTypeProvider);
    final premium = ref.watch(isPremiumProvider);

    final summary = ref.watch(statsSummaryProvider);
    final previous = ref.watch(statsPreviousSummaryProvider);
    final categories = ref.watch(statsCategoryTotalsProvider);
    final daily = ref.watch(statsDailyTotalsProvider);
    final top = ref.watch(statsTopTransactionsProvider);
    final accountSpending = ref.watch(statsAccountSpendingProvider);
    final heatmap = ref.watch(statsHeatmapProvider);
    final monthly = ref.watch(statsMonthlyProvider);
    final yearly = ref.watch(statsYearlyProvider);
    final cashflow = ref.watch(statsCashFlowProvider);
    final recurring = ref.watch(statsRecurringProvider);
    final forecast = ref.watch(statsForecastProvider);
    final insights = ref.watch(insightsProvider);
    final categoriesLookup =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};

    final summaryValue = summary.valueOrNull ?? const PeriodSummary();
    final previousValue = previous.valueOrNull ?? const PeriodSummary();
    final categoryList = categories.valueOrNull ?? const <CategoryTotal>[];
    final dailyList = daily.valueOrNull ?? const <DayTotal>[];
    final activeDays = dailyList.length;
    final averageDaily = activeDays == 0 ? 0 : summaryValue.expense ~/ activeDays;
    final averageTransaction = summaryValue.count == 0
        ? 0
        : summaryValue.expense ~/ summaryValue.count;
    final highestDay = dailyList.isEmpty
        ? null
        : dailyList.reduce((a, b) => a.total >= b.total ? a : b);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            const MetallicMark(size: 28, animated: false),
            const SizedBox(width: 10),
            Text(tr(context, 'Insights'), style: AppTextStyles.h2(palette.ink)),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ExportScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Custom report',
            icon: const Icon(Icons.auto_graph_rounded),
            onPressed: () async {
              if (!premium) {
                final allowed = await ensurePremium(context, ref, feature: 'Custom reports');
                if (!allowed) return;
              }
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CustomReportScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: () async {
          ref.invalidate(statsSummaryProvider);
          ref.invalidate(statsCategoryTotalsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: <Widget>[
            DateRangeChips(
              ranges: buildDateRanges(firstDayOfWeek: 7),
              selectedLabel: range.label,
              onSelected: (value) {
                ref.read(statsRangeProvider.notifier).state = StatsRange(
                  label: value.label,
                  start: value.start,
                  end: value.end,
                );
              },
              onCustom: () async {
                final custom = await pickCustomRange(context, start: range.start);
                if (custom == null) return;
                ref.read(statsRangeProvider.notifier).state = StatsRange(
                  label: 'Custom',
                  start: custom.start,
                  end: custom.end,
                );
              },
            ),
            const SizedBox(height: AppSpacing.x3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: SegmentedControl<String>(
                value: type,
                options: const <SegmentOption<String>>[
                  SegmentOption(value: 'all', label: 'All'),
                  SegmentOption(value: 'expense', label: 'Expense'),
                  SegmentOption(value: 'income', label: 'Income'),
                ],
                onChanged: (value) => ref.read(statsTypeProvider.notifier).state = value,
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: _FinancialHealthCard(
                summary: summaryValue,
                previous: previousValue,
                categoryCount: categoryList.length,
                activeDays: activeDays,
                monthDays: range.end.difference(range.start).inDays + 1,
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatCard(
                          label: 'Income',
                          amount: summaryValue.income,
                          type: kTypeIncome,
                          icon: Icons.south_west_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: StatCard(
                          label: 'Expenses',
                          amount: summaryValue.expense,
                          type: kTypeExpense,
                          icon: Icons.north_east_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatCard(
                          label: 'Net savings',
                          amount: summaryValue.net,
                          icon: Icons.savings_rounded,
                          tone: summaryValue.net >= 0 ? palette.income : palette.expense,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: StatCard(
                          label: 'Savings rate',
                          value: '${summaryValue.savingsRate.toStringAsFixed(0)}%',
                          icon: Icons.percent_rounded,
                          tone: palette.accent,
                          caption: 'of income saved',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatCard(
                          label: 'Avg daily spend',
                          amount: averageDaily,
                          icon: Icons.calendar_today_rounded,
                          dense: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: StatCard(
                          label: 'Avg transaction',
                          amount: averageTransaction,
                          icon: Icons.receipt_rounded,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Column(
                children: <Widget>[
                  // 1. Category donut
                  ChartCard(
                    title: 'Where the money went',
                    subtitle: range.label,
                    child: Column(
                      children: <Widget>[
                        PetalDonut(
                          size: 210,
                          centerValue: Fmt.money(
                            categoryList.fold<int>(0, (sum, item) => sum + item.total),
                            forceCompact: true,
                          ),
                          centerLabel: 'TOTAL',
                          onSelected: (index) {
                            if (index >= categoryList.length) return;
                            ref.read(transactionFilterProvider.notifier).state =
                                TransactionFilter(
                              categoryIds: <int>[categoryList[index].categoryId],
                            );
                            ref.read(navIndexProvider.notifier).state = 1;
                          },
                          slices: <PetalSlice>[
                            for (final item in categoryList.take(8))
                              PetalSlice(
                                value: item.total.toDouble(),
                                color: AppColors.fromHex(item.color),
                                label: item.name,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        ...categoryList.take(5).map(
                              (item) => ChartLegendRow(
                                color: AppColors.fromHex(item.color),
                                label: item.name,
                                value: Fmt.money(item.total, forceCompact: true),
                                percent: '${((item.total / (categoryList.fold<int>(0, (s, e) => s + e.total) == 0 ? 1 : categoryList.fold<int>(0, (s, e) => s + e.total))) * 100).toStringAsFixed(0)}%',
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 2. Daily expense bars
                  ChartCard(
                    title: 'Daily spending',
                    subtitle: highestDay == null
                        ? 'No spending yet'
                        : 'Highest on ${Fmt.date(highestDay.day.millisecondsSinceEpoch)} · ${Fmt.money(highestDay.total, forceCompact: true)}',
                    child: DailyBarChart(days: dailyList),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 3. Trend line + legend
                  ChartCard(
                    title: 'Income vs expense trend',
                    subtitle: 'Last 6 months',
                    child: Column(
                      children: <Widget>[
                        TrendLineChart(
                          income: (monthly.valueOrNull ?? const <MonthTotal>[])
                              .map((m) => m.income)
                              .toList(),
                          expense: (monthly.valueOrNull ?? const <MonthTotal>[])
                              .map((m) => m.expense)
                              .toList(),
                          labels: (monthly.valueOrNull ?? const <MonthTotal>[])
                              .map((m) => DateXShort.month(m.month))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            LegendDot(color: palette.income, label: 'Income'),
                            const SizedBox(width: 14),
                            LegendDot(color: palette.expense, label: 'Expense'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 4. Grouped bars
                  ChartCard(
                    title: 'Month by month',
                    subtitle: 'Income and expense side by side',
                    child: GroupedBarChart(
                      months: monthly.valueOrNull ?? const <MonthTotal>[],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 5. Category ranking
                  ChartCard(
                    title: 'Category ranking',
                    child: RankedBars(
                      totals: categoryList,
                      max: 8,
                      onTap: (item) {
                        ref.read(transactionFilterProvider.notifier).state =
                            TransactionFilter(categoryIds: <int>[item.categoryId]);
                        ref.read(navIndexProvider.notifier).state = 1;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 6. Calendar heatmap
                  ChartCard(
                    title: 'Daily heatmap',
                    subtitle: Fmt.monthYear(range.start.millisecondsSinceEpoch),
                    child: CalendarHeatmap(
                      month: range.start,
                      days: heatmap.valueOrNull ?? const <DayTotal>[],
                      onTapDay: (date) {
                        ref.read(transactionFilterProvider.notifier).state =
                            TransactionFilter(startDate: date, endDate: date);
                        ref.read(navIndexProvider.notifier).state = 1;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 7. Account spending
                  ChartCard(
                    title: 'Spending by account',
                    child: (accountSpending.valueOrNull ?? const <MapEntry<String, int>>[])
                            .isEmpty
                        ? const ChartEmpty()
                        : Column(
                            children: (accountSpending.valueOrNull ?? <MapEntry<String, int>>[])
                                .map((entry) {
                              final total = accountSpending.valueOrNull!
                                  .fold<int>(0, (sum, e) => sum + e.value);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  children: <Widget>[
                                    ChartLegendRow(
                                      color: palette.transfer,
                                      label: entry.key,
                                      value: Fmt.money(entry.value, forceCompact: true),
                                      percent:
                                          '${((entry.value / (total == 0 ? 1 : total)) * 100).toStringAsFixed(0)}%',
                                    ),
                                    ProgressBar(
                                      value: total == 0 ? 0 : entry.value / total,
                                      color: palette.transfer,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 8. Comparison with previous period
                  ChartCard(
                    title: 'Versus previous period',
                    child: Column(
                      children: <Widget>[
                        ComparisonRow(
                          label: 'Income',
                          current: summaryValue.income,
                          previous: previousValue.income,
                        ),
                        ComparisonRow(
                          label: 'Expenses',
                          current: summaryValue.expense,
                          previous: previousValue.expense,
                        ),
                        ComparisonRow(
                          label: 'Net savings',
                          current: summaryValue.net,
                          previous: previousValue.net,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 9. Year over year
                  ChartCard(
                    title: 'Year over year',
                    subtitle: 'Expenses by month',
                    premium: true,
                    child: premium
                        ? GroupedBarChart(months: yearly.valueOrNull ?? const <MonthTotal>[])
                        : PremiumLocked(
                            label: 'Unlock yearly deep dive',
                            child: GroupedBarChart(
                              months: yearly.valueOrNull ?? const <MonthTotal>[],
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 10. Cash flow
                  ChartCard(
                    title: 'Cash flow',
                    subtitle: 'Net balance trend',
                    child: Column(
                      children: <Widget>[
                        TrendLineChart(
                          income: (cashflow.valueOrNull ?? const <CashFlowPoint>[])
                              .map((point) => point.net < 0 ? 0 : point.net)
                              .toList(),
                          expense: (cashflow.valueOrNull ?? const <CashFlowPoint>[])
                              .map((point) => point.expense)
                              .toList(),
                          labels: (cashflow.valueOrNull ?? const <CashFlowPoint>[])
                              .map((point) => DateXShort.month(point.month))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            LegendDot(color: palette.income, label: 'Net'),
                            const SizedBox(width: 14),
                            LegendDot(color: palette.expense, label: 'Spend'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 11. Recurring vs variable
                  ChartCard(
                    title: 'Fixed vs variable spending',
                    child: Builder(
                      builder: (context) {
                        final fixed = recurring.valueOrNull ?? 0;
                        final variable = summaryValue.expense > fixed
                            ? summaryValue.expense - fixed
                            : 0;
                        final total = fixed + variable;
                        return Column(
                          children: <Widget>[
                            ProgressBar(
                              value: total == 0 ? 0 : fixed / total,
                              color: palette.accent,
                              height: 12,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _legendValue(context, 'Recurring', fixed,
                                      palette.accent),
                                ),
                                Expanded(
                                  child: _legendValue(context, 'Variable', variable,
                                      palette.tertiary),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 12. Forecast (premium)
                  ChartCard(
                    title: 'Spending forecast',
                    premium: true,
                    child: premium
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'At your current pace you will spend '
                                '${Fmt.money(forecast.valueOrNull ?? 0)} this month.',
                                style: context.bodyMuted,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Based on ${DateTime.now().day} days of data.',
                                style: context.caption,
                              ),
                            ],
                          )
                        : PremiumLocked(
                            label: 'Unlock forecasting',
                            child: Text(
                              'At your current pace you will spend '
                              '${Fmt.money(forecast.valueOrNull ?? 0)} this month.',
                              style: context.bodyMuted,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 13. Insights
                  ChartCard(
                    title: 'Insights',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (insights.valueOrNull ?? const <Insight>[])
                          .map(
                            (insight) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(Icons.auto_awesome_rounded,
                                      size: 14, color: palette.accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(insight.text,
                                        style: context.bodyMuted
                                            .copyWith(height: 1.4)),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // 14. Top transactions
                  ChartCard(
                    title: 'Largest transactions',
                    child: (top.valueOrNull ?? const <Txn>[]).isEmpty
                        ? const ChartEmpty()
                        : Column(
                            children: (top.valueOrNull ?? <Txn>[])
                                .take(10)
                                .map(
                                  (txn) => TransactionTile(
                                    txn: txn,
                                    category: categoriesLookup[txn.categoryId],
                                    showDate: true,
                                    dense: true,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => TransactionDetailScreen(
                                          transactionId: txn.id!,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  SecondaryButton(
                    label: 'Build a custom report',
                    icon: Icons.auto_graph_rounded,
                    onPressed: () async {
                      if (!premium) {
                        final allowed = await ensurePremium(context, ref, feature: 'Custom reports');
                        if (!allowed) return;
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CustomReportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            const OverlineLabelCenter(text: 'All figures come from your local ledger'),
          ],
        ),
      ),
    );
  }

  Widget _legendValue(BuildContext context, String label, int value, Color tone) {
    return Row(
      children: <Widget>[
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: context.caption),
            Text(
              Fmt.money(value, forceCompact: true),
              style: AppTextStyles.money(12, color: context.c.ink, weight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

/// Financial-health radar with a weighted score in the centre.
class _FinancialHealthCard extends StatelessWidget {
  const _FinancialHealthCard({
    required this.summary,
    required this.previous,
    required this.categoryCount,
    required this.activeDays,
    required this.monthDays,
  });

  final PeriodSummary summary;
  final PeriodSummary previous;
  final int categoryCount;
  final int activeDays;
  final int monthDays;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final savings = (summary.savingsRate / 40).clamp(0.0, 1.0).toDouble();
    final consistency =
        monthDays <= 0 ? 0.0 : (activeDays / monthDays).clamp(0.0, 1.0);
    final diversity = (categoryCount / 8).clamp(0.0, 1.0).toDouble();
    final stability = previous.expense <= 0
        ? 0.55
        : (1 -
                (summary.expense - previous.expense).abs() /
                    previous.expense)
            .clamp(0.0, 1.0)
            .toDouble();
    final activity = (summary.count / 40).clamp(0.0, 1.0).toDouble();
    final score = ((savings * 0.34 +
                consistency * 0.20 +
                diversity * 0.16 +
                stability * 0.15 +
                activity * 0.15) *
            100)
        .round();

    final label = score >= 80
        ? 'Excellent'
        : score >= 65
            ? 'Strong'
            : score >= 45
                ? 'Balanced'
                : score >= 25
                    ? 'Needs care'
                    : 'At risk';

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x5,
        AppSpacing.x5,
        AppSpacing.x4,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Eyebrow('Financial health'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption(palette.ink)
                      .copyWith(fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          HealthRadar(
            size: 258,
            score: score,
            labels: const <String>[
              'Savings',
              'Consistency',
              'Diversity',
              'Stability',
              'Activity',
            ],
            values: <double>[
              savings,
              consistency,
              diversity,
              stability,
              activity,
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: <Widget>[
              _HealthNote(
                icon: Icons.calendar_month_rounded,
                label: 'Active days',
                value: '$activeDays',
              ),
              _HealthNote(
                icon: Icons.savings_outlined,
                label: 'Savings rate',
                value: '${summary.savingsRate.toStringAsFixed(0)}%',
              ),
              _HealthNote(
                icon: Icons.receipt_long_rounded,
                label: 'Entries',
                value: '${summary.count}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthNote extends StatelessWidget {
  const _HealthNote({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(icon, size: 14, color: palette.tertiary),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.serif(size: 15, color: palette.ink)),
          Text(
            label,
            style: AppTextStyles.caption(palette.tertiary)
                .copyWith(fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class OverlineLabelCenter extends StatelessWidget {
  const OverlineLabelCenter({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: AppTextStyles.caption(context.c.tertiary).copyWith(fontSize: 10.5),
      ),
    );
  }
}
