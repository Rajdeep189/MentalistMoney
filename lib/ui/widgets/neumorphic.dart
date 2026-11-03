import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Softly extruded card on the warm beige background (neumorphism):
/// blurred dark drop shadow + bright top-left light shadow.
class NeumorphicCard extends StatelessWidget {
  const NeumorphicCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.color,
    this.shadowOffset = 7,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double shadowOffset;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.bg;
    final o = shadowOffset;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.neoShadowDark.withOpacity(0.45),
            offset: Offset(o, o),
            blurRadius: o * 2.2,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.95),
            offset: Offset(-o, -o),
            blurRadius: o * 2.2,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Round pressable neumorphic button with a pressed (inset-feel) state.
class NeumorphicButton extends StatefulWidget {
  const NeumorphicButton({
    super.key,
    required this.onTap,
    required this.child,
    this.size = 46,
  });

  final VoidCallback onTap;
  final Widget child;
  final double size;

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.bg,
          shape: BoxShape.circle,
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: AppColors.neoShadowDark.withOpacity(0.5),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.neoShadowDark.withOpacity(0.5),
                    offset: const Offset(6, 6),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.95),
                    offset: const Offset(-6, -6),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

/// Raised card for the dark analytics mode.
class DarkCard extends StatelessWidget {
  const DarkCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.darkLine.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(0, 10), blurRadius: 24),
          BoxShadow(color: Colors.white.withOpacity(0.04), offset: const Offset(0, -2), blurRadius: 6),
        ],
      ),
      child: child,
    );
  }
}
