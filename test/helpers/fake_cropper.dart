import 'dart:typed_data';

import 'package:flutter_piggypal_app/core/utils/profile_image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

/// A [CroppedFile] that answers from memory.
///
/// The real one reads its bytes off disk, and real file I/O never completes
/// under `testWidgets`' fake clock — so the stub keeps the path (the file name
/// is derived from it) and serves the bytes itself.
class FakeCroppedFile extends CroppedFile {
  FakeCroppedFile(super.path, this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> readAsBytes() async => bytes;
}

/// A stand-in for the native cropper, for tests that only care that the flow
/// runs through it.
///
/// Whatever went in comes back out — cropping a 1x1 PNG has nothing to trim,
/// and a test asserting on the pixels would be testing uCrop, not this app.
/// [extension] is what the cropper re-encoded to, which is where the uploaded
/// file name gets its suffix.
CropImage stubCropper(Uint8List bytes, {String extension = '.jpg'}) =>
    (_) async => FakeCroppedFile('/tmp/cropped$extension', bytes);

/// A cropper the user backs out of.
Future<CroppedFile?> cancelledCropper(String _) async => null;
