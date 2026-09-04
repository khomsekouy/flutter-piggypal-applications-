import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/restore_account_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/sign_in_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('RestoreAccountPage', () {
    late FakeAuthApi api;
    late AuthenticationBloc auth;

    setUp(() async {
      api = await setUpDependencies();
      auth = sl<AuthenticationBloc>();
    });

    tearDown(() async {
      await auth.close();
      await tearDownDependencies();
    });

    /// Signs in and deletes, which is the only state this screen is for.
    ///
    /// Inside `runAsync` because it does real network work through the fake
    /// adapter: a `testWidgets` body runs in a fake-async zone where those
    /// futures never complete on their own.
    Future<void> deleteAccount(WidgetTester tester) async {
      await tester.runAsync(() async {
        auth.add(
          const AuthenticationSignInRequested(
            countryCode: '+855',
            phone: '12345678',
            password: 'supersecret',
          ),
        );
        await auth.stream.firstWhere((s) => s.isAuthenticated);
        auth.add(
          const AuthenticationDeleteAccountRequested(password: 'supersecret'),
        );
        await auth.stream.firstWhere((s) => s.notice != null);
      });
    }

    GoRouter buildRouter(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/sign-in',
          name: AppRoutes.signIn,
          builder: (_, _) => const SignInPage(),
        ),
        GoRoute(
          path: '/restore-account',
          name: AppRoutes.restoreAccount,
          builder: (_, _) => const RestoreAccountPage(),
        ),
        GoRoute(
          path: '/home',
          name: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('home stub')),
        ),
      ],
    );

    Future<void> pumpAt(WidgetTester tester, String location) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = buildRouter(location);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> fillAndSubmit(WidgetTester tester, String password) async {
      await tester.enterText(find.byType(TextField).at(0), '12345678');
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.pump();
      await tester.tap(find.byType(GradientButton));
      await tester.pump();
      // The request runs on the real event loop, and the button spins while it
      // does — `pumpAndSettle` alone would wait on a frame that keeps coming.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('recovers the account and signs straight in', (tester) async {
      await deleteAccount(tester);
      await pumpAt(tester, '/restore-account');

      await fillAndSubmit(tester, 'supersecret');

      expect(api.accountDeleted, isFalse);
      // Signed in, not merely undeleted — the endpoint answers with a session,
      // so there is no second trip through the login screen.
      expect(find.text('home stub'), findsOneWidget);
      expect(auth.state.isAuthenticated, isTrue);
    });

    testWidgets('a lapsed window stays put and says why', (tester) async {
      await deleteAccount(tester);
      api.recoveryWindowClosed = true;
      await pumpAt(tester, '/restore-account');

      await fillAndSubmit(tester, 'supersecret');

      expect(find.text('home stub'), findsNothing);
      expect(
        find.text('The recovery window for this account has passed'),
        findsOneWidget,
      );
    });

    testWidgets('sign-in reads out the recovery date it was sent with', (
      tester,
    ) async {
      await deleteAccount(tester);
      await pumpAt(tester, '/sign-in');

      // The emission carrying this happened while the More tab was still up,
      // so a listener alone would never have seen it.
      expect(
        find.textContaining('You can recover it until October 2, 2026'),
        findsOneWidget,
      );
      // And it is cleared once shown, so a rebuild cannot repeat it.
      expect(auth.state.notice, isNull);
    });

    testWidgets('sign-in offers the way back even after the notice is gone', (
      tester,
    ) async {
      await pumpAt(tester, '/sign-in');

      // The window lasts weeks; someone returning on day ten has long since
      // dismissed the snackbar, and cannot sign in to find this anywhere else.
      await tester.tap(find.text('Recover a deleted account'));
      await tester.pumpAndSettle();

      expect(find.text('Recover Your Account'), findsOneWidget);
    });
  });
}
