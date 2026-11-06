import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/money.dart';
import '../core/utils/smart_engine.dart';
import '../data/db/app_database.dart';
import '../data/models/app_settings.dart';
import '../data/models/models.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/achievement_repository.dart';
import '../data/repositories/bill_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/export_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/import_repository.dart';
import '../data/repositories/label_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/split_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../data/repositories/transaction_repository.dart';

// ---------------------------------------------------------------- core wiring

final Provider<AppDatabase> databaseProvider =
    Provider<AppDatabase>((ref) => AppDatabase.instance);

/// Rebuild signal: every write bumps this notifier.
final ChangeNotifierProvider<ValueNotifier<int>> revisionProvider =
    ChangeNotifierProvider<ValueNotifier<int>>(
  (ref) => ref.watch(databaseProvider).revision,
);

final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final Provider<AccountRepository> accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(databaseProvider)),
);

final Provider<CategoryRepository> categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);

final Provider<TransactionRepository> transactionRepositoryProvider =
    Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(databaseProvider)),
);

final Provider<BudgetRepository> budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(ref.watch(databaseProvider)),
);

final Provider<LabelRepository> labelRepositoryProvider =
    Provider<LabelRepository>(
  (ref) => LabelRepository(ref.watch(databaseProvider)),
);

final FutureProvider<List<LabelInfo>> labelsProvider =
    FutureProvider<List<LabelInfo>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(labelRepositoryProvider).all();
  },
  name: 'labels',
);

final FutureProviderFamily<List<Txn>, String> labelTransactionsProvider =
    FutureProvider.family<List<Txn>, String>((ref, tag) {
  ref.watch(revisionProvider);
  return ref.watch(transactionRepositoryProvider).query(
        TransactionFilter(tags: <String>[tag], sort: 'newest'),
      );
}, name: 'labelTransactions');

final FutureProvider<List<LabelInfo>> labelsThisMonthProvider =
    FutureProvider<List<LabelInfo>>(
  (ref) {
    ref.watch(revisionProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return ref.watch(labelRepositoryProvider).all(start: start, end: end);
  },
  name: 'labelsThisMonth',
);

final Provider<GoalRepository> goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

final Provider<BillRepository> billRepositoryProvider = Provider<BillRepository>(
  (ref) => BillRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

final Provider<SplitRepository> splitRepositoryProvider = Provider<SplitRepository>(
  (ref) => SplitRepository(ref.watch(databaseProvider)),
);

final Provider<AchievementRepository> achievementRepositoryProvider =
    Provider<AchievementRepository>(
  (ref) => AchievementRepository(ref.watch(databaseProvider)),
);

final Provider<StatsRepository> statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => StatsRepository(ref.watch(databaseProvider)),
);

final Provider<ExportRepository> exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => ExportRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(statsRepositoryProvider),
  ),
);

final Provider<ImportRepository> importRepositoryProvider = Provider<ImportRepository>(
  (ref) => ImportRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);

// ------------------------------------------------------------------- settings

final FutureProvider<AppSettings> settingsProvider = FutureProvider<AppSettings>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(settingsRepositoryProvider).load();
  },
  name: 'settings',
);

/// Synchronous snapshot with sensible defaults – used by widgets that cannot
/// await (it is filled as soon as the settings load).
final Provider<AppSettings> settingsSnapshotProvider = Provider<AppSettings>((ref) {
  return ref.watch(settingsProvider).valueOrNull ?? AppSettings.empty;
});

final Provider<bool> isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(settingsSnapshotProvider).isPremium,
);

final Provider<String> userNameProvider = Provider<String>(
  (ref) => ref.watch(settingsSnapshotProvider).userName,
);

/// Applies formatting preferences to the global [Fmt] helper.
void applyFormatting(AppSettings settings) {
  Fmt.configure(
    symbolValue: settings.currencySymbol,
    code: settings.currencyCode,
    decimalDigits: settings.decimalDigits,
    symbolPositionBefore: settings.symbolBefore,
    style: settings.amountStyle,
    dateFormatPattern: settings.dateFormat,
    firstDay: settings.firstDayOfWeek,
    lang: settings.language,
  );
}

// -------------------------------------------------------------------- accounts

final FutureProvider<List<Account>> accountsProvider = FutureProvider<List<Account>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(accountRepositoryProvider).all();
  },
  name: 'accounts',
);

final FutureProvider<List<Account>> allAccountsProvider = FutureProvider<List<Account>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(accountRepositoryProvider).all(includeArchived: true);
  },
  name: 'allAccounts',
);

