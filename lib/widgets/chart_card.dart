import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'app_card.dart';
import 'premium_badge.dart';

/// Container for a chart with title, optional subtitle and actions.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.premium = false,
    this.padding = const EdgeInsets.all(AppSpacing.card),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool premium;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null)
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(child: Text(title!, style: context.h3)),
                          if (premium) ...<Widget>[
                            const SizedBox(width: 8),
                            const PremiumBadge(dense: true),
                          ],
                        ],
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!, style: context.caption),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          if (title != null) const SizedBox(height: AppSpacing.x4),
          child,
        ],
      ),
    );
  }
}

/// Legend row for donut / pie charts.
class ChartLegendRow extends StatelessWidget {
  const ChartLegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    this.percent,
    this.onTap,
    this.icon,
  });

  final Color color;
  final String label;
  final String value;
  final String? percent;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          children: <Widget>[
            Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(palette.ink),
                    ),
                  ),
                  if (percent != null) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(percent!, style: AppTextStyles.caption(palette.tertiary)),
                  ],
                ],
              ),
            ),
            Text(
              value,
              style: AppTextStyles.money(13, color: palette.ink, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
