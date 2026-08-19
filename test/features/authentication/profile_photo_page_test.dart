import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/view/profile_photo_page.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/profile_photo_picker.dart';
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
  group('ProfilePhotoPage', () {
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

    setUp(() => lastSource = null);

    Future<void> pumpPage(
      WidgetTester tester, {
      PickImage? pickImage,
      String name = 'Dara Sok',
    }) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpApp(
        ProfilePhotoPage(
          phoneNumber: '+855 12345678',
          fullName: name,
          pickImage: pickImage,
        ),
      );
    }

    testWidgets('offers both continuing and skipping', (tester) async {
      await pumpPage(tester);

      expect(find.text('Add a Profile Photo'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      // The photo is optional, so the CTA is never gated on picking one.
      final button = tester.widget<GradientButton>(find.byType(GradientButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows the step 2 marker', (tester) async {
      await pumpPage(tester);

      expect(find.text('Step 2 of 2'), findsOneWidget);
    });

    testWidgets('falls back to the initials from step one', (tester) async {
      await pumpPage(tester);

      expect(find.text('DS'), findsOneWidget);
    });

    testWidgets('picking from the gallery previews the photo', (tester) async {
      await pumpPage(tester, pickImage: stubPicker);

      expect(find.text('Upload a photo'), findsOneWidget);

      await tester.tap(find.text('Upload a photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('Upload a photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

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

    testWidgets('shows a person glyph when the name is unknown', (
      tester,
    ) async {
      await pumpPage(tester, name: '');

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
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
