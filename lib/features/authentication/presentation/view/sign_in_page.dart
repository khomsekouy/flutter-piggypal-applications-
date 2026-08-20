import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/app_text_field.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/phone_number_field.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  /// Whether the number satisfies the selected country's length rule.
  bool _phoneValid = false;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _phoneController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _passwordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  /// Digits only — the field strips the dial code and any leading zero, and
  /// `POST /auth/login` wants the national number on its own.
  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  bool _canSubmit(bool isBusy) =>
      _phoneValid && _passwordController.text.isNotEmpty && !isBusy;

  void _handleSignIn() {
    if (!_canSubmit(context.read<AuthenticationBloc>().state.isBusy)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthenticationBloc>().add(
      AuthenticationSignInRequested(
        countryCode: PhoneNumberField.dialCode,
        phone: _digits,
        password: _passwordController.text,
      ),
    );
  }

  /// Navigation and errors both live here rather than after an awaited call:
  /// the bloc is app-wide, so the result of a sign-in can arrive at any time
  /// — including from a launch check that finished while this screen was up.
  void _onAuthStateChanged(BuildContext context, AuthenticationState state) {
    final message = state.errorMessage;
    if (message != null) {
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
      context.read<AuthenticationBloc>().add(
        const AuthenticationErrorDismissed(),
      );
    }

    if (state.isAuthenticated) {
      // Replaces the auth stack so back from home cannot return to sign-in.
      context.goNamed(AppRoutes.home);
    }
  }

  void _goToCreateAccount() {
    unawaited(context.pushNamed(AppRoutes.createAccount));
  }

  void _goToForgotPassword() {
    unawaited(context.pushNamed(AppRoutes.forgotPassword));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: _onAuthStateChanged,
      builder: _buildForm,
    );
  }

  Widget _buildForm(BuildContext context, AuthenticationState state) {
    final isBusy = state.isBusy;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            // Taller top inset than the other auth screens: they push the
            // wordmark down with a back-button row, and sign-in has none.
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(),
                const SizedBox(height: 24),
                const Center(
                  child: HeroIllustration(
                    icon: Icons.account_balance_wallet_rounded,
                    badges: [
                      HeroBadge(
                        icon: Icons.attach_money,
                        color: AppColors.accentGold,
                      ),
                      HeroBadge(
                        icon: Icons.trending_up,
                        color: AppColors.primaryGreen,
                        alignment: Alignment.bottomLeft,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue managing\nyour money smarter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 28),
                PhoneNumberField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  onValidChanged: (isValid) =>
                      setState(() => _phoneValid = isValid),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSignIn(),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _goToForgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GradientButton(
                  label: 'Sign In',
                  icon: Icons.lock_outline,
                  isLoading: isBusy,
                  onPressed: _canSubmit(isBusy) ? _handleSignIn : null,
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.surfaceBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.surfaceBorder)),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'New here? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: _goToCreateAccount,
                        child: const Text(
                          'Sign Up',
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
