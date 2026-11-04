import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import 'add_transaction_sheet.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final txnAsync = ref.watch(txnByIdProvider(transactionId));

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share receipt',
            onPressed: () async {
              final txn = txnAsync.valueOrNull;
              if (txn == null) return;
              final category =
                  ref.read(categoryLookupProvider).valueOrNull?[txn.categoryId];
              final account =
                  ref.read(accountLookupProvider).valueOrNull?[txn.accountId];
              await Share.share(
                'MoneyMan receipt\n${category?.name ?? txn.type}\n${Fmt.money(txn.amount)}\n'
                '${Fmt.dateTime(txn.date)}\nAccount: ${account?.name ?? '-'}\n'
                '${txn.note ?? ''}',
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final txn = txnAsync.valueOrNull;
              if (txn == null) return;
              switch (value) {
                case 'duplicate':
                  await showAddTransactionSheet(
                    context,
                    ref,
                    initialType: txn.type,
                    initialAmount: txn.amount,
                    initialAccountId: txn.accountId,
                    initialCategoryId: txn.categoryId,
                    initialNote: txn.note,
                  );
                  break;
                case 'recurring':
                  await _createRecurring(context, ref, txn);
                  break;
                case 'delete':
                  final ok = await confirmAction(
                    context,
                    title: 'Delete transaction?',
                    message: 'Account balances will be recalculated.',
                  );
                  if (ok) {
                    await ref.read(transactionRepositoryProvider).delete(transactionId);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      showSnack(context, 'Transaction deleted');
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'duplicate', child: Text('Duplicate')),
              PopupMenuItem<String>(value: 'recurring', child: Text('Create recurring rule')),
              PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: txnAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (txn) {
          if (txn == null) {
            return const Center(child: Text('Transaction not found'));
          }
          final category = ref.watch(categoryLookupProvider).valueOrNull?[txn.categoryId];
          final account = ref.watch(accountLookupProvider).valueOrNull?[txn.accountId];
          final toAccount = ref.watch(accountLookupProvider).valueOrNull?[txn.toAccountId];
          final tone = txn.type == kTypeIncome
              ? palette.income
              : txn.type == kTypeTransfer
                  ? palette.transfer
                  : palette.expense;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: <Widget>[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.x5),
                child: Column(
                  children: <Widget>[
                    CategoryIcon(
                      icon: txn.type == kTypeTransfer
                          ? Icons.swap_horiz_rounded
                          : null,
                      iconName: txn.type == kTypeTransfer ? null : category?.icon,
                      color: tone,
                      size: 56,
                      rounded: true,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      '${txn.type == kTypeIncome ? '+' : txn.type == kTypeExpense ? '-' : ''}${Fmt.money(txn.amount)}',
                      style: AppTextStyles.money(32, color: tone, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      txn.note?.trim().isNotEmpty == true
                          ? txn.note!.trim()
                          : (category?.name ?? 'Transfer'),
                      style: context.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tone.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        txn.type == kTypeIncome
                            ? 'Income'
                            : txn.type == kTypeTransfer
                                ? 'Transfer'
                                : 'Expense',
                        style: AppTextStyles.caption(tone),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              AppCard(
                child: Column(
                  children: <Widget>[
                    _DetailRow(label: 'Category', value: category?.name ?? '—', icon: Icons.category_outlined),
                    _DetailRow(
                      label: 'Account',
                      value: account?.name ?? '—',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    if (txn.type == kTypeTransfer)
                      _DetailRow(
                        label: 'To account',
                        value: toAccount?.name ?? '—',
                        icon: Icons.arrow_forward_rounded,
                      ),
                    _DetailRow(
                      label: 'Date & time',
                      value: Fmt.dateTime(txn.date),
                      icon: Icons.schedule_rounded,
                    ),
                    _DetailRow(
                      label: 'Payment method',
                      value: txn.paymentMethod,
                      icon: Icons.credit_card_outlined,
                    ),
                    _DetailRow(
                      label: 'In reports',
                      value: txn.includeInReports ? 'Yes' : 'Excluded',
                      icon: Icons.insights_outlined,
                    ),
                    if (txn.tagNames.isNotEmpty)
                      _DetailRow(
                        label: 'Tags',
                        value: txn.tagNames.map((t) => '#$t').join('  '),
                        icon: Icons.sell_outlined,
                      ),
                    if (txn.recurringRuleId != null)
                      const _DetailRow(
                        label: 'Recurring',
                        value: 'Linked to a repeat rule',
                        icon: Icons.autorenew_rounded,
                      ),
                    _DetailRow(
                      label: 'Created',
                      value: Fmt.dateTime(txn.createdAt == 0 ? txn.date : txn.createdAt),
                      icon: Icons.history_rounded,
                    ),
                  ],
                ),
              ),
              if (txn.attachmentPath != null) ...<Widget>[
                const SizedBox(height: AppSpacing.cardGap),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Receipt', style: context.h3),
                      const SizedBox(height: AppSpacing.x2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.file(
                          File(txn.attachmentPath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Text(
                            'Receipt image not found',
                            style: context.caption,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x6),
              PrimaryButton(
                label: 'Edit transaction',
                icon: Icons.edit_rounded,
                onPressed: () => showAddTransactionSheet(context, ref, existing: txn),
              ),
              const SizedBox(height: AppSpacing.x2),
              DestructiveButton(
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: 'Delete transaction?',
                    message: 'Account balances will be recalculated. This cannot be undone.',
                  );
                  if (!ok) return;
                  await ref.read(transactionRepositoryProvider).delete(transactionId);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    showSnack(context, 'Transaction deleted');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createRecurring(BuildContext context, WidgetRef ref, Txn txn) async {
    final frequency = await showAppSelectionSheet<String>(
      context,
      items: const <String>['daily', 'weekly', 'monthly', 'yearly'],
      labelOf: (item) => frequencyLabel(item),
      title: 'Repeat this transaction',
    );
    if (frequency == null) return;
    await ref.read(transactionRepositoryProvider).saveRecurringRule(
          RecurringRule(
            frequency: frequency,
            nextDate: nextOccurrence(
              DateTime.fromMillisecondsSinceEpoch(txn.date),
              frequency,
            ).millisecondsSinceEpoch,
            type: txn.type,
            amount: txn.amount,
            accountId: txn.accountId,
            categoryId: txn.categoryId,
            paymentMethod: txn.paymentMethod,
            note: txn.note,
          ),
        );
    if (context.mounted) {
      showSnack(context, 'Repeats ${frequencyLabel(frequency).toLowerCase()} from now');
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 17, color: palette.tertiary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.body(palette.sub))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.label(palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}
