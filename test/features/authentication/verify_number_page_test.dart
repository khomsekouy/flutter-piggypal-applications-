import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/verify_number_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('VerifyNumberPage', () {
    late FakeAuthApi api;
    late AuthenticationBloc auth;

    setUp(() async {
      api = await setUpDependencies()
        // A brand-new account: unverified, which is the only state this
        // screen is ever reached in.
        ..phoneVerified = false;
      auth = sl<AuthenticationBloc>()
        ..add(
          const AuthenticationSignInRequested(
            countryCode: '+855',
            phone: '12345678',
            password: 'supersecret',
          ),
        );
      await auth.stream.firstWhere((state) => state.isAuthenticated);
    });

    tearDown(() async {
      await auth.close();
      await tearDownDependencies();
    });

    /// Pumps the screen inside a router with somewhere to go, and the session
    /// it verifies against.
    Future<void> pumpPage(
      WidgetTester tester, {
      String phoneNumber = '+855 12 345 678',
      VerifyPurpose purpose = VerifyPurpose.signUp,
      String? devCode,
    }) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/verify',
        routes: [
          GoRoute(
            path: '/verify',
            name: AppRoutes.verifyNumber,
            builder: (_, _) => VerifyNumberPage(
              phoneNumber: phoneNumber,
              purpose: purpose,
              devCode: devCode,
            ),
          ),
          GoRoute(
            path: '/profile-photo',
            name: AppRoutes.profilePhoto,
            builder: (_, _) => const Scaffold(body: Text('photo step')),
          ),
          GoRoute(
            path: '/home',
            name: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('home stub')),
          ),
          GoRoute(
            path: '/reset-password',
            name: AppRoutes.resetPassword,
            builder: (_, state) => Scaffold(
              body: Text('reset ${state.uri.queryParameters['phone']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    }

    /// Tears the tree down so the resend countdown's periodic timer is
    /// cancelled before the framework checks for pending timers.
    Future<void> disposeTree(WidgetTester tester) =>
        tester.pumpWidget(const SizedBox());

    bool verifyEnabled(WidgetTester tester) {
      final button = tester.widget<GradientButton>(find.byType(GradientButton));
      return button.onPressed != null;
    }

    Future<void> enterCode(WidgetTester tester, String code) async {
      for (var i = 0; i < code.length; i++) {
        await tester.enterText(find.byType(TextField).at(i), code[i]);
        await tester.pump();
      }
    }

    testWidgets('shows the number the code was sent to', (tester) async {
      await pumpPage(tester);

      expect(find.text('+855 12 345 678'), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('falls back when no number was passed', (tester) async {
      await pumpPage(tester, phoneNumber: '');

      expect(find.text('your number'), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('renders six code boxes', (tester) async {
      await pumpPage(tester);

      expect(find.byType(TextField), findsNWidgets(6));
      await disposeTree(tester);
    });

    testWidgets('is the third of the four sign-up steps', (tester) async {
      await pumpPage(tester);

      expect(find.text('Step 3 of 4'), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('verify stays disabled on a partial code', (tester) async {
      await pumpPage(tester);

      expect(verifyEnabled(tester), isFalse);

      await enterCode(tester, '12345');
      expect(verifyEnabled(tester), isFalse);

      await disposeTree(tester);
    });

    testWidgets('counts down before allowing a resend', (tester) async {
      await pumpPage(tester);

      expect(
        find.textContaining('01:00', findRichText: true),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 1));
      expect(
        find.textContaining('00:59', findRichText: true),
        findsOneWidget,
      );

      await disposeTree(tester);
    });

    testWidgets('offers a resend once the countdown expires', (tester) async {
      await pumpPage(tester);

      await tester.pump(const Duration(seconds: 60));

      expect(find.text('Resend'), findsOneWidget);
      expect(
        find.textContaining('Resend in', findRichText: true),
        findsNothing,
      );

      await disposeTree(tester);
    });

    testWidgets('resending asks the server for another code', (tester) async {
      await pumpPage(tester);
      await tester.pump(const Duration(seconds: 60));

      await tester.tap(find.text('Resend'));
      await tester.pumpAndSettle();

      expect(api.codeRequests, 1);
      // And the wait starts over rather than allowing a second tap.
      expect(find.textContaining('01:00', findRichText: true), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('typing advances focus to the next box', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(0), '4');
      await tester.pump();

      final second = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(second.focusNode?.hasFocus, isTrue);

      await disposeTree(tester);
    });

    testWidgets('a correct code verifies and continues to the photo step', (
      tester,
    ) async {
      await pumpPage(tester);

      await enterCode(tester, api.mockCode);
      await tester.pumpAndSettle();

      expect(api.called('/auth/verify-phone/confirm'), isTrue);
      expect(find.text('photo step'), findsOneWidget);
    });

    testWidgets('a rejected code says so and clears the boxes', (tester) async {
      await pumpPage(tester);

      await enterCode(tester, '000000');
      await tester.pumpAndSettle();

      // The server's own wording, not a message invented here.
      expect(
        find.text('Verification code is invalid or expired'),
        findsOneWidget,
      );
      expect(find.text('photo step'), findsNothing);

      // Boxes emptied, so the next attempt starts from nothing.
      final first = tester.widget<TextField>(find.byType(TextField).first);
      expect(first.controller?.text, isEmpty);

      await disposeTree(tester);
    });

    testWidgets('a wrong code costs exactly one attempt', (tester) async {
      await pumpPage(tester);

      await enterCode(tester, '000000');
      await tester.pumpAndSettle();

      // The refresh interceptor must not replay this: the server counts an
      // attempt before it compares, so a replay would spend two of the five
      // guesses the user gets.
      final attempts = api.requests
          .where((r) => r.path.endsWith('/auth/verify-phone/confirm'))
          .length;
      expect(attempts, 1);
      expect(api.called('/auth/refresh'), isFalse);

      await disposeTree(tester);
    });

    testWidgets('verifying later moves on to the photo step unverified', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.text('Verify later'));
      await tester.pumpAndSettle();

      expect(find.text('photo step'), findsOneWidget);
      expect(api.called('/auth/verify-phone/confirm'), isFalse);
    });

    testWidgets('a reset code continues to the new-password screen', (
      tester,
    ) async {
      await pumpPage(tester, purpose: VerifyPurpose.passwordReset);

      // The reset flow re-labels the action, since verifying is not the end
      // of it, and offers the number back rather than a way to skip.
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Change phone number'), findsOneWidget);

      await enterCode(tester, '123456');
      await tester.pumpAndSettle();

      // The verified number carries over, and home is not reached by
      // verifying alone.
      expect(find.text('reset +855 12 345 678'), findsOneWidget);
      expect(find.text('home stub'), findsNothing);
    });

    testWidgets('an unknown purpose verifies as sign-up', (tester) async {
      expect(VerifyPurpose.fromQueryValue(null), VerifyPurpose.signUp);
      expect(VerifyPurpose.fromQueryValue('nonsense'), VerifyPurpose.signUp);
      expect(
        VerifyPurpose.fromQueryValue('password-reset'),
        VerifyPurpose.passwordReset,
      );
    });
  });
}
