import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

/// The tabs across the top of the sign-up flow: one per step, numbered, with
/// the finished ones ticked and joined by a filled connector.
///
/// Replaces the plain bar-and-caption `AuthStepIndicator` on the screens that
/// are part of sign-up, because sign-up is now one screen with three panes:
/// the user needs to see not just how far along they are but *what* the
/// remaining steps ask for, and — for a step they have already cleared — that
/// they can go back to it.
///
/// [onStepTapped] is offered only for steps behind [currentStep]; jumping
/// forward past a step that has not been satisfied is exactly what the flow
/// exists to prevent, so a later tab is inert.
class AuthStepTabs extends StatelessWidget {
  const AuthStepTabs({
    required this.labels,
    required this.currentStep,
    super.key,
    this.onStepTapped,
  });

  /// One short caption per step, in order.
  final List<String> labels;

  /// 0-based index of the step being shown.
  final int currentStep;

  /// Called with the index of a *completed* step when its tab is tapped.
  /// Null makes every tab inert.
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: _StepTab(
              label: labels[i],
              index: i,
              total: labels.length,
              currentStep: currentStep,
              isFirst: i == 0,
              isLast: i == labels.length - 1,
              onTap: i < currentStep && onStepTapped != null
                  ? () => onStepTapped!(i)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _StepTab extends StatelessWidget {
  const _StepTab({
    required this.label,
    required this.index,
    required this.total,
    required this.currentStep,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });

  final String label;
  final int index;
  final int total;
  final int currentStep;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  bool get _isDone => index < currentStep;

  bool get _isCurrent => index == currentStep;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: _isCurrent,
      label: 'Step ${index + 1} of $total, $label',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Row(
              children: [
                // The connectors sit either side of the circle so every tab
                // is the same shape and the labels stay centred under it.
                _Connector(visible: !isFirst, filled: _isDone || _isCurrent),
                _StepBadge(
                  index: index,
                  isDone: _isDone,
                  isCurrent: _isCurrent,
                ),
                _Connector(visible: !isLast, filled: _isDone),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isCurrent
                    ? AppColors.textPrimary
                    : _isDone
                    ? AppColors.textSecondary
                    : AppColors.textHint,
                fontSize: 11.5,
                fontWeight: _isCurrent ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The numbered circle: filled green while the step is live, outlined and
/// ticked once it is behind the user, and dim ahead of them.
class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.index,
    required this.isDone,
    required this.isCurrent,
  });

  final int index;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCurrent ? AppColors.primaryButtonGradient : null,
        color: isCurrent
            ? null
            : isDone
            ? AppColors.primaryGreen.withValues(alpha: 0.14)
            : AppColors.surface,
        border: Border.all(
          color: isCurrent || isDone
              ? AppColors.primaryGreen
              : AppColors.surfaceBorder,
          width: isCurrent ? 0 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: isDone
          ? const Icon(Icons.check, size: 15, color: AppColors.primaryGreen)
          : Text(
              '${index + 1}',
              style: TextStyle(
                color: isCurrent ? Colors.white : AppColors.textHint,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.visible, required this.filled});

  final bool visible;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 2,
        color: !visible
            ? Colors.transparent
            : filled
            ? AppColors.primaryGreen
            : AppColors.surfaceBorder,
      ),
    );
  }
}
