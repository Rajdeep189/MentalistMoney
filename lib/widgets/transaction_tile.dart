import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/money.dart';
import '../data/models/models.dart';
import 'amount_text.dart';
import 'category_icon.dart';

/// A single transaction row used on the dashboard, lists and search results.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.txn,
    this.category,
    this.accountName,
    this.toAccountName,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.showDate = false,
    this.showDivider = false,
    this.trailing,
    this.dense = false,
  });

  final Txn txn;
  final Category? category;
  final String? accountName;
  final String? toAccountName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool showDate;
  final bool showDivider;
  final Widget? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final title = (txn.note != null && txn.note!.trim().isNotEmpty)
        ? txn.note!.trim()
        : (category?.name ?? (txn.type == kTypeTransfer ? 'Transfer' : 'Transaction'));

    final subtitleParts = <String>[
      if (category != null && txn.type != kTypeTransfer) category!.name,
      if (accountName != null)
        txn.type == kTypeTransfer && toAccountName != null
            ? '$accountName → $toAccountName'
            : accountName!,
      if (showDate)
        Fmt.date(txn.date)
      else
        Fmt.time(txn.date),
    ];

    final amountTone = amountColorFor(context, txn.type);

    return Material(
      color: selected ? palette.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 4 : 2,
            vertical: dense ? 8 : 10,
          ),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: palette.divider))
                : null,
          ),
          child: Row(
            children: <Widget>[
              if (txn.type == kTypeTransfer)
                CategoryIcon(
                  icon: Icons.swap_horiz_rounded,
                  color: palette.transfer,
                  size: dense ? 36 : 42,
                )
              else
                CategoryIcon(
                  iconName: category?.icon ?? 'category',
                  color: category == null ? palette.tertiary : _parse(category!.color),
                  size: dense ? 36 : 42,
                ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label(palette.ink)
                          .copyWith(fontSize: dense ? 13 : 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(palette.tertiary),
                    ),
                    if (txn.tagNames.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: txn.tagNames
                              .take(3)
                              .map((tag) => Text(
                                    '#$tag',
                                    style: AppTextStyles.caption(palette.accent)
                                        .copyWith(fontSize: 10.5),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              trailing ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (txn.type == kTypeTransfer)
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Icon(Icons.swap_horiz_rounded,
                                  size: 13, color: palette.transfer),
                            ),
                          Text(
                            '${txn.type == kTypeIncome ? '+' : txn.type == kTypeExpense ? '-' : ''}${Fmt.money(txn.amount)}',
                            style: AppTextStyles.money(
                              dense ? 13.5 : 14.5,
                              color: amountTone,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (txn.includeInReports == false)
                        Text(
                          'excluded',
                          style: AppTextStyles.caption(palette.tertiary)
                              .copyWith(fontSize: 9.5),
                        ),
                    ],
                  ),
            ],
          ),
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

/// Date group header with the day's income / expense totals.
class DateGroupHeader extends StatelessWidget {
  const DateGroupHeader({
    super.key,
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.x4,
        bottom: AppSpacing.x2,
      ),
      child: Row(
        children: <Widget>[
          Text(label, style: context.overline),
          const Spacer(),
          if (income > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '+${Fmt.money(income)}',
                style: AppTextStyles.caption(palette.income).copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTextStyles.tabular,
                ),
              ),
            ),
          if (expense > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '-${Fmt.money(expense)}',
                style: AppTextStyles.caption(palette.expense).copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTextStyles.tabular,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
