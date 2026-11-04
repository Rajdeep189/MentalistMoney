import '../db/app_database.dart';
import '../models/models.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  Future<List<Category>> all({bool includeArchived = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'categories',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'type ASC, sort_order ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Category>> byType(String type) async {
    final all = await this.all();
    return all.where((c) => c.type == type).toList();
  }

  Future<Category?> byId(int id) async {
    final db = await _db.database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: <Object?>[id], limit: 1);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<int> create(Category category) async {
    final db = await _db.database;
    final maxRow = await db.rawQuery('SELECT MAX(sort_order) AS max_order FROM categories');
    final next = ((maxRow.first['max_order'] as num?)?.toInt() ?? 0) + 1;
    final id = await db.insert(
      'categories',
      category.copyWith(sortOrder: category.sortOrder == 0 ? next : category.sortOrder).toMap()
        ..remove('id'),
    );
    _db.notifyChanged();
    return id;
  }

  Future<void> update(Category category) async {
    final db = await _db.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[category.id],
    );
    _db.notifyChanged();
  }

  Future<void> setArchived(int id, bool archived) async {
    final db = await _db.database;
    await db.update('categories', <String, Object?>{'archived': archived ? 1 : 0},
        where: 'id = ?', whereArgs: <Object?>[id]);
    _db.notifyChanged();
  }

  Future<void> toggleFavorite(Category category) async {
    await update(category.copyWith(isFavorite: !category.isFavorite));
  }

  Future<void> reorder(List<Category> categories) async {
    final db = await _db.database;
    final batch = db.batch();
    var order = 0;
    for (final category in categories) {
      batch.update(
        'categories',
        <String, Object?>{'sort_order': order++},
        where: 'id = ?',
        whereArgs: <Object?>[category.id],
      );
    }
    await batch.commit(noResult: true);
    _db.notifyChanged();
  }

  /// Deletes a category, optionally moving its transactions elsewhere.
  Future<void> delete(int id, {int? reassignTo}) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      if (reassignTo != null) {
        await txn.update(
          'transactions',
          <String, Object?>{'category_id': reassignTo},
          where: 'category_id = ?',
          whereArgs: <Object?>[id],
        );
      } else {
        await txn.update(
          'transactions',
          <String, Object?>{'category_id': null},
          where: 'category_id = ?',
          whereArgs: <Object?>[id],
        );
      }
      await txn.delete('categories', where: 'id = ?', whereArgs: <Object?>[id]);
    });
    _db.notifyChanged();
  }

  /// Merges [sourceId] into [targetId].
  Future<void> merge(int sourceId, int targetId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        'transactions',
        <String, Object?>{'category_id': targetId},
        where: 'category_id = ?',
        whereArgs: <Object?>[sourceId],
      );
      await txn.delete('budget_categories', where: 'category_id = ?', whereArgs: <Object?>[sourceId]);
      await txn.delete('categories', where: 'id = ?', whereArgs: <Object?>[sourceId]);
    });
    _db.notifyChanged();
  }
}
