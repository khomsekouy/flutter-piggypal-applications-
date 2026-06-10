import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/utils/money_formatter.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/bloc/savings_goals_bloc.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/widgets/add_goal_sheet.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/widgets/goal_card.dart';

/// Entry point for the savings-goals feature.
///
/// Owns the [SavingsGoalsBloc] lifecycle and immediately subscribes to the
/// live goal stream. The actual UI lives in [_SavingsGoalsView].
class SavingsGoalsPage extends StatelessWidget {
  const SavingsGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<SavingsGoalsBloc>()..add(const GoalsSubscriptionRequested()),
      child: const _SavingsGoalsView(),
    );
  }
}

class _SavingsGoalsView extends StatelessWidget {
  const _SavingsGoalsView();

  Future<void> _createGoal(BuildContext context) async {
    final bloc = context.read<SavingsGoalsBloc>();
    final result = await AddGoalSheet.show(context);
    if (result == null) return;
    bloc.add(
      GoalCreated(name: result.name, targetAmount: result.targetAmount),
    );
  }

  Future<void> _addMoney(BuildContext context, SavingsGoal goal) async {
    final bloc = context.read<SavingsGoalsBloc>();
    final amount = await _AddMoneyDialog.show(context, goal);
    if (amount == null) return;
    bloc.add(ContributionAdded(goalId: goal.id, amount: amount));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createGoal(context),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: BlocConsumer<SavingsGoalsBloc, SavingsGoalsState>(
        listenWhen: (prev, curr) =>
            curr.status == SavingsGoalsStatus.failure &&
            curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          if (state.status == SavingsGoalsStatus.loading ||
              state.status == SavingsGoalsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.goals.isEmpty) {
            return const _EmptyState();
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _SummaryHeader(state: state)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList.separated(
                  itemCount: state.goals.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = state.goals[index];
                    return GoalCard(
                      goal: goal,
                      onAddMoney: () => _addMoney(context, goal),
                      onDelete: () => context.read<SavingsGoalsBloc>().add(
                        GoalDeleted(goal.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.state});

  final SavingsGoalsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.tertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total saved',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              MoneyFormatter.format(state.totalSaved),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'of ${MoneyFormatter.format(state.totalTarget)} target',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No goals yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap "New goal" to start saving for something special.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small dialog to deposit money into a goal. Returns the amount or null.
class _AddMoneyDialog extends StatefulWidget {
  const _AddMoneyDialog({required this.goal});

  final SavingsGoal goal;

  static Future<double?> show(BuildContext context, SavingsGoal goal) {
    return showDialog<double>(
      context: context,
      builder: (_) => _AddMoneyDialog(goal: goal),
    );
  }

  @override
  State<_AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends State<_AddMoneyDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than 0');
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add to ${widget.goal.name}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          prefixText: r'$ ',
          labelText: 'Amount',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
