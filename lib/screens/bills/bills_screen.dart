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
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/luxe.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/section_header.dart';
import 'bill_calendar_screen.dart';
import 'bill_form_screen.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final billsAsync = ref.watch(billsProvider);
    final accounts = ref.watch(accountLookupProvider).valueOrNull ?? const <int, Account>{};

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            const MetallicMark(size: 28, animated: false),
            const SizedBox(width: 10),
            Text('Bills', style: AppTextStyles.h2(palette.ink)),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Calendar',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BillCalendarScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BillFormScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (bills) {
          if (bills.isEmpty) {
            return EmptyState(
              title: 'No bills yet',
              message:
                  'Add rent, electricity, subscriptions and more. MoneyMan reminds you before the due date.',
              illustration: IllustrationKind.bills,
              actionLabel: 'Add your first bill',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BillFormScreen()),
              ),
            );
          }
          final overdue = bills.where((b) => b.isOverdue && b.status != kBillPaid).toList();
          final upcoming = bills
              .where((b) => !b.isOverdue && b.status != kBillPaid && b.status != kBillSkipped)
              .toList();
          final paid = bills.where((b) => b.status == kBillPaid).toList();
          final monthlyTotal = bills
              .where((b) => b.frequency == 'monthly')
              .fold<int>(0, (sum, bill) => sum + bill.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(AppSpacing.x5),
                decoration: BoxDecoration(
                  gradient: AppColors.graphiteGradient,
                  borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(palette.isDark ? 0.5 : 0.2),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Eyebrow('Monthly commitments',
                            color: Color(0xFF9C9CA6)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (overdue.isEmpty
                                    ? AppColors.limeB
                                    : AppColors.sunset)
                                .withOpacity(0.16),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            overdue.isEmpty
                                ? 'All on track'
                                : '${overdue.length} overdue',
                            style: AppTextStyles.caption(
                              overdue.isEmpty
                                  ? AppColors.limeA
                                  : AppColors.darkExpense,
                            ).copyWith(fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Fmt.money(monthlyTotal),
                        style: AppTextStyles.serif(size: 30, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${bills.length} bills tracked · ${upcoming.length} upcoming',
                      style: AppTextStyles.caption(const Color(0xFF9C9CA6)),
                    ),
                  ],
                ),
              ),
              if (overdue.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.x5),
                SectionHeader(title: 'Overdue', padding: EdgeInsets.zero),
                ...overdue.map((bill) => _BillTile(
                      bill: bill,
                      accountName: accounts[bill.accountId]?.name,
                    )),
              ],
              if (upcoming.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.x5),
                SectionHeader(title: 'Upcoming', padding: EdgeInsets.zero),
                ...upcoming.map((bill) => _BillTile(
                      bill: bill,
                      accountName: accounts[bill.accountId]?.name,
                    )),
              ],
              if (paid.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.x5),
                SectionHeader(title: 'Paid', padding: EdgeInsets.zero),
                ...paid.map((bill) => _BillTile(
                      bill: bill,
                      accountName: accounts[bill.accountId]?.name,
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BillTile extends ConsumerWidget {
  const _BillTile({required this.bill, this.accountName});

  final Bill bill;
  final String? accountName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final overdue = bill.isOverdue && bill.status != kBillPaid;
    final paid = bill.status == kBillPaid;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.x4),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => BillFormScreen(bill: bill)),
        ),
        child: Row(
          children: <Widget>[
            CategoryIcon(
              icon: paid
                  ? Icons.check_circle_rounded
                  : overdue
                      ? Icons.error_outline_rounded
                      : Icons.receipt_long_rounded,
              color: paid
                  ? palette.income
                  : overdue
                      ? palette.expense
                      : palette.warning,
              size: 42,
              rounded: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(bill.name, style: AppTextStyles.label(palette.ink)),
                  const SizedBox(height: 2),
                  Text(
                    '${frequencyLabel(bill.frequency)} · ${Fmt.date(bill.dueDate)}'
                    '${accountName != null ? ' · $accountName' : ''}',
                    style: AppTextStyles.caption(palette.tertiary),
                  ),
                  if (overdue)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Overdue by ${bill.daysUntilDue.abs()} days',
                        style: AppTextStyles.caption(palette.expense),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                AmountText(bill.amount, size: 14, weight: FontWeight.w600),
                if (!paid)
                  TextButton(
                    onPressed: () => _markPaid(context, ref),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Mark paid',
                        style: AppTextStyles.caption(palette.onSoft)),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 18, color: palette.tertiary),
              onSelected: (value) async {
                final repo = ref.read(billRepositoryProvider);
                switch (value) {
                  case 'paid':
                    await _markPaid(context, ref);
                    break;
                  case 'skip':
                    await repo.skipOccurrence(bill);
                    if (context.mounted) showSnack(context, 'Occurrence skipped');
                    break;
                  case 'snooze':
                    await repo.snooze(bill, 3);
                    if (context.mounted) showSnack(context, 'Snoozed by 3 days');
                    break;
                  case 'reopen':
                    await repo.reopen(bill);
                    break;
                  case 'delete':
                    final ok = await confirmAction(
                      context,
                      title: 'Delete "${bill.name}"?',
                      message: 'Past transactions created by this bill stay in your ledger.',
                    );
                    if (ok) await repo.delete(bill.id!);
                    break;
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                if (!paid)
                  const PopupMenuItem<String>(value: 'paid', child: Text('Mark as paid')),
                if (bill.status != kBillPaid && bill.frequency != 'one_time')
                  const PopupMenuItem<String>(
                      value: 'skip', child: Text('Skip this occurrence')),
                if (bill.status != kBillPaid)
                  const PopupMenuItem<String>(value: 'snooze', child: Text('Snooze 3 days')),
                if (paid)
                  const PopupMenuItem<String>(value: 'reopen', child: Text('Reopen')),
                const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Mark "${bill.name}" as paid?',
      message: bill.autoCreateTxn
          ? 'An expense of ${Fmt.money(bill.amount)} will be added to your ledger.'
          : 'No transaction will be created.',
      confirmLabel: 'Mark paid',
      destructive: false,
    );
    if (!ok) return;
    await ref.read(billRepositoryProvider).markPaid(bill, paidOn: DateTime.now());
    if (context.mounted) showSnack(context, '${bill.name} marked as paid');
  }
}
