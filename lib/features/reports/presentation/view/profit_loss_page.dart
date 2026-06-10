import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// A proper income statement, reconciled to the headline net across screens.
class ProfitLossPage extends StatelessWidget {
  const ProfitLossPage({required this.nav, super.key});

  final TFNav nav;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;

    // Revenue lines from income categories, scaled to the headline total.
    final revenueRaw = <(String, double)>[];
    for (final cat in db.incomeCats) {
      final amount = db.tx
          .where((t) => t.isIncome && t.cat == cat.id)
          .fold<double>(0, (s, t) => s + t.amount);
      if (amount > 0) revenueRaw.add((cat.label, amount));
    }
    final revShown = revenueRaw.fold<double>(0, (s, r) => s + r.$2);
    final revScale = db.totalIncome / (revShown == 0 ? 1 : revShown);
    final revenue = [
      for (final r in revenueRaw) (r.$1, (r.$2 * revScale).round().toDouble()),
    ];

    // Expense lines scaled so operating expenses reconcile with the headline.
    final expRaw = db.budget.fold<double>(0, (s, b) => s + b.spent);
    final expScale = db.totalExpense / (expRaw == 0 ? 1 : expRaw);
    final expenses = [
      for (final b in db.budget)
        (b.label, (b.spent * expScale).round().toDouble()),
    ];

    final net = db.totalIncome - db.totalExpense;
    final margin = ((net / db.totalIncome) * 100).round();

    return TFScreen(
      header: TFBackBar(
        title: 'Profit & Loss',
        onBack: nav.back,
        trailing: const TFIconButton(icon: Icons.file_download_outlined),
      ),
      children: [
        // Net hero.
        TFCard(
          padding: const EdgeInsets.all(18),
          borderColor: c.pos.withValues(alpha: 0.30),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color.lerp(c.surface, c.pos, 0.16)!, c.surface],
            stops: const [0, 0.6],
          ),
          child: Column(
            children: [
              Text(
                'Net profit · ${db.org.period}',
                style: TFText.sans(size: 12.5, color: c.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                TFData.fmt(net),
                style: TFText.num(size: 36, color: c.pos, letterSpacing: -1.5),
              ),
              const SizedBox(height: 2),
              Text(
                '$margin% net margin',
                style: TFText.sans(size: 13, color: c.textMuted),
              ),
            ],
          ),
        ),

        const TFSectionLabel(title: 'Revenue'),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (final r in revenue) _StatementRow(label: r.$1, value: r.$2),
              _StatementRow(
                label: 'Total revenue',
                value: db.totalIncome,
                bold: true,
                tone: c.pos,
              ),
            ],
          ),
        ),

        const TFSectionLabel(title: 'Operating expenses'),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (final e in expenses)
                _StatementRow(label: e.$1, value: -e.$2),
              _StatementRow(
                label: 'Total expenses',
                value: -db.totalExpense,
                bold: true,
                tone: c.neg,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        TFCard(
          borderColor: c.primaryLine,
          color: c.primarySoft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net profit',
                style: TFText.sans(
                  size: 16,
                  weight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              Text(TFData.fmt(net), style: TFText.num(size: 22, color: c.pos)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const TFButton.ghost(
          label: 'Export statement (PDF)',
          icon: Icons.file_download_outlined,
        ),
      ],
    );
  }
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.tone,
  });

  final String label;
  final double value;
  final bool bold;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final neg = value < 0;
    final text = neg ? '(${TFData.fmt(-value)})' : TFData.fmt(value);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: bold ? Border(top: BorderSide(color: c.lineStrong)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TFText.sans(
              size: 14,
              weight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? c.text : c.textMuted,
              letterSpacing: 0,
            ),
          ),
          Text(
            text,
            style: TFText.num(
              size: 14.5,
              weight: bold ? FontWeight.w700 : FontWeight.w600,
              color: tone ?? c.text,
            ),
          ),
        ],
      ),
    );
  }
}
