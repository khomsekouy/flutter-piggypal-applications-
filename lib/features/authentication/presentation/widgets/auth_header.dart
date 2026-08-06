import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

/// Wordmark shown at the top of every auth screen, with an optional back
/// button.
///
/// Deliberately mark-free: each auth screen already carries a
/// `HeroIllustration` right below this, and a logo tile here competed with it
/// for the eye — on sign-in the two were even the same glyph.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              color: AppColors.textSecondary,
            ),
          ),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: 'Save',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'Nest',
                style: TextStyle(color: AppColors.primaryGreen),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
