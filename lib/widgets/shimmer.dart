import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';

/// Animated skeleton block.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final base = palette.isDark ? palette.cardAlt : palette.surfaceAlt;
    final highlight = palette.isDark ? palette.divider : const Color(0xFFF7F7FB);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 + t * 2, 0),
              colors: <Color>[base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton that mirrors the dashboard layout while data loads.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: <Widget>[
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: context.c.card,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          ),
          padding: const EdgeInsets.all(AppSpacing.x5),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ShimmerBox(height: 12, width: 90),
              SizedBox(height: 12),
              ShimmerBox(height: 30, width: 180),
              Spacer(),
              ShimmerBox(height: 10),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        Row(
          children: const <Widget>[
            Expanded(child: _SkeletonTile()),
            SizedBox(width: AppSpacing.cardGap),
            Expanded(child: _SkeletonTile()),
          ],
        ),
        const SizedBox(height: AppSpacing.cardGap),
        const _SkeletonTile(height: 180),
      ],
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile({this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ShimmerBox(height: 10, width: 60),
          SizedBox(height: 10),
          ShimmerBox(height: 18, width: 90),
        ],
      ),
    );
  }
}

/// Generic loading state for lists.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screen),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x3),
      itemBuilder: (context, index) => Row(
        children: const <Widget>[
          ShimmerBox(height: 42, width: 42, radius: 21),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShimmerBox(height: 12, width: 120),
                SizedBox(height: 6),
                ShimmerBox(height: 10, width: 70),
              ],
            ),
          ),
          ShimmerBox(height: 14, width: 60),
        ],
      ),
    );
  }
}
