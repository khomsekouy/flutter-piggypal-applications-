import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/dashboard/data/budget_store.dart';
import 'package:flutter_piggypal_app/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_charts.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The "Home" tab: monthly budget overview broken down by category.
class DashboardPage extends StatefulWidget {
  const DashboardPage({required this.nav, super.key});

  final TFNav nav;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _query = '';

  /// How many category cards show on Home before "View all" opens the full
  /// categories page (a 2×2 preview).
  static const _catPreviewCount = 4;

  /// How many transactions preview on Home before "View all" opens history.
  static const _txPreviewCount = 10;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BudgetCat>>(
      valueListenable: BudgetStore.instance.cats,
      builder: (context, allCats, _) {
        final totalSpent = allCats.fold<double>(0, (s, x) => s + x.spent);
        final totalBudget = allCats.fold<double>(0, (s, x) => s + x.budget);
        final usedPct = totalBudget == 0
            ? 0
            : ((totalSpent / totalBudget) * 100).round();
        final remaining = totalBudget - totalSpent;

        final q = _query.trim().toLowerCase();
        final searching = q.isNotEmpty;
        final cats = searching
            ? allCats.where((x) => x.label.toLowerCase().contains(q)).toList()
            : allCats;

        // Home shows a 2×2 preview; "View all" opens the full categories page.
        // While searching we show every match inline.
        final visibleCats = searching
            ? cats
            : cats.take(_catPreviewCount).toList();
        final canViewAll = !searching && cats.length > _catPreviewCount;

        return TFScreen(
          header: const _Header(month: 'May 2025'),
          children: [
            // Hero balance card: headline spend, usage ring, budget split.
            _HeroBalance(
              spent: totalSpent,
              budget: totalBudget,
              usedPct: usedPct,
              remaining: remaining,
            ),

            // Categories.
            TFSectionLabel(
              title: 'Categories',
              action: canViewAll ? 'View all' : null,
              onAction: canViewAll
                  ? () => widget.nav.push(TFScreens.categories)
                  : null,
            ),
            DashboardSearchField(
              hint: 'Search categories',
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 14),
            if (cats.isEmpty)
              TFEmptyMessage('No categories match “$_query”.', topPadding: 30)
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.08,
                children: [
                  for (final cat in visibleCats)
                    CategoryCard(
                      cat: cat,
                      onTap: () => widget.nav.push(TFScreens.category, {
                        'label': cat.label,
                      }),
                    ),
                ],
              ),

            // Recent transaction history (preview; "View all" opens history).
            ValueListenableBuilder<List<RecentTx>>(
              valueListenable: BudgetStore.instance.recent,
              builder: (context, recent, _) {
                final shown = recent.take(_txPreviewCount).toList();
                return Column(
                  children: [
                    TFSectionLabel(
                      title: 'Recent History',
                      action: 'View all',
                      onAction: () => widget.nav.push(TFScreens.history),
                    ),
                    TFCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          for (final (i, tx) in shown.indexed)
                            TxHistoryRow(tx: tx, first: i == 0),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Top bar: overview eyebrow + month selector, with a trailing icon button.
class _Header extends StatelessWidget {
  const _Header({required this.month});

  final String month;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OVERVIEW',
                  style: TFText.mono(
                    size: 11,
                    color: c.textDim,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      month,
                      style: TFText.sans(
                        size: 23,
                        weight: FontWeight.w700,
                        color: c.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: c.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const TFIconButton(icon: Icons.notifications_none_rounded),
        ],
      ),
    );
  }
}

/// Bold gradient "balance" card: headline spend + usage ring + budget split.
class _HeroBalance extends StatelessWidget {
  const _HeroBalance({
    required this.spent,
    required this.budget,
    required this.usedPct,
    required this.remaining,
  });

  final double spent;
  final double budget;
  final int usedPct;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final accent = context.tf.accent;
    const ink = Colors.white;
    return TFCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      borderColor: Colors.transparent,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(accent, Colors.white, 0.14)!,
          accent,
          Color.lerp(accent, Colors.black, 0.26)!,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Spent',
                      style: TFText.sans(
                        size: 13,
                        color: ink.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatMoney(spent),
                      style: TFText.num(
                        size: 32,
                        color: ink,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '↑ 12% vs Apr',
                        style: TFText.sans(size: 11.5, color: ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TFDonut(
                size: 78,
                stroke: 8,
                segments: [
                  DonutSegment(usedPct.toDouble(), ink),
                  DonutSegment(
                    (100 - usedPct).toDouble(),
                    ink.withValues(alpha: 0.24),
                  ),
                ],
                center: Text(
                  '$usedPct%',
                  style: TFText.num(size: 16, color: ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: ink.withValues(alpha: 0.18)),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroStat(label: 'Budget', value: formatMoney(budget)),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 30,
                color: ink.withValues(alpha: 0.18),
              ),
              const SizedBox(width: 16),
              _HeroStat(
                label: 'Remaining',
                value: formatMoney(remaining < 0 ? 0 : remaining),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const ink = Colors.white;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TFText.sans(size: 11.5, color: ink.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TFText.num(size: 16, color: ink, letterSpacing: -0.4),
          ),
        ],
      ),
    );
  }
}
