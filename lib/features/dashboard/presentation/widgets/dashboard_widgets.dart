import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/dashboard/data/budget_store.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Formats a dollar amount with thousands separators and two decimals.
///
/// Shared by the dashboard pages (Home, Categories, History) and the category
/// detail screen so the currency rendering stays consistent.
String formatMoney(double n) {
  final parts = n.toStringAsFixed(2).split('.');
  final whole = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return '\$$buf.${parts[1]}';
}

/// The rounded search field used across the dashboard pages.
class DashboardSearchField extends StatelessWidget {
  const DashboardSearchField({
    required this.onChanged,
    this.hint = 'Search',
    super.key,
  });

  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 19, color: c.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              cursorColor: c.primary,
              style: TFText.sans(size: 14, color: c.text, letterSpacing: 0),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TFText.sans(size: 14, color: c.textDim),
              ),
            ),
          ),
          Icon(Icons.tune, size: 19, color: c.textMuted),
        ],
      ),
    );
  }
}

/// A budget category tile: icon + label, budget/spent lines and a usage bar.
class CategoryCard extends StatelessWidget {
  const CategoryCard({required this.cat, required this.onTap, super.key});

  final BudgetCat cat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final color = cat.color;
    final spentColor = cat.over || cat.pct >= 50 ? c.neg : c.pos;
    return TFCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(cat.icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TFText.sans(size: 14.5, color: c.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _MetaLine(
            label: 'Budget',
            value: formatMoney(cat.budget),
            color: c.textMuted,
          ),
          const SizedBox(height: 3),
          _MetaLine(
            label: 'Spent',
            value: formatMoney(cat.spent),
            color: spentColor,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: TFProgress(pct: cat.pct, color: color, over: cat.over),
              ),
              const SizedBox(width: 8),
              Text(
                '${cat.pct}%',
                style: TFText.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Row(
      children: [
        Text('$label ', style: TFText.sans(size: 12, color: c.textDim)),
        Text(
          value,
          style: TFText.sans(size: 12.5, weight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

/// One income/expense row in a transaction history list (green/red by type).
class TxHistoryRow extends StatelessWidget {
  const TxHistoryRow({required this.tx, required this.first, super.key});

  final RecentTx tx;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final inc = tx.isIncome;
    final tone = inc ? c.pos : c.neg;
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
              color: inc ? c.posSoft : c.negSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              inc ? Icons.south_rounded : Icons.north_rounded,
              size: 18,
              color: tone,
            ),
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
            '${inc ? '+' : '-'}${formatMoney(tx.amount)}',
            style: TFText.num(size: 14.5, color: tone),
          ),
        ],
      ),
    );
  }
}
