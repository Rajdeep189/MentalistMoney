import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// Rounded cocoa card — the base surface of the whole app.
class PaisaCard extends StatelessWidget {
  const PaisaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.color,
    this.radius = AppRadius.card,
    this.onTap,
    this.border,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final Border? border;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final bg = color ?? palette.card;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: palette.divider.withOpacity(0.35)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: palette.accent.withOpacity(0.08),
          highlightColor: palette.accent.withOpacity(0.05),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Full-width peach pill button with dark brown label.
class PeachButton extends StatelessWidget {
  const PeachButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 58,
    this.loading = false,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;
  final bool loading;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final bg = palette.isDark ? palette.accent : palette.ink;
    final fg = palette.isDark ? palette.onAccent : Colors.white;
    return SizedBox(
      height: height,
      width: expanded ? double.infinity : null,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onPressed == null || loading ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (loading)
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                  )
                else ...<Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.base(
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.1,
                      ).copyWith(color: fg),
                    ),
                  ),
                  if (trailingIcon != null) ...<Widget>[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 20, color: fg),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill segmented control with a peach active segment.
class PaisaSegment<T> extends StatelessWidget {
  const PaisaSegment({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.labelOf,
    this.height = 48,
    this.dense = false,
  });

  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T option)? labelOf;
  final double height;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.divider.withOpacity(palette.isDark ? 0.9 : 0.8)),
      ),
      child: Row(
        children: options.map((option) {
          final selected = option == value;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: selected ? palette.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  labelOf?.call(option) ?? '$option',
                  style: AppTextStyles.base(
                    size: dense ? 12 : 13.5,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.1,
                  ).copyWith(
                    color: selected ? palette.onAccent : palette.sub,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Hand-drawn wavy progress line, like the budget and recurring cards.
class WavyProgress extends StatelessWidget {
  const WavyProgress({
    super.key,
    required this.value,
    this.color,
    this.trackColor,
    this.height = 18,
    this.waves = 7,
  });

  final double value;
  final Color? color;
  final Color? trackColor;
  final double height;
  final int waves;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _WavePainter(
              value: animated,
              color: color ?? palette.ink,
              track: trackColor ?? palette.divider,
              waves: waves,
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.value,
    required this.color,
    required this.track,
    required this.waves,
  });

  final double value;
  final Color color;
  final Color track;
  final int waves;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final amplitude = math.min(mid - 2, 6.0);
    final length = size.width * value;

    Path wave(double from, double to) {
      final path = Path()..moveTo(from, mid);
      if (to <= from) return path;
      final step = (to - from) / (waves * 2);
      var x = from;
      var up = true;
      while (x < to) {
        final next = math.min(x + step, to);
        path.quadraticBezierTo(
          (x + next) / 2,
          up ? mid - amplitude : mid + amplitude,
          next,
          mid,
        );
        up = !up;
        x = next;
      }
      return path;
    }

    canvas.drawPath(
      wave(0, size.width),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = track,
    );
    if (value <= 0) return;
    canvas.drawPath(
      wave(0, length),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Coloured stat tile (peach / olive / green / red) used on dashboards.
class PaisaStatTile extends StatelessWidget {
  const PaisaStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
    this.icon,
    this.valueSize = 22,
    this.onTap,
    this.height,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final double valueSize;
  final VoidCallback? onTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.card - 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 15, color: foreground.withOpacity(0.9)),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 12.5,
                      weight: FontWeight.w600,
                      height: 1.1,
                    ).copyWith(color: foreground.withOpacity(0.85)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: AppTextStyles.serif(size: valueSize, color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-column overview tile with a header row, chevron and free body.
class OverviewTile extends StatelessWidget {
  const OverviewTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.child,
    this.minHeight = 172,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: palette.divider.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 18, color: palette.sub),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 14.5,
                      weight: FontWeight.w600,
                      height: 1.1,
                    ).copyWith(color: palette.ink),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: palette.tertiary),
              ],
            ),
            const SizedBox(height: 14),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

/// Small rounded icon badge with tinted background.
class PaisaIconBadge extends StatelessWidget {
  const PaisaIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
    this.iconSize = 20,
    this.radius = 14,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? context.c.accent;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: inkOn(tone)),
    );
  }

  /// Ink colour that reads on top of [color].
  static Color inkOn(Color color) =>
      color.computeLuminance() > 0.55 ? AppColors.espresso : Colors.white;
}

/// Tiny rounded label used inside list cards ("Monthly", "Expense").
class PaisaChip extends StatelessWidget {
  const PaisaChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.background,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final fg = color ?? palette.sub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? fg.withOpacity(palette.isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.base(
              size: 11,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// Section label with a peach title, used across dashboards.
class PaisaSectionTitle extends StatelessWidget {
  const PaisaSectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: 10, top: 6),
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.serif(size: 19, color: palette.ink),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.divider),
                ),
                child: Text(
                  action!,
                  style: AppTextStyles.caption(palette.onSoft)
                      .copyWith(fontSize: 11.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Phone frame used by onboarding previews.
class PhoneMock extends StatelessWidget {
  const PhoneMock({
    super.key,
    required this.child,
    this.height = 470,
    this.width = 260,
  });

  final Widget child;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(42),
        border: Border.all(color: const Color(0xFFE7D6CC), width: 8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: ColoredBox(color: const Color(0xFFFFFBF8), child: child),
      ),
    );
  }
}
