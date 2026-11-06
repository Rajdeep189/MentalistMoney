import 'package:sqflite/sqflite.dart';

/// Optional demo dataset (offered on the first-run setup screen).
class DemoData {
  DemoData._();

  static Future<void> seed(Database db) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final accounts = <Map<String, Object?>>[
      {
        'name': 'Cash',
        'type': 'cash',
        'icon': 'wallet',
        'color': '#12B76A',
        'opening_balance': 250000,
        'balance': 250000,
        'currency': 'INR',
        'include_in_net_worth': 1,
        'archived': 0,
        'created_at': nowMs,
        'updated_at': nowMs,
      },
      {
        'name': 'HDFC Savings',
        'type': 'bank',
        'icon': 'account_balance',
        'color': '#2E90FA',
        'opening_balance': 4800000,
        'balance': 4800000,
        'currency': 'INR',
        'include_in_net_worth': 1,
        'archived': 0,
        'created_at': nowMs,
        'updated_at': nowMs,
      },
      {
        'name': 'ICICI Credit Card',
        'type': 'credit_card',
        'icon': 'credit_card',
        'color': '#0B0B0F',
        'opening_balance': -1250000,
        'balance': -1250000,
        'currency': 'INR',
        'include_in_net_worth': 1,
        'archived': 0,
        'credit_limit': 15000000,
        'statement_day': 5,
        'due_day': 20,
        'created_at': nowMs,
        'updated_at': nowMs,
      },
      {
        'name': 'Paytm Wallet',
        'type': 'wallet',
        'icon': 'account_balance_wallet',
        'color': '#916CFF',
        'opening_balance': 120000,
        'balance': 120000,
        'currency': 'INR',
        'include_in_net_worth': 1,
        'archived': 0,
        'created_at': nowMs,
        'updated_at': nowMs,
      },
      {
        'name': 'Loan to Alice',
        'type': 'custom',
        'icon': 'savings',
        'color': '#E91E63',
        'opening_balance': 4100100,
        'balance': 4100100,
        'currency': 'INR',
        'person': 'Alice',
        'notes': 'Wedding fund',
        'loan_kind': 'lending',
        'start_date': nowMs,
        'end_date': now.add(const Duration(days: 392)).millisecondsSinceEpoch,
        'include_in_net_worth': 0,
        'archived': 0,
        'created_at': nowMs,
        'updated_at': nowMs,
      },
      {
        'name': 'Bike Loan',
        'type': 'loan',
        'icon': 'two_wheeler',
        'color': '#2ED3B7',
        'opening_balance': -1221200,
        'balance': -1221200,
        'currency': 'INR',
        'person': 'Ravi',
        'notes': 'Two-wheeler EMI',
        'loan_kind': 'borrowing',
        'start_date': nowMs,
        'end_date': now.add(const Duration(days: 210)).millisecondsSinceEpoch,
        'include_in_net_worth': 0,
        'archived': 0,
        'created_at': nowMs,
        'updated_at': nowMs,
      },
    ];

    final accountIds = <String, int>{};
    for (final account in accounts) {
      final id = await db.insert('accounts', account);
      accountIds[account['name']! as String] = id;
    }

    final categoryRows = await db.query('categories');
    final categoryIds = <String, int>{
      for (final row in categoryRows) row['name']! as String: row['id']! as int,
    };

    final rows = <Map<String, Object?>>[];
    DateTime at(int daysAgo, int hour, int minute) {
      final date = DateTime(now.year, now.month, now.day, hour, minute)
          .subtract(Duration(days: daysAgo));
      return date;
    }

    void addTxn({
      required int daysAgo,
      required String type,
      required int paise,
      required String category,
      required String account,
      String? toAccount,
      String? note,
      String payment = 'UPI',
      int hour = 12,
      int minute = 30,
    }) {
      rows.add(<String, Object?>{
        'type': type,
        'amount': paise,
        'date': at(daysAgo, hour, minute).millisecondsSinceEpoch,
        'account_id': accountIds[account],
        'to_account_id': toAccount == null ? null : accountIds[toAccount],
        'category_id': categoryIds[category],
        'note': note,
        'payment_method': payment,
        'include_in_reports': 1,
        'created_at': nowMs,
        'updated_at': nowMs,
        'deleted': 0,
      });
    }


