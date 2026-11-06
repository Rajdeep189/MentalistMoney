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

/// Loans & lending: liability accounts read as borrowing, custom accounts as
/// money you have lent out, with a net balance header and pastel cards.
class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  String _tab = 'All';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accountsAsync = ref.watch(allAccountsProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Loans', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: 'How loans work',
            onPressed: () => _showInfo(context),
            icon: Icon(Icons.info_outline_rounded, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AccountFormScreen()),
        ),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (accounts) {
          final borrowing = accounts
              .where((a) => !a.archived && a.isLiability && a.balance != 0)
              .toList();
          final lending = accounts
              .where((a) => !a.archived && a.type == kAccountCustom && a.balance > 0)
              .toList();
          final lentTotal = lending.fold<int>(0, (sum, a) => sum + a.balance);
          final borrowedTotal =
              borrowing.fold<int>(0, (sum, a) => sum + a.balance.abs());
          final net = lentTotal - borrowedTotal;
          final visible = <Account>[
            if (_tab != 'Borrowing') ...lending,
            if (_tab != 'Lending') ...borrowing,
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: PaisaStatTile(
                      label: 'Lending',
                      value: Fmt.money(lentTotal, forceCompact: true),
                      icon: Icons.north_east_rounded,
                      background: AppColors.mint,
                      foreground: AppColors.mintDeep,
                      valueSize: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PaisaStatTile(
                      label: 'Borrowing',
                      value: Fmt.money(borrowedTotal, forceCompact: true),
                      icon: Icons.south_west_rounded,
                      background: AppColors.blush,
                      foreground: AppColors.blushDeep,
                      valueSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: palette.isDark
                      ? const Color(0xFF2E1D17)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.account_balance_outlined,
                        size: 18, color: palette.sub),
                    const SizedBox(width: 10),
                    Text(
                      'Net balance',
                      style: AppTextStyles.base(
                        size: 13.5,
                        weight: FontWeight.w600,
                        height: 1.1,
                      ).copyWith(color: palette.sub),
                    ),
                    const Spacer(),
                    Text(
                      '${net < 0 ? '−' : ''}${Fmt.money(net.abs(), forceCompact: true)}',
                      style: AppTextStyles.serif(
                        size: 18,
                        color: net >= 0 ? palette.income : palette.expense,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PaisaSegment<String>(
                options: const <String>['All', 'Lending', 'Borrowing'],
                value: _tab,
                onChanged: (value) => setState(() => _tab = value),
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                PaisaCard(
                  child: Text(
                    'No loans here yet. Add an account to track money you lent or borrowed.',
                    style: AppTextStyles.body(palette.tertiary)
                        .copyWith(height: 1.5),
                  ),
                )
              else
                for (var i = 0; i < visible.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LoanCard(
                      account: visible[i],
                      tint: i.isEven ? AppColors.butter : AppColors.lilac,
                      ink: i.isEven
                          ? AppColors.butterDeep
                          : AppColors.lilacDeep,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Loans Work',
        intro:
            "Loans help you track money you've lent to others or borrowed, with payment progress.",
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.swap_vert_rounded,
            title: 'Loan Types',
            body:
                'Lending: Money you gave to someone. They owe you.\nBorrowing: Money you received from someone. You owe them.',
          ),
          InfoSection(
            icon: Icons.payments_outlined,
            title: 'Payments',
            body:
                'Record partial or full payments to track the remaining balance on each loan.',
          ),
          InfoSection(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Summary',
            body:
                'View total lending, borrowing, and net balance at the top of the page.',
          ),
          InfoSection(
            icon: Icons.check_circle_outline_rounded,
            title: 'Status',
            body:
                'Active loans show remaining balance. Completed loans are automatically tracked when fully paid.',
          ),
          InfoSection(
            icon: Icons.person_outline_rounded,
            title: 'People',
            body:
                'Link a loan to a person to track who you lent to or borrowed from. The linked person appears in loan details.',
          ),
          InfoSection(
            icon: Icons.event_repeat_rounded,
            title: 'Due Dates',
            body:
                'Set a due date for each loan. Overdue loans are flagged automatically, and a countdown shows days remaining.',
          ),
          InfoSection(
            icon: Icons.show_chart_rounded,
            title: 'Progress',
            body:
                'A visual progress bar shows how much has been repaid. Track paid amount, remaining balance, and completion percentage.',
          ),
          InfoSection(
            icon: Icons.sort_rounded,
            title: 'Sorting',
            body:
                'Sort loans by name or amount to quickly find what you need. Tap the filter icon to change sort order.',
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.account,
    required this.tint,
    required this.ink,
  });

  final Account account;
  final Color tint;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final days = account.dueDay == null ? null : account.dueDay! - DateTime.now().day;
    final progress = account.creditLimit == null || account.creditLimit == 0
        ? 0.35
        : (account.balance.abs() / account.creditLimit!).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccountDetailScreen(accountId: account.id!),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    account.isLiability
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 21,
                    color: ink,
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
                          size: 16,
                          weight: FontWeight.w700,
                          height: 1.15,
                        ).copyWith(color: ink),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        account.isLiability ? 'Borrowing' : 'Lending',
                        style: AppTextStyles.caption(ink.withOpacity(0.75))
                            .copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                if (days != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      days >= 0 ? '$days days' : '${days.abs()}d late',
                      style: AppTextStyles.base(
                        size: 10.5,
                        weight: FontWeight.w700,
                        height: 1.1,
                      ).copyWith(color: ink),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Outstanding',
                          style: AppTextStyles.caption(ink.withOpacity(0.7))
                              .copyWith(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        Fmt.money(account.balance.abs(), forceCompact: true),
                        style: AppTextStyles.serif(size: 18, color: ink),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Repaid',
                          style: AppTextStyles.caption(ink.withOpacity(0.7))
                              .copyWith(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        '${(progress * 100).round()}%',
                        style: AppTextStyles.serif(size: 18, color: ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.45),
                valueColor: AlwaysStoppedAnimation<Color>(ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
