import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/phone_verification_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_step_indicator.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/otp_field.dart';
import 'package:go_router/go_router.dart';

/// Number of boxes in the verification code.
const _codeLength = 6;

/// Seconds the user must wait before another code can be requested.
///
/// Client-side courtesy, not the real limit: the server allows three sends
/// per fifteen minutes, so a user who resends the moment this expires will
/// still be turned away on the fourth. The message it sends back is what they
/// see then.
const _resendCooldown = 60;

/// Why a code is being checked. Both flows send an SMS code to a number and
/// check it the same way — only the copy and where success lands differ, so
/// they share one screen rather than two near-identical ones.
enum VerifyPurpose {
  /// Confirming a new account's number; verification finishes sign-up.
  signUp,

  /// Proving the number is theirs before letting them set a new password.
  passwordReset
  ;

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

/// Step two of two: the six digits.
///
/// The sign-up path talks to the API for real, through
/// [PhoneVerificationBloc]. The password-reset path is still stubbed — its
/// server-side chain (`forgot-password` → `verify-otp` → `reset-password`)
/// exists but nothing in the app calls it yet.
class VerifyNumberPage extends StatelessWidget {
  const VerifyNumberPage({
    required this.phoneNumber,
    this.purpose = VerifyPurpose.signUp,
    this.devCode,
    super.key,
  });

  /// The number the code was sent to, already formatted with its dial code.
  /// Empty when the route is opened without a `phone` query parameter.
  final String phoneNumber;

  /// Which flow sent the user here. Decides the copy and the next screen.
  final VerifyPurpose purpose;

  /// The code the server echoed back because it is running with mocked ones.
  /// Offered as a one-tap fill in debug builds and ignored everywhere else —
  /// there is no SMS provider wired up yet, so without this a debug build has
  /// no way to read the code it was sent.
  final String? devCode;

  @override
  Widget build(BuildContext context) {
    final view = _VerifyNumberView(
      phoneNumber: phoneNumber,
      purpose: purpose,
      devCode: devCode,
    );

    // Only the sign-up path makes calls, so only it needs the bloc. The reset
    // path would otherwise force every screen that pushes it to have the
    // service locator up.
    return purpose == VerifyPurpose.signUp
        ? BlocProvider(
            create: (_) => sl<PhoneVerificationBloc>(),
            child: view,
          )
        : view;
  }
}

class _VerifyNumberView extends StatefulWidget {
  const _VerifyNumberView({
    required this.phoneNumber,
    required this.purpose,
    this.devCode,
  });

  final String phoneNumber;
  final VerifyPurpose purpose;
  final String? devCode;

  @override
  State<_VerifyNumberView> createState() => _VerifyNumberViewState();
}

class _VerifyNumberViewState extends State<_VerifyNumberView> {
  final _otpKey = GlobalKey<OtpFieldState>();

  Timer? _resendTimer;
  int _secondsLeft = _resendCooldown;
  String _code = '';
  String? _errorText;

  /// Only used by the password-reset path, which has no bloc behind it yet.
  bool _isStubVerifying = false;

  /// The mocked code to offer as a one-tap fill: whichever is newer, the one
  /// step one handed over or the one a resend produced.
  String? _liveDevCode;

