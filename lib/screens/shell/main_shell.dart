import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/paisa_nav.dart';
import '../accounts/accounts_screen.dart';
import '../common/lock_gate.dart';
import '../home/home_screen.dart';
import '../stats/stats_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/search_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    AccountsScreen(),
    StatsScreen(),
    SearchScreen(),
  ];

  static const List<PaisaNavItem> _items = <PaisaNavItem>[
    PaisaNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    PaisaNavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Accounts',
    ),
    PaisaNavItem(
      icon: Icons.pie_chart_outline_rounded,
      activeIcon: Icons.pie_chart_rounded,
      label: 'Reports',
    ),
    PaisaNavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Search',
    ),
  ];

  Future<void> _openAddTransaction() async {
    await showAddTransactionSheet(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);
    final palette = context.c;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return LockGate(
      child: Scaffold(
        backgroundColor: palette.surface,
        extendBody: true,
        body: IndexedStack(index: index, children: _screens),
        floatingActionButton: index == 0
            ? Padding(
                padding: const EdgeInsets.only(bottom: 84),
                child: SizedBox(
                  height: 58,
                  width: 58,
                  child: FloatingActionButton(
                    onPressed: _openAddTransaction,
                    elevation: 6,
                    backgroundColor: palette.isDark
                        ? const Color(0xFF7A452C)
                        : palette.ink,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add_rounded,
                        size: 30, color: Colors.white),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: PaisaNavBar(
          index: index.clamp(0, _items.length - 1),
          items: _items,
          bottomInset: safeBottom,
          onSelected: (value) {
            HapticFeedback.selectionClick();
            ref.read(navIndexProvider.notifier).state = value;
          },
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
