import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// Picks one image, or `null` when the user backs out of the picker.
/// Injectable so widget tests don't need the platform channel.
typedef PickImage = Future<XFile?> Function(ImageSource source);

/// Crops the image at [sourcePath], or `null` when the user backs out of the
/// cropper. Injectable for the same reason as [PickImage] — the real one is a
/// native activity/view controller no widget test can drive.
typedef CropImage = Future<CroppedFile?> Function(String sourcePath);

/// Outcome of [selectProfileImage] / [pickProfileImageFrom].
///
/// Sealed so callers must handle every case — "cancelled" and "removed" are
/// genuinely different answers (leave the avatar alone vs. clear it), and a
/// nullable return would collapse them into the same null.
sealed class ProfileImageResult {
  const ProfileImageResult();
}

/// The user chose a picture. [bytes] are the (downscaled) image itself, held
/// in memory rather than as a `File` so the same value renders on every
/// platform and uploads as a multipart part without touching the file system.
final class ProfileImagePicked extends ProfileImageResult {
  const ProfileImagePicked({required this.bytes, required this.fileName});

  final Uint8List bytes;

  /// The picked file's name, forwarded as the multipart part's filename so the
  /// server stores it with the right extension.
  final String fileName;
}

/// The user asked to clear the current picture. Only ever returned when
/// [selectProfileImage] was called with `allowRemove: true`.
final class ProfileImageRemoved extends ProfileImageResult {
  const ProfileImageRemoved();
}

/// Nothing was picked. [errorMessage] is null for a plain dismissal, and set
/// when the picker itself refused — most often a denied camera/photos
/// permission, which only the user can undo.
final class ProfileImageCancelled extends ProfileImageResult {
  const ProfileImageCancelled({this.errorMessage});

  final String? errorMessage;
}

/// Downscaled on the way in: a profile picture only ever renders as a small
/// avatar, and a full-resolution camera shot would be megabytes to hold and
/// upload. Deliberately generous compared to the crop that follows — the
/// cropper needs pixels to throw away.
Future<XFile?> _defaultPickImage(ImageSource source) => ImagePicker().pickImage(
  source: source,
  maxWidth: 2048,
  maxHeight: 2048,
);

