import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Animated neon progress bar used on budgets & goals.
class NeonProgressBar extends StatelessWidget {
  final double progress; // 0..1 (values > 1 clamp)
  final List<Color> colors;
  final double height;
  final Color? track;

  const NeonProgressBar({
    super.key,
    required this.progress,
    required this.colors,
    this.height = 10,
    this.track,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final p = progress.clamp(0.0, 1.0);
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: track ?? AppColors.line.withOpacity(0.7),
            borderRadius: BorderRadius.circular(height),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              width: w * p,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(height),
                boxShadow: [
                  BoxShadow(color: colors.last.withOpacity(0.5), blurRadius: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
