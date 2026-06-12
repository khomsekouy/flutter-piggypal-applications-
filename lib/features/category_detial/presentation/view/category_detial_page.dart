import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/dashboard/data/budget_store.dart';
import 'package:flutter_piggypal_app/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_charts.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Per-category breakdown: budget vs. spend, a usage ring and its transactions.
class CategoryDetialPage extends StatelessWidget {
  const CategoryDetialPage({required this.nav, required this.label, super.key});

  final TFNav nav;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return ValueListenableBuilder<List<BudgetCat>>(
      valueListenable: BudgetStore.instance.cats,
      builder: (context, allCats, _) {
        BudgetCat? cat;
        for (final x in allCats) {
          if (x.label == label) {
            cat = x;
            break;
          }
        }
        if (cat == null) {
          return TFScreen(
            header: TFBackBar(title: label, onBack: nav.back),
            children: const [TFEmptyMessage('Category not found.')],
          );
        }

        final activeCat = cat;
        final spent = cat.spent;
        final budget = cat.budget;
        final remaining = (budget - spent).clamp(0, budget).toDouble();
        final pct = cat.pct;

        return TFScreen(
          header: TFBackBar(
            title: label,
            onBack: nav.back,
            trailing: TFIconButton(
              icon: Icons.add,
              onTap: () => nav.push(TFScreens.addTx, {'cat': label}),
            ),
          ),
          children: [
            // Header: identity + spent/budget/remaining + bar.
            TFCard(
              padding: const EdgeInsets.all(16),
              borderColor: c.line,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cat.color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(cat.icon, size: 24, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TFText.sans(size: 18, color: c.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'May 2025',
                            style: TFText.sans(size: 12.5, color: c.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _Stat(
                        label: 'Spent',
                        value: formatMoney(spent),
                        color: cat.color,
                      ),
                      _Stat(
                        label: 'Budget',
                        value: formatMoney(budget),
                        color: c.text,
                      ),
                      _Stat(
                        label: 'Remaining',
                        value: formatMoney(remaining),
                        color: c.pos,
                        align: CrossAxisAlignment.end,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TFProgress(
                          pct: pct,
                          color: cat.color,
                          over: cat.over,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$pct%',
                        style: TFText.sans(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Spending overview: ring + legend.
            TFCard(
              padding: const EdgeInsets.all(16),
              borderColor: c.line,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Overview',
                    style: TFText.sans(size: 14, color: c.text),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TFDonut(
                        segments: [
                          DonutSegment(spent, cat.color),
                          DonutSegment(remaining, Colors.transparent),
                        ],
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$pct%',
                              style: TFText.num(
                                size: 26,
                                color: c.text,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'of budget',
                              style: TFText.sans(size: 11, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Legend(
                              color: cat.color,
                              label: 'Spent',
                              value: formatMoney(spent),
                            ),
                            const SizedBox(height: 14),
                            _Legend(
                              color: c.textDim,
                              label: 'Remaining',
                              value: formatMoney(remaining),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Recent transactions for this category.
            TFCard(
              padding: const EdgeInsets.all(16),
              borderColor: c.line,
              child: ValueListenableBuilder<List<RecentTx>>(
                valueListenable: BudgetStore.instance.recent,
                builder: (context, _, _) {
                  final txs = BudgetStore.instance.txFor(label);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: TFText.sans(size: 14, color: c.text),
                          ),
                          Text(
                            'View All',
                            style: TFText.sans(size: 12.5, color: c.primary),
                          ),
                        ],
                      ),
                      if (txs.isEmpty)
                        const TFEmptyMessage(
                          'No transactions yet.',
                          topPadding: 20,
                        )
                      else
                        for (final (i, tx) in txs.indexed)
                          _DetailTxRow(tx: tx, cat: activeCat, first: i == 0),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.align = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(label, style: TFText.sans(size: 12, color: c.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: TFText.num(size: 16, color: color)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TFText.sans(size: 13, color: c.textMuted)),
        const Spacer(),
        Text(value, style: TFText.num(size: 13.5, color: c.text)),
      ],
    );
  }
}

class _DetailTxRow extends StatelessWidget {
  const _DetailTxRow({
    required this.tx,
    required this.cat,
    required this.first,
  });

  final RecentTx tx;
  final BudgetCat cat;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final tone = tx.isIncome ? c.pos : c.neg;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(cat.icon, size: 18, color: cat.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TFText.sans(size: 14, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TFText.sans(
                    size: 12,
                    color: c.textMuted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${tx.isIncome ? '+' : '-'}${formatMoney(tx.amount)}',
            style: TFText.num(size: 14.5, color: tone),
          ),
        ],
      ),
    );
  }
}
