import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'amount_text.dart';
import 'app_card.dart';

/// Small metric tile (income / expense / savings).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    this.amount,
    this.value,
    this.type,
    this.icon,
    this.tone,
    this.caption,
    this.onTap,
    this.dense = false,
  });

  final String label;
  final int? amount;
  final String? value;
  final String? type;
  final IconData? icon;
  final Color? tone;
  final String? caption;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accentTone = tone ?? (type == null ? palette.accent : amountColorFor(context, type));

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(dense ? 14 : AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Container(
                  height: 26,
                  width: 26,
                  decoration: BoxDecoration(
                    color: accentTone.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: accentTone),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(palette.sub),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          if (amount != null)
            AmountText(
              amount!,
              size: dense ? 17 : 19,
              type: type,
              color: tone,
              weight: FontWeight.w700,
            )
          else
            Text(
              value ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.money(dense ? 17 : 19, color: tone ?? palette.ink, weight: FontWeight.w700),
            ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(palette.tertiary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick-action icon tile.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = color ?? palette.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: <Widget>[
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: tone.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Icon(icon, color: tone, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(palette.sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
