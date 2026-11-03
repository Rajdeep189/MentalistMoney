import 'package:flutter/material.dart';

import '../../core/utils/spring_sheet.dart';
import '../sheets/add_transaction_sheet.dart';
import '../widgets/floating_pill_navbar.dart';
import 'analytics_screen.dart';
import 'bills_screen.dart';
import 'budgets_screen.dart';
import 'home_screen.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          AnalyticsScreen(),
          BillsScreen(),
          BudgetsScreen(),
        ],
      ),
      bottomNavigationBar: FloatingPillNavBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        onAdd: () => showSpringBottomSheet(
          context: context,
          builder: (ctx) => const AddTransactionSheet(),
        ),
      ),
    );
  }
}
