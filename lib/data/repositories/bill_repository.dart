import '../db/app_database.dart';
import '../models/models.dart';
import 'transaction_repository.dart';

class BillRepository {
  BillRepository(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionRepository _transactions;

  Future<List<Bill>> all() async {
    final db = await _db.database;
    final rows = await db.query('bills', orderBy: 'due_date ASC');
    return rows.map(Bill.fromMap).toList();
  }

  Future<Bill?> byId(int id) async {
    final db = await _db.database;
    final rows = await db.query('bills', where: 'id = ?', whereArgs: <Object?>[id], limit: 1);
    if (rows.isEmpty) return null;
    return Bill.fromMap(rows.first);
  }

  Future<List<Bill>> upcoming({int limit = 3}) async {
    final bills = await all();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = bills
        .where((b) => b.status != kBillPaid && b.dueDate >= now - const Duration(days: 45).inMilliseconds)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.take(limit).toList();
  }

  Future<int> create(Bill bill) async {
    final db = await _db.database;
    final id = await db.insert('bills', bill.toMap()..remove('id'));
    _db.notifyChanged();
    return id;
  }

  Future<void> update(Bill bill) async {
    final db = await _db.database;
    await db.update('bills', bill.toMap(), where: 'id = ?', whereArgs: <Object?>[bill.id]);
    _db.notifyChanged();
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('bills', where: 'id = ?', whereArgs: <Object?>[id]);
    _db.notifyChanged();
  }

  /// Marks a bill paid: optionally books the expense and rolls the due date for
  /// recurring bills.
  Future<void> markPaid(Bill bill, {required DateTime paidOn, bool createTransaction = true}) async {
    final db = await _db.database;
    if (createTransaction && bill.accountId != null) {
      await _transactions.create(
        Txn(
          type: kTypeExpense,
          amount: bill.amount,
          date: paidOn.millisecondsSinceEpoch,
          accountId: bill.accountId!,
          categoryId: bill.categoryId,
          note: bill.name,
          paymentMethod: 'Net Banking',
        ),
      );
    }
    if (bill.frequency == 'one_time') {
      await db.update(
        'bills',
        <String, Object?>{'status': kBillPaid, 'last_paid_at': paidOn.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: <Object?>[bill.id],
      );
    } else {
      final current = DateTime.fromMillisecondsSinceEpoch(bill.dueDate);
      var next = nextOccurrence(current, bill.frequency);
      while (next.isBefore(DateTime.now())) {
        next = nextOccurrence(next, bill.frequency);
      }
      await db.update(
        'bills',
        <String, Object?>{
          'due_date': next.millisecondsSinceEpoch,
          'last_paid_at': paidOn.millisecondsSinceEpoch,
          'status': kBillUpcoming,
        },
        where: 'id = ?',
        whereArgs: <Object?>[bill.id],
      );
    }
    _db.notifyChanged();
  }

  /// Skips the current occurrence (moves the due date forward).
  Future<void> skipOccurrence(Bill bill) async {
    final db = await _db.database;
    if (bill.frequency == 'one_time') {
      await db.update('bills', <String, Object?>{'status': kBillSkipped},
          where: 'id = ?', whereArgs: <Object?>[bill.id]);
    } else {
      final current = DateTime.fromMillisecondsSinceEpoch(bill.dueDate);
      final next = nextOccurrence(current, bill.frequency);
      await db.update('bills', <String, Object?>{'due_date': next.millisecondsSinceEpoch},
          where: 'id = ?', whereArgs: <Object?>[bill.id]);
    }
    _db.notifyChanged();
  }

  Future<void> snooze(Bill bill, int days) async {
    final db = await _db.database;
    final due = DateTime.fromMillisecondsSinceEpoch(bill.dueDate).add(Duration(days: days));
    await db.update('bills', <String, Object?>{'due_date': due.millisecondsSinceEpoch},
        where: 'id = ?', whereArgs: <Object?>[bill.id]);
    _db.notifyChanged();
  }

  Future<void> reopen(Bill bill) async {
    final db = await _db.database;
    await db.update('bills', <String, Object?>{'status': kBillUpcoming},
        where: 'id = ?', whereArgs: <Object?>[bill.id]);
    _db.notifyChanged();
  }

  Future<Map<DateTime, List<Bill>>> calendarFor(DateTime month) async {
    final bills = await all();
    final grouped = <DateTime, List<Bill>>{};
    for (final bill in bills) {
      final due = DateTime.fromMillisecondsSinceEpoch(bill.dueDate);
      if (due.year != month.year || due.month != month.month) continue;
      final key = DateTime(due.year, due.month, due.day);
      grouped.putIfAbsent(key, () => <Bill>[]).add(bill);
    }
    return grouped;
  }
}
