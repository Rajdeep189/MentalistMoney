import 'dart:math' as math;

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

/// "Analytics" — spending velocity, predictions, trends and anomalies.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  Future<List<Txn>>? _future;
  int _cacheRevision = -1;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final revision = ref.watch(revisionProvider).value;
    if (_future == null || revision != _cacheRevision) {
      _cacheRevision = revision;
      final now = DateTime.now();
      _future = ref.read(transactionRepositoryProvider).query(
            TransactionFilter(
              startDate: DateTime(now.year, now.month - 5, 1),
              sort: 'newest',
            ),
          );
    }
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        backgroundColor: palette.surface,
        titleSpacing: 0,
        title: Text('Analytics', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: 'How this analysis works',
            onPressed: () => _showInfo(context),
            icon: Icon(Icons.info_outline_rounded, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: FutureBuilder<List<Txn>>(
        future: _future,
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Txn>[];
          final data = _AnalyticsData(all, categories);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              40,
            ),
            children: <Widget>[
              _sectionTitle(palette, 'Smart Insights'),
              const SizedBox(height: 10),
              SizedBox(
                height: 168,
                child: data.insights.isEmpty
                    ? PaisaCard(
                        child: Text(
                          'Add more transactions and insights will show up here.',
                          style: AppTextStyles.body(palette.tertiary),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.insights.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) => _InsightCard(
                          insight: data.insights[index],
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              _VelocityCard(data: data),
              const SizedBox(height: 18),
              _sectionTitle(palette, 'Overall Spending'),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SmallStat(
                      label: 'Current Spending',
                      value: Fmt.money(data.monthSpent),
                      note: data.changeLabel,
                      valueTone: palette.expense,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallStat(
                      label: 'Monthly Average',
                      value: Fmt.money(data.monthlyAverage),
                      note: 'Last 6 Months',
                      valueTone: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallStat(
                      label: 'Predicted',
                      value: Fmt.money(data.predicted),
                      note: data.trendingUp ? 'Trending Up' : 'Trending Down',
                      valueTone:
                          data.trendingUp ? palette.expense : palette.income,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _TopCategoriesCard(rows: data.topCategories),
              const SizedBox(height: 18),
              _MonthlyOverviewCard(points: data.monthly),
              const SizedBox(height: 18),
              _PredictionsCard(rows: data.predictions),
              const SizedBox(height: 18),
              _UnusualCard(rows: data.unusual),
              const SizedBox(height: 18),
              _TrendsCard(rows: data.trends),
              const SizedBox(height: 18),
              _DayOfWeekCard(data: data),
              const SizedBox(height: 18),
              const _AboutCard(),
            ],
          );
        },
      ),
    );
  }

  static Widget _sectionTitle(AppPalette palette, String title) => Text(
        title,
        style: AppTextStyles.base(
          size: 19,
          weight: FontWeight.w700,
          height: 1.2,
        ).copyWith(color: palette.ink),
      );

  static Future<void> _showInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Analytics Works',
        intro:
            'Analytics looks at the last six months of income and expense transactions to spot trends, predict spending and flag unusual activity.',
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.speed_rounded,
            title: 'Spending Velocity',
            body:
                'How fast you are spending this month, the weekly burn rate and a projection for the full month.',
          ),
          InfoSection(
            icon: Icons.trending_up_rounded,
            title: 'Predictions',
            body:
                'Weighted averages give recent months more influence, so predictions follow your current habits.',
          ),
          InfoSection(
            icon: Icons.warning_amber_rounded,
            title: 'Unusual Spending',
            body:
                'Transactions far above the normal range for their category are flagged for review.',
          ),
          InfoSection(
            icon: Icons.calendar_view_week_rounded,
            title: 'Day of Week',
            body:
                'See which weekdays cost you the most and whether weekends run cheaper.',
          ),
        ],
      ),
    );
  }
}

class _AnalyticsData {
  _AnalyticsData(List<Txn> txns, List<Category> categories) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final expenses =
        txns.where((t) => t.type == kTypeExpense).toList(growable: false);

