import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/profile_photo_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/profile_photo_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../helpers/helpers.dart';

/// Smallest thing `Image.memory` will decode: a 1x1 transparent PNG.
final _pngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  group('ProfilePhotoPage', () {
    late FakeAuthApi api;
    late AuthenticationBloc auth;

    /// Records which source was asked for, and hands back a real PNG.
    ImageSource? lastSource;

    Future<XFile?> stubPicker(ImageSource source) async {
      lastSource = source;
      return XFile.fromData(
        _pngBytes,
        name: 'avatar.png',
        mimeType: 'image/png',
      );
    }

    // The account exists by the time this screen is reached — it is created on
    // the first screen of sign-up — so every test here starts signed in.
    // Awaited in `setUp` rather than in a test body: inside `testWidgets` the
    // binding runs its own clock, and a bloc's stream would never arrive.
    setUp(() async {
      lastSource = null;
      api = await setUpDependencies()
        ..userName = 'Dara Sok';
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

    Future<void> pumpPage(WidgetTester tester, {PickImage? pickImage}) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: AppRoutes.profilePhotoPath,
        routes: [
          GoRoute(
            path: AppRoutes.profilePhotoPath,
            name: AppRoutes.profilePhoto,
            builder: (_, _) => ProfilePhotoPage(pickImage: pickImage),
          ),
          GoRoute(
            path: AppRoutes.homePath,
            name: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('home stub')),
          ),
          GoRoute(
            path: AppRoutes.signInPath,
            name: AppRoutes.signIn,
            builder: (_, _) => const Scaffold(body: Text('sign-in stub')),
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
      await tester.pumpAndSettle();
    }

    /// Taps the CTA and waits for the upload to land.
    ///
    /// `pumpAndSettle` alone is not enough for either half of this: the
    /// multipart body is finalised on the real event loop, which only
    /// [WidgetTester.runAsync] runs, and while the request is in flight the
    /// button shows a spinner — an animation that never settles.
    Future<void> uploadAndSettle(WidgetTester tester) async {
      await tester.tap(find.byType(GradientButton));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pickFromGallery(WidgetTester tester) async {
      await tester.tap(find.text('Upload a photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers both continuing and skipping', (tester) async {
      await pumpPage(tester);

      expect(find.text('Add a Profile Photo'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      // The photo is optional, so the CTA is never gated on picking one.
      final button = tester.widget<GradientButton>(find.byType(GradientButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('is the last of the four sign-up steps', (tester) async {
      await pumpPage(tester);

      expect(find.text('Step 4 of 4'), findsOneWidget);
    });

    testWidgets('falls back to the initials on the account', (tester) async {
      await pumpPage(tester);

      expect(find.text('DS'), findsOneWidget);
    });

    testWidgets('picking from the gallery previews the photo', (tester) async {
      await pumpPage(tester, pickImage: stubPicker);

      expect(find.text('Upload a photo'), findsOneWidget);

      await pickFromGallery(tester);

      expect(lastSource, ImageSource.gallery);
      expect(find.byType(Image), findsOneWidget);
      // The empty-state initials give way to the picture.
      expect(find.text('DS'), findsNothing);
      expect(find.text('Change photo'), findsOneWidget);
    });

    testWidgets('the camera option asks the camera', (tester) async {
      await pumpPage(tester, pickImage: stubPicker);

      await tester.tap(find.text('Upload a photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(lastSource, ImageSource.camera);
    });

    testWidgets('a picked photo can be removed again', (tester) async {
      await pumpPage(tester, pickImage: stubPicker);
      await pickFromGallery(tester);

      await tester.tap(find.text('Change photo'));
      await tester.pumpAndSettle();
      expect(find.text('Remove photo'), findsOneWidget);
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(find.text('DS'), findsOneWidget);
    });

    testWidgets('the remove option is hidden until there is a photo', (
      tester,
    ) async {
      await pumpPage(tester, pickImage: stubPicker);

      await tester.tap(find.text('Upload a photo'));
      await tester.pumpAndSettle();

      expect(find.text('Remove photo'), findsNothing);
    });

    testWidgets('tapping the avatar opens the source sheet', (tester) async {
      await pumpPage(tester, pickImage: stubPicker);

      await tester.tap(find.byType(ProfilePhotoPicker));
      await tester.pumpAndSettle();

      expect(find.text('Take a photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
    });

    testWidgets('shows a person glyph when the account has no name', (
      tester,
    ) async {
      api.userName = null;
      // Awaited outside the widget clock: the refresh is a real request, and
      // the screen has to be built from its answer, not from the name the
      // sign-in cached.
      await tester.runAsync(() async {
        auth.add(const AuthenticationUserRefreshed());
        await auth.stream.firstWhere((state) => state.user?.name == null);
      });
      await pumpPage(tester);

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('a picked photo is uploaded as the multipart avatar part', (
      tester,
    ) async {
      await pumpPage(tester, pickImage: stubPicker);
      await pickFromGallery(tester);

      await uploadAndSettle(tester);

      final request = api.requestTo('/users/me', method: 'PATCH')!;
      // A file part and only a file part — this API refuses an `avatarUrl`.
      expect(request.fileParts, ['avatar']);
      expect(find.text('home stub'), findsOneWidget);
    });

    testWidgets('skipping finishes sign-up without an upload', (tester) async {
      await pumpPage(tester, pickImage: stubPicker);
      await pickFromGallery(tester);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('home stub'), findsOneWidget);
      expect(
        api.requests.where((r) => r.method == 'PATCH'),
        isEmpty,
      );
    });

    testWidgets('continuing without a photo sends nothing', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      expect(find.text('home stub'), findsOneWidget);
      expect(api.requests.where((r) => r.method == 'PATCH'), isEmpty);
    });

    testWidgets('an upload that fails still finishes sign-up', (tester) async {
      api.rejectAvatarUpload = true;
      await pumpPage(tester, pickImage: stubPicker);
      await pickFromGallery(tester);

      await uploadAndSettle(tester);

      // The account is already made and signed in; a picture that would not
      // upload is worth a message, not a sign-up held hostage.
      expect(find.text('home stub'), findsOneWidget);
    });

    testWidgets('with no session there is nothing to attach a photo to', (
      tester,
    ) async {
      final anonymous = sl<AuthenticationBloc>();
      addTearDown(anonymous.close);
      auth = anonymous;

      await pumpPage(tester);

      expect(find.text('sign-in stub'), findsOneWidget);
    });
  });

  group('initialsOf', () {
    test('takes the first and last word', () {
      expect(initialsOf('Dara Sok'), 'DS');
      expect(initialsOf('  sok   dara  chan '), 'SC');
    });

    test('handles a single word and an empty name', () {
      expect(initialsOf('Dara'), 'D');
      expect(initialsOf('   '), '');
    });
  });
}
