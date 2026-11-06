import '../db/app_database.dart';

/// A reusable transaction recipe ("Morning Coffee", "Gym Session"…).
class TxnTemplate {
  const TxnTemplate({
    this.id,
    required this.name,
    this.type = 'expense',
    this.amount = 0,
    this.icon = 'receipt_long',
    this.color = '#8A6A5C',
    this.accountId,
    this.categoryId,
    this.note,
    this.sortOrder = 0,
  });

  final int? id;
  final String name;
  final String type;
  final int amount;
  final String icon;
  final String color;
  final int? accountId;
  final int? categoryId;
  final String? note;
  final int sortOrder;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'type': type,
        'amount': amount,
        'icon': icon,
        'color': color,
        'account_id': accountId,
        'category_id': categoryId,
        'note': note,
        'sort_order': sortOrder,
      };

  factory TxnTemplate.fromMap(Map<String, Object?> map) => TxnTemplate(
        id: (map['id'] as num?)?.toInt(),
        name: map['name']! as String,
        type: (map['type'] ?? 'expense') as String,
        amount: ((map['amount'] as num?) ?? 0).toInt(),
        icon: (map['icon'] ?? 'receipt_long') as String,
        color: (map['color'] ?? '#8A6A5C') as String,
        accountId: (map['account_id'] as num?)?.toInt(),
        categoryId: (map['category_id'] as num?)?.toInt(),
        note: map['note'] as String?,
        sortOrder: ((map['sort_order'] as num?) ?? 0).toInt(),
      );
}

class TemplateRepository {
  TemplateRepository(this._db);

  final AppDatabase _db;

  Future<List<TxnTemplate>> all() async {
    final db = await _db.database;
    final rows = await db.query('templates', orderBy: 'sort_order ASC, id ASC');
    return rows.map(TxnTemplate.fromMap).toList();
  }

  Future<int> create(TxnTemplate template) async {
    final db = await _db.database;
    final id = await db.insert(
      'templates',
      template.toMap()..remove('id'),
    );
    _db.notifyChanged();
    return id;
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('templates', where: 'id = ?', whereArgs: <Object?>[id]);
    _db.notifyChanged();
  }

  Future<void> reorder(List<TxnTemplate> templates) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (var i = 0; i < templates.length; i++) {
        await txn.update(
          'templates',
          <String, Object?>{'sort_order': i},
          where: 'id = ?',
          whereArgs: <Object?>[templates[i].id],
        );
      }
    });
    _db.notifyChanged();
  }
}
