import 'package:flutter/material.dart';

/// Zigzag / perforated edge path used by both the clipper and the painter.
Path receiptPath(Size size, double tooth, double amp) {
  final w = size.width;
  final h = size.height;
  final p = Path();
  final n = (w / tooth).ceil();
  final step = w / n;
  p.moveTo(0, 0);
  // top edge — zigzag
  for (var i = 0; i < n; i++) {
    p.lineTo(step * i + step / 2, amp);
    p.lineTo(step * (i + 1), 0);
  }
  p.lineTo(w, h);
  // bottom edge — zigzag (right to left)
  for (var i = n; i > 0; i--) {
    p.lineTo(step * i - step / 2, h - amp);
    p.lineTo(step * (i - 1), h);
  }
  p.close();
  return p;
}

class ReceiptClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => receiptPath(size, 10, 5);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// Paints the perforated paper shape plus a shaped (blurred) drop shadow.
class ReceiptPainter extends CustomPainter {
  final Color color;

  ReceiptPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = receiptPath(size, 10, 5);
    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path.shift(const Offset(0, 6)), shadow);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant ReceiptPainter oldDelegate) => oldDelegate.color != color;
}

/// Tactile stamped-paper container: zigzag top & bottom edges.
class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ReceiptPainter(color),
      child: ClipPath(
        clipper: ReceiptClipper(),
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: color,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
