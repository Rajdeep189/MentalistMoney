import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/stats_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/app_card.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_tile.dart';

/// Hero card: Safe to Spend.
class SafeToSpendCard extends StatelessWidget {
  const SafeToSpendCard({super.key, required this.safe, this.onTap, this.hidden = false});

  final SafeToSpend safe;
  final VoidCallback? onTap;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final ratio = safe.budget <= 0 ? 0.0 : (safe.spent / safe.budget);
    final tone = ProgressBar.colorForRatio(context, ratio);

    return TintedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Safe to Spend', style: AppTextStyles.label(palette.sub)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tone.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  ratio > 1 ? 'Over budget' : 'On track',
                  style: AppTextStyles.caption(tone).copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          hidden
              ? Text('••••••', style: context.displayXL)
              : AnimatedAmountText(
                  safe.remaining,
                  size: 34,
                  color: safe.remaining < 0 ? palette.expense : palette.ink,
                ),
          const SizedBox(height: 6),
          Text(
            hidden
                ? 'Amounts hidden for privacy'
                : 'You can spend ${Fmt.money(safe.perDay)} today and still stay on budget.',
            style: AppTextStyles.caption(palette.sub),
          ),
          const SizedBox(height: AppSpacing.x4),
          ProgressBar(value: ratio, color: tone, height: 8),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _miniStat(context, 'Budget', safe.budget),
              _divider(context),
              _miniStat(context, 'Spent', safe.spent),
              _divider(context),
              _miniStat(context, 'Bills', safe.upcomingBills),
            ].map((widget) => Expanded(child: widget)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(
        height: 24,
        width: 1,
        color: context.c.divider,
      );

  Widget _miniStat(BuildContext context, String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(label, style: AppTextStyles.caption(context.c.tertiary).copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        AmountText(value, size: 12.5, forceCompact: true, weight: FontWeight.w600),
      ],
    );
  }
}