  @override
  void initState() {
    super.initState();
    _liveDevCode = widget.devCode;
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

  bool get _isSignUp => widget.purpose == VerifyPurpose.signUp;

  /// The bloc's current state, or a standing-still one on the reset path
  /// where there is no bloc. Read rather than watched: the rebuilds come from
  /// the `BlocBuilder` in [build], and this is also called from handlers,
  /// where watching would throw.
  PhoneVerificationState get _verification => _isSignUp
      ? context.read<PhoneVerificationBloc>().state
      : const PhoneVerificationState();

  bool get _isVerifying =>
      _isSignUp ? _verification.isSubmittingCode : _isStubVerifying;

  bool get _isSendingCode => _verification.isSendingCode;

  bool get _canResend => _secondsLeft == 0 && !_isVerifying && !_isSendingCode;

  bool get _canVerify => _code.length == _codeLength && !_isVerifying;

  String get _destination =>
      widget.phoneNumber.isEmpty ? 'your number' : widget.phoneNumber;

  /// `00:28`, as the design shows it — a bare seconds count reads as a number
  /// rather than a wait.
  String get _countdownLabel {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _title => switch (widget.purpose) {
    VerifyPurpose.signUp => 'Verify Phone Number',
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

  void _showMessage(String message) {
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

  void _handleVerify() {
    if (!_canVerify) return;
    FocusScope.of(context).unfocus();
    setState(() => _errorText = null);

    if (_isSignUp) {
      context.read<PhoneVerificationBloc>().add(
        PhoneVerificationCodeSubmitted(_code),
      );
      return;
    }
    unawaited(_verifyResetStub());
  }

  /// Stands in for the reset flow's `POST /auth/verify-otp`, which is not
  /// wired yet. Any complete code passes; the failure path below is the one
  /// the real call will take.
  // TODO(auth): call the authentication repository here.
  Future<void> _verifyResetStub() async {
    setState(() => _isStubVerifying = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isStubVerifying = false);

    // Replaces this screen rather than stacking on it: the code has been
    // spent, so going back should return to the number, not the boxes.
    context.pushReplacementNamed(
      AppRoutes.resetPassword,
      queryParameters: {'phone': widget.phoneNumber},
    );
  }

  void _handleResend() {
    if (!_canResend) return;
    _clearCode();
    _startResendCountdown();

    if (_isSignUp) {
      context.read<PhoneVerificationBloc>().add(
        const PhoneVerificationCodeRequested(),
      );
      return;
    }
    // TODO(auth): re-request the reset code here.
    _showMessage('A new code is on its way to $_destination.');
  }

  void _clearCode() {
    _otpKey.currentState?.clear();
    setState(() {
      _code = '';
      _errorText = null;
    });
  }

  /// Sign-up: the account exists already, so leaving here costs nothing but
  /// the verified stamp — on to the last step. Reset: the code is the only
  /// way forward, so this goes back to the number instead.
  void _secondaryAction() {
    if (_isSignUp) {
      context.goNamed(AppRoutes.profilePhoto);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.signIn);
    }
  }

  void _onVerificationChanged(
    BuildContext context,
    PhoneVerificationState state,
  ) {
    if (state.devCode != null && state.devCode != _liveDevCode) {
      setState(() => _liveDevCode = state.devCode);
    }

    final message = state.errorMessage;
    if (message != null) {
      if (state.codeRejected) {
        // Emptying the boxes first, then setting the message: `clear` reports
        // the empty code back through `onChanged`, which is also what wipes a
        // stale error — do it the other way round and the message this line
        // just set is the one that gets wiped.
        _otpKey.currentState?.clear();
        // Belongs under the boxes, not in a snackbar that slides away while
        // they are still looking at what they typed.
        setState(() {
          _code = '';
          _errorText = message;
        });
      } else {
        _showMessage(message);
      }
      context.read<PhoneVerificationBloc>().add(
        const PhoneVerificationErrorDismissed(),
      );
    }

    if (state.status == PhoneVerificationStatus.verified) {
      // The account's `phoneVerified` just changed under the app; re-read it
      // so anything showing the profile is not stale.
      context.read<AuthenticationBloc>().add(
        const AuthenticationUserRefreshed(),
      );
      // Replaces the auth stack so hardware-back cannot land the user on a
      // verification screen they already cleared.
      context.goNamed(AppRoutes.profilePhoto);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSignUp) return _buildPage(context);

    return BlocConsumer<PhoneVerificationBloc, PhoneVerificationState>(
      listener: _onVerificationChanged,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
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
                AuthHeader(onBack: _secondaryAction),
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
                const Text(
                  'We sent a $_codeLength-digit code to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: _PhoneChip(phoneNumber: _destination)),
                if (_isSignUp) ...[
                  const SizedBox(height: 20),
                  const AuthStepIndicator(step: 3, totalSteps: 4),
                ],
                const SizedBox(height: 28),
                const Text(
                  'Enter the code below',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 20),
                _ResendCard(
                  canResend: _canResend,
                  isSending: _isSendingCode,
                  countdown: _countdownLabel,
                  onResend: _handleResend,
                ),
                if (kDebugMode && _liveDevCode != null) ...[
                  const SizedBox(height: 12),
                  _DevCodeHint(
                    code: _liveDevCode!,
                    onFill: () => _otpKey.currentState?.fill(_liveDevCode!),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _secondaryAction,
                    icon: Icon(
                      _isSignUp ? Icons.schedule : Icons.edit_outlined,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    label: Text(
                      _isSignUp ? 'Verify later' : 'Change phone number',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: _actionLabel,
                  icon: _actionIcon,
                  isLoading: _isVerifying,
                  onPressed: _canVerify ? _handleVerify : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The number the code went to, boxed so it reads as a fact about the code
/// rather than another line of explanation.
class _PhoneChip extends StatelessWidget {
  const _PhoneChip({required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇰🇭', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(
            phoneNumber,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Didn't receive the code?" and the wait before asking again.
class _ResendCard extends StatelessWidget {
  const _ResendCard({
    required this.canResend,
    required this.isSending,
    required this.countdown,
    required this.onResend,
  });

  final bool canResend;
  final bool isSending;
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

/// Debug-only shortcut for the code the server echoed back.
///
/// Nothing texts the code yet — the API's SMS provider is still a TODO — so
/// without this a debug build against a mocked server has no way to know what
/// to type. Never built in release: see the `kDebugMode` guard on its use.
class _DevCodeHint extends StatelessWidget {
  const _DevCodeHint({required this.code, required this.onFill});

  final String code;
  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onFill,
        icon: const Icon(
          Icons.bug_report_outlined,
          size: 16,
          color: AppColors.accentGold,
        ),
        label: Text(
          'Dev build — tap to fill $code',
          style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
        ),
      ),
    );
  }
}
