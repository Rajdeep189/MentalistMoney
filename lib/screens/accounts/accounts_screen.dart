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
        title: Row(
          children: <Widget>[
            const MetallicMark(size: 30, animated: false),
            const SizedBox(width: 10),
            Text('Accounts', style: AppTextStyles.h2(palette.ink)),
          ],
        ),
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
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Row(
                    children: <Widget>[
                      Text(
                        accountTypeLabel(entry.key),
                        style: AppTextStyles.h3(palette.ink),
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
                  child: Text('Archived', style: AppTextStyles.h3(palette.ink)),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        gradient: AppColors.graphiteGradient,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge + 2),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.5 : 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ShineSweep(
        period: const Duration(milliseconds: 4600),
        opacity: 0.22,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Eyebrow('Net worth', color: Color(0xFF9C9CA6)),
                const Spacer(),
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Icon(Icons.diamond_outlined,
                      size: 14, color: AppColors.gold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Fmt.money(assets - liabilities),
                style: AppTextStyles.serif(size: 34, color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Row(
              children: <Widget>[
                Expanded(
                  child: _NetStat(
                    label: 'Assets',
                    value: assets,
                    color: AppColors.darkIncome,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.10),
                ),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: _NetStat(
                    label: 'Liabilities',
                    value: liabilities,
                    color: AppColors.darkExpense,
                    icon: Icons.trending_down_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetStat extends StatelessWidget {
  const _NetStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.overline(const Color(0xFF7C7C86))
                  .copyWith(fontSize: 8.5, letterSpacing: 1.1),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Fmt.money(value),
            style: AppTextStyles.serif(size: 15, color: Colors.white),
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
    return LuxeAccountCard(account: account, onTap: onTap);
  }
}
