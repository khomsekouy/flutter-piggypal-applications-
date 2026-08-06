import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/sign_in_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('SignInPage', () {
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpApp(const SignInPage());
    }

    bool submitEnabled(WidgetTester tester) {
      final button = tester.widget<GradientButton>(
        find.byType(GradientButton),
      );
      return button.onPressed != null;
    }

    testWidgets('submit is disabled until both fields are filled', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).at(0), '12345678');
      await tester.pump();
      expect(submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).at(1), 'supersecret');
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('signing in continues to home', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/sign-in',
        routes: [
          GoRoute(
            path: '/sign-in',
            name: AppRoutes.signIn,
            builder: (_, _) => const SignInPage(),
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
      await tester.enterText(find.byType(TextField).at(0), '12345678');
      await tester.enterText(find.byType(TextField).at(1), 'supersecret');
      await tester.pump();
      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      expect(find.text('home stub'), findsOneWidget);
    });
  });
}
