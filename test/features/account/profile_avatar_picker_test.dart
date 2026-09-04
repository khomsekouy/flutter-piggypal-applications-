import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/core/utils/profile_image_picker.dart';
import 'package:flutter_piggypal_app/features/account/data/profile_store.dart';
import 'package:flutter_piggypal_app/features/account/presentation/widgets/profile_avatar_picker.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
  group('ProfileAvatarPicker', () {
    late FakeAuthApi api;
    late AuthenticationBloc auth;
    late CropImage crop;
    ImageSource? lastSource;

    /// Whether the URL the upload answers with actually loads. Stubbed because
    /// `flutter_test` answers every HTTP request with a 400, so a real fetch
    /// could only ever fail — and the point of these tests is to tell a URL
    /// that serves an image from one that does not.
    late bool imageServed;
    final verified = <String>[];

    Future<bool> stubVerify(String url) async {
      verified.add(url);
      return imageServed;
    }

    Future<XFile?> stubPicker(ImageSource source) async {
      lastSource = source;
      return XFile.fromData(_pngBytes, path: 'avatar.png');
    }

    setUp(() async {
      lastSource = null;
      imageServed = true;
      verified.clear();
      crop = stubCropper(_pngBytes, extension: '.png');
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
      // The store is a global singleton, so a picture left on it would be the
      // starting state of whatever test runs next.
      ProfileStore.instance.current = ProfileStore.instance.current.copyWith(
        clearAvatarUrl: true,
      );
    });

    Future<void> pumpPicker(WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          // Stands in for `_SessionWatcher`, which sits above this widget in
          // the real tree and is what copies the account's avatar URL onto the
          // store the picker renders from.
          child: BlocListener<AuthenticationBloc, AuthenticationState>(
            listener: (_, state) => ProfileStore.instance.current = ProfileStore
                .instance
                .current
                .copyWith(
                  avatarUrl: state.user?.avatarUrl,
                  clearAvatarUrl: state.user?.avatarUrl == null,
                ),
            child: MaterialApp(
              home: Scaffold(
                body: TFThemeScope(
                  child: Center(
                    child: ProfileAvatarPicker(
                      name: 'Dara Sok',
                      pickImage: stubPicker,
                      cropImage: crop,
                      verifyImage: stubVerify,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Taps the avatar and chooses [option] from the source sheet.
    Future<void> pick(WidgetTester tester, String option) async {
      await tester.tap(find.byType(ProfileAvatarPicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option));
      await tester.pump();
    }

    /// Lets the multipart upload finish on the real event loop — the fake
    /// adapter still reads the request body off it.
    Future<void> settleUpload(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the avatar is a button onto the source sheet', (tester) async {
      await pumpPicker(tester);
      expect(find.text('DS'), findsOneWidget);

      await tester.tap(find.byType(ProfileAvatarPicker));
      await tester.pumpAndSettle();

      expect(find.text('Take a photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
      // The API can set a picture but not clear one, so this is not offered.
      expect(find.text('Remove photo'), findsNothing);
    });

    testWidgets('a picked photo shows before the upload finishes', (
      tester,
    ) async {
      await pumpPicker(tester);
      await pick(tester, 'Choose from gallery');

      expect(lastSource, ImageSource.gallery);
      // Drawn from memory, and a spinner over it while the PATCH is in
      // flight — the tap is answered without waiting for the network.
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await settleUpload(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Profile photo updated'), findsOneWidget);
    });

    testWidgets('the photo is uploaded and lands on the profile', (
      tester,
    ) async {
      await pumpPicker(tester);
      await pick(tester, 'Take a photo');
      expect(lastSource, ImageSource.camera);
      await settleUpload(tester);

      expect(api.requestTo('/users/me', method: 'PATCH'), isNotNull);
      // The upload answers with the stored URL, which the app copies onto
      // ProfileStore (in `_SessionWatcher`, above this widget) for every
      // other account screen to render.
      expect(auth.state.user?.avatarUrl, api.avatarUrl);
    });

    testWidgets('an upload that fails puts the old avatar back', (
      tester,
    ) async {
      api.rejectAvatarUpload = true;
      await pumpPicker(tester);
      await pick(tester, 'Choose from gallery');
      await settleUpload(tester);

      expect(find.byType(Image), findsNothing);
      expect(find.text('DS'), findsOneWidget);
      expect(find.text('Avatar could not be stored'), findsOneWidget);
    });

    Finder memoryImage() => find.byWidgetPredicate(
      (w) => w is Image && w.image is MemoryImage,
      description: 'Image.memory',
    );

    Finder networkImage() => find.byWidgetPredicate(
      (w) => w is Image && w.image is NetworkImage,
      description: 'Image.network',
    );

    testWidgets('the stored URL takes over from the preview once it loads', (
      tester,
    ) async {
      await pumpPicker(tester);
      await pick(tester, 'Choose from gallery');
      expect(memoryImage(), findsOneWidget);

      await settleUpload(tester);

      // What the account really has, not what was picked. Holding the picked
      // bytes on is what made a lost upload indistinguishable from a good one.
      expect(verified, [api.avatarUrl]);
      expect(memoryImage(), findsNothing);
      expect(networkImage(), findsOneWidget);
      expect(find.text('Profile photo updated'), findsOneWidget);
    });

    testWidgets('a photo the server will not serve back says so', (
      tester,
    ) async {
      imageServed = false;
      await pumpPicker(tester);
      await pick(tester, 'Choose from gallery');
      await settleUpload(tester);

      // The PATCH succeeded and the row holds a URL, so nothing in the
      // response says anything is wrong — only fetching it back does.
      expect(api.requestTo('/users/me', method: 'PATCH'), isNotNull);
      expect(auth.state.user?.avatarUrl, isNotNull);
      expect(
        find.text('Photo uploaded, but the server did not serve it back.'),
        findsOneWidget,
      );
      // And the picture goes with the message: an avatar that keeps drawing
      // bytes the account cannot serve is the bug, not the consolation.
      expect(memoryImage(), findsNothing);
    });

    testWidgets('backing out of the cropper changes nothing', (tester) async {
      crop = cancelledCropper;
      await pumpPicker(tester);
      await pick(tester, 'Choose from gallery');
      await settleUpload(tester);

      // The picture was chosen but never framed, so it was never confirmed —
      // the initials stay and nothing is uploaded.
      expect(find.byType(Image), findsNothing);
      expect(find.text('DS'), findsOneWidget);
      expect(api.requestTo('/users/me', method: 'PATCH'), isNull);
    });

    testWidgets('backing out of the picker changes nothing', (tester) async {
      await pumpPicker(tester);

      await tester.tap(find.byType(ProfileAvatarPicker));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20)); // the scrim
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(api.requestTo('/users/me', method: 'PATCH'), isNull);
    });
  });
}
