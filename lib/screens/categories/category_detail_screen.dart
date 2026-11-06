import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/paisa_blocks.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_detail_screen.dart';
import 'category_form_screen.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final int categoryId;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  int? _filterId;
  String _tab = 'Monthly';
  bool _overall = false;

  Future<List<Txn>>? _future;
  String _cacheKey = '';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final category =
        ref.watch(categoryByIdProvider(widget.categoryId)).valueOrNull;
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final revision = ref.watch(revisionProvider).value;
    final tone = AppColors.fromHex(category?.color ?? '#C88A5A');

    final children = categories
        .where((c) => c.parentId == widget.categoryId)
        .toList();
    final active = _filterId == null
        ? widget.categoryId
        : _filterId!;
    final ids = <int>[
      active,
      if (_filterId == null)
        for (final child in children)
          if (child.id != null) child.id!,
    ];

    if (category == null) {
      return Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(backgroundColor: palette.surface),
        body: const EmptyState(
          title: 'Category not found',
          message: 'This category may have been deleted.',
          illustration: IllustrationKind.chart,
          compact: true,
        ),
      );
    }

    final key = '${ids.join(',')}:$revision';
    if (key != _cacheKey) {
      _cacheKey = key;
      _future = ref.read(transactionRepositoryProvider).query(
            TransactionFilter(categoryIds: ids, sort: 'newest'),
          );
    }

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        backgroundColor: palette.surface,
        titleSpacing: 0,
        title: Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.h2(palette.ink),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'How categories work',
            onPressed: () => showInfoSheetForCategory(context),
            icon: Icon(Icons.info_outline_rounded, color: palette.sub),
          ),
          IconButton(
            onPressed: () => showAddTransactionSheet(
              context,
              ref,
              initialType: category.type,
              initialCategoryId: category.id,
            ),
            icon: Icon(Icons.add_rounded, size: 26, color: palette.ink),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: <Widget>[
                _FilterChip(
                  label: 'All',
                  icon: Icons.apps_rounded,
                  tone: palette.accent,
                  selected: _filterId == null,
                  onTap: () => setState(() => _filterId = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: category.name,
                  icon: AppIcons.byName(category.icon,
                      fallback: Icons.category_rounded),
                  tone: tone,
                  selected: _filterId == widget.categoryId,
                  onTap: () =>
                      setState(() => _filterId = widget.categoryId),
                ),
                for (final child in children) ...<Widget>[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: child.name,
                    icon: AppIcons.byName(child.icon,
                        fallback: Icons.category_rounded),
                    tone: AppColors.fromHex(child.color),
                    selected: _filterId == child.id,
                    onTap: () => setState(() => _filterId = child.id),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CategoryFormScreen(category: category),
          ),
        ),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(
          'Edit',
          style: AppTextStyles.base(
            size: 16,
            weight: FontWeight.w700,
            height: 1.1,
          ).copyWith(color: Colors.white),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: PaisaSegment<String>(
            options: const <String>['Daily', 'Weekly', 'Monthly', 'Yearly'],
            value: _tab,
            height: 54,
            onChanged: (value) => setState(() => _tab = value),
          ),
        ),
      ),
      body: FutureBuilder<List<Txn>>(
        future: _future,
        builder: (context, snapshot) {
          final txns = snapshot.data ?? const <Txn>[];
          if (snapshot.connectionState != ConnectionState.done &&
              _future != null &&
              txns.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = DateTime.now();
          final monthTxns = _overall
              ? txns
              : txns
                  .where((t) =>
                      DateTime.fromMillisecondsSinceEpoch(t.date).month ==
                          now.month &&
                      DateTime.fromMillisecondsSinceEpoch(t.date).year ==
                          now.year)
                  .toList();
          final spent = monthTxns
              .where((t) => t.type != kTypeIncome)
              .fold<int>(0, (sum, t) => sum + t.amount);
          final counts = monthTxns
              .where((t) => t.type != kTypeIncome)
              .length;
          final average = counts == 0 ? 0 : spent ~/ counts;
          final largest = monthTxns.isEmpty
              ? 0
              : monthTxns
                  .map((t) => t.amount)
                  .reduce((a, b) => a > b ? a : b);
          final days = _overall
              ? _dayCount(txns)
              : DateTime.now().day;
          final perDay = days == 0 ? 0 : spent ~/ days;
          final lastTxn = txns.isEmpty ? null : txns.first;
          final lastDays = lastTxn == null
              ? null
              : DateTime.now()
                  .difference(
                      DateTime.fromMillisecondsSinceEpoch(lastTxn.date))
                  .inDays;
          final groups = _group(txns);
          final breakdown = _breakdown(
            txns: txns,
            category: category,
            children: children,
          );
          final monthly = _monthlyTrend(txns);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              8,
              AppSpacing.screen,
              130,
            ),
            children: <Widget>[
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Category Breakdown',
                                style: AppTextStyles.base(
                                  size: 19,
                                  weight: FontWeight.w600,
                                  height: 1.2,
                                ).copyWith(color: palette.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Fmt.money(spent),
                                style: AppTextStyles.base(
                                  size: 17,
                                  weight: FontWeight.w700,
                                  height: 1.2,
                                ).copyWith(color: palette.ink),
                              ),
                            ],
                          ),
                        ),
                        _ToggleIcon(
                          icon: Icons.bar_chart_rounded,
                          selected: true,
                          tone: palette.accent,
                        ),
                        const SizedBox(width: 8),
                        _ToggleIcon(
                          icon: Icons.donut_large_rounded,
                          selected: false,
                          tone: palette.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: <Widget>[
                          for (final slice in breakdown)
                            if (slice.share > 0)
                              Expanded(
                                flex: (slice.share * 1000)
                                    .round()
                                    .clamp(1, 1000)
                                    .toInt(),
                                child: Container(
                                  height: 22,
                                  alignment: Alignment.center,
                                  color: AppColors.fromHex(slice.color),
                                  child: slice.share >= 0.08
                                      ? Text(
                                          '${(slice.share * 100).round()}%',
                                          style: AppTextStyles.base(
                                            size: 11.5,
                                            weight: FontWeight.w600,
                                            height: 1,
                                          ).copyWith(color: Colors.white),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final slice in breakdown)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: <Widget>[
                            Container(
                              height: 11,
                              width: 11,
                              decoration: BoxDecoration(
                                color: AppColors.fromHex(slice.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 42,
                              child: Text(
                                '${(slice.share * 100).round()}%',
                                style: AppTextStyles.base(
                                  size: 15,
                                  weight: FontWeight.w500,
                                  height: 1.2,
                                ).copyWith(color: palette.ink),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                slice.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.base(
                                  size: 15,
                                  weight: FontWeight.w400,
                                  height: 1.2,
                                ).copyWith(color: palette.ink),
                              ),
                            ),
                            Text(
                              Fmt.money(slice.total),
                              style: AppTextStyles.base(
                                size: 15,
                                weight: FontWeight.w600,
                                height: 1.2,
                              ).copyWith(color: palette.ink),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Monthly Spending Trend',
                            style: AppTextStyles.base(
                              size: 19,
                              weight: FontWeight.w600,
                              height: 1.2,
                            ).copyWith(color: palette.ink),
                          ),
                        ),
                        _ToggleIcon(
                          icon: Icons.calendar_month_rounded,
                          selected: true,
                          tone: palette.accent,
                        ),
                        const SizedBox(width: 8),
                        _ToggleIcon(
                          icon: Icons.bar_chart_rounded,
                          selected: false,
                          tone: palette.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: CustomPaint(
                        painter: _TrendPainter(
                          values: monthly.map((m) => m.total.toDouble()).toList(),
                          labels: monthly.map((m) => m.label).toList(),
                          line: palette.accent,
                          grid: palette.divider,
                          text: palette.tertiary,
                          style: AppTextStyles.base(
                            size: 10,
                            weight: FontWeight.w400,
                            height: 1.1,
                          ).copyWith(color: palette.tertiary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Overview',
                      style: AppTextStyles.base(
                        size: 20,
                        weight: FontWeight.w600,
                        height: 1.2,
                      ).copyWith(color: palette.ink),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: palette.divider.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: <Widget>[
                          for (final label in const <String>[
                            'This month',
                            'Overall',
                          ])
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _overall = label == 'Overall',
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: (_overall
                                            ? 'Overall'
                                            : 'This month') ==
                                            label
                                        ? palette.accent
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    label,
                                    style: AppTextStyles.base(
                                      size: 15,
                                      weight: FontWeight.w600,
                                      height: 1.1,
                                    ).copyWith(
                                      color: (_overall
                                                  ? 'Overall'
                                                  : 'This month') ==
                                              label
                                          ? AppColors.espresso
                                          : palette.sub,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.savings_outlined,
                            label: 'Total',
                            value: Fmt.money(spent),
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.receipt_long_outlined,
                            label: 'Transactions',
                            value: '$counts',
                          ),
                        ),
                      ],
                    ),
                    Divider(
                        color: palette.divider.withOpacity(0.4), height: 22),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.trending_up_rounded,
                            label: 'Average spent',
                            value: Fmt.money(average),
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.arrow_upward_rounded,
                            label: 'Largest',
                            value: Fmt.money(largest),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Transaction Insights',
                      style: AppTextStyles.base(
                        size: 19,
                        weight: FontWeight.w600,
                        height: 1.2,
                      ).copyWith(color: palette.ink),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.calendar_month_rounded,
                            label: 'This month',
                            value: '$counts transaction${counts == 1 ? '' : 's'}',
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.show_chart_rounded,
                            label: 'Daily Average',
                            value:
                                '${Fmt.plain(perDay)} per day',
                          ),
                        ),
                      ],
                    ),
                    Divider(
                        color: palette.divider.withOpacity(0.4), height: 22),
                    Row(
                      children: <Widget>[
                        Icon(Icons.schedule_rounded,
                            size: 18, color: palette.sub),
                        const SizedBox(width: 8),
                        Text(
                          'Last Transaction',
                          style: AppTextStyles.base(
                            size: 15,
                            weight: FontWeight.w400,
                            height: 1.2,
                          ).copyWith(color: palette.sub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastDays == null
                          ? 'No transactions yet'
                          : '$lastDays days ago',
                      style: AppTextStyles.base(
                        size: 17,
                        weight: FontWeight.w600,
                        height: 1.2,
                      ).copyWith(color: palette.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (txns.isEmpty)
                const EmptyState(
                  title: 'No transactions',
                  message: 'Add a transaction in this category to see it here.',
                  illustration: IllustrationKind.chart,
                  compact: true,
                )
              else
                for (final group in groups) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                    child: Row(
                      children: <Widget>[
                        Text(
                          group.label,
                          style: AppTextStyles.base(
                            size: 16,
                            weight: FontWeight.w500,
                            height: 1.1,
                          ).copyWith(color: palette.sub),
                        ),
                        const Spacer(),
                        Text(
                          Fmt.money(group.total),
                          style: AppTextStyles.base(
                            size: 16,
                            weight: FontWeight.w600,
                            height: 1.1,
                          ).copyWith(color: palette.ink),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: palette.divider.withOpacity(0.35)),
                    ),
                    child: Column(
                      children: <Widget>[
                        for (var i = 0; i < group.items.length; i++)
                          PaisaTxnCard(
                            txn: group.items[i],
                            category: _categoryFor(
                              categories,
                              group.items[i].categoryId,
                            ),
                            margin: EdgeInsets.zero,
                            showDivider: i < group.items.length - 1,
                            onTap: () => showTransactionDetail(
                              context,
                              group.items[i].id!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }

  Category? _categoryFor(List<Category> categories, int? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  int _dayCount(List<Txn> txns) {
    if (txns.isEmpty) return 0;
    final oldest = txns
        .map((t) => DateTime.fromMillisecondsSinceEpoch(t.date))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final diff = DateTime.now().difference(oldest).inDays;
    return diff <= 0 ? 1 : diff;
  }

  List<_Slice> _breakdown({
    required List<Txn> txns,
    required Category category,
    required List<Category> children,
  }) {
    final map = <int, int>{};
    for (final txn in txns) {
      if (txn.type == kTypeIncome) continue;
      map[txn.categoryId ?? category.id!] =
          (map[txn.categoryId ?? category.id!] ?? 0) + txn.amount;
    }
    final total = map.values.fold<int>(0, (a, b) => a + b);
    final slices = <_Slice>[];
    for (final entry in map.entries) {
      var match = entry.key == category.id ? category : null;
      if (match == null) {
        for (final child in children) {
          if (child.id == entry.key) match = child;
        }
      }
      slices.add(
        _Slice(
          name: match?.name ?? category.name,
          color: match?.color ?? category.color,
          total: entry.value,
          share: total == 0 ? 0 : entry.value / total,
        ),
      );
    }
    slices.sort((a, b) => b.total.compareTo(a.total));
    return slices;
  }

  List<_MonthPoint> _monthlyTrend(List<Txn> txns) {
    final now = DateTime.now();
    final points = <_MonthPoint>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final total = txns
          .where((t) {
            final date = DateTime.fromMillisecondsSinceEpoch(t.date);
            return date.year == month.year &&
                date.month == month.month &&
                t.type != kTypeIncome;
          })
          .fold<int>(0, (sum, t) => sum + t.amount);
      points.add(
        _MonthPoint(
          label:
              '${DateX.monthShort(month)} ${month.year.toString().substring(2)}',
          total: total,
        ),
      );
    }
    return points;
  }

  List<_TxnGroup> _group(List<Txn> items) {
    final map = <String, List<Txn>>{};
    final order = <String>[];
    for (final txn in items) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn.date);
      final key = _keyFor(date);
      if (!map.containsKey(key)) {
        map[key] = <Txn>[];
        order.add(key);
      }
      map[key]!.add(txn);
    }
    return <_TxnGroup>[
      for (final key in order)
        _TxnGroup(
          label: _labelFor(
              DateTime.fromMillisecondsSinceEpoch(map[key]!.first.date)),
          total: map[key]!.fold<int>(
            0,
            (sum, t) => sum + (t.type == kTypeIncome ? t.amount : -t.amount),
          ),
          items: map[key]!,
        ),
    ];
  }

  String _keyFor(DateTime date) {
    switch (_tab) {
      case 'Daily':
        return '${date.year}-${date.month}-${date.day}';
      case 'Weekly':
        final monday = date.subtract(Duration(days: date.weekday - 1));
        return '${monday.year}-${monday.month}-${monday.day}';
      case 'Yearly':
        return '${date.year}';
      case 'Monthly':
      default:
        return '${date.year}-${date.month}';
    }
  }

  String _labelFor(DateTime date) {
    switch (_tab) {
      case 'Daily':
        return Fmt.weekdayDate(date);
      case 'Weekly':
        return 'Week of ${Fmt.shortDate(date)}';
      case 'Yearly':
        return '${date.year}';
      case 'Monthly':
      default:
        return Fmt.monthYear(date.millisecondsSinceEpoch);
    }
  }
}

Future<void> showInfoSheetForCategory(BuildContext context) {
  return showAppSheet<void>(
    context,
    (sheetContext) => const InfoSheet(
      title: 'How Categories Work',
      intro:
          'Categories help you classify transactions by type: like Food, Transport, or Salary: so you can see where your money goes.',
      sections: <InfoSection>[
        InfoSection(
          icon: Icons.swap_vert_rounded,
          title: 'Types',
          body:
              'Separate categories for expenses, income, and transfers to keep things organized.',
        ),
        InfoSection(
          icon: Icons.account_tree_outlined,
          title: 'Subcategories',
          body:
              'Create subcategories to break down spending further (e.g., Food → Groceries, Dining Out).',
        ),
        InfoSection(
          icon: Icons.savings_outlined,
          title: 'Budgets',
          body:
              'Link categories to budgets to set spending limits and track progress.',
        ),
        InfoSection(
          icon: Icons.donut_large_rounded,
          title: 'Insights',
          body:
              'Tap any category to see transaction history, totals, and trends.',
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.divider.withOpacity(0.4)),
      ),
      child: child,
    );
  }
}

class _Slice {
  const _Slice({
    required this.name,
    required this.color,
    required this.total,
    required this.share,
  });

  final String name;
  final String color;
  final int total;
  final double share;
}

class _MonthPoint {
  const _MonthPoint({required this.label, required this.total});

  final String label;
  final int total;
}

class _TxnGroup {
  const _TxnGroup({
    required this.label,
    required this.total,
    required this.items,
  });

  final String label;
  final int total;
  final List<Txn> items;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tone.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? tone : palette.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: selected ? tone : palette.sub),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTextStyles.base(
                size: 15,
                weight: FontWeight.w500,
                height: 1.1,
              ).copyWith(color: selected ? tone : palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({
    required this.icon,
    required this.selected,
    required this.tone,
  });

  final IconData icon;
  final bool selected;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: selected ? tone.withOpacity(0.22) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: selected ? tone : palette.sub),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: palette.sub),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.base(
                size: 14.5,
                weight: FontWeight.w400,
                height: 1.1,
              ).copyWith(color: palette.sub),
            ),
          ],
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTextStyles.base(
              size: 17,
              weight: FontWeight.w600,
              height: 1.15,
            ).copyWith(color: palette.ink),
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.labels,
    required this.line,
    required this.grid,
    required this.text,
    required this.style,
  });

  final List<double> values;
  final List<String> labels;
  final Color line;
  final Color grid;
  final Color text;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 34.0;
    const bottom = 20.0;
    final width = size.width - left;
    final height = size.height - bottom;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final max = maxValue <= 0 ? 1.0 : maxValue * 1.15;
    final gridPaint = Paint()
      ..color = grid.withOpacity(0.5)
      ..strokeWidth = 1;
    final labelStyle = style.copyWith(color: text);
    for (var i = 0; i <= 3; i++) {
      final y = height - (height * i / 3);
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      final value = max * i / 3;
      final painter = TextPainter(
        text: TextSpan(
          text: Fmt.money(value.round(), forceCompact: true),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }
    final path = Path();
    final dots = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = left + (width * i / (values.length - 1 <= 0 ? 1 : values.length - 1));
      final y = height - (height * (values[i] / max));
      dots.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    for (final dot in dots) {
      canvas.drawCircle(dot, 3.5, Paint()..color = line);
    }
    for (var i = 0; i < labels.length; i++) {
      final x = left + (width * i / (labels.length - 1 <= 0 ? 1 : labels.length - 1));
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(x - painter.width / 2, height + 5),
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.labels != labels;
}
