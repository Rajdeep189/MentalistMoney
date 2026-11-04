import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/budget_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budget});

  final Budget? budget;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.budget?.name ?? '');
  late int _amount = widget.budget?.amount ?? 0;
  late String _period = widget.budget?.period ?? kPeriodMonthly;
  late String _type = widget.budget?.type ?? 'overall';
  late List<int> _categoryIds = List<int>.of(widget.budget?.categoryIds ?? const <int>[]);
  late bool _rollover = widget.budget?.rollover ?? false;
  late bool _carryForward = widget.budget?.carryForward ?? false;
  late String _color = widget.budget?.color ?? '#916CFF';
  late int? _accountId = widget.budget?.accountId;
  late DateTime _start = widget.budget?.startDate != null
      ? DateTime.fromMillisecondsSinceEpoch(widget.budget!.startDate)
      : DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _end = widget.budget?.endDate != null
      ? DateTime.fromMillisecondsSinceEpoch(widget.budget!.endDate)
      : DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showSnack(context, 'Give this budget a name', error: true);
      return;
    }
    if (_amount <= 0) {
      showSnack(context, 'Enter a budget amount', error: true);
      return;
    }
    if (_type != 'overall' && _categoryIds.isEmpty && _type != 'account') {
      showSnack(context, 'Pick at least one category', error: true);
      return;
    }
    setState(() => _saving = true);

    final range = _period == kPeriodCustom
        ? (_start, _end)
        : BudgetRepository.periodRange(_period, DateTime.now(), startDay: _start.day);

    final budget = Budget(
      id: widget.budget?.id,
      name: _nameController.text.trim(),
      amount: _amount,
      period: _period,
      startDate: range.$1.millisecondsSinceEpoch,
      endDate: DateTime(range.$2.year, range.$2.month, range.$2.day, 23, 59, 59)
          .millisecondsSinceEpoch,
      type: _type,
      rollover: _rollover,
      carryForward: _carryForward,
      color: _color,
      icon: widget.budget?.icon ?? 'savings',
      accountId: _type == 'account' ? _accountId : null,
      categoryIds: _categoryIds,
    );

    final repo = ref.read(budgetRepositoryProvider);
    if (widget.budget == null) {
      await repo.create(budget);
    } else {
      await repo.update(budget);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showSnack(context, widget.budget == null ? 'Budget created' : 'Budget updated');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final expenseCategories = categories.where((c) => c.type == kTypeExpense).toList();
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: Text(widget.budget == null ? 'New budget' : 'Edit budget')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x2,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          AppTextField(
            controller: _nameController,
            label: 'Budget name',
            hint: 'e.g. Monthly budget, Food & Drinks',
            prefixIcon: Icons.pie_chart_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.x4),
          AmountField(
            paise: _amount,
            onChanged: (value) => setState(() => _amount = value),
            label: 'Budget amount',
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('Budget type', style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <MapEntry<String, String>>[
              MapEntry<String, String>('overall', 'Overall'),
              MapEntry<String, String>('category', 'Single category'),
              MapEntry<String, String>('multi_category', 'Multiple categories'),
              MapEntry<String, String>('account', 'Account based'),
            ].map((entry) {
              return AppChip(
                label: entry.value,
                selected: _type == entry.key,
                onTap: () => setState(() => _type = entry.key),
              );
            }).toList(),
          ),
          if (_type == 'account') ...<Widget>[
            const SizedBox(height: AppSpacing.x4),
            Text('Account', style: AppTextStyles.label(palette.sub)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accounts
                  .map((account) => AppChip(
                        label: account.name,
                        selected: _accountId == account.id,
                        onTap: () => setState(() => _accountId = account.id),
                      ))
                  .toList(),
            ),
          ],
          if (_type == 'category' || _type == 'multi_category') ...<Widget>[
            const SizedBox(height: AppSpacing.x4),
            Text('Categories', style: AppTextStyles.label(palette.sub)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: expenseCategories.map((category) {
                final selected = _categoryIds.contains(category.id);
                return AppChip(
                  label: category.name,
                  selected: selected,
                  onTap: () => setState(() {
                    if (_type == 'category') {
                      _categoryIds = <int>[category.id!];
                    } else if (selected) {
                      _categoryIds.remove(category.id);
                    } else {
                      _categoryIds.add(category.id!);
                    }
                  }),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.x4),
          Text('Period', style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <String>[kPeriodWeekly, kPeriodMonthly, kPeriodYearly, kPeriodCustom]
                .map((period) => AppChip(
                      label: period[0].toUpperCase() + period.substring(1),
                      selected: _period == period,
                      onTap: () => setState(() => _period = period),
                    ))
                .toList(),
          ),
          if (_period == kPeriodCustom) ...<Widget>[
            const SizedBox(height: AppSpacing.x4),
            DateField(
              label: 'Start date',
              value: _start,
              onChanged: (value) => setState(() => _start = value),
            ),
            const SizedBox(height: AppSpacing.x3),
            DateField(
              label: 'End date',
              value: _end,
              onChanged: (value) => setState(() => _end = value),
            ),
          ],
          const SizedBox(height: AppSpacing.x4),
          Text('Colour', style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: AppColors.categoryPalette.map((color) {
              final hex = AppColors.toHex(color);
              final selected = _color == hex;
              return GestureDetector(
                onTap: () => setState(() => _color = hex),
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? palette.ink : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 4),
            child: Column(
              children: <Widget>[
                SwitchRow(
                  title: 'Roll over unused amount',
                  subtitle: 'Add leftovers to the next period',
                  value: _rollover,
                  onChanged: (value) => setState(() => _rollover = value),
                  icon: Icons.redo_rounded,
                ),
                Divider(color: palette.divider, height: 1),
                SwitchRow(
                  title: 'Carry forward overspending',
                  subtitle: 'Reduce the next period by the overspend',
                  value: _carryForward,
                  onChanged: (value) => setState(() => _carryForward = value),
                  icon: Icons.undo_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.notifications_active_outlined,
                        size: 16, color: palette.accent),
                    const SizedBox(width: 6),
                    Text('Alert thresholds', style: context.h3),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'MoneyMan notifies you at 50%, 75%, 90% and 100% of this budget.',
                  style: context.caption,
                ),
                const SizedBox(height: AppSpacing.x3),
                Row(
                  children: <Widget>[
                    for (final threshold in <int>[50, 75, 90, 100])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TintChip(label: '$threshold%', dense: true),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: widget.budget == null ? 'Create budget' : 'Save changes',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
