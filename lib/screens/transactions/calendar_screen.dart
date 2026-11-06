import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa_blocks.dart';
import 'add_transaction_sheet.dart';
import 'transaction_detail_screen.dart';
import 'transactions_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _selected = DateTime.now();
  Future<List<Txn>>? _future;
  String _cacheKey = '';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final revision = ref.watch(revisionProvider).value;
    final monthEnd = DateTime(_month.year, _month.month + 1, 1);
    final key = '${_month.year}-${_month.month}-$revision';
    if (key != _cacheKey) {
      _cacheKey = key;
      _future = ref.read(transactionRepositoryProvider).query(
            TransactionFilter(
              startDate: _month,
              endDate: monthEnd,
              sort: 'newest',
            ),
          );
    }

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        backgroundColor: palette.surface,
        titleSpacing: 0,
        title: Text('Calendar', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TransactionsScreen(),
              ),
            ),
            child: Text(
              'See all',
              style: AppTextStyles.base(
                size: 16,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: palette.accent),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTransactionSheet(
          context,
          ref,
          initialDate: _selected,
        ),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      body: FutureBuilder<List<Txn>>(
        future: _future,
        builder: (context, snapshot) {
          final txns = snapshot.data ?? const <Txn>[];
          final byDay = <int, List<Txn>>{};
          for (final txn in txns) {
            final date = DateTime.fromMillisecondsSinceEpoch(txn.date);
            byDay.putIfAbsent(date.day, () => <Txn>[]).add(txn);
          }
          final selectedItems = byDay[_selected.day] ?? const <Txn>[];
          final categories = ref.watch(categoryLookupProvider).valueOrNull ??
              const <int, Category>{};
          final accounts = ref.watch(accountLookupProvider).valueOrNull ??
              const <int, Account>{};
          final income = selectedItems
              .where((t) => t.type == kTypeIncome)
              .fold<int>(0, (sum, t) => sum + t.amount);
          final expense = selectedItems
              .where((t) => t.type == kTypeExpense)
              .fold<int>(0, (sum, t) => sum + t.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1, 1),
                    ),
                    icon: Icon(Icons.chevron_left_rounded,
                        size: 28, color: palette.accent),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${DateX.monthShort(_month)} ${_month.year}',
                        style: AppTextStyles.base(
                          size: 19,
                          weight: FontWeight.w700,
                          height: 1.2,
                        ).copyWith(color: palette.ink),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1, 1),
                    ),
                    icon: Icon(Icons.chevron_right_rounded,
                        size: 28, color: palette.accent),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  for (final label in const <String>[
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ])
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: AppTextStyles.base(
                            size: 14,
                            weight: FontWeight.w500,
                            height: 1.2,
                          ).copyWith(color: palette.sub),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _MonthGrid(
                month: _month,
                selected: _selected,
                byDay: byDay,
                onSelect: (day) => setState(() => _selected = day),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _TotalTile(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Income',
                      value: Fmt.money(income),
                      tone: palette.income,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TotalTile(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Expense',
                      value: Fmt.money(expense),
                      tone: palette.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${Fmt.weekdayDate(_selected)}, Transactions',
                style: AppTextStyles.base(
                  size: 17,
                  weight: FontWeight.w500,
                  height: 1.2,
                ).copyWith(color: palette.ink),
              ),
              const SizedBox(height: 10),
              if (selectedItems.isEmpty)
                const EmptyState(
                  title: 'No transactions found',
                  message: 'No transactions for this day',
                  illustration: IllustrationKind.wallet,
                  compact: true,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: palette.divider.withOpacity(0.35)),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (var i = 0; i < selectedItems.length; i++)
                        PaisaTxnCard(
                          txn: selectedItems[i],
                          category: categories[selectedItems[i].categoryId],
                          accountName:
                              accounts[selectedItems[i].accountId]?.name,
                          margin: EdgeInsets.zero,
                          showDivider: i < selectedItems.length - 1,
                          onTap: () => showTransactionDetail(
                            context,
                            selectedItems[i].id!,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.byDay,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Map<int, List<Txn>> byDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final items = byDay[day] ?? const <Txn>[];
      var income = 0;
      var expense = 0;
      for (final txn in items) {
        if (txn.type == kTypeIncome) {
          income += txn.amount;
        } else if (txn.type == kTypeExpense) {
          expense += txn.amount;
        }
      }
      final isSelected = selected.year == date.year &&
          selected.month == date.month &&
          selected.day == date.day;
      final label = income > 0 && expense == 0
          ? Fmt.money(income, forceCompact: true)
          : expense > 0
              ? '-${Fmt.money(expense, forceCompact: true)}'
              : null;
      cells.add(
        GestureDetector(
          onTap: () => onSelect(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? palette.accent : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '$day',
                  style: AppTextStyles.base(
                    size: 15,
                    weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    height: 1.1,
                  ).copyWith(color: palette.ink),
                ),
                if (label != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: AppTextStyles.base(
                        size: 9.5,
                        weight: FontWeight.w500,
                        height: 1.1,
                      ).copyWith(
                        color: expense > 0 ? palette.expense : palette.income,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      children: cells,
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.divider.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 15, color: tone),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.base(
                  size: 15,
                  weight: FontWeight.w400,
                  height: 1.1,
                ).copyWith(color: palette.ink),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.base(
              size: 18,
              weight: FontWeight.w700,
              height: 1.1,
            ).copyWith(color: palette.ink),
          ),
        ],
      ),
    );
  }
}
