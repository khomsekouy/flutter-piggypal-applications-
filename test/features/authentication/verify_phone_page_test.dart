import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/verify_phone_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/helpers.dart';

void main() {
  group('VerifyPhonePage', () {
    late FakeAuthApi api;
    late AuthenticationBloc auth;

    /// A bloc that never signed in, for the deep-link case. Resolved from the
    /// locator like the real one — it is registered as a factory, so this is a
    /// second, independent instance.
    late AuthenticationBloc anonymous;

    // Signing in happens here rather than in a test body on purpose: inside
    // `testWidgets` the binding runs its own clock, and awaiting a bloc's
    // stream there waits on work that only a `pump` would let run.
    setUp(() async {
      api = await setUpDependencies()
        // A brand-new account: unverified, which is the only state this
        // screen is ever reached in.
        ..phoneVerified = false;
      anonymous = sl<AuthenticationBloc>();
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
      await anonymous.close();
      await tearDownDependencies();
    });

    Future<void> pumpPage(
      WidgetTester tester, {
      AuthenticationBloc? session,
    }) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/verify-phone',
        routes: [
          GoRoute(
            path: '/verify-phone',
            name: AppRoutes.verifyPhone,
            builder: (_, _) => const VerifyPhonePage(),
          ),
          GoRoute(
            path: '/verify-number',
            name: AppRoutes.verifyNumber,
            builder: (_, state) => Scaffold(
              body: Text(
                'code screen for ${state.uri.queryParameters['phone']}',
              ),
            ),
          ),
          GoRoute(
            path: '/profile-photo',
            name: AppRoutes.profilePhoto,
            builder: (_, _) => const Scaffold(body: Text('photo step')),
          ),
          GoRoute(
            path: '/sign-in',
            name: AppRoutes.signIn,
            builder: (_, _) => const Scaffold(body: Text('sign-in stub')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        BlocProvider.value(
          value: session ?? auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('is the second of the four sign-up steps', (tester) async {
      await pumpPage(tester);

      expect(find.text('Verify Phone Number'), findsOneWidget);
      expect(find.text('Step 2 of 4'), findsOneWidget);
    });

    testWidgets('shows the account number, grouped for reading', (
      tester,
    ) async {
      await pumpPage(tester);

      // The API stores E.164 (+85512345678); nobody reads that.
      expect(find.text('+855 12 345 678'), findsOneWidget);
    });

    testWidgets('sends a code and moves on to the boxes', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      expect(api.called('/auth/verify-phone/request'), isTrue);
      expect(find.text('code screen for +855 12 345 678'), findsOneWidget);
    });

    testWidgets('the send carries no number — the session names it', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      final request = api.requestTo('/auth/verify-phone/request')!;
      expect(request.isAuthenticated, isTrue);
      expect(request.fields, isEmpty);
    });

    testWidgets('a refused send stays put and says why', (tester) async {
      api.throttleCodeRequests = true;
      await pumpPage(tester);

      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      // Rate-limited by the server (3 sends per 15 minutes), so the user is
      // still here, with the reason.
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(
        find.textContaining('Too many attempts'),
        findsOneWidget,
      );
    });

    testWidgets('an already-verified number skips straight to the photo step', (
      tester,
    ) async {
      api.phoneVerified = true;
      await pumpPage(tester);

      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      expect(find.text('photo step'), findsOneWidget);
    });

    testWidgets('verifying later moves on to the photo step', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Verify later'));
      await tester.pumpAndSettle();

      expect(find.text('photo step'), findsOneWidget);
      expect(api.called('/auth/verify-phone/request'), isFalse);
    });

    testWidgets('with no session there is nothing to verify', (tester) async {
      // Never signed in — a deep link to /verify-phone, or a stale one.
      await pumpPage(tester, session: anonymous);

      expect(find.text('sign-in stub'), findsOneWidget);
    });
  });
}
