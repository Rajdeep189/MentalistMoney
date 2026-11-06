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
import '../../widgets/luxe.dart';
import '../../widgets/luxe_account_card.dart';
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
        titleSpacing: 0,
        title: Text('Accounts', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Transfer money',
            icon: Icon(Icons.swap_horiz_rounded, color: palette.sub),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TransferScreen()),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AccountFormScreen()),
            ),
            icon: Icon(Icons.add_circle_outline_rounded,
                color: palette.onSoft),
          ),
          const SizedBox(width: 6),
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
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Row(
                    children: <Widget>[
                      Text(
                        accountTypeLabel(entry.key),
                        style: AppTextStyles.serif(size: 17, color: palette.ink),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value.length.toString().padLeft(2, '0')}',
                        style: AppTextStyles.caption(palette.tertiary)
                            .copyWith(fontSize: 10),
                      ),
                    ],
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
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Text('Archived',
                      style: AppTextStyles.serif(size: 17, color: palette.ink)),
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
    final fg = palette.isDark ? Colors.white : const Color(0xFF3A1B0E);
    final soft = fg.withOpacity(0.72);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? const <Color>[Color(0xFF6E3E28), Color(0xFF4A2618)]
              : const <Color>[Color(0xFFFFD9C6), Color(0xFFFFC1A5)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Net worth',
            style: AppTextStyles.base(
              size: 14,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: soft),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.money(assets - liabilities),
              style: AppTextStyles.serif(size: 32, color: fg),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _NetStat(
                  label: 'Assets',
                  value: assets,
                  color: fg,
                  soft: soft,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              Expanded(
                child: _NetStat(
                  label: 'Liabilities',
                  value: liabilities,
                  color: fg,
                  soft: soft,
                  icon: Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetStat extends StatelessWidget {
  const _NetStat({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final Color soft;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 13, color: soft),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption(soft).copyWith(fontSize: 11.5),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Fmt.money(value, forceCompact: true),
            style: AppTextStyles.serif(size: 17, color: color),
          ),
        ),
      ],
    );
  }
}

/// Every account renders as a real payment-card surface: credit cards get a
/// network badge and expiry, banks read as debit cards, cash as a currency
/// card and wallets as metal.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account, this.onTap});

  final Account account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tint = AppColors.categoryPalette[
        (account.type.hashCode.abs() % AppColors.categoryPalette.length)];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: palette.divider.withOpacity(0.7)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: tint.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                accountIcon(account.type),
                size: 21,
                color: tint,
              ),
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
                      size: 15,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    accountTypeLabel(account.type),
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  Fmt.money(account.balance, forceCompact: true),
                  style: AppTextStyles.money(
                    16,
                    color: account.balance < 0 ? palette.expense : palette.ink,
                    weight: FontWeight.w700,
                  ),
                ),
                if (account.creditLimit != null)
                  Text(
                    'limit ${Fmt.money(account.creditLimit!, forceCompact: true)}',
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: palette.tertiary),
          ],
        ),
      ),
    );
  }
}

IconData accountIcon(String type) {
  switch (type) {
    case kAccountBank:
      return Icons.account_balance_rounded;
    case kAccountCredit:
      return Icons.credit_card_rounded;
    case kAccountWallet:
      return Icons.account_balance_wallet_rounded;
    case kAccountInvestment:
      return Icons.trending_up_rounded;
    case kAccountLoan:
      return Icons.request_quote_rounded;
    default:
      return Icons.payments_rounded;
  }
}
