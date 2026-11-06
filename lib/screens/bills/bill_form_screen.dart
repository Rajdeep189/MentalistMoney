import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';

class BillFormScreen extends ConsumerStatefulWidget {
  const BillFormScreen({super.key, this.bill});

  final Bill? bill;

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.bill?.name ?? '');
  late final TextEditingController _notesController =
      TextEditingController(text: widget.bill?.notes ?? '');
  late int _amount = widget.bill?.amount ?? 0;
  late DateTime _dueDate = widget.bill?.dueDate == null
      ? DateTime.now().add(const Duration(days: 7))
      : DateTime.fromMillisecondsSinceEpoch(widget.bill!.dueDate);
  late String _frequency = widget.bill?.frequency ?? 'monthly';
  int? _accountId;
  int? _categoryId;
  late bool _autoCreate = widget.bill?.autoCreateTxn ?? true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final accounts = ref.read(accountsProvider).valueOrNull ?? const <Account>[];
    _accountId = widget.bill?.accountId ??
        (accounts.isEmpty ? null : accounts.first.id);
    _categoryId = widget.bill?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showSnack(context, 'Give this bill a name', error: true);
      return;
    }
    if (_amount <= 0) {
      showSnack(context, 'Enter the bill amount', error: true);
      return;
    }
    setState(() => _saving = true);
    final bill = Bill(
      id: widget.bill?.id,
      name: _nameController.text.trim(),
      amount: _amount,
      dueDate: _dueDate.millisecondsSinceEpoch,
      frequency: _frequency,
      accountId: _accountId,
      categoryId: _categoryId,
      autoCreateTxn: _autoCreate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: widget.bill?.status ?? kBillUpcoming,
      lastPaidAt: widget.bill?.lastPaidAt,
    );

    final repo = ref.read(billRepositoryProvider);
    var savedId = bill.id;
    if (widget.bill == null) {
      savedId = await repo.create(bill);
    } else {
      await repo.update(bill);
    }

    // Schedule local reminders (1 day before + on the due date).
    final settings = ref.read(settingsSnapshotProvider);
    if (settings.billReminders && settings.notificationsEnabled && savedId != null) {
      await NotificationService.instance.scheduleBillReminder(
        billId: savedId % 90000,
        name: bill.name,
        amountText: bill.amount / 100,
        dueDate: _dueDate,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showSnack(context, widget.bill == null ? 'Bill added' : 'Bill updated');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: Text(widget.bill == null ? 'New bill' : 'Edit bill')),
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
            label: 'Bill name',
            hint: 'e.g. Electricity bill',
            prefixIcon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: AppSpacing.x4),
          AmountField(
            paise: _amount,
            onChanged: (value) => setState(() => _amount = value),
            label: 'Amount',
          ),
          const SizedBox(height: AppSpacing.x4),
          DateField(
            label: 'Due date',
            value: _dueDate,
            onChanged: (value) => setState(() => _dueDate = value),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('Frequency', style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>[
              'one_time',
              'weekly',
              'monthly',
              'quarterly',
              'yearly',
            ].map((frequency) {
              return AppChip(
                label: frequencyLabel(frequency),
                selected: _frequency == frequency,
                onTap: () => setState(() => _frequency = frequency),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppDropdown<Account>(
            label: 'Pay from',
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
            label: 'Category',
            items: categories.where((c) => c.type == kTypeExpense).toList(),
            value: categories
                .where((c) => c.id == _categoryId)
                .cast<Category?>()
                .firstWhere((c) => true, orElse: () => null),
            itemLabel: (item) => item.name,
            onChanged: (item) => setState(() => _categoryId = item.id),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 4),
            child: Column(
              children: <Widget>[
                SwitchRow(
                  title: 'Create transaction when paid',
                  subtitle: 'Keeps account balances in sync',
                  value: _autoCreate,
                  onChanged: (value) => setState(() => _autoCreate = value),
                  icon: Icons.sync_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Optional',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: <Widget>[
              Icon(Icons.notifications_active_outlined, size: 15, color: palette.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Reminders are scheduled 1 day before and on the due date at 9:00 AM.',
                  style: context.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: widget.bill == null ? 'Add bill' : 'Save changes',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          if (widget.bill != null) ...<Widget>[
            const SizedBox(height: AppSpacing.x2),
            DestructiveButton(
              label: 'Delete bill',
              icon: Icons.delete_outline_rounded,
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Delete this bill?',
                  message: 'Transactions already created by this bill stay in your ledger.',
                );
                if (!ok) return;
                await ref.read(billRepositoryProvider).delete(widget.bill!.id!);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}
