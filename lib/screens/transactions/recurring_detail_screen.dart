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
import 'recurring_screen.dart';
import 'transaction_detail_screen.dart';

class RecurringDetailScreen extends ConsumerWidget {
  const RecurringDetailScreen({super.key, required this.ruleId});

  final int ruleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final rules =
        ref.watch(recurringRulesProvider).valueOrNull ?? const <RecurringRule>[];
    RecurringRule? rule;
    for (final item in rules) {
      if (item.id == ruleId) rule = item;
    }

    if (rule == null) {
      return Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(
          titleSpacing: 0,
          title: Text('Recurring', style: AppTextStyles.h2(palette.ink)),
        ),
        body: const EmptyState(
          title: 'Rule not found',
          message: 'This repeating rule may have been removed.',
          illustration: IllustrationKind.bills,
          compact: true,
        ),
      );
    }

    final current = rule;
    final accounts = ref.watch(accountLookupProvider).valueOrNull ??
        const <int, Account>{};
    final categories = ref.watch(categoryLookupProvider).valueOrNull ??
        const <int, Category>{};
    final history = ref.watch(ruleTransactionsProvider(ruleId)).valueOrNull ??
        const <Txn>[];
    final accountName = accounts[current.accountId]?.name;
    final category = categories[current.categoryId];
    final income = current.type == kTypeIncome;
    final amountTone = income ? palette.income : palette.expense;
    final next = DateTime.fromMillisecondsSinceEpoch(current.nextDate);
    final daysUntil = next
        .difference(DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day))
        .inDays;
    final cycle = _cycleDays(current.frequency);
    final elapsed = cycle <= 0
        ? 0.0
        : ((cycle - daysUntil) / cycle).clamp(0.0, 1.0).toDouble();
    final monthlyAverage = _monthlyEquivalent(current);
    final total = history.fold<int>(0, (sum, txn) => sum + txn.amount);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          current.note?.trim().isNotEmpty == true
              ? current.note!.trim()
              : (category?.name ?? 'Recurring'),
          style: AppTextStyles.h2(palette.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Delete rule',
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Delete this recurring rule?',
                message: 'Past transactions stay; future repeats stop.',
              );
              if (!ok) return;
              await ref
                  .read(transactionRepositoryProvider)
                  .deleteRecurringRule(current.id!);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: Icon(Icons.delete_outline_rounded, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showRecurringEditor(context, ref, rule: current);
        },
        backgroundColor: palette.accent,
        foregroundColor: AppColors.espresso,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(
          'Edit',
          style: AppTextStyles.base(
            size: 15,
            weight: FontWeight.w700,
            height: 1.1,
          ).copyWith(color: AppColors.espresso),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          4,
          AppSpacing.screen,
          120,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF4A2A56),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF7C4E8C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'Next occurrence',
                      style: AppTextStyles.base(
                        size: 14,
                        weight: FontWeight.w500,
                        height: 1.1,
                      ).copyWith(color: const Color(0xFFD9BCE4)),
                    ),
                    const Spacer(),
                    if (!current.active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Paused',
                          style: AppTextStyles.base(
                            size: 11.5,
                            weight: FontWeight.w600,
                            height: 1.1,
                          ).copyWith(color: const Color(0xFFEAD8F2)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  Fmt.date(current.nextDate),
                  style: AppTextStyles.base(
                    size: 27,
                    weight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ).copyWith(color: const Color(0xFFF3E4F8)),
                ),
                const SizedBox(height: 16),
                WavyProgress(
                  value: elapsed,
                  height: 20,
                  color: const Color(0xFFE7A6F5),
                  trackColor: Colors.white.withOpacity(0.14),
                  waves: 10,
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Text(
                      daysUntil < 0
                          ? '${daysUntil.abs()} days overdue'
                          : daysUntil == 0
                              ? 'Due today'
                              : '$daysUntil days until next',
                      style: AppTextStyles.base(
                        size: 14,
                        weight: FontWeight.w500,
                        height: 1.2,
                      ).copyWith(color: const Color(0xFFE2C6EC)),
                    ),
                    const Spacer(),
                    Text(
                      '${(elapsed * 100).round()}%',
                      style: AppTextStyles.base(
                        size: 15,
                        weight: FontWeight.w600,
                        height: 1.2,
                      ).copyWith(color: const Color(0xFFE2C6EC)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          PaisaSectionTitle(
            title: 'Details',
            padding: const EdgeInsets.only(bottom: 8),
          ),
          Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.divider.withOpacity(0.4)),
            ),
            child: Column(
              children: <Widget>[
                _DetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Account',
                  value: accountName ?? 'Any account',
                ),
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: category?.name ?? 'Uncategorised',
                ),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Started on',
                  value: Fmt.date(current.nextDate),
                ),
                _DetailRow(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Frequency',
                  value: frequencyLabel(current.frequency),
                ),
                _DetailRow(
                  icon: Icons.notifications_off_outlined,
                  label: 'Reminder',
                  value: 'No reminder',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          PaisaSectionTitle(
            title: 'Statistics',
            padding: const EdgeInsets.only(bottom: 10),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatBox(
                  icon: Icons.repeat_rounded,
                  value: '${history.length}',
                  label: 'Total Occurrences',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  icon: Icons.attach_money_rounded,
                  value: Fmt.money(total),
                  label: 'Total',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  icon: Icons.trending_down_rounded,
                  value: Fmt.money(monthlyAverage),
                  label: 'Monthly Average',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          PaisaSectionTitle(
            title: 'History',
            padding: const EdgeInsets.only(bottom: 10),
          ),
          if (history.isEmpty)
            PaisaCard(
              child: Text(
                'No transactions posted from this rule yet.',
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
                      accountName: accountName,
                      showTime: true,
                      margin: EdgeInsets.zero,
                      showDivider: i < history.length - 1,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TransactionDetailScreen(
                            transactionId: history[i].id!,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              income
                  ? 'Money comes in on this schedule.'
                  : 'Money goes out on this schedule.',
              style: AppTextStyles.body(palette.tertiary)
                  .copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Amount ${Fmt.money(current.amount)}',
              style: AppTextStyles.base(
                size: 13,
                weight: FontWeight.w500,
                height: 1.2,
              ).copyWith(color: amountTone),
            ),
          ),
        ],
      ),
    );
  }

  static int _cycleDays(String frequency) {
    switch (frequency) {
      case 'daily':
        return 1;
      case 'weekly':
        return 7;
      case 'monthly':
        return 30;
      case 'quarterly':
        return 91;
      case 'yearly':
        return 365;
      default:
        return 30;
    }
  }

  static int _monthlyEquivalent(RecurringRule rule) {
    switch (rule.frequency) {
      case 'daily':
        return (rule.amount * 30 * rule.interval).round();
      case 'weekly':
        return (rule.amount * 4.33 * rule.interval).round();
      case 'quarterly':
        return (rule.amount / 3 * rule.interval).round();
      case 'yearly':
        return (rule.amount / 12 * rule.interval).round();
      case 'one_time':
        return 0;
      default:
        return rule.amount;
    }
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
        children: <Widget>[
          Icon(icon, size: 20, color: const Color(0xFFF0A07E)),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w600,
                    height: 1.2,
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

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.divider.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: palette.isDark
                  ? Colors.white.withOpacity(0.08)
                  : palette.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: palette.sub),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.base(
                size: 16.5,
                weight: FontWeight.w700,
                height: 1.1,
              ).copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            style: AppTextStyles.base(
              size: 12.5,
              weight: FontWeight.w400,
              height: 1.25,
            ).copyWith(color: palette.tertiary),
          ),
        ],
      ),
    );
  }
}
