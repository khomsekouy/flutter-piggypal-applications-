import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/account/presentation/view/delete_account_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

/// Records what the screen asked the shell to do, so a test can tell "went
/// back" from "stayed put".
class _RecordingNav implements TFNav {
  int backs = 0;

  @override
  void back() => backs += 1;

  @override
  void push(String screen, [Map<String, Object?> params = const {}]) {}

  @override
  void reset() {}

  @override
  void tab(String name) {}
}

void main() {
  group('DeleteAccountPage', () {
    late FakeAuthApi api;
    late AuthenticationBloc auth;
    late _RecordingNav nav;

    setUp(() async {
      nav = _RecordingNav();
      api = await setUpDependencies();
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

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: MaterialApp(
            // The real shell supplies the Scaffold every pushed screen sits
            // in; TFScreen is only the scrolling body inside it.
            home: Scaffold(
              body: TFThemeScope(child: DeleteAccountPage(nav: nav)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Lets the request finish on the real event loop — the fake adapter runs
    /// there, and the spinner animates meanwhile, so `pumpAndSettle` alone
    /// would wait on a frame that never stops coming.
    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
    }

    /// Types [password] and taps through. The button is below the fold on the
    /// default surface.
    Future<void> submit(WidgetTester tester, String password) async {
      await tester.enterText(find.byType(TextField), password);
      await tester.pump();
      await tester.ensureVisible(find.text('Delete My Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete My Account'));
      await tester.pump();
      await settle(tester);
    }

    testWidgets('says what goes, and asks for the password to prove it', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('This closes your account'), findsOneWidget);
      expect(find.text('Confirm your password'), findsOneWidget);
      // No number of days is claimed: the grace period is server-side config,
      // so a figure named here would be a promise the app cannot check.
      expect(find.textContaining('30 days'), findsNothing);
    });

    testWidgets('will not submit without a password', (tester) async {
      await pumpPage(tester);
      await tester.ensureVisible(find.text('Delete My Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete My Account'));
      await tester.pumpAndSettle();

      expect(api.called('/auth/delete-account'), isFalse);
      expect(api.accountDeleted, isFalse);
    });

    testWidgets('deletes the account and ends the session', (tester) async {
      await pumpPage(tester);
      await submit(tester, 'supersecret');

      expect(api.accountDeleted, isTrue);
      // Nothing is navigated from here: the session watcher above this screen
      // takes the user to sign-in, which is where the date is read out.
      expect(nav.backs, 0);
      expect(auth.state.status, AuthenticationStatus.unauthenticated);
      expect(auth.state.notice, contains('October 2, 2026'));
    });

    testWidgets('a wrong password says so and keeps the user signed in', (
      tester,
    ) async {
      await pumpPage(tester);
      await submit(tester, 'not-it');

      expect(find.text('Password is incorrect'), findsOneWidget);
      expect(api.accountDeleted, isFalse);
      expect(auth.state.isAuthenticated, isTrue);
      // The form stays usable, rather than being stuck behind its own spinner.
      expect(find.text('Delete My Account'), findsOneWidget);
    });

    testWidgets('Keep My Account just goes back', (tester) async {
      await pumpPage(tester);
      await tester.ensureVisible(find.text('Keep My Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep My Account'));
      await tester.pumpAndSettle();

      expect(nav.backs, 1);
      expect(api.called('/auth/delete-account'), isFalse);
    });
  });
}
