import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/create_account_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/forgot_password_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/profile_photo_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/reset_password_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/sign_in_page.dart';
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
        path: AppRoutes.createAccountPath,
        name: AppRoutes.createAccount,
        builder: (context, state) => const CreateAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePhotoPath,
        name: AppRoutes.profilePhoto,
        // Nothing to pass any more: the account is created on the first
        // screen of sign-up, so this one reads the name it needs off the
        // session and uploads the picture against it.
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
          // Passed as `?phone=...` — e.g.
          // context.goNamed(AppRoutes.verifyNumber,
          //   queryParameters: {'phone': '+855 12345678'});
          final phone = state.uri.queryParameters['phone'] ?? '';
          return VerifyNumberPage(
            phoneNumber: phone,
            purpose: VerifyPurpose.fromQueryValue(
              state.uri.queryParameters['purpose'],
            ),
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
          // Reached after the code sent to this number was verified.
          final phone = state.uri.queryParameters['phone'] ?? '';
          return ResetPasswordPage(phoneNumber: phone);
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
