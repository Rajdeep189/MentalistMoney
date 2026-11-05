import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Rounded, animated progress bar with colour states.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
    this.trackColor,
    this.animate = true,
    this.duration = const Duration(milliseconds: 600),
  });

  /// 0..1 (clamped for painting, values > 1 are shown as full).
  final double value;
  final Color? color;
  final double height;
  final Color? trackColor;
  final bool animate;
  final Duration duration;

  static Color colorForRatio(BuildContext context, double ratio) {
    final palette = context.c;
    if (ratio > 0.91) return palette.expense;
    if (ratio > 0.76) return const Color(0xFFF79009);
    if (ratio > 0.5) return const Color(0xFFFDB022);
    return palette.income;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final ratio = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    final tone = color ?? colorForRatio(context, value);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: trackColor ?? (palette.isDark ? palette.cardAlt : palette.surfaceAlt),
        child: animate
            ? TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: ratio),
                duration: duration,
                curve: Curves.easeOutCubic,
                builder: (context, animated, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animated.clamp(0.0, 1.0).toDouble(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tone,
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                ),
              )
            : FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Animated circular progress ring with optional centre child.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 76,
    this.strokeWidth = 8,
    this.color,
    this.trackColor,
    this.child,
    this.animate = true,
    this.backgroundGradient = false,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? child;
  final bool animate;
  final bool backgroundGradient;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = color ?? palette.accent;
    final ratio = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();

    final painter = _RingPainter(
      ratio: ratio,
      color: tone,
      trackColor: trackColor ?? (palette.isDark ? palette.cardAlt : palette.surfaceAlt),
      strokeWidth: strokeWidth,
      gradient: backgroundGradient,
    );

    return SizedBox(
      height: size,
      width: size,
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) => CustomPaint(
                painter: _RingPainter(
                  ratio: animated,
                  color: tone,
                  trackColor:
                      trackColor ?? (palette.isDark ? palette.cardAlt : palette.surfaceAlt),
                  strokeWidth: strokeWidth,
                  gradient: backgroundGradient,
                ),
                child: Center(child: child),
              ),
            )
          : CustomPaint(
              painter: painter,
              child: Center(child: child),
            ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.ratio,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.gradient,
  });

  final double ratio;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(centre, radius, track);

    if (ratio <= 0) return;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient
          ? SweepGradient(
              colors: <Color>[color.withOpacity(0.55), color],
              transform: const GradientRotation(-math.pi / 2),
            ).createShader(rect)
          : null
      ..color = color;

    // soft outer glow
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * ratio,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..color = color.withOpacity(0.45),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * ratio,
      false,
      progressPaint,
    );
    // leading spark
    final angle = -math.pi / 2 + 2 * math.pi * ratio;
    final tip = centre +
        Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    canvas.drawCircle(tip, strokeWidth * 0.42, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Small tick-style indicator (used in the achievements list).
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.total,
    required this.completed,
    this.color,
    this.size = 8,
    this.spacing = 4,
  });

  final int total;
  final int completed;
  final Color? color;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = color ?? palette.accent;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List<Widget>.generate(
        total,
        (index) => Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < completed ? tone : palette.divider,
          ),
        ),
      ),
    );
  }
}

/// Label + percent + bar used in many lists.
class LabelledProgress extends StatelessWidget {
  const LabelledProgress({
    super.key,
    required this.label,
    required this.value,
    this.trailingText,
    this.color,
    this.height = 8,
    this.caption,
  });

  final String label;
  final double value;
  final String? trailingText;
  final Color? color;
  final double height;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: AppTextStyles.label(palette.ink))),
            Text(
              trailingText ?? '${(value * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.label(palette.sub),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(value: value, height: height, color: color),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(caption!, style: AppTextStyles.caption(palette.tertiary)),
          ),
      ],
    );
  }
}
