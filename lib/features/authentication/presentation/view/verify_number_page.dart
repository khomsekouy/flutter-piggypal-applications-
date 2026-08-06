import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/otp_field.dart';
import 'package:go_router/go_router.dart';

/// Number of boxes in the verification code.
const _codeLength = 6;

/// Seconds the user must wait before another code can be requested.
const _resendCooldown = 60;

/// Why a code is being checked. Both flows send an SMS code to a number and
/// check it the same way — only the copy and where success lands differ, so
/// they share one screen rather than two near-identical ones.
enum VerifyPurpose {
  /// Confirming a new account's number; verification finishes sign-up.
  signUp,

  /// Proving the number is theirs before letting them set a new password.
  passwordReset;

  /// How the purpose travels in the route's `purpose` query parameter.
  String get queryValue => switch (this) {
    VerifyPurpose.signUp => 'sign-up',
    VerifyPurpose.passwordReset => 'password-reset',
  };

  /// Reads the query parameter back. Anything unrecognised — including a
  /// missing value — falls back to sign-up, the flow that came first.
  static VerifyPurpose fromQueryValue(String? value) =>
      value == VerifyPurpose.passwordReset.queryValue
      ? VerifyPurpose.passwordReset
      : VerifyPurpose.signUp;
}

class VerifyNumberPage extends StatefulWidget {
  const VerifyNumberPage({
    required this.phoneNumber,
    this.purpose = VerifyPurpose.signUp,
    super.key,
  });

  /// The number the code was sent to, already formatted with its dial code.
  /// Empty when the route is opened without a `phone` query parameter.
  final String phoneNumber;

  /// Which flow sent the user here. Decides the copy and the next screen.
  final VerifyPurpose purpose;

  @override
  State<VerifyNumberPage> createState() => _VerifyNumberPageState();
}

class _VerifyNumberPageState extends State<VerifyNumberPage> {
  final _otpKey = GlobalKey<OtpFieldState>();

  Timer? _resendTimer;
  int _secondsLeft = _resendCooldown;
  String _code = '';
  bool _isVerifying = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  bool get _canResend => _secondsLeft == 0 && !_isVerifying;

  bool get _canVerify => _code.length == _codeLength && !_isVerifying;

  String get _destination =>
      widget.phoneNumber.isEmpty ? 'your number' : widget.phoneNumber;

  String get _title => switch (widget.purpose) {
    VerifyPurpose.signUp => 'Verify Your Number',
    VerifyPurpose.passwordReset => 'Check Your Messages',
  };

  String get _actionLabel => switch (widget.purpose) {
    VerifyPurpose.signUp => 'Verify',
    VerifyPurpose.passwordReset => 'Continue',
  };

  IconData get _actionIcon => switch (widget.purpose) {
    VerifyPurpose.signUp => Icons.verified_outlined,
    VerifyPurpose.passwordReset => Icons.arrow_forward_rounded,
  };

  /// Stands in for the real verification request. Any complete code passes
  /// for now, but the failure path in [_handleVerify] is already the one the
  /// real call will take.
  // TODO(auth): call the authentication repository here.
  Future<bool> _submitCode(String code) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return code.length == _codeLength;
  }

  Future<void> _handleVerify() async {
    if (!_canVerify) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final isValid = await _submitCode(_code);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (!isValid) {
      setState(() => _errorText = 'That code is not right. Try again.');
      _otpKey.currentState?.clear();
      return;
    }
    switch (widget.purpose) {
      case VerifyPurpose.signUp:
        // Replaces the auth stack so hardware-back from home cannot land the
        // user back on a verification screen they already cleared.
        context.goNamed(AppRoutes.home);
      case VerifyPurpose.passwordReset:
        // Replaces this screen rather than stacking on it: the code has been
        // spent, so going back should return to the number, not the boxes.
        context.pushReplacementNamed(
          AppRoutes.resetPassword,
          queryParameters: {'phone': widget.phoneNumber},
        );
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    // TODO(auth): trigger the real "send code" request here.
    _otpKey.currentState?.clear();
    setState(() {
      _code = '';
      _errorText = null;
    });
    _startResendCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(
          'A new code is on its way to $_destination.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  void _changeNumber() {
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
                AuthHeader(onBack: _changeNumber),
                const SizedBox(height: 20),
                const Center(
                  child: HeroIllustration(
                    icon: Icons.sms_outlined,
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
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Enter the $_codeLength-digit code we sent to\n',
                      ),
                      TextSpan(
                        text: _destination,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                OtpField(
                  key: _otpKey,
                  length: _codeLength,
                  enabled: !_isVerifying,
                  hasError: _errorText != null,
                  onChanged: (code) => setState(() {
                    _code = code;
                    _errorText = null;
                  }),
                  onCompleted: (_) => _handleVerify(),
                ),
                if (_errorText case final error?) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                GradientButton(
                  label: _actionLabel,
                  icon: _actionIcon,
                  isLoading: _isVerifying,
                  onPressed: _canVerify ? _handleVerify : null,
                ),
                const SizedBox(height: 20),
                Center(
                  child: _canResend
                      ? GestureDetector(
                          onTap: _handleResend,
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Text(
                          'Resend code in ${_secondsLeft}s',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Wrong number? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: _changeNumber,
                        child: const Text(
                          'Change it',
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
