import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_charts.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Pushed transaction detail with metadata and receipt slot.
class TxDetailPage extends StatelessWidget {
  const TxDetailPage({required this.nav, required this.id, super.key});

  final TFNav nav;
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final t = db.tx.firstWhere((x) => x.id == id);
    final inc = t.isIncome;
    final pr = db.programOrNull(t.programId);

    return TFScreen(
      header: TFBackBar(
        title: 'Transaction',
        onBack: nav.back,
        trailing: const TFIconButton(icon: Icons.more_horiz),
      ),
      children: [
        // Amount hero.
        TFCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TFGlyphBadge(
                size: 56,
                radius: 18,
                bg: inc ? c.posSoft : c.negSoft,
                fg: inc ? c.pos : c.neg,
                child: Icon(
                  inc ? Icons.south_rounded : Icons.north_rounded,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${inc ? '+' : '–'}${TFData.fmt(t.amount)}',
                style: TFText.num(
                  size: 34,
                  color: inc ? c.pos : c.text,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.title,
                textAlign: TextAlign.center,
                style: TFText.sans(size: 14, color: c.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Metadata.
        TFCard(
          child: Column(
            children: [
              TFDetailRow(label: 'Type', value: inc ? 'Income' : 'Expense'),
              TFDetailRow(label: 'Category', value: db.catLabel(t.cat)),
              TFDetailRow(label: 'Date', value: '${t.date}, 2026'),
              TFDetailRow(label: 'Method', value: t.method),
              TFDetailRow(label: 'Program', value: pr?.name ?? '—', last: true),
            ],
          ),
        ),

        const TFSectionLabel(title: 'Receipt'),
        if (t.receipt)
          TFCard(
            child: Row(
              children: [
                const TFPlaceholder(label: 'JPG', width: 54, height: 68),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Receipt attached',
                        style: TFText.sans(size: 14, color: c.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to preview · matched',
                        style: TFText.sans(
                          size: 12,
                          weight: FontWeight.w500,
                          color: c.textDim,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const TFStatusPill.receipt(ReceiptStatus.matched),
              ],
            ),
          )
        else
          _GhostButton(
            icon: Icons.photo_camera_outlined,
            label: 'Attach receipt',
            onTap: () => nav.push(TFScreens.receipts),
          ),
      ],
    );
  }
}

/// Full-width secondary button (the prototype's `.btn--ghost`).
class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: c.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: c.text),
            const SizedBox(width: 8),
            Text(
              label,
              style: TFText.sans(
                size: 15,
                weight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
