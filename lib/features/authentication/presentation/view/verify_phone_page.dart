import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/phone_verification_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/utils/phone_display.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/verify_number_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_step_indicator.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/requires_session.dart';
import 'package:go_router/go_router.dart';

/// Step one of two: confirm the number, then ask for a code.
///
/// Reached straight after sign-up, which is the earliest this screen *can*
/// exist: the API sends codes only to the number on the caller's own session
/// (`POST /auth/verify-phone/request` takes no body and reads the number off
/// the access token), so there is nothing to verify until an account is
/// there. That is also why the number here is shown rather than typed — it is
/// the one the account was created with, and the API has no endpoint for
/// changing it.
///
/// Verifying is optional. The account already works; this only stamps
/// `phoneVerified`, so "Verify later" is a real way out rather than a
/// dead end.
class VerifyPhonePage extends StatelessWidget {
  const VerifyPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PhoneVerificationBloc>(),
      child: const _VerifyPhoneView(),
    );
  }
}

class _VerifyPhoneView extends StatelessWidget {
  const _VerifyPhoneView();

  /// On to the last step. The account exists and is signed in, so skipping
  /// here abandons nothing — it only leaves `phoneVerified` unstamped.
  void _verifyLater(BuildContext context) =>
      context.goNamed(AppRoutes.profilePhoto);

  void _sendCode(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<PhoneVerificationBloc>().add(
      const PhoneVerificationCodeRequested(),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }

  void _onVerificationChanged(
    BuildContext context,
    PhoneVerificationState state,
    String phoneNumber,
  ) {
    final message = state.errorMessage;
    if (message != null) {
      _showMessage(context, message);
      context.read<PhoneVerificationBloc>().add(
        const PhoneVerificationErrorDismissed(),
      );
    }

    switch (state.status) {
      case PhoneVerificationStatus.codeSent:
        unawaited(
          context.pushNamed(
            AppRoutes.verifyNumber,
            queryParameters: {
              'phone': phoneNumber,
              'purpose': VerifyPurpose.signUp.queryValue,
            },
            // Only ever non-null against a server with mocked codes; see
            // PhoneVerificationState.devCode.
            extra: state.devCode,
          ),
        );
      case PhoneVerificationStatus.alreadyVerified:
        // No code was sent, so there is nothing to type. Say why, then get
        // out of the way.
        _showMessage(context, 'Your number is already verified.');
        context.read<AuthenticationBloc>().add(
          const AuthenticationUserRefreshed(),
        );
        context.goNamed(AppRoutes.profilePhoto);
      case PhoneVerificationStatus.initial:
      case PhoneVerificationStatus.sendingCode:
      case PhoneVerificationStatus.submittingCode:
      case PhoneVerificationStatus.verified:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequiresSession(
      builder: (context, user) => _buildPage(
        context,
        formatPhoneForDisplay(user.phone),
      ),
    );
  }

  Widget _buildPage(BuildContext context, String phoneNumber) {
    return BlocListener<PhoneVerificationBloc, PhoneVerificationState>(
      listener: (context, state) =>
          _onVerificationChanged(context, state, phoneNumber),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                  AuthHeader(onBack: () => _verifyLater(context)),
                  const SizedBox(height: 20),
                  const Center(
                    child: HeroIllustration(
                      icon: Icons.smartphone,
                      badges: [
                        HeroBadge(
                          icon: Icons.check,
                          color: AppColors.primaryGreen,
                          alignment: Alignment.topCenter,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verify Phone Number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We will send a 6-digit verification code\n'
                    'to the number on your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const AuthStepIndicator(step: 2, totalSteps: 4),
                  const SizedBox(height: 28),
                  const Text(
                    'Phone Number',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AccountPhoneField(phoneNumber: phoneNumber),
                  const SizedBox(height: 8),
                  const Text(
                    "You'll receive an OTP by SMS.",
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 28),
                  BlocBuilder<PhoneVerificationBloc, PhoneVerificationState>(
                    builder: (context, state) => GradientButton(
                      label: 'Send Code',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: state.isSendingCode,
                      onPressed: state.isBusy ? null : () => _sendCode(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => _verifyLater(context),
                      child: const Text(
                        'Verify later',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The number the code will go to, shown the way the input field on sign-up
/// showed it — flag, dial code, number — but not editable, because the API
/// will not let this number change.
class _AccountPhoneField extends StatelessWidget {
  const _AccountPhoneField({required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Text('🇰🇭', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              phoneNumber,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Icon(Icons.lock_outline, size: 18, color: AppColors.textHint),
        ],
      ),
    );
  }
}
