import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/view/savings_goals_page.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/view/transactions_page.dart';

/// Top-level navigation shell.
///
/// App-level composition (not a clean-arch feature itself): it just hosts the
/// feature pages behind a bottom navigation bar. Each tab owns its own bloc.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _pages = [TransactionsPage(), SavingsGoalsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Goals',
          ),
        ],
      ),
    );
  }
}
