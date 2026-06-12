import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/programs/domain/entities/program.dart';
import 'package:flutter_piggypal_app/features/programs/presentation/bloc/programs_bloc.dart';
import 'package:flutter_piggypal_app/features/programs/presentation/widgets/program_card.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_segmented.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The "Programs" tab.
///
/// Owns the [ProgramsBloc] lifecycle and subscribes to the live Drift stream;
/// the list UI lives in [_ProgramsView].
class ProgramsPage extends StatelessWidget {
  const ProgramsPage({required this.nav, super.key});

  final TFNav nav;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ProgramsBloc>()..add(const ProgramsSubscriptionRequested()),
      child: _ProgramsView(nav: nav),
    );
  }
}

class _ProgramsView extends StatefulWidget {
  const _ProgramsView({required this.nav});

  final TFNav nav;

  @override
  State<_ProgramsView> createState() => _ProgramsViewState();
}

class _ProgramsViewState extends State<_ProgramsView> {
  // null = "all"; otherwise filter by status.
  ProgramStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgramsBloc, ProgramsState>(
      builder: (context, state) {
        final all = state.items;
        final list = _filter == null
            ? all
            : all.where((p) => p.status == _filter).toList();

        return TFScreen(
          pinnedHeader: true,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TFAppBar(
                eyebrow: '${all.length} programs',
                title: 'Programs',
                trailing: const TFIconButton(icon: Icons.search),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: TFSegmented<ProgramStatus?>(
                  value: _filter,
                  options: const [null, ...ProgramStatus.values],
                  labelOf: (s) => switch (s) {
                    null => 'All',
                    ProgramStatus.active => 'Active',
                    ProgramStatus.upcoming => 'Upcoming',
                    ProgramStatus.completed => 'Completed',
                  },
                  onChanged: (s) => setState(() => _filter = s),
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 14),
            ..._body(context, state, list),
          ],
        );
      },
    );
  }

  List<Widget> _body(
    BuildContext context,
    ProgramsState state,
    List<Program> list,
  ) {
    if (state.status == ProgramsStatus.loading ||
        state.status == ProgramsStatus.initial) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (state.status == ProgramsStatus.failure) {
      return [
        TFEmptyMessage(state.errorMessage ?? 'Could not load programs.'),
      ];
    }
    if (list.isEmpty) {
      return const [TFEmptyMessage('No programs here.')];
    }
    return [
      for (final p in list) ...[
        ProgramCard(
          program: p,
          onTap: () => widget.nav.push(TFScreens.program, {'id': p.id}),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}
