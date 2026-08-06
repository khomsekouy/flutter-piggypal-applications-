import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/forgot_password_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('ForgotPasswordPage', () {
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

    testWidgets('sending a code opens verification for the reset flow', (
      tester,
    ) async {
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

      // The number and the flow both travel to the code screen: without the
      // purpose it would verify the user straight into home.
      expect(
        find.text('verify phone=%2B855+12345678&purpose=password-reset'),
        findsOneWidget,
      );
    });
  });
}
