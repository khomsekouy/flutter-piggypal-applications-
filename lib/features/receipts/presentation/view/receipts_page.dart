import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_charts.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Receipt capture CTA + matched/needs-review counts + a thumbnail gallery.
class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({required this.nav, super.key});

  final TFNav nav;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final matched = db.receipts
        .where((r) => r.status == ReceiptStatus.matched)
        .length;
    final pending = db.receipts.length - matched;

    return TFScreen(
      header: TFBackBar(
        title: 'Receipts',
        onBack: nav.back,
        trailing: const TFIconButton(icon: Icons.search),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _CountStat(
                value: '$matched',
                label: 'Matched',
                color: c.pos,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CountStat(
                value: '$pending',
                label: 'Needs review',
                color: c.warn,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Scan CTA.
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.primaryLine),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scan a receipt',
                        style: TFText.sans(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-extract vendor, total & date',
                        style: TFText.sans(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: c.textMuted,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: c.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        const TFSectionLabel(title: 'Recent receipts'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: db.receipts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 196,
          ),
          itemBuilder: (context, i) {
            final r = db.receipts[i];
            return TFCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flexes to fill leftover cell height so the card content
                  // never overflows, whatever the text scale.
                  Expanded(
                    child: TFPlaceholder(
                      label:
                          'RECEIPT\n${r.vendor.split(' ').first.toUpperCase()}',
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TFData.fmt(r.amount),
                        style: TFText.num(size: 15, color: c.text),
                      ),
                      Text(
                        r.date,
                        style: TFText.sans(size: 11, color: c.textDim),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    r.vendor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TFText.sans(
                      size: 12,
                      color: c.text,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TFStatusPill.receipt(r.status),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CountStat extends StatelessWidget {
  const _CountStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
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
          Text(value, style: TFText.num(size: 20, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TFText.sans(size: 12, color: c.textMuted)),
        ],
      ),
    );
  }
}
