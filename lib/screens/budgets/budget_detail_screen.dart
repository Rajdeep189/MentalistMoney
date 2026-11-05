import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/section_header.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_detail_screen.dart';
import 'budget_form_screen.dart';

class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({super.key, required this.budgetId});

  final int budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final progressAsync = ref.watch(budgetProgressByIdProvider(budgetId));

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Budget'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) async {
              final progress = progressAsync.valueOrNull;
              if (progress == null) return;
              if (value == 'edit') {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BudgetFormScreen(budget: progress.budget),
                  ),
                );
              } else if (value == 'delete') {
                final ok = await confirmAction(
                  context,
                  title: 'Delete this budget?',
                  message: 'Your transactions stay safe — only the budget is removed.',
                );
                if (!ok) return;
                await ref.read(budgetRepositoryProvider).delete(budgetId);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text('Edit budget')),
              PopupMenuItem<String>(value: 'delete', child: Text('Delete budget')),
            ],
          ),
        ],
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (progress) {
          if (progress == null) return const Center(child: Text('Budget not found'));
          final budget = progress.budget;
          final tone = ProgressBar.colorForRatio(context, progress.ratio);
          final daily = ref.watch(budgetDailySpendProvider(budgetId)).valueOrNull ??
              const <DayTotal>[];
          final categoryTotals =
              ref.watch(budgetCategoryTotalsProvider(budgetId)).valueOrNull ??
                  const <CategoryTotal>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              AppSpacing.x10,
            ),
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CategoryIcon(
                          iconName: budget.icon,
                          color: AppColors.fromHex(budget.color),
                          size: 44,
                          rounded: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(budget.name, style: context.h2),
                              Text(
                                '${Fmt.date(budget.startDate)} → ${Fmt.date(budget.endDate)}',
                                style: context.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        AmountText(progress.spent, size: 30, weight: FontWeight.w700),
                        Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 4),
                          child: Text(
                            'of ${Fmt.money(progress.amount)}',
                            style: context.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    ProgressBar(value: progress.ratio, color: tone, height: 10),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Text(
                          progress.isOver
                              ? 'Over by ${Fmt.money(progress.spent - progress.amount)}'
                              : '${Fmt.money(progress.remaining)} remaining',
                          style: AppTextStyles.label(
                            progress.isOver ? palette.expense : palette.income,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${progress.percent.toStringAsFixed(0)}% used',
                          style: context.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.x4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Daily allowance', style: context.caption),
                          const SizedBox(height: 4),
                          AmountText(progress.dailyAllowance, size: 17,
                              weight: FontWeight.w700),
                          Text('${progress.daysLeft} days left', style: context.caption),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.x4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Projected spend', style: context.caption),
                          const SizedBox(height: 4),
                          AmountText(progress.projectedSpend, size: 17,
                              weight: FontWeight.w700),
                          Text(
                            progress.projectedSpend > progress.amount
                                ? 'Will exceed budget'
                                : 'Within budget',
                            style: AppTextStyles.caption(
                              progress.projectedSpend > progress.amount
                                  ? palette.expense
                                  : palette.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.cardGap),
              ChartCard(
                title: 'Daily spending',
                subtitle: 'Inside this budget period',
                child: SizedBox(
                  height: 140,
                  child: daily.isEmpty
                      ? Center(
                          child: Text('No spending yet in this period',
                              style: context.caption),
                        )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
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
                                  reservedSize: 22,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= daily.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${daily[index].day.day}',
                                        style: AppTextStyles.caption(palette.tertiary)
                                            .copyWith(fontSize: 9),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: List<BarChartGroupData>.generate(
                              daily.length,
                              (index) => BarChartGroupData(
                                x: index,
                                barRods: <BarChartRodData>[
                                  BarChartRodData(
                                    toY: (daily[index].total / 100).toDouble(),
                                    color: tone,
                                    width: daily.length > 20 ? 4 : 8,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              if (categoryTotals.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.cardGap),
                ChartCard(
                  title: 'Category breakdown',
                  child: Column(
                    children: categoryTotals.map((total) {
                      final share = progress.spent == 0
                          ? 0.0
                          : total.total / progress.spent;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: <Widget>[
                            ChartLegendRow(
                              color: AppColors.fromHex(total.color),
                              label: total.name,
                              value: Fmt.money(total.total, forceCompact: true),
                              percent: '${(share * 100).toStringAsFixed(0)}%',
                            ),
                            ProgressBar(
                              value: share,
                              color: AppColors.fromHex(total.color),
                              height: 5,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.cardGap),
              AppCard(
                color: palette.accentSoft,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.auto_awesome_rounded, size: 18, color: palette.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        progress.projectedSpend > progress.amount
                            ? 'At this pace you will spend ${Fmt.money(progress.projectedSpend)} by ${Fmt.date(budget.endDate)} — ${Fmt.money(progress.projectedSpend - progress.amount)} over budget.'
                            : 'At this pace you will spend ${Fmt.money(progress.projectedSpend)} by ${Fmt.date(budget.endDate)}, staying within budget.',
                        style: AppTextStyles.caption(palette.onSoft).copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x5),
              SectionHeader(title: 'Transactions', padding: EdgeInsets.zero),
              _BudgetTransactions(budget: budget),
              const SizedBox(height: AppSpacing.x5),
              PrimaryButton(
                label: 'Add expense to this budget',
                icon: Icons.add_rounded,
                onPressed: () => showAddTransactionSheet(
                  context,
                  ref,
                  initialType: kTypeExpense,
                  initialCategoryId: budget.categoryIds.isEmpty
                      ? null
                      : budget.categoryIds.first,
                ),
              ),
            ],
          );
        },
      ),
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
          return AppCard(
            child: Text('No expenses in this period yet.', style: context.bodyMuted),
          );
        }
        return AppCard(
          child: Column(
            children: txns
                .take(20)
                .map((txn) => TransactionTile(
                      txn: txn,
                      category: categories[txn.categoryId],
                      showDate: true,
                      dense: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TransactionDetailScreen(transactionId: txn.id!),
                        ),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}
