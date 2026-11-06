import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// Soft, slowly drifting aurora blobs that sit behind hero content.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.intensity = 1,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double intensity;
  final EdgeInsets padding;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value * 2 * math.pi;
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _AuroraPainter(
                    palette: palette,
                    t: t,
                    intensity: widget.intensity,
                  ),
                ),
              ),
              Padding(padding: widget.padding, child: child),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.palette,
    required this.t,
    required this.intensity,
  });

  final AppPalette palette;
  final double t;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = <List<Object>>[
      <Object>[AppColors.limeA, 0.42, 0.22, 0.55],
      <Object>[palette.violet, 0.85, 0.30, 0.46],
      <Object>[AppColors.tangerine, 0.30, 0.90, 0.40],
    ];
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < blobs.length; i++) {
      final color = blobs[i][0] as Color;
      final baseX = blobs[i][1] as double;
      final baseY = blobs[i][2] as double;
      final scale = blobs[i][3] as double;
      final phase = t + i * 2.1;
      final center = Offset(
        size.width * (baseX + 0.10 * math.sin(phase)),
        size.height * (baseY + 0.12 * math.cos(phase * 0.8)),
      );
      final radius = size.longestSide * scale * 0.75;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withOpacity((palette.isDark ? 0.34 : 0.30) * intensity),
            color.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
    // paper grain / vignette
    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          palette.surface.withOpacity(palette.isDark ? 0.20 : 0.45),
          palette.surface.withOpacity(0),
          palette.surface.withOpacity(palette.isDark ? 0.35 : 0.5),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.palette != palette;
}

/// Adds a diagonal metallic sheen that sweeps across [child] forever.
class ShineSweep extends StatefulWidget {
  const ShineSweep({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 3800),
    this.opacity = 0.5,
    this.borderRadius,
  });

  final Widget child;
  final Duration period;
  final double opacity;
  final BorderRadius? borderRadius;

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: <Widget>[
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = _c.value;
                  return FractionallySizedBox(
                    alignment: Alignment(-1.6 + t * 3.2, 0),
                    widthFactor: 0.42,
                    child: Transform.rotate(
                      angle: 0.32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(widget.opacity * 0.55),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted translucent panel used for nav bars, sheets and floating cards.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.radius = AppRadius.card,
    this.blur = 18,
    this.tint,
    this.border,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final Color? tint;
  final Color? border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? palette.glass,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border ?? palette.glassBorder),
            boxShadow: shadow
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(palette.isDark ? 0.45 : 0.06),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small uppercase eyebrow above a serif headline.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color, this.icon});

  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final c = color ?? palette.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 6),
        ],
        Text(text.toUpperCase(), style: AppTextStyles.overline(c)),
      ],
    );
  }
}

