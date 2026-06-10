import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_charts.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_rows.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_segmented.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The "Reports" tab: period toggle, bar chart, expense donut, top programs.
class ReportsPage extends StatefulWidget {
  const ReportsPage({required this.nav, super.key});

  final TFNav nav;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _period = '6M';

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final topPrograms = [...db.programs]
      ..sort((a, b) => b.profit.compareTo(a.profit));
    final top = topPrograms.take(4).toList();

    return TFScreen(
      header: const TFAppBar(
        eyebrow: 'Analytics',
        title: 'Reports',
        trailing: TFIconButton(icon: Icons.file_download_outlined),
      ),
      children: [
        TFSegmented<String>(
          value: _period,
          options: const ['1M', '3M', '6M', 'YTD'],
          labelOf: (s) => s,
          onChanged: (s) => setState(() => _period = s),
        ),
        const SizedBox(height: 14),

        // Net profit + bar pairs.
        TFCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Net profit',
                        style: TFText.sans(size: 12.5, color: c.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TFData.fmt(db.netProfit),
                        style: TFText.num(size: 26, color: c.pos),
                      ),
                    ],
                  ),
                  const TFPill(
                    label: '+26% QoQ',
                    tone: PillTone.pos,
                    leading: Icon(Icons.auto_awesome),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TFBarPairs(
                income: db.incomeSeries,
                expense: db.expenseSeries,
                labels: db.months,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TFLegend(color: c.pos, label: 'Income'),
                  const SizedBox(width: 16),
                  TFLegend(color: c.neg, label: 'Expenses'),
                ],
              ),
            ],
          ),
        ),

        // Expense breakdown.
        TFSectionLabel(
          title: 'Expense breakdown',
          action: 'Details',
          onAction: () => widget.nav.push(TFScreens.budgets),
        ),
        TFCard(
          child: Row(
            children: [
              TFDonut(
                size: 108,
                stroke: 14,
                segments: [
                  for (final b in db.budget)
                    DonutSegment(b.spent, tfCatColor(b.hue)),
                ],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TFData.fmtK(db.totalSpent),
                      style: TFText.num(size: 16, color: c.text),
                    ),
                    Text(
                      'total',
                      style: TFText.sans(size: 9.5, color: c.textDim),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final b in db.budget.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: tfCatColor(b.hue),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TFText.sans(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: c.textMuted,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            Text(
                              TFData.fmtK(b.spent),
                              style: TFText.num(size: 12, color: c.text),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Top programs.
        TFSectionLabel(
          title: 'Top programs by profit',
          action: 'P&L',
          onAction: () => widget.nav.push(TFScreens.pnl),
        ),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, p) in top.indexed)
                TFRow(
                  first: i == 0,
                  onTap: () => widget.nav.push(TFScreens.program, {'id': p.id}),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text(
                          '${i + 1}',
                          style: TFText.num(size: 13, color: c.textDim),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TFGlyphBadge(
                        size: 36,
                        radius: 11,
                        hue: p.hue,
                        child: Text(p.code.substring(0, 2)),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: TFRowMain(
                          title: p.name,
                          subtitle: '${p.marginPct}% margin',
                        ),
                      ),
                      Text(
                        TFData.fmtK(p.profit),
                        style: TFText.num(size: 14, color: c.pos),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
