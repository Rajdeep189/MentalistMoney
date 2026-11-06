import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_text_styles.dart';

/// Violet PRO badge with a subtle shimmer.
class PremiumBadge extends StatefulWidget {
  const PremiumBadge({super.key, this.dense = false, this.label = 'PRO'});

  final bool dense;
  final String label;

  @override
  State<PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<PremiumBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shift = _controller.value * 2 - 1;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.dense ? 6 : 8,
            vertical: widget.dense ? 2 : 3,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + shift, -1),
              end: Alignment(1 + shift, 1),
              colors: <Color>[
                palette.accent,
                Color.lerp(palette.accent, Colors.white, 0.35)!,
                palette.accent,
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.overline(Colors.white).copyWith(
              fontSize: widget.dense ? 8 : 9,
              letterSpacing: 0.6,
            ),
          ),
        );
      },
    );
  }
}

/// Wrapper that shows a lock icon overlay for locked premium content.
class PremiumLocked extends StatelessWidget {
  const PremiumLocked({super.key, required this.child, this.label = 'Premium feature'});

  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Stack(
      children: <Widget>[
        Opacity(opacity: 0.35, child: IgnorePointer(child: child)),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: palette.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.lock_rounded, size: 15, color: palette.accent),
                  const SizedBox(width: 6),
                  Text(label, style: AppTextStyles.label(palette.ink)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
