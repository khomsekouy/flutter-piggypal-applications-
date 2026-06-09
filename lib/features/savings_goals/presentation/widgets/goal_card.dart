import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/utils/money_formatter.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';

/// Displays a single savings goal with its progress.
class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.goal,
    required this.onAddMoney,
    required this.onDelete,
    super.key,
  });

  final SavingsGoal goal;
  final VoidCallback onAddMoney;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Color(goal.colorValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.15),
                  child: Icon(Icons.savings, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        goal.isCompleted
                            ? 'Goal reached 🎉'
                            : '${MoneyFormatter.format(goal.remaining)} to go',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<void>(
                  itemBuilder: (context) => [
                    PopupMenuItem<void>(
                      onTap: onDelete,
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 10,
                backgroundColor: accent.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  MoneyFormatter.format(goal.currentAmount),
                  style: theme.textTheme.labelLarge,
                ),
                Text(
                  MoneyFormatter.format(goal.targetAmount),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: goal.isCompleted ? null : onAddMoney,
                icon: const Icon(Icons.add),
                label: const Text('Add money'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
