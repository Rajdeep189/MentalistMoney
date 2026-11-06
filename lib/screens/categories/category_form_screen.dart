import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/fields.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.category, this.initialType = kTypeExpense});

  final Category? category;
  final String initialType;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.category?.name ?? '');
  late final TextEditingController _notesController =
      TextEditingController(text: widget.category?.notes ?? '');
  late String _type = widget.category?.type ?? widget.initialType;
  late String _icon = widget.category?.icon ?? 'category';
  late String _color = widget.category?.color ?? '#916CFF';
  late int _monthlyBudget = widget.category?.monthlyBudget ?? 0;
  late bool _archived = widget.category?.archived ?? false;
  late bool _favorite = widget.category?.isFavorite ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showSnack(context, 'Give this category a name', error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(categoryRepositoryProvider);
    final category = Category(
      id: widget.category?.id,
      name: _nameController.text.trim(),
      type: _type,
      icon: _icon,
      color: _color,
      monthlyBudget: _monthlyBudget,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      archived: _archived,
      isFavorite: _favorite,
      sortOrder: widget.category?.sortOrder ?? 0,
    );
    if (widget.category == null) {
      await repo.create(category);
    } else {
      await repo.update(category);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showSnack(context, widget.category == null ? 'Category created' : 'Category updated');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: Text(widget.category == null ? 'New category' : 'Edit category')),
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
              size: 72,
              rounded: true,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppTextField(
            controller: _nameController,
            label: 'Name',
            hint: 'e.g. Food & Drinks',
            prefixIcon: Icons.category_outlined,
          ),
          const SizedBox(height: AppSpacing.x4),
          SegmentedControl<String>(
            value: _type,
            options: const <SegmentOption<String>>[
              SegmentOption(value: kTypeExpense, label: 'Expense'),
              SegmentOption(value: kTypeIncome, label: 'Income'),
            ],
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('Icon', style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppIcons.categoryIcons.map((icon) {
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
          AmountField(
            paise: _monthlyBudget,
            onChanged: (value) => setState(() => _monthlyBudget = value),
            label: 'Monthly budget for this category (optional)',
            showCalculator: false,
          ),
          const SizedBox(height: AppSpacing.x4),
          AppTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Optional',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.x3),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 4),
            child: Column(
              children: <Widget>[
                SwitchRow(
                  title: 'Favourite',
                  subtitle: 'Shown first when adding transactions',
                  value: _favorite,
                  onChanged: (value) => setState(() => _favorite = value),
                  icon: Icons.star_outline_rounded,
                ),
                Divider(color: palette.divider, height: 1),
                SwitchRow(
                  title: 'Archived',
                  value: _archived,
                  onChanged: (value) => setState(() => _archived = value),
                  icon: Icons.archive_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: widget.category == null ? 'Create category' : 'Save changes',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
