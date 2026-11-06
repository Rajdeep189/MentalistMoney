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
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';

/// Batch-5 "Spending health" report: a computed health score with sub-scores,
/// streaks, monthly challenge, per-category report card, habits, heatmap,
/// category trends, savings projection and detected subscriptions.
class SpendingHealthScreen extends ConsumerStatefulWidget {
  const SpendingHealthScreen({super.key});

  @override
  ConsumerState<SpendingHealthScreen> createState() =>
      _SpendingHealthScreenState();
}

class _SpendingHealthScreenState extends ConsumerState<SpendingHealthScreen> {
  Future<List<Txn>>? _future;
  String _cacheKey = '';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final revision = ref.watch(revisionProvider).value;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    final key = 'rev-$revision';
    if (key != _cacheKey) {
      _cacheKey = key;
      _future = ref.read(transactionRepositoryProvider).query(
            TransactionFilter(
              startDate: sixMonthsAgo,
              endDate: DateTime(now.year, now.month + 1, 1),
              sort: 'oldest',
            ),
          );
    }
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};
    final budgets =
        ref.watch(budgetsProvider).valueOrNull ?? const <BudgetProgress>[];

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Spending health', style: AppTextStyles.h2(palette.ink)),
      ),
      body: FutureBuilder<List<Txn>>(
        future: _future,
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Txn>[];
          final model = _HealthModel.build(
            all: all,
            now: now,
            monthStart: monthStart,
            budgets: budgets,
            categories: categories,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              40,
            ),
            children: <Widget>[
              _HealthScoreCard(model: model),
              const SizedBox(height: 14),
              _StreakCard(model: model),
              const SizedBox(height: 14),
              _ChallengeCard(model: model),
              const SizedBox(height: 20),
              PaisaSectionTitle(title: 'Report Card', subtitle: Fmt.monthYear(now.millisecondsSinceEpoch)),
              const SizedBox(height: 10),
              _ReportCard(model: model, categories: categories),
              const SizedBox(height: 20),
              PaisaSectionTitle(
                title: 'Your Habits',
                subtitle: 'Patterns from the last three months',
              ),
              const SizedBox(height: 10),
              _HabitsCards(model: model),
              const SizedBox(height: 20),
              PaisaSectionTitle(
                title: 'Spending Heatmap',
                subtitle: Fmt.monthYear(now.millisecondsSinceEpoch),
              ),
              const SizedBox(height: 10),
              _HeatmapCard(model: model, month: now),
              const SizedBox(height: 20),
              PaisaSectionTitle(
                title: 'Category Health',
                subtitle: 'This month vs last month',
              ),
              const SizedBox(height: 10),
              _CategoryHealthCard(model: model),
              const SizedBox(height: 20),
              _ProjectionCard(model: model),
              const SizedBox(height: 14),
              _SubscriptionCard(model: model),
              const SizedBox(height: 14),
              _CostPerDayCard(model: model, categories: categories),
            ],
          );
        },
      ),
    );
  }
}

class _HealthScore {
  const _HealthScore({
    required this.score,
    required this.label,
    required this.color,
    required this.savings,
    required this.budget,
    required this.trend,
  });

  final int score;
  final String label;
  final Color color;
  final int savings;
  final int budget;
  final int trend;
}

class _CategoryHealth {
  const _CategoryHealth({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.current,
    required this.previous,
    required this.months,
  });

  final int categoryId;
  final String name;
  final String icon;
  final String color;
  final int current;
  final int previous;
  final List<int> months;

  double get change => previous == 0
      ? (current == 0 ? 0 : 1)
      : (current - previous) / previous;

  String get grade {
    if (previous == 0) return 'C';
    if (change <= -0.5) return 'A';
    if (change <= -0.2) return 'B';
    if (change < 0.2) return 'C';
    if (change < 0.6) return 'D';
    return 'F';
  }
}

