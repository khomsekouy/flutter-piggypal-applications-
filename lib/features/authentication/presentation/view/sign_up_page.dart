import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/registration_verification_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/utils/password_rules.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/app_text_field.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_step_tabs.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/otp_field.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/phone_number_field.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/resend_code_card.dart';
import 'package:go_router/go_router.dart';

/// Number of boxes in the verification code.
const _codeLength = 6;

/// Seconds the user must wait before another code can be requested.
const _resendCooldown = 60;

/// The three panes of sign-up, in order.
enum SignUpStep {
  /// Who they are: name, number, and an email if they want one.
  details,

  /// The six digits texted to the number from [details].
  verify,

  /// The password the account will be signed in with.
  password
  ;

  String get tabLabel => switch (this) {
    SignUpStep.details => 'Details',
    SignUpStep.verify => 'Verify',
    SignUpStep.password => 'Password',
  };
}

/// The tabs across the whole of sign-up: this screen's three panes, plus the
/// optional photo that follows on its own screen.
///
/// Shared with `ProfilePhotoPage` so the strip the user has been watching
/// fill up does not change shape on the last step.
List<String> get signUpTabLabels => [
  for (final step in SignUpStep.values) step.tabLabel,
  'Photo',
];

/// Sign-up, as one screen with three panes.
///
/// The order is deliberate and is the whole point of the redesign: details
/// first, then the number is proved, and only then is a password asked for.
/// A user who abandons the flow at the code step has handed over nothing
/// secret, and a number that never verifies never becomes an account — which
/// is the opposite of the old flow, where registering was step one and the
/// verification that followed was optional.
///
/// The account is created in one request at the end of the third pane; the
/// optional profile photo stays on its own screen after it, because by then
/// there is a session to attach it to.
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // One instance for the whole flow, and only this flow: the proof it hands
    // back is spent by the `register` call two panes later, so it has to
    // outlive the code pane without outliving the screen.
    return BlocProvider(
      create: (_) => sl<RegistrationVerificationBloc>(),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  final _otpKey = GlobalKey<OtpFieldState>();

  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  SignUpStep _step = SignUpStep.details;

  /// Which way the last step change went, so the pane slides in from the side
  /// the user came from.
  bool _movingForward = true;

  /// Whether the number satisfies the Cambodian length rule. Owned by
  /// [PhoneNumberField], which enforces it.
  bool _phoneValid = false;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  // --- verification pane state -------------------------------------------

  String _code = '';
  String? _codeError;
  Timer? _resendTimer;
  int _secondsLeft = 0;

  /// The server's complaint about the number — a 409, meaning it already has
  /// an account — and the digits it was made about, so a single edit clears
  /// it. Kept together: a message about a number nobody is typing any more
  /// would sit under the field accusing the wrong one.
  String? _phoneRejection;
  String? _rejectedPhone;

  @override
  void initState() {
    super.initState();
    for (final controller in _editableFields) {
      controller.addListener(_onFieldChanged);
    }
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openLegalDocument('Terms & Conditions');
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => _openLegalDocument('Privacy Policy');
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _editableFields) {
      controller
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    for (final node in [
      _nameFocus,
      _phoneFocus,
      _emailFocus,
      _passwordFocus,
      _confirmFocus,
    ]) {
      node.dispose();
    }
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  List<TextEditingController> get _editableFields => [
    _nameController,
    _phoneController,
    _emailController,
    _passwordController,
    _confirmPasswordController,
  ];

  void _onFieldChanged() => setState(() {});

  // --- pane one: details --------------------------------------------------

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  String get _name => _nameController.text.trim();

  String get _email => _emailController.text.trim();

  /// The number as the user should read it, e.g. `+855 12345678`.
  String get _displayPhone => '${PhoneNumberField.dialCode} $_digits';

  /// Complaint about the email, or null. Empty passes: the field is optional,
  /// which is also why the label says so.
  String? get _emailError {
    if (_email.isEmpty) return null;
    // Deliberately loose — the server is the authority on a deliverable
    // address, and a strict client-side pattern only ever rejects real ones.
    final looksLikeEmail = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');
    return looksLikeEmail.hasMatch(_email)
        ? null
        : 'Enter a valid email address.';
  }

  /// The server's rejection of the number in the field, or null once it has
  /// been edited — the complaint was about the digits that were there then.
  String? get _phoneServerError =>
      _rejectedPhone == _digits ? _phoneRejection : null;

  bool get _detailsComplete =>
      _name.isNotEmpty &&
      _phoneValid &&
      _emailError == null &&
      _phoneServerError == null;

  /// The flow's state, read rather than watched: the rebuilds come from the
  /// [BlocBuilder] in [build], and this is also called from handlers, where
  /// watching would throw.
  RegistrationVerificationState get _verification =>
      context.read<RegistrationVerificationBloc>().state;

  /// Whether the number in the field is the one the middle pane already
  /// proved — true only until the user edits a digit, because the proof names
  /// the number it was issued for and the server checks that it matches.
  bool get _phoneAlreadyVerified => _verification.provesNumber(_digits);

  // --- pane three: password ----------------------------------------------

  String? get _passwordError => passwordError(_passwordController.text);

  String? get _confirmError => confirmPasswordError(
    _passwordController.text,
    _confirmPasswordController.text,
  );

  bool get _passwordComplete =>
      isPasswordPairValid(
        _passwordController.text,
        _confirmPasswordController.text,
      ) &&
      _agreedToTerms;

  // --- step movement ------------------------------------------------------

  /// Tabs move backwards only. Forward is what the buttons do, and each of
  /// them has a condition — a tap on "Password" that skipped the code would
  /// create the very thing this order exists to prevent: an account for a
  /// number nobody answered.
  void _onStepTapped(int index) {
    final step = SignUpStep.values[index];
    if (step.index > _step.index) return;
    _goToStep(step);
  }

  void _goToStep(SignUpStep step) {
    if (step == _step) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _movingForward = step.index > _step.index;
      _step = step;
      // The boxes are rebuilt empty whenever the pane is entered, so the code
      // held here has to go with them — otherwise coming back to the pane
      // after a code was accepted leaves Verify enabled over six empty boxes.
      if (step == SignUpStep.verify) {
        _code = '';
        _codeError = null;
      }
    });
  }

  /// Back one pane, or out of sign-up entirely from the first.
  void _back() {
    switch (_step) {
      case SignUpStep.details:
        _backToSignIn();
      case SignUpStep.verify:
        _goToStep(SignUpStep.details);
      case SignUpStep.password:
        // The code has been spent by now, so this returns to the pane the
        // user can still act on rather than to six boxes that would only
        // re-verify a number that is already proved.
        _goToStep(SignUpStep.details);
    }
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

  // --- verification -------------------------------------------------------

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  bool get _sendingCode => _verification.isSendingCode;

  bool get _verifyingCode => _verification.isVerifyingCode;

  bool get _canResend => _secondsLeft == 0 && !_verification.isBusy;

  bool get _canVerify => _code.length == _codeLength && !_verifyingCode;

  String get _countdownLabel {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Asks for the code. The move to the middle pane happens when the server
  /// says one went out — see [_onVerificationChanged].
  ///
  /// A number that already has an account is the one failure this has to
  /// handle well, and it is the server that knows: `register/request-otp`
  /// answers 409, and the message it sends back is shown on the field.
  void _requestCode() {
    if (!_detailsComplete || _verification.isBusy) return;
    FocusScope.of(context).unfocus();

    // Back on the first pane with a number that is already proved: there is
    // nothing to text, so this is a plain "continue". Asking again would spend
    // one of the three sends the server allows and retire a proof that works.
    if (_step == SignUpStep.details && _phoneAlreadyVerified) {
      _goToStep(SignUpStep.password);
      return;
    }

    setState(() => _codeError = null);
    context.read<RegistrationVerificationBloc>().add(
      RegistrationCodeRequested(
        countryCode: PhoneNumberField.dialCode,
        phone: _digits,
      ),
    );
  }

  /// Checks the six digits. The move to the password pane happens on the way
  /// back, once the server has handed over the proof that pane will spend.
  void _submitCode() {
    if (!_canVerify) return;
    FocusScope.of(context).unfocus();
    setState(() => _codeError = null);
    context.read<RegistrationVerificationBloc>().add(
      RegistrationCodeSubmitted(
        countryCode: PhoneNumberField.dialCode,
        phone: _digits,
        code: _code,
      ),
    );
  }

  void _clearCode() {
    _otpKey.currentState?.clear();
    setState(() {
      _code = '';
      _codeError = null;
    });
  }

  void _onVerificationChanged(
    BuildContext context,
    RegistrationVerificationState state,
  ) {
    final message = state.errorMessage;
    if (message != null) {
      if (state.numberRejected) {
        // About the number, not the code — so it belongs on the field that
        // owns it, on the pane the user can act from. No code is coming.
        setState(() {
          _phoneRejection = message;
          _rejectedPhone = _digits;
        });
        _goToStep(SignUpStep.details);
      } else if (state.codeRejected) {
        // Emptying the boxes first, then setting the message: `clear` reports
        // the empty code back through `onChanged`, which is also what wipes a
        // stale error — do it the other way round and the message this line
        // just set is the one that gets wiped.
        _otpKey.currentState?.clear();
        // Belongs under the boxes, not in a snackbar that slides away while
        // they are still looking at what they typed.
        setState(() {
          _code = '';
          _codeError = message;
        });
      } else {
        _showMessage(message);
      }
      context.read<RegistrationVerificationBloc>().add(
        const RegistrationVerificationErrorDismissed(),
      );
      return;
    }

    switch (state.status) {
      case RegistrationVerificationStatus.codeSent:
        _clearCode();
        _startResendCountdown();
        // Already on the boxes: this was a resend, and saying so is the only
        // sign anything happened.
        if (_step == SignUpStep.verify) {
          _showMessage('A new code is on its way to $_displayPhone.');
        } else {
          _goToStep(SignUpStep.verify);
        }
      case RegistrationVerificationStatus.verified:
        _resendTimer?.cancel();
        _goToStep(SignUpStep.password);
      case RegistrationVerificationStatus.initial:
      case RegistrationVerificationStatus.sendingCode:
      case RegistrationVerificationStatus.verifyingCode:
        // Nothing to do: the loading states drive the buttons, and `initial`
        // is where a discarded proof lands the user back on the first pane.
        break;
    }
  }

  // --- registration -------------------------------------------------------

  /// Creates the account, which also signs it in. One request, at the end,
  /// with everything the three panes collected.
  void _createAccount() {
    final bloc = context.read<AuthenticationBloc>();
    if (!_passwordComplete || bloc.state.isBusy) return;
    FocusScope.of(context).unfocus();
    bloc.add(
      AuthenticationSignUpRequested(
        countryCode: PhoneNumberField.dialCode,
        phone: _digits,
        password: _passwordController.text,
        name: _name,
        // Only when it proves *this* number: the token names the one it was
        // issued for, and the server refuses a mismatch. Sending it anyway
        // would turn an edited digit into a failed sign-up.
        verificationToken: _phoneAlreadyVerified ? _verification.token : null,
        email: _email.isEmpty ? null : _email,
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthenticationState state) {
    final message = state.errorMessage;
    if (message != null) {
      _showMessage(message);
      context.read<AuthenticationBloc>().add(
        const AuthenticationErrorDismissed(),
      );
    }

    // The proof of the number died between the code pane and this one — it is
    // good for ten minutes, and choosing a password can take longer. Nothing
    // on the password pane can fix that, so the proof goes and the user is
    // returned to the number to ask for a fresh code.
    if (state.verificationExpired) {
      context.read<RegistrationVerificationBloc>().add(
        const RegistrationVerificationInvalidated(),
      );
      _goToStep(SignUpStep.details);
    }

    // Registering signs the account in, and the number was proved before the
    // account existed — so the only thing left is the optional picture.
    if (state.isAuthenticated) {
      context.goNamed(AppRoutes.profilePhoto);
    }
  }

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

  void _openLegalDocument(String title) {
    // TODO(auth): point these at the hosted legal documents when they exist.
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This document is not available yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: _onAuthStateChanged,
        ),
        BlocListener<
          RegistrationVerificationBloc,
          RegistrationVerificationState
        >(
          // Clearing a message re-emits the status it was carried on, and a
          // rejected code sits on `codeSent`. Without this, dismissing "that
          // code is invalid" would immediately be followed by "a new code is
          // on its way" — for a resend nobody asked for and the server never
          // made.
          listenWhen: (previous, current) =>
              previous.status != current.status || current.errorMessage != null,
          listener: _onVerificationChanged,
        ),
      ],
      // Both blocs drive the buttons: one owns the code calls, the other the
      // registration at the end.
      child: BlocBuilder<
        RegistrationVerificationBloc,
        RegistrationVerificationState
      >(
        builder: (context, _) =>
            BlocBuilder<AuthenticationBloc, AuthenticationState>(
              builder: (context, state) => _buildPage(context, state.isBusy),
            ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, bool isSubmitting) {
    return PopScope(
      // The first pane is the only one where leaving means leaving sign-up;
      // on the others the gesture walks back a pane instead.
      canPop: _step == SignUpStep.details,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
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
                  AuthHeader(onBack: _back),
                  const SizedBox(height: 18),
                  Center(child: _hero),
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
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  AuthStepTabs(
                    labels: signUpTabLabels,
                    currentStep: _step.index,
                    onStepTapped: _onStepTapped,
                  ),
                  const SizedBox(height: 26),
                  _AnimatedPane(
                    stepIndex: _step.index,
                    movingForward: _movingForward,
                    child: switch (_step) {
                      SignUpStep.details => _buildDetailsPane(),
                      SignUpStep.verify => _buildVerifyPane(),
                      SignUpStep.password => _buildPasswordPane(isSubmitting),
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Already have an account? ',
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
      ),
    );
  }

  Widget get _hero => switch (_step) {
    SignUpStep.details => const HeroIllustration(
      icon: Icons.person_outline,
      badges: [
        HeroBadge(
          icon: Icons.savings_rounded,
          color: AppColors.accentGold,
          alignment: Alignment.topCenter,
        ),
      ],
    ),
    SignUpStep.verify => const HeroIllustration(
      icon: Icons.sms_outlined,
      badges: [
        HeroBadge(
          icon: Icons.check,
          color: AppColors.primaryGreen,
          alignment: Alignment.topCenter,
        ),
      ],
    ),
    SignUpStep.password => const HeroIllustration(
      icon: Icons.lock_outline,
      badges: [
        HeroBadge(
          icon: Icons.shield_outlined,
          color: AppColors.primaryGreen,
          alignment: Alignment.topCenter,
        ),
      ],
    ),
  };

  String get _title => switch (_step) {
    SignUpStep.details => 'Create Account',
    SignUpStep.verify => 'Verify Your Number',
    SignUpStep.password => 'Set Your Password',
  };

  String get _subtitle => switch (_step) {
    SignUpStep.details => 'Tell us who you are.\nIt takes about a minute.',
    SignUpStep.verify =>
      'We sent a $_codeLength-digit code to\n$_displayPhone.',
    SignUpStep.password => 'Last step — pick a password\nfor $_name.',
  };

  // --- pane one -----------------------------------------------------------

  Widget _buildDetailsPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Full name',
          controller: _nameController,
          hintText: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          focusNode: _nameFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _phoneFocus.requestFocus(),
        ),
        const SizedBox(height: 14),
        PhoneNumberField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _emailFocus.requestFocus(),
          onValidChanged: (isValid) => setState(() => _phoneValid = isValid),
          // "Phone is already registered", in the server's own words and on
          // the field it is about — the user's move from here is to sign in
          // or to correct a digit, and both start here.
          errorText: _phoneServerError,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Email (optional)',
          controller: _emailController,
          hintText: 'you@example.com',
          prefixIcon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          focusNode: _emailFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _requestCode(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add an email and you can recover the account without your SIM.',
          style: TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: _phoneAlreadyVerified ? 'Continue' : 'Send Code',
          icon: Icons.arrow_forward_rounded,
          isLoading: _sendingCode,
          onPressed: _detailsComplete && !_sendingCode ? _requestCode : null,
        ),
      ],
    );
  }

  // --- pane two -----------------------------------------------------------

  Widget _buildVerifyPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhoneChip(phoneNumber: _displayPhone, onEdit: _back),
        const SizedBox(height: 22),
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
          enabled: !_verifyingCode,
          hasError: _codeError != null,
          onChanged: (code) => setState(() {
            _code = code;
            _codeError = null;
          }),
          onCompleted: (_) => _submitCode(),
        ),
        if (_codeError case final error?) ...[
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 20),
        ResendCodeCard(
          canResend: _canResend,
          isSending: _sendingCode,
          countdown: _countdownLabel,
          onResend: _requestCode,
        ),
        if (kDebugMode && _verification.devCode != null) ...[
          const SizedBox(height: 12),
          _DevCodeHint(
            code: _verification.devCode!,
            onFill: () =>
                _otpKey.currentState?.fill(_verification.devCode!),
          ),
        ],
        const SizedBox(height: 20),
        GradientButton(
          label: 'Verify',
          icon: Icons.verified_outlined,
          isLoading: _verifyingCode,
          onPressed: _canVerify ? _submitCode : null,
        ),
      ],
    );
  }

  // --- pane three ---------------------------------------------------------

  Widget _buildPasswordPane(bool isSubmitting) {
    final password = _passwordController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_phoneAlreadyVerified) ...[
          _VerifiedNumberChip(phoneNumber: _displayPhone),
          const SizedBox(height: 18),
        ],
        AppTextField(
          label: 'Password',
          controller: _passwordController,
          hintText: '••••••••',
          prefixIcon: Icons.lock_open_outlined,
          obscureText: _obscurePassword,
          errorText: _passwordError,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _confirmFocus.requestFocus(),
          suffix: _VisibilityToggle(
            obscured: _obscurePassword,
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 12),
        _PasswordChecklist(
          isLongEnough: password.length >= minPasswordLength,
          matches:
              password.isNotEmpty &&
              password == _confirmPasswordController.text,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirm,
          errorText: _confirmError,
          focusNode: _confirmFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _createAccount(),
          suffix: _VisibilityToggle(
            obscured: _obscureConfirm,
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 16),
        _TermsCheckbox(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value),
          termsTap: _termsTap,
          privacyTap: _privacyTap,
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Create Account',
          icon: Icons.check_rounded,
          isLoading: isSubmitting,
          onPressed: _passwordComplete && !isSubmitting ? _createAccount : null,
        ),
      ],
    );
  }
}

