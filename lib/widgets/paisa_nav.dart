import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';

/// One destination in the Paisa bottom bar.
class PaisaNavItem {
  const PaisaNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Four-item bottom navigation: a soft rounded pill highlights the active tab,
/// labels are always visible and the bar sits flush on the surface.
class PaisaNavBar extends StatelessWidget {
  const PaisaNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
    this.bottomInset = 0,
  });

  final List<PaisaNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: bottomInset + 8,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.divider.withOpacity(0.7)),
        ),
      ),
      child: Row(
        children: <Widget>[
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: i == index
                        ? (palette.isDark
                            ? palette.cardAlt
                            : palette.accent.withOpacity(0.30))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        i == index ? items[i].activeIcon : items[i].icon,
                        size: 22,
                        color: i == index
                            ? palette.ink
                            : palette.tertiary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: AppTextStyles.base(
                          size: 11,
                          weight: i == index ? FontWeight.w700 : FontWeight.w500,
                          height: 1.0,
                        ).copyWith(
                          color: i == index
                              ? palette.ink
                              : palette.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
