import 'package:flutter/material.dart';

import '../../core/constants/app_categories.dart';

/// Large circular geometric category icon (gradient disc + white glyph).
class CategoryIcon extends StatelessWidget {
  final AppCategory category;
  final double size;

  const CategoryIcon({super.key, required this.category, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [category.color, category.color2],
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.35),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(category.icon, color: Colors.white, size: size * 0.46),
    );
  }
}
