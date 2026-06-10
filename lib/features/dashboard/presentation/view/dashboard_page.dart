import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_charts.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_rows.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The "Overview" tab: cash hero, quick actions, KPIs, active programs, recent.
class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.nav, super.key});

  final TFNav nav;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    return TFScreen(
      padBody: false,
      header: TFAppBar(
        eyebrow: db.org.name,
        title: 'Overview',
        trailing: const TFIconButton(icon: Icons.notifications_outlined),
      ),
      children: [
        // Hero balance card.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TFCard(
            padding: const EdgeInsets.all(18),
            borderColor: c.primaryLine,
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.lerp(c.surface, c.primary, 0.24)!,
                c.surface,
              ],
              stops: const [0, 0.62],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cash on hand',
                      style: TFText.sans(
                        size: 12.5,
                        color: c.textMuted,
                      ),
                    ),
                    TFPill(label: db.org.period, tone: PillTone.primary),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  TFData.fmt(db.org.cash),
                  style: TFText.num(
                    size: 38,
                    color: c.text,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '▲ Net ${TFData.fmt(db.netProfit)}',
                      style: TFText.sans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: c.pos,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      '${TFData.fmt(db.outstanding)} outstanding',
                      style: TFText.sans(
                        size: 13,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TFAreaChart(income: db.incomeSeries, expense: db.expenseSeries),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final m in db.months)
                        Text(
                          m,
                          style: TFText.sans(
                            size: 10.5,
                            color: c.textDim,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TFLegend(color: c.pos, label: 'Income'),
                    const SizedBox(width: 16),
                    TFLegend(color: c.neg, label: 'Expenses', dashed: true),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Quick actions.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.south_rounded,
                  label: 'Add income',
                  fg: c.pos,
                  bg: c.posSoft,
                  onTap: () => nav.push(TFScreens.add, {'kind': TxKind.income}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.north_rounded,
                  label: 'Add expense',
                  fg: c.neg,
                  bg: c.negSoft,
                  onTap: () =>
                      nav.push(TFScreens.add, {'kind': TxKind.expense}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.photo_camera_outlined,
                  label: 'Scan receipt',
                  fg: c.primary,
                  bg: c.primarySoft,
                  onTap: () => nav.push(TFScreens.receipts),
                ),
              ),
            ],
          ),
        ),

        // KPI tiles.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TFTile(
                      icon: Icons.south_rounded,
                      tone: c.pos,
                      label: 'Income',
                      value: TFData.fmtK(db.totalIncome),
                      delta: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TFTile(
                      icon: Icons.north_rounded,
                      tone: c.neg,
                      label: 'Expenses',
                      value: TFData.fmtK(db.totalExpense),
                      delta: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TFTile(
                      icon: Icons.balance,
                      tone: c.primary,
                      label: 'Net profit',
                      value: TFData.fmtK(db.netProfit),
                      delta: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TFTile(
                      icon: Icons.track_changes,
                      tone: c.warn,
                      label: 'Budget used',
                      value: '${db.budgetUsedPct}%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Active programs (horizontal).
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TFSectionLabel(
            title: 'Active programs',
            action: 'See all',
            onAction: () => nav.tab(TFTabs.programs),
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            itemCount: db.programs
                .where((p) => p.status == ProgramStatus.active)
                .length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = db.programs
                  .where((p) => p.status == ProgramStatus.active)
                  .elementAt(i);
              return _ActiveProgramCard(
                program: p,
                onTap: () => nav.push(TFScreens.program, {'id': p.id}),
              );
            },
          ),
        ),

        // Recent activity.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              TFSectionLabel(
                title: 'Recent activity',
                action: 'See all',
                onAction: () => nav.push(TFScreens.txList, {'filter': 'all'}),
              ),
              TFCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (final (i, t) in db.tx.take(5).indexed)
                      TxRow(
                        tx: t,
                        first: i == 0,
                        onTap: () => nav.push(TFScreens.txDetail, {'id': t.id}),
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TFText.sans(size: 11.5, color: c.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveProgramCard extends StatelessWidget {
  const _ActiveProgramCard({required this.program, required this.onTap});

  final Program program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final p = program;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TFGlyphBadge(
                  size: 36,
                  radius: 11,
                  hue: p.hue,
                  child: Text(p.code.substring(0, 2)),
                ),
                TFStatusPill.program(p.status),
              ],
            ),
            const SizedBox(height: 11),
            SizedBox(
              height: 34,
              child: Text(
                p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TFText.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: c.text,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TFData.fmtK(p.profit),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TFText.num(size: 16, color: c.pos),
                      ),
                      Text(
                        'net profit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TFText.sans(
                          size: 10.5,
                          color: c.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TFSpark(
                  data: [
                    p.budget * 0.2,
                    p.spent * 0.5,
                    p.income * 0.6,
                    p.income * 0.8,
                    p.income,
                  ],
                  color: tfCatColor(p.hue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