final FutureProvider<Map<int, Account>> accountLookupProvider =
    FutureProvider<Map<int, Account>>((ref) async {
  final accounts = await ref.watch(allAccountsProvider.future);
  return <int, Account>{for (final account in accounts) account.id!: account};
}, name: 'accountLookup');

final FutureProvider<Map<String, int>> netWorthProvider =
    FutureProvider<Map<String, int>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(accountRepositoryProvider).totals();
}, name: 'netWorth');

// ------------------------------------------------------------------ categories

final FutureProvider<List<Category>> categoriesProvider = FutureProvider<List<Category>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(categoryRepositoryProvider).all();
  },
  name: 'categories',
);

final FutureProvider<List<Category>> allCategoriesProvider =
    FutureProvider<List<Category>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(categoryRepositoryProvider).all(includeArchived: true);
}, name: 'allCategories');

final FutureProvider<Map<int, Category>> categoryLookupProvider =
    FutureProvider<Map<int, Category>>((ref) async {
  final categories = await ref.watch(allCategoriesProvider.future);
  return <int, Category>{for (final category in categories) category.id!: category};
}, name: 'categoryLookup');

// ---------------------------------------------------------------- transactions

final StateProvider<TransactionFilter> transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());

final FutureProvider<List<Txn>> filteredTransactionsProvider = FutureProvider<List<Txn>>(
  (ref) {
    ref.watch(revisionProvider);
    final filter = ref.watch(transactionFilterProvider);
    return ref.watch(transactionRepositoryProvider).query(filter);
  },
  name: 'filteredTransactions',
);

final FutureProvider<List<Txn>> recentTransactionsProvider = FutureProvider<List<Txn>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(transactionRepositoryProvider).recent(limit: 8);
  },
  name: 'recentTransactions',
);

final ruleTransactionsProvider =
    FutureProvider.family<List<Txn>, int>((ref, ruleId) {
  ref.watch(revisionProvider);
  return ref.watch(transactionRepositoryProvider).byRecurringRule(ruleId);
}, name: 'ruleTransactions');

final accountTransactionsProvider =
    FutureProvider.family<List<Txn>, int>((ref, accountId) {
  ref.watch(revisionProvider);
  return ref.watch(transactionRepositoryProvider).query(
        TransactionFilter(accountIds: <int>[accountId], sort: 'newest'),
      );
}, name: 'accountTransactions');

final FutureProvider<List<String>> allTagsProvider = FutureProvider<List<String>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(transactionRepositoryProvider).allTags();
  },
  name: 'allTags',
);

final FutureProvider<Map<String, String>> noteHistoryProvider =
    FutureProvider<Map<String, String>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(transactionRepositoryProvider).noteCategoryHistory();
}, name: 'noteHistory');

final StateProvider<String> searchQueryProvider = StateProvider<String>((ref) => '');

final FutureProvider<List<Txn>> searchResultsProvider = FutureProvider<List<Txn>>(
  (ref) {
    final query = ref.watch(searchQueryProvider);
    if (query.trim().isEmpty) return Future<List<Txn>>.value(const <Txn>[]);
    ref.watch(revisionProvider);
    return ref
        .watch(transactionRepositoryProvider)
        .query(TransactionFilter(query: query.trim()));
  },
  name: 'searchResults',
);

final FutureProvider<List<RecurringRule>> recurringRulesProvider =
    FutureProvider<List<RecurringRule>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(transactionRepositoryProvider).recurringRules();
}, name: 'recurringRules');

// --------------------------------------------------------------------- periods

/// First day of the accounting month from settings.
final Provider<DateTime> monthStartProvider = Provider<DateTime>((ref) {
  final settings = ref.watch(settingsSnapshotProvider);
  final now = DateTime.now();
  final startDay = settings.startOfMonth.clamp(1, 28).toInt();
  if (now.day >= startDay) return DateTime(now.year, now.month, startDay);
  return DateTime(now.year, now.month - 1, startDay);
});

final Provider<DateTime> monthEndProvider = Provider<DateTime>((ref) {
  final start = ref.watch(monthStartProvider);
  return DateTime(start.year, start.month + 1, start.day)
      .subtract(const Duration(seconds: 1));
});

final FutureProvider<PeriodSummary> monthSummaryProvider =
    FutureProvider<PeriodSummary>((ref) {
  ref.watch(revisionProvider);
  final start = ref.watch(monthStartProvider);
  final end = ref.watch(monthEndProvider);
  return ref.watch(statsRepositoryProvider).summary(start, end);
}, name: 'monthSummary');

