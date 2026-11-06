import 'dart:io';

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
import '../../widgets/app_sheets.dart';
import 'add_transaction_sheet.dart';

/// Opens the transaction detail panel as a draggable bottom sheet.
Future<void> showTransactionDetail(
  BuildContext context,
  int transactionId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, controller) => TransactionDetailScreen(
        transactionId: transactionId,
        scrollController: controller,
      ),
    ),
  );
}

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.scrollController,
  });

  final int transactionId;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final txnAsync = ref.watch(txnByIdProvider(transactionId));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(30),
      ),
      child: ColoredBox(
        color: palette.card,
        child: txnAsync.when(
          loading: () => const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 320,
            child: Center(child: Text('$error')),
          ),
          data: (txn) {
            if (txn == null) {
              return SizedBox(
                height: 320,
                child: Center(
                  child: Text(
                    'Transaction not found',
                    style: AppTextStyles.body(palette.sub),
                  ),
                ),
              );
            }
            final category =
                ref.watch(categoryLookupProvider).valueOrNull?[txn.categoryId];
            final account =
                ref.watch(accountLookupProvider).valueOrNull?[txn.accountId];
            final toAccount =
                ref.watch(accountLookupProvider).valueOrNull?[txn.toAccountId];
            final tone = txn.type == kTypeIncome
                ? palette.income
                : txn.type == kTypeTransfer
                    ? palette.transfer
                    : palette.expense;
            final icon = txn.type == kTypeTransfer
                ? Icons.swap_horiz_rounded
                : AppIcons.byName(category?.icon,
                    fallback: Icons.receipt_long_rounded);
            final tileTone = txn.type == kTypeTransfer
                ? const Color(0xFF5B6BF0)
                : txn.type == kTypeIncome
                    ? const Color(0xFF2FBF7A)
                    : AppColors.fromHex(category?.color ?? '#F6A126');
            final title = (txn.note?.trim().isNotEmpty == true)
                ? txn.note!.trim()
                : (category?.name ??
                    (txn.type == kTypeTransfer ? 'Transfer' : 'Transaction'));
            final created = txn.createdAt == 0 ? txn.date : txn.createdAt;

            return Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Flexible(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: <Widget>[
                      _HeaderRow(
                        icon: icon,
                        tileTone: tileTone,
                        title: title,
                        amount: Fmt.money(txn.amount),
                        tone: tone,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 68),
                        child: Text(
                          Fmt.dateTime(txn.date),
                          style: AppTextStyles.body(palette.sub)
                              .copyWith(fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: palette.divider.withOpacity(0.5),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Transaction Details',
                        style: AppTextStyles.base(
                          size: 20,
                          weight: FontWeight.w600,
                          height: 1.15,
                        ).copyWith(color: palette.accent),
                      ),
                      const SizedBox(height: 18),
                      _DetailItem(
                        icon: Icons.account_balance_rounded,
                        tone: AppColors.fromHex(account?.color ?? '#E8604C'),
                        label: 'Account',
                        value: account?.name ?? '—',
                      ),
                      if (txn.type == kTypeTransfer)
                        _DetailItem(
                          icon: Icons.arrow_forward_rounded,
                          tone: const Color(0xFF5B6BF0),
                          label: 'To account',
                          value: toAccount?.name ?? '—',
                        ),
                      _DetailItem(
                        icon: AppIcons.byName(category?.icon,
                            fallback: Icons.category_rounded),
                        tone: AppColors.fromHex(category?.color ?? '#C88A5A'),
                        label: 'Category',
                        value: category?.name ?? 'Uncategorised',
                      ),
                      if (txn.tagNames.isNotEmpty)
                        _DetailItem(
                          icon: Icons.sell_rounded,
                          tone: const Color(0xFF9B2FD0),
                          label: txn.tagNames.length == 1 ? 'Label' : 'Labels',
                          value: txn.tagNames
                              .map((tag) => '#$tag')
                              .join(', '),
                        ),
                      if (txn.recurringRuleId != null)
                        _DetailItem(
                          icon: Icons.event_repeat_rounded,
                          tone: const Color(0xFF2F9BF2),
                          label: 'Recurring',
                          value: 'Linked to a repeat rule',
                        ),
                      if (txn.loanAccountId != null)
                        _DetailItem(
                          icon: Icons.savings_rounded,
                          tone: const Color(0xFFF2407E),
                          label: 'Loan',
                          value: ref
                                  .watch(accountLookupProvider)
                                  .valueOrNull?[txn.loanAccountId]
                                  ?.name ??
                              'Linked loan',
                        ),
                      if (txn.place != null && txn.place!.isNotEmpty)
                        _DetailItem(
                          icon: Icons.place_rounded,
                          tone: const Color(0xFF00897B),
                          label: 'Place',
                          value: txn.place!,
                        ),
                      if (txn.payee != null && txn.payee!.isNotEmpty)
                        _DetailItem(
                          icon: Icons.person_rounded,
                          tone: const Color(0xFFE91E63),
                          label: 'Person',
                          value: txn.payee!,
                        ),
                      _DetailItem(
                        icon: Icons.credit_card_rounded,
                        tone: const Color(0xFF2FBF7A),
                        label: 'Payment method',
                        value: txn.paymentMethod,
                      ),
                      if (!txn.includeInReports)
                        _DetailItem(
                          icon: Icons.visibility_off_rounded,
                          tone: const Color(0xFFB0785A),
                          label: 'Reports',
                          value: 'Excluded from totals',
                        ),
                      if (txn.attachmentPath != null) ...<Widget>[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.file(
                            File(txn.attachmentPath!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Text(
                              'Receipt image not found',
                              style: AppTextStyles.caption(palette.tertiary),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Created on ${Fmt.date(created)}',
                        style: AppTextStyles.body(palette.tertiary)
                            .copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: palette.divider.withOpacity(0.5),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            tone: palette.expense,
                            onTap: () async {
                              final ok = await confirmAction(
                                context,
                                title: 'Delete transaction?',
                                message:
                                    'Account balances will be recalculated. This cannot be undone.',
                              );
                              if (!ok) return;
                              await ref
                                  .read(transactionRepositoryProvider)
                                  .delete(transactionId);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                showSnack(context, 'Transaction deleted');
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            tone: palette.accent,
                            onTap: () => showAddTransactionSheet(
                              context,
                              ref,
                              existing: txn,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.copy_rounded,
                            label: 'Copy',
                            tone: palette.accent,
                            onTap: () async {
                              await showAddTransactionSheet(
                                context,
                                ref,
                                initialType: txn.type,
                                initialAmount: txn.amount,
                                initialAccountId: txn.accountId,
                                initialCategoryId: txn.categoryId,
                                initialNote: txn.note,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.icon,
    required this.tileTone,
    required this.title,
    required this.amount,
    required this.tone,
  });

  final IconData icon;
  final Color tileTone;
  final String title;
  final String amount;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      children: <Widget>[
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: tileTone,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 27, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.base(
              size: 20,
              weight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: palette.ink),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          amount,
          style: AppTextStyles.base(
            size: 20,
            weight: FontWeight.w600,
            height: 1.1,
          ).copyWith(color: tone),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, valueAnim, child) => Opacity(
        opacity: valueAnim,
        child: Transform.translate(
          offset: Offset(0, (1 - valueAnim) * 10),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: AppTextStyles.base(
                      size: 15,
                      weight: FontWeight.w400,
                      height: 1.1,
                    ).copyWith(color: palette.sub),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 17,
                      weight: FontWeight.w600,
                      height: 1.25,
                    ).copyWith(color: palette.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 20, color: tone),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.base(
                size: 16,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: tone),
            ),
          ],
        ),
      ),
    );
  }
}
