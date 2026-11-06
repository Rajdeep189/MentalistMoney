import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/luxe.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustration.dart';
import '../../widgets/shimmer.dart';
import '../../widgets/paisa_blocks.dart';
import '../../widgets/transaction_tile.dart';
import '../io/export_screen.dart';
import '../io/csv_import_screen.dart';
import 'add_transaction_sheet.dart';
import 'filters_screen.dart';
import 'recurring_screen.dart';
import 'search_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _groupBy = 'day';
  final Set<int> _selected = <int>{};
  bool get _selectionMode => _selected.isNotEmpty;

  List<_Group> _group(List<Txn> txns) {
    final groups = <String, _Group>{};
    for (final txn in txns) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn.date);
      String key;
      String label;
      switch (_groupBy) {
        case 'week':
          final start = date.subtract(Duration(days: date.weekday - 1));
          key = '${start.year}-${start.month}-${start.day}';
          label = 'Week of ${Fmt.date(start.millisecondsSinceEpoch)}';
          break;
        case 'month':
          key = '${date.year}-${date.month}';
          label = Fmt.monthYear(txn.date);
          break;
        default:
          key = '${date.year}-${date.month}-${date.day}';
          label = DateX.relativeDay(date);
      }
      final group = groups.putIfAbsent(key, () => _Group(label: label));
      group.items.add(txn);
      if (txn.type == kTypeIncome) {
        group.income += txn.amount;
      } else if (txn.type == kTypeExpense) {
        group.expense += txn.amount;
      }
    }
    return groups.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final filter = ref.watch(transactionFilterProvider);
    final txnsAsync = ref.watch(filteredTransactionsProvider);
    final accounts = ref.watch(accountLookupProvider).valueOrNull ?? const <int, Account>{};
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            const MetallicMark(size: 28, animated: false),
            const SizedBox(width: 10),
            Text(tr(context, 'Transactions'), style: AppTextStyles.h2(context.c.ink)),
          ],
        ),
        actions: <Widget>[
          if (_selectionMode) ...<Widget>[
            IconButton(
              tooltip: 'Change category',
              icon: const Icon(Icons.category_outlined),
              onPressed: () => _bulkChangeCategory(categories),
            ),
            IconButton(
              tooltip: 'Change account',
              icon: const Icon(Icons.account_balance_wallet_outlined),
              onPressed: () => _bulkChangeAccount(accounts.values.toList()),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _bulkDelete,
            ),
            IconButton(
              tooltip: 'Clear selection',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(_selected.clear),
            ),
          ] else ...<Widget>[
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
              ),
            ),
            IconButton(
              icon: Badge(
                isLabelVisible: filter.activeCount > 0,
                label: Text('${filter.activeCount}'),
                backgroundColor: palette.accent,
                child: const Icon(Icons.tune_rounded),
              ),
              onPressed: _openFilters,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                switch (value) {
                  case 'csv':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ExportScreen()),
                    );
                    break;
                  case 'import':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CsvImportScreen()),
                    );
                    break;
                  case 'recurring':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const RecurringScreen()),
                    );
                    break;
                  case 'group':
                    await _pickGrouping();
                    break;
                }
              },
              itemBuilder: (context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'csv', child: Text('Export CSV / PDF')),
                PopupMenuItem<String>(value: 'import', child: Text('Import CSV')),
                PopupMenuItem<String>(value: 'recurring', child: Text('Recurring transactions')),
                PopupMenuItem<String>(value: 'group', child: Text('Grouping')),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              AppSpacing.x2,
            ),
            child: Column(
              children: <Widget>[
                _FlowStrip(
                  income: ref.watch(monthSummaryProvider).valueOrNull?.income ?? 0,
                  expense: ref.watch(monthSummaryProvider).valueOrNull?.expense ?? 0,
                ),
                const SizedBox(height: AppSpacing.x3),
                AppSearchField(
                  hint: 'Search notes, categories, tags…',
                  onChanged: (value) {
                    ref.read(transactionFilterProvider.notifier).state =
                        ref.read(transactionFilterProvider).copyWith(query: value);
                  },
                  onFilter: _openFilters,
                  filterCount: filter.activeCount,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      for (final type in <String>['all', kTypeExpense, kTypeIncome, kTypeTransfer])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppChip(
                            label: type == 'all' ? 'All' : _typeLabel(type),
                            selected: type == 'all'
                                ? filter.types.isEmpty
                                : filter.types.length == 1 && filter.types.first == type,
                            onTap: () {
                              ref.read(transactionFilterProvider.notifier).state = filter.copyWith(
                                types: type == 'all' ? <String>[] : <String>[type],
                              );
                            },
                          ),
                        ),
                      if (filter.activeCount > 0)
                        AppChip(
                          label: 'Clear',
                          icon: Icons.close_rounded,
                          onTap: () {
                            ref.read(transactionFilterProvider.notifier).state =
                                const TransactionFilter();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: txnsAsync.when(
              loading: () => const ListSkeleton(),
              error: (error, _) => Center(
                child: Text('Could not load transactions: $error',
                    style: AppTextStyles.caption(palette.expense)),
              ),
              data: (txns) {
                if (txns.isEmpty) {
                  return EmptyState(
                    title: filter.isEmpty ? 'No transactions yet' : 'Nothing matches these filters',
                    message: filter.isEmpty
                        ? 'Log your first expense, income or transfer to see it here.'
                        : 'Try widening the date range or clearing filters.',
                    illustration: IllustrationKind.wallet,
                    actionLabel: filter.isEmpty ? 'Add your first transaction' : 'Clear filters',
                    onAction: filter.isEmpty
                        ? () => showAddTransactionSheet(context, ref)
                        : () {
                            ref.read(transactionFilterProvider.notifier).state =
                                const TransactionFilter();
                          },
                  );
                }

                final groups = _group(txns);

                return RefreshIndicator(
                  color: palette.accent,
                  onRefresh: () async {
                    ref.invalidate(filteredTransactionsProvider);
                    await Future<void>.delayed(const Duration(milliseconds: 300));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      0,
                      AppSpacing.screen,
                      120,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          DateGroupHeader(
                            label: group.label,
                            income: group.income,
                            expense: group.expense,
                          ),
                          ...group.items.map((txn) {
                            final tile = PaisaTxnCard(
                              txn: txn,
                              category: categories[txn.categoryId],
                              accountName: accounts[txn.accountId]?.name,
                              toAccountName: accounts[txn.toAccountId]?.name,
                              selected: _selected.contains(txn.id),
                              onLongPress: () {
                                setState(() => _selected.add(txn.id!));
                              },
                              onTap: () {
                                if (_selectionMode) {
                                  setState(() {
                                    if (!_selected.remove(txn.id)) _selected.add(txn.id!);
                                  });
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          TransactionDetailScreen(transactionId: txn.id!),
                                    ),
                                  );
                                }
                              },
                            );

                            if (_selectionMode) return tile;

                            return Dismissible(
                              key: ValueKey<int>(txn.id!),
                              background: _swipeBackground(
                                context,
                                Alignment.centerLeft,
                                Icons.edit_rounded,
                                palette.accent,
                              ),
                              secondaryBackground: _swipeBackground(
                                context,
                                Alignment.centerRight,
                                Icons.delete_rounded,
                                palette.expense,
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  final id = await showAddTransactionSheet(
                                    context,
                                    ref,
                                    existing: txn,
                                  );
                                  return id != null;
                                }
                                return confirmAction(
                                  context,
                                  title: 'Delete transaction?',
                                  message:
                                      'This will adjust your account balances and cannot be undone.',
                                );
                              },
                              onDismissed: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  await ref.read(transactionRepositoryProvider).delete(txn.id!);
                                  if (context.mounted) {
                                    showSnack(context, 'Transaction deleted');
                                  }
                                }
                              },
                              child: tile,
                            );
                          }),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _swipeBackground(
    BuildContext context,
    Alignment alignment,
    IconData icon,
    Color color,
  ) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color.withOpacity(0.14),
      child: Icon(icon, color: color),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case kTypeIncome:
        return 'Income';
      case kTypeTransfer:
        return 'Transfer';
      default:
        return 'Expense';
    }
  }

  Future<void> _openFilters() async {
    final current = ref.read(transactionFilterProvider);
    final result = await Navigator.of(context).push<TransactionFilter>(
      MaterialPageRoute<TransactionFilter>(builder: (_) => FiltersScreen(initial: current)),
    );
    if (result != null) {
      ref.read(transactionFilterProvider.notifier).state = result;
    }
  }

  Future<void> _pickGrouping() async {
    final selected = await showAppSelectionSheet<String>(
      context,
      items: const <String>['day', 'week', 'month'],
      labelOf: (item) => item[0].toUpperCase() + item.substring(1),
      title: 'Group transactions by',
      selected: _groupBy,
    );
    if (selected != null) setState(() => _groupBy = selected);
  }

  Future<void> _bulkChangeCategory(Map<int, Category> categories) async {
    final list = categories.values.where((c) => c.type == kTypeExpense).toList();
    final selected = await showAppSelectionSheet<Category>(
      context,
      items: list,
      labelOf: (item) => item.name,
      title: 'Move to category',
    );
    if (selected == null) return;
    await ref.read(transactionRepositoryProvider).updateMany(
          _selected.toList(),
          categoryId: selected.id,
        );
    setState(_selected.clear);
    if (mounted) showSnack(context, 'Category updated for selected transactions');
  }

  Future<void> _bulkChangeAccount(List<Account> accounts) async {
    final selected = await showAppSelectionSheet<Account>(
      context,
      items: accounts,
      labelOf: (item) => item.name,
      title: 'Move to account',
    );
    if (selected == null) return;
    await ref.read(transactionRepositoryProvider).updateMany(
          _selected.toList(),
          accountId: selected.id,
        );
    setState(_selected.clear);
    if (mounted) showSnack(context, 'Account updated for selected transactions');
  }

  Future<void> _bulkDelete() async {
    final ok = await confirmAction(
      context,
      title: 'Delete ${_selected.length} transactions?',
      message: 'Balances will be adjusted. This cannot be undone.',
    );
    if (!ok) return;
    await ref.read(transactionRepositoryProvider).deleteMany(_selected.toList());
    setState(_selected.clear);
    if (mounted) showSnack(context, 'Transactions deleted');
  }
}

