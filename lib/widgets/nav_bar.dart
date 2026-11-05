import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// One destination in the floating glass navigation capsule.
class LuxeNavItem {
  const LuxeNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating glass navigation: a translucent capsule with an animated sunset
/// pill for the active tab, a detached circular menu button, and a slow light
/// sweep that travels across the glass.
class LuxeNavBar extends StatefulWidget {
  const LuxeNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
    this.onMenu,
    this.bottomInset = 0,
  });

  final List<LuxeNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;
  final VoidCallback? onMenu;
  final double bottomInset;

  @override
  State<LuxeNavBar> createState() => _LuxeNavBarState();
}

class _LuxeNavBarState extends State<LuxeNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final isDark = palette.isDark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x4,
        0,
        AppSpacing.x4,
        math.max(widget.bottomInset, AppSpacing.x3),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  height: 68,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.62)
                        : Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.white.withOpacity(0.9),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.55 : 0.10),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: <Widget>[
                      // slow travelling sheen
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _sheen,
                          builder: (context, _) {
                            final t = _sheen.value;
                            return IgnorePointer(
                              child: FractionallySizedBox(
                                alignment: Alignment(-1 + t * 2.4, 0),
                                widthFactor: 0.36,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: <Color>[
                                        Colors.white.withOpacity(0),
                                        Colors.white.withOpacity(isDark ? 0.10 : 0.55),
                                        Colors.white.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          for (var i = 0; i < widget.items.length; i++)
                            Expanded(
                              child: _NavSlot(
                                item: widget.items[i],
                                selected: i == widget.index,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onSelected(i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          _MenuOrb(onTap: widget.onMenu),
        ],
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final LuxeNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.sunsetGradient : null,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.sunset.withOpacity(0.42),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 21,
                color: selected
                    ? Colors.white
                    : (palette.isDark ? palette.tertiary : palette.sub),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: AppTextStyles.caption(Colors.white)
                        .copyWith(fontSize: 9.5, height: 1.0, letterSpacing: 0.1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuOrb extends StatefulWidget {
  const _MenuOrb({this.onTap});

  final VoidCallback? onTap;

  @override
  State<_MenuOrb> createState() => _MenuOrbState();
}

class _MenuOrbState extends State<_MenuOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 68,
        width: 68,
        decoration: BoxDecoration(
          color: palette.isDark
              ? Colors.black.withOpacity(0.62)
              : Colors.white.withOpacity(0.78),
          shape: BoxShape.circle,
          border: Border.all(
            color: palette.isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.white.withOpacity(0.9),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(palette.isDark ? 0.55 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: _spin,
              builder: (context, _) {
                return Transform.rotate(
                  angle: _spin.value * 2 * math.pi,
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: <Color>[
                          palette.accent.withOpacity(0.0),
                          palette.accent.withOpacity(0.55),
                          palette.violet.withOpacity(0.35),
                          palette.accent.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Icon(
              Icons.more_horiz_rounded,
              size: 24,
              color: palette.ink,
            ),
          ],
        ),
      ),
    );
  }
}
