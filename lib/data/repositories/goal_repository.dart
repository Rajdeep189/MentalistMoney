import '../db/app_database.dart';
import '../models/models.dart';
import 'transaction_repository.dart';

class GoalRepository {
  GoalRepository(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionRepository _transactions;

  Future<List<Goal>> all() async {
    final db = await _db.database;
    final rows = await db.query('goals', orderBy: 'status ASC, created_at DESC');
    return rows.map(Goal.fromMap).toList();
  }

  Future<Goal?> byId(int id) async {
    final db = await _db.database;
    final rows = await db.query('goals', where: 'id = ?', whereArgs: <Object?>[id], limit: 1);
    if (rows.isEmpty) return null;
    return Goal.fromMap(rows.first);
  }

  Future<int> create(Goal goal) async {
    final db = await _db.database;
    final id = await db.insert('goals', goal.copyWith(
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ).toMap()..remove('id'));
    _db.notifyChanged();
    return id;
  }

  Future<void> update(Goal goal) async {
    final db = await _db.database;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: <Object?>[goal.id]);
    _db.notifyChanged();
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('goals', where: 'id = ?', whereArgs: <Object?>[id]);
    _db.notifyChanged();
  }

  Future<List<GoalContribution>> contributions(int goalId) async {
    final db = await _db.database;
    final rows = await db.query(
      'goal_contributions',
      where: 'goal_id = ?',
      whereArgs: <Object?>[goalId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(GoalContribution.fromMap).toList();
  }

  Future<int> activeCount() async {
    final goals = await all();
    return goals.where((g) => g.status == kGoalActive).length;
  }

  Future<int> totalSaved() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COALESCE(SUM(saved_amount),0) AS t FROM goals');
    return (rows.first['t'] as num?)?.toInt() ?? 0;
  }

  /// Adds a contribution, updates the goal and optionally books a matching
  /// "Savings" transaction so the account balance stays in sync.
  Future<void> addContribution({
    required Goal goal,
    required int amount,
    required DateTime date,
    int? accountId,
    String? note,
    bool createTransaction = true,
    String? savingsCategory,
  }) async {
    final db = await _db.database;
    int? txnId;
    if (createTransaction && accountId != null) {
      int? categoryId = goal.categoryId;
      if (categoryId == null && savingsCategory != null) {
        final rows = await db.query('categories',
            where: 'name = ? AND type = ?',
            whereArgs: <Object?>[savingsCategory, kTypeExpense],
            limit: 1);
        if (rows.isNotEmpty) categoryId = (rows.first['id'] as num).toInt();
      }
      txnId = await _transactions.create(
        Txn(
          type: kTypeExpense,
          amount: amount,
          date: date.millisecondsSinceEpoch,
          accountId: accountId,
          categoryId: categoryId,
          note: note ?? 'Goal: ${goal.name}',
          paymentMethod: 'Net Banking',
        ),
      );
    }

    await db.insert('goal_contributions', <String, Object?>{
      'goal_id': goal.id,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'account_id': accountId,
      'note': note,
      'transaction_id': txnId,
    });

    final newSaved = goal.savedAmount + amount;
    await db.update(
      'goals',
      <String, Object?>{
        'saved_amount': newSaved,
        'status': newSaved >= goal.targetAmount ? kGoalCompleted : goal.status,
      },
      where: 'id = ?',
      whereArgs: <Object?>[goal.id],
    );
    _db.notifyChanged();
  }

  Future<void> setStatus(int goalId, String status) async {
    final db = await _db.database;
    await db.update('goals', <String, Object?>{'status': status},
        where: 'id = ?', whereArgs: <Object?>[goalId]);
    _db.notifyChanged();
  }

  Future<void> deleteContribution(GoalContribution contribution, int goalId) async {
    final db = await _db.database;
    final goal = await byId(goalId);
    if (goal == null) return;
    await db.delete('goal_contributions',
        where: 'id = ?', whereArgs: <Object?>[contribution.id]);
    await db.update(
      'goals',
      <String, Object?>{
        'saved_amount': (goal.savedAmount - contribution.amount).clamp(0, 1 << 62),
      },
      where: 'id = ?',
      whereArgs: <Object?>[goalId],
    );
    if (contribution.transactionId != null) {
      await _transactions.delete(contribution.transactionId!);
    }
    _db.notifyChanged();
  }
}
