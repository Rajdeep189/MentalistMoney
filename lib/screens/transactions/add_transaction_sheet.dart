import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../core/utils/smart_engine.dart';
import '../../core/utils/validators.dart';
import '../../data/models/models.dart';
import '../../data/repositories/place_repository.dart';
import '../../providers/app_providers.dart';
import '../../services/receipt_service.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';
import '../accounts/account_form_screen.dart';
import '../budgets/budget_form_screen.dart';

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
  int? _budgetId;
  int? _loanAccountId;
  String? _place;
  String? _payee;
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
    _budgetId = existing?.budgetId;
    _loanAccountId = existing?.loanAccountId;
    _place = existing?.place;
    _payee = existing?.payee;
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
      budgetId: _budgetId,
      loanAccountId: _loanAccountId,
      place: _place,
      payee: _payee,
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
    final budgets =
        ref.watch(budgetsProvider).valueOrNull ?? const <BudgetProgress>[];
    final loans = accounts.where((a) => a.loanKind != null).toList();

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
                    SegmentOption(value: kTypeExpense, label: 'Expense'),
                    SegmentOption(value: kTypeIncome, label: 'Income'),
                    SegmentOption(value: kTypeTransfer, label: 'Transfer'),
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
                _SectionHeaderRow(
                  icon: Icons.account_balance_wallet_outlined,
                  title: _type == kTypeTransfer ? 'From account' : 'Account',
                  subtitle: _selectedAccountName(accounts),
                  onAdd: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountFormScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final account in accounts)
                      _Pill(
                        label: account.name,
                        icon: AppIcons.byName(account.icon,
                            fallback: Icons.account_balance_rounded),
                        tone: AppColors.fromHex(account.color),
                        selected: account.id == _accountId,
                        onTap: () => setState(() {
                          _accountId = account.id;
                          if (_toAccountId == account.id) _toAccountId = null;
                        }),
                      ),
                  ],
                ),
                if (_type == kTypeTransfer) ...<Widget>[
                  const SizedBox(height: 16),
                  _SectionHeaderRow(
                    icon: Icons.arrow_forward_rounded,
                    title: 'To account',
                    subtitle: _toAccountId == null
                        ? 'Select account'
                        : accounts
                                .where((a) => a.id == _toAccountId)
                                .isEmpty
                            ? 'Select account'
                            : accounts
                                .firstWhere((a) => a.id == _toAccountId)
                                .name,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final account in accounts)
                        if (account.id != _accountId)
                          _Pill(
                            label: account.name,
                            icon: AppIcons.byName(account.icon,
                                fallback: Icons.account_balance_rounded),
                            tone: palette.transfer,
                            selected: _toAccountId == account.id,
                            onTap: () =>
                                setState(() => _toAccountId = account.id),
                          ),
                    ],
                  ),
                ] else ...<Widget>[
                  const SizedBox(height: 16),
                  _SectionHeaderRow(
                    icon: Icons.category_outlined,
                    title: 'Category',
                    subtitle: _categoryLabel(categories),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final category in categories)
                        _Pill(
                          label: category.name,
                          icon: AppIcons.byName(category.icon,
                              fallback: Icons.category_rounded),
                          tone: AppColors.fromHex(category.color),
                          selected: category.id == _categoryId,
                          onTap: () =>
                              setState(() => _categoryId = category.id),
                        ),
                      _Pill(
                        label: 'Add',
                        icon: Icons.add_circle_outline_rounded,
                        tone: palette.accent,
                        selected: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CategoryQuickManager(type: _type),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionHeaderRow(
                    icon: Icons.savings_outlined,
                    title: 'Budget',
                    subtitle: _budgetLabel(),
                    onAdd: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BudgetFormScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final budget in budgets.take(6))
                        _Pill(
                          label: budget.budget.name,
                          icon: AppIcons.byName(budget.budget.icon,
                              fallback: Icons.savings_rounded),
                          tone: AppColors.fromHex(budget.budget.color),
                          selected: budget.budget.id == _budgetId,
                          onTap: () => setState(() => _budgetId =
                              _budgetId == budget.budget.id
                                  ? null
                                  : budget.budget.id),
                        ),
                      _Pill(
                        label: 'Add',
                        icon: Icons.add_circle_outline_rounded,
                        tone: palette.accent,
                        selected: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const BudgetFormScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                _ExpanderRow(
                  icon: Icons.sell_outlined,
                  title: 'Label',
                  subtitle: _tags.isEmpty
                      ? 'Select label'
                      : _tags.map((tag) => '#$tag').join(', '),
                  onTap: _addTagDialog,
                ),
                if (_type != kTypeTransfer)
                  _ExpanderRow(
                    icon: Icons.credit_card_rounded,
                    title: 'Loan',
                    subtitle: _loanLabel(loans),
                    onTap: () => _pickLoan(loans),
                  ),
                _ExpanderRow(
                  icon: Icons.place_outlined,
                  title: 'Place',
                  subtitle: _place ?? 'Select a place',
                  onTap: () => _pickEntity(isPlace: true),
                ),
                _ExpanderRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Payee',
                  subtitle: _payee ?? 'Select a person',
                  onTap: () => _pickEntity(isPlace: false),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Text(
                      'Receipt or Bill (optional)',
                      style: AppTextStyles.base(
                        size: 15,
                        weight: FontWeight.w500,
                        height: 1.2,
                      ).copyWith(color: palette.sub),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.lock_outline_rounded,
                        size: 14, color: palette.tertiary),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickAttachment,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? Colors.white.withOpacity(0.03)
                          : palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: palette.divider.withOpacity(0.6),
                      ),
                    ),
                    child: _attachmentPath == null
                        ? Column(
                            children: <Widget>[
                              Icon(Icons.photo_camera_outlined,
                                  size: 30, color: palette.tertiary),
                              const SizedBox(height: 8),
                              Text(
                                'Add Receipt or Bill',
                                style: AppTextStyles.base(
                                  size: 15.5,
                                  weight: FontWeight.w600,
                                  height: 1.2,
                                ).copyWith(color: palette.accent),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to select an image',
                                style: AppTextStyles.base(
                                  size: 13.5,
                                  weight: FontWeight.w400,
                                  height: 1.2,
                                ).copyWith(color: palette.sub),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_attachmentPath!),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Text(
                                'Receipt not available',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption(palette.tertiary),
                              ),
                            ),
                          ),
                  ),
                ),
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
                  if (_attachmentPath != null)
                    Row(
                      children: <Widget>[
                        SecondaryButton(
                          label: 'Remove receipt',
                          icon: Icons.delete_outline_rounded,
                          expanded: false,
                          height: 44,
                          onPressed: () =>
                              setState(() => _attachmentPath = null),
                        ),
                      ],
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
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _save(),
                      icon: const Icon(Icons.receipt_long_rounded, size: 20),
                      label: Text(
                        widget.existing == null
                            ? 'Add transaction'
                            : 'Update transaction',
                        style: AppTextStyles.base(
                          size: 16.5,
                          weight: FontWeight.w700,
                          height: 1.1,
                        ).copyWith(color: AppColors.espresso),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: AppColors.espresso,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _showQuickActions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: AppColors.espresso,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Icon(
                      _showAdvanced
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _selectedAccountName(List<Account> accounts) {
    for (final account in accounts) {
      if (account.id == _accountId) return account.name;
    }
    return 'Select account';
  }

  String _categoryLabel(List<Category> categories) {
    if (_categoryId == null) return 'Select a category';
    for (final category in categories) {
      if (category.id == _categoryId) return category.name;
    }
    return 'Select a category';
  }

  String _budgetLabel() {
    if (_budgetId == null) return 'Select a budget';
    final budgets = ref.read(budgetsProvider).valueOrNull ??
        const <BudgetProgress>[];
    for (final budget in budgets) {
      if (budget.budget.id == _budgetId) return budget.budget.name;
    }
    return 'Select a budget';
  }

  String _loanLabel(List<Account> loans) {
    if (_loanAccountId == null) return 'Select Loan';
    for (final loan in loans) {
      if (loan.id == _loanAccountId) return loan.name;
    }
    return 'Select Loan';
  }

  Future<void> _pickLoan(List<Account> loans) async {
    final choice = await showAppSheet<int?>(
      context,
      (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          18 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Link a loan',
              style: AppTextStyles.base(
                size: 22,
                weight: FontWeight.w700,
                height: 1.2,
              ).copyWith(color: sheetContext.c.ink),
            ),
            const SizedBox(height: 12),
            if (loans.isEmpty)
              Text(
                'Create a loan from the Loans screen first.',
                style: AppTextStyles.body(sheetContext.c.sub),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final loan in loans)
                    _Pill(
                      label: loan.name,
                      icon: Icons.savings_rounded,
                      tone: const Color(0xFFF2407E),
                      selected: loan.id == _loanAccountId,
                      onTap: () => Navigator.of(sheetContext).pop(loan.id),
                    ),
                  _Pill(
                    label: 'None',
                    icon: Icons.close_rounded,
                    tone: sheetContext.c.sub,
                    selected: _loanAccountId == null,
                    onTap: () => Navigator.of(sheetContext).pop(-1),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    setState(() => _loanAccountId = choice == -1 ? null : choice);
  }

  Future<void> _pickEntity({required bool isPlace}) async {
    final entries = (isPlace
            ? ref.read(placesProvider).valueOrNull
            : ref.read(peopleProvider).valueOrNull) ??
        const <TagEntityStat>[];
    final controller = TextEditingController(
      text: (isPlace ? _place : _payee) ?? '',
    );
    final choice = await showAppSheet<String>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            18 + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                isPlace ? 'Select a place' : 'Select a person',
                style: AppTextStyles.base(
                  size: 22,
                  weight: FontWeight.w700,
                  height: 1.2,
                ).copyWith(color: sheetContext.c.ink),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final entry in entries)
                    _Pill(
                      label: entry.name,
                      icon: isPlace ? Icons.place_rounded : Icons.person_rounded,
                      tone: AppColors.fromHex(entry.color),
                      selected: (isPlace ? _place : _payee) == entry.name,
                      onTap: () => Navigator.of(sheetContext).pop(entry.name),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: controller,
                label: isPlace ? 'New place' : 'New person',
                hint: isPlace ? 'e.g. Home, Office' : 'e.g. Alice',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    final repo = ref.read(placeRepositoryProvider);
                    try {
                      if (isPlace) {
                        await repo.createPlace(name: name);
                      } else {
                        await repo.createPerson(name: name);
                      }
                    } catch (_) {}
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop(name);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sheetContext.c.accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Use this ${isPlace ? 'place' : 'person'}',
                    style: AppTextStyles.base(
                      size: 15.5,
                      weight: FontWeight.w700,
                      height: 1.1,
                    ).copyWith(color: AppColors.espresso),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;
    setState(() {
      if (isPlace) {
        _place = choice;
      } else {
        _payee = choice;
      }
    });
  }

  Future<void> _showQuickActions() async {
    final choice = await showAppSheet<String>(
      context,
      (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          16 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.playlist_add_rounded,
                  color: sheetContext.c.accent),
              title: Text(
                'Save & add another',
                style: AppTextStyles.body(sheetContext.c.ink),
              ),
              onTap: () => Navigator.of(sheetContext).pop('another'),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_rounded,
                  color: sheetContext.c.accent),
              title: Text(
                _attachmentPath == null
                    ? 'Attach receipt'
                    : 'Change receipt',
                style: AppTextStyles.body(sheetContext.c.ink),
              ),
              onTap: () => Navigator.of(sheetContext).pop('receipt'),
            ),
            ListTile(
              leading: Icon(Icons.tune_rounded, color: sheetContext.c.accent),
              title: Text(
                _showAdvanced ? 'Hide more options' : 'Show more options',
                style: AppTextStyles.body(sheetContext.c.ink),
              ),
              onTap: () => Navigator.of(sheetContext).pop('advanced'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'another') {
      await _save(addAnother: true);
    } else if (choice == 'receipt') {
      await _pickAttachment();
    } else if (choice == 'advanced') {
      setState(() => _showAdvanced = !_showAdvanced);
    }
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

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAdd,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      children: <Widget>[
        Icon(icon, size: 24, color: palette.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: AppTextStyles.base(
                  size: 18,
                  weight: FontWeight.w500,
                  height: 1.15,
                ).copyWith(color: palette.ink),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.base(
                  size: 15,
                  weight: FontWeight.w400,
                  height: 1.2,
                ).copyWith(color: palette.accent),
              ),
            ],
          ),
        ),
        if (onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: Icon(Icons.add_rounded, size: 22, color: palette.accent),
          )
        else
          Icon(Icons.keyboard_arrow_up_rounded,
              size: 22, color: palette.accent),
      ],
    );
  }
}

class _ExpanderRow extends StatelessWidget {
  const _ExpanderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: palette.divider.withOpacity(0.35)),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 24, color: palette.ink.withOpacity(0.85)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.base(
                      size: 18,
                      weight: FontWeight.w500,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 15,
                      weight: FontWeight.w400,
                      height: 1.2,
                    ).copyWith(color: palette.sub),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 24, color: palette.sub),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? tone.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? tone : palette.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: tone),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTextStyles.base(
                size: 15,
                weight: FontWeight.w500,
                height: 1.1,
              ).copyWith(color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}
