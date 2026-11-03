import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_categories.dart';
import '../core/utils/format.dart';
import '../data/db/database_helper.dart';
import '../data/models/account_model.dart';
import '../data/models/budget_model.dart';
import '../data/models/subscription_model.dart';
import '../data/models/transaction_model.dart';

/// Central app state: accounts, transactions, budgets, subscriptions,
/// plus all derived analytics (heatmap, streaks, Bia insights).
class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Account> accounts = [];
  List<Transaction> transactions = [];
  List<Budget> budgets = [];
  List<Subscription> subscriptions = [];
  bool loaded = false;
  bool hideBalance = false;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  // ------------------------------------------------------------------
  // Loading & seeding
  // ------------------------------------------------------------------

  Future<void> loadData() async {
    await _seedIfEmpty();
    accounts = (await _db.queryAll('accounts', orderBy: 'id ASC'))
        .map((m) => Account.fromMap(m))
        .toList();
    transactions = (await _db.queryAll('transactions', orderBy: 'date DESC'))
        .map((m) => Transaction.fromMap(m))
        .toList();
    budgets = (await _db.queryAll('budgets', orderBy: 'id ASC'))
        .map((m) => Budget.fromMap(m))
        .toList();
    subscriptions = (await _db.queryAll('subscriptions', orderBy: 'next_due ASC'))
        .map((m) => Subscription.fromMap(m))
        .toList();
    loaded = true;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Mutations
  // ------------------------------------------------------------------

  Future<void> addTransaction(Transaction t) async {
    final id = await _db.insert('transactions', t.toMap());
    t.id = id;
    final i = accounts.indexWhere((a) => a.id == t.accountId);
    if (i >= 0) {
      final a = accounts[i];
      if (t.type == TxnType.income) {
        a.balance += t.amount;
      } else {
        a.balance -= t.amount; // expense & transfer both leave the account
      }
      await _db.update('accounts', {'balance': a.balance}, 'id = ?', [a.id]);
    }
    transactions = [t, ...transactions];
    notifyListeners();
  }

  Future<void> markSubscriptionPaid(Subscription s) async {
    await _db.update('subscriptions', {'is_paid': 1}, 'id = ?', [s.id]);
    s.isPaid = true;
    final accId = accounts.isNotEmpty ? (accounts.first.id ?? 1) : 1;
    await addTransaction(Transaction(
      amount: s.total > 0 ? s.total : s.amount,
      type: TxnType.expense,
      category: 'bills',
      note: '${s.name} — paid',
      accountId: accId,
      tags: const ['Bills'],
      date: DateTime.now(),
    ));
  }

  void toggleHideBalance() {
    hideBalance = !hideBalance;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Derived values — dashboard
  // ------------------------------------------------------------------

  double get totalBalance => accounts.fold(0.0, (s, a) => s + a.balance);

  List<Transaction> get todayTransactions {
    final today = _day(DateTime.now());
    return transactions.where((t) => _day(t.date) == today).toList();
  }

  // ------------------------------------------------------------------
  // Derived values — analytics / habit tracking
  // ------------------------------------------------------------------

  /// Number of logged transactions per calendar day.
  Map<DateTime, int> get activityByDay {
    final map = <DateTime, int>{};
    for (final t in transactions) {
      if (t.type == TxnType.transfer) continue;
      final d = _day(t.date);
      map[d] = (map[d] ?? 0) + 1;
    }
    return map;
  }

  int get loggedDaysLast31 {
    final today = _day(DateTime.now());
    final map = activityByDay;
    var c = 0;
    for (var i = 0; i < 31; i++) {
      if ((map[today.subtract(Duration(days: i))] ?? 0) > 0) c++;
    }
    return c;
  }

  double get consistencyPercent => loggedDaysLast31 / 31 * 100;

  int get currentStreak {
    final map = activityByDay;
    final today = _day(DateTime.now());
    var d = (map[today] ?? 0) > 0 ? today : today.subtract(const Duration(days: 1));
    if ((map[d] ?? 0) == 0) return 0;
    var streak = 0;
    while ((map[d] ?? 0) > 0) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    final map = activityByDay;
    if (map.isEmpty) return 0;
    final days = map.keys.toList()..sort();
    var best = 0, cur = 0;
    DateTime? prev;
    for (final d in days) {
      if (prev != null && d.difference(prev).inDays == 1) {
        cur++;
      } else {
        cur = 1;
      }
      if (cur > best) best = cur;
      prev = d;
    }
    return best;
  }

  String get longestStreakRange {
    final map = activityByDay;
    if (map.isEmpty) return '';
    final days = map.keys.toList()..sort();
    var best = 0, cur = 0;
    DateTime? prev, bestEnd;
    for (final d in days) {
      if (prev != null && d.difference(prev).inDays == 1) {
        cur++;
      } else {
        cur = 1;
      }
      if (cur > best) {
        best = cur;
        bestEnd = d;
      }
      prev = d;
    }
    if (bestEnd == null) return '';
    final start = bestEnd.subtract(Duration(days: best - 1));
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, y').format(bestEnd)}';
  }

  /// Spending per day for the last 7 days (index 6 = today).
  List<double> get last7DaysSpending {
    final today = _day(DateTime.now());
    final map = <DateTime, double>{};
    for (final t in transactions) {
      if (t.type != TxnType.expense) continue;
      final d = _day(t.date);
      map[d] = (map[d] ?? 0) + t.amount;
    }
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return map[d] ?? 0;
    });
  }

  static DateTime _mondayOf(DateTime d) {
    final day = _day(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  double _weekSpend(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7));
    var s = 0.0;
    for (final t in transactions) {
      if (t.type != TxnType.expense) continue;
      final d = _day(t.date);
      if (!d.isBefore(weekStart) && d.isBefore(end)) s += t.amount;
    }
    return s;
  }

  double get thisWeekSpend => _weekSpend(_mondayOf(DateTime.now()));

  double get lastWeekSpend => _weekSpend(_mondayOf(DateTime.now()).subtract(const Duration(days: 7)));

  double get weeklyChangePercent {
    final lw = lastWeekSpend;
    if (lw <= 0) return 0;
    return (thisWeekSpend - lw) / lw * 100;
  }

  /// Expense totals per category in the current calendar month.
  Map<String, double> get categoryTotalsThisMonth {
    final now = DateTime.now();
    final map = <String, double>{};
    for (final t in transactions) {
      if (t.type != TxnType.expense) continue;
      if (t.date.year == now.year && t.date.month == now.month) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  double budgetSpent(String categoryKey) => categoryTotalsThisMonth[categoryKey] ?? 0;

  MapEntry<String, double> get topCategoryThisWeek {
    final monday = _mondayOf(DateTime.now());
    final end = monday.add(const Duration(days: 7));
    final map = <String, double>{};
    for (final t in transactions) {
      if (t.type != TxnType.expense) continue;
      final d = _day(t.date);
      if (!d.isBefore(monday) && d.isBefore(end)) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    if (map.isEmpty) return const MapEntry('other', 0);
    var best = map.entries.first;
    for (final e in map.entries) {
      if (e.value > best.value) best = e;
    }
    return best;
  }

  /// Locally-computed "AI" insight generated purely from on-device data.
  String get biaInsight {
    final pct = consistencyPercent.toStringAsFixed(0);
    final logged = loggedDaysLast31;
    final change = weeklyChangePercent;
    final dir = change <= 0 ? 'down' : 'up';
    final top = Categories.byKey(topCategoryThisWeek.key).label;
    final gap = longestStreak - currentStreak;
    final streakLine = gap > 0
        ? '$gap day${gap == 1 ? '' : 's'} to beat your best streak of $longestStreak.'
        : 'You are at your best streak — keep it alive.';
    return 'You logged on $logged of the last 31 days ($pct% consistency). '
        'This week you spent ${formatMoneyShort(thisWeekSpend)} — '
        '${change.abs().toStringAsFixed(0)}% $dir vs last week, led by $top. '
        'On weeks you log consistently, discretionary spending trends down. $streakLine';
  }

  // ------------------------------------------------------------------
  // Demo seed (only on first launch — everything stays 100% offline)
  // ------------------------------------------------------------------

  Future<void> _seedIfEmpty() async {
    if (await _db.count('accounts') > 0) return;

    for (final a in [
      Account(
        name: 'HDFC Bank',
        type: AccountType.bank,
        balance: 84250.00,
        maskedNumber: 'Account **4821',
        color1: const Color(0xFF1E3A8A),
        color2: const Color(0xFF3B82F6),
      ),
      Account(
        name: 'ICICI Credit Card',
        type: AccountType.card,
        balance: -12480.50,
        maskedNumber: '**** 3264',
        color1: const Color(0xFF0F172A),
        color2: const Color(0xFF475569),
      ),
      Account(
        name: 'Cash Wallet',
        type: AccountType.cash,
        balance: 3200.00,
        maskedNumber: 'Physical cash',
        color1: const Color(0xFF065F46),
        color2: const Color(0xFF34D399),
      ),
    ]) {
      await _db.insert('accounts', a.toMap());
    }

    for (final b in [
      Budget(categoryKey: 'food', limit: 9000),
      Budget(categoryKey: 'transport', limit: 3500),
      Budget(categoryKey: 'shopping', limit: 6000),
      Budget(categoryKey: 'entertainment', limit: 2500),
      Budget(categoryKey: 'bills', limit: 7000),
    ]) {
      await _db.insert('budgets', b.toMap());
    }

    final now = DateTime.now();

    DateTime nextMonthly(int day) {
      var d = DateTime(now.year, now.month, day);
      if (!d.isAfter(now)) d = DateTime(now.year, now.month + 1, day);
      return d;
    }

    for (final s in [
      Subscription(
        name: 'Netflix',
        fromName: 'Netflix Inc.',
        toName: 'Rajdeep',
        amount: 649,
        cycle: 'Monthly',
        nextDue: nextMonthly(5),
        issued: now.subtract(const Duration(days: 25)),
        isPaid: true,
        color: const Color(0xFFE50914),
        icon: Icons.movie_filter_rounded,
        items: const [InvoiceItem('Premium 4K plan', 1, 649)],
      ),
      Subscription(
        name: 'Spotify',
        fromName: 'Spotify AB',
        toName: 'Rajdeep',
        amount: 119,
        cycle: 'Monthly',
        nextDue: nextMonthly(12),
        issued: now.subtract(const Duration(days: 18)),
        isPaid: true,
        color: const Color(0xFF1DB954),
        icon: Icons.music_note_rounded,
        items: const [InvoiceItem('Premium Individual', 1, 119)],
      ),
      Subscription(
        name: 'House Rent',
        fromName: 'Landlord — Mr. Verma',
        toName: 'Rajdeep',
        amount: 18000,
        cycle: 'Monthly',
        nextDue: nextMonthly(1),
        issued: now.subtract(const Duration(days: 3)),
        isPaid: false,
        color: const Color(0xFF8A5CF6),
        icon: Icons.home_rounded,
        items: const [InvoiceItem('Rent — monthly', 1, 18000)],
      ),
      Subscription(
        name: 'Studio Sphere BV',
        fromName: 'Studio Sphere BV',
        toName: 'Dip Inc.',
        amount: 13310,
        cycle: 'Invoice IN-001',
        nextDue: now.add(const Duration(days: 14)),
        issued: now.subtract(const Duration(days: 16)),
        isPaid: false,
        color: const Color(0xFFFF7A1A),
        icon: Icons.receipt_long_rounded,
        items: const [
          InvoiceItem('Discovery', 12, 180),
          InvoiceItem('Identity', 36, 190),
          InvoiceItem('Guidelines', 10, 180),
        ],
      ),
    ]) {
      await _db.insert('subscriptions', s.toMap());
    }

    // Deterministic demo activity over the last 45 days so the heatmap,
    // streaks and charts have real data to work with.
    final rnd = Random(42);
    final today = _day(now);
    const cats = ['food', 'transport', 'shopping', 'groceries', 'bills', 'entertainment', 'health'];
    final notes = <String, List<String>>{
      'food': ['Lunch at café', 'Dinner out', 'Coffee & snacks', 'Street food'],
      'transport': ['Uber ride', 'Metro recharge', 'Fuel'],
      'shopping': ['Amazon order', 'New clothes', 'Gadget'],
      'groceries': ['BigBasket', 'Local kirana', 'Fruits & veg'],
      'bills': ['Electricity', 'Wi-Fi recharge', 'Mobile recharge'],
      'entertainment': ['Movie tickets', 'Game', 'Concert'],
      'health': ['Pharmacy', 'Gym', 'Doctor visit'],
    };
    const tagPool = ['Work', 'Personal', 'Fun', 'Urgent'];
    const people = ['Aarav', 'Priya', 'Rahul', 'Sara'];

    for (var d = 44; d >= 0; d--) {
      final day = today.subtract(Duration(days: d));
      var count = rnd.nextInt(6) == 0 ? 0 : 1 + rnd.nextInt(3);
      if (d == 0) count = 2;
      if (d == 3 || d == 11) count = 0;
      for (var i = 0; i < count; i++) {
        final cat = cats[rnd.nextInt(cats.length)];
        final note = notes[cat]![rnd.nextInt(notes[cat]!.length)];
        final tags = rnd.nextInt(3) == 0 ? [tagPool[rnd.nextInt(tagPool.length)]] : <String>[];
        final split = rnd.nextInt(8) == 0
            ? [people[rnd.nextInt(people.length)], people[rnd.nextInt(people.length)]]
            : <String>[];
        await _db.insert('transactions', Transaction(
          amount: _amountFor(cat, rnd),
          type: TxnType.expense,
          category: cat,
          note: note,
          accountId: 1 + rnd.nextInt(3),
          tags: tags,
          splitWith: split,
          date: day.add(Duration(hours: 8 + rnd.nextInt(12), minutes: rnd.nextInt(60))),
        ).toMap());
      }
    }

    await _db.insert('transactions', Transaction(
      amount: 85000,
      type: TxnType.income,
      category: 'salary',
      note: 'Salary — monthly',
      accountId: 1,
      tags: const ['Work'],
      date: today.subtract(const Duration(days: 30)).add(const Duration(hours: 9)),
    ).toMap());
  }

  double _amountFor(String cat, Random rnd) {
    switch (cat) {
      case 'food':
        return 120 + rnd.nextDouble() * 780;
      case 'transport':
        return 40 + rnd.nextDouble() * 360;
      case 'shopping':
        return 499 + rnd.nextDouble() * 3500;
      case 'groceries':
        return 250 + rnd.nextDouble() * 1250;
      case 'bills':
        return 199 + rnd.nextDouble() * 2300;
      case 'entertainment':
        return 150 + rnd.nextDouble() * 1050;
      case 'health':
        return 200 + rnd.nextDouble() * 4800;
      default:
        return 100 + rnd.nextDouble() * 900;
    }
  }
}
