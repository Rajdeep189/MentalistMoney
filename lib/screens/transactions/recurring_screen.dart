import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustration.dart';
import '../../widgets/pickers.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final rules = ref.watch(recurringRulesProvider);
    final accounts = ref.watch(accountLookupProvider).valueOrNull ?? const <int, Account>{};
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Recurring transactions'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Post due transactions now',
            icon: const Icon(Icons.play_circle_outline_rounded),
            onPressed: () async {
              await ref.read(transactionRepositoryProvider).materialiseRecurring();
              if (context.mounted) showSnack(context, 'Due recurring transactions posted');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'No recurring transactions',
              message: 'Automate rent, subscriptions and salary so nothing is missed.',
              illustration: IllustrationKind.bills,
              actionLabel: 'Create a repeat rule',
              onAction: () => _openEditor(context, ref),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              120,
            ),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x3),
            itemBuilder: (context, index) {
              final rule = list[index];
              final category = categories[rule.categoryId];
              return AppCard(
                onTap: () => _openEditor(context, ref, rule: rule),
                child: Row(
                  children: <Widget>[
                    CategoryIcon(
                      iconName: category?.icon ?? 'autorenew',
                      color: rule.type == kTypeIncome ? palette.income : palette.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            rule.note?.trim().isNotEmpty == true
                                ? rule.note!
                                : (category?.name ?? 'Recurring'),
                            style: AppTextStyles.label(palette.ink),
                          ),
                          Text(
                            '${frequencyLabel(rule.frequency)} · next ${Fmt.date(rule.nextDate)}'
                            '${rule.accountId != null ? ' · ${accounts[rule.accountId]?.name ?? ''}' : ''}',
                            style: AppTextStyles.caption(palette.tertiary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          Fmt.money(rule.amount),
                          style: AppTextStyles.money(14, color: palette.ink,
                              weight: FontWeight.w600),
                        ),
                        Switch.adaptive(
                          value: rule.active,
                          onChanged: (value) => ref
                              .read(transactionRepositoryProvider)
                              .toggleRecurringRule(rule.id!, value),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {RecurringRule? rule}) async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const <Account>[];
    final categories = ref.read(categoriesProvider).valueOrNull ?? const <Category>[];
    if (accounts.isEmpty) {
      showSnack(context, 'Add an account before creating a recurring rule', error: true);
      return;
    }
    final result = await showAppSheet<RecurringRule>(
      context,
      (sheetContext) => _RecurringEditor(
        rule: rule,
        accounts: accounts,
        categories: categories,
      ),
    );
    if (result == null) return;
    await ref.read(transactionRepositoryProvider).saveRecurringRule(result);
    if (context.mounted) showSnack(context, 'Recurring rule saved');
  }
}

class _RecurringEditor extends StatefulWidget {
  const _RecurringEditor({
    this.rule,
    required this.accounts,
    required this.categories,
  });

  final RecurringRule? rule;
  final List<Account> accounts;
  final List<Category> categories;

  @override
  State<_RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends State<_RecurringEditor> {
  late String _type = widget.rule?.type ?? kTypeExpense;
  late int _amount = widget.rule?.amount ?? 0;
  late String _frequency = widget.rule?.frequency ?? 'monthly';
  late int _accountId = widget.rule?.accountId ?? widget.accounts.first.id!;
  int? _categoryId;
  late DateTime _next = DateTime.fromMillisecondsSinceEpoch(
    widget.rule?.nextDate ?? DateTime.now().millisecondsSinceEpoch,
  );
  late final TextEditingController _noteController =
      TextEditingController(text: widget.rule?.note ?? '');

  @override
  void initState() {
    super.initState();
    _categoryId = widget.rule?.categoryId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final filteredCategories =
        widget.categories.where((c) => c.type == _type).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SheetHeader(
            title: widget.rule == null ? 'New repeat rule' : 'Edit repeat rule',
            subtitle: 'MoneyMan posts it automatically when it is due.',
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                0,
                AppSpacing.x5,
                AppSpacing.x5,
              ),
              children: <Widget>[
                SegmentedControl<String>(
                  value: _type,
                  options: const <SegmentOption<String>>[
                    SegmentOption(value: kTypeExpense, label: 'Expense'),
                    SegmentOption(value: kTypeIncome, label: 'Income'),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value;
                    _categoryId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.x4),
                AmountField(
                  paise: _amount,
                  onChanged: (value) => setState(() => _amount = value),
                  label: 'Amount',
                ),
                const SizedBox(height: AppSpacing.x4),
                AppDropdown<Account>(
                  label: 'Account',
                  items: widget.accounts,
                  value: widget.accounts.firstWhere((a) => a.id == _accountId,
                      orElse: () => widget.accounts.first),
                  itemLabel: (item) => item.name,
                  onChanged: (item) => setState(() => _accountId = item.id!),
                ),
                const SizedBox(height: AppSpacing.x4),
                AppDropdown<Category>(
                  label: 'Category',
                  items: filteredCategories,
                  value: filteredCategories
                      .where((c) => c.id == _categoryId)
                      .cast<Category?>()
                      .firstWhere((c) => true, orElse: () => null),
                  itemLabel: (item) => item.name,
                  onChanged: (item) => setState(() => _categoryId = item.id),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text('Repeat', style: AppTextStyles.label(palette.sub)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kFrequencyOptions
                      .where((frequency) => frequency != 'one_time')
                      .map((frequency) => AppChip(
                            label: frequencyLabel(frequency),
                            selected: _frequency == frequency,
                            onTap: () => setState(() => _frequency = frequency),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.x4),
                DateField(
                  label: 'Next date',
                  value: _next,
                  onChanged: (value) => setState(() => _next = value),
                ),
                const SizedBox(height: AppSpacing.x4),
                AppTextField(
                  controller: _noteController,
                  label: 'Note',
                  hint: 'e.g. Netflix subscription',
                ),
                const SizedBox(height: AppSpacing.x5),
                PrimaryButton(
                  label: 'Save rule',
                  onPressed: () {
                    if (_amount <= 0) {
                      showSnack(context, 'Enter an amount', error: true);
                      return;
                    }
                    Navigator.of(context).pop(
                      RecurringRule(
                        id: widget.rule?.id,
                        frequency: _frequency,
                        nextDate: _next.millisecondsSinceEpoch,
                        type: _type,
                        amount: _amount,
                        accountId: _accountId,
                        categoryId: _categoryId,
                        note: _noteController.text.trim().isEmpty
                            ? null
                            : _noteController.text.trim(),
                        active: widget.rule?.active ?? true,
                      ),
                    );
                  },
                ),
                if (widget.rule != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.x2),
                  DestructiveButton(
                    label: 'Delete rule',
                    icon: Icons.delete_outline_rounded,
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final repo = ProviderScope.containerOf(context, listen: false)
                          .read(transactionRepositoryProvider);
                      await repo.deleteRecurringRule(widget.rule!.id!);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
