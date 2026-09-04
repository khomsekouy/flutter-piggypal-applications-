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

/// Brings back an account that was deleted but not yet purged.
///
/// A screen of its own rather than a branch of sign-in, because signing in is
/// exactly what does *not* work here: the API refuses a deleted account, so
/// the only way back is `POST /auth/restore-account`. Without this screen the
/// recovery window the server keeps would be unreachable from the app, and the
/// date shown at deletion would be a promise nothing could keep.
///
/// Takes the same two fields as sign-in and, when it succeeds, hands back the
/// same thing: a session. The user is simply signed in.
class RestoreAccountPage extends StatefulWidget {
  const RestoreAccountPage({super.key});

  @override
  State<RestoreAccountPage> createState() => _RestoreAccountPageState();
}

class _RestoreAccountPageState extends State<RestoreAccountPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

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

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  bool _canSubmit(bool isBusy) =>
      _phoneValid && _passwordController.text.isNotEmpty && !isBusy;

  void _handleRestore() {
    if (!_canSubmit(context.read<AuthenticationBloc>().state.isBusy)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthenticationBloc>().add(
      AuthenticationAccountRestoreRequested(
        countryCode: PhoneNumberField.dialCode,
        phone: _digits,
        password: _passwordController.text,
      ),
    );
  }

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
      context.goNamed(AppRoutes.home);
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(onBack: _backToSignIn),
                const SizedBox(height: 20),
                const Center(
                  child: HeroIllustration(
                    icon: Icons.restore_rounded,
                    badges: [
                      HeroBadge(
                        icon: Icons.history,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Recover Your Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Deleted an account by mistake? Enter the number and\n'
                  'password it used and we will put it back.',
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
                  onSubmitted: (_) => _handleRestore(),
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
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Recover Account',
                  icon: Icons.restore_rounded,
                  isLoading: isBusy,
                  onPressed: _canSubmit(isBusy) ? _handleRestore : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Once the recovery window has passed the account cannot be '
                  'brought back, and the number is free to register again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
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
