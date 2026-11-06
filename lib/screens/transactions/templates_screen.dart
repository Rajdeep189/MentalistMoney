import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/template_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import 'add_transaction_sheet.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final async = ref.watch(templatesProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Templates', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.divider),
            ),
            child: Text(
              '2/2',
              style: AppTextStyles.base(
                size: 13,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: palette.sub),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editTemplate(context),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (templates) {
          if (templates.isEmpty) {
            return EmptyState(
              title: 'No templates yet',
              message:
                  'Templates are one-tap shortcuts for transactions you log often — coffee, commute, groceries.',
              illustration: IllustrationKind.wallet,
              actionLabel: 'Create a template',
              onAction: () => _editTemplate(context),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 120),
            itemCount: templates.length,
            onReorder: (oldIndex, newIndex) async {
              final list = <TxnTemplate>[...templates];
              if (newIndex > oldIndex) newIndex -= 1;
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              await ref.read(templateRepositoryProvider).reorder(list);
            },
            itemBuilder: (context, index) {
              final template = templates[index];
              return _TemplateRow(
                key: ValueKey<int>(template.id ?? index),
                template: template,
                onTap: () => _useTemplate(context, template),
                onLongPress: () => _editTemplate(context, existing: template),
                dragHandle: ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle_rounded,
                      color: palette.sub, size: 24),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _useTemplate(BuildContext context, TxnTemplate template) {
    return showAddTransactionSheet(
      context,
      ref,
      initialType: template.type,
      initialAmount: template.amount,
      initialAccountId: template.accountId,
      initialCategoryId: template.categoryId,
      initialNote: template.note ?? template.name,
    );
  }

  Future<void> _editTemplate(
    BuildContext context, {
    TxnTemplate? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
      text: existing == null ? '' : (existing.amount / 100).toStringAsFixed(0),
    );
    var type = existing?.type ?? kTypeExpense;
    var color = existing?.color ?? '#8A6A5C';
    const icons = <String>[
      'fastfood',
      'shopping_basket',
      'directions_bus',
      'restaurant',
      'local_gas_station',
      'movie',
      'fitness_center',
      'bolt',
      'account_balance',
      'payments',
    ];
    var icon = existing?.icon ?? icons.first;

    final saved = await showAppSheet<bool>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                existing == null ? 'New template' : 'Edit template',
                style: AppTextStyles.base(
                  size: 22,
                  weight: FontWeight.w700,
                  height: 1.2,
                ).copyWith(color: sheetContext.c.ink),
              ),
              const SizedBox(height: 16),
              _SheetField(controller: nameController, hint: 'Template name'),
              const SizedBox(height: 10),
              _SheetField(
                controller: amountController,
                hint: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  for (final option in const <String>[kTypeExpense, kTypeIncome])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setSheetState(() => type = option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: type == option
                                ? sheetContext.c.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: type == option
                                  ? sheetContext.c.accent
                                  : sheetContext.c.divider,
                            ),
                          ),
                          child: Text(
                            option == kTypeExpense ? 'Expense' : 'Income',
                            style: AppTextStyles.base(
                              size: 14.5,
                              weight: FontWeight.w600,
                              height: 1.1,
                            ).copyWith(
                              color: type == option
                                  ? AppColors.espresso
                                  : sheetContext.c.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final option in icons)
                    GestureDetector(
                      onTap: () => setSheetState(() => icon = option),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: icon == option
                              ? AppColors.fromHex(color)
                              : sheetContext.c.cardAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AppIcons.byName(option,
                              fallback: Icons.receipt_long_rounded),
                          size: 21,
                          color: icon == option
                              ? Colors.white
                              : sheetContext.c.ink,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  if (existing != null) ...<Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () async {
                            final ok = await confirmAction(
                              sheetContext,
                              title: 'Delete "${existing.name}"?',
                              message: 'The template disappears, transactions stay.',
                            );
                            if (!ok) return;
                            await ref
                                .read(templateRepositoryProvider)
                                .delete(existing.id!);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop(false);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: sheetContext.c.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: AppTextStyles.base(
                              size: 15,
                              weight: FontWeight.w600,
                              height: 1.1,
                            ).copyWith(color: sheetContext.c.expense),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sheetContext.c.accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          existing == null ? 'Create' : 'Save',
                          style: AppTextStyles.base(
                            size: 16,
                            weight: FontWeight.w700,
                            height: 1.1,
                          ).copyWith(color: AppColors.espresso),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      if (context.mounted) {
        showSnack(context, 'Give the template a name', error: true);
      }
      return;
    }
    final repo = ref.read(templateRepositoryProvider);
    if (existing == null) {
      await repo.create(
        TxnTemplate(
          name: name,
          type: type,
          amount: Fmt.parseAmount(amountController.text),
          icon: icon,
          color: color,
        ),
      );
    } else {
      await repo.delete(existing.id!);
      await repo.create(
        TxnTemplate(
          name: name,
          type: type,
          amount: Fmt.parseAmount(amountController.text),
          icon: icon,
          color: color,
          accountId: existing.accountId,
          categoryId: existing.categoryId,
          sortOrder: existing.sortOrder,
        ),
      );
    }
    if (context.mounted) {
      showSnack(context, existing == null ? 'Template created' : 'Template saved');
    }
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    super.key,
    required this.template,
    required this.onTap,
    required this.onLongPress,
    required this.dragHandle,
  });

  final TxnTemplate template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = AppColors.fromHex(template.color);
    final income = template.type == kTypeIncome;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: <Widget>[
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  AppIcons.byName(template.icon,
                      fallback: Icons.receipt_long_rounded),
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.base(
                        size: 20,
                        weight: FontWeight.w600,
                        height: 1.15,
                      ).copyWith(color: palette.ink),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (income ? palette.income : palette.expense)
                                .withOpacity(0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            income ? 'Income' : 'Expense',
                            style: AppTextStyles.base(
                              size: 12.5,
                              weight: FontWeight.w600,
                              height: 1.1,
                            ).copyWith(
                              color:
                                  income ? palette.income : palette.expense,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Fmt.money(template.amount),
                          style: AppTextStyles.base(
                            size: 14.5,
                            weight: FontWeight.w500,
                            height: 1.1,
                          ).copyWith(color: palette.sub),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              dragHandle,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: palette.cardAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: AppTextStyles.base(
          size: 16,
          weight: FontWeight.w500,
          height: 1.3,
        ).copyWith(color: palette.ink),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: AppTextStyles.base(
            size: 15.5,
            weight: FontWeight.w400,
          ).copyWith(color: palette.tertiary),
        ),
      ),
    );
  }
}
