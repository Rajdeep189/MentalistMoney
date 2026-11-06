import '../db/app_database.dart';
import '../models/models.dart';

class AchievementRepository {
  AchievementRepository(this._db);

  final AppDatabase _db;

  Future<List<Achievement>> all() async {
    final db = await _db.database;
    final rows = await db.query('achievements', orderBy: 'unlocked DESC, id ASC');
    return rows.map(Achievement.fromMap).toList();
  }

  Future<void> setProgress(String key, int progress) async {
    final db = await _db.database;
    final rows = await db.query('achievements', where: 'key = ?', whereArgs: <Object?>[key], limit: 1);
    if (rows.isEmpty) return;
    final achievement = Achievement.fromMap(rows.first);
    final target = achievement.target;
    final unlocked = achievement.unlocked || progress >= target;
    await db.update(
      'achievements',
      <String, Object?>{
        'progress': progress,
        'unlocked': unlocked ? 1 : 0,
        'unlocked_at': unlocked && achievement.unlockedAt == null
            ? DateTime.now().millisecondsSinceEpoch
            : achievement.unlockedAt,
      },
      where: 'key = ?',
      whereArgs: <Object?>[key],
    );
    _db.notifyChanged();
  }

  Future<void> unlock(String key) async {
    final db = await _db.database;
    final rows = await db.query('achievements', where: 'key = ?', whereArgs: <Object?>[key], limit: 1);
    if (rows.isEmpty) return;
    final achievement = Achievement.fromMap(rows.first);
    await db.update(
      'achievements',
      <String, Object?>{
        'unlocked': 1,
        'progress': achievement.target,
        'unlocked_at': achievement.unlockedAt ?? DateTime.now().millisecondsSinceEpoch,
      },
      where: 'key = ?',
      whereArgs: <Object?>[key],
    );
    _db.notifyChanged();
  }

  /// Recomputes every achievement from live data.
  Future<void> refresh({required int txnCount, required int streak, required int goalsCompleted, required int savedPaise, required int budgetsCount, required int reportsOpened, required bool premiumTouched}) async {
    await setProgress('first_transaction', txnCount >= 1 ? 1 : 0);
    await setProgress('txn_100', txnCount);
    await setProgress('streak_7', streak);
    await setProgress('streak_30', streak);
    await setProgress('first_budget', budgetsCount >= 1 ? 1 : 0);
    await setProgress('first_goal', goalsCompleted >= 1 ? 1 : 0);
    await setProgress('saved_10k', savedPaise);
    await setProgress('reports_10', reportsOpened);
    if (premiumTouched) await unlock('premium_explorer');
  }
}
