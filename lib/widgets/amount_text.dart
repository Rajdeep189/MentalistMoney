import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/money.dart';
import '../providers/app_providers.dart';

/// Derives the display colour for an amount from its transaction type.
Color amountColorFor(BuildContext context, String? type) {
  final palette = context.c;
  switch (type) {
    case 'income':
      return palette.income;
    case 'transfer':
      return palette.transfer;
    case 'expense':
      return palette.expense;
    default:
      return palette.ink;
  }
}

/// Tabular-figure money text that respects privacy settings.
class AmountText extends ConsumerWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.size = 15,
    this.weight = FontWeight.w600,
    this.type,
    this.color,
    this.signed = false,
    this.withSymbol = true,
    this.forceCompact = false,
    this.strikethrough = false,
    this.align,
    this.maxLines = 1,
    this.hideable = true,
  });

  final int amount;
  final double size;
  final FontWeight weight;

  /// 'income' | 'expense' | 'transfer' – controls colour and sign.
  final String? type;
  final Color? color;
  final bool signed;
  final bool withSymbol;
  final bool forceCompact;
  final bool strikethrough;
  final TextAlign? align;
  final int maxLines;
  final bool hideable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);
    final manualHide = ref.watch(amountsHiddenProvider);
    final hidden = hideable && (manualHide || settings.privacyHideDashboard);

    final tone = color ??
        (type == null ? palette.ink : amountColorFor(context, type));
    final prefix = signed
        ? (amount > 0
            ? (type == 'income' ? '+' : type == 'expense' ? '-' : '')
            : '-')
        : '';

    final text = hidden
        ? '••••'
        : '$prefix${Fmt.money(amount, withSymbol: withSymbol, forceCompact: forceCompact)}';

    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: AppTextStyles.money(size, color: tone, weight: weight).copyWith(
        decoration: strikethrough ? TextDecoration.lineThrough : null,
        decorationColor: tone,
      ),
    );
  }
}

/// Amount with a count-up animation (used on the dashboard hero numbers).
class AnimatedAmountText extends StatelessWidget {
  const AnimatedAmountText(
    this.amount, {
    super.key,
    this.size = 34,
    this.weight = FontWeight.w700,
    this.color,
    this.type,
    this.duration = const Duration(milliseconds: 700),
    this.withSymbol = true,
  });

  final int amount;
  final double size;
  final FontWeight weight;
  final Color? color;
  final String? type;
  final Duration duration;
  final bool withSymbol;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? (type == null ? context.c.ink : amountColorFor(context, type));
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        Fmt.money(value.round(), withSymbol: withSymbol),
        style: AppTextStyles.money(size, color: tone, weight: weight),
      ),
    );
  }
}

/// Small labelled money row ("Income ...... ₹24,000").
class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.label,
    required this.amount,
    this.type,
    this.icon,
    this.emphasis = false,
  });

  final String label;
  final int amount;
  final String? type;
  final IconData? icon;
  final bool emphasis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: palette.tertiary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: emphasis ? AppTextStyles.label(palette.ink) : AppTextStyles.body(palette.sub),
            ),
          ),
          AmountText(amount, size: emphasis ? 16 : 15, type: type),
        ],
      ),
    );
  }
}