/// Editorial section header: eyebrow + serif title + optional action.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.x3),
  });

  final String title;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (eyebrow != null) ...<Widget>[
                  Eyebrow(eyebrow!),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: AppTextStyles.h2(palette.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: palette.ink,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    actionLabel!,
                    style: AppTextStyles.label(palette.sub)
                        .copyWith(fontSize: 12.5, letterSpacing: 0.2),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: palette.sub),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact stat tile inspired by the reference analytics screens.
class LuxeStat extends StatelessWidget {
  const LuxeStat({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.tint,
    this.accent = false,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final Color? tint;
  final bool accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final base = tint ?? palette.accent;
    final bg = accent
        ? base
        : (palette.isDark ? palette.card : palette.card);
    final fg = accent
        ? (base.computeLuminance() > 0.6 ? Colors.black : Colors.white)
        : palette.ink;
    final muted = accent ? fg.withOpacity(0.72) : palette.sub;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: accent ? Colors.transparent : palette.divider,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent
                  ? base.withOpacity(0.35)
                  : Colors.black.withOpacity(palette.isDark ? 0.28 : 0.04),
              blurRadius: accent ? 20 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: accent
                          ? fg.withOpacity(0.16)
                          : base.withOpacity(palette.isDark ? 0.22 : 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 15, color: accent ? fg : palette.ink),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(muted)
                        .copyWith(fontSize: 11, letterSpacing: 0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTextStyles.serif(size: 24, color: fg),
              ),
            ),
            if (caption != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(muted).copyWith(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// MoneyMan monogram: a metallic shield with a serif `M`, an inner graphite
/// ring and a lime hairline that catches the light.
class MetallicMark extends StatelessWidget {
  const MetallicMark({super.key, this.size = 44, this.animated = true});

  final double size;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.metalGradient,
              borderRadius: BorderRadius.circular(size * 0.30),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.16),
                ),
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.35),
                  blurRadius: size * 0.28,
                  spreadRadius: -size * 0.1,
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(size * 0.09),
            decoration: BoxDecoration(
              gradient: AppColors.graphiteGradient,
              borderRadius: BorderRadius.circular(size * 0.24),
            ),
          ),
          Text(
            'M',
            style: AppTextStyles.serif(size: size * 0.52, color: AppColors.limeA),
          ),
          Positioned(
            right: size * 0.13,
            top: size * 0.13,
            child: Container(
              height: size * 0.12,
              width: size * 0.12,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
    if (!animated) return mark;
    return ShineSweep(
      period: const Duration(milliseconds: 3400),
      opacity: 0.55,
      borderRadius: BorderRadius.circular(size * 0.30),
      child: mark,
    );
  }
}

/// Wordmark used at the very top of Home: serif name + metallic monogram.
class LuxeWordmark extends StatelessWidget {
  const LuxeWordmark({super.key, this.subtitle, this.trailing});

  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      children: <Widget>[
        const MetallicMark(size: 46),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ShineSweep(
                period: const Duration(milliseconds: 5200),
                opacity: 0.5,
                child: Text(
                  'MoneyMan',
                  style: AppTextStyles.wordmark(palette.ink, size: 28),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(palette.tertiary)
                      .copyWith(fontSize: 11.5, letterSpacing: 0.4),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Animated "Made by Superman" signature plaque for the end of Settings.
class MadeBySuperman extends StatefulWidget {
  const MadeBySuperman({super.key});

  @override
  State<MadeBySuperman> createState() => _MadeBySupermanState();
}

class _MadeBySupermanState extends State<MadeBySuperman>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final glow = 0.35 + 0.35 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
        return Container(
          padding: const EdgeInsets.all(AppSpacing.x5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF141418),
                Color(0xFF23242A),
                Color(0xFF0B0B0E),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.gold.withOpacity(0.28)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.gold.withOpacity(glow * 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ShineSweep(
            period: const Duration(milliseconds: 3000),
            opacity: 0.28,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            child: Column(
              children: <Widget>[
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.metalGradient,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.4),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF0C0C0E),
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text(
                  'Crafted with precision',
                  style: AppTextStyles.overline(AppColors.gold)
                      .copyWith(letterSpacing: 2.2),
                ),
                const SizedBox(height: AppSpacing.x2),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment(-1 + t * 2, 0),
                    end: Alignment(0 + t * 2, 0),
                    colors: const <Color>[
                      Color(0xFFC9A96A),
                      Color(0xFFFFF3D6),
                      Color(0xFFC9A96A),
                      Color(0xFF8A6E3D),
                    ],
                  ).createShader(rect),
                  child: Text(
                    'Made by Superman',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.serif(size: 25, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'MoneyMan · designed & built with obsessive care',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(Colors.white.withOpacity(0.55))
                      .copyWith(fontSize: 11.5),
                ),
                const SizedBox(height: AppSpacing.x4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (var i = 0; i < 5; i++)
                      Transform.translate(
                        offset: Offset(
                          0,
                          -3 * math.sin(t * 2 * math.pi + i * 0.7),
                        ),
                        child: Icon(
                          i.isEven ? Icons.auto_awesome : Icons.star_rounded,
                          size: 14,
                          color: AppColors.gold.withOpacity(0.85),
                        ),
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
