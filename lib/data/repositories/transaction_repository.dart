import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/models.dart';

/// All transaction reads/writes. Balances are updated atomically inside the
/// same SQLite transaction as the row itself.
class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  // ------------------------------------------------------------------ create

  Future<int> create(Txn txn, {List<String> tags = const <String>[]}) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    late int id;
    await db.transaction((txnDb) async {
      id = await txnDb.insert('transactions', txn.copyWith(
        createdAt: now,
        updatedAt: now,
      ).toMap()..remove('id'));
      await _applyEffects(txnDb, txn, 1);
      await _writeTags(txnDb, id, tags);
    });
    _db.notifyChanged();
    return id;
  }

  Future<void> update(Txn txn, {List<String>? tags}) async {
    final db = await _db.database;
    final id = txn.id;
    if (id == null) return;
    await db.transaction((txnDb) async {
      final existingRows = await txnDb.query(
        'transactions',
        where: 'id = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      if (existingRows.isNotEmpty) {
        final existing = Txn.fromMap(existingRows.first);
        await _applyEffects(txnDb, existing, -1);
      }
      await txnDb.update(
        'transactions',
        txn.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch).toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      await _applyEffects(txnDb, txn, 1);
      if (tags != null) await _writeTags(txnDb, id, tags);
    });
    _db.notifyChanged();
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txnDb) async {
      final rows = await txnDb.query(
        'transactions',
        where: 'id = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        await _applyEffects(txnDb, Txn.fromMap(rows.first), -1);
      }
      await txnDb.delete('transactions', where: 'id = ?', whereArgs: <Object?>[id]);
    });
    _db.notifyChanged();
  }

  Future<void> deleteMany(List<int> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  Future<void> updateMany(
    List<int> ids, {
    int? categoryId,
    int? accountId,
  }) async {
    if (ids.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txnDb) async {
      for (final id in ids) {
        final rows = await txnDb.query(
          'transactions',
          where: 'id = ?',
          whereArgs: <Object?>[id],
          limit: 1,
        );
        if (rows.isEmpty) continue;
        final existing = Txn.fromMap(rows.first);
        await _applyEffects(txnDb, existing, -1);
        final updated = existing.copyWith(
          categoryId: categoryId,
          accountId: accountId,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await txnDb.update(
          'transactions',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
        await _applyEffects(txnDb, updated, 1);
      }
    });
    _db.notifyChanged();
  }

  Future<void> addTagToMany(List<int> ids, String tag) async {
    final db = await _db.database;
    for (final id in ids) {
      final existing = await tagsFor(id);
      final merged = <String>[...existing];
      if (!merged.contains(tag)) merged.add(tag);
      await _writeTags(db, id, merged);
    }
    _db.notifyChanged();
  }

  Future<void> _applyEffects(DatabaseExecutor db, Txn txn, int direction) async {
    final delta = txn.amount * direction;
    switch (txn.type) {
      case kTypeIncome:
        await db.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          <Object?>[delta, txn.accountId],
        );
        break;
      case kTypeTransfer:
        await db.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          <Object?>[delta, txn.accountId],
        );
        if (txn.toAccountId != null) {
          await db.rawUpdate(
            'UPDATE accounts SET balance = balance + ? WHERE id = ?',
            <Object?>[delta, txn.toAccountId],
          );
        }
        break;
      default:
        await db.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          <Object?>[delta, txn.accountId],
        );
    }
  }

  // -------------------------------------------------------------------- tags

  Future<void> _writeTags(DatabaseExecutor db, int txnId, List<String> tags) async {
    await db.delete('transaction_tags', where: 'transaction_id = ?', whereArgs: <Object?>[txnId]);
    for (final tag in tags) {
      final name = tag.trim();
      if (name.isEmpty) continue;
      final existing = await db.query('tags',
          where: 'name = ? COLLATE NOCASE', whereArgs: <Object?>[name], limit: 1);
      int tagId;
      if (existing.isEmpty) {
        tagId = await db.insert('tags', <String, Object?>{'name': name});
      } else {
        tagId = (existing.first['id'] as num).toInt();
      }
      await db.insert(
        'transaction_tags',
        <String, Object?>{'transaction_id': txnId, 'tag_id': tagId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await db.rawDelete(
      'DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM transaction_tags)',
    );
  }

  Future<List<String>> tagsFor(int txnId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT tags.name AS name FROM tags
      INNER JOIN transaction_tags ON transaction_tags.tag_id = tags.id
      WHERE transaction_tags.transaction_id = ?
      ORDER BY tags.name
    ''', <Object?>[txnId]);
    return rows.map((row) => row['name']! as String).toList();
  }

  Future<Map<int, List<String>>> _tagMap() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT transaction_tags.transaction_id AS txn_id, tags.name AS name
      FROM transaction_tags
      INNER JOIN tags ON tags.id = transaction_tags.tag_id
    ''');
    final map = <int, List<String>>{};
    for (final row in rows) {
      final id = (row['txn_id'] as num).toInt();
      map.putIfAbsent(id, () => <String>[]).add(row['name']! as String);
    }
    return map;
  }

  Future<List<String>> allTags() async {
    final db = await _db.database;
    final rows = await db.query('tags', orderBy: 'name COLLATE NOCASE');
    return rows.map((row) => row['name']! as String).toList();
  }

  /// note -> category name, used for smart category suggestions.
  Future<Map<String, String>> noteCategoryHistory() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT transactions.note AS note, categories.name AS category
      FROM transactions
      INNER JOIN categories ON categories.id = transactions.category_id
      WHERE transactions.note IS NOT NULL AND transactions.note != ''
        AND transactions.deleted = 0
      GROUP BY transactions.note
      ORDER BY MAX(transactions.date) DESC
      LIMIT 300
    ''');
    final map = <String, String>{};
    for (final row in rows) {
      final note = (row['note'] as String?)?.trim();
      final category = row['category'] as String?;
      if (note != null && note.isNotEmpty && category != null) {
        map.putIfAbsent(note.toLowerCase(), () => category);
      }
    }
    return map;
  }

  // ------------------------------------------------------------------- reads

  Txn _mapWithTag(Map<String, Object?> row, Map<int, List<String>> tags) {
    final txn = Txn.fromMap(row);
    final list = tags[txn.id] ?? const <String>[];
    return txn.copyWith(tagNames: list);
  }

  Future<List<Txn>> query(
    TransactionFilter filter, {
    int? limit,
    int? offset,
  }) async {
    final db = await _db.database;
    final where = <String>['deleted = 0'];
    final args = <Object?>[];

    if (filter.startDate != null) {
      where.add('date >= ?');
      args.add(DateTime(filter.startDate!.year, filter.startDate!.month, filter.startDate!.day)
          .millisecondsSinceEpoch);
    }
    if (filter.endDate != null) {
      where.add('date <= ?');
      args.add(DateTime(filter.endDate!.year, filter.endDate!.month, filter.endDate!.day,
              23, 59, 59, 999)
          .millisecondsSinceEpoch);
    }
    if (filter.types.isNotEmpty) {
      where.add('type IN (${List.filled(filter.types.length, '?').join(',')})');
      args.addAll(filter.types);
    }
    if (filter.accountIds.isNotEmpty) {
      final placeholders = List.filled(filter.accountIds.length, '?').join(',');
      where.add('(account_id IN ($placeholders) OR to_account_id IN ($placeholders))');
      args.addAll(filter.accountIds);
      args.addAll(filter.accountIds);
    }
    if (filter.categoryIds.isNotEmpty) {
      where.add('category_id IN (${List.filled(filter.categoryIds.length, '?').join(',')})');
      args.addAll(filter.categoryIds);
    }
    if (filter.paymentMethods.isNotEmpty) {
      where.add(
          'payment_method IN (${List.filled(filter.paymentMethods.length, '?').join(',')})');
      args.addAll(filter.paymentMethods);
    }
    if (filter.minAmount != null) {
      where.add('amount >= ?');
      args.add(filter.minAmount);
    }
    if (filter.maxAmount != null) {
      where.add('amount <= ?');
      args.add(filter.maxAmount);
    }
    if (filter.recurringOnly) {
      where.add('recurring_rule_id IS NOT NULL');
    }
    if (filter.includeInReportsOnly == true) {
      where.add('include_in_reports = 1');
    } else if (filter.includeInReportsOnly == false) {
      where.add('include_in_reports = 0');
    }
    if (filter.query != null && filter.query!.trim().isNotEmpty) {
      where.add('(note LIKE ? OR payment_method LIKE ?)');
      final like = '%${filter.query!.trim()}%';
      args..add(like)..add(like);
    }

    String orderBy;
    switch (filter.sort) {
      case 'oldest':
        orderBy = 'date ASC, id ASC';
        break;
      case 'highest':
        orderBy = 'amount DESC';
        break;
      case 'lowest':
        orderBy = 'amount ASC';
        break;
      default:
        orderBy = 'date DESC, id DESC';
    }

    final rows = await db.query(
      'transactions',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    final tagMap = await _tagMap();
    var result = rows.map((row) => _mapWithTag(row, tagMap)).toList();

    // Category / tag / free-text matching needs joins, so refine in memory.
    if (filter.query != null && filter.query!.trim().isNotEmpty) {
      final q = filter.query!.trim().toLowerCase();
      final categories = await db.query('categories');
      final categoryNames = <int, String>{
        for (final row in categories) (row['id'] as num).toInt(): (row['name'] as String)
      };
      final accounts = await db.query('accounts');
      final accountNames = <int, String>{
        for (final row in accounts) (row['id'] as num).toInt(): (row['name'] as String)
      };
      result = result.where((txn) {
        final categoryName = (categoryNames[txn.categoryId] ?? '').toLowerCase();
        final accountName = (accountNames[txn.accountId] ?? '').toLowerCase();
        final note = (txn.note ?? '').toLowerCase();
        final amountText = (txn.amount / 100).toStringAsFixed(2);
        final tags = txn.tagNames.join(' ').toLowerCase();
        return note.contains(q) ||
            categoryName.contains(q) ||
            accountName.contains(q) ||
            tags.contains(q) ||
            amountText.contains(q) ||
            txn.paymentMethod.toLowerCase().contains(q);
      }).toList();
    }

    if (filter.tags.isNotEmpty) {
      result = result
          .where((txn) => filter.tags.any((tag) =>
              txn.tagNames.any((t) => t.toLowerCase() == tag.toLowerCase())))
          .toList();
    }

    return result;
  }

  Future<List<Txn>> recent({int limit = 8}) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: 'deleted = 0',
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    final tagMap = await _tagMap();
    return rows.map((row) => _mapWithTag(row, tagMap)).toList();
  }

  Future<List<Txn>> byRecurringRule(int ruleId, {int limit = 20}) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: 'deleted = 0 AND recurring_rule_id = ?',
      whereArgs: <Object?>[ruleId],
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    final tagMap = await _tagMap();
    return rows.map((row) => _mapWithTag(row, tagMap)).toList();
  }

  Future<Txn?> byId(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final tags = await tagsFor(id);
    final txn = Txn.fromMap(rows.first, tags: tags);
    final attachment = await db.query(
      'attachments',
      where: 'transaction_id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return txn.copyWith(
      attachmentPath:
          attachment.isEmpty ? null : attachment.first['path'] as String?,
    );
  }

  Future<List<Txn>> between(DateTime start, DateTime end,
      {bool includeTransfers = false, bool onlyReports = true}) async {
    final filter = TransactionFilter(
      startDate: start,
      endDate: end,
      includeInReportsOnly: onlyReports ? true : null,
    );
    final all = await query(filter, limit: 20000);
    if (includeTransfers) return all;
    return all.where((t) => t.type != kTypeTransfer).toList();
  }

  Future<List<Txn>> betweenRaw(DateTime start, DateTime end) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: 'deleted = 0 AND date >= ? AND date <= ?',
      whereArgs: <Object?>[
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'date ASC',
    );
    return rows.map(Txn.fromMap).toList();
  }

  // -------------------------------------------------------------- duplicates

  Future<Txn?> findDuplicate(Txn draft) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: 'deleted = 0 AND amount = ? AND account_id = ? AND type = ? AND date BETWEEN ? AND ?',
      whereArgs: <Object?>[
        draft.amount,
        draft.accountId,
        draft.type,
        draft.date - const Duration(hours: 12).inMilliseconds,
        draft.date + const Duration(hours: 12).inMilliseconds,
      ],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Txn.fromMap(rows.first);
  }

  Future<Set<String>> transactionDays({int days = 400}) async {
    final db = await _db.database;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      'SELECT DISTINCT date FROM transactions WHERE deleted = 0 AND date >= ?',
      <Object?>[since],
    );
    return rows.map((row) {
      final date = DateTime.fromMillisecondsSinceEpoch((row['date'] as num).toInt());
      return '${date.year}-${date.month}-${date.day}';
    }).toSet();
  }

  Future<int> count() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM transactions WHERE deleted = 0');
    return (rows.first['c'] as num).toInt();
  }

  // ------------------------------------------------------------- attachments

  Future<void> setAttachment(int txnId, String? path) async {
    final db = await _db.database;
    await db.delete('attachments', where: 'transaction_id = ?', whereArgs: <Object?>[txnId]);
    if (path != null && path.isNotEmpty) {
      await db.insert('attachments', <String, Object?>{
        'transaction_id': txnId,
        'path': path,
        'type': 'image',
      });
    }
    _db.notifyChanged();
  }

  // --------------------------------------------------------------- recurring

  Future<void> materialiseRecurring() async {
    final db = await _db.database;
    final rules = await db.query(
      'recurring_rules',
      where: 'active = 1 AND next_date <= ?',
      whereArgs: <Object?>[DateTime.now().millisecondsSinceEpoch],
    );
    if (rules.isEmpty) return;
    for (final row in rules) {
      final rule = RecurringRule.fromMap(row);
      final accountId = rule.accountId;
      if (accountId == null) continue;
      var next = DateTime.fromMillisecondsSinceEpoch(rule.nextDate);
      var guard = 0;
      while (next.isBefore(DateTime.now()) && guard < 60) {
        await create(
          Txn(
            type: rule.type,
            amount: rule.amount,
            date: next.millisecondsSinceEpoch,
            accountId: accountId,
            categoryId: rule.categoryId,
            note: rule.note,
            paymentMethod: rule.paymentMethod,
            recurringRuleId: rule.id,
          ),
        );
        next = nextOccurrence(next, rule.frequency, interval: rule.interval);
        guard++;
      }
      await db.update(
        'recurring_rules',
        <String, Object?>{
          'next_date': next.millisecondsSinceEpoch,
          'last_run_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: <Object?>[rule.id],
      );
    }
    _db.notifyChanged();
  }

  /// Posts the next occurrence of a single rule and advances its schedule.
  Future<void> processRecurringRule(RecurringRule rule) async {
    final accountId = rule.accountId;
    if (accountId == null || rule.id == null) return;
    final due = DateTime.fromMillisecondsSinceEpoch(rule.nextDate);
    await create(
      Txn(
        type: rule.type,
        amount: rule.amount,
        date: due.millisecondsSinceEpoch,
        accountId: accountId,
        categoryId: rule.categoryId,
        note: rule.note,
        paymentMethod: rule.paymentMethod,
        recurringRuleId: rule.id,
      ),
    );
    await _advanceRule(rule, due);
  }

  /// Skips the current occurrence without recording a transaction.
  Future<void> skipRecurringRule(RecurringRule rule) async {
    if (rule.id == null) return;
    final due = DateTime.fromMillisecondsSinceEpoch(rule.nextDate);
    await _advanceRule(rule, due);
  }

  Future<void> _advanceRule(RecurringRule rule, DateTime from) async {
    final next = nextOccurrence(from, rule.frequency, interval: rule.interval);
    final db = await _db.database;
    await db.update(
      'recurring_rules',
      <String, Object?>{
        'next_date': next.millisecondsSinceEpoch,
        'last_run_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object?>[rule.id],
    );
    _db.notifyChanged();
  }

  Future<List<RecurringRule>> recurringRules() async {
    final db = await _db.database;
    final rows = await db.query('recurring_rules', orderBy: 'next_date ASC');
    return rows.map(RecurringRule.fromMap).toList();
  }

  Future<int> saveRecurringRule(RecurringRule rule) async {
    final db = await _db.database;
    int id;
    if (rule.id == null) {
      id = await db.insert('recurring_rules', rule.toMap()..remove('id'));
    } else {
      await db.update('recurring_rules', rule.toMap(),
          where: 'id = ?', whereArgs: <Object?>[rule.id]);
      id = rule.id!;
    }
    _db.notifyChanged();
    return id;
  }

  Future<void> deleteRecurringRule(int id) async {
    final db = await _db.database;
    await db.delete('recurring_rules', where: 'id = ?', whereArgs: <Object?>[id]);
    _db.notifyChanged();
  }

  Future<void> toggleRecurringRule(int id, bool active) async {
    final db = await _db.database;
    await db.update('recurring_rules', <String, Object?>{'active': active ? 1 : 0},
        where: 'id = ?', whereArgs: <Object?>[id]);
    _db.notifyChanged();
  }
}
