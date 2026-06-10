import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/utils/money_formatter.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/widgets/transaction_tile.dart';

/// Entry point for the transactions feature.
///
/// Owns the [TransactionsBloc] and subscribes to the live stream immediately.
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<TransactionsBloc>()
            ..add(const TransactionsSubscriptionRequested()),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  Future<void> _addTransaction(BuildContext context) async {
    final bloc = context.read<TransactionsBloc>();
    final result = await AddTransactionSheet.show(context);
    if (result == null) return;
    bloc.add(
      TransactionAdded(
        title: result.title,
        amount: result.amount,
        type: result.type,
        category: result.category,
        date: result.date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: BlocConsumer<TransactionsBloc, TransactionsState>(
        listenWhen: (prev, curr) =>
            curr.status == TransactionsStatus.failure &&
            curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          if (state.status == TransactionsStatus.loading ||
              state.status == TransactionsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _BalanceHeader(state: state),
              if (state.transactions.isEmpty)
                const Expanded(child: _EmptyState())
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: state.transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final transaction = state.transactions[index];
                      return TransactionTile(
                        transaction: transaction,
                        onDelete: () => context.read<TransactionsBloc>().add(
                          TransactionDeleted(transaction.id),
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

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.state});

  final TransactionsState state;

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
            colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              MoneyFormatter.format(state.balance),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(
                  label: 'Income',
                  amount: state.totalIncome,
                  icon: Icons.arrow_downward,
                ),
                const SizedBox(width: 24),
                _Stat(
                  label: 'Expense',
                  amount: state.totalExpense,
                  icon: Icons.arrow_upward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final double amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: onPrimary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: onPrimary.withValues(alpha: 0.8),
              ),
            ),
            Text(
              MoneyFormatter.format(amount),
              style: theme.textTheme.titleSmall?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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
              Icons.receipt_long_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No transactions yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap "Add" to record your first income or expense.',
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
