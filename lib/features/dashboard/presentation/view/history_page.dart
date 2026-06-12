import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/features/dashboard/data/budget_store.dart';
import 'package:flutter_piggypal_app/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The full transaction history reached from the Home "View all" action: every
/// recent transaction in a single list, with its own search.
class HistoryPage extends StatefulWidget {
  const HistoryPage({required this.nav, super.key});

  final TFNav nav;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<RecentTx>>(
      valueListenable: BudgetStore.instance.recent,
      builder: (context, allTx, _) {
        final q = _query.trim().toLowerCase();
        final txs = q.isEmpty
            ? allTx
            : allTx
                  .where(
                    (t) =>
                        t.title.toLowerCase().contains(q) ||
                        t.subtitle.toLowerCase().contains(q),
                  )
                  .toList();

        return TFScreen(
          header: TFBackBar(title: 'Recent History', onBack: widget.nav.back),
          children: [
            DashboardSearchField(
              hint: 'Search transactions',
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            if (txs.isEmpty)
              TFEmptyMessage('No transactions match “$_query”.', topPadding: 40)
            else
              TFCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (final (i, tx) in txs.indexed)
                      TxHistoryRow(tx: tx, first: i == 0),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
