import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// Primary filled button (accent background).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.height = 54,
    this.background,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final double height;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final enabled = onPressed != null && !loading;
    final bg = background ?? palette.accent;
    final fg = background != null ? Colors.white : palette.onAccent;

    return SizedBox(
      height: height,
      width: expanded ? double.infinity : null,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: palette.isDark ? palette.cardAlt : palette.divider,
          disabledForegroundColor: palette.tertiary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
          textStyle: AppTextStyles.label(fg).copyWith(fontSize: 15, letterSpacing: 0.2),
        ),
        child: loading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 19, color: fg),
                    const SizedBox(width: AppSpacing.x2),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.label(fg).copyWith(fontSize: 15, letterSpacing: 0.2),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary (outlined / surface) button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 54,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return SizedBox(
      height: height,
      width: expanded ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed == null || loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          backgroundColor: palette.isDark ? palette.cardAlt : Colors.white,
          side: BorderSide(color: palette.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: palette.accent),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 19, color: palette.ink),
                    const SizedBox(width: AppSpacing.x2),
                  ],
                  Text(label, style: AppTextStyles.label(palette.ink).copyWith(fontSize: 15)),
                ],
              ),
      ),
    );
  }
}

/// Destructive action button (red on light red).
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.filled = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return SizedBox(
      height: 52,
      width: expanded ? double.infinity : null,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: filled ? palette.expense : palette.expenseBg,
          foregroundColor: filled ? Colors.white : palette.expense,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: filled ? Colors.white : palette.expense),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.label(filled ? Colors.white : palette.expense),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact circular icon button used in app bars and rows.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.filled = true,
    this.size = 42,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filled;
  final double size;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final bg = color ?? (palette.isDark ? palette.cardAlt : Colors.white);
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: filled ? bg : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: size,
            width: size,
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}
