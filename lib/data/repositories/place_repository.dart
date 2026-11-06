import '../db/app_database.dart';
import '../models/models.dart';

/// A place or person label with usage totals, shown on the Places / People
/// screens. Totals come from the `place` / `payee` text columns on transactions.
class TagEntityStat {
  const TagEntityStat({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
    required this.income,
    required this.expense,
  });

  final int id;
  final String name;
  final String icon;
  final String color;
  final int count;
  final int income;
  final int expense;

  int get net => income - expense;
}

class PlaceRepository {
  PlaceRepository(this._db);

  final AppDatabase _db;

  Future<List<TagEntityStat>> _stats(
    String table,
    String txnColumn, {
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await _db.database;
    final extra = <String>[];
    final args = <Object?>[];
    if (start != null) {
      extra.add('AND t.date >= ?');
      args.add(start.millisecondsSinceEpoch);
    }
    if (end != null) {
      extra.add('AND t.date < ?');
      args.add(end.millisecondsSinceEpoch);
    }
    final rows = await db.rawQuery('''
      SELECT x.id AS id, x.name AS name, x.icon AS icon, x.color AS color,
             COUNT(t.id) AS cnt,
             COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) AS income,
             COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0) AS expense
      FROM $table x
      LEFT JOIN transactions t
        ON t.$txnColumn = x.name AND t.deleted = 0 ${extra.join(' ')}
      GROUP BY x.id
      ORDER BY x.name COLLATE NOCASE
    ''', args);
    return rows
        .map(
          (row) => TagEntityStat(
            id: (row['id'] as num).toInt(),
            name: row['name']! as String,
            icon: (row['icon'] ?? 'place') as String,
            color: (row['color'] ?? '#2ED3B7') as String,
            count: ((row['cnt'] as num?) ?? 0).toInt(),
            income: ((row['income'] as num?) ?? 0).toInt(),
            expense: ((row['expense'] as num?) ?? 0).toInt(),
          ),
        )
        .toList();
  }

  Future<List<TagEntityStat>> allPlaces({DateTime? start, DateTime? end}) =>
      _stats('places', 'place', start: start, end: end);

  Future<List<TagEntityStat>> allPeople({DateTime? start, DateTime? end}) =>
      _stats('people', 'payee', start: start, end: end);

  Future<List<Txn>> transactionsFor(String column, String name) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: '$column = ? AND deleted = 0',
      whereArgs: <Object?>[name],
      orderBy: 'date DESC',
    );
    return rows.map(Txn.fromMap).toList();
  }

  Future<int> createPlace({
    required String name,
    String icon = 'place',
    String color = '#2ED3B7',
  }) async {
    final db = await _db.database;
    final id = await db.insert('places', <String, Object?>{
      'name': name.trim(),
      'icon': icon,
      'color': color,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    _db.notifyChanged();
    return id;
  }

  Future<int> createPerson({
    required String name,
    String icon = 'person',
    String color = '#E91E63',
  }) async {
    final db = await _db.database;
    final id = await db.insert('people', <String, Object?>{
      'name': name.trim(),
      'icon': icon,
      'color': color,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    _db.notifyChanged();
    return id;
  }

  Future<void> rename(
    String table,
    int id,
    String name, {
    String? icon,
    String? color,
  }) async {
    final db = await _db.database;
    await db.update(
      table,
      <String, Object?>{
        'name': name.trim(),
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    _db.notifyChanged();
  }

  Future<void> delete(String table, int id) async {
    final db = await _db.database;
    await db.delete(table, where: 'id = ?', whereArgs: <Object?>[id]);
    _db.notifyChanged();
  }
}
