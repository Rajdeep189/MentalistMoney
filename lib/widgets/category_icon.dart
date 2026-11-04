import 'package:flutter/material.dart';

import '../core/theme/app_radius.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/app_icons.dart';
import '../data/models/models.dart';

/// Circular tinted icon container used for categories, accounts and rows.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    this.icon,
    this.color,
    this.size = 42,
    this.iconName,
    this.rounded = false,
    this.iconSize,
    this.backgroundOpacity = 0.14,
  });

  /// Either pass an [IconData] or a persisted icon [iconName].
  final IconData? icon;
  final String? iconName;
  final Color? color;
  final double size;
  final bool rounded;
  final double? iconSize;
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;
    final resolved = icon ?? AppIcons.byName(iconName);
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: tone.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(rounded ? size * 0.32 : size / 2),
      ),
      alignment: Alignment.center,
      child: Icon(resolved, size: iconSize ?? size * 0.48, color: tone),
    );
  }
}

/// Convenience constructor for a category row icon.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.category,
    this.size = 42,
    this.showColors = true,
  });

  final Category? category;
  final double size;
  final bool showColors;

  @override
  Widget build(BuildContext context) {
    final fallback = Theme.of(context).colorScheme.onSurfaceVariant;
    final color =
        category == null || !showColors ? fallback : _parse(category!.color);
    return CategoryIcon(
      iconName: category?.icon ?? 'category',
      color: color,
      size: size,
    );
  }

  Color _parse(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.tryParse(value, radix: 16) ?? 0xFF916CFF);
  }
}

/// Header used at the top of detail pages (icon + title + subtitle).
class IconHeading extends StatelessWidget {
  const IconHeading({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.trailing,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CategoryIcon(iconName: icon, color: color, size: 52, rounded: true),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: context.h2),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: context.caption),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Empty visual made of concentric tinted circles (no external assets needed).
class RoundedGlyph extends StatelessWidget {
  const RoundedGlyph({
    super.key,
    this.icon,
    this.color,
    this.size = 64,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[tone.withOpacity(0.22), tone.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Icon(icon, size: size * 0.45, color: tone),
    );
  }
}
