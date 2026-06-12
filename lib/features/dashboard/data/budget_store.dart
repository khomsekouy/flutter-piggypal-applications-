import 'package:flutter/material.dart';

/// A spending category with its monthly budget vs. spend.
class BudgetCat {
  const BudgetCat({
    required this.label,
    required this.icon,
    required this.color,
    required this.budget,
    required this.spent,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double budget;
  final double spent;

  int get pct => budget == 0 ? 0 : ((spent / budget) * 100).round();
  bool get over => spent > budget;
}

/// In-memory store of budget categories shared across screens.
///
/// Front-end only: holds a seeded list and notifies listeners when a new
/// category is added from the Add-category form.
class BudgetStore {
  BudgetStore._();
  static final BudgetStore instance = BudgetStore._();

  final ValueNotifier<List<BudgetCat>> cats = ValueNotifier(List.of(_seed));
  final ValueNotifier<List<RecentTx>> recent = ValueNotifier(
    List.of(kRecentTx),
  );

  void add(BudgetCat cat) => cats.value = [...cats.value, cat];

  /// Records a transaction: prepends it to the history and, for an expense
  /// tied to a category, increases that category's spend.
  void addTx(RecentTx tx) {
    recent.value = [tx, ...recent.value];
    if (tx.isIncome || tx.category == null) return;
    cats.value = [
      for (final cat in cats.value)
        if (cat.label == tx.category)
          BudgetCat(
            label: cat.label,
            icon: cat.icon,
            color: cat.color,
            budget: cat.budget,
            spent: cat.spent + tx.amount,
          )
        else
          cat,
    ];
  }

  /// Transactions belonging to [categoryLabel], newest first.
  List<RecentTx> txFor(String categoryLabel) =>
      recent.value.where((t) => t.category == categoryLabel).toList();
}

/// A recent transaction shown in the home history list.
class RecentTx {
  const RecentTx({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    this.category,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;

  /// The budget category this expense counts against (null for income).
  final String? category;
}

/// Mock recent transactions, newest first.
const kRecentTx = <RecentTx>[
  RecentTx(
    title: 'Grocery Store',
    subtitle: 'Food · May 18 · 06:30 PM',
    amount: 68.35,
    isIncome: false,
    category: 'Food',
  ),
  RecentTx(
    title: 'Monthly Salary',
    subtitle: 'Income · May 1',
    amount: 3200,
    isIncome: true,
  ),
  RecentTx(
    title: 'Netflix',
    subtitle: 'Entertainment · May 3',
    amount: 15.99,
    isIncome: false,
    category: 'Entertainment',
  ),
  RecentTx(
    title: 'Lunch',
    subtitle: 'Food · May 20 · 12:45 PM',
    amount: 12.80,
    isIncome: false,
    category: 'Food',
  ),
  RecentTx(
    title: 'Uber Ride',
    subtitle: 'Transport · May 4',
    amount: 12.50,
    isIncome: false,
    category: 'Transport',
  ),
  RecentTx(
    title: 'Freelance Project',
    subtitle: 'Income · May 5',
    amount: 450,
    isIncome: true,
  ),
  RecentTx(
    title: 'Coffee Shop',
    subtitle: 'Food · May 6 · 09:15 AM',
    amount: 5.40,
    isIncome: false,
    category: 'Food',
  ),
];

const _seed = <BudgetCat>[
  BudgetCat(
    label: 'Food',
    icon: Icons.restaurant,
    color: Color(0xFFF97316),
    budget: 800,
    spent: 512.75,
  ),
  BudgetCat(
    label: 'Drinks',
    icon: Icons.local_cafe,
    color: Color(0xFF8B5CF6),
    budget: 200,
    spent: 135.40,
  ),
  BudgetCat(
    label: 'Transport',
    icon: Icons.directions_bus,
    color: Color(0xFF3B82F6),
    budget: 400,
    spent: 248.60,
  ),
  BudgetCat(
    label: 'Shopping',
    icon: Icons.shopping_bag,
    color: Color(0xFFEC4899),
    budget: 400,
    spent: 315.20,
  ),
  BudgetCat(
    label: 'Bills',
    icon: Icons.receipt_long,
    color: Color(0xFF14B8A6),
    budget: 700,
    spent: 612.30,
  ),
  BudgetCat(
    label: 'Health',
    icon: Icons.favorite,
    color: Color(0xFFEF4444),
    budget: 300,
    spent: 120,
  ),
  BudgetCat(
    label: 'Education',
    icon: Icons.school,
    color: Color(0xFF22C55E),
    budget: 300,
    spent: 80,
  ),
  BudgetCat(
    label: 'Entertainment',
    icon: Icons.sports_esports,
    color: Color(0xFF7C3AED),
    budget: 250,
    spent: 110.50,
  ),
  BudgetCat(
    label: 'Travel',
    icon: Icons.flight,
    color: Color(0xFF06B6D4),
    budget: 700,
    spent: 224,
  ),
  BudgetCat(
    label: 'Others',
    icon: Icons.more_horiz,
    color: Color(0xFF9CA3AF),
    budget: 450,
    spent: 100,
  ),
];
