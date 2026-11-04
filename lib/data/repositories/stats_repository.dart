import '../db/app_database.dart';
import '../models/models.dart';

class Insight {
  const Insight({
    required this.text,
    this.icon = 'insights',
    this.tone = 'neutral',
  });

  final String text;
  final String icon;

  /// neutral | positive | negative | warning
  final String tone;
}

class CashFlowPoint {
  const CashFlowPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final int income;
  final int expense;

  int get net => income - expense;
}

/// All analytics are computed from the local ledger.
class StatsRepository {
  StatsRepository(this._db);

  final AppDatabase _db;

  Future<PeriodSummary> summary(DateTime start, DateTime end) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT type, COUNT(*) AS c, COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE deleted = 0 AND date >= ? AND date <= ? AND include_in_reports = 1
      GROUP BY type
    ''', <Object?>[start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    var income = 0;
    var expense = 0;
    var transfers = 0;
    var count = 0;
    for (final row in rows) {
      final type = row['type'] as String;
      final total = (row['total'] as num).toInt();
      count += (row['c'] as num).toInt();
      if (type == kTypeIncome) {
        income += total;
      } else if (type == kTypeExpense) {
        expense += total;
      } else {
        transfers += total;
      }
    }
    return PeriodSummary(
      income: income,
      expense: expense,
      transferIn: transfers,
      transferOut: transfers,
      count: count,
    );
  }

  Future<List<CategoryTotal>> categoryTotals(
    DateTime start,
    DateTime end, {
    String type = kTypeExpense,
  }) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT categories.id AS id, categories.name AS name, categories.color AS color,
             categories.icon AS icon,
             COALESCE(SUM(transactions.amount), 0) AS total,
             COUNT(transactions.id) AS c
      FROM transactions
      INNER JOIN categories ON categories.id = transactions.category_id
      WHERE transactions.deleted = 0 AND transactions.type = ?
        AND transactions.date >= ? AND transactions.date <= ?
        AND transactions.include_in_reports = 1
      GROUP BY categories.id
      ORDER BY total DESC
    ''', <Object?>[type, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    return rows
        .map((row) => CategoryTotal(
              categoryId: (row['id'] as num).toInt(),
              name: row['name'] as String,
              color: row['color'] as String,
              icon: row['icon'] as String,
              total: (row['total'] as num).toInt(),
              count: (row['c'] as num).toInt(),
            ))
        .toList();
  }

