import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Receipt-style dashed divider.
class DashedLine extends StatelessWidget {
  final Color? color;
  final double indent;
  final double outdent;

  const DashedLine({super.key, this.color, this.indent = 16, this.outdent = 16});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedPainter(color ?? AppColors.line, indent, outdent),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  final double indent;
  final double outdent;

  _DashedPainter(this.color, this.indent, this.outdent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = indent;
    while (x < size.width - outdent) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 5, 0.5), paint);
      x += 9;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter oldDelegate) => false;
}