class _Group {
  _Group({required this.label});

  final String label;
  final List<Txn> items = <Txn>[];
  int income = 0;
  int expense = 0;
}

/// Compact month cash-flow strip at the top of the ledger.
class _FlowStrip extends StatelessWidget {
  const _FlowStrip({required this.income, required this.expense});

  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final net = income - expense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.graphiteGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'NET THIS MONTH',
                style: AppTextStyles.overline(const Color(0xFF8A8A94))
                    .copyWith(fontSize: 8, letterSpacing: 1.2),
              ),
              Text(
                Fmt.money(net),
                style: AppTextStyles.serif(
                  size: 20,
                  color: net >= 0 ? AppColors.limeA : AppColors.darkExpense,
                ),
              ),
            ],
          ),
          const Spacer(),
          _FlowPill(
            label: 'In',
            amount: income,
            color: AppColors.darkIncome,
            icon: Icons.south_west_rounded,
          ),
          const SizedBox(width: 8),
          _FlowPill(
            label: 'Out',
            amount: expense,
            color: AppColors.darkExpense,
            icon: Icons.north_east_rounded,
          ),
        ],
      ),
    );
  }
}

class _FlowPill extends StatelessWidget {
  const _FlowPill({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            '${label} ${Fmt.money(amount, forceCompact: true)}',
            style: AppTextStyles.caption(color).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
