import 'package:flutter_test/flutter_test.dart';
import 'package:moneyman/data/db/app_database.dart';
import 'package:moneyman/data/models/models.dart';
import 'package:moneyman/data/repositories/account_repository.dart';
import 'package:moneyman/data/repositories/achievement_repository.dart';
import 'package:moneyman/data/repositories/bill_repository.dart';
import 'package:moneyman/data/repositories/budget_repository.dart';
import 'package:moneyman/data/repositories/category_repository.dart';
import 'package:moneyman/data/repositories/goal_repository.dart';
import 'package:moneyman/data/repositories/split_repository.dart';
import 'package:moneyman/data/repositories/stats_repository.dart';
import 'package:moneyman/data/repositories/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Exercises the real schema, seeds and repositories against an in-memory
/// SQLite database so data-layer regressions fail CI instead of the app.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase db;
  late TransactionRepository transactions;
  late AccountRepository accounts;
  late CategoryRepository categories;
  late BudgetRepository budgets;
  late GoalRepository goals;
  late BillRepository bills;
  late SplitRepository splits;
  late StatsRepository stats;
  late AchievementRepository achievements;

  setUp(() async {
    db = AppDatabase.instance;
    await db.wipeData();
    await db.database;
    transactions = TransactionRepository(db);
    accounts = AccountRepository(db);
    categories = CategoryRepository(db);
    budgets = BudgetRepository(db);
    goals = GoalRepository(db, transactions);
    bills = BillRepository(db, transactions);
    splits = SplitRepository(db);
    stats = StatsRepository(db);
    achievements = AchievementRepository(db);

    if ((await accounts.all()).isEmpty) {
      await accounts.create(
        const Account(
          name: 'Cash',
          type: kAccountCash,
          icon: 'wallet',
          color: '#12B76A',
          openingBalance: 500000,
          balance: 500000,
        ),
      );
    }
  });

  tearDownAll(() async {
    await db.close();
  });

  test('schema and seeds are created', () async {
    final database = await db.database;
    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = tables.map((row) => row['name'] as String).toSet();
    for (final table in <String>[
      'settings',
      'accounts',
      'categories',
      'transactions',
      'tags',
      'transaction_tags',
      'budgets',
      'budget_categories',
      'goals',
      'goal_contributions',
      'bills',
      'recurring_rules',
      'attachments',
      'split_groups',
      'split_members',
      'split_expenses',
      'split_shares',
      'settlements',
      'achievements',
      'user_profile',
    ]) {
      expect(names, contains(table), reason: 'missing table $table');
    }

    final seededCategories = await categories.all();
    expect(seededCategories.length, greaterThanOrEqualTo(20));
    expect(seededCategories.where((c) => c.type == kTypeIncome), isNotEmpty);

    final seededAchievements = await achievements.all();
    expect(seededAchievements.length, greaterThanOrEqualTo(10));

    final seededAccounts = await accounts.all();
    expect(seededAccounts, isNotEmpty);
  });

  test('transactions update balances and reports exclude transfers', () async {
    final accountList = await accounts.all();
    final cash = accountList.first;
    final expenseCategory = (await categories.all())
        .firstWhere((category) => category.type == kTypeExpense);

    await transactions.create(
      Txn(
        amount: 45000,
        type: kTypeExpense,
        accountId: cash.id!,
        categoryId: expenseCategory.id,
        date: DateTime.now().millisecondsSinceEpoch,
        paymentMethod: 'UPI',
        note: 'Coffee',
      ),
    );

    final reloaded = (await accounts.all()).firstWhere((a) => a.id == cash.id);
    expect(reloaded.balance, cash.balance - 45000);

    final summary = await stats.summary(
      DateTime.now().subtract(const Duration(days: 1)),
      DateTime.now().add(const Duration(days: 1)),
    );
    expect(summary.expense, 45000);
    expect(summary.income, 0);
    expect(summary.count, 1);
  });

  test('budget progress honours its window', () async {
    final accountList = await accounts.all();
    final categoryList = await categories.all();
    final (start, end) = BudgetRepository.periodRange(kPeriodMonthly, DateTime.now());
    final id = await budgets.create(
      Budget(
        name: 'Food',
        amount: 500000,
        period: kPeriodMonthly,
        startDate: start.millisecondsSinceEpoch,
        endDate: end.millisecondsSinceEpoch,
        categoryIds: <int>[categoryList.first.id!],
      ),
    );

    await transactions.create(
      Txn(
        amount: 120000,
        type: kTypeExpense,
        accountId: accountList.first.id!,
        categoryId: categoryList.first.id,
        date: DateTime.now().millisecondsSinceEpoch,
        paymentMethod: 'UPI',
      ),
    );

    final progress = await budgets.allWithProgress();
    final budget = progress.firstWhere((item) => item.budget.id == id);
    expect(budget.spent, 120000);
    expect(budget.ratio, closeTo(0.24, 0.001));
    expect(budget.remaining, 380000);
  });

  test('goal contributions create a savings transaction', () async {
    final accountList = await accounts.all();
    final goalId = await goals.create(
      Goal(
        name: 'Emergency fund',
        targetAmount: 1000000,
        accountId: accountList.first.id,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await goals.addContribution(
      goal: (await goals.byId(goalId))!,
      amount: 250000,
      date: DateTime.now(),
      accountId: accountList.first.id,
      note: 'First top-up',
      createTransaction: true,
      savingsCategory: 'Savings',
    );

    final goal = await goals.byId(goalId);
    expect(goal, isNotNull);
    expect(goal!.savedAmount, 250000);
    expect(goal.progress, closeTo(0.25, 0.001));

    final contributions = await goals.contributions(goalId);
    expect(contributions.length, 1);
  });

  test('bills can be marked paid and create an expense', () async {
    final accountList = await accounts.all();
    final billId = await bills.create(
      Bill(
        name: 'Electricity',
        amount: 89900,
        dueDate: DateTime.now().millisecondsSinceEpoch,
        frequency: 'monthly',
        accountId: accountList.first.id,
      ),
    );

    final bill = (await bills.byId(billId))!;
    await bills.markPaid(bill, paidOn: DateTime.now());

    final rolled = await bills.byId(billId);
    expect(rolled!.lastPaidAt, isNotNull);
    // Monthly bills roll forward to the next occurrence instead of closing.
    expect(rolled.status, kBillUpcoming);
    expect(rolled.dueDate, greaterThan(bill.dueDate));
    expect(await transactions.count(), 1);

    final oneTimeId = await bills.create(
      Bill(
        name: 'Annual insurance',
        amount: 450000,
        dueDate: DateTime.now().millisecondsSinceEpoch,
        frequency: 'one_time',
        accountId: accountList.first.id,
      ),
    );
    await bills.markPaid((await bills.byId(oneTimeId))!, paidOn: DateTime.now());
    final closed = await bills.byId(oneTimeId);
    expect(closed!.status, kBillPaid);
    expect(await transactions.count(), 2);
  });

  test('split groups compute balances and settlements', () async {
    final groupId = await splits.createGroup('Goa trip', <String>['You', 'Rahul']);
    final members = await splits.members(groupId);
    final you = members.firstWhere((member) => member.name == 'You');
    final rahul = members.firstWhere((member) => member.name == 'Rahul');

    await splits.addExpense(
      groupId: groupId,
      amount: 300000,
      paidByMemberId: you.id!,
      date: DateTime.now(),
      description: 'Hotel',
      splitMethod: 'equal',
      shareValues: <int, int>{you.id!: 150000, rahul.id!: 150000},
    );

    final summary = await splits.summary(groupId);
    expect(summary, isNotNull);
    expect(summary!.totalSpent, 300000);
    final youBalance = summary.balances.firstWhere((b) => b.member.id == you.id);
    expect(youBalance.net, 150000);
    expect(summary.suggestions, isNotEmpty);
    expect(summary.suggestions.first.from.id, rahul.id);
    expect(summary.suggestions.first.amount, 150000);
  });

  test('recurring rules materialise due transactions', () async {
    final accountList = await accounts.all();
    final categoryList = await categories.all();
    final ruleId = await transactions.saveRecurringRule(
      RecurringRule(
        amount: 19900,
        type: kTypeExpense,
        accountId: accountList.first.id!,
        categoryId: categoryList.first.id,
        frequency: 'monthly',
        interval: 1,
        nextDate: DateTime.now()
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
        note: 'Netflix',
        active: true,
      ),
    );

    await transactions.materialiseRecurring();
    final after = await transactions.count();
    expect(after, 1);

    await transactions.toggleRecurringRule(ruleId, false);
    final rules = await transactions.recurringRules();
    expect(rules.first.active, isFalse);
  });

  test('search, filters and duplicate detection work', () async {
    final accountList = await accounts.all();
    final categoryList = await categories.all();
    final now = DateTime.now().millisecondsSinceEpoch;

    final first = Txn(
      amount: 25000,
      type: kTypeExpense,
      accountId: accountList.first.id!,
      categoryId: categoryList.first.id,
      date: now,
      paymentMethod: 'Cash',
      note: 'Auto rickshaw',
    );
    await transactions.create(first);

    final duplicate = await transactions.findDuplicate(first);
    expect(duplicate, isNotNull);

    final found = await transactions.query(
      const TransactionFilter(query: 'rickshaw'),
    );
    expect(found.length, 1);

    final byAmount = await transactions.query(
      const TransactionFilter(minAmount: 20000, maxAmount: 30000),
    );
    expect(byAmount.length, 1);
  });
}
