import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'demo_data.dart';
import 'seed_data.dart';

/// Offline-first SQLite database (the single source of truth).
///
/// The whole app listens to [revision]; every mutation calls [notifyChanged]
/// so Riverpod providers re-query automatically.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int schemaVersion = 2;
  static const String fileName = 'moneyman.db';

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _opening ??= _open();
    return _opening!;
  }

  void notifyChanged() {
    revision.value = revision.value + 1;
  }

  Future<String> get databasePath async {
    final dir = await getDatabasesPath();
    return p.join(dir, fileName);
  }

  Future<Database> _open() async {
    final path = await databasePath;
    final db = await openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
      onUpgrade: _upgrade,
    );
    _db = db;
    return db;
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    // Migrations are additive and idempotent so upgrades never lose data.
    if (oldVersion < 2) {
      await _addColumnIfMissing(db, 'accounts', 'icon', "TEXT DEFAULT 'wallet'");
      await _addColumnIfMissing(db, 'accounts', 'person', 'TEXT');
      await _addColumnIfMissing(db, 'accounts', 'start_date', 'INTEGER');
      await _addColumnIfMissing(db, 'accounts', 'end_date', 'INTEGER');
      await _addColumnIfMissing(db, 'accounts', 'category_id', 'INTEGER');
      await _addColumnIfMissing(db, 'accounts', 'loan_kind', 'TEXT');
      await _addColumnIfMissing(db, 'tags', 'color', "TEXT DEFAULT '#A855F7'");
      await _addColumnIfMissing(db, 'transactions', 'budget_id', 'INTEGER');
      await _addColumnIfMissing(db, 'transactions', 'loan_account_id', 'INTEGER');
      await _addColumnIfMissing(db, 'transactions', 'place', 'TEXT');
      await _addColumnIfMissing(db, 'transactions', 'payee', 'TEXT');
      await db.execute('''CREATE TABLE IF NOT EXISTS places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'place',
        color TEXT DEFAULT '#2ED3B7',
        created_at INTEGER
      )''');
      await db.execute('''CREATE TABLE IF NOT EXISTS people (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'person',
        color TEXT DEFAULT '#E91E63',
        created_at INTEGER
      )''');
      await db.execute('''CREATE TABLE IF NOT EXISTS templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        amount INTEGER NOT NULL DEFAULT 0,
        icon TEXT DEFAULT 'receipt_long',
        color TEXT DEFAULT '#8A6A5C',
        account_id INTEGER,
        category_id INTEGER,
        note TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      )''');
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _opening = null;
  }

  /// Deletes every row (keeps settings + schema).
  Future<void> wipeData({bool keepSettings = true}) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in <String>[
        'transaction_tags',
        'templates',
        'places',
        'people',
        'attachments',
        'transactions',
        'tags',
        'budget_categories',
        'budgets',
        'goal_contributions',
        'goals',
        'bills',
        'recurring_rules',
        'split_shares',
        'split_expenses',
        'split_members',
        'settlements',
        'split_groups',
        'accounts',
      ]) {
        await txn.delete(table);
      }
      if (!keepSettings) {
        await txn.delete('settings');
        await txn.delete('categories');
        await txn.delete('achievements');
      } else {
        await txn.delete('categories');
        await txn.delete('achievements');
        await _seedCategories(txn);
        await _seedAchievements(txn);
      }
    });
    notifyChanged();
  }

  // --------------------------------------------------------------- schema

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'INR',
        currency_symbol TEXT NOT NULL DEFAULT '₹',
        created_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'wallet',
        color TEXT NOT NULL DEFAULT '#916CFF',
        opening_balance INTEGER NOT NULL DEFAULT 0,
        balance INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'INR',
        notes TEXT,
        include_in_net_worth INTEGER NOT NULL DEFAULT 1,
        archived INTEGER NOT NULL DEFAULT 0,
        credit_limit INTEGER,
        statement_day INTEGER,
        due_day INTEGER,
        person TEXT,
        start_date INTEGER,
        end_date INTEGER,
        category_id INTEGER,
        loan_kind TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'category',
        color TEXT NOT NULL DEFAULT '#916CFF',
        parent_id INTEGER,
        monthly_budget INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        date INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        to_account_id INTEGER,
        category_id INTEGER,
        note TEXT,
        payment_method TEXT NOT NULL DEFAULT 'UPI',
        include_in_reports INTEGER NOT NULL DEFAULT 1,
        recurring_rule_id INTEGER,
        budget_id INTEGER,
        loan_account_id INTEGER,
        place TEXT,
        payee TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (to_account_id) REFERENCES accounts (id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT DEFAULT '#A855F7'
      )
    ''');

    batch.execute('''
      CREATE TABLE transaction_tags (
        transaction_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (transaction_id, tag_id),
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'place',
        color TEXT DEFAULT '#2ED3B7',
        created_at INTEGER
      )
    ''');

    batch.execute('''
      CREATE TABLE people (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'person',
        color TEXT DEFAULT '#E91E63',
        created_at INTEGER
      )
    ''');

    batch.execute('''
      CREATE TABLE templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        amount INTEGER NOT NULL DEFAULT 0,
        icon TEXT DEFAULT 'receipt_long',
        color TEXT DEFAULT '#8A6A5C',
        account_id INTEGER,
        category_id INTEGER,
        note TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'image',
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL,
        period TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'overall',
        rollover INTEGER NOT NULL DEFAULT 0,
        carry_forward INTEGER NOT NULL DEFAULT 0,
        color TEXT NOT NULL DEFAULT '#916CFF',
        icon TEXT NOT NULL DEFAULT 'savings',
        archived INTEGER NOT NULL DEFAULT 0,
        account_id INTEGER,
        alert_thresholds TEXT NOT NULL DEFAULT '50,75,90,100',
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE budget_categories (
        budget_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        PRIMARY KEY (budget_id, category_id),
        FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount INTEGER NOT NULL,
        saved_amount INTEGER NOT NULL DEFAULT 0,
        deadline INTEGER,
        account_id INTEGER,
        category_id INTEGER,
        icon TEXT NOT NULL DEFAULT 'flag',
        color TEXT NOT NULL DEFAULT '#916CFF',
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        recurring_amount INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE goal_contributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        date INTEGER NOT NULL,
        account_id INTEGER,
        note TEXT,
        transaction_id INTEGER,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL,
        due_date INTEGER NOT NULL,
        frequency TEXT NOT NULL DEFAULT 'monthly',
        account_id INTEGER,
        category_id INTEGER,
        reminder_at INTEGER,
        auto_create_txn INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'upcoming',
        last_paid_at INTEGER,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE recurring_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        frequency TEXT NOT NULL,
        interval INTEGER NOT NULL DEFAULT 1,
        next_date INTEGER NOT NULL,
        end_date INTEGER,
        type TEXT NOT NULL DEFAULT 'expense',
        amount INTEGER NOT NULL,
        account_id INTEGER,
        category_id INTEGER,
        payment_method TEXT NOT NULL DEFAULT 'UPI',
        note TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        last_run_at INTEGER,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE split_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'group',
        created_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE split_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES split_groups (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE split_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        paid_by_member_id INTEGER NOT NULL,
        date INTEGER NOT NULL,
        category_id INTEGER,
        description TEXT,
        split_method TEXT NOT NULL DEFAULT 'equal',
        FOREIGN KEY (group_id) REFERENCES split_groups (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE split_shares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER NOT NULL,
        member_id INTEGER NOT NULL,
        value INTEGER NOT NULL,
        FOREIGN KEY (expense_id) REFERENCES split_expenses (id) ON DELETE CASCADE,
        FOREIGN KEY (member_id) REFERENCES split_members (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE settlements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        from_member_id INTEGER NOT NULL,
        to_member_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (group_id) REFERENCES split_groups (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'emoji_events',
        unlocked INTEGER NOT NULL DEFAULT 0,
        unlocked_at INTEGER,
        progress INTEGER NOT NULL DEFAULT 0,
        target INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Indexes
    batch.execute('CREATE INDEX idx_txn_date ON transactions (date)');
    batch.execute('CREATE INDEX idx_txn_category ON transactions (category_id)');
    batch.execute('CREATE INDEX idx_txn_account ON transactions (account_id)');
    batch.execute('CREATE INDEX idx_txn_to_account ON transactions (to_account_id)');
    batch.execute('CREATE INDEX idx_txn_type ON transactions (type)');
    batch.execute('CREATE INDEX idx_goal_contrib_goal ON goal_contributions (goal_id)');
    batch.execute('CREATE INDEX idx_budget_cat_budget ON budget_categories (budget_id)');
    batch.execute('CREATE INDEX idx_split_shares_expense ON split_shares (expense_id)');

    await batch.commit(noResult: true);
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final entry in defaultSettings().entries) {
      batch.insert(
        'settings',
        <String, Object?>{'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    batch.insert('user_profile', <String, Object?>{
      'name': 'there',
      'currency_code': 'INR',
      'currency_symbol': '₹',
      'created_at': now,
    });
    await batch.commit(noResult: true);
    await _seedCategories(db);
    await _seedAchievements(db);
  }

  Future<void> _seedCategories(DatabaseExecutor db) async {
    final batch = db.batch();
    var order = 0;
    for (final category in kSeedCategories) {
      batch.insert('categories', <String, Object?>{
        'name': category.name,
        'type': category.type,
        'icon': category.icon,
        'color': category.color,
        'monthly_budget': 0,
        'archived': 0,
        'sort_order': order++,
        'is_favorite': category.isFavorite ? 1 : 0,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedAchievements(DatabaseExecutor db) async {
    final batch = db.batch();
    for (final achievement in kSeedAchievements) {
      batch.insert('achievements', <String, Object?>{
        'key': achievement.key,
        'name': achievement.name,
        'description': achievement.description,
        'icon': achievement.icon,
        'unlocked': 0,
        'progress': 0,
        'target': achievement.target,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Inserts optional demo data so a brand-new install is not empty.
  Future<void> seedDemoData() async {
    final db = await database;
    await DemoData.seed(db);
    notifyChanged();
  }
}
