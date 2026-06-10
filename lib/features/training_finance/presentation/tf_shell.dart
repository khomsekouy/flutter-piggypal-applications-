import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/budgets/presentation/view/budgets_page.dart';
import 'package:flutter_piggypal_app/features/dashboard/presentation/view/dashboard_page.dart';
import 'package:flutter_piggypal_app/features/more/presentation/view/more_page.dart';
import 'package:flutter_piggypal_app/features/participants/presentation/view/participant_detail_page.dart';
import 'package:flutter_piggypal_app/features/participants/presentation/view/participants_page.dart';
import 'package:flutter_piggypal_app/features/programs/presentation/view/program_detail_page.dart';
import 'package:flutter_piggypal_app/features/programs/presentation/view/programs_page.dart';
import 'package:flutter_piggypal_app/features/receipts/presentation/view/receipts_page.dart';
import 'package:flutter_piggypal_app/features/reports/presentation/view/profit_loss_page.dart';
import 'package:flutter_piggypal_app/features/reports/presentation/view/reports_page.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/view/add_transaction_page.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/view/tx_detail_page.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/view/tx_list_page.dart';

/// One entry on the in-shell push stack.
class _RouteEntry {
  const _RouteEntry(this.screen, this.params);
  final String screen;
  final Map<String, Object?> params;
}

/// Root of the Training Finance module: hosts the tab roots + push stack and a
/// custom bottom bar with a centre FAB, mirroring the prototype's navigation.
class TFShell extends StatefulWidget {
  const TFShell({super.key});

  @override
  State<TFShell> createState() => _TFShellState();
}

class _TFShellState extends State<TFShell> implements TFNav {
  String _tab = TFTabs.dashboard;
  final List<_RouteEntry> _stack = [];

  @override
  void tab(String name) => setState(() {
    _stack.clear();
    _tab = name;
  });

  @override
  void push(String screen, [Map<String, Object?> params = const {}]) =>
      setState(() => _stack.add(_RouteEntry(screen, params)));

  @override
  void back() => setState(() {
    if (_stack.isNotEmpty) _stack.removeLast();
  });

  @override
  void reset() => setState(_stack.clear);

  Widget _buildTab(String tab) => switch (tab) {
    TFTabs.programs => ProgramsPage(nav: this),
    TFTabs.reports => ReportsPage(nav: this),
    TFTabs.more => MorePage(nav: this),
    _ => DashboardPage(nav: this),
  };

  Widget _buildPushed(_RouteEntry e) {
    final p = e.params;
    return switch (e.screen) {
      TFScreens.program => ProgramDetailPage(
        nav: this,
        id: p['id']! as String,
      ),
      TFScreens.participants => ParticipantsPage(
        nav: this,
        programId: p['program'] as String?,
      ),
      TFScreens.participant => ParticipantDetailPage(
        nav: this,
        id: p['id']! as String,
      ),
      TFScreens.txList => TxListPage(
        nav: this,
        presetKind: p['kind'] as TxKind?,
        programId: p['program'] as String?,
      ),
      TFScreens.txDetail => TxDetailPage(nav: this, id: p['id']! as String),
      TFScreens.budgets => BudgetsPage(nav: this),
      TFScreens.receipts => ReceiptsPage(nav: this),
      TFScreens.pnl => ProfitLossPage(nav: this),
      TFScreens.add => AddTransactionPage(
        nav: this,
        presetKind: p['kind'] as TxKind?,
      ),
      _ => DashboardPage(nav: this),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final top = _stack.isEmpty ? null : _stack.last;
    final isAdd = top?.screen == TFScreens.add;
    final pushed = top != null;

    final body = pushed ? _buildPushed(top) : _buildTab(_tab);
    final key = pushed ? 'push-${_stack.length}-${top.screen}' : 'tab-$_tab';

    return PopScope(
      canPop: _stack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: const Cubic(0.2, 0.7, 0.3, 1),
                transitionBuilder: (child, anim) {
                  final slide = Tween<Offset>(
                    begin: Offset(pushed ? 0.06 : 0, pushed ? 0 : 0.03),
                    end: Offset.zero,
                  ).animate(anim);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(key: ValueKey(key), child: body),
              ),
            ),
            if (!isAdd)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _TabBar(
                  currentTab: pushed ? null : _tab,
                  onTab: tab,
                  onFab: () => push(TFScreens.add),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.currentTab,
    required this.onTab,
    required this.onFab,
  });

  /// Active tab, or null when a pushed screen is on top (no tab highlighted).
  final String? currentTab;
  final void Function(String) onTab;
  final VoidCallback onFab;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, 14, 12 + bottomInset),
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          _TabItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: currentTab == TFTabs.dashboard,
            onTap: () => onTab(TFTabs.dashboard),
          ),
          _TabItem(
            icon: Icons.grid_view_rounded,
            label: 'Programs',
            active: currentTab == TFTabs.programs,
            onTap: () => onTab(TFTabs.programs),
          ),
          Expanded(
            child: Center(child: _Fab(onTap: onFab)),
          ),
          _TabItem(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            active: currentTab == TFTabs.reports,
            onTap: () => onTab(TFTabs.reports),
          ),
          _TabItem(
            icon: Icons.menu_rounded,
            label: 'More',
            active: currentTab == TFTabs.more,
            onTap: () => onTab(TFTabs.more),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final color = active ? c.primary : c.textDim;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TFText.sans(size: 10.5, color: color, letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Transform.translate(
      offset: const Offset(0, -20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(Icons.add, size: 26, color: c.primaryInk),
        ),
      ),
    );
  }
}
