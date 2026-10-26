import 'package:flutter/material.dart';

import '../../widgets/bottom_menu.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../household/household_screen.dart';
import '../recurring/recurring_rules_screen.dart';

/// The four tabs of the bottom menu. Each keeps its state (scroll position,
/// filters) while another one is shown.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  AppTab _tab = AppTab.dashboard;

  /// Shows [tab], e.g. the household when its name is tapped on the
  /// dashboard.
  void select(AppTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab.index,
        children: const [
          DashboardScreen(),
          HistoryScreen(),
          RecurringRulesScreen(),
          HouseholdScreen(),
        ],
      ),
      bottomNavigationBar: BottomMenu(current: _tab, onSelect: select),
    );
  }
}
