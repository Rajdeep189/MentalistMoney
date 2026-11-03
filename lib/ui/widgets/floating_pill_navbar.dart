import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class NavItemData {
  final IconData icon;
  final String label;
  const NavItemData(this.icon, this.label);
}

/// Floating pill-shaped dock with a glowing neon active state and a
/// raised central '+' action button.
class FloatingPillNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;

  const FloatingPillNavBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.onAdd,
  });

  static const items = [
    NavItemData(Icons.home_rounded, 'Home'),
    NavItemData(Icons.bar_chart_rounded, 'Stats'),
    NavItemData(Icons.receipt_long_rounded, 'Bills'),
    NavItemData(Icons.account_balance_wallet_rounded, 'Budgets'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 92,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    offset: const Offset(0, 12),
                    blurRadius: 24,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  _navItem(0),
                  _navItem(1),
                  const SizedBox(width: 76), // gap for the FAB
                  _navItem(2),
                  _navItem(3),
                ],
              ),
            ),
            Positioned(
              bottom: 36,
              child: Hero(
                tag: 'add-fab',
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neon,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neon.withOpacity(0.55),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(0, 8),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.neonInk, size: 32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i) {
    final active = i == index;
    final item = items[i];
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.neon : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: active
                ? [BoxShadow(color: AppColors.neon.withOpacity(0.6), blurRadius: 14, spreadRadius: 1)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                color: active ? AppColors.neonInk : AppColors.inkSoft,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? AppColors.neonInk : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