    for (final txn in expenses) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn.date);
      if (!date.isBefore(monthStart)) {
        monthSpent += txn.amount;
        if (date.day <= now.day) monthToDatePriorDays += 0;
      } else if (!date.isBefore(lastMonthStart)) {
        lastMonthSpent += txn.amount;
      }
      final key = '${date.year}-${date.month}';
      monthTotals[key] = (monthTotals[key] ?? 0) + txn.amount;
      dayOfWeek[date.weekday - 1] += txn.amount;
      final monthKey = '${date.year}-${date.month}';
      if (!date.isBefore(monthStart)) {
        currentCategory[txn.categoryId ?? 0] =
            (currentCategory[txn.categoryId ?? 0] ?? 0) + txn.amount;
      } else if (!date.isBefore(lastMonthStart)) {
        lastCategory[txn.categoryId ?? 0] =
            (lastCategory[txn.categoryId ?? 0] ?? 0) + txn.amount;
      }
      final catKey = '${txn.categoryId ?? 0}:$monthKey';
      categoryMonth[catKey] = (categoryMonth[catKey] ?? 0) + txn.amount;
    }

    for (final txn in txns) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn.date);
      if (!date.isBefore(monthStart) && txn.type == kTypeExpense) {
        last7.add(txn);
      }
    }

    elapsedDays = now.day;
    daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    remainingDays = math.max(0, daysInMonth - elapsedDays);
    daily = elapsedDays == 0 ? 0 : monthSpent ~/ elapsedDays;
    weeklyBurn = daily * 7;
    predicted = daily * daysInMonth;
    monthlyAverage = monthTotals.isEmpty
        ? 0
        : monthTotals.values.reduce((a, b) => a + b) ~/ monthTotals.length;
    trendingUp = monthSpent > lastMonthSpent;
    final changePct = lastMonthSpent == 0
        ? (monthSpent == 0 ? 0.0 : 100.0)
        : ((monthSpent - lastMonthSpent) / lastMonthSpent) * 100;
    changeLabel =
        '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}% vs last month';

    // Smart insights: biggest increases by category.
    final increases = <_Insight>[];
    final catMap = <int, Category>{for (final c in categories) c.id!: c};
    final keys = <int>{...currentCategory.keys, ...lastCategory.keys};
    final deltas = <MapEntry<int, double>>[];
    for (final key in keys) {
      final cur = currentCategory[key] ?? 0;
      final prev = lastCategory[key] ?? 0;
      if (cur <= 0) continue;
      final pct = prev == 0 ? 100.0 : ((cur - prev) / prev) * 100;
      deltas.add(MapEntry(key, pct));
    }
    deltas.sort((a, b) => b.value.compareTo(a.value));
    for (final entry in deltas.take(3)) {
      if (entry.value <= 20) continue;
      final category = catMap[entry.key];
      final name = category?.name ?? 'Uncategorised';
      final cur = currentCategory[entry.key] ?? 0;
      final prev = lastCategory[entry.key] ?? 0;
      increases.add(
        _Insight(
          title: 'High Spending in $name',
          body:
              'Spending in $name is ${entry.value.round()}% higher than last month.',
          delta: cur - prev,
        ),
      );
    }
    insights = increases;

    final top = <_CategoryRow>[];
    final total = currentCategory.values.fold<int>(0, (a, b) => a + b);
    final sorted = currentCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted.take(5)) {
      final category = catMap[entry.key];
      top.add(
        _CategoryRow(
          name: category?.name ?? 'Uncategorised',
          icon: category?.icon ?? 'category',
          color: category?.color ?? '#C88A5A',
          total: entry.value,
          share: total == 0 ? 0 : entry.value / total,
        ),
      );
    }
    topCategories = top;

    final months = <_MonthPoint>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final value = monthTotals['${month.year}-${month.month}'] ?? 0;
      months.add(
        _MonthPoint(
          label:
              '${DateX.monthShort(month)}/${month.year.toString().substring(2)}',
          total: value,
        ),
      );
    }
    monthly = months;

    final preds = <_Prediction>[];
    final avgByCategory = <int, int>{};
    for (var i = 1; i <= 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      for (final entry in catMap.keys) {
        final value = categoryMonth['${entry}:${month.year}-${month.month}'] ?? 0;
        if (value > 0) {
          avgByCategory[entry] = (avgByCategory[entry] ?? 0) + value ~/ 3;
        }
      }
    }
    final predEntries = avgByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in predEntries.take(10)) {
      final category = catMap[entry.key];
      if (category == null) continue;
      final average = entry.value;
      final projected = average == 0 ? 0 : (average * 1.1).round();
      preds.add(
        _Prediction(
          name: category.name,
          color: category.color,
          average: average,
          predicted: projected,
          up: projected >= average,
        ),
      );
    }
    predictions = preds;

    final unusualRows = <_Unusual>[];
    for (final txn in expenses) {
      final catAvg = (categoryMonth['${txn.categoryId ?? 0}:${_monthKey(txn)}'] ?? 0);
      if (catAvg == 0) continue;
      if (txn.amount > catAvg * 0.6 && txn.amount > 100000) {
        unusualRows.add(
          _Unusual(
            txn: txn,
            category: catMap[txn.categoryId ?? 0],
          ),
        );
      }
      if (unusualRows.length >= 12) break;
    }
    unusualRows.sort((a, b) => b.txn.date.compareTo(a.txn.date));
    unusual = unusualRows;

    final trendRows = <_Trend>[];
    for (final entry in sorted.take(6)) {
      final category = catMap[entry.key];
      if (category == null) continue;
      final prev = lastCategory[entry.key] ?? 0;
      final pct = prev == 0 ? 100.0 : ((entry.value - prev) / prev) * 100;
      trendRows.add(
        _Trend(
          category: category,
          total: entry.value,
          count: txns
              .where((t) =>
                  t.categoryId == entry.key &&
                  t.type == kTypeExpense &&
                  DateTime.fromMillisecondsSinceEpoch(t.date)
                      .isAfter(monthStart.subtract(const Duration(seconds: 1))))
              .length,
          percent: pct,
        ),
      );
    }
    trends = trendRows;

    weekend = (dayOfWeek[5] + dayOfWeek[6]);
    weekday = dayOfWeek[0] +
        dayOfWeek[1] +
        dayOfWeek[2] +
        dayOfWeek[3] +
        dayOfWeek[4];
    var peakIndex = 0;
    for (var i = 1; i < 7; i++) {
      if (dayOfWeek[i] > dayOfWeek[peakIndex]) peakIndex = i;
    }
    peakDay = _dayNames[peakIndex];
    var lowIndex = 0;
    for (var i = 1; i < 7; i++) {
      if (dayOfWeek[i] < dayOfWeek[lowIndex]) lowIndex = i;
    }
    lowestDay = _dayNames[lowIndex];
  }

  static const List<String> _dayNames = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String _monthKey(Txn txn) {
    final date = DateTime.fromMillisecondsSinceEpoch(txn.date);
    return '${date.year}-${date.month}';
  }

  final Map<String, int> monthTotals = <String, int>{};
  final Map<int, int> currentCategory = <int, int>{};
  final Map<int, int> lastCategory = <int, int>{};
  final Map<String, int> categoryMonth = <String, int>{};
  final List<int> dayOfWeek = List<int>.filled(7, 0);
  final List<Txn> last7 = <Txn>[];

  int monthSpent = 0;
  int lastMonthSpent = 0;
  int monthToDatePriorDays = 0;
  int elapsedDays = 1;
  int daysInMonth = 30;
  int remainingDays = 0;
  int daily = 0;
  int weeklyBurn = 0;
  int predicted = 0;
  int monthlyAverage = 0;
  bool trendingUp = true;
  String changeLabel = '';
  List<_Insight> insights = <_Insight>[];
  List<_CategoryRow> topCategories = <_CategoryRow>[];
  List<_MonthPoint> monthly = <_MonthPoint>[];
  List<_Prediction> predictions = <_Prediction>[];
  List<_Unusual> unusual = <_Unusual>[];
  List<_Trend> trends = <_Trend>[];
  int weekend = 0;
  int weekday = 0;
  String peakDay = '—';
  String lowestDay = '—';
}

