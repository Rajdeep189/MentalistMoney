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
                  style: AppTextStyles.base(
                    size: 38,
                    weight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.6,
                  ).copyWith(color: palette.accent),
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
                          size: 18,
                          weight: FontWeight.w600,
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
                          size: 17,
                          weight: FontWeight.w700,
                          height: 1.1,
                        ).copyWith(color: palette.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(20),
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
                style: AppTextStyles.body(palette.tertiary)
                    .copyWith(fontSize: 12.5, height: 1.4),
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
    final look = _lookFor(account);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccountDetailScreen(accountId: account.id!),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom:
                      BorderSide(color: palette.divider.withOpacity(0.35)),
                )
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: look.tint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(look.icon, size: 23, color: Colors.white),
            ),
            const SizedBox(width: 13),
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
                      weight: FontWeight.w600,
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
                    style: AppTextStyles.body(palette.tertiary).copyWith(
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              Fmt.money(account.balance),
              style: AppTextStyles.base(
                size: 16,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: const Color(0xFF6BD6A0)),
            ),
          ],
        ),
      ),
    );
  }

  _AssetLook _lookFor(Account account) {
    final haystack =
        '${account.name} ${account.notes ?? ''}'.toLowerCase();
    if (haystack.contains('rent') || haystack.contains('apartment')) {
      return const _AssetLook(Icons.money_rounded, Color(0xFF12A594));
    }
    if (haystack.contains('home') ||
        haystack.contains('house') ||
        haystack.contains('residence') ||
        haystack.contains('property') ||
        haystack.contains('real estate')) {
      return const _AssetLook(Icons.account_balance_rounded, Color(0xFF4CAF50));
    }
    if (haystack.contains('vehicle') ||
        haystack.contains('car') ||
        haystack.contains('bike')) {
      return const _AssetLook(Icons.directions_car_filled_rounded,
          Color(0xFF2F9BF2));
    }
    if (haystack.contains('gold') || haystack.contains('jewellery')) {
      return const _AssetLook(Icons.workspace_premium_rounded,
          Color(0xFFE0A126));
    }
    if (account.type == kAccountInvestment) {
      return const _AssetLook(Icons.trending_up_rounded, Color(0xFF3BB273));
    }
    return const _AssetLook(Icons.savings_rounded, Color(0xFF8A6ACF));
  }
}

class _AssetLook {
  const _AssetLook(this.icon, this.tint);

  final IconData icon;
  final Color tint;
}
