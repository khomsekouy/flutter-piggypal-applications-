import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_charts.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Org-wide budget: donut roll-up + per-category allocation vs. spend.
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({required this.nav, super.key});

  final TFNav nav;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final remaining = db.totalBudget - db.totalSpent;

    return TFScreen(
      header: TFBackBar(
        title: 'Budgets',
        onBack: nav.back,
        trailing: const TFIconButton(icon: Icons.add),
      ),
      children: [
        TFCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              TFDonut(
                size: 118,
                stroke: 15,
                segments: [
                  for (final b in db.budget)
                    DonutSegment(b.spent, tfCatColor(b.hue)),
                ],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${db.budgetUsedPct}%',
                      style: TFText.num(size: 22, color: c.text),
                    ),
                    Text(
                      'spent',
                      style: TFText.sans(size: 10, color: c.textDim),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total allocated',
                      style: TFText.sans(size: 12.5, color: c.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TFData.fmt(db.totalBudget),
                      style: TFText.num(size: 24, color: c.text),
                    ),
                    Container(
                      height: 1,
                      color: c.line,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TFData.fmtK(db.totalSpent),
                              style: TFText.num(size: 15, color: c.neg),
                            ),
                            Text(
                              'spent',
                              style: TFText.sans(size: 10.5, color: c.textDim),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TFData.fmtK(remaining),
                              style: TFText.num(size: 15, color: c.pos),
                            ),
                            Text(
                              'left',
                              style: TFText.sans(size: 10.5, color: c.textDim),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const TFSectionLabel(title: 'By category', action: 'Adjust'),
        for (final b in db.budget) ...[
          TFCard(
            padding: const EdgeInsets.all(11),
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: tfCatColor(b.hue),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b.label,
                        style: TFText.sans(size: 14, color: c.text),
                      ),
                    ),
                    if (b.over) ...[
                      const TFPill(label: 'Over', tone: PillTone.neg),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${b.pct}%',
                      style: TFText.num(
                        size: 13.5,
                        color: b.over ? c.neg : c.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                TFProgress(pct: b.pct, color: tfCatColor(b.hue), over: b.over),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${TFData.fmt(b.spent)} spent',
                      style: TFText.sans(size: 11.5, color: c.textDim),
                    ),
                    Text(
                      'of ${TFData.fmt(b.alloc)}',
                      style: TFText.sans(size: 11.5, color: c.textDim),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
