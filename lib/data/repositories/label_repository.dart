import '../db/app_database.dart';

/// A tag (shown in the UI as a "label") together with its usage totals.
class LabelInfo {
  const LabelInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.count,
    required this.income,
    required this.expense,
  });

  final int id;
  final String name;
  final String color;
  final int count;
  final int income;
  final int expense;

  int get net => income - expense;
}

class LabelRepository {
  LabelRepository(this._db);

  final AppDatabase _db;

  /// Every label with transaction counts and income/expense totals. Passing a
  /// date range restricts the totals to that window (used by "This month").
  Future<List<LabelInfo>> all({DateTime? start, DateTime? end}) async {
    final db = await _db.database;
    final where = <String>['t.deleted = 0'];
    final args = <Object?>[];
    if (start != null) {
      where.add('t.date >= ?');
      args.add(start.millisecondsSinceEpoch);
    }
    if (end != null) {
      where.add('t.date < ?');
      args.add(end.millisecondsSinceEpoch);
    }
    final clause = where.join(' AND ');
    final rows = await db.rawQuery('''
      SELECT tags.id AS id,
             tags.name AS name,
             COALESCE(tags.color, '#A855F7') AS color,
             COUNT(t.id) AS cnt,
             COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) AS income,
             COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0) AS expense
      FROM tags
      LEFT JOIN transaction_tags tt ON tt.tag_id = tags.id
      LEFT JOIN transactions t ON t.id = tt.transaction_id AND $clause
      GROUP BY tags.id
      ORDER BY tags.name COLLATE NOCASE
    ''', args);
    return rows
        .map(
          (row) => LabelInfo(
            id: (row['id'] as num).toInt(),
            name: row['name']! as String,
            color: (row['color'] ?? '#A855F7') as String,
            count: ((row['cnt'] as num?) ?? 0).toInt(),
            income: ((row['income'] as num?) ?? 0).toInt(),
            expense: ((row['expense'] as num?) ?? 0).toInt(),
          ),
        )
        .toList();
  }

  Future<int> create({required String name, String color = '#A855F7'}) async {
    final db = await _db.database;
    final id = await db.insert(
      'tags',
      <String, Object?>{'name': name.trim(), 'color': color},
      conflictAlgorithm: null,
    );
    _db.notifyChanged();
    return id;
  }

  Future<void> rename(int id, String name) async {
    final db = await _db.database;
    await db.update(
      'tags',
      <String, Object?>{'name': name.trim()},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    _db.notifyChanged();
  }

  Future<void> setColor(int id, String color) async {
    final db = await _db.database;
    await db.update(
      'tags',
      <String, Object?>{'color': color},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    _db.notifyChanged();
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('transaction_tags',
          where: 'tag_id = ?', whereArgs: <Object?>[id]);
      await txn.delete('tags', where: 'id = ?', whereArgs: <Object?>[id]);
    });
    _db.notifyChanged();
  }
}
