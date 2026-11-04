import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/amount_text.dart';
import '../budgets/budgets_screen.dart';
import '../common/lock_gate.dart';
import '../goals/goals_screen.dart';
import '../home/home_screen.dart';
import '../stats/stats_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transactions_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final List<Widget> _screens = const <Widget>[
    HomeScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    GoalsScreen(),
    StatsScreen(),
  ];

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Transactions'),
    _NavItem(icon: Icons.pie_chart_outline_rounded, activeIcon: Icons.pie_chart_rounded, label: 'Budgets'),
    _NavItem(icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded, label: 'Goals'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Stats'),
  ];

  Future<void> _openAddTransaction() async {
    await showAddTransactionSheet(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);
    final palette = context.c;

    return LockGate(
      child: Scaffold(
        backgroundColor: palette.surface,
        extendBody: true,
        body: IndexedStack(index: index, children: _screens),
        floatingActionButton: index <= 3
            ? Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  height: AppSpacing.fabSize,
                  width: AppSpacing.fabSize,
                  child: FloatingActionButton(
                    onPressed: _openAddTransaction,
                    elevation: 3,
                    backgroundColor: palette.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: _BottomNav(
          index: index,
          items: _items,
          onSelected: (value) {
            HapticFeedback.selectionClick();
            ref.read(navIndexProvider.notifier).state = value;
          },
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.items, required this.onSelected});

  final int index;
  final List<_NavItem> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      decoration: BoxDecoration(
        color: palette.navBar,
        border: Border(top: BorderSide(color: palette.divider)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: palette.shadow, blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.navBarHeight,
          child: Row(
            children: List<Widget>.generate(items.length, (i) {
              final item = items[i];
              final selected = i == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AnimatedScale(
                        scale: selected ? 1.06 : 1,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 23,
                          color: selected ? palette.accent : palette.tertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.label(
                          selected ? palette.accent : palette.tertiary,
                        ).copyWith(fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Reusable app-bar action that hides / shows every amount in the app.
class PrivacyToggle extends ConsumerWidget {
  const PrivacyToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final hidden = ref.watch(amountsHiddenProvider);
    return IconButton(
      tooltip: hidden ? 'Show amounts' : 'Hide amounts',
      onPressed: () {
        ref.read(amountsHiddenProvider.notifier).state = !hidden;
      },
      icon: Icon(
        hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 20,
        color: palette.sub,
      ),
    );
  }
}

/// Small helper chip showing the current month.
class MonthChip extends StatelessWidget {
  const MonthChip({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.cardAlt : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.calendar_today_rounded, size: 11, color: palette.sub),
          const SizedBox(width: 5),
          Text(
            FmtMonth.label(),
            style: AppTextStyles.caption(palette.sub),
          ),
        ],
      ),
    );
  }
}

class FmtMonth {
  FmtMonth._();

  static String label() {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}
