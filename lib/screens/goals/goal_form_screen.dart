import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goal});

  final Goal? goal;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.goal?.name ?? '');
  late final TextEditingController _notesController =
      TextEditingController(text: widget.goal?.notes ?? '');
  late int _target = widget.goal?.targetAmount ?? 0;
  late int _saved = widget.goal?.savedAmount ?? 0;
  late int _recurring = widget.goal?.recurringAmount ?? 0;
  late String _icon = widget.goal?.icon ?? 'flag';
  late String _color = widget.goal?.color ?? '#916CFF';
  late int? _accountId = widget.goal?.accountId;
  late int? _categoryId = widget.goal?.categoryId;
  late DateTime? _deadline = widget.goal?.deadline == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(widget.goal!.deadline!);
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showSnack(context, 'Give this goal a name', error: true);
      return;
    }
    if (_target <= 0) {
      showSnack(context, 'Enter a target amount', error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(goalRepositoryProvider);
    final goal = Goal(
      id: widget.goal?.id,
      name: _nameController.text.trim(),
      targetAmount: _target,
      savedAmount: _saved,
      deadline: _deadline?.millisecondsSinceEpoch,
      accountId: _accountId,
      categoryId: _categoryId,
      icon: _icon,
      color: _color,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      recurringAmount: _recurring,
      status: widget.goal?.status ?? kGoalActive,
      createdAt: widget.goal?.createdAt ?? 0,
    );
    if (widget.goal == null) {
      await repo.create(goal);
    } else {
      await repo.update(goal);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showSnack(context, widget.goal == null ? 'Goal created' : 'Goal updated');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: Text(widget.goal == null ? 'New goal' : 'Edit goal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x2,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          Center(
            child: CategoryIcon(
              iconName: _icon,
              color: AppColors.fromHex(_color),
              size: 68,
              rounded: true,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppTextField(
            controller: _nameController,
            label: 'Goal name',
            hint: 'e.g. Emergency fund, Goa trip',
            prefixIcon: Icons.flag_outlined,
          ),
          const SizedBox(height: AppSpacing.x4),
          AmountField(
            paise: _target,
            onChanged: (value) => setState(() => _target = value),
            label: 'Target amount',
          ),
          const SizedBox(height: AppSpacing.x4),
          AmountField(
            paise: _saved,
            onChanged: (value) => setState(() => _saved = value),
            label: 'Already saved',
            showCalculator: false,
          ),
          const SizedBox(height: AppSpacing.x4),
          AmountField(
            paise: _recurring,
            onChanged: (value) => setState(() => _recurring = value),
            label: 'Monthly contribution (optional)',
            showCalculator: false,
          ),
          const SizedBox(height: AppSpacing.x4),
          DateField(
            label: 'Deadline (optional)',
            value: _deadline ?? DateTime.now().add(const Duration(days: 90)),
            onChanged: (value) => setState(() => _deadline = value),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('Icon', style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppIcons.goalIcons.map((icon) {
              final selected = _icon == icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = icon),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: selected ? AppColors.fromHex(_color) : palette.divider,
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: CategoryIcon(
                    iconName: icon,
                    color: selected ? AppColors.fromHex(_color) : palette.sub,
                    size: 32,
                  ),
                ),
              );
            }).toList(),
          ),
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
          AppDropdown<Account>(
            label: 'Linked account (optional)',
            items: accounts,
            value: accounts
                .where((a) => a.id == _accountId)
                .cast<Account?>()
                .firstWhere((a) => true, orElse: () => null),
            itemLabel: (item) => item.name,
            onChanged: (item) => setState(() => _accountId = item.id),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppDropdown<Category>(
            label: 'Linked savings category (optional)',
            items: categories.where((c) => c.type == kTypeExpense).toList(),
            value: categories
                .where((c) => c.id == _categoryId)
                .cast<Category?>()
                .firstWhere((c) => true, orElse: () => null),
            itemLabel: (item) => item.name,
            onChanged: (item) => setState(() => _categoryId = item.id),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Why does this goal matter?',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: widget.goal == null ? 'Create goal' : 'Save changes',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
