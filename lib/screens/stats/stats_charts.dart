import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../widgets/progress_widgets.dart';

/// Donut chart with a centred total.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.totals,
    required this.total,
    this.size = 150,
    this.onTap,
    this.centerLabel = 'Total',
  });

  final List<CategoryTotal> totals;
  final int total;
  final double size;
  final ValueChanged<CategoryTotal>? onTap;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (totals.isEmpty) {
      return SizedBox(
        height: size,
        child: Center(child: Text('No data for this period', style: context.caption)),
      );
    }
    return SizedBox(
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: size * 0.30,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final index = response?.touchedSection?.touchedSectionIndex ?? -1;
                  if (index >= 0 && index < totals.length && onTap != null) {
                    onTap!(totals[index]);
                  }
                },
              ),
              sections: List<PieChartSectionData>.generate(totals.length, (index) {
                final item = totals[index];
                final color = index == 0
                    ? palette.accent
                    : AppColors.fromHex(item.color).withOpacity(0.85);
                return PieChartSectionData(
                  value: math.max(1, item.total).toDouble(),
                  color: color,
                  radius: index == 0 ? size * 0.17 : size * 0.14,
                  showTitle: false,
                );
              }),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(centerLabel, style: context.caption),
              Text(
                Fmt.money(total, forceCompact: true),
                style: AppTextStyles.money(16, color: palette.ink, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vertical bar chart for daily totals.
class DailyBarChart extends StatelessWidget {
  const DailyBarChart({
    super.key,
    required this.days,
    this.height = 160,
    this.color,
    this.highlightMax = true,
  });

  final List<DayTotal> days;
  final double height;
  final Color? color;
  final bool highlightMax;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (days.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('No expenses in this period', style: context.caption)),
      );
    }
    final maxValue = days.map((d) => d.total).reduce(math.max);
    final maxIndex = days.indexWhere((d) => d.total == maxValue);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue == 0 ? 1 : maxValue / 3,
            getDrawingHorizontalLine: (value) => FlLine(
              color: palette.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: math.max(1, (days.length / 6).floorToDouble()),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${days[index].day.day}',
                      style: AppTextStyles.caption(palette.tertiary).copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List<BarChartGroupData>.generate(
            days.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: days[index].total / 100,
                  width: days.length > 24 ? 4 : 9,
                  color: highlightMax && index == maxIndex
                      ? palette.expense
                      : (color ?? palette.accent).withOpacity(0.75),
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Line chart for trends (income vs expense).
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.income,
    required this.expense,
    this.labels = const <String>[],
    this.height = 170,
  });

  final List<int> income;
  final List<int> expense;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (income.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('Not enough data yet', style: context.caption)),
      );
    }
    final maxValue = <int>[...income, ...expense].reduce(math.max);

    List<FlSpot> spots(List<int> values) => List<FlSpot>.generate(
          values.length,
          (index) => FlSpot(index.toDouble(), values[index] / 100),
        );

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxValue == 0 ? 100 : maxValue / 100 * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: palette.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[index],
                      style: AppTextStyles.caption(palette.tertiary).copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => palette.ink,
              getTooltipItems: (spots) => spots
                  .map(
                    (spot) => LineTooltipItem(
                      Fmt.money((spot.y * 100).round(), forceCompact: true),
                      AppTextStyles.caption(Colors.white),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: spots(income),
              isCurved: true,
              curveSmoothness: 0.25,
              color: palette.income,
              barWidth: 2.6,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: palette.income.withOpacity(0.10),
              ),
            ),
            LineChartBarData(
              spots: spots(expense),
              isCurved: true,
              curveSmoothness: 0.25,
              color: palette.expense,
              barWidth: 2.6,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: palette.expense.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped bars (income vs expense per month).
class GroupedBarChart extends StatelessWidget {
  const GroupedBarChart({
    super.key,
    required this.months,
    this.height = 170,
  });

  final List<MonthTotal> months;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (months.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('Not enough data yet', style: context.caption)),
      );
    }
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateXShort.month(months[index].month),
                      style: AppTextStyles.caption(palette.tertiary).copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List<BarChartGroupData>.generate(
            months.length,
            (index) => BarChartGroupData(
              x: index,
              barsSpace: 3,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: months[index].income / 100,
                  width: 8,
                  color: palette.income,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: months[index].expense / 100,
                  width: 8,
                  color: palette.expense,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DateXShort {
  DateXShort._();

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String month(DateTime date) => _months[date.month - 1];
}

/// Horizontal ranking rows with progress bars.
class RankedBars extends StatelessWidget {
  const RankedBars({
    super.key,
    required this.totals,
    this.max = 6,
    this.onTap,
  });

  final List<CategoryTotal> totals;
  final int max;
  final ValueChanged<CategoryTotal>? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (totals.isEmpty) {
      return Text('No categories to show', style: context.caption);
    }
    final grandTotal = totals.fold<int>(0, (sum, item) => sum + item.total);
    return Column(
      children: totals.take(max).map((item) {
        final share = grandTotal == 0 ? 0.0 : item.total / grandTotal;
        final color = AppColors.fromHex(item.color);
        return InkWell(
          onTap: onTap == null ? null : () => onTap!(item),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(palette.ink)),
                    ),
                    Text(
                      Fmt.money(item.total, forceCompact: true),
                      style: AppTextStyles.money(13, color: palette.ink,
                          weight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${(share * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: context.caption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressBar(value: share, color: color, height: 6),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Calendar heatmap of daily spending.
class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({
    super.key,
    required this.month,
    required this.days,
    this.onTapDay,
  });

  final DateTime month;
  final List<DayTotal> days;
  final ValueChanged<DateTime>? onTapDay;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final totals = <int, int>{
      for (final day in days) day.day.day: day.total,
    };
    final maxValue = days.isEmpty ? 0 : days.map((d) => d.total).reduce(math.max);
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = (firstOfMonth.weekday + 6) % 7; // Monday-first grid

    const weekLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: <Widget>[
        Row(
          children: weekLabels
              .map((label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: AppTextStyles.caption(palette.tertiary)
                            .copyWith(fontSize: 10),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leading + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index < leading) return const SizedBox.shrink();
            final dayNumber = index - leading + 1;
            final value = totals[dayNumber] ?? 0;
            final intensity = maxValue == 0 ? 0.0 : value / maxValue;
            final date = DateTime(month.year, month.month, dayNumber);
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 220 + index * 12),
              builder: (context, animated, _) => GestureDetector(
                onTap: onTapDay == null ? null : () => onTapDay!(date),
                child: Opacity(
                  opacity: animated.clamp(0.0, 1.0).toDouble(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: value == 0
                          ? (palette.isDark ? palette.cardAlt : palette.surfaceAlt)
                          : palette.accent.withOpacity(0.15 + intensity * 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: AppTextStyles.caption(
                        intensity > 0.55 ? Colors.white : palette.sub,
                      ).copyWith(fontSize: 10.5),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text('Less', style: AppTextStyles.caption(palette.tertiary).copyWith(fontSize: 9)),
            const SizedBox(width: 6),
            for (final opacity in <double>[0.15, 0.35, 0.55, 0.75, 0.95])
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: palette.accent.withOpacity(opacity),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Text('More', style: AppTextStyles.caption(palette.tertiary).copyWith(fontSize: 9)),
          ],
        ),
      ],
    );
  }
}

/// Legend dot used by chart cards.
class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: context.caption),
      ],
    );
  }
}

/// Comparison row: this period vs previous period.
class ComparisonRow extends StatelessWidget {
  const ComparisonRow({
    super.key,
    required this.label,
    required this.current,
    required this.previous,
  });

  final String label;
  final int current;
  final int previous;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final change = previous == 0 ? 0.0 : ((current - previous) / previous) * 100;
    final up = change > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: AppTextStyles.body(palette.ink))),
          Text(Fmt.money(current, forceCompact: true),
              style: AppTextStyles.money(13, color: palette.ink, weight: FontWeight.w600)),
          const SizedBox(width: 10),
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: previous == 0 ? palette.tertiary : (up ? palette.expense : palette.income),
          ),
          SizedBox(
            width: 44,
            child: Text(
              previous == 0 ? '—' : '${change.abs().toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(
                previous == 0 ? palette.tertiary : (up ? palette.expense : palette.income),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small empty placeholder used inside chart cards.
class ChartEmpty extends StatelessWidget {
  const ChartEmpty({super.key, this.message = 'No data for this period'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.caption(context.c.tertiary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Section spacing helper.
class ChartSection extends StatelessWidget {
  const ChartSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppRadius.card / 4),
      child: child,
    );
  }
}
