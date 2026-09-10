import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/password_reset_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/phone_verification_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_step_indicator.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/otp_field.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/phone_number_field.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/resend_code_card.dart';
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
/// Both paths talk to the API for real, through a bloc apiece: sign-up
/// through [PhoneVerificationBloc] (`verify-phone/confirm`, guarded, no
/// number in the body), password reset through [PasswordResetBloc]
/// (`verify-otp`, unguarded, the number in the body because there is no
/// session to read one from).
class VerifyNumberPage extends StatelessWidget {
  const VerifyNumberPage({
    required this.phoneNumber,
    this.countryCode,
    this.purpose = VerifyPurpose.signUp,
    this.devCode,
    super.key,
  });

  /// The number the code was sent to. On the reset path this is the
  /// **national** number alone, with [countryCode] beside it, because
  /// `verify-otp` wants the two apart. On the sign-up path there is no
  /// country code to pair it with and it arrives display-ready, straight off
  /// the session. Empty when the route is opened without a `phone` parameter.
  final String phoneNumber;

  /// The dialling code that goes with [phoneNumber], on the reset path only.
  /// Null on the sign-up path, which is what makes [phoneNumber] print as-is.
  final String? countryCode;

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
      countryCode: countryCode,
      purpose: purpose,
      devCode: devCode,
    );

    // A bloc each, and only the one the path in play uses: the two answer to
    // different endpoints with different auth, and nothing here needs both.
    return switch (purpose) {
      VerifyPurpose.signUp => BlocProvider(
        create: (_) => sl<PhoneVerificationBloc>(),
        child: view,
      ),
      VerifyPurpose.passwordReset => BlocProvider(
        create: (_) => sl<PasswordResetBloc>(),
        child: view,
      ),
    };
  }
}

class _VerifyNumberView extends StatefulWidget {
  const _VerifyNumberView({
    required this.phoneNumber,
    required this.purpose,
    this.countryCode,
    this.devCode,
  });

  final String phoneNumber;
  final String? countryCode;
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

  /// The sign-up bloc's state, or a standing-still one on the reset path
  /// where that bloc is not provided. Read rather than watched: the rebuilds
  /// come from the `BlocConsumer` in [build], and this is also called from
  /// handlers, where watching would throw.
  PhoneVerificationState get _verification => _isSignUp
      ? context.read<PhoneVerificationBloc>().state
      : const PhoneVerificationState();

  /// The reset bloc's state, and the mirror of [_verification] — a
  /// standing-still one on the sign-up path, for the same reason.
  PasswordResetState get _reset => _isSignUp
      ? const PasswordResetState()
      : context.read<PasswordResetBloc>().state;

  bool get _isVerifying =>
      _isSignUp ? _verification.isSubmittingCode : _reset.isVerifyingCode;

  bool get _isSendingCode =>
      _isSignUp ? _verification.isSendingCode : _reset.isSendingCode;

  bool get _canResend => _secondsLeft == 0 && !_isVerifying && !_isSendingCode;

  bool get _canVerify => _code.length == _codeLength && !_isVerifying;

  /// The dial code to send with the reset calls.
  ///
  /// Falls back to the only country the app offers, which is also the one the
  /// number field enforces: a deep link straight into this screen carries no
  /// country, and refusing to continue over that would be a dead end where a
  /// correct guess exists.
  String get _countryCode {
    final code = widget.countryCode;
    return code == null || code.isEmpty ? PhoneNumberField.dialCode : code;
  }

  /// The number as the user should read it. The reset path carries the dial
  /// code separately, so it is joined back on here; the sign-up path's number
  /// arrives already formatted.
  String get _destination {
    if (widget.phoneNumber.isEmpty) return 'your number';
    final code = widget.countryCode;
    return code == null || code.isEmpty
        ? widget.phoneNumber
        : '$code ${widget.phoneNumber}';
  }

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
    context.read<PasswordResetBloc>().add(
      PasswordResetCodeSubmitted(
        countryCode: _countryCode,
        phone: widget.phoneNumber,
        code: _code,
      ),
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
    // `forgot-password` again, which is also how it is resent: the server
    // retires whatever code was live and issues a new one.
    context.read<PasswordResetBloc>().add(
      PasswordResetCodeRequested(
        countryCode: _countryCode,
        phone: widget.phoneNumber,
      ),
    );
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

  void _onResetChanged(BuildContext context, PasswordResetState state) {
    if (state.devCode != null && state.devCode != _liveDevCode) {
      setState(() => _liveDevCode = state.devCode);
    }

    final message = state.errorMessage;
    if (message != null) {
      if (state.codeRejected) {
        // Same order as the sign-up path, and for the same reason: `clear`
        // reports the empty code back through `onChanged`, which is what
        // wipes a stale error — set the message first and it wipes that one.
        _otpKey.currentState?.clear();
        setState(() {
          _code = '';
          _errorText = message;
        });
      } else {
        _showMessage(message);
      }
      context.read<PasswordResetBloc>().add(
        const PasswordResetErrorDismissed(),
      );
      return;
    }

    switch (state.status) {
      case PasswordResetStatus.codeSent:
        // This bloc starts fresh on this screen, so the only way it reaches
        // `codeSent` here is a resend that the server accepted.
        _showMessage('A new code is on its way to $_destination.');
      case PasswordResetStatus.codeVerified:
        // Replaces this screen rather than stacking on it: the code has been
        // spent, so going back should return to the number, not the boxes.
        //
        // The token rides in `extra`, not the query string: it is a
        // credential, and a URL is the one place in the flow that gets
        // logged, shared and restored.
        context.pushReplacementNamed(
          AppRoutes.resetPassword,
          queryParameters: {'phone': _destination},
          extra: state.resetToken,
        );
      case PasswordResetStatus.initial:
      case PasswordResetStatus.sendingCode:
      case PasswordResetStatus.verifyingCode:
      case PasswordResetStatus.updatingPassword:
      case PasswordResetStatus.passwordUpdated:
        // Nothing to do: the loading states drive the button, and the last
        // two belong to the screen after this one.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSignUp) {
      return BlocConsumer<PasswordResetBloc, PasswordResetState>(
        // As on the number screen: clearing a message re-emits the status it
        // was carried on, and a rejected code sits on `codeSent`. Without
        // this, dismissing "that code is invalid" would immediately be
        // followed by "a new code is on its way" — for a resend nobody asked
        // for and the server never made.
        listenWhen: (previous, current) =>
            previous.status != current.status || current.errorMessage != null,
        listener: _onResetChanged,
        builder: (context, _) => _buildPage(context),
      );
    }

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
                ResendCodeCard(
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