    // Current month
    addTxn(daysAgo: 0, type: 'expense', paise: 32000, category: 'Food & Drinks', account: 'Paytm Wallet', note: 'Swiggy lunch', payment: 'UPI', hour: 13);
    addTxn(daysAgo: 1, type: 'expense', paise: 145000, category: 'Groceries', account: 'HDFC Savings', note: 'BigBasket weekly', payment: 'Card', hour: 19);
    addTxn(daysAgo: 2, type: 'expense', paise: 28000, category: 'Transport', account: 'Cash', note: 'Auto to office', payment: 'Cash', hour: 9);
    addTxn(daysAgo: 3, type: 'expense', paise: 249000, category: 'Shopping', account: 'ICICI Credit Card', note: 'Myntra sale', payment: 'Card', hour: 21);
    addTxn(daysAgo: 4, type: 'expense', paise: 89900, category: 'Bills & Utilities', account: 'HDFC Savings', note: 'Electricity bill', payment: 'Net Banking', hour: 11);
    addTxn(daysAgo: 5, type: 'expense', paise: 35000, category: 'Food & Drinks', account: 'Paytm Wallet', note: 'Cafe with team', payment: 'UPI', hour: 18);
    addTxn(daysAgo: 6, type: 'expense', paise: 120000, category: 'Health', account: 'HDFC Savings', note: 'Pharmacy + checkup', payment: 'UPI', hour: 10);
    addTxn(daysAgo: 7, type: 'expense', paise: 19900, category: 'Subscriptions', account: 'ICICI Credit Card', note: 'Netflix', payment: 'Card', hour: 6);
    addTxn(daysAgo: 8, type: 'expense', paise: 6000, category: 'Transport', account: 'Paytm Wallet', note: 'Metro card', payment: 'UPI', hour: 8);
    addTxn(daysAgo: 9, type: 'expense', paise: 45000, category: 'Entertainment', account: 'Cash', note: 'Movie night', payment: 'Cash', hour: 20);
    addTxn(daysAgo: 10, type: 'income', paise: 8500000, category: 'Salary', account: 'HDFC Savings', note: 'Monthly salary', payment: 'Net Banking', hour: 9);
    addTxn(daysAgo: 11, type: 'expense', paise: 1800000, category: 'Rent', account: 'HDFC Savings', note: 'Flat rent', payment: 'Net Banking', hour: 10);
    addTxn(daysAgo: 12, type: 'expense', paise: 96000, category: 'Personal Care', account: 'ICICI Credit Card', note: 'Salon', payment: 'Card', hour: 17);
    addTxn(daysAgo: 13, type: 'income', paise: 1500000, category: 'Freelance', account: 'HDFC Savings', note: 'Design project', payment: 'UPI', hour: 15);
    addTxn(daysAgo: 14, type: 'transfer', paise: 500000, category: 'Savings', account: 'HDFC Savings', toAccount: 'Paytm Wallet', note: 'Wallet top-up', payment: 'UPI', hour: 12);
    addTxn(daysAgo: 15, type: 'expense', paise: 78000, category: 'Food & Drinks', account: 'Paytm Wallet', note: 'Zomato dinner', payment: 'UPI', hour: 21);
    addTxn(daysAgo: 16, type: 'expense', paise: 42000, category: 'Transport', account: 'Cash', note: 'Petrol', payment: 'Cash', hour: 9);

    // Previous month
    addTxn(daysAgo: 40, type: 'income', paise: 8500000, category: 'Salary', account: 'HDFC Savings', note: 'Monthly salary', payment: 'Net Banking', hour: 9);
    addTxn(daysAgo: 41, type: 'expense', paise: 1800000, category: 'Rent', account: 'HDFC Savings', note: 'Flat rent', payment: 'Net Banking', hour: 10);
    addTxn(daysAgo: 43, type: 'expense', paise: 265000, category: 'Groceries', account: 'HDFC Savings', note: 'Monthly groceries', payment: 'Card', hour: 18);
    addTxn(daysAgo: 45, type: 'expense', paise: 89000, category: 'Bills & Utilities', account: 'HDFC Savings', note: 'Electricity bill', payment: 'Net Banking', hour: 11);
    addTxn(daysAgo: 47, type: 'expense', paise: 1250000, category: 'Travel', account: 'ICICI Credit Card', note: 'Train tickets', payment: 'Card', hour: 14);
    addTxn(daysAgo: 50, type: 'expense', paise: 62000, category: 'Food & Drinks', account: 'Paytm Wallet', note: 'Weekend dining', payment: 'UPI', hour: 20);
    addTxn(daysAgo: 52, type: 'expense', paise: 310000, category: 'Shopping', account: 'ICICI Credit Card', note: 'Shoes', payment: 'Card', hour: 16);
    addTxn(daysAgo: 55, type: 'expense', paise: 45000, category: 'Health', account: 'Cash', note: 'Gym membership', payment: 'Cash', hour: 7);

