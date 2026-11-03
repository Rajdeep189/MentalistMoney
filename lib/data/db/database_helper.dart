import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Offline-first SQLite store (sqflite). All app data lives on-device.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();

  DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'mentalist.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance REAL NOT NULL,
            masked_number TEXT NOT NULL,
            color1 INTEGER NOT NULL,
            color2 INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            note TEXT NOT NULL,
            account_id INTEGER NOT NULL,
            tags TEXT NOT NULL,
            split_with TEXT NOT NULL,
            date INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_key TEXT NOT NULL,
            limit_amount REAL NOT NULL,
            period TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE subscriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            from_name TEXT NOT NULL,
            to_name TEXT NOT NULL,
            amount REAL NOT NULL,
            cycle TEXT NOT NULL,
            next_due INTEGER NOT NULL,
            issued INTEGER NOT NULL,
            is_paid INTEGER NOT NULL,
            color INTEGER NOT NULL,
            icon_code INTEGER NOT NULL,
            icon_font_family TEXT,
            items TEXT NOT NULL
          )''');
      },
    );
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table, {String orderBy = 'id DESC'}) async {
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  Future<int> update(String table, Map<String, dynamic> row, String where, List<Object?> whereArgs) async {
    final db = await database;
    return db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<Object?> whereArgs) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<int> count(String table) async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return Sqflite.firstIntValue(r) ?? 0;
  }
}