final FutureProvider<PeriodSummary> lastMonthSummaryProvider =
    FutureProvider<PeriodSummary>((ref) {
  ref.watch(revisionProvider);
  final start = ref.watch(monthStartProvider);
  final prevStart = DateTime(start.year, start.month - 1, start.day);
  final prevEnd = start.subtract(const Duration(seconds: 1));
  return ref.watch(statsRepositoryProvider).summary(prevStart, prevEnd);
}, name: 'lastMonthSummary');

final FutureProvider<List<CategoryTotal>> monthCategoryTotalsProvider =
    FutureProvider<List<CategoryTotal>>((ref) {
  ref.watch(revisionProvider);
  final start = ref.watch(monthStartProvider);
  final end = ref.watch(monthEndProvider);
  return ref.watch(statsRepositoryProvider).categoryTotals(start, end);
}, name: 'monthCategoryTotals');

final FutureProvider<List<DayTotal>> monthDailyTotalsProvider =
    FutureProvider<List<DayTotal>>((ref) {
  ref.watch(revisionProvider);
  final start = ref.watch(monthStartProvider);
  final end = ref.watch(monthEndProvider);
  return ref.watch(statsRepositoryProvider).dailyTotals(start, end);
}, name: 'monthDailyTotals');

final FutureProvider<List<MonthTotal>> monthlyTotalsProvider =
    FutureProvider<List<MonthTotal>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(statsRepositoryProvider).monthlyTotals(months: 6);
}, name: 'monthlyTotals');

final FutureProvider<List<Insight>> insightsProvider = FutureProvider<List<Insight>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(statsRepositoryProvider).insights();
  },
  name: 'insights',
);

/// Safe to spend = monthly budget - spent - upcoming bills - planned savings.
class SafeToSpend {
  const SafeToSpend({
    required this.budget,
    required this.spent,
    required this.upcomingBills,
    required this.plannedSavings,
  });

  final int budget;
  final int spent;
  final int upcomingBills;
  final int plannedSavings;

  int get remaining => budget - spent - upcomingBills - plannedSavings;

  double get ratio => budget <= 0 ? 0 : (spent / budget).clamp(0.0, 1.5).toDouble();

  int get perDay {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = (lastDay - now.day) + 1;
    if (daysLeft <= 0) return remaining;
    return (remaining / daysLeft).round();
  }
}

final FutureProvider<SafeToSpend> safeToSpendProvider = FutureProvider<SafeToSpend>(
  (ref) async {
    ref.watch(revisionProvider);
    final db = ref.watch(databaseProvider);
    final start = ref.watch(monthStartProvider);
    final end = ref.watch(monthEndProvider);

    final budgets = await ref.watch(budgetRepositoryProvider).allWithProgress();
    final overall = budgets.where((b) => b.budget.type == 'overall').toList();
    final monthlyBudget = overall.isNotEmpty
        ? overall.first.budget.amount
        : budgets.fold<int>(0, (sum, b) => sum + b.budget.amount);
    final spent = overall.isNotEmpty
        ? overall.first.spent
        : budgets.fold<int>(0, (sum, b) => sum + b.spent);

    final connection = await db.database;
    final billRows = await connection.rawQuery('''
      SELECT COALESCE(SUM(amount),0) AS total FROM bills
      WHERE status != 'paid' AND due_date >= ? AND due_date <= ?
    ''', <Object?>[start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    final bills = (billRows.first['total'] as num?)?.toInt() ?? 0;

    final goalRows = await connection.rawQuery(
      "SELECT COALESCE(SUM(recurring_amount),0) AS total FROM goals WHERE status = 'active'",
    );
    final savings = (goalRows.first['total'] as num?)?.toInt() ?? 0;

    return SafeToSpend(
      budget: monthlyBudget,
      spent: spent,
      upcomingBills: bills,
      plannedSavings: savings,
    );
  },
  name: 'safeToSpend',
);

// --------------------------------------------------------------------- budgets

final FutureProvider<List<BudgetProgress>> budgetsProvider =
    FutureProvider<List<BudgetProgress>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(budgetRepositoryProvider).allWithProgress();
}, name: 'budgets');

final FutureProviderFamily<List<DayTotal>, int> budgetDailySpendProvider =
    FutureProvider.family<List<DayTotal>, int>((ref, budgetId) async {
  ref.watch(revisionProvider);
  final budget = await ref.watch(budgetRepositoryProvider).byId(budgetId);
  if (budget == null) return const <DayTotal>[];
  return ref.watch(budgetRepositoryProvider).dailySpend(budget);
});

