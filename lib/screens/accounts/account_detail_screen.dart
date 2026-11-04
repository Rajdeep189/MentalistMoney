import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_detail_screen.dart';
import 'account_form_screen.dart';
import 'transfer_screen.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final accountAsync = ref.watch(accountByIdProvider(accountId));

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Account'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final account = accountAsync.valueOrNull;
              if (account == null) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AccountFormScreen(account: account),
                ),
              );
            },
          ),
        ],
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (account) {
          if (account == null) return const Center(child: Text('Account not found'));
          return _AccountBody(account: account);
        },
      ),
    );
  }
}

class _AccountBody extends ConsumerWidget {
  const _AccountBody({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};

    return FutureBuilder<List<Txn>>(
      future: ref.read(transactionRepositoryProvider).query(
            TransactionFilter(accountIds: <int>[account.id!], sort: 'newest'),
          ),
      builder: (context, snapshot) {
        final txns = snapshot.data ?? const <Txn>[];
        var income = 0;
        var expense = 0;
        for (final txn in txns) {
          if (txn.type == kTypeIncome && txn.accountId == account.id) {
            income += txn.amount;
          } else if (txn.type == kTypeExpense) {
            expense += txn.amount;
          }
        }

        final monthly = <int>[0, 0, 0, 0, 0, 0];
        for (final txn in txns) {
          if (txn.type != kTypeExpense) continue;
          final date = DateTime.fromMillisecondsSinceEpoch(txn.date);
          final diff = (DateTime.now().year - date.year) * 12 +
              (DateTime.now().month - date.month);
          if (diff >= 0 && diff < 6) {
            monthly[5 - diff] += txn.amount;
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.x2,
            AppSpacing.screen,
            AppSpacing.x10,
          ),
          children: <Widget>[
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(account.name, style: context.h2),
                  Text(
                    '${accountTypeLabel(account.type)} · ${account.currency}',
                    style: context.caption,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  AmountText(account.balance, size: 30, weight: FontWeight.w700),
                  if (account.type == kAccountCredit && account.creditLimit != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.x3),
                    ProgressBar(
                      value: account.creditLimit == 0
                          ? 0
                          : account.balance.abs() / account.creditLimit!,
                      height: 7,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Available credit ${Fmt.money(account.availableCredit)}',
                      style: context.caption,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.cardGap),
            Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    label: 'Money in',
                    amount: income,
                    type: kTypeIncome,
                    icon: Icons.south_west_rounded,
                    dense: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: StatCard(
                    label: 'Money out',
                    amount: expense,
                    type: kTypeExpense,
                    icon: Icons.north_east_rounded,
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x5),
            Row(
              children: <Widget>[
                Expanded(
                  child: PrimaryButton(
                    label: 'Add',
                    icon: Icons.add_rounded,
                    height: 48,
                    onPressed: () => showAddTransactionSheet(
                      context,
                      ref,
                      initialAccountId: account.id,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Transfer',
                    icon: Icons.swap_horiz_rounded,
                    height: 48,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TransferScreen(fromAccountId: account.id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x5),
            ChartCard(
              title: 'Monthly spending',
              subtitle: 'Last 6 months',
              child: SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthly.map((value) {
                    final maxValue = monthly.reduce((a, b) => a > b ? a : b);
                    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              Fmt.money(value, withSymbol: false, forceCompact: true),
                              style: AppTextStyles.caption(palette.tertiary)
                                  .copyWith(fontSize: 9),
                            ),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: ratio),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, animated, _) => Container(
                                height: 70 * animated,
                                decoration: BoxDecoration(
                                  color: palette.accent.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            SectionHeader(title: 'Transactions (${txns.length})', padding: EdgeInsets.zero),
            if (txns.isEmpty)
              AppCard(child: Text('No transactions in this account yet.', style: context.bodyMuted))
            else
              AppCard(
                child: Column(
                  children: txns
                      .take(25)
                      .map(
                        (txn) => TransactionTile(
                          txn: txn,
                          category: categories[txn.categoryId],
                          accountName: account.name,
                          showDate: true,
                          dense: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  TransactionDetailScreen(transactionId: txn.id!),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: AppSpacing.x5),
            Row(
              children: <Widget>[
                Expanded(
                  child: SecondaryButton(
                    label: account.archived ? 'Unarchive' : 'Archive',
                    icon: Icons.archive_outlined,
                    height: 46,
                    onPressed: () async {
                      await ref
                          .read(accountRepositoryProvider)
                          .setArchived(account.id!, !account.archived);
                      if (context.mounted) {
                        showSnack(
                          context,
                          account.archived ? 'Account unarchived' : 'Account archived',
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DestructiveButton(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    onPressed: () async {
                      final ok = await confirmAction(
                        context,
                        title: 'Delete "${account.name}"?',
                        message: 'Every transaction in this account will be removed.',
                      );
                      if (!ok) return;
                      await ref.read(accountRepositoryProvider).delete(account.id!);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