class _HealthModel {
  _HealthModel({
    required this.health,
    required this.thisMonthExpense,
    required this.thisMonthIncome,
    required this.lastMonthExpense,
    required this.streakDays,
    required this.lastStreakDays,
    required this.averageDaily,
    required this.challengeName,
    required this.challengeSpent,
    required this.challengeTarget,
    required this.categories,
    required this.biggestWeekday,
    required this.biggestWeekdayShare,
    required this.endOfMonthShare,
    required this.dayTotals,
    required this.dayIncome,
    required this.projectionYearEnd,
    required this.monthlySavings,
    required this.subscriptions,
    required this.subscriptionTotal,
    required this.costPerDay,
    required this.yearSaved,
  });

  final _HealthScore health;
  final int thisMonthExpense;
  final int thisMonthIncome;
  final int lastMonthExpense;
  final int streakDays;
  final int lastStreakDays;
  final int averageDaily;
  final String challengeName;
  final int challengeSpent;
  final int challengeTarget;
  final List<_CategoryHealth> categories;
  final String biggestWeekday;
  final double biggestWeekdayShare;
  final double endOfMonthShare;
  final Map<int, int> dayTotals;
  final Map<int, int> dayIncome;
  final int projectionYearEnd;
  final int monthlySavings;
  final List<_Subscription> subscriptions;
  final int subscriptionTotal;
  final int costPerDay;
  final int yearSaved;

