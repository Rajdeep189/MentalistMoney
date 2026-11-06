import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/money.dart';
import '../data/models/models.dart';

/// Vivid tile colours used by the reference app for category and account art.
class TileColors {
  TileColors._();

  static const Color blue = Color(0xFF3B82F6);
  static const Color indigo = Color(0xFF4F5BD5);
  static const Color green = Color(0xFF22C55E);
  static const Color teal = Color(0xFF14B8A6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color purple = Color(0xFFA855F7);
  static const Color pink = Color(0xFFEC4899);
  static const Color red = Color(0xFFEF4444);
  static const Color sky = Color(0xFF38BDF8);
  static const Color lime = Color(0xFF84CC16);
  static const Color coral = Color(0xFFFF6B5E);

  static const List<Color> all = <Color>[
    blue,
    indigo,
    green,
    teal,
    amber,
    purple,
    pink,
    red,
    sky,
    lime,
    coral,
  ];

  static Color forKey(String key) =>
      all[key.hashCode.abs() % all.length];
}

/// Deep tinted card backgrounds used on stats and reminder cards.
class TileTints {
  TileTints._();

  static const Color income = Color(0xFF1B3A2B);
  static const Color incomeDeep = Color(0xFF123024);
  static const Color expense = Color(0xFF3D201D);
  static const Color expenseDeep = Color(0xFF341A18);
  static const Color blue = Color(0xFF25324A);
  static const Color info = Color(0xFF3B2A22);
}

/// A rounded dark sheet with a title, intro and a list of icon + text blocks,
/// pinned behind a peach "Got it" button. Used by every "How X Works" screen.
class InfoSheet extends StatelessWidget {
  const InfoSheet({
    super.key,
    required this.title,
    required this.intro,
    required this.sections,
    this.buttonLabel = 'Got it',
    this.onDone,
  });

