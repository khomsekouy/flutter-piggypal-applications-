import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_charts.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_rows.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Pushed program detail: header, P&L, budget, participants & transactions.
class ProgramDetailPage extends StatelessWidget {
  const ProgramDetailPage({required this.nav, required this.id, super.key});

  final TFNav nav;
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final p = db.program(id);
    final parts = db.participants.where((u) => u.programId == p.id).toList();
    final txs = db.tx.where((t) => t.programId == p.id).toList();

    return TFScreen(
      header: TFBackBar(
        title: 'Program',
        onBack: nav.back,
        trailing: const TFIconButton(icon: Icons.more_horiz),
      ),
      children: [
        // Header card.
        TFCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TFGlyphBadge(
                    size: 48,
                    radius: 15,
                    hue: p.hue,
                    child: Text(p.code.substring(0, 2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.code,
                          style: TFText.mono(size: 10.5, color: c.textDim),
                        ),
                        TFStatusPill.program(p.status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                p.name,
                style: TFText.sans(
                  size: 20,
                  weight: FontWeight.w700,
                  color: c.text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.people_outline,
                text: '${p.enrolled} of ${p.capacity} enrolled · ${p.trainer}',
              ),
              const SizedBox(height: 7),
              _InfoLine(
                icon: Icons.calendar_today_outlined,
                text: '${p.start} – ${p.end} · ${p.weeks} weeks',
              ),
              const SizedBox(height: 7),
              _InfoLine(icon: Icons.location_on_outlined, text: p.location),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // P&L tiles.
        Row(
          children: [
            Expanded(
              child: TFTile(
                icon: Icons.south_rounded,
                tone: c.pos,
                label: 'Income',
                value: TFData.fmt(p.income),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TFTile(
                icon: Icons.north_rounded,
                tone: c.neg,
                label: 'Expenses',
                value: TFData.fmt(p.spent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TFCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Net profit',
                    style: TFText.sans(
                      size: 12.5,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    TFData.fmt(p.profit),
                    style: TFText.num(size: 26, color: c.pos),
                  ),
                ],
              ),
              TFDonut(
                size: 84,
                stroke: 12,
                segments: [
                  DonutSegment(p.spent, c.neg),
                  DonutSegment(p.profit, c.pos),
                ],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${p.marginPct}%',
                      style: TFText.num(size: 17, color: c.text),
                    ),
                    Text(
                      'margin',
                      style: TFText.sans(
                        size: 9.5,
                        color: c.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Budget.
        const TFSectionLabel(title: 'Budget'),
        TFCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${TFData.fmt(p.spent)} of ${TFData.fmt(p.budget)}',
                    style: TFText.sans(
                      size: 13,
                      color: c.textMuted,
                    ),
                  ),
                  Text(
                    '${p.budgetUsedPct}%',
                    style: TFText.sans(
                      size: 13,
                      weight: FontWeight.w700,
                      color: p.budgetUsedPct > 90 ? c.warn : c.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              TFProgress(
                pct: p.budgetUsedPct,
                color: tfCatColor(p.hue),
                over: p.budgetUsedPct > 100,
              ),
              const SizedBox(height: 8),
              Text(
                '${TFData.fmt(p.budget - p.spent)} remaining',
                style: TFText.sans(
                  size: 12,
                  color: c.textDim,
                ),
              ),
            ],
          ),
        ),

        // Participants preview.
        TFSectionLabel(
          title: 'Participants · ${parts.length}',
          action: 'View all',
          onAction: () => nav.push(TFScreens.participants, {'program': p.id}),
        ),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, u) in parts.take(4).indexed)
                TFRow(
                  first: i == 0,
                  onTap: () => nav.push(TFScreens.participant, {'id': u.id}),
                  child: Row(
                    children: [
                      TFAvatar(name: u.name, hue: u.hue),
                      const SizedBox(width: 13),
                      Expanded(
                        child: TFRowMain(
                          title: u.name,
                          subtitle: 'Enrolled ${u.enrolled}',
                        ),
                      ),
                      TFStatusPill.pay(u.pay),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Transactions preview.
        TFSectionLabel(
          title: 'Transactions',
          action: 'See all',
          onAction: () => nav.push(TFScreens.txList, {'program': p.id}),
        ),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, t) in txs.take(5).indexed)
                TxRow(
                  tx: t,
                  first: i == 0,
                  onTap: () => nav.push(TFScreens.txDetail, {'id': t.id}),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Row(
      children: [
        Icon(icon, size: 15, color: c.textDim),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TFText.sans(
              size: 13,
              weight: FontWeight.w500,
              color: c.textMuted,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
