import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<AppSettings> load() async {
    final db = await _db.database;
    final rows = await db.query('settings');
    final map = <String, String>{};
    for (final row in rows) {
      final key = row['key'] as String?;
      final value = row['value'] as String?;
      if (key != null && value != null) map[key] = value;
    }
    return AppSettings(map);
  }

  Future<void> set(String key, String value) async {
    final db = await _db.database;
    await db.insert(
      'settings',
      <String, Object?>{'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _db.notifyChanged();
  }

  Future<void> setBool(String key, bool value) => set(key, value ? 'true' : 'false');

  Future<void> setInt(String key, int value) => set(key, '$value');

  Future<void> setMany(Map<String, String> values) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final entry in values.entries) {
      batch.insert(
        'settings',
        <String, Object?>{'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _db.notifyChanged();
  }

  Future<void> increment(String key) async {
    final current = await load();
    await setInt(key, current.integer(key, 0) + 1);
  }
}
