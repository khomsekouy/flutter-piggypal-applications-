import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

/// "Didn't receive the code?" and the wait before asking again.
///
/// Shared by the two screens that hold six boxes — sign-up's verification
/// pane and the password-reset flow — because a resend looks and waits the
/// same in both, and the cooldown is the part users notice when it drifts.
class ResendCodeCard extends StatelessWidget {
  const ResendCodeCard({
    required this.canResend,
    required this.isSending,
    required this.countdown,
    required this.onResend,
    super.key,
  });

  final bool canResend;
  final bool isSending;

  /// The wait left, already formatted as `mm:ss`.
  final String countdown;

  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen),
            ),
            child: isSending
                ? const Padding(
                    padding: EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  )
                : const Icon(
                    Icons.schedule,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Didn't receive the code? ",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: canResend ? onResend : null,
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: canResend
                              ? AppColors.primaryGreen
                              : AppColors.textHint,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!canResend) ...[
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'Resend in '),
                        TextSpan(
                          text: countdown,
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