  Future<List<DayTotal>> dailyTotals(
    DateTime start,
    DateTime end, {
    String type = kTypeExpense,
  }) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT date, amount FROM transactions
      WHERE deleted = 0 AND type = ? AND date >= ? AND date <= ? AND include_in_reports = 1
      ORDER BY date ASC
    ''', <Object?>[type, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    final totals = <String, int>{};
    final dayMap = <String, DateTime>{};
    for (final row in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch((row['date'] as num).toInt());
      final key = '${date.year}-${date.month}-${date.day}';
      totals[key] = (totals[key] ?? 0) + (row['amount'] as num).toInt();
      dayMap[key] = DateTime(date.year, date.month, date.day);
    }
    final keys = totals.keys.toList()..sort();
    return keys.map((key) => DayTotal(day: dayMap[key]!, total: totals[key]!)).toList();
  }

  Future<List<MonthTotal>> monthlyTotals({int months = 6}) async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month - (months - 1), 1);
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT date, type, amount FROM transactions
      WHERE deleted = 0 AND date >= ? AND type != 'transfer' AND include_in_reports = 1
    ''', <Object?>[first.millisecondsSinceEpoch]);
    final result = <String, MonthTotal>{};
    for (var i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - (months - 1) + i, 1);
      final key = '${month.year}-${month.month}';
      result[key] = MonthTotal(month: month, income: 0, expense: 0);
    }
    for (final row in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch((row['date'] as num).toInt());
      final key = '${date.year}-${date.month}';
      final existing = result[key];
      if (existing == null) continue;
      final amount = (row['amount'] as num).toInt();
      result[key] = row['type'] == kTypeIncome
          ? MonthTotal(month: existing.month, income: existing.income + amount, expense: existing.expense)
          : MonthTotal(month: existing.month, income: existing.income, expense: existing.expense + amount);
    }
    return result.values.toList();
  }

  Future<List<MonthTotal>> yearlyComparison() async {
    final now = DateTime.now();
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT date, type, amount FROM transactions
      WHERE deleted = 0 AND type != 'transfer' AND include_in_reports = 1
        AND date >= ?
    ''', <Object?>[DateTime(now.year - 1, 1, 1).millisecondsSinceEpoch]);
    final map = <String, Map<String, int>>{};
    for (final row in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch((row['date'] as num).toInt());
      final key = '${date.year}-${date.month}';
      final entry = map.putIfAbsent(key, () => <String, int>{'income': 0, 'expense': 0});
      final amount = (row['amount'] as num).toInt();
      entry[row['type'] == kTypeIncome ? 'income' : 'expense'] =
          (entry[row['type'] == kTypeIncome ? 'income' : 'expense'] ?? 0) + amount;
    }
    // Last 24 months, oldest first, only months with data.
    final points = <MonthTotal>[];
    for (var i = 23; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month}';
      final entry = map[key];
      if (entry == null) continue;
      points.add(MonthTotal(
        month: month,
        income: entry['income'] ?? 0,
        expense: entry['expense'] ?? 0,
      ));
    }
    return points;
  }

  Future<List<CashFlowPoint>> cashFlow({int months = 6}) async {
    final totals = await monthlyTotals(months: months);
    return totals
        .map((t) => CashFlowPoint(month: t.month, income: t.income, expense: t.expense))
        .toList();
  }

  Future<List<MapEntry<String, int>>> accountSpending(DateTime start, DateTime end) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT accounts.name AS name, COALESCE(SUM(transactions.amount), 0) AS total
      FROM transactions
      INNER JOIN accounts ON accounts.id = transactions.account_id
      WHERE transactions.deleted = 0 AND transactions.type = 'expense'
        AND transactions.date >= ? AND transactions.date <= ?
      GROUP BY accounts.id
      ORDER BY total DESC
    ''', <Object?>[start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    return rows
        .map((row) => MapEntry<String, int>(
              row['name'] as String,
              (row['total'] as num).toInt(),
            ))
        .toList();
  }

  Future<List<Txn>> topTransactions(DateTime start, DateTime end, {int limit = 10}) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: "deleted = 0 AND type = 'expense' AND date >= ? AND date <= ?",
      whereArgs: <Object?>[start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'amount DESC',
      limit: limit,
    );
    return rows.map(Txn.fromMap).toList();
  }

  Future<List<DayTotal>> heatmap(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return dailyTotals(start, end);
  }

  Future<int> recurringTotal(DateTime start, DateTime end) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total FROM transactions
      WHERE deleted = 0 AND type = 'expense' AND recurring_rule_id IS NOT NULL
        AND date >= ? AND date <= ?
    ''', <Object?>[start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Projected spend for the running month (linear pace).
  Future<int> forecastMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final summaryNow = await summary(start, now);
    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (dayOfMonth <= 0) return summaryNow.expense;
    return ((summaryNow.expense / dayOfMonth) * daysInMonth).round();
  }

  Future<List<Insight>> insights() async {
    final now = DateTime.now();
    final thisStart = DateTime(now.year, now.month, 1);
    final thisEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final lastStart = DateTime(now.year, now.month - 1, 1);
    final lastEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    final thisCats = await categoryTotals(thisStart, thisEnd);
    final lastCats = await categoryTotals(lastStart, lastEnd);
    final thisSummary = await summary(thisStart, thisEnd);
    final lastSummary = await summary(lastStart, lastEnd);

    final insights = <Insight>[];

    if (thisCats.isNotEmpty) {
      final top = thisCats.first;
      insights.add(Insight(
        text:
            '${top.name} is your largest expense this month at ${_money(top.total)}.',
        icon: 'insights',
      ));
      final last = lastCats.where((c) => c.categoryId == top.categoryId).toList();
      if (last.isNotEmpty && last.first.total > 0) {
        final change = ((top.total - last.first.total) / last.first.total) * 100;
        if (change.abs() >= 5) {
          insights.add(Insight(
            text:
                'You spent ${change.abs().toStringAsFixed(0)}% ${change > 0 ? 'more' : 'less'} on ${top.name} than last month.',
            icon: change > 0 ? 'trending_up' : 'trending_down',
            tone: change > 0 ? 'negative' : 'positive',
          ));
        }
      }
    }

    if (lastSummary.savingsRate != 0 || thisSummary.savingsRate != 0) {
      insights.add(Insight(
        text:
            'Your savings rate is ${thisSummary.savingsRate.toStringAsFixed(0)}% this month (last month ${lastSummary.savingsRate.toStringAsFixed(0)}%).',
        icon: 'percent',
        tone: thisSummary.savingsRate >= lastSummary.savingsRate ? 'positive' : 'warning',
      ));
    }

    final avgDaily = thisSummary.expense ~/ (now.day <= 0 ? 1 : now.day);
    if (avgDaily > 0) {
      insights.add(Insight(
        text: 'Your average daily spend is ${_money(avgDaily)}.',
        icon: 'calendar_month',
      ));
    }

    final forecast = await forecastMonth();
    if (thisSummary.income > 0 && forecast > thisSummary.income) {
      insights.add(Insight(
        text:
            'At this pace you will spend ${_money(forecast)} this month, more than you earn.',
        icon: 'trending_up',
        tone: 'warning',
      ));
    }

    final db = await _db.database;
    final budgetRows = await db.query('budgets', where: 'archived = 0');
    if (budgetRows.isNotEmpty) {
      final budget = Budget.fromMap(budgetRows.first);
      final progress = await db.rawQuery('''
        SELECT COALESCE(SUM(amount),0) AS total FROM transactions
        WHERE deleted = 0 AND type = 'expense' AND date >= ? AND date <= ?
      ''', <Object?>[budget.startDate, budget.endDate]);
      final spent = (progress.first['total'] as num).toInt();
      if (budget.amount > 0) {
        final ratio = spent / budget.amount;
        if (ratio > 0.8) {
          insights.add(Insight(
            text:
                'You have used ${(ratio * 100).toStringAsFixed(0)}% of "${budget.name}". Slow down to stay on track.',
            icon: 'percent',
            tone: 'warning',
          ));
        } else {
          insights.add(Insight(
            text:
                'You are on track with "${budget.name}" – ${_money(budget.amount - spent)} still available.',
            icon: 'verified',
            tone: 'positive',
          ));
        }
      }
    }

    if (insights.isEmpty) {
      insights.add(const Insight(
        text: 'Add a few transactions and MoneyMan will start surfacing insights.',
        icon: 'insights',
      ));
    }
    return insights;
  }

  String _money(int paise) {
    final value = paise / 100;
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
    return '₹${value.toStringAsFixed(0)}';
  }
}
