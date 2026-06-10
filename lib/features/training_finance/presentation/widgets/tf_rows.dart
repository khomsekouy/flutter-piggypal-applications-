import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// A divider-separated list row (vertical padding honours density).
class TFRow extends StatelessWidget {
  const TFRow({
    required this.child,
    this.onTap,
    this.first = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final padV = context.tf.rowPadV;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padV),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: c.line)),
        ),
        child: child,
      ),
    );
  }
}

/// Title-over-subtitle text block for list rows.
class TFRowMain extends StatelessWidget {
  const TFRowMain({
    required this.title,
    this.subtitle,
    this.titleWeight = FontWeight.w600,
    super.key,
  });

  final String title;
  final String? subtitle;
  final FontWeight titleWeight;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TFText.sans(size: 14.5, weight: titleWeight, color: c.text),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TFText.sans(
              size: 12.5,
              weight: FontWeight.w500,
              color: c.textMuted,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}

/// A single income/expense transaction row.
class TxRow extends StatelessWidget {
  const TxRow({required this.tx, this.onTap, this.first = false, super.key});

  final Tx tx;
  final VoidCallback? onTap;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final inc = tx.isIncome;
    final db = TFData.instance;
    return TFRow(
      onTap: onTap,
      first: first,
      child: Row(
        children: [
          TFGlyphBadge(
            radius: 13,
            bg: inc ? c.posSoft : c.negSoft,
            fg: inc ? c.pos : c.neg,
            child: Icon(
              inc ? Icons.south_rounded : Icons.north_rounded,
              size: 19,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: TFRowMain(
              title: tx.title,
              subtitle:
                  '${db.catLabel(tx.cat)} · ${tx.date}'
                  '${tx.receipt ? ' · 📎' : ''}',
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${inc ? '+' : '–'}${TFData.fmt(tx.amount)}',
                style: TFText.num(size: 15, color: inc ? c.pos : c.text),
              ),
              const SizedBox(height: 1),
              Text(
                tx.method,
                style: TFText.sans(
                  size: 11,
                  color: c.textDim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
