import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/programs/domain/entities/program.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// A program summary card used on the Programs list.
class ProgramCard extends StatelessWidget {
  const ProgramCard({required this.program, this.onTap, super.key});

  final Program program;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final p = program;
    return TFCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TFGlyphBadge(
                size: 44,
                radius: 14,
                hue: p.hue,
                child: Text(p.code.substring(0, 2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.code,
                          style: TFText.mono(size: 10.5, color: c.textDim),
                        ),
                        _statusPill(p.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TFText.sans(
                        size: 15.5,
                        weight: FontWeight.w700,
                        color: c.text,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.category} · ${p.trainer}',
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TFMetric(
                label: 'Net',
                value: TFData.fmtK(p.profit),
                tone: p.profit >= 0 ? c.pos : c.neg,
              ),
              const SizedBox(width: 18),
              TFMetric(label: 'Enrolled', value: '${p.enrolled}/${p.capacity}'),
              const SizedBox(width: 18),
              TFMetric(
                label: 'Budget used',
                value: '${p.budgetUsedPct}%',
                tone: p.budgetUsedPct > 90 ? c.warn : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TFProgress(
            pct: p.budgetUsedPct,
            color: tfCatColor(p.hue),
            over: p.budgetUsedPct > 100,
          ),
        ],
      ),
    );
  }
}

/// Maps the domain [ProgramStatus] onto the shared status pill.
TFPill _statusPill(ProgramStatus status) {
  final (PillTone tone, String label) = switch (status) {
    ProgramStatus.active => (PillTone.pos, 'Active'),
    ProgramStatus.upcoming => (PillTone.primary, 'Upcoming'),
    ProgramStatus.completed => (PillTone.muted, 'Completed'),
  };
  return TFPill(
    label: label,
    tone: tone,
    dot: status != ProgramStatus.completed,
  );
}