final FutureProviderFamily<List<CategoryTotal>, int> budgetCategoryTotalsProvider =
    FutureProvider.family<List<CategoryTotal>, int>((ref, budgetId) async {
  ref.watch(revisionProvider);
  final budget = await ref.watch(budgetRepositoryProvider).byId(budgetId);
  if (budget == null) return const <CategoryTotal>[];
  return ref.watch(budgetRepositoryProvider).categoryBreakdown(budget);
});

// ----------------------------------------------------------------------- goals

final FutureProvider<List<Goal>> goalsProvider = FutureProvider<List<Goal>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(goalRepositoryProvider).all();
  },
  name: 'goals',
);

final FutureProviderFamily<List<GoalContribution>, int> goalContributionsProvider =
    FutureProvider.family<List<GoalContribution>, int>((ref, goalId) {
  ref.watch(revisionProvider);
  return ref.watch(goalRepositoryProvider).contributions(goalId);
});

final FutureProvider<int> totalSavedProvider = FutureProvider<int>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(goalRepositoryProvider).totalSaved();
}, name: 'totalSaved');

// ----------------------------------------------------------------------- bills

final FutureProvider<List<Bill>> billsProvider = FutureProvider<List<Bill>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(billRepositoryProvider).all();
  },
  name: 'bills',
);

final FutureProvider<List<Bill>> upcomingBillsProvider = FutureProvider<List<Bill>>(
  (ref) {
    ref.watch(revisionProvider);
    return ref.watch(billRepositoryProvider).upcoming(limit: 3);
  },
  name: 'upcomingBills',
);

// ---------------------------------------------------------------------- splits

final FutureProvider<List<SplitGroup>> splitGroupsProvider =
    FutureProvider<List<SplitGroup>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(splitRepositoryProvider).groups();
}, name: 'splitGroups');

final FutureProviderFamily<SplitGroupSummary?, int> splitSummaryProvider =
    FutureProvider.family<SplitGroupSummary?, int>((ref, groupId) {
  ref.watch(revisionProvider);
  return ref.watch(splitRepositoryProvider).summary(groupId);
});

// ---------------------------------------------------------------- achievements

final FutureProvider<List<Achievement>> achievementsProvider =
    FutureProvider<List<Achievement>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(achievementRepositoryProvider).all();
}, name: 'achievements');

// ------------------------------------------------------------------ navigation

final StateProvider<int> navIndexProvider = StateProvider<int>((ref) => 0);

final StateProvider<bool> amountsHiddenProvider = StateProvider<bool>((ref) => false);

// ------------------------------------------------------------- detail lookups

final FutureProviderFamily<Txn?, int> txnByIdProvider =
    FutureProvider.family<Txn?, int>((ref, id) {
  ref.watch(revisionProvider);
  return ref.watch(transactionRepositoryProvider).byId(id);
});

final FutureProviderFamily<Account?, int> accountByIdProvider =
    FutureProvider.family<Account?, int>((ref, id) {
  ref.watch(revisionProvider);
  return ref.watch(accountRepositoryProvider).byId(id);
});

final FutureProviderFamily<Category?, int> categoryByIdProvider =
    FutureProvider.family<Category?, int>((ref, id) {
  ref.watch(revisionProvider);
  return ref.watch(categoryRepositoryProvider).byId(id);
});

final FutureProviderFamily<Budget?, int> budgetByIdProvider =
    FutureProvider.family<Budget?, int>((ref, id) {
  ref.watch(revisionProvider);
  return ref.watch(budgetRepositoryProvider).byId(id);
});

final FutureProviderFamily<BudgetProgress?, int> budgetProgressByIdProvider =
    FutureProvider.family<BudgetProgress?, int>((ref, id) async {
  ref.watch(revisionProvider);
  final repo = ref.watch(budgetRepositoryProvider);
  final budget = await repo.byId(id);
  if (budget == null) return null;
  return repo.progressFor(budget);
});

final FutureProviderFamily<Goal?, int> goalByIdProvider =
    FutureProvider.family<Goal?, int>((ref, id) {
  ref.watch(revisionProvider);
  return ref.watch(goalRepositoryProvider).byId(id);
});

final FutureProviderFamily<Bill?, int> billByIdProvider =
    FutureProvider.family<Bill?, int>((ref, id) {
  ref.watch(revisionProvider);
  return ref.watch(billRepositoryProvider).byId(id);
});

// ------------------------------------------------------------- smart features

Category? findCategoryByName(List<Category> categories, String? name) {
  if (name == null) return null;
  for (final category in categories) {
    if (category.name.toLowerCase() == name.toLowerCase()) return category;
  }
  return null;
}

SmartResult parseQuickAdd(String text) => SmartEngine.parseQuickAdd(text);

// ------------------------------------------------------------------- reports

class StatsRange {
  const StatsRange({required this.label, required this.start, required this.end});

