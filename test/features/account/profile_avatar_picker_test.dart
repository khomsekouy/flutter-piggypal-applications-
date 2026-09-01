import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/core/utils/profile_image_picker.dart';
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

    Future<XFile?> stubPicker(ImageSource source) async {
      lastSource = source;
      return XFile.fromData(_pngBytes, path: 'avatar.png');
    }

    setUp(() async {
      lastSource = null;
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
    });

    Future<void> pumpPicker(WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: MaterialApp(
            home: Scaffold(
              body: TFThemeScope(
                child: Center(
                  child: ProfileAvatarPicker(
                    name: 'Dara Sok',
                    pickImage: stubPicker,
                    cropImage: crop,
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
