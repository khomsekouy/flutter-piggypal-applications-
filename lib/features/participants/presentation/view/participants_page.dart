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

/// Roster of enrolled participants, optionally scoped to one program.
class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({required this.nav, this.programId, super.key});

  final TFNav nav;
  final String? programId;

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  PayStatus? _seg; // null = "all"

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final prog = db.programOrNull(widget.programId);

    var list = db.participants;
    if (widget.programId != null) {
      list = list.where((u) => u.programId == widget.programId).toList();
    }
    if (_seg != null) list = list.where((u) => u.pay == _seg).toList();

    final paid = db.participants.fold<double>(0, (s, u) => s + u.paid);
    final due = db.participants.fold<double>(0, (s, u) => s + u.due);

    return TFScreen(
      header: prog != null
          ? TFBackBar(title: 'Participants', onBack: widget.nav.back)
          : TFAppBar(
              eyebrow: '${db.participants.length} enrolled',
              title: 'Participants',
              trailing: const TFIconButton(icon: Icons.search),
            ),
      children: [
        if (prog == null) ...[
          TFCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Collected',
                        style: TFText.sans(size: 12, color: c.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TFData.fmt(paid),
                        style: TFText.num(size: 20, color: c.pos),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: c.line,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Outstanding',
                        style: TFText.sans(size: 12, color: c.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TFData.fmt(due),
                        style: TFText.num(size: 20, color: c.neg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        TFSegmented<PayStatus?>(
          value: _seg,
          options: const [null, ...PayStatus.values],
          labelOf: (s) => switch (s) {
            null => 'All',
            PayStatus.paid => 'Paid',
            PayStatus.partial => 'Partial',
            PayStatus.pending => 'Pending',
          },
          onChanged: (s) => setState(() => _seg = s),
        ),
        const SizedBox(height: 14),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No participants here.',
                      style: TFText.sans(
                        size: 13,
                        weight: FontWeight.w500,
                        color: c.textDim,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final (i, u) in list.indexed)
                      TFRow(
                        first: i == 0,
                        onTap: () => widget.nav.push(TFScreens.participant, {
                          'id': u.id,
                        }),
                        child: Row(
                          children: [
                            TFAvatar(name: u.name, hue: u.hue),
                            const SizedBox(width: 13),
                            Expanded(
                              child: TFRowMain(
                                title: u.name,
                                subtitle:
                                    '${db.program(u.programId).code} · '
                                    '${TFData.fmt(u.paid)} of '
                                    '${TFData.fmt(u.fee)}',
                              ),
                            ),
                            TFStatusPill.pay(u.pay),
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
