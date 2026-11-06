import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// ---------------------------------------------------------------------------
/// Financial-health radar: five axes, a smoothed gradient polygon, axis dots and
/// a serif score at the centre.
/// ---------------------------------------------------------------------------
class HealthRadar extends StatelessWidget {
  const HealthRadar({
    super.key,
    required this.labels,
    required this.values,
    required this.score,
    this.size = 260,
    this.caption = 'out of 100',
    this.animation = const Duration(milliseconds: 1100),
  }) : assert(labels.length == values.length);

  final List<String> labels;
  final List<double> values;
  final int score;
  final double size;
  final String caption;
  final Duration animation;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: animation,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          height: size,
          width: size,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: Size.square(size),
                painter: _RadarPainter(
                  labels: labels,
                  values: values,
                  progress: t,
                  grid: palette.divider.withOpacity(palette.isDark ? 0.9 : 1),
                  labelColor: palette.sub,
                  axisColor: palette.tertiary,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${(score * t).round()}',
                    style: AppTextStyles.serif(
                      size: size * 0.155,
                      color: palette.ink,
                      tabularFigures: true,
                    ),
                  ),
                  Text(
                    caption,
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 10.5, letterSpacing: 0.6),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.labels,
    required this.values,
    required this.progress,
    required this.grid,
    required this.labelColor,
    required this.axisColor,
  });

  final List<String> labels;
  final List<double> values;
  final double progress;
  final Color grid;
  final Color labelColor;
  final Color axisColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 3) return;
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = math.min(size.width, size.height) / 2 - 30;
    final start = -math.pi / 2;

    Offset point(int i, double r) {
      final a = start + i * (2 * math.pi / n);
      return center + Offset(math.cos(a) * r, math.sin(a) * r);
    }

    // rings + spokes
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = grid;
    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = point(i, r);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(
        center,
        point(i, radius),
        gridPaint..color = grid.withOpacity(0.6),
      );
    }

    // value polygon (smoothed)
    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        point(i, radius * values[i].clamp(0.06, 1.0) * progress),
    ];
    final smooth = _smoothPolygon(pts);
    canvas.drawPath(
      smooth,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            AppColors.limeA.withOpacity(0.45),
            AppColors.gold.withOpacity(0.30),
            AppColors.violet.withOpacity(0.24),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawPath(
      smooth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = const LinearGradient(
          colors: <Color>[
            AppColors.limeA,
            AppColors.gold,
            AppColors.violet,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // axis dots + labels
    for (var i = 0; i < n; i++) {
      final p = pts[i];
      canvas.drawCircle(
        p,
        4.5,
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawCircle(
        p,
        3,
        Paint()..color = i.isEven ? AppColors.limeB : AppColors.gold,
      );

      final lp = point(i, radius + 18);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontFamily: AppTextStyles.family,
            fontSize: 10.5,
            height: 1.1,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 76);
      final offset = Offset(
        lp.dx - tp.width / 2,
        lp.dy - tp.height / 2,
      );
      tp.paint(canvas, offset);
    }
  }

  Path _smoothPolygon(List<Offset> pts) {
    final path = Path();
    final n = pts.length;
    if (n == 0) return path;
    final mid = Offset(
      (pts[n - 1].dx + pts[0].dx) / 2,
      (pts[n - 1].dy + pts[0].dy) / 2,
    );
    path.moveTo(mid.dx, mid.dy);
    for (var i = 0; i < n; i++) {
      final current = pts[i];
      final next = pts[(i + 1) % n];
      final m = Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      path.quadraticBezierTo(current.dx, current.dy, m.dx, m.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.progress != progress || old.values != values;
}

/// ---------------------------------------------------------------------------
/// Stacked bar chart with dashed guides, rounded caps and an optional
/// highlighted column. Used for the "Total spend" panel.
/// ---------------------------------------------------------------------------
class StackedBarDatum {
  const StackedBarDatum({
    required this.label,
    required this.segments,
    this.sublabel,
  });

  final String label;
  final List<double> segments;
  final String? sublabel;
}

class StackedBarChart extends StatelessWidget {
  const StackedBarChart({
    super.key,
    required this.data,
    required this.colors,
    this.height = 190,
    this.selected,
    this.onSelected,
    this.showValues = true,
    this.maxOverride,
    this.barWidth = 22,
    this.valuePrefix = '',
  });

  final List<StackedBarDatum> data;
  final List<Color> colors;
  final double height;
  final int? selected;
  final ValueChanged<int>? onSelected;
  final bool showValues;
  final double? maxOverride;
  final double barWidth;
  final String valuePrefix;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totals = <double>[
                for (final d in data) d.segments.fold<double>(0, (a, b) => a + b),
              ];
              final maxTotal = maxOverride ??
                  (totals.isEmpty
                      ? 1
                      : totals.reduce(math.max).toDouble());
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (var i = 0; i < data.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSelected == null ? null : () => onSelected!(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            if (showValues && totals[i] > 0)
                              Text(
                                '${valuePrefix}${_short(totals[i] * t)}',
                                style: AppTextStyles.caption(
                                  (selected == null || selected == i)
                                      ? palette.ink
                                      : palette.tertiary,
                                ).copyWith(fontSize: 9.5),
                              ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: (height - 46) * (totals[i] / maxTotal) * t,
                              width: barWidth,
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(barWidth / 2),
                                child: Column(
                                  children: <Widget>[
                                    for (var s =
                                        data[i].segments.length - 1;
                                        s >= 0;
                                        s--)
                                      if (data[i].segments[s] > 0)
                                        Expanded(
                                          flex: (data[i].segments[s] * 100)
                                              .round()
                                              .clamp(1, 100000),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colors[s % colors.length],
                                              gradient:
                                                  selected == null || selected == i
                                                      ? LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: <Color>[
                                                            colors[s % colors.length],
                                                            colors[s % colors.length]
                                                                .withOpacity(0.72),
                                                          ],
                                                        )
                                                      : null,
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data[i].label,
                              style: AppTextStyles.caption(
                                selected == i
                                    ? palette.ink
                                    : palette.tertiary,
                              ).copyWith(
                                fontSize: 10,
                                fontWeight: selected == i
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _short(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return v.toStringAsFixed(0);
  }
}

/// ---------------------------------------------------------------------------
/// Petal donut: each slice is a rounded petal instead of an arc — the flower
/// motif from the tracking reference.
/// ---------------------------------------------------------------------------
class PetalSlice {
  const PetalSlice({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;
}

class PetalDonut extends StatelessWidget {
  const PetalDonut({
    super.key,
    required this.slices,
    this.size = 210,
    this.centerLabel,
    this.centerValue,
    this.selected,
    this.onSelected,
    this.petalLength = 0.62,
  });

  final List<PetalSlice> slices;
  final double size;
  final String? centerLabel;
  final String? centerValue;
  final int? selected;
  final ValueChanged<int>? onSelected;
  final double petalLength;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutBack,
      builder: (context, t, _) {
        return SizedBox(
          height: size,
          width: size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onSelected == null
                ? null
                : (details) {
                    final center = Offset(size / 2, size / 2);
                    final v = details.localPosition - center;
                    var angle =
                        math.atan2(v.dy, v.dx) + math.pi / 2;
                    if (angle < 0) angle += 2 * math.pi;
                    final totalV = slices.fold<double>(
                        0, (a, sl) => a + sl.value);
                    if (totalV <= 0) return;
                    var acc = 0.0;
                    for (var i = 0; i < slices.length; i++) {
                      final sweep =
                          slices[i].value / totalV * 2 * math.pi;
                      if (angle >= acc && angle < acc + sweep) {
                        onSelected!(i);
                        return;
                      }
                      acc += sweep;
                    }
                  },
            child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: Size.square(size),
                painter: _PetalPainter(
                  slices: slices,
                  progress: t.clamp(0.0, 1.0),
                  selected: selected,
                  petalLength: petalLength,
                  backdrop: palette.isDark
                      ? palette.cardAlt
                      : palette.surfaceAlt.withOpacity(0.7),
                ),
              ),
              if (centerValue != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      centerValue!,
                      style: AppTextStyles.serif(
                        size: size * 0.13,
                        color: palette.ink,
                        tabularFigures: true,
                      ),
                    ),
                    if (centerLabel != null)
                      Text(
                        centerLabel!,
                        style: AppTextStyles.caption(palette.tertiary)
                            .copyWith(fontSize: 9.5, letterSpacing: 0.5),
                      ),
                  ],
                ),
            ],
            ),
          ),
        );
      },
    );
  }
}

class _PetalPainter extends CustomPainter {
  _PetalPainter({
    required this.slices,
    required this.progress,
    required this.selected,
    required this.petalLength,
    required this.backdrop,
  });

  final List<PetalSlice> slices;
  final double progress;
  final int? selected;
  final double petalLength;
  final Color backdrop;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final outer = math.min(size.width, size.height) / 2;
    final total = slices.fold<double>(0, (a, s) => a + s.value);
    if (total <= 0) return;
    final inner = outer * (1 - petalLength);
    final gap = 0.06 / slices.length;

    var angle = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final sweep = (slices[i].value / total) * 2 * math.pi * progress;
      final dim = selected != null && selected != i;
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: angle,
          endAngle: angle + sweep,
          colors: <Color>[
            slices[i].color.withOpacity(dim ? 0.30 : 1),
            slices[i].color.withOpacity(dim ? 0.18 : 0.62),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: outer));

      final start = angle + gap;
      final end = angle + sweep - gap;
      if (end > start) {
        final path = Path()
          ..moveTo(
            center.dx + math.cos(start) * inner,
            center.dy + math.sin(start) * inner,
          )
          ..arcTo(
            Rect.fromCircle(center: center, radius: inner),
            start,
            end - start,
            false,
          )
          ..lineTo(
            center.dx + math.cos(end) * outer,
            center.dy + math.sin(end) * outer,
          )
          ..arcTo(
            Rect.fromCircle(center: center, radius: outer),
            end,
            start - end,
            false,
          )
          ..close();
        canvas.drawPath(path, paint);
        if (!dim) {
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Colors.white.withOpacity(0.35),
          );
        }
      }
      angle += sweep;
    }

    // faint core ring
    canvas.drawCircle(
      center,
      inner * 0.94,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = backdrop,
    );
  }

  @override
  bool shouldRepaint(covariant _PetalPainter old) =>
      old.progress != progress || old.selected != selected;
}

/// ---------------------------------------------------------------------------
/// Glowing dual chart: a smooth line over soft bars with a draggable cursor.
/// ---------------------------------------------------------------------------
class GlowActivityChart extends StatefulWidget {
  const GlowActivityChart({
    super.key,
    required this.values,
    this.labels = const <String>[],
    this.height = 180,
    this.accent = AppColors.sunset,
    this.showBars = true,
    this.onChanged,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color accent;
  final bool showBars;
  final ValueChanged<int>? onChanged;

  @override
  State<GlowActivityChart> createState() => _GlowActivityChartState();
}

class _GlowActivityChartState extends State<GlowActivityChart> {
  int? _active;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int indexFor(double dx) {
            if (widget.values.length < 2) return 0;
            final step = width / (widget.values.length - 1);
            return (dx / step).round().clamp(0, widget.values.length - 1);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) {
              setState(() => _active = indexFor(d.localPosition.dx));
              widget.onChanged?.call(_active!);
            },
            onHorizontalDragEnd: (_) {
              setState(() => _active = null);
            },
            onTapDown: (d) {
              setState(() => _active = indexFor(d.localPosition.dx));
              widget.onChanged?.call(_active!);
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 950),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GlowLinePainter(
                          values: widget.values,
                          labels: widget.labels,
                          progress: t,
                          active: _active,
                          accent: widget.accent,
                          showBars: widget.showBars,
                          gridColor: palette.divider,
                          labelColor: palette.tertiary,
                        ),
                      ),
                    ),
                    if (_active != null)
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 0,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: palette.ink,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              _fmt(widget.values[_active!]),
                              style: AppTextStyles.caption(
                                palette.isDark ? palette.surface : Colors.white,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
}

class _GlowLinePainter extends CustomPainter {
  _GlowLinePainter({
    required this.values,
    required this.labels,
    required this.progress,
    required this.active,
    required this.accent,
    required this.showBars,
    required this.gridColor,
    required this.labelColor,
  });

  final List<double> values;
  final List<String> labels;
  final double progress;
  final int? active;
  final Color accent;
  final bool showBars;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final bottom = size.height - (labels.isEmpty ? 6 : 22);
    final maxV = values.reduce(math.max);
    if (maxV <= 0) return;
    final step = values.length > 1 ? size.width / (values.length - 1) : size.width;

    Offset pt(int i) {
      final h = (values[i] / maxV) * (bottom - 12) * progress;
      return Offset(values.length > 1 ? i * step : size.width / 2, bottom - h);
    }

    // dashed baseline
    final dash = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var y = 0; y < 4; y++) {
      final yy = bottom - (bottom / 4) * y;
      for (var x = 0.0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, yy), Offset(x + 4, yy), dash);
      }
    }

    if (showBars) {
      final bw = math.min(14.0, step * 0.42);
      for (var i = 0; i < values.length; i++) {
        final p = pt(i);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(p.dx - bw / 2, p.dy + 8, bw, bottom - p.dy - 8),
          const Radius.circular(6),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                accent.withOpacity(0.22),
                accent.withOpacity(0.03),
              ],
            ).createShader(rect.outerRect),
        );
      }
    }

    final pts = <Offset>[for (var i = 0; i < values.length; i++) pt(i)];
    final smooth = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      smooth.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    smooth.lineTo(pts.last.dx, pts.last.dy);

    final fill = Path.from(smooth)
      ..lineTo(pts.last.dx, bottom)
      ..lineTo(pts.first.dx, bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            accent.withOpacity(0.28),
            accent.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, bottom)),
    );

    // glow pass
    canvas.drawPath(
      smooth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = accent.withOpacity(0.35),
    );
    canvas.drawPath(
      smooth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: <Color>[accent.withOpacity(0.75), accent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, bottom)),
    );

    // cursor
    if (active != null && active! < pts.length) {
      final p = pts[active!];
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, bottom),
        Paint()
          ..color = accent.withOpacity(0.35)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 9, Paint()..color = accent.withOpacity(0.18));
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3, Paint()..color = accent);
    }

    if (labels.isNotEmpty) {
      for (var i = 0; i < labels.length && i < values.length; i++) {
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(
              fontFamily: AppTextStyles.family,
              fontSize: 9.5,
              color: labelColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = values.length > 1 ? i * step : size.width / 2;
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlowLinePainter old) =>
      old.progress != progress ||
      old.active != active ||
      old.values != values ||
      old.accent != accent;
}

/// ---------------------------------------------------------------------------
/// 180° gauge with a dotted outer ring, tick marks and a needle.
/// ---------------------------------------------------------------------------
class ArcGauge extends StatelessWidget {
  const ArcGauge({
    super.key,
    required this.value,
    this.size = 220,
    this.label,
    this.accent = AppColors.violet,
    this.centerText,
  });

  final double value;
  final double size;
  final String? label;
  final Color accent;
  final String? centerText;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          height: size * 0.66,
          width: size,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              CustomPaint(
                size: Size(size, size * 0.66),
                painter: _GaugePainter(
                  value: t,
                  accent: accent,
                  track: palette.divider,
                  dots: palette.tertiary.withOpacity(0.4),
                ),
              ),
              Positioned(
                bottom: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      centerText ??
                          '${(t * 100).round()}',
                      style: AppTextStyles.serif(
                        size: 34,
                        color: palette.ink,
                        tabularFigures: true,
                      ),
                    ),
                    if (label != null)
                      Text(
                        label!,
                        style: AppTextStyles.caption(palette.tertiary)
                            .copyWith(fontSize: 10, letterSpacing: 0.6),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.accent,
    required this.track,
    required this.dots,
  });

  final double value;
  final Color accent;
  final Color track;
  final Color dots;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 6);
    final radius = size.width / 2 - 16;

    // dotted outer ring
    for (var i = 0; i <= 48; i++) {
      final a = math.pi + (i / 48) * math.pi;
      final p = center + Offset(math.cos(a) * (radius + 10), math.sin(a) * (radius + 10));
      canvas.drawCircle(p, 1.2, Paint()..color = dots);
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = math.max(10.0, radius * 0.13);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = track,
    );
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: math.pi,
          endAngle: 2 * math.pi,
          colors: <Color>[accent.withOpacity(0.55), accent],
        ).createShader(rect),
    );

    // needle
    final a = math.pi + math.pi * value;
    final tip = center + Offset(math.cos(a) * (radius - stroke), math.sin(a) * (radius - stroke));
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = accent
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = accent);
    canvas.drawCircle(center, 2.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.accent != accent;
}

