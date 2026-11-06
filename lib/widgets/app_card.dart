import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// The single card primitive used across the app.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.card),
    this.onTap,
    this.color,
    this.gradient,
    this.border,
    this.radius = AppRadius.card,
    this.margin,
    this.elevated = false,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final bool elevated;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final surface = color ?? palette.card;

    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(
              color: palette.isDark
                  ? palette.divider
                  : palette.divider.withOpacity(0.75),
            ),
        boxShadow: elevated
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(palette.isDark ? 0.28 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: palette.accent.withOpacity(0.06),
          highlightColor: palette.accent.withOpacity(0.04),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Card with a soft violet tint – used for the "Safe to Spend" hero card.
class TintedCard extends StatelessWidget {
  const TintedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x5),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? <Color>[palette.accentSoft, palette.card]
              : <Color>[
                  Color.lerp(palette.accent, Colors.white, 0.88)!,
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: palette.accent.withOpacity(palette.isDark ? 0.35 : 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Dark premium card used for credit cards and the hero net-worth block.
class DarkCard extends StatelessWidget {
  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x5),
    this.onTap,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final highlight = accent ?? palette.accent;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF23242A),
            const Color(0xFF121216),
            Color.lerp(const Color(0xFF0B0B0E), highlight, 0.16)!,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: highlight.withOpacity(0.16),
            blurRadius: 26,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Thin tinted status chip used for labels such as "3x Restaurants".
class TintChip extends StatelessWidget {
  const TintChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.background,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = color ?? palette.accent;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.x2 : AppSpacing.x3,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background ?? tone.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: tone),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.label(tone).copyWith(fontSize: dense ? 11 : 12),
          ),
        ],
      ),
    );
  }
}
