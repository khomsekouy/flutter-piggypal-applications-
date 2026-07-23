import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';

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
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: TFColors.basePos,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.black,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
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
                    style: TextStyle(color: TFColors.basePos),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Your personal finance companion',
          style: TextStyle(fontSize: 14, color: Color(0xFF99A2AF)),
        ),
      ],
    );
  }
}
