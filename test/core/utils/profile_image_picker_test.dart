import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/utils/profile_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../helpers/helpers.dart';

final _bytes = Uint8List.fromList([1, 2, 3, 4]);
final _croppedBytes = Uint8List.fromList([5, 6, 7, 8]);

void main() {
  group('pickProfileImageFrom', () {
    test('returns the cropped image as bytes and a name', () async {
      final result = await pickProfileImageFrom(
        ImageSource.gallery,
        // `path` too: off the web, `XFile.name` reads the basename of the
        // path, and the `name` argument alone leaves it empty.
        pickImage: (_) async => XFile.fromData(
          _bytes,
          name: 'avatar.png',
          path: 'avatar.png',
          mimeType: 'image/png',
        ),
        cropImage: stubCropper(_croppedBytes),
      );

      expect(result, isA<ProfileImagePicked>());
      result as ProfileImagePicked;
      // What comes back is the cropper's output, not the raw pick.
      expect(result.bytes, _croppedBytes);
      // The picked file's stem, re-suffixed to what cropping re-encoded to.
      expect(result.fileName, 'avatar.jpg');
    });

    test('the cropper is handed the picked file', () async {
      String? cropped;

      await pickProfileImageFrom(
        ImageSource.gallery,
        pickImage: (_) async =>
            XFile.fromData(_bytes, path: 'some/where/avatar.png'),
        cropImage: (sourcePath) async {
          cropped = sourcePath;
          return null;
        },
      );

      expect(cropped, 'some/where/avatar.png');
    });

    test('backing out of the cropper cancels the whole choice', () async {
      final result = await pickProfileImageFrom(
        ImageSource.gallery,
        pickImage: (_) async => XFile.fromData(_bytes, path: 'avatar.png'),
        cropImage: cancelledCropper,
      );

      expect(result, isA<ProfileImageCancelled>());
      expect((result as ProfileImageCancelled).errorMessage, isNull);
    });

    test('a cropper that will not open keeps the picked image', () async {
      final result = await pickProfileImageFrom(
        ImageSource.gallery,
        pickImage: (_) async => XFile.fromData(_bytes, path: 'avatar.png'),
        cropImage: (_) async => throw PlatformException(code: 'no_activity'),
      );

      expect(result, isA<ProfileImagePicked>());
      result as ProfileImagePicked;
      expect(result.bytes, _bytes);
      expect(result.fileName, 'avatar.png');
    });

    test('a cropper the build has no native half for keeps the pick', () async {
      // `MissingPluginException` is not a `PlatformException`, so it takes its
      // own catch arm — the one that used to let this crash the flow.
      final result = await pickProfileImageFrom(
        ImageSource.gallery,
        pickImage: (_) async => XFile.fromData(_bytes, path: 'avatar.png'),
        cropImage: (_) async => throw MissingPluginException(
          'No implementation found for method cropImage',
        ),
      );

      expect(result, isA<ProfileImagePicked>());
      expect((result as ProfileImagePicked).bytes, _bytes);
    });

    test('backing out of the picker cancels without an error', () async {
      final result = await pickProfileImageFrom(
        ImageSource.camera,
        pickImage: (_) async => null,
        cropImage: stubCropper(_croppedBytes),
      );

      expect(result, isA<ProfileImageCancelled>());
      expect((result as ProfileImageCancelled).errorMessage, isNull);
    });

    test('a refused picker cancels with a message naming the source', () async {
      Future<ProfileImageResult> refuse(ImageSource source) =>
          pickProfileImageFrom(
            source,
            pickImage: (_) async =>
                throw PlatformException(code: 'camera_access_denied'),
            cropImage: stubCropper(_croppedBytes),
          );

      final camera = await refuse(ImageSource.camera) as ProfileImageCancelled;
      final photos = await refuse(ImageSource.gallery) as ProfileImageCancelled;

      expect(camera.errorMessage, contains('Camera'));
      expect(photos.errorMessage, contains('Photos'));
    });
  });

  group('selectProfileImage', () {
    /// Pumps a button that runs the flow and records what it answered.
    Future<ProfileImageResult?> Function() pumpSheet(
      WidgetTester tester, {
      bool allowRemove = false,
      PickImage? pickImage,
      CropImage? cropImage,
    }) {
      ProfileImageResult? result;
      var done = false;

      return () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await selectProfileImage(
                      context,
                      allowRemove: allowRemove,
                      pickImage: pickImage,
                      cropImage: cropImage,
                    );
                    done = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        return done ? result : null;
      };
    }

    testWidgets('offers the camera and the gallery', (tester) async {
      await pumpSheet(tester)();

      expect(find.text('Take a photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
      expect(find.text('Remove photo'), findsNothing);
    });

    testWidgets('gallery asks the gallery, camera asks the camera', (
      tester,
    ) async {
      ImageSource? asked;
      Future<XFile?> record(ImageSource source) async {
        asked = source;
        return XFile.fromData(_bytes, path: 'a.png', mimeType: 'image/png');
      }

      final open = pumpSheet(
        tester,
        pickImage: record,
        cropImage: stubCropper(_croppedBytes),
      );

      await open();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(asked, ImageSource.gallery);

      await open();
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();
      expect(asked, ImageSource.camera);
    });

    testWidgets('removing is offered only when asked for', (tester) async {
      final open = pumpSheet(tester, allowRemove: true);
      await open();

      expect(find.text('Remove photo'), findsOneWidget);
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();

      expect(await open(), isA<ProfileImageRemoved>());
    });

    testWidgets('dismissing the sheet picks nothing', (tester) async {
      final open = pumpSheet(tester);
      await open();

      // Tap the scrim above the sheet.
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();

      expect(await open(), isA<ProfileImageCancelled>());
    });
  });
}