  final String title;
  final String intro;
  final List<InfoSection> sections;
  final String buttonLabel;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final dark = palette.isDark;
    final bg = dark ? const Color(0xFF2E1D17) : Colors.white;
    final ink = dark ? Colors.white : AppColors.espresso;
    final muted = dark ? const Color(0xFFD9C3B8) : const Color(0xFF6B4E42);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: ColoredBox(
        color: bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.serif(size: 24, color: ink),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (onDone != null) {
                        onDone!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    icon: Icon(Icons.close_rounded, size: 22, color: muted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                children: <Widget>[
                  Text(
                    intro,
                    style: AppTextStyles.body(muted).copyWith(height: 1.55),
                  ),
                  const SizedBox(height: 18),
                  for (final section in sections) ...<Widget>[
                    _InfoSectionTile(section: section, ink: ink, muted: muted),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                8,
                22,
                18 + MediaQuery.of(context).padding.bottom,
              ),
              child: SizedBox(
                height: 58,
                width: double.infinity,
                child: Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      if (onDone != null) {
                        onDone!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    child: Center(
                      child: Text(
                        buttonLabel,
                        style: AppTextStyles.base(
                          size: 16,
                          weight: FontWeight.w700,
                          height: 1.1,
                        ).copyWith(color: AppColors.espresso),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoSection {
  const InfoSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _InfoSectionTile extends StatelessWidget {
  const _InfoSectionTile({
    required this.section,
    required this.ink,
    required this.muted,
  });

  final InfoSection section;
  final Color ink;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF6B4530),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(section.icon, size: 19, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                section.title,
                style: AppTextStyles.base(
                  size: 15,
                  weight: FontWeight.w700,
                  height: 1.2,
                ).copyWith(color: ink),
              ),
              const SizedBox(height: 5),
              Text(
                section.body,
                style: AppTextStyles.body(muted).copyWith(height: 1.5, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular progress ring with a rounded cap and a small wavy tail, as used on
/// budget cards and the budgets header.
class RingGauge extends StatelessWidget {
  const RingGauge({
    super.key,
    required this.value,
    this.size = 96,
    this.strokeWidth = 10,
    this.color,
    this.trackColor,
    this.center,
    this.waveTail = true,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? center;
  final bool waveTail;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = color ?? palette.income;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => SizedBox(
        height: size,
        width: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: animated,
            color: tone,
            track: trackColor ??
                (palette.isDark ? Colors.white.withOpacity(0.10) : palette.divider),
            strokeWidth: strokeWidth,
            waveTail: waveTail,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.strokeWidth,
    required this.waveTail,
  });

  final double value;
  final Color color;
  final Color track;
  final double strokeWidth;
  final bool waveTail;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, paint..color = track);
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      paint..color = color,
    );
    if (!waveTail || value >= 0.995) return;

    final endAngle = -math.pi / 2 + math.pi * 2 * value;
    final start = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    final tail = Path()..moveTo(start.dx, start.dy);
    final normal = Offset(math.cos(endAngle), math.sin(endAngle));
    final tangent = Offset(-math.sin(endAngle), math.cos(endAngle));
    for (var i = 1; i <= 3; i++) {
      final sign = i.isOdd ? 1.0 : -1.0;
      tail.quadraticBezierTo(
        start.dx + normal.dx * 8 * i + tangent.dx * 4 * i,
        start.dy + normal.dy * 8 * i + tangent.dy * 4 * i + 4 * sign,
        start.dx + normal.dx * 8 * i,
        start.dy + normal.dy * 8 * i,
      );
    }
    canvas.drawPath(
      tail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.85
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Horizontal pastel tile: icon square, small label and a bold figure.
class PastelSummaryTile extends StatelessWidget {
  const PastelSummaryTile({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
    required this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: foreground),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppTextStyles.base(
                    size: 12,
                    weight: FontWeight.w600,
                    height: 1.1,
                  ).copyWith(color: foreground.withOpacity(0.85)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTextStyles.base(
                      size: 16,
                      weight: FontWeight.w700,
                      height: 1.1,
                    ).copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Full-width status row (On Track / Warning / Exceeded) with a circular icon.
class StatusPillRow extends StatelessWidget {
  const StatusPillRow({
    super.key,
    required this.label,
    required this.count,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final int count;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: foreground.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppTextStyles.base(
                    size: 12,
                    weight: FontWeight.w600,
                    height: 1.1,
                  ).copyWith(color: foreground.withOpacity(0.85)),
                ),
                const SizedBox(height: 1),
                Text(
                  '$count',
                  style: AppTextStyles.base(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ).copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Month heatmap with tinted day cells, matching the home calendar card.
class MonthHeatmap extends StatelessWidget {
  const MonthHeatmap({
    super.key,
    required this.month,
    required this.totals,
    this.today,
    this.onDay,
    this.maxCells = 42,
  });

  final DateTime month;
  final Map<int, int> totals;
  final DateTime? today;
  final ValueChanged<int>? onDay;
  final int maxCells;

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Reference layout starts weeks on Monday.
    final leading = (first.weekday - DateTime.monday) % 7;
    final now = today ?? DateTime.now();
    final peak = totals.values.isEmpty
        ? 1
        : totals.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: <Widget>[
        Text(
          '${_months[month.month - 1]} ${month.year}',
          style: AppTextStyles.base(
            size: 15,
            weight: FontWeight.w700,
            height: 1.1,
          ).copyWith(color: palette.sub),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.05,
          children: <Widget>[
            for (var i = 0; i < leading; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              Builder(
                builder: (context) {
                  final amount = totals[day] ?? 0;
                  final ratio = amount == 0 ? 0.0 : (amount / peak).clamp(0.15, 1.0);
                  final isToday =
                      now.year == month.year && now.month == month.month && now.day == day;
                  return GestureDetector(
                    onTap: onDay == null ? null : () => onDay!(day),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: amount == 0
                            ? (palette.isDark
                                ? Colors.white.withOpacity(0.05)
                                : palette.surfaceAlt)
                            : palette.accent.withOpacity(0.18 + ratio * 0.62),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && amount == 0
                            ? Border.all(color: palette.accent, width: 1.4)
                            : null,
                      ),
                      child: Text(
                        '$day',
                        style: AppTextStyles.base(
                          size: 12,
                          weight: FontWeight.w600,
                          height: 1.1,
                        ).copyWith(
                          color: amount > 0
                              ? (ratio > 0.5
                                  ? AppColors.espresso
                                  : palette.ink)
                              : palette.tertiary,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Multi-series trend chart: previous month (dashed grey), this month (solid
/// peach) and upcoming projections (dashed olive), with axis labels.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.previous,
    required this.current,
    required this.upcoming,
    this.height = 210,
    this.startDay = 1,
    this.endDay = 30,
    this.today,
    this.prefix = '\$',
  });

  final List<double> previous;
  final List<double> current;
  final List<double> upcoming;
  final double height;
  final int startDay;
  final int endDay;
  final int? today;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final marked = today ?? DateTime.now().day;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _Legend(
              label: 'Last month',
              color: palette.tertiary,
              dashed: true,
            ),
            const SizedBox(width: 14),
            _Legend(label: 'This month', color: palette.accent),
            const SizedBox(width: 14),
            _Legend(
              label: 'Upcoming',
              color: const Color(0xFFBFD07A),
              dashed: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(
              previous: previous,
              current: current,
              upcoming: upcoming,
              startDay: startDay,
              endDay: endDay,
              today: marked,
              prefix: prefix,
              ink: palette.tertiary,
              grid: palette.divider.withOpacity(0.55),
              previousColor: palette.tertiary,
              currentColor: palette.accent,
              upcomingColor: const Color(0xFFBFD07A),
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color, this.dashed = false});

  final String label;
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 16,
          height: 6,
          child: CustomPaint(
            painter: _LineSwatchPainter(color: color, dashed: dashed),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption(context.c.sub).copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}

class _LineSwatchPainter extends CustomPainter {
  _LineSwatchPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (!dashed) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }
    for (var x = 0.0; x < size.width; x += 5) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 3, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineSwatchPainter old) =>
      old.color != color || old.dashed != dashed;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.previous,
    required this.current,
    required this.upcoming,
    required this.startDay,
    required this.endDay,
    required this.today,
    required this.prefix,
    required this.ink,
    required this.grid,
    required this.previousColor,
    required this.currentColor,
    required this.upcomingColor,
  });

  final List<double> previous;
  final List<double> current;
  final List<double> upcoming;
  final int startDay;
  final int endDay;
  final int today;
  final String prefix;
  final Color ink;
  final Color grid;
  final Color previousColor;
  final Color currentColor;
  final Color upcomingColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0;
    const bottom = 22.0;
    final chart = Rect.fromLTRB(left, 6, size.width, size.height - bottom);
    if (chart.width <= 0) return;

    final all = <double>[...previous, ...current, ...upcoming];
    var maxV = all.isEmpty ? 1.0 : all.reduce((a, b) => a > b ? a : b);
    var minV = 0.0;
    if (all.isNotEmpty && all.reduce((a, b) => a < b ? a : b) < 0) {
      minV = all.reduce((a, b) => a < b ? a : b);
    }
    maxV = maxV == minV ? maxV + 1 : maxV;
    final span = maxV - minV;

    double yFor(double value) =>
        chart.bottom - ((value - minV) / span) * chart.height;
    double xFor(num day) =>
        chart.left + ((day - startDay) / (endDay - startDay)) * chart.width;

    // horizontal grid + y labels
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    const steps = 5;
    for (var i = 0; i <= steps; i++) {
      final value = minV + span * i / steps;
      final y = yFor(value);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final label = _axisLabel(value);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: ink, fontSize: 10, fontFamily: AppTextStyles.family),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chart.left - tp.width - 6, y - tp.height / 2));
    }

    // x labels
    final tickDays = <int>[
      startDay,
      startDay + 5,
      startDay + 10,
      startDay + 15,
      startDay + 20,
      startDay + 25,
    ];
    for (final day in tickDays) {
      if (day > endDay) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: '$day',
          style: TextStyle(color: ink, fontSize: 10, fontFamily: AppTextStyles.family),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xFor(day) - tp.width / 2, chart.bottom + 6));
    }

    void drawSeries(List<double> values, Color color, bool dashed, {bool fill = false}) {
      if (values.length < 2) return;
      final step = (endDay - startDay) / (values.length - 1);
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final point = Offset(xFor(startDay + step * i), yFor(values[i]));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      if (fill) {
        final area = Path.from(path)
          ..lineTo(chart.right, chart.bottom)
          ..lineTo(chart.left, chart.bottom)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[color.withOpacity(0.28), color.withOpacity(0.02)],
            ).createShader(chart),
        );
      }
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      if (dashed) {
        _drawDashed(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    }

    drawSeries(previous, previousColor, true);
    drawSeries(upcoming, upcomingColor, true);
    drawSeries(current, currentColor, false, fill: true);

    // today marker
    final todayX = xFor(today);
    final dash = Paint()
      ..color = ink.withOpacity(0.5)
      ..strokeWidth = 1;
    for (var y = chart.top; y < chart.bottom; y += 6) {
      canvas.drawLine(Offset(todayX, y), Offset(todayX, math.min(y + 3, chart.bottom)), dash);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 6, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 5;
      }
    }
  }

  String _axisLabel(double value) {
    if (value.abs() >= 100000) return '${prefix}${(value / 100000).toStringAsFixed(0)}L';
    if (value.abs() >= 1000) return '${prefix}${(value / 1000).toStringAsFixed(0)}K';
    return '${prefix}${value.toStringAsFixed(0)}';
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => true;
}

/// Card with an icon + title header row and an optional chevron.
class PaisaSectionCard extends StatelessWidget {
  const PaisaSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.divider.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: palette.sub),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.base(
                      size: 18,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: palette.tertiary),
              ],
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Upcoming / recent transaction row with a coloured icon tile, meta line,
/// tag chips and a two-tone amount.
class PaisaTxnCard extends StatelessWidget {
  const PaisaTxnCard({
    super.key,
    required this.txn,
    this.category,
    this.accountName,
    this.toAccountName,
    this.onTap,
    this.showTime = true,
  });

  final Txn txn;
  final Category? category;
  final String? accountName;
  final String? toAccountName;
  final VoidCallback? onTap;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final title = (txn.note != null && txn.note!.trim().isNotEmpty)
        ? txn.note!.trim()
        : (category?.name ?? (txn.type == kTypeTransfer ? 'Transfer' : 'Transaction'));
    final tone = txn.type == kTypeIncome
        ? TileColors.green
        : txn.type == kTypeTransfer
            ? palette.transfer
            : TileColors.forKey(category?.name ?? 'expense');
    final icon = txn.type == kTypeTransfer
        ? Icons.swap_horiz_rounded
        : (category == null ? Icons.category_rounded : AppIconsFallback.iconFor(category!));
    final amountTone = txn.type == kTypeIncome
        ? palette.income
        : txn.type == kTypeTransfer
            ? palette.transfer
            : palette.expense;
    final meta = <String>[
      Fmt.time(txn.date),
      Fmt.date(txn.date),
      if (accountName != null) '🏦 $accountName',
      if (txn.type == kTypeTransfer && toAccountName != null) '→ $toAccountName',
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.divider.withOpacity(0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 16,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 11.5, height: 1.35),
                  ),
                  if (txn.tagNames.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: <Widget>[
                        for (final tag in txn.tagNames.take(3))
                          _TagChip(label: tag),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${txn.type == kTypeIncome ? '+' : txn.type == kTypeTransfer ? '' : '−'}${Fmt.money(txn.amount)}',
                  style: AppTextStyles.money(
                    15,
                    color: amountTone,
                    weight: FontWeight.w700,
                    serifFace: false,
                  ),
                ),
                if (txn.type == kTypeTransfer)
                  Text(
                    Fmt.money(txn.amount, forceCompact: true),
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 10.5),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = TileColors.all[label.hashCode.abs() % TileColors.all.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.label_rounded, size: 10, color: tone),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.base(
              size: 10.5,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: palette.isDark ? Colors.white : tone),
          ),
        ],
      ),
    );
  }
}

/// Income / expense comparison card used on reports and account detail.
class DeltaStatCard extends StatelessWidget {
  const DeltaStatCard({
    super.key,
    required this.label,
    required this.amount,
    required this.delta,
    required this.income,
    this.previous,
  });

  final String label;
  final int amount;
  final double delta;
  final bool income;
  final int? previous;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tint = income ? TileTints.income : TileTints.expense;
    final dot = income ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.isDark ? tint : (income ? AppColors.mint : AppColors.blush),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.base(
                    size: 13,
                    weight: FontWeight.w600,
                    height: 1.1,
                  ).copyWith(color: palette.sub),
                ),
              ),
              Icon(
                delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: income ? palette.income : palette.expense,
              ),
              Text(
                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
                style: AppTextStyles.caption(
                  income ? palette.income : palette.expense,
                ).copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.money(amount),
              style: AppTextStyles.serif(size: 20, color: palette.ink),
            ),
          ),
          if (previous != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'was ${Fmt.money(previous!, forceCompact: true)}',
              style: AppTextStyles.caption(palette.tertiary).copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rounded toggle row used on the budget detail screen.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.divider.withOpacity(0.65)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.base(
                    size: 15,
                    weight: FontWeight.w600,
                    height: 1.15,
                  ).copyWith(color: palette.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption(palette.tertiary)
                      .copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: palette.accent,
          ),
        ],
      ),
    );
  }
}

/// Small helper that maps a category to an icon, falling back to a tag icon.
class AppIconsFallback {
  AppIconsFallback._();

  static IconData iconFor(Category category) {
    switch (category.name.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'bills & utilities':
        return Icons.receipt_long_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
