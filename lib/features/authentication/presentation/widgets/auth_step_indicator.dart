import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

/// Progress bar for a multi-step auth flow (today: sign-up's details → photo).
///
/// Shows one bar per step plus a "Step x of y" label, so the user knows how
/// much is left before the form asks them to commit.
class AuthStepIndicator extends StatelessWidget {
  const AuthStepIndicator({
    required this.step,
    required this.totalSteps,
    super.key,
  });

  /// 1-based index of the step being shown.
  final int step;

  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= totalSteps; i++) ...[
              if (i > 1) const SizedBox(width: 8),
              Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step
                      ? AppColors.primaryGreen
                      : AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Step $step of $totalSteps',
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