/// Month summary card with comparison against last month.
class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    super.key,
    required this.summary,
    required this.previous,
    this.onTap,
  });

  final PeriodSummary summary;
  final PeriodSummary previous;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final delta = previous.expense == 0
        ? 0.0
        : ((summary.expense - previous.expense) / previous.expense) * 100;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const OverlineLabel('This month'),
              const Spacer(),
              if (delta != 0)
                Row(
                  children: <Widget>[
                    Icon(
                      delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 12,
                      color: delta > 0 ? palette.expense : palette.income,
                    ),
                    Text(
                      '${delta.abs().toStringAsFixed(0)}% vs last month',
                      style: AppTextStyles.caption(
                        delta > 0 ? palette.expense : palette.income,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Income', style: AppTextStyles.caption(palette.tertiary)),
                    const SizedBox(height: 2),
                    AmountText(summary.income, size: 17, color: palette.income,
                        weight: FontWeight.w600, forceCompact: true),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Expenses', style: AppTextStyles.caption(palette.tertiary)),
                    const SizedBox(height: 2),
                    AmountText(summary.expense, size: 17, color: palette.expense,
                        weight: FontWeight.w600, forceCompact: true),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Net', style: AppTextStyles.caption(palette.tertiary)),
                    const SizedBox(height: 2),
                    AmountText(summary.net, size: 17, weight: FontWeight.w600,
                        forceCompact: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.savings_rounded, size: 15, color: palette.accent),
                const SizedBox(width: 6),
                Text(
                  'Savings rate ${summary.savingsRate.toStringAsFixed(0)}%',
                  style: AppTextStyles.caption(palette.accent)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${summary.count} transactions',
                  style: AppTextStyles.caption(palette.tertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact budget progress list (top 3).
class BudgetMiniCard extends StatelessWidget {
  const BudgetMiniCard({
    super.key,
    required this.budgets,
    required this.onTapBudget,
    required this.onSeeAll,
  });

  final List<BudgetProgress> budgets;
  final ValueChanged<BudgetProgress> onTapBudget;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (budgets.isEmpty) {
      return AppCard(
        onTap: onSeeAll,
        child: Row(
          children: <Widget>[
            CategoryIcon(icon: Icons.pie_chart_rounded, color: palette.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Create your first budget', style: context.h3),
                  const SizedBox(height: 2),
                  Text('Set a limit and stay on track', style: context.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.tertiary),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: 'Budgets',
            action: 'See all',
            onAction: onSeeAll,
            padding: EdgeInsets.zero,
          ),
          ...budgets.take(3).map((progress) {
            final tone = ProgressBar.colorForRatio(context, progress.ratio);
            return InkWell(
              onTap: () => onTapBudget(progress),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            progress.budget.name,
                            style: AppTextStyles.label(palette.ink),
                          ),
                        ),
                        Text(
                          '${Fmt.money(progress.spent, forceCompact: true)} / ${Fmt.money(progress.amount, forceCompact: true)}',
                          style: AppTextStyles.caption(palette.sub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ProgressBar(value: progress.ratio, color: tone, height: 7),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Recent transactions list card.
class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.onTapTransaction,
    required this.onSeeAll,
  });

  final List<Txn> transactions;
  final Map<int, Account> accounts;
  final Map<int, Category> categories;
  final ValueChanged<Txn> onTapTransaction;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (transactions.isEmpty) {
      return AppCard(
        onTap: onSeeAll,
        child: Row(
          children: <Widget>[
            CategoryIcon(icon: Icons.receipt_long_rounded, color: palette.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No transactions yet — tap to add your first',
                  style: AppTextStyles.body(palette.sub)),
            ),
            Icon(Icons.add_circle_rounded, color: palette.accent),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        children: <Widget>[
          SectionHeader(
            title: 'Recent',
            action: 'See all',
            onAction: onSeeAll,
            padding: EdgeInsets.zero,
          ),
          ...transactions.take(6).map(
                (txn) => TransactionTile(
                  txn: txn,
                  category: categories[txn.categoryId],
                  accountName: accounts[txn.accountId]?.name,
                  toAccountName: accounts[txn.toAccountId]?.name,
                  onTap: () => onTapTransaction(txn),
                  dense: true,
                ),
              ),
        ],
      ),
    );
  }
}

/// Monthly category donut with legend.
class SpendingDonutCard extends StatelessWidget {
  const SpendingDonutCard({
    super.key,
    required this.totals,
    required this.onTapCategory,
    this.onSeeAll,
  });

  final List<CategoryTotal> totals;
  final ValueChanged<CategoryTotal> onTapCategory;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final total = totals.fold<int>(0, (sum, item) => sum + item.total);
    if (totals.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Spending by category', style: context.h3),
            const SizedBox(height: 12),
            Text('No expenses yet this month.', style: context.caption),
          ],
        ),
      );
    }

    final top = totals.take(5).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: 'Spending this month',
            action: 'Details',
            onAction: onSeeAll,
            padding: EdgeInsets.zero,
          ),
          Row(
            children: <Widget>[
              SizedBox(
                height: 132,
                width: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 44,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            final index = response?.touchedSection?.touchedSectionIndex ?? -1;
                            if (index >= 0 && index < top.length) {
                              onTapCategory(top[index]);
                            }
                          },
                        ),
                        sections: List<PieChartSectionData>.generate(top.length, (index) {
                          final item = top[index];
                          final share = total == 0 ? 0.0 : item.total / total;
                          return PieChartSectionData(
                            value: item.total.toDouble().clamp(1, double.infinity),
                            color: index == 0
                                ? palette.accent
                                : _parse(item.color).withOpacity(0.85),
                            radius: index == 0 ? 22 : 18,
                            showTitle: share >= 0.12,
                            title: '${(share * 100).round()}%',
                            titleStyle: AppTextStyles.caption(Colors.white)
                                .copyWith(fontSize: 9.5, fontWeight: FontWeight.w600),
                          );
                        }),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('Total', style: AppTextStyles.caption(palette.tertiary)
                            .copyWith(fontSize: 10)),
                        AmountText(total, size: 14, forceCompact: true, weight: FontWeight.w700),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  children: top.map((item) {
                    final share = total == 0 ? 0.0 : item.total / total;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: <Widget>[
                          Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              color: _parse(item.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(palette.sub),
                            ),
                          ),
                          Text(
                            '${(share * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.caption(palette.ink)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parse(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.tryParse(value, radix: 16) ?? 0xFF916CFF);
  }
}

/// Upcoming bills card with a quick "mark as paid" action.
class UpcomingBillsCard extends StatelessWidget {
  const UpcomingBillsCard({
    super.key,
    required this.bills,
    required this.onMarkPaid,
    required this.onSeeAll,
  });

  final List<Bill> bills;
  final ValueChanged<Bill> onMarkPaid;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (bills.isEmpty) {
      return AppCard(
        onTap: onSeeAll,
        child: Row(
          children: <Widget>[
            CategoryIcon(icon: Icons.event_available_rounded, color: palette.warning),
            const SizedBox(width: 12),
            Expanded(child: Text('No upcoming bills', style: context.bodyMuted)),
            Icon(Icons.chevron_right_rounded, color: palette.tertiary),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        children: <Widget>[
          SectionHeader(
            title: 'Upcoming bills',
            action: 'All bills',
            onAction: onSeeAll,
            padding: EdgeInsets.zero,
          ),
          ...bills.map((bill) {
            final overdue = bill.isOverdue;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: <Widget>[
                  CategoryIcon(
                    icon: overdue ? Icons.error_outline_rounded : Icons.calendar_month_rounded,
                    color: overdue ? palette.expense : palette.warning,
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(bill.name, style: AppTextStyles.label(palette.ink)),
                        Text(
                          overdue
                              ? 'Overdue by ${bill.daysUntilDue.abs()} days'
                              : 'Due in ${bill.daysUntilDue} days · ${Fmt.date(bill.dueDate)}',
                          style: AppTextStyles.caption(
                            overdue ? palette.expense : palette.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AmountText(bill.amount, size: 13.5, weight: FontWeight.w600),
                  IconButton(
                    tooltip: 'Mark as paid',
                    onPressed: () => onMarkPaid(bill),
                    icon: Icon(Icons.check_circle_outline_rounded,
                        size: 20, color: palette.income),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Net worth summary card.
class NetWorthCard extends StatelessWidget {
  const NetWorthCard({
    super.key,
    required this.assets,
    required this.liabilities,
    required this.onTap,
  });

  final int assets;
  final int liabilities;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return DarkCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Net worth',
                style: AppTextStyles.label(palette.darkSub),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: palette.darkSub, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          AmountText(assets - liabilities, size: 26, color: Colors.white,
              weight: FontWeight.w700),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: <Widget>[
              _stat(context, 'Assets', assets, palette.income),
              const SizedBox(width: AppSpacing.x5),
              _stat(context, 'Liabilities', liabilities, palette.expense),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, int value, Color tone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(label, style: AppTextStyles.caption(context.c.darkSub)),
          ],
        ),
        const SizedBox(height: 2),
        AmountText(value, size: 13, color: Colors.white, forceCompact: true),
      ],
    );
  }
}

/// Quick actions row.
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({
    super.key,
    required this.onExpense,
    required this.onIncome,
    required this.onTransfer,
    required this.onBill,
    required this.onStats,
  });

  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onTransfer;
  final VoidCallback onBill;
  final VoidCallback onStats;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: QuickActionTile(
              icon: Icons.south_west_rounded,
              label: 'Expense',
              color: palette.expense,
              onTap: onExpense,
            ),
          ),
          Expanded(
            child: QuickActionTile(
              icon: Icons.north_east_rounded,
              label: 'Income',
              color: palette.income,
              onTap: onIncome,
            ),
          ),
          Expanded(
            child: QuickActionTile(
              icon: Icons.swap_horiz_rounded,
              label: 'Transfer',
              color: palette.transfer,
              onTap: onTransfer,
            ),
          ),
          Expanded(
            child: QuickActionTile(
              icon: Icons.receipt_long_rounded,
              label: 'Bill',
              color: palette.warning,
              onTap: onBill,
            ),
          ),
          Expanded(
            child: QuickActionTile(
              icon: Icons.bar_chart_rounded,
              label: 'Stats',
              color: palette.accent,
              onTap: onStats,
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart insight cards.
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.insights});

  final List<Insight> insights;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (insights.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: 'Insights',
            padding: EdgeInsets.zero,
            icon: Icons.auto_awesome_rounded,
          ),
          ...insights.take(3).map((insight) {
            final tone = switch (insight.tone) {
              'positive' => palette.income,
              'negative' => palette.expense,
              'warning' => palette.warning,
              _ => palette.accent,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      color: tone.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.auto_awesome_rounded, size: 13, color: tone),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight.text,
                      style: AppTextStyles.body(palette.sub).copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Monthly spending sparkline used in the net-worth/detail headers.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({super.key, required this.values, this.color, this.height = 44});

  final List<int> values;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (values.isEmpty) return SizedBox(height: height);
    final maxValue = values.reduce(math.max);
    final tone = color ?? palette.accent;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((value) {
          final ratio = maxValue == 0 ? 0.0 : value / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, animated, _) => Container(
                  height: math.max(4, height * animated),
                  decoration: BoxDecoration(
                    color: tone.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
