import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/forgot_password_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('ForgotPasswordPage', () {
    late FakeAuthApi api;

    setUp(() async => api = await setUpDependencies());

    tearDown(tearDownDependencies);

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpApp(const ForgotPasswordPage());
    }

    bool submitEnabled(WidgetTester tester) {
      final button = tester.widget<GradientButton>(
        find.byType(GradientButton),
      );
      return button.onPressed != null;
    }

    testWidgets('asks for the Cambodian number the account uses', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('+855'), findsOneWidget);
    });

    testWidgets('send code is disabled until the number is valid', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.pump();
      expect(submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).first, '12345678');
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    /// Pumps the page inside a router with the code screen to move on to,
    /// and hands the router back so a test can step off that screen again.
    Future<GoRouter> pumpFlow(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            name: AppRoutes.forgotPassword,
            builder: (_, _) => const ForgotPasswordPage(),
          ),
          GoRoute(
            path: '/verify-number',
            name: AppRoutes.verifyNumber,
            builder: (_, state) => Scaffold(
              body: Text('verify ${state.uri.query}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.enterText(find.byType(TextField).first, '12345678');
      await tester.pump();
      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('sending a code asks the server, split as the API wants it', (
      tester,
    ) async {
      await pumpFlow(tester);

      expect(api.requestTo('/auth/forgot-password')?.fields, {
        'countryCode': '+855',
        'phone': '12345678',
      });
      // No session exists in this flow, and the call must not wait on one.
      expect(api.requestTo('/auth/forgot-password')?.isAuthenticated, isFalse);
    });

    testWidgets('sending a code opens verification for the reset flow', (
      tester,
    ) async {
      await pumpFlow(tester);

      // The number travels split, and the flow with it: without the purpose
      // the next screen would verify the user straight into sign-up.
      expect(
        find.text(
          'verify phone=12345678&countryCode=%2B855&purpose=password-reset',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an unknown number opens verification just the same', (
      tester,
    ) async {
      api.resetPhone = '+85599999999';

      await pumpFlow(tester);

      // Stopping here for a number with no account would say which numbers
      // have accounts — the one thing this endpoint is shaped to prevent.
      expect(
        find.textContaining('verify phone=12345678'),
        findsOneWidget,
      );
    });

    testWidgets('a throttled send stays put and says why', (tester) async {
      api.throttleResetRequests = true;

      await pumpFlow(tester);

      // Nothing was sent, so moving on to the code screen would strand the
      // user in front of six boxes no code will ever fill.
      expect(find.textContaining('verify phone='), findsNothing);
      expect(
        find.text('Too many attempts. Please wait a few minutes and try '
            'again.'),
        findsOneWidget,
      );
    });

    testWidgets('a send refused after a good one still stays put', (
      tester,
    ) async {
      final router = await pumpFlow(tester);
      // Back to the number, as "change phone number" on the code screen does.
      expect(find.textContaining('verify phone='), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      api.throttleResetRequests = true;
      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      // The refused send leaves the bloc on the `codeSent` it reached the
      // first time, so clearing the message re-emits that status. It must not
      // be mistaken for a second successful send.
      expect(find.textContaining('verify phone='), findsNothing);
      expect(
        find.text('Too many attempts. Please wait a few minutes and try '
            'again.'),
        findsOneWidget,
      );
    });
  });
}
