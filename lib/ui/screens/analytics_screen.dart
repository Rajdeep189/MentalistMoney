import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../providers/app_provider.dart';
import '../widgets/heatmap.dart';
import '../widgets/neumorphic.dart';

/// Step 3 — Analytics & habit tracking in deep dark mode:
/// consistency heatmap, streaks, weekly chart and the glowing Bia Analysis card.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    if (!p.loaded) {
      return Container(color: AppColors.darkBg, child: const Center(child: CircularProgressIndicator()));
    }
    final values = p.last7DaysSpending;
    final max = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = max * 1.25;

    return Container(
      color: AppColors.darkBg,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _header(p)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _consistencyCard(p)),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _streakRow(p)),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _chartCard(values, maxY)),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _biaCard(p)),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
      ),
    );
  }

  Widget _header(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistics', style: TextStyle(color: AppColors.darkInk, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                '${formatMonthYear(DateTime.now())} • ${p.loggedDaysLast31}/31 days logged',
                style: const TextStyle(color: AppColors.darkInkSoft, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkLine),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: AppColors.darkInkSoft, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _consistencyCard(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Consistency', style: TextStyle(color: AppColors.darkInk, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.help_outline_rounded, size: 15, color: AppColors.darkInkSoft),
                const Spacer(),
                const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF59C2FF)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${p.consistencyPercent.toStringAsFixed(0)}%',
              style: const TextStyle(color: AppColors.darkInk, fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            HeatmapCalendar(activity: p.activityByDay),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Less', style: TextStyle(color: AppColors.darkInkSoft, fontSize: 10)),
                const SizedBox(width: 5),
                for (final c in [0, 2, 4, 6, 8].map(HeatmapCalendar.cellColor))
                  Container(
                    width: 11,
                    height: 11,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                  ),
                const SizedBox(width: 5),
                const Text('More', style: TextStyle(color: AppColors.darkInkSoft, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakRow(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(child: _streakCard('Current Streak', p.currentStreak, null)),
          const SizedBox(width: 12),
          Expanded(child: _streakCard('Longest Streak', p.longestStreak, p.longestStreakRange)),
        ],
      ),
    );
  }

  Widget _streakCard(String title, int days, String? range) {
    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.darkInkSoft, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.orange, size: 26),
              const SizedBox(width: 6),
              Text('$days', style: const TextStyle(color: AppColors.darkInk, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              const Text('days', style: TextStyle(color: AppColors.darkInkSoft, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          if (range == null)
            Row(
              children: List.generate(
                6,
                (i) => Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkLine),
                  ),
                ),
              ),
            )
          else
            Text(range, style: const TextStyle(color: AppColors.darkInkSoft, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _chartCard(List<double> values, double maxY) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Spending — last 7 days', style: TextStyle(color: AppColors.darkInk, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: maxY <= 0 ? 1 : maxY,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              (i >= 0 && i < dayLabels.length) ? dayLabels[i] : '',
                              style: const TextStyle(color: AppColors.darkInkSoft, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: AppColors.darkLine.withOpacity(0.6),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    values.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF59C2FF), Color(0xFF2E7CF6)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _biaCard(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1B1430), Color(0xFF151923)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.violet.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: AppColors.violet.withOpacity(0.25), blurRadius: 30, spreadRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFB020), size: 20),
                SizedBox(width: 8),
                Text('Bia Analysis', style: TextStyle(color: Color(0xFFFFB020), fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              p.biaInsight,
              style: const TextStyle(color: Color(0xFFC9CEDC), fontSize: 14, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