  final String label;
  final DateTime start;
  final DateTime end;

  StatsRange copyWith({String? label, DateTime? start, DateTime? end}) => StatsRange(
        label: label ?? this.label,
        start: start ?? this.start,
        end: end ?? this.end,
      );
}

StatsRange defaultStatsRange() {
  final now = DateTime.now();
  return StatsRange(
    label: 'This month',
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
  );
}

final StateProvider<StatsRange> statsRangeProvider =
    StateProvider<StatsRange>((ref) => defaultStatsRange());

final StateProvider<String> statsTypeProvider = StateProvider<String>((ref) => 'all');

final FutureProvider<PeriodSummary> statsSummaryProvider =
    FutureProvider<PeriodSummary>((ref) {
  ref.watch(revisionProvider);
  final range = ref.watch(statsRangeProvider);
  return ref.watch(statsRepositoryProvider).summary(range.start, range.end);
}, name: 'statsSummary');

final FutureProvider<PeriodSummary> statsPreviousSummaryProvider =
    FutureProvider<PeriodSummary>((ref) {
  ref.watch(revisionProvider);
  final range = ref.watch(statsRangeProvider);
  final span = range.end.difference(range.start);
  final prevEnd = range.start.subtract(const Duration(seconds: 1));
  final prevStart = prevEnd.subtract(span);
  return ref.watch(statsRepositoryProvider).summary(prevStart, prevEnd);
}, name: 'statsPreviousSummary');

final FutureProvider<List<CategoryTotal>> statsCategoryTotalsProvider =
    FutureProvider<List<CategoryTotal>>((ref) {
  ref.watch(revisionProvider);
  final range = ref.watch(statsRangeProvider);
  final type = ref.watch(statsTypeProvider);
  return ref.watch(statsRepositoryProvider).categoryTotals(
        range.start,
        range.end,
        type: type == 'income' ? kTypeIncome : kTypeExpense,
      );
}, name: 'statsCategoryTotals');

final FutureProvider<List<DayTotal>> statsDailyTotalsProvider =
    FutureProvider<List<DayTotal>>((ref) {
  ref.watch(revisionProvider);
  final range = ref.watch(statsRangeProvider);
  final type = ref.watch(statsTypeProvider);
  return ref.watch(statsRepositoryProvider).dailyTotals(
        range.start,
        range.end,
        type: type == 'income' ? kTypeIncome : kTypeExpense,
      );
}, name: 'statsDailyTotals');

final FutureProvider<List<Txn>> statsTopTransactionsProvider =
    FutureProvider<List<Txn>>((ref) {
  ref.watch(revisionProvider);
  final range = ref.watch(statsRangeProvider);
  return ref.watch(statsRepositoryProvider).topTransactions(range.start, range.end);
}, name: 'statsTopTransactions');

final FutureProvider<List<MapEntry<String, int>>> statsAccountSpendingProvider =
    FutureProvider<List<MapEntry<String, int>>>((ref) {
  ref.watch(revisionProvider);
  final range = ref.watch(statsRangeProvider);
  return ref.watch(statsRepositoryProvider).accountSpending(range.start, range.end);
}, name: 'statsAccountSpending');

final FutureProvider<List<DayTotal>> statsHeatmapProvider =
    FutureProvider<List<DayTotal>>((ref) {
  ref.watch(revisionProvider);
  final range = ref.watch(statsRangeProvider);
  return ref.watch(statsRepositoryProvider).heatmap(range.start);
}, name: 'statsHeatmap');

final FutureProvider<List<MonthTotal>> statsMonthlyProvider =
    FutureProvider<List<MonthTotal>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(statsRepositoryProvider).monthlyTotals(months: 6);
}, name: 'statsMonthly');

final FutureProvider<List<MonthTotal>> statsYearlyProvider =
    FutureProvider<List<MonthTotal>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(statsRepositoryProvider).yearlyComparison();
}, name: 'statsYearly');

final FutureProvider<List<CashFlowPoint>> statsCashFlowProvider =
    FutureProvider<List<CashFlowPoint>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(statsRepositoryProvider).cashFlow(months: 6);
}, name: 'statsCashFlow');

final FutureProvider<int> statsForecastProvider = FutureProvider<int>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(statsRepositoryProvider).forecastMonth();
}, name: 'statsForecast');

final FutureProvider<int> statsRecurringProvider = FutureProvider<int>((ref) {
  ref.watch(revisionProvider);
  final range = ref.watch(statsRangeProvider);
  return ref.watch(statsRepositoryProvider).recurringTotal(range.start, range.end);
}, name: 'statsRecurring');
