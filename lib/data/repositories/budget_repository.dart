import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../db/app_database.dart';
import '../models/models.dart';

class BudgetRepository {
  BudgetRepository(this._db);

  final AppDatabase _db;

  Future<List<Budget>> all({bool includeArchived = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'budgets',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'start_date DESC, id DESC',
    );
    final links = await db.query('budget_categories');
    final byBudget = <int, List<int>>{};
    for (final link in links) {
      final budgetId = (link['budget_id'] as num).toInt();
      byBudget.putIfAbsent(budgetId, () => <int>[]).add((link['category_id'] as num).toInt());
    }
    return rows
        .map((row) => Budget.fromMap(
              row,
              categoryIds: byBudget[(row['id'] as num).toInt()] ?? const <int>[],
            ))
        .toList();
  }

  Future<Budget?> byId(int id) async {
    final all = await this.all(includeArchived: true);
    for (final budget in all) {
      if (budget.id == id) return budget;
    }
    return null;
  }

  Future<int> create(Budget budget) async {
    final db = await _db.database;
    late int id;
    await db.transaction((txn) async {
      id = await txn.insert('budgets', budget.toMap()..remove('id'));
      for (final categoryId in budget.categoryIds) {
        await txn.insert(
          'budget_categories',
          <String, Object?>{'budget_id': id, 'category_id': categoryId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
    _db.notifyChanged();
    return id;
  }

  Future<void> update(Budget budget) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('budgets', budget.toMap(),
          where: 'id = ?', whereArgs: <Object?>[budget.id]);
      await txn.delete('budget_categories',
          where: 'budget_id = ?', whereArgs: <Object?>[budget.id]);
      for (final categoryId in budget.categoryIds) {
        await txn.insert(
          'budget_categories',
          <String, Object?>{'budget_id': budget.id, 'category_id': categoryId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
    _db.notifyChanged();
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: <Object?>[id]);
    _db.notifyChanged();
  }

  Future<int> activeCount() async {
    final list = await all();
    return list.where((b) => !b.archived).length;
  }

  /// Spent amount for a budget within its own period.
  Future<BudgetProgress> progressFor(Budget budget) async {
    final db = await _db.database;
    final where = <String>[
      'deleted = 0',
      "type = 'expense'",
      'date >= ?',
      'date <= ?',
      'include_in_reports = 1',
    ];
    final args = <Object?>[budget.startDate, budget.endDate];

    if (budget.type != 'overall') {
      if (budget.categoryIds.isNotEmpty) {
        where.add(
            'category_id IN (${List.filled(budget.categoryIds.length, '?').join(',')})');
        args.addAll(budget.categoryIds);
      } else if (budget.type == 'account' && budget.accountId != null) {
        where.add('account_id = ?');
        args.add(budget.accountId);
      }
    }

    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total, COUNT(*) AS c FROM transactions WHERE ${where.join(' AND ')}',
      args,
    );
    final spent = (rows.first['total'] as num?)?.toInt() ?? 0;
    final count = (rows.first['c'] as num?)?.toInt() ?? 0;
    return BudgetProgress(budget: budget, spent: spent, transactionCount: count);
  }

  Future<List<BudgetProgress>> allWithProgress({bool includeArchived = false}) async {
    final budgets = await all(includeArchived: includeArchived);
    final result = <BudgetProgress>[];
    for (final budget in budgets) {
      result.add(await progressFor(budget));
    }
    result.sort((a, b) {
      if (a.budget.type == 'overall' && b.budget.type != 'overall') return -1;
      if (b.budget.type == 'overall' && a.budget.type != 'overall') return 1;
      return b.ratio.compareTo(a.ratio);
    });
    return result;
  }

  /// Spent per day inside a budget period (for the detail chart).
  Future<List<DayTotal>> dailySpend(Budget budget) async {
    final db = await _db.database;
    final where = <String>[
      'deleted = 0',
      "type = 'expense'",
      'date >= ?',
      'date <= ?',
    ];
    final args = <Object?>[budget.startDate, budget.endDate];
    if (budget.categoryIds.isNotEmpty) {
      where.add(
          'category_id IN (${List.filled(budget.categoryIds.length, '?').join(',')})');
      args.addAll(budget.categoryIds);
    }
    final rows = await db.rawQuery(
      'SELECT date, amount FROM transactions WHERE ${where.join(' AND ')} ORDER BY date ASC',
      args,
    );
    final totals = <String, int>{};
    final days = <String, DateTime>{};
    for (final row in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch((row['date'] as num).toInt());
      final key = '${date.year}-${date.month}-${date.day}';
      totals[key] = (totals[key] ?? 0) + (row['amount'] as num).toInt();
      days[key] = DateTime(date.year, date.month, date.day);
    }
    final keys = totals.keys.toList()..sort();
    return keys.map((key) => DayTotal(day: days[key]!, total: totals[key]!)).toList();
  }

  /// Category breakdown inside the budget period.
  Future<List<CategoryTotal>> categoryBreakdown(Budget budget) async {
    final db = await _db.database;
    final where = <String>[
      'transactions.deleted = 0',
      "transactions.type = 'expense'",
      'transactions.date >= ?',
      'transactions.date <= ?',
    ];
    final args = <Object?>[budget.startDate, budget.endDate];
    if (budget.categoryIds.isNotEmpty) {
      where.add(
          'transactions.category_id IN (${List.filled(budget.categoryIds.length, '?').join(',')})');
      args.addAll(budget.categoryIds);
    }
    final rows = await db.rawQuery('''
      SELECT categories.id AS id, categories.name AS name, categories.color AS color,
             categories.icon AS icon, SUM(transactions.amount) AS total,
             COUNT(transactions.id) AS c
      FROM transactions
      INNER JOIN categories ON categories.id = transactions.category_id
      WHERE ${where.join(' AND ')}
      GROUP BY categories.id
      ORDER BY total DESC
    ''', args);
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

  /// Rolls a budget's dates into the current period.
  Future<void> rollToCurrentPeriod(Budget budget) async {
    final now = DateTime.now();
    final start = DateTime.fromMillisecondsSinceEpoch(budget.startDate);
    if (now.isBefore(DateTime.fromMillisecondsSinceEpoch(budget.endDate))) return;
    final range = periodRange(budget.period, now, startDay: start.day);
    await update(budget.copyWith(
      startDate: range.$1.millisecondsSinceEpoch,
      endDate: range.$2.millisecondsSinceEpoch,
    ));
  }

  static (DateTime, DateTime) periodRange(
    String period,
    DateTime now, {
    int startDay = 1,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    switch (period) {
      case kPeriodWeekly:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return (start, DateTime(start.year, start.month, start.day, 23, 59, 59).add(const Duration(days: 6)));
      case kPeriodYearly:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31, 23, 59, 59));
      case kPeriodCustom:
        final start = customStart ?? DateTime(now.year, now.month, 1);
        final end = customEnd ?? DateTime(now.year, now.month + 1, 1);
        return (start, DateTime(end.year, end.month, end.day, 23, 59, 59));
      default:
        final start = DateXHelper.startOfMonth(now, startDay);
        final end = DateTime(start.year, start.month + 1, start.day - 1, 23, 59, 59);
        return (start, end);
    }
  }
}

/// Local helper so the repository does not depend on the UI date utilities.
class DateXHelper {
  DateXHelper._();

  static DateTime startOfMonth(DateTime d, int startDay) {
    if (startDay <= 1) return DateTime(d.year, d.month, 1);
    if (d.day >= startDay) return DateTime(d.year, d.month, startDay);
    return DateTime(d.year, d.month - 1, startDay);
  }
}
