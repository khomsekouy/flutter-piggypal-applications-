import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/create_account_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('CreateAccountPage', () {
    late FakeAuthApi api;

    // This screen now creates the account, so it needs the real bloc and a
    // server to answer it.
    setUp(() async {
      api = await setUpDependencies()
        ..phoneVerified = false;
    });

    tearDown(tearDownDependencies);

    /// The form is taller than the default 800x600 test surface, which puts
    /// the terms checkbox and submit button out of hit-test range.
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpApp(const CreateAccountPage());
    }

    bool submitEnabled(WidgetTester tester) {
      final button = tester.widget<GradientButton>(
        find.byType(GradientButton),
      );
      return button.onPressed != null;
    }

    Future<void> fillValidForm(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).at(0), 'Dara Sok');
      await tester.enterText(find.byType(TextField).at(1), '12345678');
      await tester.enterText(find.byType(TextField).at(2), 'supersecret');
      await tester.enterText(find.byType(TextField).at(3), 'supersecret');
      await tester.pump();
    }

    testWidgets('renders a single confirm-password field', (tester) async {
      await pumpPage(tester);

      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('submit is disabled until the form is valid', (tester) async {
      await pumpPage(tester);

      expect(submitEnabled(tester), isFalse);

      await fillValidForm(tester);
      // Terms are unchecked, so the form is still incomplete.
      expect(submitEnabled(tester), isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('terms checkbox starts unchecked', (tester) async {
      await pumpPage(tester);

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('shows an error when the passwords differ', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(2), 'supersecret');
      await tester.enterText(find.byType(TextField).at(3), 'different');
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('shows an error for a too-short password', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(2), 'short');
      await tester.pump();

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
    });

    testWidgets('states the length rule when the number is too short', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(1), '12');
      await tester.pump();

      expect(find.text('Cambodian numbers are 8–9 digits.'), findsOneWidget);
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('caps the number at nine digits', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(1), '1234567890');
      await tester.pump();

      final phoneField = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );
      // Cambodia tops out at 9 digits, so the tenth never lands.
      expect(phoneField.controller?.text, '123456789');
      expect(
        find.text('Cambodian numbers are at most 9 digits.'),
        findsOneWidget,
      );
    });

    testWidgets('offers Cambodia only — the dial code is not a picker', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('+855'), findsOneWidget);

      await tester.tap(find.text('+855'));
      await tester.pumpAndSettle();

      // Nothing to open: no country list, no other dial codes.
      expect(find.text('United States'), findsNothing);
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('drops the trunk 0 and says why', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(1), '012345678');
      await tester.pump();

      final phoneField = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );
      expect(phoneField.controller?.text, '12345678');
      expect(
        find.text('Skip the leading 0 — +855 replaces it.'),
        findsOneWidget,
      );
      // The number is still valid once the zero is gone.
      expect(find.text('Cambodian numbers are 8–9 digits.'), findsNothing);
    });

    testWidgets('rejects letters in the phone field and says why', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(1), '12abc345');
      await tester.pump();

      final phoneField = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );
      expect(phoneField.controller?.text, '12345');
      expect(
        find.text('Numbers only — letters and symbols are ignored.'),
        findsOneWidget,
      );
    });

    testWidgets('clears the digits-only warning on the next valid edit', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(1), 'abc');
      await tester.pump();
      expect(
        find.text('Numbers only — letters and symbols are ignored.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).at(1), '12345678');
      await tester.pump();
      expect(
        find.text('Numbers only — letters and symbols are ignored.'),
        findsNothing,
      );
    });

    testWidgets('is the first of four steps and creates the account', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('registers the account, then moves on to verification', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: AppRoutes.createAccountPath,
        routes: [
          GoRoute(
            path: AppRoutes.createAccountPath,
            name: AppRoutes.createAccount,
            builder: (_, _) => const CreateAccountPage(),
          ),
          GoRoute(
            path: AppRoutes.verifyPhonePath,
            name: AppRoutes.verifyPhone,
            builder: (_, _) => const Scaffold(body: Text('verify step')),
          ),
          GoRoute(
            path: AppRoutes.profilePhotoPath,
            name: AppRoutes.profilePhoto,
            builder: (_, _) => const Scaffold(body: Text('photo step')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => sl<AuthenticationBloc>(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await fillValidForm(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      final request = api.requestTo('/auth/register')!;
      // The dialling code and the national number travel apart, which is how
      // `POST /auth/register` wants them.
      expect(request.fields['countryCode'], '+855');
      expect(request.fields['phone'], '12345678');
      expect(request.fields['name'], 'Dara Sok');
      // No picture yet: it is picked on the last screen, once there is an
      // account to attach it to.
      expect(request.fileParts, isEmpty);

      // The account exists now, so the number can finally be proved.
      expect(find.text('verify step'), findsOneWidget);
      expect(find.text('photo step'), findsNothing);
    });

    testWidgets('offers a route back to sign in', (tester) async {
      await pumpPage(tester);

      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
