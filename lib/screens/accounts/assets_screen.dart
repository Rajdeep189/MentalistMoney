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
import 'account_detail_screen.dart';
import 'account_form_screen.dart';

/// Investments and property-style accounts rolled up as "Assets", matching the
/// reference layout: total figure, groups with per-group totals, tinted rows.
class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final accountsAsync = ref.watch(allAccountsProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Assets', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: 'How assets work',
            onPressed: () => _showInfo(context),
            icon: Icon(Icons.info_outline_rounded, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AccountFormScreen(),
          ),
        ),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (accounts) {
          final assets = accounts
              .where((a) =>
                  !a.archived &&
                  !a.isLiability &&
                  (a.type == kAccountInvestment || a.type == kAccountCustom))
              .toList();
          final total = assets.fold<int>(0, (sum, a) => sum + a.balance);
          final groups = <String, List<Account>>{};
          for (final account in assets) {
            groups.putIfAbsent(account.type, () => <Account>[]).add(account);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              Text(
                'Total',
                style: AppTextStyles.base(
                  size: 14,
                  weight: FontWeight.w600,
                  height: 1.1,
                ).copyWith(color: palette.sub),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Fmt.money(total),
                  style: AppTextStyles.serif(
                    size: 34,
                    color: palette.accent,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (assets.isEmpty)
                PaisaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'No assets yet',
                        style: AppTextStyles.base(
                          size: 15,
                          weight: FontWeight.w700,
                          height: 1.2,
                        ).copyWith(color: palette.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add an investment or custom account to track the value of things you own.',
                        style: AppTextStyles.body(palette.tertiary)
                            .copyWith(height: 1.5),
                      ),
                    ],
                  ),
                )
              else
                for (final entry in groups.entries) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        _labelFor(entry.key),
                        style: AppTextStyles.base(
                          size: 16,
                          weight: FontWeight.w700,
                          height: 1.15,
                        ).copyWith(color: palette.ink),
                      ),
                      const Spacer(),
                      Text(
                        Fmt.money(
                          entry.value.fold<int>(0, (sum, a) => sum + a.balance),
                          forceCompact: true,
                        ),
                        style: AppTextStyles.base(
                          size: 14,
                          weight: FontWeight.w600,
                          height: 1.1,
                        ).copyWith(color: palette.sub),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: palette.divider.withOpacity(0.35)),
                    ),
                    child: Column(
                      children: <Widget>[
                        for (var i = 0; i < entry.value.length; i++)
                          _AssetRow(
                            account: entry.value[i],
                            showDivider: i < entry.value.length - 1,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              Text(
                'Assets are valued at their current account balance.',
                style: AppTextStyles.caption(palette.tertiary)
                    .copyWith(fontSize: 11.5),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _labelFor(String type) {
    switch (type) {
      case kAccountInvestment:
        return 'Investments';
      case kAccountCustom:
        return 'Other';
      default:
        return accountTypeLabel(type);
    }
  }

  static Future<void> _showInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Assets Work',
        intro:
            'Assets help you track the value of things you own, like investments, property, or vehicles.',
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.category_outlined,
            title: 'Asset Types',
            body:
                'Organize by type: Real Estate, Vehicle, Investment, Gold, and more.',
          ),
          InfoSection(
            icon: Icons.trending_up_rounded,
            title: 'Valuation',
            body:
                'Track purchase price and current value to see how your assets perform.',
          ),
          InfoSection(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Portfolio',
            body:
                'View your total portfolio value with a grouped summary by asset type.',
          ),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.account, required this.showDivider});

  final Account account;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tint = TileColors.all[(account.name.hashCode.abs()) % TileColors.all.length];
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccountDetailScreen(accountId: account.id!),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: palette.divider.withOpacity(0.35)))
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.home_work_rounded,
                  size: 23, color: Colors.white),
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
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    account.notes?.trim().isNotEmpty == true
                        ? account.notes!
                        : accountTypeLabel(account.type),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              Fmt.money(account.balance, forceCompact: true),
              style: AppTextStyles.base(
                size: 14,
                weight: FontWeight.w700,
                height: 1.1,
              ).copyWith(color: const Color(0xFF6BD6A0)),
            ),
          ],
        ),
      ),
    );
  }
}