    // Two months back
    addTxn(daysAgo: 70, type: 'income', paise: 8500000, category: 'Salary', account: 'HDFC Savings', note: 'Monthly salary', payment: 'Net Banking', hour: 9);
    addTxn(daysAgo: 71, type: 'expense', paise: 1800000, category: 'Rent', account: 'HDFC Savings', note: 'Flat rent', payment: 'Net Banking', hour: 10);
    addTxn(daysAgo: 73, type: 'expense', paise: 298000, category: 'Groceries', account: 'HDFC Savings', note: 'Groceries', payment: 'Card', hour: 18);
    addTxn(daysAgo: 76, type: 'expense', paise: 175000, category: 'Food & Drinks', account: 'Paytm Wallet', note: 'Dining out', payment: 'UPI', hour: 20);
    addTxn(daysAgo: 78, type: 'expense', paise: 96000, category: 'Bills & Utilities', account: 'HDFC Savings', note: 'Wifi + gas', payment: 'UPI', hour: 11);
    addTxn(daysAgo: 80, type: 'expense', paise: 210000, category: 'Education', account: 'HDFC Savings', note: 'Online course', payment: 'Card', hour: 15);

    for (final row in rows) {
      await db.insert('transactions', row);
    }

    // Recompute balances from the inserted data.
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

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));

    Future<int> budget({
      required String name,
      required int amount,
      required String type,
      required String icon,
      required String color,
      List<String> categories = const <String>[],
      String period = 'monthly',
    }) async {
      final id = await db.insert('budgets', <String, Object?>{
        'name': name,
        'amount': amount,
        'period': period,
        'start_date': monthStart.millisecondsSinceEpoch,
        'end_date': monthEnd.millisecondsSinceEpoch,
        'type': type,
        'rollover': 0,
        'carry_forward': 0,
        'color': color,
        'icon': icon,
        'archived': 0,
      });
      for (final category in categories) {
        final categoryId = categoryIds[category];
        if (categoryId != null) {
          await db.insert('budget_categories', <String, Object?>{
            'budget_id': id,
            'category_id': categoryId,
          });
        }
      }
      return id;
    }

    await budget(name: 'Monthly budget', amount: 4500000, type: 'overall', icon: 'savings', color: '#916CFF');
    await budget(name: 'Food & Drinks', amount: 600000, type: 'category', icon: 'restaurant', color: '#F79009', categories: <String>['Food & Drinks']);
    await budget(name: 'Transport', amount: 300000, type: 'category', icon: 'directions_car', color: '#2E90FA', categories: <String>['Transport']);
    await budget(name: 'Shopping', amount: 400000, type: 'category', icon: 'shopping_bag', color: '#E4559C', categories: <String>['Shopping']);

    final goalRows = <Map<String, Object?>>[
      {
        'name': 'Emergency Fund',
        'target_amount': 30000000,
        'saved_amount': 12000000,
        'deadline': DateTime(now.year + 1, 3, 31).millisecondsSinceEpoch,
        'icon': 'savings',
        'color': '#12B76A',
        'status': 'active',
        'recurring_amount': 500000,
        'created_at': nowMs,
        'notes': 'Six months of expenses',
      },
      {
        'name': 'Goa Trip',
        'target_amount': 8000000,
        'saved_amount': 2400000,
        'deadline': DateTime(now.year, now.month + 4, 15).millisecondsSinceEpoch,
        'icon': 'beach_access',
        'color': '#916CFF',
        'status': 'active',
        'recurring_amount': 200000,
        'created_at': nowMs,
        'notes': null,
      },
      {
        'name': 'New Laptop',
        'target_amount': 12000000,
        'saved_amount': 12000000,
        'deadline': DateTime(now.year, now.month - 1, 20).millisecondsSinceEpoch,
        'icon': 'laptop_mac',
        'color': '#2E90FA',
        'status': 'completed',
        'recurring_amount': 0,
        'created_at': nowMs,
        'notes': null,
      },
    ];

    for (final goal in goalRows) {
      final id = await db.insert('goals', goal);
      await db.insert('goal_contributions', <String, Object?>{
        'goal_id': id,
        'amount': goal['saved_amount'],
        'date': at(20, 10, 0).millisecondsSinceEpoch,
        'account_id': accountIds['HDFC Savings'],
        'note': 'Initial contribution',
      });
    }

    final billRows = <Map<String, Object?>>[
      {
        'name': 'Electricity bill',
        'amount': 89900,
        'due_date': at(-3, 10, 0).millisecondsSinceEpoch,
        'frequency': 'monthly',
        'account_id': accountIds['HDFC Savings'],
        'category_id': categoryIds['Bills & Utilities'],
        'auto_create_txn': 1,
        'status': 'upcoming',
      },
      {
        'name': 'Broadband',
        'amount': 79900,
        'due_date': at(-6, 10, 0).millisecondsSinceEpoch,
        'frequency': 'monthly',
        'account_id': accountIds['HDFC Savings'],
        'category_id': categoryIds['Bills & Utilities'],
        'auto_create_txn': 1,
        'status': 'upcoming',
      },
      {
        'name': 'Netflix',
        'amount': 19900,
        'due_date': at(-9, 10, 0).millisecondsSinceEpoch,
        'frequency': 'monthly',
        'account_id': accountIds['ICICI Credit Card'],
        'category_id': categoryIds['Subscriptions'],
        'auto_create_txn': 1,
        'status': 'upcoming',
      },
      {
        'name': 'House rent',
        'amount': 1800000,
        'due_date': at(1, 10, 0).millisecondsSinceEpoch,
        'frequency': 'monthly',
        'account_id': accountIds['HDFC Savings'],
        'category_id': categoryIds['Rent'],
        'auto_create_txn': 1,
        'status': 'upcoming',
      },
      {
        'name': 'Mobile recharge',
        'amount': 39900,
        'due_date': at(12, 10, 0).millisecondsSinceEpoch,
        'frequency': 'monthly',
        'account_id': accountIds['Paytm Wallet'],
        'category_id': categoryIds['Bills & Utilities'],
        'auto_create_txn': 1,
        'status': 'upcoming',
      },
    ];
    for (final bill in billRows) {
      await db.insert('bills', bill);
    }

    // Split group demo
    final groupId = await db.insert('split_groups', <String, Object?>{
      'name': 'Goa Trip',
      'icon': 'groups',
      'created_at': nowMs,
    });
    final memberIds = <int>[];
    for (final name in <String>['You', 'Rahul', 'Amit', 'Priya']) {
      memberIds.add(await db.insert('split_members', <String, Object?>{
        'group_id': groupId,
        'name': name,
      }));
    }
    final expenseId = await db.insert('split_expenses', <String, Object?>{
      'group_id': groupId,
      'amount': 600000,
      'paid_by_member_id': memberIds[1],
      'date': at(12, 18, 0).millisecondsSinceEpoch,
      'category_id': categoryIds['Travel'],
      'description': 'Hotel booking',
      'split_method': 'equal',
    });
    for (final memberId in memberIds) {
      await db.insert('split_shares', <String, Object?>{
        'expense_id': expenseId,
        'member_id': memberId,
        'value': 150000,
      });
    }
    final fuelExpense = await db.insert('split_expenses', <String, Object?>{
      'group_id': groupId,
      'amount': 320000,
      'paid_by_member_id': memberIds[0],
      'date': at(11, 9, 0).millisecondsSinceEpoch,
      'category_id': categoryIds['Transport'],
      'description': 'Rented scooter + fuel',
      'split_method': 'equal',
    });
    for (final memberId in memberIds) {
      await db.insert('split_shares', <String, Object?>{
        'expense_id': fuelExpense,
        'member_id': memberId,
        'value': 80000,
      });
    }
  }
}
