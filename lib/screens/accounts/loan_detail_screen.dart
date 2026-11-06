import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_detail_screen.dart';
import 'loan_form_screen.dart';

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final accounts =
        ref.watch(allAccountsProvider).valueOrNull ?? const <Account>[];
    Account? found;
    for (final account in accounts) {
      if (account.id == accountId) found = account;
    }

    if (found == null) {
      return Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(backgroundColor: palette.surface),
        body: const EmptyState(
          title: 'Loan not found',
          message: 'This loan may have been deleted.',
          illustration: IllustrationKind.wallet,
          compact: true,
        ),
      );
    }

    final loan = found;
    final borrowing = loan.loanKind == 'borrowing';
    final accent = borrowing ? const Color(0xFF2ED3B7) : const Color(0xFFF2407E);
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};
    final history =
        ref.watch(accountTransactionsProvider(accountId)).valueOrNull ??
            const <Txn>[];

    final total = loan.openingBalance.abs() == 0
        ? loan.balance.abs()
        : loan.openingBalance.abs();
    final remaining = loan.balance.abs();
    final paid = (total - remaining).clamp(0, total).toInt();
    final ratio = total == 0 ? 0.0 : paid / total;
    final daysLeft = loan.endDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(loan.endDate!)
            .difference(DateTime.now())
            .inDays;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        backgroundColor: palette.surface,
        actions: <Widget>[
          IconButton(
            tooltip: 'Add payment',
            onPressed: () => showAddTransactionSheet(
              context,
              ref,
              initialType: borrowing ? kTypeExpense : kTypeIncome,
              initialAmount: remaining,
              initialAccountId: loan.id,
              initialCategoryId: loan.categoryId,
              initialNote: '${loan.name} payment',
            ),
            icon: Icon(Icons.add_rounded, size: 26, color: palette.ink),
          ),
          IconButton(
            tooltip: 'Delete loan',
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Delete "${loan.name}"?',
                message: 'Transactions recorded against this loan are removed.',
              );
              if (!ok) return;
              await ref.read(accountRepositoryProvider).delete(loan.id!);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: Icon(Icons.delete_outline_rounded, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LoanFormScreen(loan: loan),
            ),
          );
        },
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(
          'Edit',
          style: AppTextStyles.base(
            size: 15,
            weight: FontWeight.w700,
            height: 1.1,
          ).copyWith(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          4,
          AppSpacing.screen,
          130,
        ),
        children: <Widget>[
          Text(
            loan.name,
            style: AppTextStyles.base(
              size: 30,
              weight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -0.5,
            ).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _SoftTag(
                label: borrowing ? 'Borrowing' : 'Lending',
                icon: borrowing
                    ? Icons.arrow_downward_rounded
                    : Icons.trending_up_rounded,
                background: accent,
                foreground: AppColors.espresso,
              ),
              if (daysLeft != null)
                _SoftTag(
                  label: daysLeft < 0
                      ? '${daysLeft.abs()} days overdue'
                      : '$daysLeft days left',
                  icon: Icons.schedule_rounded,
                  background: accent.withOpacity(0.35),
                  foreground: accent,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            borrowing ? 'Amount Borrowed' : 'Amount Lent',
            style: AppTextStyles.base(
              size: 15,
              weight: FontWeight.w400,
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
                size: 36,
                weight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -0.6,
              ).copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.divider.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Repayment Progress',
                  style: AppTextStyles.base(
                    size: 18,
                    weight: FontWeight.w600,
                    height: 1.15,
                  ).copyWith(color: palette.ink),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: palette.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ProgressFigure(
                        label: 'Paid',
                        value: Fmt.money(paid),
                      ),
                    ),
                    Expanded(
                      child: _ProgressFigure(
                        label: 'Amount',
                        value: Fmt.money(remaining),
                        tone: palette.expense,
                      ),
                    ),
                    Expanded(
                      child: _ProgressFigure(
                        label: 'Total',
                        value: Fmt.money(total),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loan Details',
            style: AppTextStyles.base(
              size: 20,
              weight: FontWeight.w600,
              height: 1.15,
            ).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.divider.withOpacity(0.4)),
            ),
            child: Column(
              children: <Widget>[
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: borrowing ? 'Borrowed from' : 'Lent to',
                  value: loan.person?.trim().isNotEmpty == true
                      ? loan.person!
                      : 'Not set',
                ),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Start date',
                  value: loan.startDate == null
                      ? 'Not set'
                      : Fmt.date(loan.startDate!),
                ),
                _DetailRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'End date',
                  value: loan.endDate == null
                      ? 'Not set'
                      : Fmt.date(loan.endDate!),
                ),
                _DetailRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Notes',
                  value: loan.notes?.trim().isNotEmpty == true
                      ? loan.notes!
                      : 'No notes',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Mark "${loan.name}" as done?',
                  message:
                      'The loan is archived and its remaining balance is closed.',
                );
                if (!ok) return;
                await ref
                    .read(accountRepositoryProvider)
                    .update(loan.copyWith(balance: 0, archived: true));
                if (context.mounted) {
                  showSnack(context, 'Loan completed');
                  Navigator.of(context).pop();
                }
              },
              icon: Icon(
                Icons.check_rounded,
                size: 20,
                color: palette.isDark
                    ? const Color(0xFFF6C453)
                    : AppColors.espresso,
              ),
              label: Text(
                'Mark as Done',
                style: AppTextStyles.base(
                  size: 16,
                  weight: FontWeight.w600,
                  height: 1.1,
                ).copyWith(
                  color: palette.isDark
                      ? const Color(0xFFF6C453)
                      : AppColors.espresso,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.isDark
                    ? const Color(0xFF6B4A0F)
                    : const Color(0xFFF6C453),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          PaisaSectionTitle(
            title: 'Payment History',
            color: palette.accent,
            padding: const EdgeInsets.only(bottom: 10),
          ),
          if (history.isEmpty)
            PaisaCard(
              child: Text(
                'No payments recorded for this loan yet.',
                style: AppTextStyles.body(palette.tertiary),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.divider.withOpacity(0.4)),
              ),
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < history.length; i++)
                    PaisaTxnCard(
                      txn: history[i],
                      category: categories[history[i].categoryId],
                      accountName: loan.name,
                      margin: EdgeInsets.zero,
                      showDivider: i < history.length - 1,
                      onTap: () =>
                          showTransactionDetail(context, history[i].id!),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SoftTag extends StatelessWidget {
  const _SoftTag({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.base(
              size: 14.5,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _ProgressFigure extends StatelessWidget {
  const _ProgressFigure({
    required this.label,
    required this.value,
    this.tone,
  });

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.base(
            size: 13.5,
            weight: FontWeight.w400,
            height: 1.1,
          ).copyWith(color: palette.sub),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTextStyles.base(
              size: 16.5,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: tone ?? palette.ink),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: palette.divider.withOpacity(0.4)),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 22, color: palette.sub),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppTextStyles.base(
                    size: 14,
                    weight: FontWeight.w400,
                    height: 1.1,
                  ).copyWith(color: palette.sub),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTextStyles.base(
                    size: 16.5,
                    weight: FontWeight.w600,
                    height: 1.25,
                  ).copyWith(color: palette.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
