import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../core/utils/smart_engine.dart';
import '../../core/utils/validators.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/receipt_service.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';

/// Opens the add / edit transaction bottom sheet.
Future<int?> showAddTransactionSheet(
  BuildContext context,
  WidgetRef ref, {
  Txn? existing,
  String? initialType,
  int? initialAccountId,
  int? initialCategoryId,
  int? initialAmount,
  String? initialNote,
  DateTime? initialDate,
}) {
  return showAppSheet<int>(
    context,
    (sheetContext) => AddTransactionSheet(
      existing: existing,
      initialType: initialType,
      initialAccountId: initialAccountId,
      initialCategoryId: initialCategoryId,
      initialAmount: initialAmount,
      initialNote: initialNote,
      initialDate: initialDate,
    ),
    maxHeightFactor: 0.95,
  );
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.existing,
    this.initialType,
    this.initialAccountId,
    this.initialCategoryId,
    this.initialAmount,
    this.initialNote,
    this.initialDate,
  });

  final Txn? existing;
  final String? initialType;
  final int? initialAccountId;
  final int? initialCategoryId;
  final int? initialAmount;
  final String? initialNote;
  final DateTime? initialDate;

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late String _type;
  late int _amount;
  late int _dateMs;
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;
  late String _paymentMethod;
  bool _includeInReports = true;
  String _recurring = 'one_time';

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = <String>[];
  String? _attachmentPath;
  bool _saving = false;
  bool _showAdvanced = false;
  String? _amountError;
  bool _duplicateWarningShown = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final settings = ref.read(settingsSnapshotProvider);
    _type = existing?.type ?? widget.initialType ?? settings.defaultTxnType;
    _amount = existing?.amount ?? widget.initialAmount ?? 0;
    _dateMs = existing?.date ??
        (widget.initialDate ?? DateTime.now()).millisecondsSinceEpoch;
    _accountId = existing?.accountId ??
        widget.initialAccountId ??
        settings.defaultAccountId;
    _toAccountId = existing?.toAccountId;
    _categoryId = existing?.categoryId ?? widget.initialCategoryId;
    _paymentMethod = existing?.paymentMethod ?? settings.defaultPaymentMethod;
    _includeInReports = existing?.includeInReports ?? true;
    _noteController.text = existing?.note ?? widget.initialNote ?? '';
    if (existing != null) {
      _tags.addAll(existing.tagNames);
      _attachmentPath = existing.attachmentPath;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  List<Account> _accounts() {
    final async = ref.watch(accountsProvider);
    return async.valueOrNull ?? const <Account>[];
  }

  List<Category> _categories() {
    final async = ref.watch(categoriesProvider);
    final all = async.valueOrNull ?? const <Category>[];
    return all.where((c) => c.type == (_type == kTypeIncome ? kTypeIncome : kTypeExpense)).toList();
  }

  String? _validate() {
    if (_amount <= 0) return 'Enter an amount greater than zero';
    if (_accountId == null) return 'Select an account';
    if (_type == kTypeTransfer) {
      if (_toAccountId == null) return 'Select the destination account';
      if (_toAccountId == _accountId) return 'Choose two different accounts';
    } else if (_categoryId == null) {
      return 'Select a category';
    }
    return null;
  }

  Future<void> _save({bool addAnother = false}) async {
    final error = _validate();
    if (error != null) {
      setState(() => _amountError = error);
      showSnack(context, error, error: true);
      return;
    }
    setState(() {
      _amountError = null;
      _saving = true;
    });

    final repo = ref.read(transactionRepositoryProvider);
    final draft = Txn(
      id: widget.existing?.id,
      type: _type,
      amount: _amount,
      date: _dateMs,
      accountId: _accountId!,
      toAccountId: _type == kTypeTransfer ? _toAccountId : null,
      categoryId: _type == kTypeTransfer ? null : _categoryId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      paymentMethod: _paymentMethod,
      includeInReports: _includeInReports,
    );

    if (widget.existing == null && !_duplicateWarningShown) {
      final duplicate = await repo.findDuplicate(draft);
      if (duplicate != null && mounted) {
        final proceed = await confirmAction(
          context,
          title: 'Possible duplicate',
          message:
              'A similar ${_type} of ${Fmt.money(_amount)} already exists for this account. Save anyway?',
          confirmLabel: 'Save anyway',
          destructive: false,
        );
        if (!proceed) {
          setState(() => _saving = false);
          return;
        }
        _duplicateWarningShown = true;
      }
    }

    try {
      int id;
      if (widget.existing == null) {
        id = await repo.create(draft, tags: _tags);
        if (_attachmentPath != null) {
          await repo.setAttachment(id, _attachmentPath);
        }
        if (_recurring != 'one_time') {
          await repo.saveRecurringRule(RecurringRule(
            frequency: _recurring,
            nextDate: nextOccurrence(
              DateTime.fromMillisecondsSinceEpoch(_dateMs),
              _recurring,
            ).millisecondsSinceEpoch,
            type: _type,
            amount: _amount,
            accountId: _accountId,
            categoryId: _categoryId,
            paymentMethod: _paymentMethod,
            note: draft.note,
          ));
        }
      } else {
        id = widget.existing!.id!;
        await repo.update(draft, tags: _tags);
        await repo.setAttachment(id, _attachmentPath);
      }

      await _refreshAchievements();
      if (!mounted) return;
      Navigator.of(context).pop(id);
      showSnack(context, widget.existing == null ? 'Transaction saved' : 'Transaction updated');

      if (addAnother) {
        // Re-open a fresh sheet for rapid entry.
        await showAddTransactionSheet(
          context,
          ref,
          initialType: _type,
          initialAccountId: _accountId,
          initialCategoryId: _categoryId,
          initialDate: DateTime.fromMillisecondsSinceEpoch(_dateMs),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Could not save: $error', error: true);
      }
    }
  }

  Future<void> _refreshAchievements() async {
    final repo = ref.read(transactionRepositoryProvider);
    final achievements = ref.read(achievementRepositoryProvider);
    final count = await repo.count();
    final days = await repo.transactionDays();
    await achievements.refresh(
      txnCount: count,
      streak: _streak(days),
      goalsCompleted: (ref.read(goalsProvider).valueOrNull ?? const <Goal>[])
          .where((g) => g.isCompleted)
          .length,
      savedPaise: ref.read(totalSavedProvider).valueOrNull ?? 0,
      budgetsCount: (ref.read(budgetsProvider).valueOrNull ?? <BudgetProgress>[]).length,
      reportsOpened: ref.read(settingsSnapshotProvider).reportsOpened,
      premiumTouched: ref.read(isPremiumProvider),
    );
  }

  int _streak(Set<String> days) {
    var streak = 0;
    var cursor = DateTime.now();
    while (true) {
      final key = '${cursor.year}-${cursor.month}-${cursor.day}';
      if (days.contains(key)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        // Allow today to be missing without breaking the streak.
        if (streak == 0 && DateTime.now().difference(cursor).inDays == 0) {
          cursor = cursor.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return streak;
  }

  void _applySmartNote(String value) {
    final history = ref.read(noteHistoryProvider).valueOrNull ?? const <String, String>{};
    final suggestion = SmartEngine.suggestCategoryName(value, history: history);
    if (suggestion == null) return;
    final match = _categories().where(
      (c) => c.name.toLowerCase() == suggestion.toLowerCase(),
    );
    if (match.isNotEmpty && _categoryId != match.first.id) {
      setState(() => _categoryId = match.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accounts = _accounts();
    final categories = _categories();

    if (_accountId == null && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: <Widget>[
          SheetHeader(
            title: widget.existing == null ? 'Add transaction' : 'Edit transaction',
            subtitle: widget.existing == null
                ? 'Log it in seconds — everything stays on this device.'
                : 'Update the details of this transaction.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                0,
                AppSpacing.x5,
                AppSpacing.x4,
              ),
              children: <Widget>[
                SegmentedControl<String>(
                  value: widget.existing != null ? widget.existing!.type : _type,
                  options: const <SegmentOption<String>>[
                    SegmentOption(value: kTypeExpense, label: 'Expense', icon: Icons.south_west_rounded),
                    SegmentOption(value: kTypeIncome, label: 'Income', icon: Icons.north_east_rounded),
                    SegmentOption(value: kTypeTransfer, label: 'Transfer', icon: Icons.swap_horiz_rounded),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value;
                    _categoryId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.x4),
                AmountField(
                  paise: _amount,
                  onChanged: (value) => setState(() {
                    _amount = value;
                    _amountError = null;
                  }),
                  error: _amountError,
                  autofocus: widget.existing == null,
                  accentColor: _type == kTypeIncome
                      ? palette.income
                      : _type == kTypeTransfer
                          ? palette.transfer
                          : palette.accent,
                ),
                const SizedBox(height: AppSpacing.x4),
                Text('Account', style: AppTextStyles.label(palette.sub)),
                const SizedBox(height: 8),
                if (accounts.isEmpty)
                  Text(
                    'Add an account first to record transactions.',
                    style: AppTextStyles.body(palette.expense),
                  )
                else
                  SizedBox(
                    height: 62,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final selected = account.id == _accountId;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _accountId = account.id;
                            if (_toAccountId == account.id) _toAccountId = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? palette.accent.withOpacity(0.1)
                                  : (palette.isDark ? palette.cardAlt : Colors.white),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: selected ? palette.accent : palette.divider,
                                width: selected ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                CategoryIcon(
                                  iconName: account.icon,
                                  color: selected ? palette.accent : palette.sub,
                                  size: 30,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      account.name,
                                      style: AppTextStyles.label(palette.ink)
                                          .copyWith(fontSize: 12),
                                    ),
                                    Text(
                                      Fmt.money(account.balance, forceCompact: true),
                                      style: AppTextStyles.caption(palette.tertiary)
                                          .copyWith(fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_type == kTypeTransfer) ...<Widget>[
                  const SizedBox(height: AppSpacing.x4),
                  Text('To account', style: AppTextStyles.label(palette.sub)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: accounts
                        .where((a) => a.id != _accountId)
                        .map((account) => AppChip(
                              label: account.name,
                              selected: _toAccountId == account.id,
                              onTap: () => setState(() => _toAccountId = account.id),
                              color: palette.transfer,
                            ))
                        .toList(),
                  ),
                ] else ...<Widget>[
                  const SizedBox(height: AppSpacing.x4),
                  CategorySelectorGrid(
                    categories: categories,
                    selectedId: _categoryId,
                    onSelected: (id) => setState(() => _categoryId = id),
                    onManage: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CategoryQuickManager(type: _type),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x4),
                DateField(
                  label: 'Date & time',
                  value: DateTime.fromMillisecondsSinceEpoch(_dateMs),
                  includeTime: true,
                  onChanged: (value) => setState(() => _dateMs = value.millisecondsSinceEpoch),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    AppChip(
                      label: 'Today',
                      selected: false,
                      onTap: () => setState(() => _dateMs = DateTime.now().millisecondsSinceEpoch),
                    ),
                    AppChip(
                      label: 'Yesterday',
                      selected: false,
                      onTap: () => setState(() => _dateMs =
                          DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
                AppTextField(
                  controller: _noteController,
                  label: 'Note',
                  hint: 'e.g. Zomato dinner with team',
                  prefixIcon: Icons.edit_note_rounded,
                  onChanged: _applySmartNote,
                ),
                const SizedBox(height: AppSpacing.x3),
                Text('Tags', style: AppTextStyles.label(palette.sub)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ..._tags.map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      ),
                    ),
                    ActionChip(
                      avatar: Icon(Icons.add_rounded, size: 16, color: palette.accent),
                      label: Text('Add tag', style: AppTextStyles.caption(palette.onSoft)),
                      onPressed: _addTagDialog,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
                Text('Payment method', style: AppTextStyles.label(palette.sub)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kPaymentMethods
                      .map((method) => AppChip(
                            label: method,
                            selected: _paymentMethod == method,
                            onTap: () => setState(() => _paymentMethod = method),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.x4),
                InkWell(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          _showAdvanced
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: palette.sub,
                        ),
                        const SizedBox(width: 6),
                        Text('More options', style: AppTextStyles.label(palette.sub)),
                      ],
                    ),
                  ),
                ),
                if (_showAdvanced) ...<Widget>[
                  Text('Repeat', style: AppTextStyles.label(palette.sub)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <String>[
                      'one_time',
                      'daily',
                      'weekly',
                      'monthly',
                      'yearly',
                    ].map((frequency) {
                      return AppChip(
                        label: frequencyLabel(frequency),
                        selected: _recurring == frequency,
                        onTap: () => setState(() => _recurring = frequency),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  SwitchRow(
                    title: 'Include in reports',
                    subtitle: 'Turn off for personal transfers you do not want counted',
                    value: _includeInReports,
                    onChanged: (value) => setState(() => _includeInReports = value),
                    icon: Icons.insights_rounded,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Row(
                    children: <Widget>[
                      SecondaryButton(
                        label: _attachmentPath == null ? 'Attach receipt' : 'Change receipt',
                        icon: Icons.photo_camera_rounded,
                        expanded: false,
                        height: 44,
                        onPressed: _pickAttachment,
                      ),
                      if (_attachmentPath != null) ...<Widget>[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() => _attachmentPath = null),
                          icon: Icon(Icons.delete_outline_rounded, color: palette.expense),
                        ),
                      ],
                    ],
                  ),
                  if (_attachmentPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.file(
                          File(_attachmentPath!),
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Text(
                            'Receipt not available',
                            style: AppTextStyles.caption(palette.tertiary),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.x3),
                ],
                const SizedBox(height: AppSpacing.x4),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x3,
              AppSpacing.x5,
              AppSpacing.x4 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: palette.card,
              border: Border(top: BorderSide(color: palette.divider)),
            ),
            child: Row(
              children: <Widget>[
                if (widget.existing == null)
                  Expanded(
                    child: SecondaryButton(
                      label: 'Save & add another',
                      onPressed: _saving ? null : () => _save(addAnother: true),
                    ),
                  ),
                if (widget.existing == null) const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: widget.existing == null ? 'Save' : 'Update',
                    loading: _saving,
                    onPressed: _saving ? null : () => _save(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTagDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add tag', style: context.h3),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. work, family, trip'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && !_tags.contains(result)) {
      setState(() => _tags.add(result.replaceAll('#', '')));
    }
  }

  Future<void> _pickAttachment() async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    if (fromCamera == null) return;
    try {
      final path = await ReceiptService.instance.pick(fromCamera: fromCamera);
      if (path != null && mounted) {
        setState(() => _attachmentPath = path);
      }
    } catch (error) {
      if (mounted) showSnack(context, 'Could not attach receipt: $error', error: true);
    }
  }
}

/// Lightweight category creator reachable from the add-transaction sheet.
class CategoryQuickManager extends ConsumerWidget {
  const CategoryQuickManager({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final filtered = categories.where((c) => c.type == type).toList();
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text('Manage categories')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: <Widget>[
          AppTextField(
            controller: controller,
            label: 'New ${type == kTypeIncome ? 'income' : 'expense'} category',
            hint: 'Category name',
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Add category',
            height: 46,
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              if (Validators.name(name) != null) return;
              await ref.read(categoryRepositoryProvider).create(
                    Category(name: name, type: type),
                  );
              controller.clear();
            },
          ),
          const SizedBox(height: AppSpacing.x5),
          ...filtered.map(
            (category) => ListTile(
              leading: CategoryIcon(iconName: category.icon, color: palette.accent),
              title: Text(category.name, style: AppTextStyles.body(palette.ink)),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: palette.expense, size: 20),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: 'Delete ${category.name}?',
                    message: 'Transactions in this category will become uncategorised.',
                  );
                  if (ok) {
                    await ref.read(categoryRepositoryProvider).delete(category.id!);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
