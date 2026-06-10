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

/// The "More" tab: module shortcuts, appearance tweaks, settings.
class MorePage extends StatelessWidget {
  const MorePage({required this.nav, super.key});

  final TFNav nav;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final scope = TFThemeScope.of(context);
    final theme = context.tf;

    final items = <_ModuleItem>[
      _ModuleItem(
        Icons.people_outline,
        'Participants',
        '${db.participants.length} enrolled',
        262,
        () => nav.push(TFScreens.participants),
      ),
      _ModuleItem(
        Icons.south_rounded,
        'Income',
        '${TFData.fmtK(db.totalIncome)} collected',
        152,
        () => nav.push(TFScreens.txList, {'kind': TxKind.income}),
      ),
      _ModuleItem(
        Icons.north_rounded,
        'Expenses',
        '${TFData.fmtK(db.totalExpense)} spent',
        8,
        () => nav.push(TFScreens.txList, {'kind': TxKind.expense}),
      ),
      _ModuleItem(
        Icons.track_changes,
        'Budgets',
        '${db.budgetUsedPct}% used',
        38,
        () => nav.push(TFScreens.budgets),
      ),
      _ModuleItem(
        Icons.receipt_long_outlined,
        'Receipts',
        '${db.receipts.length} this period',
        192,
        () => nav.push(TFScreens.receipts),
      ),
      _ModuleItem(
        Icons.balance,
        'Profit & Loss',
        '${TFData.fmtK(db.netProfit)} net',
        218,
        () => nav.push(TFScreens.pnl),
      ),
    ];

    return TFScreen(
      header: TFAppBar(eyebrow: db.org.name, title: 'More'),
      children: [
        for (final it in items) ...[
          TFCard(
            padding: const EdgeInsets.all(11),
            radius: 18,
            onTap: it.onTap,
            child: Row(
              children: [
                TFGlyphBadge(
                  size: 42,
                  radius: 13,
                  hue: it.hue,
                  child: Icon(it.icon),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        it.label,
                        style: TFText.sans(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        it.sub,
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
          const SizedBox(height: 10),
        ],

        // Appearance tweaks (live re-tint of the whole module).
        const TFSectionLabel(title: 'Appearance'),
        TFCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accent', style: TFText.sans(size: 13, color: c.textMuted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final accent in TFTheme.accents)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => scope.setAccent(accent),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.accent == accent
                                  ? c.text
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: theme.accent == accent
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Theme', style: TFText.sans(size: 13, color: c.textMuted)),
              const SizedBox(height: 10),
              TFSegmented<TFMode>(
                value: theme.mode,
                options: const [TFMode.dark, TFMode.light],
                labelOf: (m) => m == TFMode.dark ? 'Dark' : 'Light',
                onChanged: scope.setMode,
              ),
              const SizedBox(height: 16),
              Text('Density', style: TFText.sans(size: 13, color: c.textMuted)),
              const SizedBox(height: 10),
              TFSegmented<TFDensity>(
                value: theme.density,
                options: const [
                  TFDensity.compact,
                  TFDensity.regular,
                  TFDensity.comfortable,
                ],
                labelOf: (d) => switch (d) {
                  TFDensity.compact => 'Compact',
                  TFDensity.regular => 'Regular',
                  TFDensity.comfortable => 'Comfortable',
                },
                onChanged: scope.setDensity,
              ),
            ],
          ),
        ),

        // Settings list.
        const TFSectionLabel(title: 'Settings'),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, s) in const [
                ('Organization profile', Icons.grid_view_rounded),
                ('Team & permissions', Icons.people_outline),
                ('Tax & currency', Icons.sell_outlined),
                ('Notifications', Icons.notifications_outlined),
              ].indexed)
                TFRow(
                  first: i == 0,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Icon(s.$2, size: 18, color: c.textMuted),
                      ),
                      const SizedBox(width: 13),
                      Expanded(child: TFRowMain(title: s.$1)),
                      Icon(Icons.chevron_right, size: 17, color: c.textMuted),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Training Finance · v1.0 · ${db.org.name}',
            style: TFText.sans(
              size: 11.5,
              weight: FontWeight.w500,
              color: c.textDim,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuleItem {
  const _ModuleItem(this.icon, this.label, this.sub, this.hue, this.onTap);

  final IconData icon;
  final String label;
  final String sub;
  final double hue;
  final VoidCallback onTap;
}
