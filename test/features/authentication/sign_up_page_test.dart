import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/sign_up_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/otp_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('SignUpPage', () {
    late FakeAuthApi api;

    setUp(() async {
      api = await setUpDependencies()
        ..phoneVerified = false;
    });

    tearDown(tearDownDependencies);

    /// The flow is taller than the default 800x600 test surface, which puts
    /// the submit button out of hit-test range.
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpApp(const SignUpPage());
    }

    bool submitEnabled(WidgetTester tester) {
      final button = tester.widget<GradientButton>(find.byType(GradientButton));
      return button.onPressed != null;
    }

    /// Lets the API round trip resolve, then the pane transition finish.
    Future<void> settlePane(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> fillDetails(
      WidgetTester tester, {
      String name = 'Dara Sok',
      String phone = '12345678',
      String email = '',
    }) async {
      await tester.enterText(find.byType(TextField).at(0), name);
      await tester.enterText(find.byType(TextField).at(1), phone);
      await tester.enterText(find.byType(TextField).at(2), email);
      await tester.pump();
    }

    Future<void> enterCode(WidgetTester tester, String code) async {
      for (var i = 0; i < code.length; i++) {
        await tester.enterText(find.byType(TextField).at(i), code[i]);
        await tester.pump();
      }
    }

    /// Details → code → password, leaving the password pane on screen.
    Future<void> reachPasswordPane(WidgetTester tester) async {
      await fillDetails(tester);
      await tester.tap(find.byType(GradientButton));
      await settlePane(tester);
      await enterCode(tester, api.mockCode);
      await settlePane(tester);
    }

    testWidgets('opens on the details pane and asks for no password yet', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Email (optional)'), findsOneWidget);
      expect(find.text('+855'), findsOneWidget);
      // The password comes two panes later — that reordering is the point.
      expect(find.text('Confirm Password'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('the three panes are named in order', (tester) async {
      await pumpPage(tester);

      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('sending a code needs a name and a valid number', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(submitEnabled(tester), isFalse);

      await fillDetails(tester, phone: '12');
      expect(find.text('Cambodian numbers are 8–9 digits.'), findsOneWidget);
      expect(submitEnabled(tester), isFalse);

      await fillDetails(tester);
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('the email is optional but has to look like one', (
      tester,
    ) async {
      await pumpPage(tester);

      await fillDetails(tester, email: 'not-an-email');
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(submitEnabled(tester), isFalse);

      await fillDetails(tester, email: 'dara@example.com');
      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('drops the trunk 0 and says why', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField).at(1), '012345678');
      await tester.pump();

      final phoneField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(phoneField.controller?.text, '12345678');
      expect(
        find.text('Skip the leading 0 — +855 replaces it.'),
        findsOneWidget,
      );
    });

    testWidgets('the code pane shows the number and creates no account', (
      tester,
    ) async {
      await pumpPage(tester);
      await fillDetails(tester);
      await tester.tap(find.byType(GradientButton));
      await settlePane(tester);

      expect(find.text('Verify Your Number'), findsOneWidget);
      expect(find.textContaining('+855 12345678'), findsWidgets);
      // Six boxes, and nothing registered: the account does not exist until
      // the number is proved and a password is set.
      expect(find.byType(TextField), findsNWidgets(6));
      expect(api.requestTo('/auth/register'), isNull);
      expect(api.requestTo('/auth/register/request-otp'), isNotNull);

      // The dialling code and the national number travel apart, as every call
      // in this API wants them.
      final request = api.requestTo('/auth/register/request-otp')!;
      expect(request.fields['countryCode'], '+855');
      expect(request.fields['phone'], '12345678');
    });

    testWidgets('a number that already has an account never gets a code', (
      tester,
    ) async {
      api.registeredPhone = '+85512345678';
      await pumpPage(tester);
      await fillDetails(tester);
      await tester.tap(find.byType(GradientButton));
      await settlePane(tester);

      // Still on the details pane, with the server's own wording under the
      // field the user can act on — there is no code coming to wait for.
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Phone is already registered'), findsOneWidget);
      expect(submitEnabled(tester), isFalse);
      expect(api.called('/auth/register'), isFalse);
    });

    testWidgets('a wrong code is rejected and the pane stays put', (
      tester,
    ) async {
      await pumpPage(tester);
      await fillDetails(tester);
      await tester.tap(find.byType(GradientButton));
      await settlePane(tester);

      final wrong = api.mockCode == '000000' ? '111111' : '000000';
      await enterCode(tester, wrong);
      await settlePane(tester);

      // The server's wording, not the screen's: it answers a mistyped code, an
      // expired one and a spent one identically, and the app must not invent a
      // distinction it was refused.
      expect(
        find.text('Verification code is invalid or expired'),
        findsOneWidget,
      );
      expect(find.text('Set Your Password'), findsNothing);
    });

    testWidgets('the right code opens the password pane', (tester) async {
      await pumpPage(tester);
      await reachPasswordPane(tester);

      expect(find.text('Set Your Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.textContaining('verified'), findsOneWidget);
    });

    testWidgets('creating the account needs matching passwords and terms', (
      tester,
    ) async {
      await pumpPage(tester);
      await reachPasswordPane(tester);

      expect(submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).at(0), 'supersecret');
      await tester.enterText(find.byType(TextField).at(1), 'different');
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).at(1), 'supersecret');
      await tester.pump();
      // The terms are still unticked, so the form is still incomplete.
      expect(submitEnabled(tester), isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('rejects a too-short password', (tester) async {
      await pumpPage(tester);
      await reachPasswordPane(tester);

      await tester.enterText(find.byType(TextField).at(0), 'short');
      await tester.pump();

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
    });

    testWidgets('registers once, at the end, then moves on to the photo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: AppRoutes.signUpPath,
        routes: [
          GoRoute(
            path: AppRoutes.signUpPath,
            name: AppRoutes.signUp,
            builder: (_, _) => const SignUpPage(),
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

      await fillDetails(tester, email: 'dara@example.com');
      await tester.tap(find.byType(GradientButton));
      await settlePane(tester);
      await enterCode(tester, api.mockCode);
      await settlePane(tester);

      await tester.enterText(find.byType(TextField).at(0), 'supersecret');
      await tester.enterText(find.byType(TextField).at(1), 'supersecret');
      await tester.pump();
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
      expect(request.fields['email'], 'dara@example.com');
      // The proof from `register/verify-otp`, which is what makes the account
      // come into existence already verified.
      expect(request.fields['verificationToken'], api.verificationToken);
      // No picture yet: it is picked on the next screen, once there is an
      // account to attach it to.
      expect(request.fileParts, isEmpty);

      // The number was proved before the account existed, so verification is
      // not asked for again.
      expect(find.text('photo step'), findsOneWidget);
    });

    testWidgets('resending asks for another code and says so', (tester) async {
      await pumpPage(tester);
      await fillDetails(tester);
      await tester.tap(find.byType(GradientButton));
      await settlePane(tester);
      expect(api.registrationCodeRequests, 1);

      // The card only offers a resend once the cooldown has run out.
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Resend'));
      await settlePane(tester);

      expect(api.registrationCodeRequests, 2);
      // Still on the boxes, and told a new code is coming — a resend that
      // moved the user anywhere would lose the pane they are waiting on.
      expect(find.byType(OtpField), findsOneWidget);
      expect(
        find.textContaining('A new code is on its way'),
        findsOneWidget,
      );
    });

    testWidgets('a proof that expired sends the user back for a fresh code', (
      tester,
    ) async {
      await pumpPage(tester);
      await reachPasswordPane(tester);
      // Ten minutes is all the proof gets, and choosing a password can take
      // longer.
      api.rejectVerificationToken = true;

      await tester.enterText(find.byType(TextField).at(0), 'supersecret');
      await tester.enterText(find.byType(TextField).at(1), 'supersecret');
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.byType(GradientButton));
      await settlePane(tester);

      // No account, and back on the number: nothing on the password pane
      // could have fixed this, and the way on is another code.
      expect(find.text('Full name'), findsOneWidget);
      expect(
        find.text('Phone verification is invalid or expired'),
        findsOneWidget,
      );
      // The proof is gone with it, so the button asks for a code rather than
      // offering to carry on with one the server has already refused.
      expect(find.text('Send Code'), findsOneWidget);
    });

    testWidgets('offers a route back to sign in', (tester) async {
      await pumpPage(tester);

      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
