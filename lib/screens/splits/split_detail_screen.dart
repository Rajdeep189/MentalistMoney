import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/split_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/fields.dart';
import '../../widgets/section_header.dart';

class SplitDetailScreen extends ConsumerWidget {
  const SplitDetailScreen({super.key, required this.groupId});

  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final summaryAsync = ref.watch(splitSummaryProvider(groupId));

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(summaryAsync.valueOrNull?.group.name ?? 'Split group'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Share summary',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _share(context, summaryAsync.valueOrNull),
          ),
          IconButton(
            tooltip: 'Delete group',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Delete this group?',
                message: 'All shared expenses and settlements in this group will be removed.',
              );
              if (!ok) return;
              await ref.read(splitRepositoryProvider).deleteGroup(groupId);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpense(context, ref, summaryAsync.valueOrNull),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (summary) {
          if (summary == null) return const Center(child: Text('Group not found'));
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Total spent', style: context.caption),
                    AmountText(summary.totalSpent, size: 26, weight: FontWeight.w700),
                    Text(
                      '${summary.members.length} members · ${summary.expenses.length} expenses',
                      style: context.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x5),
              SectionHeader(title: 'Balances', padding: EdgeInsets.zero),
              AppCard(
                child: Column(
                  children: summary.balances
                      .map(
                        (balance) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: <Widget>[
                              CategoryIcon(
                                icon: Icons.person_rounded,
                                color: balance.net >= 0 ? palette.income : palette.expense,
                                size: 34,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(balance.member.name,
                                        style: AppTextStyles.label(palette.ink)),
                                    Text(
                                      'paid ${Fmt.money(balance.paid, forceCompact: true)} · share ${Fmt.money(balance.owed, forceCompact: true)}',
                                      style: context.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                balance.net >= 0
                                    ? '+${Fmt.money(balance.net, forceCompact: true)}'
                                    : '-${Fmt.money(balance.net.abs(), forceCompact: true)}',
                                style: AppTextStyles.money(13,
                                    color: balance.net >= 0 ? palette.income : palette.expense,
                                    weight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (summary.suggestions.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.x5),
                SectionHeader(title: 'Simplest settlements', padding: EdgeInsets.zero),
                AppCard(
                  child: Column(
                    children: summary.suggestions
                        .map(
                          (suggestion) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    '${suggestion.from.name} → ${suggestion.to.name}',
                                    style: AppTextStyles.body(palette.ink),
                                  ),
                                ),
                                Text(
                                  Fmt.money(suggestion.amount, forceCompact: true),
                                  style: AppTextStyles.money(13, color: palette.ink,
                                      weight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(splitRepositoryProvider)
                                        .addSettlement(
                                          groupId: groupId,
                                          fromMemberId: suggestion.from.id!,
                                          toMemberId: suggestion.to.id!,
                                          amount: suggestion.amount,
                                          date: DateTime.now(),
                                          note: 'Settled in app',
                                        );
                                    if (context.mounted) {
                                      showSnack(context, 'Settlement recorded');
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 30),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  child: Text('Settle',
                                      style: AppTextStyles.caption(palette.accent)),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x5),
              SectionHeader(title: 'Expenses', padding: EdgeInsets.zero),
              if (summary.expenses.isEmpty)
                AppCard(
                  child: Text('No expenses yet. Tap "Add expense" to start.',
                      style: context.bodyMuted),
                )
              else
                AppCard(
                  child: Column(
                    children: summary.expenses
                        .map(
                          (expense) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: <Widget>[
                                CategoryIcon(
                                  icon: Icons.receipt_long_rounded,
                                  color: palette.accent,
                                  size: 34,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        expense.description?.trim().isNotEmpty == true
                                            ? expense.description!
                                            : 'Shared expense',
                                        style: AppTextStyles.label(palette.ink),
                                      ),
                                      Text(
                                        'Paid by ${_memberName(summary, expense.paidByMemberId)} · ${Fmt.date(expense.date)}',
                                        style: context.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  Fmt.money(expense.amount, forceCompact: true),
                                  style: AppTextStyles.money(13, color: palette.ink,
                                      weight: FontWeight.w600),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      size: 16, color: palette.tertiary),
                                  onPressed: () async {
                                    final ok = await confirmAction(
                                      context,
                                      title: 'Remove this expense?',
                                      message: 'Balances will be recalculated.',
                                    );
                                    if (!ok) return;
                                    await ref
                                        .read(splitRepositoryProvider)
                                        .deleteExpense(expense.id!);
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _memberName(SplitGroupSummary summary, int memberId) {
    for (final member in summary.members) {
      if (member.id == memberId) return member.name;
    }
    return 'Unknown';
  }

  Future<void> _share(BuildContext context, SplitGroupSummary? summary) async {
    if (summary == null) return;
    final buffer = StringBuffer()
      ..writeln('${summary.group.name} — split summary')
      ..writeln('Total: ${Fmt.money(summary.totalSpent)}')
      ..writeln();
    for (final balance in summary.balances) {
      buffer.writeln(
        '${balance.member.name}: ${balance.net >= 0 ? 'is owed' : 'owes'} '
        '${Fmt.money(balance.net.abs())}',
      );
    }
    if (summary.suggestions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Settle with:');
      for (final suggestion in summary.suggestions) {
        buffer.writeln(
          '${suggestion.from.name} → ${suggestion.to.name}: ${Fmt.money(suggestion.amount)}',
        );
      }
    }
    await Share.share(buffer.toString(), subject: summary.group.name);
  }

  Future<void> _addExpense(
    BuildContext context,
    WidgetRef ref,
    SplitGroupSummary? summary,
  ) async {
    if (summary == null || summary.members.isEmpty) return;
    final categories = ref.read(categoriesProvider).valueOrNull ?? const <Category>[];
    final description = TextEditingController();
    int amount = 0;
    int paidBy = summary.members.first.id!;
    String method = 'equal';
    final selected = <int>{for (final member in summary.members) member.id!};
    final percents = <int, int>{};
    final exact = <int, int>{};
    final shares = <int, int>{};

    final result = await showAppSheet<bool>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SheetHeader(title: 'Add shared expense'),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
                  children: <Widget>[
                    AmountField(
                      paise: amount,
                      onChanged: (value) => setSheetState(() => amount = value),
                      label: 'Total amount',
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    AppTextField(
                      controller: description,
                      label: 'Description',
                      hint: 'e.g. Hotel booking',
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    Text('Paid by', style: AppTextStyles.label(context.c.sub)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: summary.members
                          .map(
                            (member) => AppChip(
                              label: member.name,
                              selected: paidBy == member.id,
                              onTap: () => setSheetState(() => paidBy = member.id!),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    Text('Split method', style: AppTextStyles.label(context.c.sub)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const <MapEntry<String, String>>[
                        MapEntry<String, String>('equal', 'Equally'),
                        MapEntry<String, String>('percent', 'By %'),
                        MapEntry<String, String>('exact', 'Exact amounts'),
                        MapEntry<String, String>('shares', 'By shares'),
                      ]
                          .map(
                            (entry) => AppChip(
                              label: entry.value,
                              selected: method == entry.key,
                              onTap: () => setSheetState(() => method = entry.key),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    ...summary.members.map((member) {
                      final id = member.id!;
                      final included = selected.contains(id);
                      if (method == 'equal' || method == 'percent') {
                        return SwitchRow(
                          title: member.name,
                          value: included,
                          onChanged: (value) => setSheetState(() {
                            if (value) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          }),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(member.name,
                                  style: AppTextStyles.body(context.c.ink)),
                            ),
                            SizedBox(
                              width: 110,
                              child: AppTextField(
                                hint: method == 'percent' ? '%' : method == 'shares' ? 'shares' : '₹',
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final parsed = int.tryParse(value) ?? 0;
                                  if (method == 'percent') {
                                    percents[id] = parsed * 100;
                                  } else if (method == 'shares') {
                                    shares[id] = parsed;
                                  } else {
                                    exact[id] = Fmt.parseAmount(value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.x4),
                    PrimaryButton(
                      label: 'Add expense',
                      onPressed: () {
                        if (amount <= 0) {
                          showSnack(context, 'Enter an amount', error: true);
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                    ),
                    const SizedBox(height: AppSpacing.x5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != true) return;

    final Map<int, int> values;
    switch (method) {
      case 'percent':
        final totalPercent = selected.fold<int>(0, (sum, id) => sum + (percents[id] ?? 10000 ~/ summary.members.length));
        values = <int, int>{
          for (final id in selected)
            id: totalPercent == 0 ? 10000 ~/ selected.length : (percents[id] ?? 10000 ~/ summary.members.length),
        };
        break;
      case 'shares':
        values = <int, int>{
          for (final entry in shares.entries)
            if (entry.value > 0) entry.key: entry.value,
        };
        break;
      case 'exact':
        values = <int, int>{
          for (final entry in exact.entries)
            if (entry.value > 0) entry.key: entry.value,
        };
        break;
      default:
        values = <int, int>{
          for (final id in selected) id: (amount / selected.length).round(),
        };
    }

    await ref.read(splitRepositoryProvider).addExpense(
          groupId: groupId,
          amount: amount,
          paidByMemberId: paidBy,
          date: DateTime.now(),
          description: description.text.trim().isEmpty ? null : description.text.trim(),
          splitMethod: method,
          shareValues: values,
        );
    if (context.mounted) showSnack(context, 'Shared expense added');
  }
}
