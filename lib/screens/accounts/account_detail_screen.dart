import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
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
        titleSpacing: 0,
        title: Text('Accounts', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Transfer',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TransferScreen(fromAccountId: accountId),
              ),
            ),
            icon: Icon(Icons.compare_arrows_rounded, color: palette.sub),
          ),
          IconButton(
            tooltip: 'Edit account',
            onPressed: () async {
              final account = accountAsync.valueOrNull;
              if (account == null) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AccountFormScreen(account: account),
                ),
              );
            },
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: palette.accent.withOpacity(0.25),
              child: Icon(Icons.person_rounded, size: 17, color: palette.accent),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (account) {
          if (account == null) {
            return const Center(child: Text('Account not found'));
          }
          return _AccountBody(account: account);
        },
      ),
    );
  }
}

class _AccountBody extends ConsumerStatefulWidget {
  const _AccountBody({required this.account});

  final Account account;

  @override
  ConsumerState<_AccountBody> createState() => _AccountBodyState();
}

class _AccountBodyState extends ConsumerState<_AccountBody> {
  late final PageController _controller =
      PageController(initialPage: _initialIndex);
  int _page = 0;

  int get _initialIndex {
    final accounts = ref.read(allAccountsProvider).valueOrNull ?? const <Account>[];
    final index = accounts.indexWhere((a) => a.id == widget.account.id);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _page = _initialIndex;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accounts =
        ref.watch(allAccountsProvider).valueOrNull ?? <Account>[widget.account];
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};
    final account = widget.account;

    return FutureBuilder<List<Txn>>(
      future: ref.read(transactionRepositoryProvider).query(
            TransactionFilter(accountIds: <int>[account.id!], sort: 'newest'),
          ),
      builder: (context, snapshot) {
        final txns = snapshot.data ?? const <Txn>[];
        final now = DateTime.now();
        var income = 0;
        var expense = 0;
        var prevIncome = 0;
        var prevExpense = 0;
        for (final txn in txns) {
          final date = DateTime.fromMillisecondsSinceEpoch(txn.date);
          final isThisMonth = date.year == now.year && date.month == now.month;
          final prev = DateTime(now.year, now.month - 1);
          final isPrevMonth = date.year == prev.year && date.month == prev.month;
          if (txn.type == kTypeIncome) {
            if (isThisMonth) income += txn.amount;
            if (isPrevMonth) prevIncome += txn.amount;
          } else if (txn.type == kTypeExpense) {
            if (isThisMonth) expense += txn.amount;
            if (isPrevMonth) prevExpense += txn.amount;
          }
        }
        final incomeDelta =
            prevIncome == 0 ? (income > 0 ? 100.0 : 0.0) : (income - prevIncome) / prevIncome * 100;
        final expenseDelta = prevExpense == 0
            ? (expense > 0 ? 100.0 : 0.0)
            : (expense - prevExpense) / prevExpense * 100;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            4,
            AppSpacing.screen,
            120,
          ),
          children: <Widget>[
            SizedBox(
              height: 226,
              child: PageView.builder(
                controller: _controller,
                itemCount: accounts.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) =>
                    _AccountHero(account: accounts[index]),
              ),
            ),
            if (accounts.length > 1) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (var i = 0; i < accounts.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 7,
                      width: 7,
                      decoration: BoxDecoration(
                        color:
                            i == _page ? palette.accent : palette.divider,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DeltaStatCard(
                        label: 'Income',
                        amount: income,
                        delta: incomeDelta,
                        income: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Compared to ${Fmt.money(prevIncome)} last month',
                        style: AppTextStyles.caption(palette.tertiary)
                            .copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DeltaStatCard(
                        label: 'Expense',
                        amount: expense,
                        delta: expenseDelta,
                        income: false,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Compared to ${Fmt.money(prevExpense)} last month',
                        style: AppTextStyles.caption(palette.tertiary)
                            .copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Transactions',
              style: AppTextStyles.serif(size: 19, color: AppColors.accentShift),
            ),
            const SizedBox(height: 10),
            if (txns.isEmpty)
              PaisaCard(
                child: Text(
                  'No transactions in this account yet.',
                  style: AppTextStyles.body(palette.tertiary),
                ),
              )
            else
              for (final txn in txns.take(20))
                PaisaTxnCard(
                  txn: txn,
                  category: categories[txn.categoryId],
                  accountName: account.name,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TransactionDetailScreen(transactionId: txn.id!),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: PeachButton(
                    label: 'Add',
                    icon: Icons.add_rounded,
                    height: 50,
                    onPressed: () => showAddTransactionSheet(
                      context,
                      ref,
                      initialAccountId: account.id,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TransferScreen(fromAccountId: account.id),
                        ),
                      ),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Transfer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.ink,
                        side: BorderSide(color: palette.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
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
              icon: Icon(Icons.delete_outline_rounded,
                  size: 16, color: palette.expense),
              label: Text(
                'Delete account',
                style: AppTextStyles.caption(palette.expense),
              ),
            ),
            TextButton.icon(
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
              icon: Icon(Icons.archive_outlined, size: 16, color: palette.sub),
              label: Text(
                account.archived ? 'Unarchive account' : 'Archive account',
                style: AppTextStyles.caption(palette.sub),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Large tinted account card: icon, name, digits chip, balance and badges.
class _AccountHero extends StatelessWidget {
  const _AccountHero({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tint = _tintFor(account.type);
    final digits = (account.id ?? 0).toString().padLeft(4, '0');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.isDark ? tint : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.divider.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF26B5B),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_iconFor(account.type),
                    size: 26, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.base(
                        size: 17,
                        weight: FontWeight.w700,
                        height: 1.15,
                      ).copyWith(color: palette.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      account.notes?.trim().isNotEmpty == true
                          ? account.notes!
                          : '${accountTypeLabel(account.type)} · ${account.currency}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(palette.sub)
                          .copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF26B5B).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  digits,
                  style: AppTextStyles.base(
                    size: 11,
                    weight: FontWeight.w600,
                    height: 1.1,
                  ).copyWith(color: const Color(0xFFF6877A)),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Total balance',
            style: AppTextStyles.caption(palette.sub).copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.money(account.balance),
              style: AppTextStyles.serif(
                size: 28,
                color: palette.isDark
                    ? const Color(0xFFF6877A)
                    : palette.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Spacer(),
              _HeroChip(label: accountTypeLabel(account.type).split(' ').first),
              if (account.creditLimit != null) ...<Widget>[
                const SizedBox(width: 6),
                _HeroChip(
                  label: Fmt.money(account.creditLimit!, forceCompact: true),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Color _tintFor(String type) {
    switch (type) {
      case kAccountCredit:
        return const Color(0xFF4A1F1C);
      case kAccountBank:
        return const Color(0xFF3B1D1A);
      case kAccountWallet:
        return const Color(0xFF23303B);
      case kAccountInvestment:
        return const Color(0xFF1C3A2B);
      default:
        return const Color(0xFF2A1F1B);
    }
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case kAccountBank:
        return Icons.account_balance_rounded;
      case kAccountCredit:
        return Icons.credit_card_rounded;
      case kAccountWallet:
        return Icons.wallet_rounded;
      case kAccountInvestment:
        return Icons.trending_up_rounded;
      case kAccountLoan:
        return Icons.request_quote_rounded;
      default:
        return Icons.calculate_rounded;
    }
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        label,
        style: AppTextStyles.base(
          size: 11,
          weight: FontWeight.w600,
          height: 1.1,
        ).copyWith(color: context.c.sub),
      ),
    );
  }
}
