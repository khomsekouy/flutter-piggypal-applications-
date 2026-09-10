import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/password_reset_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/utils/password_rules.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/app_text_field.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:go_router/go_router.dart';

/// Last step of the password reset: choose the new password.
///
/// Only reachable once the code sent to [phoneNumber] has been verified —
/// [resetToken] is the proof of that, and without it there is nothing this
/// screen can do but send the user back to the start.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({
    required this.phoneNumber,
    this.resetToken,
    super.key,
  });

  /// The verified number, already formatted with its dial code. Empty when
  /// the route is opened without a `phone` query parameter. Shown, and
  /// nothing more: the reset is tied to [resetToken], not to this.
  final String phoneNumber;

  /// The ticket `verify-otp` minted, handed over as the route's `extra`.
  ///
  /// Null when this screen is reached any other way — a deep link, or a
  /// restored route — in which case the form is closed and the only way on is
  /// through the flow proper. Ten minutes, one use, and stored nowhere.
  final String? resetToken;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PasswordResetBloc>(),
      child: _ResetPasswordView(
        phoneNumber: phoneNumber,
        resetToken: resetToken,
      ),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView({required this.phoneNumber, this.resetToken});

  final String phoneNumber;
  final String? resetToken;

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _passwordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  String? get _passwordError => passwordError(_passwordController.text);

  String? get _confirmError => confirmPasswordError(
    _passwordController.text,
    _confirmPasswordController.text,
  );

  /// Read, not watched: this is reached from the submit handler as well as
  /// from `build`, and `watch` outside a build throws.
  bool get _isLoading =>
      context.read<PasswordResetBloc>().state.isUpdatingPassword;

  /// Whether there is a ticket to spend. Without one the server would refuse
  /// whatever was typed, so the form stays closed and says why.
  bool get _hasToken => widget.resetToken?.isNotEmpty ?? false;

  bool get _canSubmit =>
      _hasToken &&
      isPasswordPairValid(
        _passwordController.text,
        _confirmPasswordController.text,
      ) &&
      !_isLoading;

  void _handleUpdatePassword() {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    context.read<PasswordResetBloc>().add(
      PasswordResetSubmitted(
        resetToken: widget.resetToken!,
        newPassword: _passwordController.text,
      ),
    );
  }

  void _showMessage(String message) {
    // The messenger lives above the router, so a message survives the jump
    // off this screen.
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

  void _onResetStateChanged(BuildContext context, PasswordResetState state) {
    final message = state.errorMessage;
    if (message != null) {
      _showMessage(message);
      context.read<PasswordResetBloc>().add(
        const PasswordResetErrorDismissed(),
      );
      // A rejected token means the ten minutes ran out, or it was already
      // spent. Nothing on this screen can succeed after that, so the user
      // goes back to the number rather than retyping a password into a form
      // that will keep failing.
      if (state.codeRejected) {
        context.goNamed(AppRoutes.forgotPassword);
      }
      return;
    }

    if (state.status != PasswordResetStatus.passwordUpdated) return;

    _showMessage('Password updated. Sign in with your new password.');
    // Replaces the reset stack: the code and the token are both spent, so
    // none of these screens should be reachable with a back gesture.
    context.goNamed(AppRoutes.signIn);
  }

  void _backToSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasswordResetBloc, PasswordResetState>(
      listener: _onResetStateChanged,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final account = widget.phoneNumber.isEmpty
        ? 'your account'
        : widget.phoneNumber;
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
                    icon: Icons.password_rounded,
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
                  'Set a New Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                      const TextSpan(text: 'Choose a new password for\n'),
                      TextSpan(
                        text: account,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'New Password',
                  controller: _passwordController,
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_open_outlined,
                  obscureText: _obscurePassword,
                  errorText: _passwordError,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _confirmFocus.requestFocus(),
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
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
                  onSubmitted: (_) => _handleUpdatePassword(),
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                if (!_hasToken) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'This link has expired. Start again from Forgot '
                    'Password to get a new code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 28),
                GradientButton(
                  label: 'Update Password',
                  icon: Icons.lock_reset,
                  isLoading: _isLoading,
                  onPressed: _canSubmit ? _handleUpdatePassword : null,
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _backToSignIn,
                    child: const Text(
                      'Back to Sign In',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
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
    );
  }
}
