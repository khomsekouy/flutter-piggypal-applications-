import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/forgot_password_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/profile_photo_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/reset_password_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/restore_account_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/sign_in_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/sign_up_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/verify_number_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/verify_phone_page.dart';
import 'package:flutter_piggypal_app/features/splash/presentation/view/splash_page.dart';
import 'package:flutter_piggypal_app/features/training_finance/training_finance_app.dart';
import 'package:go_router/go_router.dart';

/// Builds and owns the app's [GoRouter].
///
/// Every top-level route is declared here in one place. Screens navigate by
/// route **name** (see [AppRoutes]) via `context.goNamed(...)` /
/// `context.pushNamed(...)`, so the URL paths can change without touching the
/// screens.
///
/// Usage — hand [router] to `MaterialApp.router` in `app/view/app.dart`.
abstract final class AppRouter {
  AppRouter._();

  /// The single router instance for the whole app.
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splashPath,
    // Set to `true` while wiring routes to see every navigation in the logs.
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.signInPath,
        name: AppRoutes.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.restoreAccountPath,
        name: AppRoutes.restoreAccount,
        builder: (context, state) => const RestoreAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.signUpPath,
        name: AppRoutes.signUp,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePhotoPath,
        name: AppRoutes.profilePhoto,
        // Nothing to pass: the account is created at the end of the sign-up
        // screen, so this one reads the name it needs off the session and
        // uploads the picture against it.
        builder: (context, state) => const ProfilePhotoPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyPhonePath,
        name: AppRoutes.verifyPhone,
        builder: (context, state) => const VerifyPhonePage(),
      ),
      GoRoute(
        path: AppRoutes.verifyNumberPath,
        name: AppRoutes.verifyNumber,
        builder: (context, state) {
          // Passed as `?phone=...`, with `?countryCode=...` beside it on the
          // reset path — that flow's `verify-otp` call wants the dial code
          // and the national digits apart, so they travel apart rather than
          // being re-split out of one display string here.
          final params = state.uri.queryParameters;
          return VerifyNumberPage(
            phoneNumber: params['phone'] ?? '',
            countryCode: params['countryCode'],
            purpose: VerifyPurpose.fromQueryValue(params['purpose']),
            // Step one passes the code the server echoed back when it is
            // running with mocked ones, so a debug build can prefill it.
            // Absent on a deep link, which is the same as no mock.
            devCode: state.extra is String ? state.extra! as String : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordPath,
        name: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPasswordPath,
        name: AppRoutes.resetPassword,
        builder: (context, state) {
          // Reached after the code sent to this number was verified. The
          // number is only shown; the reset token is what the call needs, and
          // it rides in `extra` rather than the query string because a URL is
          // the one part of this that gets logged, shared and restored.
          final phone = state.uri.queryParameters['phone'] ?? '';
          return ResetPasswordPage(
            phoneNumber: phone,
            resetToken: state.extra is String ? state.extra! as String : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.home,
        // TrainingFinanceApp — not TFShell directly. It owns the module's
        // TFThemeScope, text/icon defaults and status-bar treatment, all of
        // which TFShell reads via `context.tf`.
        //
        // Inside it, TFShell drives navigation between the dashboard,
        // programs, reports and so on through its own push stack; go_router
        // only needs to know how to reach the module.
        builder: (context, state) => const TrainingFinanceApp(),
      ),
    ],
    // Shown if a route name/path is mistyped or a deep link doesn't match.
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}
