import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tiny hand-drawn bar chart used on the dashboard balance card.
class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final double height;

  const MiniBarChart({super.key, required this.values, this.height = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _MiniBarPainter(values)),
    );
  }
}

class _MiniBarPainter extends CustomPainter {
  final List<double> values;

  _MiniBarPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final max = values.reduce((a, b) => a > b ? a : b);
    final top = max <= 0 ? 1.0 : max;
    const gap = 6.0;
    final bw = (size.width - gap * (values.length - 1)) / values.length;
    for (var i = 0; i < values.length; i++) {
      final h = values[i] <= 0 ? 4.0 : (values[i] / top) * (size.height - 6);
      final x = i * (bw + gap);
      final isLast = i == values.length - 1;
      final paint = Paint()..color = isLast ? AppColors.orange : AppColors.ink.withOpacity(0.16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, bw, h),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarPainter oldDelegate) => oldDelegate.values != values;
}
