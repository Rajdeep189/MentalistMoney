import 'dart:math' as math;

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
import '../../widgets/category_icon.dart';
import '../../widgets/luxe.dart';
import '../../widgets/luxe_charts.dart';
import '../../widgets/transaction_tile.dart';

Color _colorOf(String hex) {
  final parsed = int.tryParse(hex.replaceAll('#', ''), radix: 16);
  return parsed == null ? AppColors.accent : Color(0xFF000000 | parsed);
}

/// Hero: Safe to Spend, on obsidian glass with an aurora wash.
class SafeToSpendCard extends StatelessWidget {
  const SafeToSpendCard({
    super.key,
    required this.safe,
    this.onTap,
    this.hidden = false,
  });

  final SafeToSpend safe;
  final VoidCallback? onTap;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final ratio = safe.budget <= 0 ? 0.0 : (safe.spent / safe.budget);
    final over = safe.remaining < 0;
    final tone = over
        ? AppColors.sunset
        : ratio > 0.85
            ? AppColors.gold
            : AppColors.limeB;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge + 4),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(palette.isDark ? 0.55 : 0.22),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge + 4),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFF1B1C22),
                        Color(0xFF101014),
                        Color(0xFF08080A),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: AuroraBackground(
                  child: const SizedBox.expand(),
                  intensity: 0.9,
                ),
              ),
              Positioned.fill(
                child: ShineSweep(
                  period: const Duration(milliseconds: 5000),
                  opacity: 0.22,
                  child: const SizedBox.expand(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Eyebrow('Safe to spend',
                            color: Color(0xFF9C9CA6)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tone.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: tone.withOpacity(0.35)),
                          ),
                          child: Text(
                            over ? 'Over budget' : 'On track',
                            style: AppTextStyles.caption(tone)
                                .copyWith(fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    hidden
                        ? Text(
                            '••••••',
                            style: AppTextStyles.serif(
                              size: 40,
                              color: Colors.white,
                            ),
                          )
                        : AnimatedAmountText(
                            safe.remaining,
                            size: 40,
                            weight: FontWeight.w400,
                            color: over ? AppColors.darkExpense : Colors.white,
                          ),
                    const SizedBox(height: 6),
                    Text(
                      hidden
                          ? 'Amounts hidden for privacy'
                          : 'Spend up to ${Fmt.money(safe.perDay)} a day and stay on plan.',
                      style: AppTextStyles.caption(const Color(0xFF9C9CA6)),
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(
                        children: <Widget>[
                          Container(
                            height: 8,
                            color: Colors.white.withOpacity(0.10),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio.clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    tone.withOpacity(0.7),
                                    tone,
                                  ],
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: tone.withOpacity(0.6),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    Row(
                      children: <Widget>[
                        _HeroStat(label: 'Budget', value: safe.budget),
                        _heroDivider(),
                        _HeroStat(label: 'Spent', value: safe.spent),
                        _heroDivider(),
                        _HeroStat(label: 'Bills', value: safe.upcomingBills),
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

  Widget _heroDivider() => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        color: Colors.white.withOpacity(0.10),
      );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTextStyles.overline(const Color(0xFF7C7C86))
                .copyWith(fontSize: 8.5, letterSpacing: 1.1),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.money(value, forceCompact: true),
              style: AppTextStyles.serif(size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Month cash-flow card modelled on the "Total spend" reference panels.
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
    final delta = previous.expense <= 0
        ? 0.0
        : (summary.expense - previous.expense) / previous.expense * 100;
    final total = math.max(summary.income, summary.expense).toDouble();

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Eyebrow('This month'),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        AmountText(
                          summary.expense,
                          size: 26,
                          weight: FontWeight.w400,
                          hideable: true,
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            delta == 0
                                ? 'vs last month'
                                : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
                            style: AppTextStyles.caption(
                              delta <= 0 ? palette.income : palette.expense,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _Sparkline(
                values: <double>[
                  previous.expense.toDouble().clamp(1, double.infinity),
                  summary.expense.toDouble().clamp(1, double.infinity),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          _LegendBar(
            label: 'Income',
            amount: summary.income,
            color: AppColors.limeB,
            fraction: total <= 0 ? 0 : summary.income / total,
          ),
          const SizedBox(height: 10),
          _LegendBar(
            label: 'Expense',
            amount: summary.expense,
            color: AppColors.sunset,
            fraction: total <= 0 ? 0 : summary.expense / total,
          ),
          const SizedBox(height: AppSpacing.x4),
          Row(
            children: <Widget>[
              _pill(
                context,
                Icons.savings_outlined,
                'Saved ${summary.savingsRate.toStringAsFixed(0)}%',
              ),
              const SizedBox(width: 8),
              _pill(
                context,
                Icons.receipt_long_outlined,
                '${summary.count} entries',
              ),
              const Spacer(),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_outward_rounded,
                    size: 15, color: palette.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: palette.sub),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption(palette.sub)
                .copyWith(fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _LegendBar extends StatelessWidget {
  const _LegendBar({
    required this.label,
    required this.amount,
    required this.color,
    required this.fraction,
  });

  final String label;
  final int amount;
  final Color color;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      children: <Widget>[
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 58,
          child: Text(label, style: AppTextStyles.caption(palette.sub)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: <Widget>[
                Container(
                  height: 8,
                  color: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.02, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[color.withOpacity(0.55), color],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          Fmt.money(amount, forceCompact: true),
          style: AppTextStyles.label(palette.ink).copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return SizedBox(
      height: 40,
      width: 62,
      child: CustomPaint(
        painter: _SparkPainter(values: values, color: palette.accent),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce(math.max);
    if (maxV <= 0) return;
    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * (i / math.max(1, values.length - 1)),
          size.height - (values[i] / maxV) * (size.height - 6) - 3,
        ),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    canvas.drawCircle(pts.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values;
}

/// Compact budget list with lime→sunset progress rails.
class BudgetMiniCard extends StatelessWidget {
  const BudgetMiniCard({
    super.key,
    required this.budgets,
    this.onTapBudget,
    this.onSeeAll,
  });

  final List<BudgetProgress> budgets;
  final ValueChanged<BudgetProgress>? onTapBudget;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final visible = budgets.take(3).toList();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x4,
        AppSpacing.x5,
        AppSpacing.x3,
      ),
      child: Column(
        children: <Widget>[
          SectionHeading(
            title: 'Budgets',
            eyebrow: 'On the way',
            actionLabel: 'All',
            onAction: onSeeAll,
            padding: const EdgeInsets.only(bottom: AppSpacing.x3),
          ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
              child: Text(
                'No budgets yet — create one to track your pace.',
                style: AppTextStyles.caption(palette.sub),
              ),
            ),
          for (final progress in visible)
            InkWell(
              onTap: onTapBudget == null ? null : () => onTapBudget!(progress),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          height: 26,
                          width: 26,
                          decoration: BoxDecoration(
                            color: _colorOf(progress.budget.color)
                                .withOpacity(palette.isDark ? 0.26 : 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.pie_chart_rounded,
                            size: 13,
                            color: _colorOf(progress.budget.color),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            progress.budget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label(palette.ink)
                                .copyWith(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${progress.percent.toStringAsFixed(0)}%',
                          style: AppTextStyles.serif(
                            size: 14,
                            color: progress.isOver
                                ? palette.expense
                                : palette.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(
                        children: <Widget>[
                          Container(
                            height: 6,
                            color: palette.isDark
                                ? palette.cardAlt
                                : palette.surfaceAlt,
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.ratio.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: progress.ratio > 1
                                    ? AppColors.sunsetGradient
                                    : AppColors.limeGradient,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: (progress.ratio > 1
                                            ? AppColors.sunset
                                            : AppColors.limeB)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
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
                        Text(
                          '${Fmt.money(progress.spent, forceCompact: true)} of ${Fmt.money(progress.amount, forceCompact: true)}',
                          style: AppTextStyles.caption(palette.tertiary)
                              .copyWith(fontSize: 10.5),
                        ),
                        const Spacer(),
                        Text(
                          progress.isOver
                              ? 'Over by ${Fmt.money(progress.spent - progress.amount, forceCompact: true)}'
                              : '${Fmt.money(progress.remaining, forceCompact: true)} left',
                          style: AppTextStyles.caption(
                            progress.isOver ? palette.expense : palette.tertiary,
                          ).copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Recent ledger entries inside a soft card.
class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.categories,
    this.onTapTransaction,
    this.onSeeAll,
  });

  final List<Txn> transactions;
  final Map<int, Account> accounts;
  final Map<int, Category> categories;
  final ValueChanged<Txn>? onTapTransaction;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x4,
        AppSpacing.x5,
        AppSpacing.x2,
      ),
      child: Column(
        children: <Widget>[
          SectionHeading(
            title: 'Latest activity',
            eyebrow: 'Ledger',
            actionLabel: 'See all',
            onAction: onSeeAll,
            padding: const EdgeInsets.only(bottom: AppSpacing.x2),
          ),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x5),
              child: Text(
                'Your story starts with the first entry.',
                style: AppTextStyles.caption(palette.sub),
              ),
            )
          else
            for (var i = 0; i < transactions.length; i++)
              TransactionTile(
                txn: transactions[i],
                category: categories[transactions[i].categoryId],
                accountName: accounts[transactions[i].accountId]?.name,
                toAccountName:
                    accounts[transactions[i].toAccountId]?.name,
                onTap: onTapTransaction == null
                    ? null
                    : () => onTapTransaction!(transactions[i]),
                showDate: true,
                showDivider: i != transactions.length - 1,
                dense: true,
              ),
        ],
      ),
    );
  }
}

/// Petal donut spending breakdown.
class SpendingDonutCard extends StatelessWidget {
  const SpendingDonutCard({
    super.key,
    required this.totals,
    this.onTapCategory,
    this.onSeeAll,
  });

  final List<CategoryTotal> totals;
  final ValueChanged<CategoryTotal>? onTapCategory;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final top = totals.take(6).toList();
    final sum = top.fold<int>(0, (a, t) => a + t.total);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        children: <Widget>[
          SectionHeading(
            title: 'Where it goes',
            eyebrow: 'Categories',
            actionLabel: 'Explore',
            onAction: onSeeAll,
            padding: const EdgeInsets.only(bottom: AppSpacing.x2),
          ),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x5),
              child: Text(
                'No spending yet this month.',
                style: AppTextStyles.caption(palette.sub),
              ),
            )
          else
            Row(
              children: <Widget>[
                PetalDonut(
                  size: 168,
                  slices: <PetalSlice>[
                    for (final t in top)
                      PetalSlice(
                        value: t.total.toDouble(),
                        color: _colorOf(t.color),
                        label: t.name,
                      ),
                  ],
                  centerValue: Fmt.money(sum, forceCompact: true),
                  centerLabel: 'SPENT',
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      for (final t in top.take(5))
                        InkWell(
                          onTap:
                              onTapCategory == null ? null : () => onTapCategory!(t),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  height: 7,
                                  width: 7,
                                  decoration: BoxDecoration(
                                    color: _colorOf(t.color),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    t.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption(palette.sub)
                                        .copyWith(fontSize: 11),
                                  ),
                                ),
                                Text(
                                  sum == 0
                                      ? '0%'
                                      : '${(t.total / sum * 100).toStringAsFixed(0)}%',
                                  style: AppTextStyles.label(palette.ink)
                                      .copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Bills with a soft date chip.
class UpcomingBillsCard extends StatelessWidget {
  const UpcomingBillsCard({
    super.key,
    required this.bills,
    this.onMarkPaid,
    this.onSeeAll,
  });

  final List<Bill> bills;
  final ValueChanged<Bill>? onMarkPaid;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x4,
        AppSpacing.x5,
        AppSpacing.x3,
      ),
      child: Column(
        children: <Widget>[
          SectionHeading(
            title: 'Bills ahead',
            eyebrow: 'Reminders',
            actionLabel: 'All',
            onAction: onSeeAll,
            padding: const EdgeInsets.only(bottom: AppSpacing.x2),
          ),
          if (bills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
              child: Text(
                'Nothing due soon. Breathe easy.',
                style: AppTextStyles.caption(palette.sub),
              ),
            ),
          for (final bill in bills.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.graphiteGradient,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.event_note_rounded,
                        size: 18, color: AppColors.limeA),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          bill.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label(palette.ink)
                              .copyWith(fontSize: 13.5),
                        ),
                        Text(
                          bill.isOverdue
                              ? 'Overdue'
                              : bill.daysUntilDue == 0
                                  ? 'Due today'
                                  : 'Due in ${bill.daysUntilDue} days',
                          style: AppTextStyles.caption(
                            bill.isOverdue ? palette.expense : palette.tertiary,
                          ).copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  AmountText(bill.amount, size: 13.5),
                  if (onMarkPaid != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Mark paid',
                      onPressed: () => onMarkPaid!(bill),
                      icon: Icon(Icons.check_circle_outline_rounded,
                          size: 19, color: palette.income),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Net worth on a champagne-metal card.
class NetWorthCard extends StatelessWidget {
  const NetWorthCard({
    super.key,
    required this.assets,
    required this.liabilities,
    this.onTap,
  });

  final int assets;
  final int liabilities;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFF7E9C9),
              Color(0xFFD9BC80),
              Color(0xFFB9944F),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.gold.withOpacity(0.38),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ShineSweep(
          period: const Duration(milliseconds: 4200),
          opacity: 0.5,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.diamond_outlined,
                      size: 15, color: Color(0xFF3A2C10)),
                  const SizedBox(width: 6),
                  Text(
                    'NET WORTH',
                    style: AppTextStyles.overline(const Color(0xFF4A3818))
                        .copyWith(fontSize: 9, letterSpacing: 1.4),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded,
                      size: 16, color: Color(0xFF3A2C10)),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Fmt.money(assets - liabilities),
                  style: AppTextStyles.serif(
                    size: 30,
                    color: const Color(0xFF241A06),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  _netStat('Assets', assets, const Color(0xFF1E3D12)),
                  const SizedBox(width: AppSpacing.x5),
                  _netStat('Owed', liabilities, const Color(0xFF5B2118)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _netStat(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline(const Color(0xFF5C4820))
              .copyWith(fontSize: 8.5, letterSpacing: 1),
        ),
        const SizedBox(height: 2),
        Text(
          Fmt.money(value),
          style: AppTextStyles.serif(size: 14, color: color),
        ),
      ],
    );
  }
}

/// Four glass quick actions.
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
    final actions = <_QuickAction>[
      _QuickAction('Expense', Icons.south_west_rounded, AppColors.sunset, onExpense),
      _QuickAction('Income', Icons.north_east_rounded, AppColors.limeB, onIncome),
      _QuickAction('Transfer', Icons.swap_horiz_rounded, AppColors.violet, onTransfer),
      _QuickAction('Bill', Icons.event_note_rounded, AppColors.gold, onBill),
      _QuickAction('Insights', Icons.insights_rounded, AppColors.sky, onStats),
    ];
    return Row(
      children: <Widget>[
        for (var i = 0; i < actions.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSpacing.x2),
          Expanded(child: _QuickTile(action: actions[i])),
        ],
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.color, this.onTap);

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: palette.isDark ? palette.card : palette.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: palette.divider),
        ),
        child: Column(
          children: <Widget>[
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: action.color.withOpacity(palette.isDark ? 0.24 : 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, size: 17, color: action.color),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                action.label,
                style: AppTextStyles.caption(palette.sub)
                    .copyWith(fontSize: 9.5, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editorial insight strip.
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.insights});

  final List<Insight> insights;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (insights.isEmpty) return const SizedBox.shrink();
    final insight = insights.first;
    final tone = switch (insight.tone) {
      'positive' => AppColors.limeB,
      'negative' => AppColors.sunset,
      'warning' => AppColors.gold,
      _ => palette.accent,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        gradient: AppColors.graphiteGradient,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: tone.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 16, color: tone),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'INSIGHT',
                  style: AppTextStyles.overline(const Color(0xFF8A8A94))
                      .copyWith(fontSize: 8.5, letterSpacing: 1.6),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.text,
                  style: AppTextStyles.serif(
                    size: 15,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim bar sparkline, kept for use in other dashboards.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    this.color = AppColors.accent,
    this.height = 48,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (values.isEmpty) return SizedBox(height: height);
    final maxV = values.reduce(math.max);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final v in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: maxV <= 0 ? 2 : (v / maxV) * height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[color, color.withOpacity(0.35)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Category chips row used by the hero section on Home.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({super.key, required this.totals});

  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: totals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final total = totals[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: palette.isDark ? palette.card : Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: palette.divider),
            ),
            child: Row(
              children: <Widget>[
                CategoryIcon(
                  iconName: total.icon,
                  color: _colorOf(total.color),
                  size: 22,
                  iconSize: 11,
                ),
                const SizedBox(width: 7),
                Text(
                  total.name,
                  style: AppTextStyles.caption(palette.sub)
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