/// The real cropper: a square, circle-masked crop, because that is exactly the
/// shape the avatar renders in. Locking the ratio means what the user frames
/// here is what they get, rather than a rectangle the avatar then centre-crops
/// behind their back.
///
/// Dressed in the palette the caller is on ([background] / [foreground] /
/// [accent]) so the native screen does not flash a stock white toolbar in the
/// middle of a dark flow.
Future<CroppedFile?> _defaultCropImage(
  String sourcePath, {
  required Color background,
  required Color foreground,
  required Color accent,
}) {
  return ImageCropper().cropImage(
    sourcePath: sourcePath,
    // The size the avatar is actually stored and served at. Cropping is also
    // where the image gets its final downscale, so the upload stays small.
    maxWidth: 1024,
    maxHeight: 1024,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop photo',
        toolbarColor: background,
        toolbarWidgetColor: foreground,
        backgroundColor: background,
        activeControlsWidgetColor: accent,
        // uCrop draws its own status bar icons, so it has to be told which
        // way the caller's palette runs.
        statusBarLight:
            ThemeData.estimateBrightnessForColor(background) ==
            Brightness.light,
        cropStyle: CropStyle.circle,
        lockAspectRatio: true,
        // The ratio is locked, so the bottom bar is only rotate and scale —
        // both worth keeping for a photo taken at arm's length.
        hideBottomControls: false,
        initAspectRatio: CropAspectRatioPreset.square,
      ),
      IOSUiSettings(
        title: 'Crop photo',
        cropStyle: CropStyle.circle,
        aspectRatioLockEnabled: true,
        // With the ratio locked these two would only offer a choice that
        // cannot be taken.
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
}

/// Says why the crop step was skipped, because the fallback that follows is
/// otherwise invisible: the photo uploads, just uncropped, which looks from
/// the outside exactly like a cropper that was never wired up. Debug only —
/// the user already has their picture and needs no explanation.
void _warnCropperSkipped(Object error) {
  if (!kDebugMode) return;
  debugPrint(
    'profile photo: the cropper did not open, uploading the picked image '
    'uncropped. $error',
  );
}

/// The name to upload the cropped image under: the picked file's stem with the
/// cropper's extension, since cropping re-encodes (to JPEG by default) and the
/// server stores the file by whatever extension it is handed.
String _croppedFileName(String pickedName, String croppedPath) {
  final stem = p.basenameWithoutExtension(pickedName);
  final extension = p.extension(croppedPath);
  return '${stem.isEmpty ? 'avatar' : stem}$extension';
}

/// Reads one image from [source] (the camera or the photo library), then hands
/// it to the cropper so the user frames their own avatar.
///
/// Never throws: a denied permission or an unavailable camera comes back as
/// [ProfileImageCancelled] carrying a message worth showing the user, and
/// backing out of the cropper cancels the same way backing out of the picker
/// does. Pass [pickImage] / [cropImage] to stub the platform channels in tests.
Future<ProfileImageResult> pickProfileImageFrom(
  ImageSource source, {
  PickImage? pickImage,
  CropImage? cropImage,
  Color? background,
  Color? foreground,
  Color? accent,
}) async {
  final XFile? file;
  try {
    file = await (pickImage ?? _defaultPickImage)(source);
  } on PlatformException catch (_) {
    return ProfileImageCancelled(
      errorMessage: source == ImageSource.camera
          ? 'Camera unavailable. Check the app permissions and try again.'
          : 'Photos unavailable. Check the app permissions and try again.',
    );
  }
  if (file == null) return const ProfileImageCancelled();

  final picked = file;
  Future<ProfileImageResult> uncropped() async => ProfileImagePicked(
    bytes: await picked.readAsBytes(),
    fileName: picked.name,
  );

  // On the web `XFile.path` is a blob URL and the cropper needs
  // `WebUiSettings` (and so a BuildContext) that this layer has no business
  // holding. The app ships on iOS and Android; the web build keeps the picked
  // image as-is rather than breaking.
  if (kIsWeb && cropImage == null) return uncropped();

  Future<CroppedFile?> defaultCrop(String path) => _defaultCropImage(
    path,
    background: background ?? AppColors.surface,
    foreground: foreground ?? AppColors.textPrimary,
    accent: accent ?? AppColors.primaryGreen,
  );

  final CroppedFile? cropped;
  try {
    cropped = await (cropImage ?? defaultCrop)(picked.path);
  } on PlatformException catch (error) {
    // The cropper is a nicety on top of a picture the user already chose —
    // if it will not open, upload what they picked rather than lose it.
    _warnCropperSkipped(error);
    return uncropped();
  } on MissingPluginException catch (error) {
    // The plugin's native half is not in this build — a hot restart after
    // adding it, or an iOS build whose pods predate it. Not a
    // [PlatformException], so it needs its own arm; same answer either way.
    _warnCropperSkipped(error);
    return uncropped();
  }
  // Backing out of the cropper is backing out of the whole choice: the picked
  // image was never confirmed, so there is nothing to keep.
  if (cropped == null) return const ProfileImageCancelled();

  return ProfileImagePicked(
    bytes: await cropped.readAsBytes(),
    fileName: _croppedFileName(picked.name, cropped.path),
  );
}

/// Asks the user where the profile picture should come from — camera or
/// gallery — then reads it.
///
/// This is the whole flow behind one call: it shows the source sheet, opens
/// the picker, sends the result through the cropper, and hands back bytes
/// ready to preview and upload. Set [allowRemove] when there is already a
/// picture to clear, which adds a third option and can return
/// [ProfileImageRemoved]. The sheet and the cropper dress themselves in the
/// auth palette by default; screens on another palette (the TF shell's, which
/// has a light mode) pass [background], [foreground] and [accent].
///
/// Dismissing the sheet, the picker or the cropper returns
/// [ProfileImageCancelled]; so does a failure, with a message attached.
/// Nothing is shown for you — the caller decides where an error goes (see
/// [showProfileImageError] for the default snack bar).
Future<ProfileImageResult> selectProfileImage(
  BuildContext context, {
  bool allowRemove = false,
  PickImage? pickImage,
  CropImage? cropImage,
  Color? background,
  Color? foreground,
  Color? accent,
}) async {
  final choice = await showModalBottomSheet<_PhotoSource>(
    context: context,
    backgroundColor: background ?? AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _PhotoSourceSheet(
      allowRemove: allowRemove,
      foreground: foreground ?? AppColors.textPrimary,
    ),
  );

  return switch (choice) {
    null => const ProfileImageCancelled(),
    _PhotoSource.remove => const ProfileImageRemoved(),
    _PhotoSource.camera || _PhotoSource.gallery => await pickProfileImageFrom(
      choice == _PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      pickImage: pickImage,
      cropImage: cropImage,
      background: background,
      foreground: foreground,
      accent: accent,
    ),
  };
}

/// Shows [result]'s failure message, if it has one. No-op for a plain
/// dismissal or a successful pick, so callers can hand it every result.
void showProfileImageError(BuildContext context, ProfileImageResult result) {
  final message = result is ProfileImageCancelled ? result.errorMessage : null;
  if (message == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
}

enum _PhotoSource { camera, gallery, remove }

/// The pick-a-source bottom sheet. Pops with the chosen [_PhotoSource], or
/// null when dismissed.
class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet({
    required this.allowRemove,
    required this.foreground,
  });

  final bool allowRemove;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _SheetAction(
            icon: Icons.photo_camera_outlined,
            label: 'Take a photo',
            color: foreground,
            onTap: () => Navigator.of(context).pop(_PhotoSource.camera),
          ),
          _SheetAction(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            color: foreground,
            onTap: () => Navigator.of(context).pop(_PhotoSource.gallery),
          ),
          if (allowRemove)
            _SheetAction(
              icon: Icons.delete_outline,
              label: 'Remove photo',
              color: AppColors.error,
              onTap: () => Navigator.of(context).pop(_PhotoSource.remove),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// One row of the pick-a-source bottom sheet.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
