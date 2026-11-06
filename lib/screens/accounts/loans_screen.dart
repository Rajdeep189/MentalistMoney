import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import 'loan_detail_screen.dart';
import 'loan_form_screen.dart';

/// Warm tints used for loan cards: lending reads pink, borrowing reads teal.
class LoanTone {
  const LoanTone({required this.background, required this.accent});

  final Color background;
  final Color accent;

  static const LoanTone lending = LoanTone(
    background: Color(0xFF6E0F2B),
    accent: Color(0xFFF2407E),
  );
  static const LoanTone borrowing = LoanTone(
    background: Color(0xFF0F3B36),
    accent: Color(0xFF2ED3B7),
  );
  static const LoanTone completed = LoanTone(
    background: Color(0xFF2E2A20),
    accent: Color(0xFFC9B58C),
  );
}

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  String _tab = 'Lending';
  bool _sortByAmount = false;

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
            icon: Icon(Icons.info_outline_rounded,
                size: 22, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LoanFormScreen(
              initialBorrowing: _tab == 'Borrowing',
            ),
          ),
        ),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: PaisaSegment<String>(
            options: const <String>['Lending', 'Borrowing', 'Completed'],
            value: _tab,
            height: 54,
            onChanged: (value) => setState(() => _tab = value),
          ),
        ),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (accounts) {
          final loans = accounts
              .where((a) => !a.archived && a.loanKind != null)
              .toList();
          final lending = loans
              .where((a) => a.loanKind == 'lending')
              .toList();
          final borrowing =
              loans.where((a) => a.loanKind == 'borrowing').toList();
          final completed = accounts
              .where((a) => a.archived && a.loanKind != null)
              .toList();

          final lentTotal = lending.fold<int>(0, (sum, a) => sum + a.balance);
          final borrowedTotal =
              borrowing.fold<int>(0, (sum, a) => sum + a.balance.abs());
          final net = lentTotal - borrowedTotal;

          var visible = _tab == 'Borrowing'
              ? borrowing
              : _tab == 'Completed'
                  ? completed
                  : lending;
          if (_sortByAmount) {
            visible = [...visible]
              ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.divider.withOpacity(0.4)),
                ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Text(
                                  'Lending',
                                  style: AppTextStyles.base(
                                    size: 16,
                                    weight: FontWeight.w400,
                                    height: 1.1,
                                  ).copyWith(color: palette.sub),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    Fmt.money(lentTotal),
                                    style: AppTextStyles.base(
                                      size: 21,
                                      weight: FontWeight.w700,
                                      height: 1.1,
                                    ).copyWith(color: palette.expense),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 46,
                            color: palette.divider.withOpacity(0.6),
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Text(
                                  'Borrowing',
                                  style: AppTextStyles.base(
                                    size: 16,
                                    weight: FontWeight.w400,
                                    height: 1.1,
                                  ).copyWith(color: palette.sub),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    borrowedTotal == 0
                                        ? Fmt.money(0)
                                        : '-${Fmt.money(borrowedTotal)}',
                                    style: AppTextStyles.base(
                                      size: 21,
                                      weight: FontWeight.w700,
                                      height: 1.1,
                                    ).copyWith(color: palette.income),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: palette.divider.withOpacity(0.4),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Net Loan Balance',
                                  style: AppTextStyles.base(
                                    size: 16,
                                    weight: FontWeight.w500,
                                    height: 1.15,
                                  ).copyWith(color: palette.ink),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  net >= 0
                                      ? "You're owed more than you owe"
                                      : 'You owe more than you are owed',
                                  style: AppTextStyles.body(palette.tertiary)
                                      .copyWith(fontSize: 13.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            Fmt.money(net.abs()),
                            style: AppTextStyles.base(
                              size: 20,
                              weight: FontWeight.w700,
                              height: 1.1,
                            ).copyWith(
                              color:
                                  net >= 0 ? palette.income : palette.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Text(
                    '${visible.length} loan${visible.length == 1 ? '' : 's'}',
                    style: AppTextStyles.base(
                      size: 20,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.accent),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _sortByAmount = !_sortByAmount),
                    child: Icon(Icons.sort_rounded,
                        size: 22, color: palette.sub),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showInfo(context),
                    child: Icon(Icons.info_outline_rounded,
                        size: 22, color: palette.sub),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                PaisaCard(
                  child: Text(
                    _tab == 'Completed'
                        ? 'No completed loans yet. Loans you mark done land here.'
                        : 'No ${_tab.toLowerCase()} loans yet. Tap + to track money you have ${_tab == 'Lending' ? 'lent out' : 'borrowed'}.',
                    style: AppTextStyles.body(palette.tertiary)
                        .copyWith(height: 1.5),
                  ),
                )
              else
                for (var i = 0; i < visible.length; i++)
                  Entrance(
                    index: i,
                    // Swipe a loan left to archive it as completed.
                    child: Dismissible(
                      key: ValueKey<int>(visible[i].id ?? i),
                      direction: DismissDirection.endToStart,
                      background: _SwipeDone(tone: palette.income),
                      confirmDismiss: (_) async {
                        final ok = await confirmAction(
                          context,
                          title: 'Mark "${visible[i].name}" as done?',
                          message:
                              'The loan is archived and closed at a zero balance.',
                          confirmLabel: 'Mark done',
                          destructive: false,
                        );
                        if (!ok) return false;
                        await ref
                            .read(accountRepositoryProvider)
                            .update(visible[i].copyWith(balance: 0, archived: true));
                        return true;
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LoanCard(
                          account: visible[i],
                          tone: _tab == 'Completed'
                              ? LoanTone.completed
                              : visible[i].loanKind == 'borrowing'
                                  ? LoanTone.borrowing
                                  : LoanTone.lending,
                          index: i,
                        ),
                      ),
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
    required this.tone,
    required this.index,
  });

  final Account account;
  final LoanTone tone;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final total = account.openingBalance.abs() == 0
        ? account.balance.abs()
        : account.openingBalance.abs();
    final remaining = account.balance.abs();
    final paid = (total - remaining).clamp(0, total).toInt();
    final ratio = total == 0 ? 0.0 : paid / total;
    final daysLeft = account.endDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(account.endDate!)
            .difference(DateTime.now())
            .inDays;
    final bg = palette.isDark ? tone.background : AppColors.blush;
    final accent = palette.isDark ? tone.accent : AppColors.blushDeep;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LoanDetailScreen(accountId: account.id!),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    AppIcons.byName(account.icon, fallback: Icons.savings_rounded),
                    size: 26,
                    color: Colors.white,
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
                          size: 19,
                          weight: FontWeight.w600,
                          height: 1.15,
                        ).copyWith(color: palette.ink),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        account.notes?.trim().isNotEmpty == true
                            ? account.notes!
                            : (account.person ?? 'Personal loan'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(
                          palette.isDark
                              ? Colors.white.withOpacity(0.62)
                              : palette.sub,
                        ).copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (daysLeft != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.schedule_rounded, size: 12, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          '${daysLeft.clamp(0, 9999)} days',
                          style: AppTextStyles.base(
                            size: 12,
                            weight: FontWeight.w600,
                            height: 1,
                          ).copyWith(color: accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _CardFigure(label: 'Paid', value: Fmt.money(paid)),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: accent.withOpacity(0.28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _CardFigure(label: 'Total', value: Fmt.money(total)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: accent.withOpacity(0.22),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.calendar_today_rounded,
                    size: 14,
                    color: palette.isDark
                        ? Colors.white.withOpacity(0.62)
                        : palette.sub),
                const SizedBox(width: 7),
                Text(
                  account.endDate == null
                      ? 'No due date'
                      : 'Due ${Fmt.date(account.endDate!)}',
                  style: AppTextStyles.base(
                    size: 14,
                    weight: FontWeight.w400,
                    height: 1.2,
                  ).copyWith(
                    color: palette.isDark
                        ? Colors.white.withOpacity(0.62)
                        : palette.sub,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(ratio * 100).round()}%',
                  style: AppTextStyles.base(
                    size: 14,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ).copyWith(
                    color: palette.isDark
                        ? Colors.white.withOpacity(0.72)
                        : palette.sub,
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

class _SwipeDone extends StatelessWidget {
  const _SwipeDone({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.check_circle_rounded, color: tone, size: 24),
          const SizedBox(width: 8),
          Text(
            'Mark done',
            style: AppTextStyles.base(
              size: 15,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

class _CardFigure extends StatelessWidget {
  const _CardFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.base(
            size: 14.5,
            weight: FontWeight.w400,
            height: 1.1,
          ).copyWith(
            color: palette.isDark
                ? Colors.white.withOpacity(0.62)
                : palette.sub,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTextStyles.base(
              size: 18,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: palette.ink),
          ),
        ),
      ],
    );
  }
}
