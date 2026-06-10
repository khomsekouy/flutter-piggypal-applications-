import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_rows.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Pushed participant profile: payment progress + linked program.
class ParticipantDetailPage extends StatelessWidget {
  const ParticipantDetailPage({
    required this.nav,
    required this.id,
    super.key,
  });

  final TFNav nav;
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final u = db.participants.firstWhere((x) => x.id == id);
    final pr = db.program(u.programId);

    return TFScreen(
      header: TFBackBar(
        title: 'Participant',
        onBack: nav.back,
        trailing: const TFIconButton(icon: Icons.more_horiz),
      ),
      children: [
        // Profile card.
        TFCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              TFAvatar(name: u.name, hue: u.hue, size: 68),
              const SizedBox(height: 12),
              Text(
                u.name,
                style: TFText.sans(
                  size: 20,
                  weight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Enrolled ${u.enrolled} · ${pr.code}',
                style: TFText.sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: c.textMuted,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              TFStatusPill.pay(u.pay),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Payment progress.
        TFCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment progress',
                    style: TFText.sans(size: 13, color: c.textMuted),
                  ),
                  Text(
                    '${u.pct}%',
                    style: TFText.sans(
                      size: 13,
                      weight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              TFProgress(pct: u.pct, color: c.pos),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TFData.fmt(u.paid),
                        style: TFText.num(size: 18, color: c.pos),
                      ),
                      Text(
                        'paid',
                        style: TFText.sans(size: 11, color: c.textDim),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TFData.fmt(u.due),
                        style: TFText.num(
                          size: 18,
                          color: u.due > 0 ? c.neg : c.text,
                        ),
                      ),
                      Text(
                        'balance due',
                        style: TFText.sans(size: 11, color: c.textDim),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Linked program.
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TFRow(
            first: true,
            onTap: () => nav.push(TFScreens.program, {'id': pr.id}),
            child: Row(
              children: [
                TFGlyphBadge(
                  radius: 13,
                  hue: pr.hue,
                  child: Text(pr.code.substring(0, 2)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: TFRowMain(title: pr.name, subtitle: pr.category),
                ),
                Icon(Icons.chevron_right, size: 18, color: c.textMuted),
              ],
            ),
          ),
        ),

        if (u.due > 0) ...[
          const SizedBox(height: 16),
          _PrimaryButton(
            icon: Icons.credit_card,
            label: 'Record payment · ${TFData.fmt(u.due)}',
            onTap: nav.back,
          ),
        ],
      ],
    );
  }
}

/// Full-width primary action button (the prototype's `.btn--primary`).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
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
          color: c.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: c.primaryInk),
            const SizedBox(width: 8),
            Text(
              label,
              style: TFText.sans(
                size: 15,
                weight: FontWeight.w700,
                color: c.primaryInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
