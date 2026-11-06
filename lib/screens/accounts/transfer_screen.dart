import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key, this.fromAccountId});

  final int? fromAccountId;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  int? _fromId;
  int? _toId;
  int _amount = 0;
  int _fee = 0;
  late DateTime _date = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fromId = widget.fromAccountId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save(List<Account> accounts) async {
    if (_fromId == null || _toId == null) {
      showSnack(context, 'Choose both accounts', error: true);
      return;
    }
    if (_fromId == _toId) {
      showSnack(context, 'Choose two different accounts', error: true);
      return;
    }
    if (_amount <= 0) {
      showSnack(context, 'Enter an amount', error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(transactionRepositoryProvider);
    await repo.create(
      Txn(
        type: kTypeTransfer,
        amount: _amount,
        date: _date.millisecondsSinceEpoch,
        accountId: _fromId!,
        toAccountId: _toId,
        note: _noteController.text.trim().isEmpty ? 'Transfer' : _noteController.text.trim(),
        paymentMethod: 'Net Banking',
      ),
    );
    if (_fee > 0) {
      await repo.create(
        Txn(
          type: kTypeExpense,
          amount: _fee,
          date: _date.millisecondsSinceEpoch,
          accountId: _fromId!,
          note: 'Transfer fee',
          paymentMethod: 'Other',
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showSnack(context, 'Transfer completed');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final from = accounts.where((a) => a.id == _fromId).cast<Account?>().firstWhere(
          (a) => true,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('Transfer money')),
      body: accounts.length < 2
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.swap_horiz_rounded, size: 40, color: palette.accent),
                    const SizedBox(height: 12),
                    Text('You need at least two accounts to transfer',
                        textAlign: TextAlign.center, style: context.h3),
                    const SizedBox(height: 6),
                    Text('Add another account from the Accounts screen.',
                        textAlign: TextAlign.center, style: context.bodyMuted),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.x2,
                AppSpacing.screen,
                AppSpacing.x10,
              ),
              children: <Widget>[
                AmountField(
                  paise: _amount,
                  onChanged: (value) => setState(() => _amount = value),
                  label: 'Amount to transfer',
                  accentColor: palette.transfer,
                ),
                const SizedBox(height: AppSpacing.x5),
                Text('From', style: AppTextStyles.label(palette.sub)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: accounts
                      .map((account) => AppChip(
                            label: '${account.name} · ${Fmt.money(account.balance, forceCompact: true)}',
                            selected: _fromId == account.id,
                            onTap: () => setState(() {
                              _fromId = account.id;
                              if (_toId == account.id) _toId = null;
                            }),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.x5),
                Text('To', style: AppTextStyles.label(palette.sub)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: accounts
                      .where((account) => account.id != _fromId)
                      .map((account) => AppChip(
                            label: account.name,
                            selected: _toId == account.id,
                            onTap: () => setState(() => _toId = account.id),
                            color: palette.transfer,
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.x5),
                DateField(
                  label: 'Date',
                  value: _date,
                  onChanged: (value) => setState(() => _date = value),
                ),
                const SizedBox(height: AppSpacing.x4),
                AmountField(
                  paise: _fee,
                  onChanged: (value) => setState(() => _fee = value),
                  label: 'Fee (optional)',
                  showCalculator: false,
                ),
                const SizedBox(height: AppSpacing.x4),
                AppTextField(
                  controller: _noteController,
                  label: 'Note',
                  hint: 'e.g. Wallet top-up',
                ),
                if (from != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.x4),
                  Row(
                    children: <Widget>[
                      CategoryIcon(
                        iconName: from.icon,
                        color: palette.transfer,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Available in ${from.name}: ${Fmt.money(from.balance)}',
                        style: context.caption,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.x6),
                PrimaryButton(
                  label: 'Transfer',
                  icon: Icons.swap_horiz_rounded,
                  loading: _saving,
                  background: palette.transfer,
                  onPressed: _saving ? null : () => _save(accounts),
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  'Transfers move money between your accounts. They never count as income or expense.',
                  style: context.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}
