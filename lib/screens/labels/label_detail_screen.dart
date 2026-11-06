import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/label_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_detail_screen.dart';
import 'labels_screen.dart';

class LabelDetailScreen extends ConsumerStatefulWidget {
  const LabelDetailScreen({
    super.key,
    required this.labelId,
    required this.labelName,
  });

  final int labelId;
  final String labelName;

  @override
  ConsumerState<LabelDetailScreen> createState() => _LabelDetailScreenState();
}

class _LabelDetailScreenState extends ConsumerState<LabelDetailScreen> {
  String _tab = 'Monthly';
  late String _name = widget.labelName;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final labels = ref.watch(labelsProvider).valueOrNull ?? const <LabelInfo>[];
    LabelInfo? info;
    for (final label in labels) {
      if (label.id == widget.labelId) info = label;
    }
    final tone = AppColors.fromHex(info?.color ?? '#A855F7');
    final txns =
        ref.watch(labelTransactionsProvider(_name)).valueOrNull ?? const <Txn>[];
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};
    final accounts =
        ref.watch(accountLookupProvider).valueOrNull ?? const <int, Account>{};
    final groups = _group(txns);
    final income = txns
        .where((t) => t.type == kTypeIncome)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final expense = txns
        .where((t) => t.type == kTypeExpense)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final total = income - expense;
    final ratio = income + expense == 0 ? 0.5 : income / (income + expense);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        backgroundColor: palette.surface,
        titleSpacing: 0,
        title: Text(
          'Label details',
          style: AppTextStyles.h2(palette.ink),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add transaction',
            onPressed: () => showAddTransactionSheet(
              context,
              ref,
              initialType: kTypeExpense,
            ),
            icon: Icon(Icons.add_rounded, size: 26, color: palette.ink),
          ),
          IconButton(
            tooltip: 'Delete label',
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Delete "$_name"?',
                message:
                    'The label is removed from every transaction. Transactions stay.',
              );
              if (!ok) return;
              await ref.read(labelRepositoryProvider).delete(widget.labelId);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: Icon(Icons.delete_outline_rounded, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _rename,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          4,
          AppSpacing.screen,
          130,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.divider.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Total',
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w400,
                    height: 1.1,
                  ).copyWith(color: palette.sub),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _signed(total),
                    style: AppTextStyles.base(
                      size: 32,
                      weight: FontWeight.w700,
                      height: 1.05,
                      letterSpacing: -0.5,
                    ).copyWith(color: palette.ink),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${txns.length} transaction${txns.length == 1 ? '' : 's'}',
                  style: AppTextStyles.base(
                    size: 15,
                    weight: FontWeight.w400,
                    height: 1.2,
                  ).copyWith(color: palette.sub),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Row(
                      children: <Widget>[
                        Container(
                          height: 8,
                          width: constraints.maxWidth * ratio,
                          color: palette.income,
                        ),
                        Container(
                          height: 8,
                          width: constraints.maxWidth * (1 - ratio),
                          color: palette.expense,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _SplitCard(
                        label: 'Income',
                        value: Fmt.money(income),
                        count: txns.where((t) => t.type == kTypeIncome).length,
                        tone: palette.income,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SplitCard(
                        label: 'Expense',
                        value: Fmt.money(expense),
                        count: txns.where((t) => t.type == kTypeExpense).length,
                        tone: palette.expense,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (txns.isEmpty)
            const EmptyState(
              title: 'No transactions',
              message: 'Tag a transaction with this label to see it here.',
              illustration: IllustrationKind.wallet,
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
                      _signed(group.total),
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
                  border: Border.all(color: palette.divider.withOpacity(0.35)),
                ),
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < group.items.length; i++)
                      PaisaTxnCard(
                        txn: group.items[i],
                        category: categories[group.items[i].categoryId],
                        accountName: accounts[group.items[i].accountId]?.name,
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
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Label colour: ${info?.color ?? ''}',
                style: AppTextStyles.caption(palette.tertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _name);
    final result = await showAppSheet<String>(
      context,
      (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          20,
          22,
          20 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Rename label',
              style: AppTextStyles.base(
                size: 22,
                weight: FontWeight.w700,
                height: 1.2,
              ).copyWith(color: sheetContext.c.ink),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: sheetContext.c.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: AppTextStyles.base(
                  size: 16,
                  weight: FontWeight.w500,
                  height: 1.3,
                ).copyWith(color: sheetContext.c.ink),
                decoration: InputDecoration(
                  hintText: 'Label name',
                  border: InputBorder.none,
                  hintStyle: AppTextStyles.base(
                    size: 15.5,
                    weight: FontWeight.w400,
                  ).copyWith(color: sheetContext.c.tertiary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: sheetContext.c.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'Save',
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w700,
                    height: 1.1,
                  ).copyWith(color: AppColors.espresso),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == null || result.isEmpty) return;
    await ref.read(labelRepositoryProvider).rename(widget.labelId, result);
    if (mounted) setState(() => _name = result);
  }

  List<_LabelGroup> _group(List<Txn> items) {
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
    return <_LabelGroup>[
      for (final key in order)
        _LabelGroup(
          label: _labelFor(DateTime.fromMillisecondsSinceEpoch(map[key]!.first.date)),
          total: map[key]!.fold<int>(
            0,
            (sum, t) => sum + (t.type == kTypeIncome ? t.amount : -t.amount),
          ),
          items: map[key]!,
        ),
    ];
  }

  static String _signed(int paise) =>
      paise < 0 ? '-${Fmt.plain(-paise)}' : Fmt.plain(paise);

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

class _LabelGroup {
  const _LabelGroup({
    required this.label,
    required this.total,
    required this.items,
  });

  final String label;
  final int total;
  final List<Txn> items;
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.label,
    required this.value,
    required this.count,
    required this.tone,
  });

  final String label;
  final String value;
  final int count;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.base(
              size: 14.5,
              weight: FontWeight.w500,
              height: 1.1,
            ).copyWith(color: palette.sub),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.base(
                size: 18,
                weight: FontWeight.w700,
                height: 1.1,
              ).copyWith(color: tone),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count transaction${count == 1 ? '' : 's'}',
            style: AppTextStyles.base(
              size: 13,
              weight: FontWeight.w400,
              height: 1.1,
            ).copyWith(color: palette.sub),
          ),
        ],
      ),
    );
  }
}
