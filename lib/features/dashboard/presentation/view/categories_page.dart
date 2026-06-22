import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/features/dashboard/data/budget_store.dart';
import 'package:flutter_piggypal_app/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The full categories list reached from the Home "View all" action: every
/// budget category in a grid, with its own search.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({required this.nav, super.key});

  final TFNav nav;

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BudgetCat>>(
      valueListenable: BudgetStore.instance.cats,
      builder: (context, allCats, _) {
        final q = _query.trim().toLowerCase();
        final cats = q.isEmpty
            ? allCats
            : allCats.where((x) => x.label.toLowerCase().contains(q)).toList();

        return TFScreen(
          pinnedHeader: true,
          // Back bar + search field stay pinned; the grid scrolls beneath.
          header: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TFBackBar(title: 'Categories', onBack: widget.nav.back),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: DashboardSearchField(
                  hint: 'Search categories',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ],
          ),
          children: [
            if (cats.isEmpty)
              TFEmptyMessage('No categories match “$_query”.', topPadding: 40)
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.08,
                children: [
                  for (final cat in cats)
                    CategoryCard(
                      cat: cat,
                      onTap: () => widget.nav.push(TFScreens.category, {
                        'label': cat.label,
                      }),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
