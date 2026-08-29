import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/utils/password_rules.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/app_text_field.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_step_indicator.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/hero_illustration.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/phone_number_field.dart';
import 'package:go_router/go_router.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  /// Whether the number satisfies the Cambodian length rule. Owned by
  /// [PhoneNumberField], which enforces it.
  bool _phoneValid = false;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _phoneController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openLegalDocument('Terms & Conditions');
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => _openLegalDocument('Privacy Policy');
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _phoneController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  String? get _passwordError => passwordError(_passwordController.text);

  String? get _confirmError => confirmPasswordError(
    _passwordController.text,
    _confirmPasswordController.text,
  );

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _phoneValid &&
      isPasswordPairValid(
        _passwordController.text,
        _confirmPasswordController.text,
      ) &&
      _agreedToTerms;

  /// Creates the account. `POST /auth/register` goes out from here, and the
  /// session it answers with is what the rest of sign-up runs on: the number
  /// cannot be verified without one, because the API sends codes only to the
  /// number on the caller's own session.
  ///
  /// The photo comes later, on the last screen, and is a separate request —
  /// there is no registration call left to attach it to by then.
  void _handleNext() {
    final bloc = context.read<AuthenticationBloc>();
    if (!_canSubmit || bloc.state.isBusy) return;
    FocusScope.of(context).unfocus();
    bloc.add(
      AuthenticationSignUpRequested(
        countryCode: PhoneNumberField.dialCode,
        phone: _digits,
        password: _passwordController.text,
        name: _nameController.text.trim(),
      ),
    );
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

  void _onAuthStateChanged(BuildContext context, AuthenticationState state) {
    final message = state.errorMessage;
    if (message != null) {
      _showMessage(message);
      context.read<AuthenticationBloc>().add(
        const AuthenticationErrorDismissed(),
      );
    }

    // Registering signs the account in, so what is left is proving the
    // number — the step that needed this session to exist at all.
    if (state.isAuthenticated) {
      if (state.user?.phoneVerified ?? false) {
        context.goNamed(AppRoutes.profilePhoto);
      } else {
        context.goNamed(AppRoutes.verifyPhone);
      }
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: _onAuthStateChanged,
      builder: (context, state) => _buildPage(context, state.isBusy),
    );
  }

  Widget _buildPage(BuildContext context, bool isSubmitting) {
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
                    icon: Icons.savings_rounded,
                    badges: [
                      HeroBadge(
                        icon: Icons.attach_money,
                        color: AppColors.accentGold,
                        alignment: Alignment.topCenter,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start saving smarter in a\ncouple of taps.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const AuthStepIndicator(step: 1, totalSteps: 4),
                const SizedBox(height: 24),
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
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  onValidChanged: (isValid) =>
                      setState(() => _phoneValid = isValid),
                ),
                const SizedBox(height: 14),
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
                  onSubmitted: (_) => _handleNext(),
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
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        activeColor: AppColors.primaryGreen,
                        side: const BorderSide(
                          color: AppColors.textSecondary,
                        ),
                        onChanged: (value) =>
                            setState(() => _agreedToTerms = value ?? false),
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
                              recognizer: _termsTap,
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              recognizer: _privacyTap,
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: isSubmitting,
                  onPressed: _canSubmit && !isSubmitting ? _handleNext : null,
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
    );
  }
}