  static _HealthModel build({
    required List<Txn> all,
    required DateTime now,
    required DateTime monthStart,
    required List<BudgetProgress> budgets,
    required Map<int, Category> categories,
  }) {
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final daysElapsed = now.day;

    int incomeOf(Iterable<Txn> items) => items
        .where((t) => t.type == kTypeIncome)
        .fold<int>(0, (sum, t) => sum + t.amount);
    int expenseOf(Iterable<Txn> items) => items
        .where((t) => t.type == kTypeExpense)
        .fold<int>(0, (sum, t) => sum + t.amount);

    final thisMonth = all.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.date);
      return !d.isBefore(monthStart);
    }).toList();
    final lastMonth = all.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.date);
      return !d.isBefore(lastMonthStart) && d.isBefore(monthStart);
    }).toList();

    final thisExpense = expenseOf(thisMonth);
    final thisIncome = incomeOf(thisMonth);
    final prevExpense = expenseOf(lastMonth);
    final prevIncome = incomeOf(lastMonth);

    // Savings sub-score (target 20% of income).
    final savingsRate =
        thisIncome == 0 ? 0.0 : (thisIncome - thisExpense) / thisIncome;
    final savings = (savingsRate / 0.2 * 100).clamp(0, 100).round();

    // Budget sub-score: how much of allotted budget is still left.
    var budgetScore = 60;
    if (budgets.isNotEmpty) {
      var total = 0;
      var used = 0;
      for (final budget in budgets) {
        total += budget.budget.amount;
        used += budget.spent.clamp(0, budget.budget.amount);
      }
      if (total > 0) {
        budgetScore = ((1 - used / total) * 100).clamp(0, 100).round();
      }
    }

    // Trend sub-score: pace this month vs last month at the same point.
    var trendScore = 60;
    if (prevExpense > 0) {
      final lastPace = prevExpense * (daysElapsed / 30.0);
      final ratio = lastPace == 0 ? 1.0 : thisExpense / lastPace;
      trendScore = (100 - (ratio - 1) * 100).clamp(0, 100).round();
    }

    final rawScore =
        (savings * 0.45 + budgetScore * 0.30 + trendScore * 0.25).round();
    final score = rawScore.clamp(0, 100);
    final label = score >= 80
        ? 'Excellent'
        : score >= 60
            ? 'Good'
            : score >= 40
                ? 'Fair'
                : 'Needs work';

    // Daily totals for the current month.
    final dayTotals = <int, int>{};
    final dayIncome = <int, int>{};
    for (final txn in thisMonth) {
      final day = DateTime.fromMillisecondsSinceEpoch(txn.date).day;
      if (txn.type == kTypeExpense) {
        dayTotals[day] = (dayTotals[day] ?? 0) + txn.amount;
      } else if (txn.type == kTypeIncome) {
        dayIncome[day] = (dayIncome[day] ?? 0) + txn.amount;
      }
    }
    final averageDaily = daysElapsed == 0 ? 0 : thisExpense ~/ daysElapsed;

    // Spending streak: consecutive days at or below the daily average.
    var streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    while (true) {
      final day = cursor.day;
      final sameMonth = cursor.month == now.month && cursor.year == now.year;
      final spent = sameMonth ? (dayTotals[day] ?? 0) : 0;
      if (sameMonth && spent <= averageDaily) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    var lastStreak = 0;
    for (var day = daysElapsed; day >= 1; day--) {
      if ((dayTotals[day] ?? 0) <= averageDaily) {
        lastStreak++;
      } else {
        break;
      }
    }

    // Category health for this month, with 5-month history for sparklines.
    final byId = <int, List<Txn>>{};
    for (final txn in thisMonth.where((t) => t.type == kTypeExpense)) {
      final id = txn.categoryId ?? -1;
      byId.putIfAbsent(id, () => <Txn>[]).add(txn);
    }
    final lastById = <int, int>{};
    for (final txn in lastMonth.where((t) => t.type == kTypeExpense)) {
      final id = txn.categoryId ?? -1;
      lastById[id] = (lastById[id] ?? 0) + txn.amount;
    }
    final categoryHealth = <_CategoryHealth>[];
    for (final entry in byId.entries) {
      final months = <int>[];
      for (var offset = 4; offset >= 0; offset--) {
        final start = DateTime(now.year, now.month - offset, 1);
        final end = DateTime(now.year, now.month - offset + 1, 1);
        var total = 0;
        for (final txn in all) {
          if (txn.type != kTypeExpense || (txn.categoryId ?? -1) != entry.key) {
            continue;
          }
          final d = DateTime.fromMillisecondsSinceEpoch(txn.date);
          if (!d.isBefore(start) && d.isBefore(end)) total += txn.amount;
        }
        months.add(total);
      }
      final current = entry.value.fold<int>(0, (sum, t) => sum + t.amount);
      final category = categories[entry.key];
      categoryHealth.add(
        _CategoryHealth(
          categoryId: entry.key,
          name: category?.name ?? 'Uncategorised',
          icon: category?.icon ?? 'category',
          color: category?.color ?? '#C88A5A',
          current: current,
          previous: lastById[entry.key] ?? 0,
          months: months,
        ),
      );
    }
    categoryHealth.sort((a, b) => b.current.compareTo(a.current));

    // Monthly challenge: worst-performing category vs last month.
    var challengeName = categoryHealth.isEmpty
        ? 'your top category'
        : categoryHealth.first.name;
    var challengeSpent = thisExpense;
    var challengeTarget = (thisExpense * 0.85).round();
    for (final category in categoryHealth) {
      if (category.previous > 0 && category.current > category.previous) {
        challengeName = category.name;
        challengeSpent = category.current;
        challengeTarget = (category.previous * 0.85).round();
        break;
      }
    }

    // Habits: biggest weekday and end-of-month share.
    final weekdayTotals = <int, int>{};
    final weekdayCounts = <int, int>{};
    var endOfMonthSpend = 0;
    var lastThreeTotal = 0;
    for (final txn in all) {
      if (txn.type != kTypeExpense) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(txn.date);
      weekdayTotals[d.weekday] = (weekdayTotals[d.weekday] ?? 0) + txn.amount;
      weekdayCounts[d.weekday] = (weekdayCounts[d.weekday] ?? 0) + 1;
      lastThreeTotal += txn.amount;
      if (d.day >= 25) endOfMonthSpend += txn.amount;
    }
    var biggestWeekday = 1;
    var biggestAvg = 0.0;
    for (final entry in weekdayTotals.entries) {
      final count = weekdayCounts[entry.key] ?? 1;
      final avg = entry.value / count;
      if (avg > biggestAvg) {
        biggestAvg = avg;
        biggestWeekday = entry.key;
      }
    }
    const weekdayNames = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final endShare =
        lastThreeTotal == 0 ? 0.0 : endOfMonthSpend / lastThreeTotal;

    // Savings projection for the calendar year.
    final monthsThisYear = now.month;
    var yearSaved = 0;
    var monthsWithData = 0;
    var savingsSum = 0;
    for (var offset = 0; offset < monthsThisYear; offset++) {
      final start = DateTime(now.year, now.month - offset, 1);
      final end = DateTime(now.year, now.month - offset + 1, 1);
      final slice = all.where((t) {
        final d = DateTime.fromMillisecondsSinceEpoch(t.date);
        return !d.isBefore(start) && d.isBefore(end);
      });
      final saved = incomeOf(slice) - expenseOf(slice);
      yearSaved += saved;
      if (incomeOf(slice) > 0) {
        savingsSum += saved;
        monthsWithData++;
      }
    }
    final monthlySavings = monthsWithData == 0 ? 0 : savingsSum ~/ monthsWithData;
    final monthsLeft = math.max(0, 12 - now.month);
    final projection = yearSaved + monthlySavings * monthsLeft;

    // Subscriptions: notes seen in two or more distinct months.
    final byNote = <String, Set<String>>{};
    final noteAmount = <String, int>{};
    for (final txn in all.where((t) => t.type == kTypeExpense)) {
      final note = (txn.note ?? '').trim();
      if (note.length < 3) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(txn.date);
      byNote.putIfAbsent(note, () => <String>{}).add('${d.year}-${d.month}');
      noteAmount[note] = (noteAmount[note] ?? 0) + txn.amount;
    }
    final subscriptions = <_Subscription>[];
    var subscriptionTotal = 0;
    for (final entry in byNote.entries) {
      final months = entry.value.length;
      if (months < 2) continue;
      final total = noteAmount[entry.key] ?? 0;
      final unit = total ~/ months;
      subscriptionTotal += unit;
      subscriptions.add(
        _Subscription(
          name: entry.key,
          amount: unit,
          months: months,
        ),
      );
    }
    subscriptions.sort((a, b) => b.amount.compareTo(a.amount));
    final costPerDay = subscriptionTotal ~/ 30;

    return _HealthModel(
      health: _HealthScore(
        score: score,
        label: label,
        color: score >= 70
            ? const Color(0xFF2ED3B7)
            : score >= 40
                ? const Color(0xFFF6C453)
                : const Color(0xFFF58C8C),
        savings: savings,
        budget: budgetScore,
        trend: trendScore,
      ),
      thisMonthExpense: thisExpense,
      thisMonthIncome: thisIncome,
      lastMonthExpense: prevExpense,
      streakDays: streak,
      lastStreakDays: lastStreak,
      averageDaily: averageDaily,
      challengeName: challengeName,
      challengeSpent: challengeSpent,
      challengeTarget: challengeTarget,
      categories: categoryHealth,
      biggestWeekday: weekdayNames[biggestWeekday - 1],
      biggestWeekdayShare: weekdayTotals.isEmpty
          ? 0
          : (weekdayTotals[biggestWeekday] ?? 0) /
              math.max(1, weekdayTotals.values.reduce((a, b) => a + b)),
      endOfMonthShare: endShare,
      dayTotals: dayTotals,
      dayIncome: dayIncome,
      projectionYearEnd: projection,
      monthlySavings: monthlySavings,
      subscriptions: subscriptions,
      subscriptionTotal: subscriptionTotal,
      costPerDay: costPerDay,
      yearSaved: yearSaved,
    );
  }
}