/// ---------------------------------------------------------------------------
/// Calendar consistency heatmap: weekday rows × week columns with a dim→bright
/// ramp and rounded cells.
/// ---------------------------------------------------------------------------
class ConsistencyHeatmap extends StatelessWidget {
  const ConsistencyHeatmap({
    super.key,
    required this.intensity,
    this.weeks = 12,
    this.cell = 16,
    this.accent = AppColors.limeB,
    this.weekdayLabels = const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  });

  final Map<DateTime, double> intensity;
  final int weeks;
  final double cell;
  final Color accent;
  final List<String> weekdayLabels;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    // start on the Monday of the first visible week
    final start = end.subtract(Duration(days: weeks * 7 - 1));
    final startMonday = start.subtract(Duration(days: start.weekday - 1));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 2),
            for (final l in weekdayLabels)
              SizedBox(
                height: cell + 5,
                child: Text(
                  l,
                  style: AppTextStyles.caption(palette.tertiary)
                      .copyWith(fontSize: 8.5, height: 1.4),
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var w = 0; w < weeks; w++)
                  Column(
                    children: <Widget>[
                      for (var d = 0; d < 7; d++)
                        _cell(
                          startMonday.add(Duration(days: w * 7 + d)),
                          end,
                          palette,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(DateTime day, DateTime today, AppPalette palette) {
    final v = intensity[DateTime(day.year, day.month, day.day)] ?? 0;
    final future = day.isAfter(today);
    final bg = future
        ? Colors.transparent
        : Color.lerp(
            palette.isDark ? palette.cardAlt : palette.cardAlt,
            accent,
            v.clamp(0.0, 1.0) * 0.9,
          )!;
    return Container(
      margin: const EdgeInsets.only(right: 5, bottom: 5),
      height: cell,
      width: cell,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: v == 0 && !future
            ? Border.all(color: palette.divider)
            : null,
      ),
    );
  }
}
