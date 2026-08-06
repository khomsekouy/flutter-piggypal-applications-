import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/utils/password_rules.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/app_text_field.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:go_router/go_router.dart';

/// Last step of the password reset: choose the new password.
///
/// Only reachable once the code sent to [phoneNumber] has been verified —
/// the number is carried through the flow so the reset can be tied to it.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({required this.phoneNumber, super.key});

  /// The verified number, already formatted with its dial code. Empty when
  /// the route is opened without a `phone` query parameter.
  final String phoneNumber;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

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

  bool get _canSubmit =>
      isPasswordPairValid(
        _passwordController.text,
        _confirmPasswordController.text,
      ) &&
      !_isLoading;

  Future<void> _handleUpdatePassword() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    // TODO(auth): send the new password with the verification token from the
    // previous step; today this only simulates the round trip.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    // The messenger lives above the router, so the confirmation survives the
    // jump back to sign-in.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(
          'Password updated. Sign in with your new password.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
    // Replaces the reset stack: the code has been spent, so none of these
    // screens should be reachable with a back gesture.
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
