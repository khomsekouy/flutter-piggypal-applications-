import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/verify_number_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('VerifyNumberPage', () {
    Future<void> pumpPage(
      WidgetTester tester, {
      String phoneNumber = '+855 12345678',
    }) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpApp(VerifyNumberPage(phoneNumber: phoneNumber));
    }

    /// Tears the tree down so the resend countdown's periodic timer is
    /// cancelled before the framework checks for pending timers.
    Future<void> disposeTree(WidgetTester tester) =>
        tester.pumpWidget(const SizedBox());

    bool verifyEnabled(WidgetTester tester) {
      final button = tester.widget<GradientButton>(
        find.byType(GradientButton),
      );
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

      expect(
        find.textContaining('+855 12345678', findRichText: true),
        findsOneWidget,
      );
      await disposeTree(tester);
    });

    testWidgets('falls back when no number was passed', (tester) async {
      await pumpPage(tester, phoneNumber: '');

      expect(
        find.textContaining('your number', findRichText: true),
        findsOneWidget,
      );
      await disposeTree(tester);
    });

    testWidgets('renders six code boxes', (tester) async {
      await pumpPage(tester);

      expect(find.byType(TextField), findsNWidgets(6));
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

      expect(find.text('Resend code in 60s'), findsOneWidget);
      expect(find.text('Resend Code'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend code in 59s'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('offers a resend once the countdown expires', (tester) async {
      await pumpPage(tester);

      await tester.pump(const Duration(seconds: 60));

      expect(find.text('Resend Code'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsNothing);

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

    testWidgets('a complete code verifies and continues to home', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/verify',
        routes: [
          GoRoute(
            path: '/verify',
            name: AppRoutes.verifyNumber,
            builder: (_, _) =>
                const VerifyNumberPage(phoneNumber: '+855 12345678'),
          ),
          GoRoute(
            path: '/home',
            name: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('home stub')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await enterCode(tester, '123456');
      await tester.pumpAndSettle();

      expect(find.text('home stub'), findsOneWidget);
    });

    testWidgets('a reset code continues to the new-password screen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/verify',
        routes: [
          GoRoute(
            path: '/verify',
            name: AppRoutes.verifyNumber,
            builder: (_, _) => const VerifyNumberPage(
              phoneNumber: '+855 12345678',
              purpose: VerifyPurpose.passwordReset,
            ),
          ),
          GoRoute(
            path: '/reset-password',
            name: AppRoutes.resetPassword,
            builder: (_, state) => Scaffold(
              body: Text('reset ${state.uri.queryParameters['phone']}'),
            ),
          ),
          GoRoute(
            path: '/home',
            name: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('home stub')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      // The reset flow re-labels the action, since verifying is not the end
      // of it.
      expect(find.text('Continue'), findsOneWidget);

      await enterCode(tester, '123456');
      await tester.pumpAndSettle();

      // The verified number carries over, and home is not reached by
      // verifying alone.
      expect(find.text('reset +855 12345678'), findsOneWidget);
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
