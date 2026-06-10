import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/utils/money_formatter.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/entities/transaction.dart';
import 'package:intl/intl.dart';

/// A single row in the transactions list.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.onDelete,
    super.key,
  });

  final Transaction transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.isIncome;
    final color = isIncome ? Colors.green.shade600 : theme.colorScheme.error;
    final sign = isIncome ? '+' : '-';

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: theme.colorScheme.surfaceContainerHighest,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Text(transaction.title),
        subtitle: Text(
          '${transaction.category} • '
          '${DateFormat.yMMMd().format(transaction.date)}',
        ),
        trailing: Text(
          '$sign${MoneyFormatter.format(transaction.amount)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