class _Subscription {
  const _Subscription({
    required this.name,
    required this.amount,
    required this.months,
  });

  final String name;
  final int amount;
  final int months;
}

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.model});

  final _HealthModel model;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final health = model.health;
    return PaisaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Health Score',
            style: AppTextStyles.base(
              size: 19,
              weight: FontWeight.w700,
              height: 1.2,
            ).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              RingGauge(
                value: health.score / 100,
                size: 118,
                strokeWidth: 12,
                color: health.color,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${health.score}',
                      style: AppTextStyles.base(
                        size: 34,
                        weight: FontWeight.w700,
                        height: 1.0,
                      ).copyWith(color: palette.ink),
                    ),
                    Text(
                      health.label,
                      style: AppTextStyles.base(
                        size: 12.5,
                        weight: FontWeight.w500,
                        height: 1.2,
                      ).copyWith(color: palette.sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _SubScore(
                      label: 'Savings',
                      value: health.savings,
                      tone: const Color(0xFF2ED3B7),
                    ),
                    const SizedBox(height: 12),
                    _SubScore(
                      label: 'Budget',
                      value: health.budget,
                      tone: const Color(0xFFF6C453),
                    ),
                    const SizedBox(height: 12),
                    _SubScore(
                      label: 'Trend',
                      value: health.trend,
                      tone: const Color(0xFFF6C453),
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

class _SubScore extends StatelessWidget {
  const _SubScore({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final int value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: AppTextStyles.base(
              size: 15,
              weight: FontWeight.w500,
              height: 1.1,
            ).copyWith(color: palette.sub),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: palette.divider.withOpacity(0.45),
              valueColor: AlwaysStoppedAnimation<Color>(tone),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 26,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: AppTextStyles.base(
              size: 15,
              weight: FontWeight.w700,
              height: 1.1,
            ).copyWith(color: palette.ink),
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.model});

  final _HealthModel model;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    const flame = Color(0xFFF2A03D);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: palette.isDark ? const Color(0xFF2B2109) : const Color(0xFFFFF4DC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: flame.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: flame, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Spending Streak',
                  style: AppTextStyles.base(
                    size: 17,
                    weight: FontWeight.w600,
                    height: 1.15,
                  ).copyWith(color: palette.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  '${model.lastStreakDays} days under average!',
                  style: AppTextStyles.base(
                    size: 15.5,
                    weight: FontWeight.w500,
                    height: 1.2,
                  ).copyWith(color: flame),
                ),
                const SizedBox(height: 2),
                Text(
                  'Best: ${model.streakDays} days',
                  style: AppTextStyles.base(
                    size: 13,
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

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.model});

  final _HealthModel model;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final over = model.challengeSpent > model.challengeTarget;
    final progress = model.challengeTarget == 0
        ? 1.0
        : (model.challengeSpent / model.challengeTarget).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.flag_rounded, size: 20, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monthly Challenge',
                  style: AppTextStyles.base(
                    size: 17,
                    weight: FontWeight.w600,
                    height: 1.15,
                  ).copyWith(color: palette.ink),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.expense.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  over ? 'Over Target' : 'On Track',
                  style: AppTextStyles.base(
                    size: 12.5,
                    weight: FontWeight.w600,
                    height: 1.1,
                  ).copyWith(color: palette.expense),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reduce ${model.challengeName} by 15%',
            style: AppTextStyles.base(
              size: 15,
              weight: FontWeight.w400,
              height: 1.3,
            ).copyWith(color: palette.sub),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: palette.divider.withOpacity(0.45),
              valueColor: AlwaysStoppedAnimation<Color>(palette.expense),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                Fmt.money(model.challengeSpent),
                style: AppTextStyles.base(
                  size: 13.5,
                  weight: FontWeight.w600,
                  height: 1.1,
                ).copyWith(color: palette.expense),
              ),
              const Spacer(),
              Text(
                Fmt.money(model.challengeTarget),
                style: AppTextStyles.base(
                  size: 13.5,
                  weight: FontWeight.w500,
                  height: 1.1,
                ).copyWith(color: palette.sub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.model, required this.categories});

  final _HealthModel model;
  final Map<int, Category> categories;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (model.categories.isEmpty) {
      return PaisaCard(
        child: Text(
          'Log a few expenses to see grades for each category.',
          style: AppTextStyles.body(palette.sub),
        ),
      );
    }
    Color gradeTone(String grade) {
      switch (grade) {
        case 'A':
          return const Color(0xFF2ED3B7);
        case 'B':
          return const Color(0xFF7DD8A8);
        case 'C':
          return const Color(0xFFF6C453);
        case 'D':
          return const Color(0xFFF2A03D);
        default:
          return palette.expense;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider.withOpacity(0.4)),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0;
              i < math.min(8, model.categories.length);
              i++)
            Builder(
              builder: (context) {
                final entry = model.categories[i];
                final category = categories[entry.categoryId];
                final tone = gradeTone(entry.grade);
                final change = entry.previous == 0
                    ? 'New this month'
                    : '${entry.change >= 0 ? 'Increased' : 'Decreased'} '
                        '${(entry.change.abs() * 100).round()}% from last month';
                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    border: i < math.min(8, model.categories.length) - 1
                        ? Border(
                            bottom: BorderSide(
                              color: palette.divider.withOpacity(0.35),
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        height: 38,
                        width: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tone.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          entry.grade,
                          style: AppTextStyles.base(
                            size: 17,
                            weight: FontWeight.w700,
                            height: 1.0,
                          ).copyWith(color: tone),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              category?.name ?? 'Uncategorised',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.base(
                                size: 16,
                                weight: FontWeight.w500,
                                height: 1.15,
                              ).copyWith(color: palette.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              change,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.base(
                                size: 12.5,
                                weight: FontWeight.w400,
                                height: 1.2,
                              ).copyWith(color: palette.sub),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Fmt.money(entry.current),
                        style: AppTextStyles.base(
                          size: 15.5,
                          weight: FontWeight.w600,
                          height: 1.1,
                        ).copyWith(color: palette.ink),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HabitsCards extends StatelessWidget {
  const _HabitsCards({required this.model});

  final _HealthModel model;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final cards = <Map<String, String>>[
      {
        'icon': 'calendar',
        'title': '${model.biggestWeekday} is your biggest spending day',
        'body':
            '${(model.biggestWeekdayShare * 100).round()}% of your spending happens on ${model.biggestWeekday}s.',
      },
      {
        'icon': 'clock',
        'title': 'You spend more at the end of the month',
        'body':
            '${(model.endOfMonthShare * 100).round()}% of spending lands in the last week.',
      },
      {
        'icon': 'trend',
        'title': model.thisMonthExpense <= model.lastMonthExpense
            ? 'You are spending less than last month'
            : 'Spending is up from last month',
        'body':
            '${Fmt.money(model.thisMonthExpense)} this month vs ${Fmt.money(model.lastMonthExpense)} last month.',
      },
    ];
    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final card = cards[index];
          return Container(
            width: 232,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.divider.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: palette.accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    card['icon'] == 'clock'
                        ? Icons.schedule_rounded
                        : card['icon'] == 'trend'
                            ? Icons.trending_up_rounded
                            : Icons.calendar_today_rounded,
                    size: 18,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  card['title']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.base(
                    size: 15.5,
                    weight: FontWeight.w600,
                    height: 1.25,
                  ).copyWith(color: palette.ink),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    card['body']!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 13,
                      weight: FontWeight.w400,
                      height: 1.35,
                    ).copyWith(color: palette.sub),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.model, required this.month});

  final _HealthModel model;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = (DateTime(month.year, month.month, 1).weekday - 1) % 7;
    final peak = model.dayTotals.values.isEmpty
        ? 1
        : model.dayTotals.values.reduce((a, b) => a > b ? a : b);
    return PaisaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.05,
            children: <Widget>[
              for (var i = 0; i < leading; i++) const SizedBox.shrink(),
              for (var day = 1; day <= days; day++)
                Builder(
                  builder: (context) {
                    final income = model.dayIncome[day] ?? 0;
                    final expense = model.dayTotals[day] ?? 0;
                    final ratio = expense == 0
                        ? 0.0
                        : (expense / peak).clamp(0.18, 1.0);
                    Color color;
                    if (income > 0 && income >= expense) {
                      color = palette.income.withOpacity(0.75);
                    } else if (expense > 0) {
                      color = palette.expense.withOpacity(0.2 + ratio * 0.72);
                    } else if (income > 0) {
                      color = palette.income.withOpacity(0.5);
                    } else {
                      color = Colors.transparent;
                    }
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(7),
                        border: expense == 0 && income == 0
                            ? Border.all(
                                color: palette.divider.withOpacity(0.35),
                              )
                            : null,
                      ),
                      child: Text(
                        '$day',
                        style: AppTextStyles.base(
                          size: 11,
                          weight: FontWeight.w600,
                          height: 1.0,
                        ).copyWith(
                          color: (expense > 0 && ratio > 0.6) || income > 0
                              ? Colors.white
                              : palette.sub,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _LegendDot(color: palette.income, label: 'Income'),
              const SizedBox(width: 12),
              Text(
                '~',
                style: AppTextStyles.base(
                  size: 15,
                  weight: FontWeight.w500,
                  height: 1.1,
                ).copyWith(color: palette.tertiary),
              ),
              const SizedBox(width: 12),
              _LegendDot(color: palette.expense, label: 'Expense'),
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
    final palette = context.c;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 9,
          width: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.base(
            size: 12.5,
            weight: FontWeight.w400,
            height: 1.1,
          ).copyWith(color: palette.sub),
        ),
      ],
    );
  }
}

class _CategoryHealthCard extends StatelessWidget {
  const _CategoryHealthCard({required this.model});

  final _HealthModel model;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    if (model.categories.isEmpty) {
      return PaisaCard(
        child: Text(
          'Category health appears once you have a month of spending.',
          style: AppTextStyles.body(palette.sub),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider.withOpacity(0.4)),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < math.min(6, model.categories.length); i++)
            Builder(
              builder: (context) {
                final entry = model.categories[i];
                final up = entry.change > 0.01;
                final tone = up ? palette.expense : palette.income;
                final label = entry.previous == 0
                    ? 'New'
                    : '${up ? '+' : ''}${(entry.change * 100).round()}%';
                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    border: i < math.min(6, model.categories.length) - 1
                        ? Border(
                            bottom: BorderSide(
                              color: palette.divider.withOpacity(0.35),
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: AppColors.fromHex(entry.color),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          AppIcons.byName(entry.icon,
                              fallback: Icons.category_rounded),
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.base(
                                size: 15.5,
                                weight: FontWeight.w500,
                                height: 1.15,
                              ).copyWith(color: palette.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Fmt.money(entry.current),
                              style: AppTextStyles.base(
                                size: 12.5,
                                weight: FontWeight.w400,
                                height: 1.2,
                              ).copyWith(color: palette.sub),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 74,
                        height: 30,
                        child: _Sparkbars(
                          values: entry.months,
                          color: tone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 52,
                        child: Text(
                          label,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.base(
                            size: 13,
                            weight: FontWeight.w600,
                            height: 1.1,
                          ).copyWith(color: tone),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Sparkbars extends StatelessWidget {
  const _Sparkbars({required this.values, required this.color});

  final List<int> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final peak = values.isEmpty
        ? 1
        : values.reduce((a, b) => a > b ? a : b) == 0
            ? 1
            : values.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final value in values)
          Container(
            width: 10,
            height: math.max(3.0, 26 * (value / peak)),
            decoration: BoxDecoration(
              color: color.withOpacity(value == 0 ? 0.22 : 0.85),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.model});

  final _HealthModel model;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return PaisaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Savings Projection',
            style: AppTextStyles.base(
              size: 18,
              weight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 8),
          Text(
            Fmt.money(model.projectionYearEnd < 0 ? 0 : model.projectionYearEnd),
            style: AppTextStyles.base(
              size: 30,
              weight: FontWeight.w700,
              height: 1.05,
            ).copyWith(color: palette.income),
          ),
          const SizedBox(height: 4),
          Text(
            '${Fmt.money(model.yearSaved)} saved so far this year',
            style: AppTextStyles.base(
              size: 13.5,
              weight: FontWeight.w400,
              height: 1.2,
            ).copyWith(color: palette.sub),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(Icons.trending_up_rounded, size: 16, color: palette.income),
              const SizedBox(width: 6),
              Text(
                '${Fmt.money(model.monthlySavings)} saved per month',
                style: AppTextStyles.base(
                  size: 14,
                  weight: FontWeight.w500,
                  height: 1.2,
                ).copyWith(color: palette.income),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.model});

  final _HealthModel model;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.autorenew_rounded, size: 19, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Subscriptions Detected',
                  style: AppTextStyles.base(
                    size: 17,
                    weight: FontWeight.w600,
                    height: 1.15,
                  ).copyWith(color: palette.ink),
                ),
              ),
              Text(
                Fmt.money(model.subscriptionTotal),
                style: AppTextStyles.base(
                  size: 17,
                  weight: FontWeight.w700,
                  height: 1.15,
                ).copyWith(color: palette.ink),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total recurring monthly',
            style: AppTextStyles.base(
              size: 12.5,
              weight: FontWeight.w400,
              height: 1.2,
            ).copyWith(color: palette.sub),
          ),
          const SizedBox(height: 6),
          if (model.subscriptions.isEmpty)
            Text(
              'Repeat payments will show up here once a note appears in two invoices.',
              style: AppTextStyles.base(
                size: 13,
                weight: FontWeight.w400,
                height: 1.35,
              ).copyWith(color: palette.sub),
            )
          else
            for (final sub in model.subscriptions.take(4))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: palette.accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.repeat_rounded,
                        size: 16,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            sub.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.base(
                              size: 14.5,
                              weight: FontWeight.w500,
                              height: 1.15,
                            ).copyWith(color: palette.ink),
                          ),
                          Text(
                            '${sub.months} months detected',
                            style: AppTextStyles.base(
                              size: 12,
                              weight: FontWeight.w400,
                              height: 1.2,
                            ).copyWith(color: palette.sub),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Fmt.money(sub.amount),
                      style: AppTextStyles.base(
                        size: 14,
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

class _CostPerDayCard extends StatelessWidget {
  const _CostPerDayCard({
    required this.model,
    required this.categories,
  });

  final _HealthModel model;
  final Map<int, Category> categories;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.calendar_today_rounded,
                  size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cost Per Day',
                  style: AppTextStyles.base(
                    size: 17,
                    weight: FontWeight.w600,
                    height: 1.15,
                  ).copyWith(color: palette.ink),
                ),
              ),
              Text(
                '${Fmt.money(model.costPerDay)}/day',
                style: AppTextStyles.base(
                  size: 15,
                  weight: FontWeight.w700,
                  height: 1.15,
                ).copyWith(color: palette.ink),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (model.categories.isEmpty)
            Text(
              'Category-level cost per day appears after your first month.',
              style: AppTextStyles.base(
                size: 13,
                weight: FontWeight.w400,
                height: 1.35,
              ).copyWith(color: palette.sub),
            )
          else
            for (final entry in model.categories.take(3))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        categories[entry.categoryId]?.name ?? 'Uncategorised',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.base(
                          size: 14,
                          weight: FontWeight.w400,
                          height: 1.2,
                        ).copyWith(color: palette.ink),
                      ),
                    ),
                    Text(
                      '${Fmt.money(entry.current ~/ 30)}/day',
                      style: AppTextStyles.base(
                        size: 13.5,
                        weight: FontWeight.w500,
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
