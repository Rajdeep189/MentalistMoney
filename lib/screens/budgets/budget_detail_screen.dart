import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_detail_screen.dart';
import 'budget_form_screen.dart';

class BudgetDetailScreen extends ConsumerStatefulWidget {
  const BudgetDetailScreen({super.key, required this.budgetId});

  final int budgetId;

  @override
  ConsumerState<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ConsumerState<BudgetDetailScreen> {
  bool _showOnHome = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final progressAsync = ref.watch(budgetProgressByIdProvider(widget.budgetId));

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Budget', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add expense',
            onPressed: () {
              final budget = progressAsync.valueOrNull?.budget;
              showAddTransactionSheet(
                context,
                ref,
                initialType: kTypeExpense,
                initialCategoryId: (budget?.categoryIds.isEmpty ?? true)
                    ? null
                    : budget!.categoryIds.first,
              );
            },
            icon: Icon(Icons.add_rounded, color: palette.sub),
          ),
          IconButton(
            tooltip: 'Delete budget',
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Delete this budget?',
                message:
                    'Your transactions stay safe — only the budget is removed.',
              );
              if (!ok) return;
              await ref
                  .read(budgetRepositoryProvider)
                  .delete(widget.budgetId);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: Icon(Icons.delete_outline_rounded, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final progress = progressAsync.valueOrNull;
          if (progress == null) return;
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BudgetFormScreen(budget: progress.budget),
            ),
          );
        },
        backgroundColor: const Color(0xFF2ED3B7),
        foregroundColor: AppColors.espresso,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(
          'Edit',
          style: AppTextStyles.base(
            size: 15,
            weight: FontWeight.w700,
            height: 1.1,
          ).copyWith(color: AppColors.espresso),
        ),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (progress) {
          if (progress == null) {
            return const Center(child: Text('Budget not found'));
          }
          final budget = progress.budget;
          final daily =
              ref.watch(budgetDailySpendProvider(widget.budgetId)).valueOrNull ??
                  const <DayTotal>[];
          final categoryTotals = ref
                  .watch(budgetCategoryTotalsProvider(widget.budgetId))
                  .valueOrNull ??
              const <CategoryTotal>[];
          final accent = progress.isOver
              ? const Color(0xFFF58C8C)
              : progress.ratio > 0.8
                  ? const Color(0xFFF6C453)
                  : const Color(0xFF2ED3B7);
          final status = progress.isOver
              ? 'Exceeded'
              : progress.ratio > 0.8
                  ? 'Warning'
                  : 'Good';

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    accent.withOpacity(palette.isDark ? 0.10 : 0.07),
                    palette.card,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: accent.withOpacity(0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            AppIcons.byName(budget.icon),
                            size: 26,
                            color: AppColors.espresso,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                budget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.base(
                                  size: 19,
                                  weight: FontWeight.w700,
                                  height: 1.15,
                                ).copyWith(color: palette.ink),
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: <Widget>[
                                  _MiniTag(
                                    label: budget.period[0].toUpperCase() +
                                        budget.period.substring(1),
                                    tone: accent,
                                  ),
                                  _MiniTag(
                                    label: budget.type == 'overall'
                                        ? 'Overall'
                                        : 'Category',
                                    tone: accent,
                                  ),
                                  _MiniTag(label: 'Automatic', tone: accent),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: accent.withOpacity(0.45)),
                          ),
                          child: Text(
                            status,
                            style: AppTextStyles.base(
                              size: 12,
                              weight: FontWeight.w700,
                              height: 1.1,
                            ).copyWith(color: accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Text(
                          '${progress.percent.toStringAsFixed(0)}% Used',
                          style: AppTextStyles.base(
                            size: 15,
                            weight: FontWeight.w500,
                            height: 1.1,
                          ).copyWith(color: palette.sub),
                        ),
                        const Spacer(),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${Fmt.money(progress.spent)} of ${Fmt.money(progress.amount)}',
                              style: AppTextStyles.base(
                                size: 14.5,
                                weight: FontWeight.w500,
                                height: 1.1,
                              ).copyWith(color: palette.ink),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    WavyProgress(
                      value: progress.ratio,
                      height: 20,
                      color: accent,
                      trackColor: Color.alphaBlend(
                        accent.withOpacity(0.18),
                        palette.isDark
                            ? const Color(0xFF161110)
                            : Colors.white,
                      ),
                      waves: 9,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Remaining',
                                  style: AppTextStyles.base(
                                    size: 14,
                                    weight: FontWeight.w400,
                                    height: 1.1,
                                  ).copyWith(color: palette.sub)),
                              const SizedBox(height: 3),
                              Text(
                                Fmt.money(progress.remaining,
                                    forceCompact: true),
                                style: AppTextStyles.base(
                                  size: 18,
                                  weight: FontWeight.w600,
                                  height: 1.1,
                                ).copyWith(color: palette.ink),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text('Spent',
                                  style: AppTextStyles.base(
                                    size: 14,
                                    weight: FontWeight.w400,
                                    height: 1.1,
                                  ).copyWith(color: palette.sub)),
                              const SizedBox(height: 3),
                              Text(
                                Fmt.money(progress.spent, forceCompact: true),
                                style: AppTextStyles.base(
                                  size: 18,
                                  weight: FontWeight.w600,
                                  height: 1.1,
                                ).copyWith(color: palette.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.calendar_today_rounded,
                              size: 14, color: accent),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'You can spend ${Fmt.money(progress.dailyAllowance)}/day for '
                              '${progress.daysLeft} more days',
                              style: AppTextStyles.base(
                                size: 13,
                                weight: FontWeight.w500,
                                height: 1.2,
                              ).copyWith(color: accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ToggleRow(
                title: 'Show Budget',
                subtitle: 'Track this budget on home screen',
                value: _showOnHome,
                onChanged: (value) => setState(() => _showOnHome = value),
              ),
              PaisaSectionCard(
                title: 'Budget Progress',
                titleColor: accent,
                child: _BudgetProgressChart(
                  budget: budget,
                  daily: daily,
                  spent: progress.spent,
                  accent: accent,
                ),
              ),
              if (categoryTotals.isNotEmpty)
                PaisaSectionCard(
                  title: 'Category Breakdown',
                  titleColor: accent,
                  child: Column(
                    children: <Widget>[
                      for (final total in categoryTotals) ...<Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: AppColors.fromHex(total.color),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                AppIcons.byName(total.icon),
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          total.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.base(
                                            size: 16.5,
                                            weight: FontWeight.w600,
                                            height: 1.15,
                                          ).copyWith(color: palette.ink),
                                        ),
                                      ),
                                      Text(
                                        '${progress.spent == 0 ? 0 : (total.total / progress.spent * 100).round()}%',
                                        style: AppTextStyles.base(
                                          size: 13.5,
                                          weight: FontWeight.w500,
                                          height: 1.1,
                                        ).copyWith(color: palette.tertiary),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        Fmt.money(total.total),
                                        style: AppTextStyles.base(
                                          size: 15,
                                          weight: FontWeight.w600,
                                          height: 1.1,
                                        ).copyWith(color: palette.ink),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: progress.spent == 0
                                          ? 0
                                          : (total.total / progress.spent)
                                              .clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: palette.divider,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.fromHex(total.color),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                'Recent transactions',
                style: AppTextStyles.base(
                  size: 18,
                  weight: FontWeight.w700,
                  height: 1.15,
                ).copyWith(color: palette.accent),
              ),
              const SizedBox(height: 10),
              _BudgetTransactions(budget: budget),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showAddTransactionSheet(
                    context,
                    ref,
                    initialType: kTypeExpense,
                    initialCategoryId: budget.categoryIds.isEmpty
                        ? null
                        : budget.categoryIds.first,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add expense to this budget'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.ink,
                    side: BorderSide(color: palette.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: AppTextStyles.base(
          size: 10.5,
          weight: FontWeight.w600,
          height: 1.1,
        ).copyWith(color: tone),
      ),
    );
  }
}

/// Cumulative spend against the ideal pace and the budget limit.
class _BudgetProgressChart extends StatelessWidget {
  const _BudgetProgressChart({
    required this.budget,
    required this.daily,
    required this.spent,
    required this.accent,
  });

  final Budget budget;
  final List<DayTotal> daily;
  final int spent;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final start = DateTime.fromMillisecondsSinceEpoch(budget.startDate);
    final end = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
    final totalDays = end.difference(start).inDays.clamp(1, 400);
    final perDay = <int, int>{
      for (final day in daily)
        day.day.difference(DateTime(start.year, start.month, start.day)).inDays:
            day.total,
    };
    var running = 0.0;
    final spots = <FlSpot>[];
    for (var i = 0; i <= totalDays; i++) {
      running += perDay[i]?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), running));
    }
    final maxY = (budget.amount > spent ? budget.amount : spent) * 1.15;
    final limitY = budget.amount.toDouble();

    return Column(
      children: <Widget>[
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: totalDays.toDouble(),
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: palette.divider.withOpacity(0.35),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Text(
                      Fmt.money(value.toInt(), forceCompact: true),
                      style: AppTextStyles.caption(palette.tertiary)
                          .copyWith(fontSize: 9),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: (totalDays / 3).clamp(1, 400).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final date = start.add(Duration(days: value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${_month(date.month)} ${date.day}',
                          style: AppTextStyles.caption(palette.tertiary)
                              .copyWith(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: <LineChartBarData>[
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: accent,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        accent.withOpacity(0.32),
                        accent.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: <FlSpot>[
                    const FlSpot(0, 0),
                    FlSpot(totalDays.toDouble(), limitY),
                  ],
                  color: palette.tertiary,
                  barWidth: 1.4,
                  dashArray: const <int>[6, 5],
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: <FlSpot>[
                    FlSpot(0, limitY),
                    FlSpot(totalDays.toDouble(), limitY),
                  ],
                  color: const Color(0xFFF58C8C),
                  barWidth: 1.4,
                  dashArray: const <int>[2, 3],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _ChartLegend(color: accent, label: 'Expense'),
            const SizedBox(width: 16),
            _ChartLegend(color: palette.tertiary, label: 'Ideal Pace'),
            const SizedBox(width: 16),
            _ChartLegend(color: const Color(0xFFF58C8C), label: 'Limit'),
          ],
        ),
      ],
    );
  }

  static String _month(int month) => const <String>[
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 3,
          width: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption(palette.sub).copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}

class _BudgetTransactions extends ConsumerWidget {
  const _BudgetTransactions({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};
    final accounts =
        ref.watch(accountLookupProvider).valueOrNull ?? const <int, Account>{};
    return FutureBuilder<List<Txn>>(
      future: ref.read(transactionRepositoryProvider).query(
            TransactionFilter(
              startDate: DateTime.fromMillisecondsSinceEpoch(budget.startDate),
              endDate: DateTime.fromMillisecondsSinceEpoch(budget.endDate),
              categoryIds: budget.categoryIds,
              types: const <String>[kTypeExpense],
            ),
          ),
      builder: (context, snapshot) {
        final txns = snapshot.data ?? const <Txn>[];
        if (txns.isEmpty) {
          return PaisaCard(
            child: Text(
              'No expenses in this period yet.',
              style: AppTextStyles.body(context.c.sub),
            ),
          );
        }
        return Column(
          children: <Widget>[
            for (final txn in txns.take(8))
              PaisaTxnCard(
                txn: txn,
                category: categories[txn.categoryId],
                accountName: accounts[txn.accountId]?.name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        TransactionDetailScreen(transactionId: txn.id!),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
