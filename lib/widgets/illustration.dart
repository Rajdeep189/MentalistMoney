import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum IllustrationKind {
  onboardingTrack,
  onboardingAccounts,
  onboardingGoals,
  onboardingPrivate,
  wallet,
  chart,
  target,
  bills,
  premium,
  achievements,
  backup,
  search,
  split,
  success,
}

/// Original flat geometric illustrations drawn with a CustomPainter so the app
/// ships no stock imagery and stays crisp at any size.
class AppIllustration extends StatelessWidget {
  const AppIllustration({
    super.key,
    required this.kind,
    this.size = 160,
  });

  final IllustrationKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: _IllustrationPainter(kind: kind, palette: palette),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter({required this.kind, required this.palette});

  final IllustrationKind kind;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final accent = palette.accent;
    final ink = palette.isDark ? Colors.white : AppColors.ink;
    final soft = accent.withOpacity(0.14);
    final softAlt = accent.withOpacity(0.08);
    final green = palette.income;
    final blue = palette.transfer;
    final amber = palette.warning;

    Paint fill(Color color) => Paint()..color = color;
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Shared backdrop.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s),
        Radius.circular(s * 0.28),
      ),
      fill(softAlt),
    );

    switch (kind) {
      case IllustrationKind.onboardingTrack:
        // Receipt + rows
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.24, s * 0.18, s * 0.5, s * 0.64),
          Radius.circular(s * 0.08),
        );
        canvas.drawRRect(rect, fill(Colors.white));
        canvas.drawRRect(rect, stroke(accent.withOpacity(0.25), s * 0.012));
        for (var i = 0; i < 3; i++) {
          final y = s * (0.32 + i * 0.16);
          canvas.drawCircle(Offset(s * 0.34, y), s * 0.032, fill(i == 0 ? accent : soft));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(s * 0.42, y - s * 0.02, s * (0.2 - i * 0.03), s * 0.035),
              Radius.circular(s * 0.02),
            ),
            fill(i == 0 ? accent.withOpacity(0.55) : palette.divider),
          );
        }
        canvas.drawCircle(Offset(s * 0.76, s * 0.72), s * 0.15, fill(accent));
        // plus
        canvas.drawLine(Offset(s * 0.69, s * 0.72), Offset(s * 0.83, s * 0.72),
            stroke(Colors.white, s * 0.022));
        canvas.drawLine(Offset(s * 0.76, s * 0.65), Offset(s * 0.76, s * 0.79),
            stroke(Colors.white, s * 0.022));
        break;

      case IllustrationKind.onboardingAccounts:
        // Three stacked cards
        for (var i = 2; i >= 0; i--) {
          final top = s * (0.26 + i * 0.12);
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(s * (0.2 + i * 0.04), top, s * 0.56, s * 0.3),
            Radius.circular(s * 0.07),
          );
          canvas.drawRRect(rect, fill(i == 0 ? Colors.white : palette.divider.withOpacity(0.85)));
          canvas.drawRRect(rect, stroke(accent.withOpacity(0.2), s * 0.01));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(s * (0.26 + i * 0.04), top + s * 0.06, s * 0.14, s * 0.09),
              Radius.circular(s * 0.02),
            ),
            fill(accent.withOpacity(i == 0 ? 0.75 : 0.35)),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(s * (0.26 + i * 0.04), top + s * 0.2, s * 0.3, s * 0.03),
              Radius.circular(s * 0.02),
            ),
            fill(palette.divider),
          );
        }
        canvas.drawCircle(Offset(s * 0.78, s * 0.3), s * 0.06, fill(green));
        break;

      case IllustrationKind.onboardingGoals:
        // Progress bars + target ring
        for (var i = 0; i < 3; i++) {
          final y = s * (0.3 + i * 0.14);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(s * 0.18, y, s * 0.44, s * 0.07),
              Radius.circular(s * 0.035),
            ),
            fill(palette.divider),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(s * 0.18, y, s * (0.44 - i * 0.1), s * 0.07),
              Radius.circular(s * 0.035),
            ),
            fill(i == 1 ? green : accent),
          );
        }
        canvas.drawCircle(Offset(s * 0.72, s * 0.66), s * 0.17, fill(Colors.white));
        canvas.drawCircle(
          Offset(s * 0.72, s * 0.66),
          s * 0.17,
          stroke(accent.withOpacity(0.3), s * 0.02),
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(s * 0.72, s * 0.66), radius: s * 0.17),
          -math.pi / 2,
          math.pi * 1.25,
          false,
          stroke(accent, s * 0.03),
        );
        canvas.drawCircle(Offset(s * 0.72, s * 0.66), s * 0.045, fill(ink));
        break;

      case IllustrationKind.onboardingPrivate:
        // Lock + shield
        final shield = Path()
          ..moveTo(s * 0.5, s * 0.16)
          ..lineTo(s * 0.8, s * 0.28)
          ..quadraticBezierTo(s * 0.8, s * 0.62, s * 0.5, s * 0.84)
          ..quadraticBezierTo(s * 0.2, s * 0.62, s * 0.2, s * 0.28)
          ..close();
        canvas.drawPath(shield, fill(Colors.white));
        canvas.drawPath(shield, stroke(accent.withOpacity(0.28), s * 0.015));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.4, s * 0.44, s * 0.2, s * 0.18),
            Radius.circular(s * 0.04),
          ),
          fill(accent),
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(s * 0.5, s * 0.44), radius: s * 0.075),
          math.pi,
          math.pi,
          false,
          stroke(accent, s * 0.03),
        );
        canvas.drawCircle(Offset(s * 0.5, s * 0.52), s * 0.018, fill(Colors.white));
        break;

      case IllustrationKind.wallet:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.16, s * 0.3, s * 0.68, s * 0.42),
          Radius.circular(s * 0.09),
        );
        canvas.drawRRect(rect, fill(Colors.white));
        canvas.drawRRect(rect, stroke(accent.withOpacity(0.25), s * 0.012));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.52, s * 0.42, s * 0.32, s * 0.18),
            Radius.circular(s * 0.06),
          ),
          fill(accent.withOpacity(0.16)),
        );
        canvas.drawCircle(Offset(s * 0.6, s * 0.51), s * 0.03, fill(accent));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.16, s * 0.28, s * 0.34, s * 0.1),
            Radius.circular(s * 0.05),
          ),
          fill(accent.withOpacity(0.5)),
        );
        break;

      case IllustrationKind.chart:
        final bars = <double>[0.3, 0.55, 0.42, 0.75, 0.6];
        for (var i = 0; i < bars.length; i++) {
          final height = s * bars[i] * 0.55;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                s * (0.2 + i * 0.13),
                s * 0.78 - height,
                s * 0.08,
                height,
              ),
              Radius.circular(s * 0.04),
            ),
            fill(i == 3 ? accent : accent.withOpacity(0.28)),
          );
        }
        canvas.drawLine(
          Offset(s * 0.16, s * 0.78),
          Offset(s * 0.84, s * 0.78),
          stroke(palette.divider, s * 0.015),
        );
        break;

      case IllustrationKind.target:
        for (var i = 3; i >= 0; i--) {
          canvas.drawCircle(
            Offset(s * 0.5, s * 0.5),
            s * (0.1 + i * 0.075),
            fill(i.isEven ? soft : Colors.white.withOpacity(0.0)),
          );
        }
        canvas.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.28, stroke(accent.withOpacity(0.4), s * 0.02));
        canvas.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.16, stroke(accent, s * 0.025));
        canvas.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.05, fill(accent));
        break;

      case IllustrationKind.bills:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.24, s * 0.2, s * 0.52, s * 0.6),
          Radius.circular(s * 0.07),
        );
        canvas.drawRRect(rect, fill(Colors.white));
        canvas.drawRRect(rect, stroke(accent.withOpacity(0.25), s * 0.012));
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(s * 0.32, s * (0.32 + i * 0.11), s * 0.36, s * 0.03),
              Radius.circular(s * 0.015),
            ),
            fill(palette.divider),
          );
        }
        canvas.drawCircle(Offset(s * 0.66, s * 0.68), s * 0.11, fill(amber));
        canvas.drawLine(
          Offset(s * 0.66, s * 0.63),
          Offset(s * 0.66, s * 0.7),
          stroke(Colors.white, s * 0.02),
        );
        canvas.drawCircle(Offset(s * 0.66, s * 0.74), s * 0.012, fill(Colors.white));
        break;

      case IllustrationKind.premium:
        final path = Path();
        const points = 5;
        final centre = Offset(s * 0.5, s * 0.48);
        for (var i = 0; i < points * 2; i++) {
          final radius = i.isEven ? s * 0.26 : s * 0.13;
          final angle = -math.pi / 2 + i * math.pi / points;
          final point = Offset(
            centre.dx + radius * math.cos(angle),
            centre.dy + radius * math.sin(angle),
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, fill(accent));
        canvas.drawCircle(Offset(s * 0.3, s * 0.26), s * 0.035, fill(amber));
        canvas.drawCircle(Offset(s * 0.74, s * 0.72), s * 0.025, fill(green));
        break;

      case IllustrationKind.achievements:
        final cup = Path()
          ..moveTo(s * 0.34, s * 0.28)
          ..lineTo(s * 0.66, s * 0.28)
          ..lineTo(s * 0.62, s * 0.55)
          ..quadraticBezierTo(s * 0.5, s * 0.68, s * 0.38, s * 0.55)
          ..close();
        canvas.drawPath(cup, fill(accent));
        canvas.drawLine(
          Offset(s * 0.5, s * 0.66),
          Offset(s * 0.5, s * 0.76),
          stroke(accent, s * 0.03),
        );
        canvas.drawLine(
          Offset(s * 0.4, s * 0.78),
          Offset(s * 0.6, s * 0.78),
          stroke(accent, s * 0.03),
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(s * 0.5, s * 0.44), radius: s * 0.2),
          -math.pi * 0.85,
          math.pi * 0.7,
          false,
          stroke(amber, s * 0.02),
        );
        break;

      case IllustrationKind.backup:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.2, s * 0.34, s * 0.6, s * 0.4),
            Radius.circular(s * 0.08),
          ),
          fill(Colors.white),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.2, s * 0.34, s * 0.6, s * 0.4),
            Radius.circular(s * 0.08),
          ),
          stroke(accent.withOpacity(0.3), s * 0.012),
        );
        final arrow = Path()
          ..moveTo(s * 0.5, s * 0.64)
          ..lineTo(s * 0.5, s * 0.44);
        canvas.drawPath(arrow, stroke(accent, s * 0.025));
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.43, s * 0.51)
            ..lineTo(s * 0.5, s * 0.43)
            ..lineTo(s * 0.57, s * 0.51),
          stroke(accent, s * 0.025),
        );
        canvas.drawCircle(Offset(s * 0.5, s * 0.72), s * 0.02, fill(green));
        break;

      case IllustrationKind.search:
        canvas.drawCircle(
          Offset(s * 0.45, s * 0.44),
          s * 0.2,
          stroke(accent, s * 0.03),
        );
        canvas.drawCircle(Offset(s * 0.45, s * 0.44), s * 0.2, fill(accent.withOpacity(0.08)));
        canvas.drawLine(
          Offset(s * 0.6, s * 0.6),
          Offset(s * 0.76, s * 0.76),
          stroke(accent, s * 0.04),
        );
        break;

      case IllustrationKind.split:
        final centre = Offset(s * 0.5, s * 0.5);
        for (var i = 0; i < 3; i++) {
          final angle = -math.pi / 2 + i * (2 * math.pi / 3);
          final point = Offset(
            centre.dx + s * 0.16 * math.cos(angle),
            centre.dy + s * 0.16 * math.sin(angle),
          );
          canvas.drawLine(centre, point, stroke(accent.withOpacity(0.4), s * 0.015));
          canvas.drawCircle(point, s * 0.09, fill(i == 0 ? accent : Colors.white));
          canvas.drawCircle(point, s * 0.09, stroke(accent.withOpacity(0.3), s * 0.01));
        }
        canvas.drawCircle(centre, s * 0.055, fill(ink));
        break;

      case IllustrationKind.success:
        canvas.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.28, fill(green.withOpacity(0.14)));
        canvas.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.18, fill(green));
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.42, s * 0.5)
            ..lineTo(s * 0.48, s * 0.57)
            ..lineTo(s * 0.6, s * 0.43),
          stroke(Colors.white, s * 0.03),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.palette != palette;
}

/// Onboarding page content = illustration + copy + bullets.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt({super.key, required this.kind, this.size = 220});

  final IllustrationKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: AppIllustration(kind: kind, size: size),
    );
  }
}

/// Small helper text style used by onboarding pages.
TextStyle illustrationCaption(BuildContext context) => AppTextStyles.body(context.c.sub);
