import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/verify_number_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/phone_number_field.dart';
import 'package:go_router/go_router.dart';

/// First step of the password reset: collect the number the account was
/// registered with, so a code can be sent to it.
///
/// Step two is [VerifyNumberPage] with [VerifyPurpose.passwordReset]; step
/// three is the new-password screen it hands off to.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();

  /// Whether the number satisfies the Cambodian length rule. Owned by
  /// [PhoneNumberField], which enforces it.
  bool _phoneValid = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  bool get _canSubmit => _phoneValid && !_isLoading;

  Future<void> _handleSendCode() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    // TODO(auth): request the real reset code here. Deliberately continues
    // even for an unknown number — telling callers which numbers have
    // accounts would leak them.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    unawaited(
      context.pushNamed(
        AppRoutes.verifyNumber,
        queryParameters: {
          'phone': '${PhoneNumberField.dialCode} $_digits',
          'purpose': VerifyPurpose.passwordReset.queryValue,
        },
      ),
    );
  }

  /// Pops back to sign-in, or navigates there outright when this page was
  /// opened as a deep link and has nothing to pop.
  void _backToSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(onBack: _backToSignIn),
                const SizedBox(height: 20),
                const Center(
                  child: HeroIllustration(
                    icon: Icons.lock_reset,
                    badges: [
                      HeroBadge(
                        icon: Icons.sms_outlined,
                        color: AppColors.primaryGreen,
                        alignment: Alignment.topCenter,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your phone number and we\nwill send you a reset code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                PhoneNumberField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSendCode(),
                  onValidChanged: (isValid) =>
                      setState(() => _phoneValid = isValid),
                ),
                const SizedBox(height: 28),
                GradientButton(
                  label: 'Send Code',
                  icon: Icons.sms_outlined,
                  isLoading: _isLoading,
                  onPressed: _canSubmit ? _handleSendCode : null,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Remembered it? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: _backToSignIn,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
