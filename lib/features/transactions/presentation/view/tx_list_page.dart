import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_rows.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_segmented.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Transaction list — all/income/expense, optionally scoped to a program.
class TxListPage extends StatefulWidget {
  const TxListPage({
    required this.nav,
    this.presetKind,
    this.programId,
    super.key,
  });

  final TFNav nav;
  final TxKind? presetKind;
  final String? programId;

  @override
  State<TxListPage> createState() => _TxListPageState();
}

class _TxListPageState extends State<TxListPage> {
  // null = "all"
  late TxKind? _seg = widget.presetKind;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;

    var list = db.tx;
    if (widget.programId != null) {
      list = list.where((t) => t.programId == widget.programId).toList();
    }
    if (_seg != null) list = list.where((t) => t.kind == _seg).toList();

    final income = list
        .where((t) => t.isIncome)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = list
        .where((t) => !t.isIncome)
        .fold<double>(0, (s, t) => s + t.amount);

    final isPush = widget.programId != null || widget.presetKind != null;
    final title = widget.programId != null
        ? 'Transactions'
        : switch (_seg) {
            TxKind.income => 'Income',
            TxKind.expense => 'Expenses',
            null => 'Transactions',
          };

    return TFScreen(
      pinnedHeader: true,
      header: isPush
          ? TFBackBar(
              title: title,
              onBack: widget.nav.back,
              trailing: const TFIconButton(icon: Icons.tune),
            )
          : TFAppBar(
              eyebrow: 'All accounts',
              title: title,
              trailing: const TFIconButton(icon: Icons.tune),
            ),
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Income',
                value: TFData.fmtK(income),
                color: c.pos,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                label: 'Expenses',
                value: TFData.fmtK(expense),
                color: c.neg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TFSegmented<TxKind?>(
          value: _seg,
          options: const [null, TxKind.income, TxKind.expense],
          labelOf: (s) => switch (s) {
            null => 'All',
            TxKind.income => 'Income',
            TxKind.expense => 'Expenses',
          },
          onChanged: (s) => setState(() => _seg = s),
        ),
        const SizedBox(height: 8),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, t) in list.indexed)
                TxRow(
                  tx: t,
                  first: i == 0,
                  onTap: () =>
                      widget.nav.push(TFScreens.txDetail, {'id': t.id}),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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
    return TFCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TFText.sans(size: 11.5, color: c.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: TFText.num(size: 18, color: color)),
        ],
      ),
    );
  }
}