class _Insight {
  const _Insight({required this.title, required this.body, required this.delta});
  final String title;
  final String body;
  final int delta;
}

class _CategoryRow {
  const _CategoryRow({
    required this.name,
    required this.icon,
    required this.color,
    required this.total,
    required this.share,
  });
  final String name;
  final String icon;
  final String color;
  final int total;
  final double share;
}

class _MonthPoint {
  const _MonthPoint({required this.label, required this.total});
  final String label;
  final int total;
}

class _Prediction {
  const _Prediction({
    required this.name,
    required this.color,
    required this.average,
    required this.predicted,
    required this.up,
  });
  final String name;
  final String color;
  final int average;
  final int predicted;
  final bool up;
}

class _Unusual {
  const _Unusual({required this.txn, required this.category});
  final Txn txn;
  final Category? category;
}

class _Trend {
  const _Trend({
    required this.category,
    required this.total,
    required this.count,
    required this.percent,
  });
  final Category category;
  final int total;
  final int count;
  final double percent;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF6C453);
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2109),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: amber.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: amber.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    size: 19, color: amber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.base(
                    size: 15,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ).copyWith(color: amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              insight.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(Colors.white.withOpacity(0.82))
                  .copyWith(fontSize: 13.5, height: 1.35),
            ),
          ),
          Row(
            children: <Widget>[
              const Icon(Icons.arrow_upward_rounded,
                  size: 15, color: Color(0xFFFB6B6B)),
              const SizedBox(width: 4),
              Text(
                Fmt.money(insight.delta.abs()),
                style: AppTextStyles.base(
                  size: 13.5,
                  weight: FontWeight.w600,
                  height: 1.2,
                ).copyWith(color: const Color(0xFFFB6B6B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VelocityCard extends StatelessWidget {
  const _VelocityCard({required this.data});

  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return PaisaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Spending Velocity',
                style: AppTextStyles.base(
                  size: 19,
                  weight: FontWeight.w600,
                  height: 1.2,
                ).copyWith(color: palette.ink),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5C),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.remove_rounded,
                        size: 14, color: Color(0xFF7FB4F5)),
                    const SizedBox(width: 4),
                    Text(
                      'Steady',
                      style: AppTextStyles.base(
                        size: 13,
                        weight: FontWeight.w600,
                        height: 1,
                      ).copyWith(color: const Color(0xFF7FB4F5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                Fmt.money(data.daily),
                style: AppTextStyles.base(
                  size: 34,
                  weight: FontWeight.w700,
                  height: 1.05,
                  letterSpacing: -0.6,
                ).copyWith(color: palette.accent),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/daily',
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w400,
                    height: 1.1,
                  ).copyWith(color: palette.sub),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Text(
                '${data.elapsedDays} days elapsed',
                style: AppTextStyles.body(palette.sub).copyWith(fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${data.remainingDays} days remaining',
                style: AppTextStyles.body(palette.sub).copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (data.daysInMonth == 0
                  ? 0
                  : data.elapsedDays / data.daysInMonth),
              minHeight: 7,
              backgroundColor: palette.divider,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Last 7 Days',
            style: AppTextStyles.body(palette.sub).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: CustomPaint(
              painter: _AreaPainter(
                values: _lastSeven(data),
                line: palette.accent,
                fill: palette.accent.withOpacity(0.25),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: palette.divider.withOpacity(0.4), height: 1),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniFigure(
                  label: 'Weekly Burn Rate',
                  value: Fmt.money(data.weeklyBurn),
                ),
              ),
              Expanded(
                child: _MiniFigure(
                  label: 'Projected Monthly',
                  value: Fmt.money(data.predicted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<double> _lastSeven(_AnalyticsData data) {
    final now = DateTime.now();
    final values = List<double>.filled(7, 0);
    for (final txn in data.last7) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn.date);
      final diff = now.difference(DateTime(date.year, date.month, date.day)).inDays;
      if (diff >= 0 && diff < 7) {
        values[6 - diff] += txn.amount / 100;
      }
    }
    return values;
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.label,
    required this.value,
    required this.note,
    required this.valueTone,
  });

  final String label;
  final String value;
  final String note;
  final Color valueTone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.divider.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.base(
              size: 13.5,
              weight: FontWeight.w500,
              height: 1.15,
            ).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.base(
                size: 17,
                weight: FontWeight.w700,
                height: 1.1,
              ).copyWith(color: valueTone),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.base(
              size: 12.5,
              weight: FontWeight.w400,
              height: 1.15,
            ).copyWith(color: palette.sub),
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({required this.rows});

  final List<_CategoryRow> rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return PaisaCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Top categories',
            style: AppTextStyles.base(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: palette.accent),
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.fromHex(row.color),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      AppIcons.byName(row.icon, fallback: Icons.category_rounded),
                      size: 23,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.base(
                            size: 17.5,
                            weight: FontWeight.w500,
                            height: 1.2,
                          ).copyWith(color: palette.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(row.share * 100).toStringAsFixed(1)}% of total',
                          style: AppTextStyles.base(
                            size: 14,
                            weight: FontWeight.w400,
                            height: 1.2,
                          ).copyWith(color: palette.sub),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Fmt.money(row.total),
                    style: AppTextStyles.base(
                      size: 16,
                      weight: FontWeight.w600,
                      height: 1.1,
                    ).copyWith(color: palette.ink),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthlyOverviewCard extends StatelessWidget {
  const _MonthlyOverviewCard({required this.points});

  final List<_MonthPoint> points;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return PaisaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Monthly Overview',
            style: AppTextStyles.base(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: palette.accent),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _LinePainter(
                values: points.map((p) => p.total.toDouble()).toList(),
                labels: points.map((p) => p.label).toList(),
                line: palette.accent,
                grid: palette.divider,
                text: palette.tertiary,
                style: AppTextStyles.base(
                  size: 10.5,
                  weight: FontWeight.w400,
                  height: 1.1,
                ).copyWith(color: palette.tertiary),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionsCard extends StatelessWidget {
  const _PredictionsCard({required this.rows});

  final List<_Prediction> rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return PaisaCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Spending Predictions',
            style: AppTextStyles.base(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: palette.accent),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Not enough history to predict spending yet.',
                style: AppTextStyles.body(palette.tertiary),
              ),
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            row.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.base(
                              size: 17,
                              weight: FontWeight.w700,
                              height: 1.2,
                            ).copyWith(color: AppColors.fromHex(row.color)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Average Spending: ${Fmt.money(row.average)}',
                            style: AppTextStyles.base(
                              size: 14.5,
                              weight: FontWeight.w400,
                              height: 1.25,
                            ).copyWith(color: palette.sub),
                          ),
                          Text(
                            'Predicted: ${Fmt.money(row.predicted)}',
                            style: AppTextStyles.base(
                              size: 14.5,
                              weight: FontWeight.w400,
                              height: 1.25,
                            ).copyWith(color: palette.sub),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      row.up
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 22,
                      color: row.up ? palette.expense : palette.income,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _UnusualCard extends StatelessWidget {
  const _UnusualCard({required this.rows});

  final List<_Unusual> rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return PaisaCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Unusual Spending',
            style: AppTextStyles.base(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: palette.accent),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Nothing unusual — your spending looks consistent.',
                style: AppTextStyles.body(palette.tertiary),
              ),
            )
          else
            for (final row in rows.take(10))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.fromHex(
                            row.category?.color ?? '#3B82F6'),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        AppIcons.byName(row.category?.icon,
                            fallback: Icons.show_chart_rounded),
                        size: 23,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            row.txn.note?.trim().isNotEmpty == true
                                ? row.txn.note!.trim()
                                : (row.category?.name ?? 'Transaction'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.base(
                              size: 16.5,
                              weight: FontWeight.w500,
                              height: 1.2,
                            ).copyWith(
                              color: AppColors.fromHex(
                                  row.category?.color ?? '#3B82F6'),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Amount: ${Fmt.money(row.txn.amount)}',
                            style: AppTextStyles.base(
                              size: 14.5,
                              weight: FontWeight.w400,
                              height: 1.2,
                            ).copyWith(color: palette.sub),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Fmt.date(row.txn.date),
                      style: AppTextStyles.base(
                        size: 13.5,
                        weight: FontWeight.w400,
                        height: 1.2,
                      ).copyWith(color: palette.sub),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TrendsCard extends StatelessWidget {
  const _TrendsCard({required this.rows});

  final List<_Trend> rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return PaisaCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Category Trends',
            style: AppTextStyles.base(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: palette.accent),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.fromHex(row.category.color),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      AppIcons.byName(row.category.icon,
                          fallback: Icons.category_rounded),
                      size: 23,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          row.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.base(
                            size: 16.5,
                            weight: FontWeight.w500,
                            height: 1.2,
                          ).copyWith(color: palette.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${row.count} transactions this period',
                          style: AppTextStyles.base(
                            size: 14,
                            weight: FontWeight.w400,
                            height: 1.2,
                          ).copyWith(color: palette.sub),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 4,
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: palette.expense,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        Fmt.money(row.total),
                        style: AppTextStyles.base(
                          size: 15.5,
                          weight: FontWeight.w600,
                          height: 1.1,
                        ).copyWith(color: palette.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${row.percent >= 0 ? '↑' : '↓'}${row.percent.abs().round()}%',
                        style: AppTextStyles.base(
                          size: 13.5,
                          weight: FontWeight.w500,
                          height: 1.1,
                        ).copyWith(
                          color: row.percent >= 0
                              ? palette.expense
                              : palette.income,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayOfWeekCard extends StatelessWidget {
  const _DayOfWeekCard({required this.data});

  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final max = data.dayOfWeek.reduce((a, b) => a > b ? a : b);
    final weekendLower = data.weekend < data.weekday;
    return PaisaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Spending by Day of Week',
            style: AppTextStyles.base(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: palette.accent),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: max == 0 ? 0 : data.dayOfWeek[i] / max,
                            ),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => Container(
                              height: 20 + (80 * value),
                              decoration: BoxDecoration(
                                color: palette.accent
                                    .withOpacity(i == 6 ? 0.55 : 0.85),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _short[i],
                            style: AppTextStyles.base(
                              size: 12.5,
                              weight: FontWeight.w400,
                              height: 1.1,
                            ).copyWith(color: palette.sub),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: palette.divider.withOpacity(0.4), height: 1),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _DayStat(
                  icon: Icons.trending_up_rounded,
                  label: 'Peak Spending Day',
                  value: data.peakDay,
                  tone: const Color(0xFFFB6B6B),
                ),
              ),
              Expanded(
                child: _DayStat(
                  icon: Icons.trending_down_rounded,
                  label: 'Lowest Spending Day',
                  value: data.lowestDay,
                  tone: const Color(0xFF3DDC97),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Weekend Spending',
                      style: AppTextStyles.body(palette.sub)
                          .copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Fmt.money(data.weekend),
                      style: AppTextStyles.base(
                        size: 16,
                        weight: FontWeight.w600,
                        height: 1.1,
                      ).copyWith(color: palette.ink),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14351F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  data.weekday == 0
                      ? 'No weekday spend'
                      : weekendLower
                          ? '${((data.weekday - data.weekend) / data.weekday * 100).round()}% lower on\nweekends'
                          : '${((data.weekend - data.weekday) / data.weekday * 100).round()}% higher on\nweekends',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.base(
                    size: 13,
                    weight: FontWeight.w500,
                    height: 1.25,
                  ).copyWith(color: const Color(0xFF6BD6A0)),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Weekday Spending',
                      style: AppTextStyles.body(palette.sub)
                          .copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Fmt.money(data.weekday),
                      style: AppTextStyles.base(
                        size: 16,
                        weight: FontWeight.w600,
                        height: 1.1,
                      ).copyWith(color: palette.ink),
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

  static const List<String> _short = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
}

class _DayStat extends StatelessWidget {
  const _DayStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      children: <Widget>[
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: tone.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: tone),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: AppTextStyles.base(
                size: 12.5,
                weight: FontWeight.w400,
                height: 1.2,
              ).copyWith(color: palette.sub),
            ),
            Text(
              value,
              style: AppTextStyles.base(
                size: 16,
                weight: FontWeight.w600,
                height: 1.2,
              ).copyWith(color: palette.ink),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniFigure extends StatelessWidget {
  const _MiniFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.body(palette.sub).copyWith(fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.base(
            size: 17,
            weight: FontWeight.w600,
            height: 1.15,
          ).copyWith(color: palette.ink),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    const body = <String>[
      'Calculation Method:',
      '• Analysis based on last 6 months of transactions',
      '• Transfer transactions are excluded',
      '• Predictions use weighted averages (recent months have higher influence)',
      '• Anomalies are detected using statistical analysis',
      '',
      'Limitations:',
      '• Predictions may not account for upcoming irregular expenses',
      '• Historical patterns might not reflect future spending',
      '• Seasonal variations might affect accuracy',
      '• Limited data history may impact prediction accuracy',
      '',
      'Weight Distribution:',
      '• Current month: 30% influence',
      '• Last month: 25% influence',
      '• 2 months ago: 20% influence',
      '• 3 months ago: 15% influence',
      '• 4-5 months ago: 5% each',
    ];
    return PaisaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'About This Analysis',
            style: AppTextStyles.base(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: palette.accent),
          ),
          const SizedBox(height: 8),
          for (final line in body)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                line,
                style: AppTextStyles.base(
                  size: 14.5,
                  weight: line.endsWith(':')
                      ? FontWeight.w600
                      : FontWeight.w400,
                  height: 1.35,
                ).copyWith(color: palette.sub),
              ),
            ),
        ],
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter({
    required this.values,
    required this.line,
    required this.fill,
  });

  final List<double> values;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final max = values.reduce((a, b) => a > b ? a : b);
    final top = max <= 0 ? 1.0 : max;
    final path = Path();
    final area = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (size.height * (values[i] / top) * 0.85) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }
    area.lineTo(size.width, size.height);
    area.close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(_AreaPainter old) => old.values != values;
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.labels,
    required this.line,
    required this.grid,
    required this.text,
    required this.style,
  });

  final List<double> values;
  final List<String> labels;
  final Color line;
  final Color grid;
  final Color text;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 40.0;
    const bottom = 22.0;
    final width = size.width - left;
    final height = size.height - bottom;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final max = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final gridPaint = Paint()
      ..color = grid.withOpacity(0.5)
      ..strokeWidth = 1;
    final labelStyle = style.copyWith(color: text);
    for (var i = 0; i <= 3; i++) {
      final y = height - (height * i / 3);
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      final painter = TextPainter(
        text: TextSpan(
          text: Fmt.money((max * i / 3).round(), forceCompact: true),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }
    final path = Path();
    final dots = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = left + (width * i / (values.length - 1));
      final y = height - (height * 0.85 * (values[i] / max)) - 6;
      dots.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    for (final dot in dots) {
      canvas.drawCircle(dot, 4, Paint()..color = line);
    }
    for (var i = 0; i < labels.length; i++) {
      final x = left + (width * i / (labels.length - 1));
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x - painter.width / 2, height + 6));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values;
}