/// Slides the next pane in, from the side the user is moving towards.
///
/// Only the incoming pane is laid out. `AnimatedSwitcher` would by default
/// stack the outgoing one behind it, which costs twice here: the column
/// jumps to the taller of the two mid-swap, and — because the verification
/// pane's boxes are held by a `GlobalKey` — a fast there-and-back would put
/// two widgets carrying that key in the tree at once, which is a crash rather
/// than a glitch.
class _AnimatedPane extends StatelessWidget {
  const _AnimatedPane({
    required this.stepIndex,
    required this.movingForward,
    required this.child,
  });

  final int stepIndex;
  final bool movingForward;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      layoutBuilder: (currentChild, _) =>
          currentChild ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(movingForward ? 0.15 : -0.15, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(stepIndex), child: child),
    );
  }
}

/// The number the code went to, with a way back to the pane that owns it —
/// a mistyped digit is the likeliest reason no code arrives.
class _PhoneChip extends StatelessWidget {
  const _PhoneChip({required this.phoneNumber, required this.onEdit});

  final String phoneNumber;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Text('🇰🇭', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              phoneNumber,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 15,
              color: AppColors.primaryGreen,
            ),
            label: const Text(
              'Change',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The same number on the last pane, ticked — the point of putting the code
/// before the password is that by here the number is settled, and the user
/// should be able to see that without going back.
class _VerifiedNumberChip extends StatelessWidget {
  const _VerifiedNumberChip({required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 18,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$phoneNumber verified',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
/// without this a debug build against a server with mocked codes has no way to
/// know what to type. Never built in release: see the `kDebugMode` guard on
/// its use, which is also why a release build against such a server simply
/// cannot get past this pane.
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

/// The two rules the password pane enforces, ticked as they are met — cheaper
/// to read than an error that only appears once you have got it wrong.
class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({
    required this.isLongEnough,
    required this.matches,
  });

  final bool isLongEnough;
  final bool matches;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RuleChip(
          label: 'At least $minPasswordLength characters',
          satisfied: isLongEnough,
        ),
        const SizedBox(width: 8),
        _RuleChip(label: 'Both match', satisfied: matches),
      ],
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final color = satisfied ? AppColors.primaryGreen : AppColors.textHint;
    return Expanded(
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: TextStyle(color: color, fontSize: 11.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.termsTap,
    required this.privacyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final TapGestureRecognizer termsTap;
  final TapGestureRecognizer privacyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            activeColor: AppColors.primaryGreen,
            side: const BorderSide(color: AppColors.textSecondary),
            onChanged: (checked) => onChanged(checked ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms & Conditions',
                  recognizer: termsTap,
                  style: const TextStyle(color: AppColors.primaryGreen),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  recognizer: privacyTap,
                  style: const TextStyle(color: AppColors.primaryGreen),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
