import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/fields.dart';
import '../../widgets/luxe_account_card.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.account});

  final Account? account;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.account?.name ?? '');
  late final TextEditingController _notesController =
      TextEditingController(text: widget.account?.notes ?? '');
  late String _type = widget.account?.type ?? kAccountCash;
  late String _icon = widget.account?.icon ?? 'wallet';
  late String _color = widget.account?.color ?? '#141418';
  late int _openingBalance = widget.account?.openingBalance ?? 0;
  late int? _creditLimit = widget.account?.creditLimit;
  late int? _statementDay = widget.account?.statementDay;
  late int? _dueDay = widget.account?.dueDay;
  late bool _includeInNetWorth = widget.account?.includeInNetWorth ?? true;
  late bool _archived = widget.account?.archived ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if ((_nameController.text.trim()).isEmpty) {
      showSnack(context, 'Give this account a name', error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(accountRepositoryProvider);
    final account = Account(
      id: widget.account?.id,
      name: _nameController.text.trim(),
      type: _type,
      icon: _icon,
      color: _color,
      openingBalance: _openingBalance,
      balance: widget.account?.balance ?? _openingBalance,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      includeInNetWorth: _includeInNetWorth,
      archived: _archived,
      creditLimit: _type == kAccountCredit ? _creditLimit : null,
      statementDay: _type == kAccountCredit ? _statementDay : null,
      dueDay: _type == kAccountCredit ? _dueDay : null,
      createdAt: widget.account?.createdAt ?? 0,
      updatedAt: widget.account?.updatedAt ?? 0,
    );

    if (widget.account == null) {
      await repo.create(account);
    } else {
      await repo.update(account);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showSnack(context, widget.account == null ? 'Account created' : 'Account updated');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final isCredit = _type == kAccountCredit;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(widget.account == null ? 'New account' : 'Edit account'),
        actions: <Widget>[
          if (widget.account != null)
            IconButton(
              tooltip: _archived ? 'Unarchive' : 'Archive',
              icon: Icon(_archived ? Icons.unarchive_rounded : Icons.archive_outlined),
              onPressed: () => setState(() => _archived = !_archived),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x2,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder: (context, value, _) {
              return LiveCardPreview(
                name: value.text,
                type: _type,
                hex: _color,
                balance: _openingBalance,
                creditLimit: _creditLimit,
              );
            },
          ),
          const SizedBox(height: AppSpacing.x4),
          AppTextField(
            controller: _nameController,
            label: 'Account name',
            hint: 'e.g. HDFC Savings',
            prefixIcon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 4),
          Text(
            'Your name appears on the card as you type.',
            style: AppTextStyles.caption(palette.tertiary)
                .copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('Account type', style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>[
              kAccountCash,
              kAccountBank,
              kAccountCredit,
              kAccountWallet,
              kAccountInvestment,
              kAccountLoan,
              kAccountCustom,
            ].map((type) {
              return AppChip(
                label: accountTypeLabel(type),
                selected: _type == type,
                onTap: () => setState(() => _type = type),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.x4),
          AmountField(
            paise: _openingBalance,
            onChanged: (value) => setState(() => _openingBalance = value),
            label: isCredit ? 'Outstanding balance' : 'Opening balance',
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('Icon', style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppIcons.accountIcons.map((icon) {
              final selected = _icon == icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = icon),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: selected ? palette.accent : palette.divider,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: CategoryIcon(
                    iconName: icon,
                    color: selected ? palette.accent : palette.sub,
                    size: 34,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.x4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder: (context, value, _) {
              return CardStylePicker(
                selectedHex: _color,
                holder: value.text,
                onSelected: (style) => setState(() => _color = style.hex),
              );
            },
          ),
          if (isCredit) ...<Widget>[
            const SizedBox(height: AppSpacing.x4),
            AmountField(
              paise: _creditLimit ?? 0,
              onChanged: (value) => setState(() => _creditLimit = value),
              label: 'Credit limit',
              showCalculator: false,
            ),
            const SizedBox(height: AppSpacing.x4),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppDropdown<int>(
                    label: 'Statement day',
                    items: List<int>.generate(28, (index) => index + 1),
                    value: _statementDay,
                    itemLabel: (item) => '$item',
                    onChanged: (value) => setState(() => _statementDay = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown<int>(
                    label: 'Payment due day',
                    items: List<int>.generate(28, (index) => index + 1),
                    value: _dueDay,
                    itemLabel: (item) => '$item',
                    onChanged: (value) => setState(() => _dueDay = value),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.x4),
          AppTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Optional',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.x3),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 4),
            child: Column(
              children: <Widget>[
                SwitchRow(
                  title: 'Include in net worth',
                  value: _includeInNetWorth,
                  onChanged: (value) => setState(() => _includeInNetWorth = value),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                Divider(color: palette.divider, height: 1),
                SwitchRow(
                  title: 'Archived',
                  subtitle: 'Hidden from pickers but keeps its history',
                  value: _archived,
                  onChanged: (value) => setState(() => _archived = value),
                  icon: Icons.archive_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: widget.account == null ? 'Create account' : 'Save changes',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          if (widget.account != null) ...<Widget>[
            const SizedBox(height: AppSpacing.x2),
            DestructiveButton(
              label: 'Delete account',
              icon: Icons.delete_outline_rounded,
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Delete "${widget.account!.name}"?',
                  message:
                      'All transactions in this account will be deleted and balances recalculated. This cannot be undone.',
                );
                if (!ok) return;
                await ref.read(accountRepositoryProvider).delete(widget.account!.id!);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}
