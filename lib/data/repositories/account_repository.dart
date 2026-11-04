import '../db/app_database.dart';
import '../models/models.dart';

class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  Future<List<Account>> all({bool includeArchived = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'accounts',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'archived ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(Account.fromMap).toList();
  }

  Future<List<Account>> archived() async {
    final db = await _db.database;
    final rows = await db.query('accounts', where: 'archived = 1');
    return rows.map(Account.fromMap).toList();
  }

  Future<Account?> byId(int id) async {
    final db = await _db.database;
    final rows = await db.query('accounts', where: 'id = ?', whereArgs: <Object?>[id], limit: 1);
    if (rows.isEmpty) return null;
    return Account.fromMap(rows.first);
  }

  Future<int> create(Account account) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert('accounts', account.copyWith(
      createdAt: now,
      updatedAt: now,
      balance: account.openingBalance,
    ).toMap()..remove('id'));
    _db.notifyChanged();
    return id;
  }

  Future<void> update(Account account) async {
    final db = await _db.database;
    await db.update(
      'accounts',
      account.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch).toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[account.id],
    );
    _db.notifyChanged();
  }

  Future<void> setArchived(int id, bool archived) async {
    final db = await _db.database;
    await db.update(
      'accounts',
      <String, Object?>{
        'archived': archived ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    _db.notifyChanged();
  }

  /// Deletes an account together with its transactions.
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Remove the "other side" effect of transfers before dropping rows.
      final transfers = await txn.query(
        'transactions',
        where: 'to_account_id = ? AND deleted = 0',
        whereArgs: <Object?>[id],
      );
      for (final row in transfers) {
        final amount = (row['amount'] as num).toInt();
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          <Object?>[amount, row['account_id']],
        );
      }
      await txn.delete('transactions', where: 'account_id = ?', whereArgs: <Object?>[id]);
      await txn.delete('accounts', where: 'id = ?', whereArgs: <Object?>[id]);
    });
    _db.notifyChanged();
  }

  /// Recomputes every balance from the transaction ledger (used after imports).
  Future<void> recalculateBalances() async {
    final db = await _db.database;
    await db.rawUpdate('''
      UPDATE accounts SET balance = opening_balance + COALESCE((
        SELECT SUM(CASE
          WHEN type = 'income' THEN amount
          WHEN type = 'expense' THEN -amount
          ELSE -amount END)
        FROM transactions
        WHERE transactions.account_id = accounts.id AND deleted = 0
      ), 0) + COALESCE((
        SELECT SUM(amount) FROM transactions
        WHERE transactions.to_account_id = accounts.id
          AND transactions.type = 'transfer' AND deleted = 0
      ), 0)
    ''');
    _db.notifyChanged();
  }

  Future<int> netWorth() async {
    final accounts = await all();
    var total = 0;
    for (final account in accounts) {
      if (!account.includeInNetWorth) continue;
      total += account.balance;
    }
    return total;
  }

  Future<Map<String, int>> totals() async {
    final accounts = await all();
    var assets = 0;
    var liabilities = 0;
    for (final account in accounts) {
      if (!account.includeInNetWorth) continue;
      if (account.balance >= 0) {
        assets += account.balance;
      } else {
        liabilities += account.balance.abs();
      }
    }
    return <String, int>{'assets': assets, 'liabilities': liabilities};
  }
}
