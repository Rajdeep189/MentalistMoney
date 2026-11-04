import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/progress_widgets.dart';
import 'account_detail_screen.dart';
import 'account_form_screen.dart';
import 'transfer_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final accountsAsync = ref.watch(allAccountsProvider);
    final totals = ref.watch(netWorthProvider).valueOrNull ??
        const <String, int>{'assets': 0, 'liabilities': 0};

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Transfer money',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TransferScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AccountFormScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (accounts) {
          final active = accounts.where((a) => !a.archived).toList();
          final archived = accounts.where((a) => a.archived).toList();
          if (active.isEmpty) {
            return EmptyState(
              title: 'No accounts yet',
              message: 'Add cash, bank accounts, cards or wallets to start tracking.',
              illustration: IllustrationKind.wallet,
              actionLabel: 'Add an account',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountFormScreen()),
              ),
            );
          }

          final groups = <String, List<Account>>{};
          for (final account in active) {
            groups.putIfAbsent(account.type, () => <Account>[]).add(account);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              _NetWorthHeader(
                assets: totals['assets'] ?? 0,
                liabilities: totals['liabilities'] ?? 0,
              ),
              const SizedBox(height: AppSpacing.x5),
              for (final entry in groups.entries) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    accountTypeLabel(entry.key).toUpperCase(),
                    style: context.overline,
                  ),
                ),
                ...entry.value.map(
                  (account) => AccountCard(
                    account: account,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountDetailScreen(accountId: account.id!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
              ],
              if (archived.isNotEmpty) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('ARCHIVED', style: context.overline),
                ),
                ...archived.map(
                  (account) => AccountCard(
                    account: account,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountDetailScreen(accountId: account.id!),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NetWorthHeader extends StatelessWidget {
  const _NetWorthHeader({required this.assets, required this.liabilities});

  final int assets;
  final int liabilities;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Net worth', style: AppTextStyles.label(palette.darkSub)),
          const SizedBox(height: 4),
          AmountText(assets - liabilities, size: 30, color: Colors.white,
              weight: FontWeight.w700),
          const SizedBox(height: AppSpacing.x4),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Assets', style: AppTextStyles.caption(palette.darkSub)),
                    const SizedBox(height: 2),
                    AmountText(assets, size: 15, color: palette.income),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: palette.darkDivider),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Liabilities', style: AppTextStyles.caption(palette.darkSub)),
                    const SizedBox(height: 2),
                    AmountText(liabilities, size: 15, color: palette.expense),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Credit cards get the premium dark treatment; other accounts use white cards.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account, this.onTap});

  final Account account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;

    if (account.type == kAccountCredit) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x3),
        child: DarkCard(
          onTap: onTap,
          accent: _parse(account.color),
          padding: const EdgeInsets.all(AppSpacing.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.credit_card_rounded, size: 18, color: palette.darkSub),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      account.name,
                      style: AppTextStyles.label(Colors.white),
                    ),
                  ),
                  if (account.archived)
                    Text('Archived', style: AppTextStyles.caption(palette.darkSub)),
                ],
              ),
              const SizedBox(height: AppSpacing.x4),
              AmountText(account.balance, size: 24, color: Colors.white,
                  weight: FontWeight.w700),
              const SizedBox(height: 4),
              Text(
                account.creditLimit == null
                    ? 'Outstanding balance'
                    : 'Outstanding · limit ${Fmt.money(account.creditLimit!, forceCompact: true)}',
                style: AppTextStyles.caption(palette.darkSub),
              ),
              if (account.creditLimit != null) ...<Widget>[
                const SizedBox(height: AppSpacing.x3),
                ProgressBar(
                  value: account.creditLimit == 0
                      ? 0
                      : (account.balance.abs() / account.creditLimit!),
                  color: _parse(account.color),
                  trackColor: palette.darkDivider,
                  height: 6,
                ),
                const SizedBox(height: 6),
                Text(
                  'Available ${Fmt.money(account.availableCredit, forceCompact: true)}',
                  style: AppTextStyles.caption(palette.darkSub),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            CategoryIcon(
              iconName: account.icon,
              color: _parse(account.color),
              size: 46,
              rounded: true,
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label(palette.ink),
                        ),
                      ),
                      if (account.archived) ...<Widget>[
                        const SizedBox(width: 6),
                        Text('· archived',
                            style: AppTextStyles.caption(palette.tertiary)
                                .copyWith(fontSize: 10)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accountTypeLabel(account.type),
                    style: AppTextStyles.caption(palette.tertiary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                AmountText(
                  account.balance,
                  size: 16,
                  color: account.balance < 0 ? palette.expense : palette.ink,
                  weight: FontWeight.w600,
                ),
                Text(
                  account.includeInNetWorth ? 'in net worth' : 'excluded',
                  style: AppTextStyles.caption(palette.tertiary).copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parse(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.tryParse(value, radix: 16) ?? 0xFF916CFF);
  }
}
