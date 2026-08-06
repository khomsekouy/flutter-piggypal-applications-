import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/reset_password_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('ResetPasswordPage', () {
    Future<void> pumpPage(
      WidgetTester tester, {
      String phoneNumber = '+855 12345678',
    }) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpApp(ResetPasswordPage(phoneNumber: phoneNumber));
    }

    bool submitEnabled(WidgetTester tester) {
      final button = tester.widget<GradientButton>(
        find.byType(GradientButton),
      );
      return button.onPressed != null;
    }

    testWidgets('names the account being reset', (tester) async {
      await pumpPage(tester);

      expect(
        find.textContaining('+855 12345678', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('falls back when no number was passed', (tester) async {
      await pumpPage(tester, phoneNumber: '');

      expect(
        find.textContaining('your account', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('submit is disabled until both passwords agree', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).at(0), 'supersecret');
      await tester.pump();
      expect(submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).at(1), 'supersecret');
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('rejects a too-short password', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(0), 'short');
      await tester.pump();

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('rejects a confirmation that does not match', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(0), 'supersecret');
      await tester.enterText(find.byType(TextField).at(1), 'different');
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('updating the password returns to sign in', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/reset-password',
        routes: [
          GoRoute(
            path: '/reset-password',
            name: AppRoutes.resetPassword,
            builder: (_, _) =>
                const ResetPasswordPage(phoneNumber: '+855 12345678'),
          ),
          GoRoute(
            path: '/sign-in',
            name: AppRoutes.signIn,
            builder: (_, _) => const Scaffold(body: Text('sign in stub')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.enterText(find.byType(TextField).at(0), 'supersecret');
      await tester.enterText(find.byType(TextField).at(1), 'supersecret');
      await tester.pump();
      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      expect(find.text('sign in stub'), findsOneWidget);
      // The confirmation outlives the route change, so the user knows the
      // reset took before they type their new password.
      expect(
        find.text('Password updated. Sign in with your new password.'),
        findsOneWidget,
      );
    });
  });
}
