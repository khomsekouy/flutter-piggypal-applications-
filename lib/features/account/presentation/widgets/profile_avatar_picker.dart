import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/core/utils/profile_image_picker.dart';
import 'package:flutter_piggypal_app/features/account/data/profile_store.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The account avatar, tappable to change the picture.
///
/// Looks like the plain [TFAvatar] plus a camera badge — the badge is what
/// says the avatar is a button, since an avatar on its own reads as decoration
/// and nobody would think to tap it.
///
/// Picking is optimistic: the chosen image is drawn immediately and the upload
/// (`PATCH /users/me`) runs underneath with a spinner over the avatar, so the
/// screen answers the tap at once. A failed upload puts the old picture back
/// and says why. The uploaded URL arrives via the auth bloc → [ProfileStore],
/// which is where the rest of the account screens read it from.
///
/// Optimistic only until the answer comes back, though. Once the upload
/// returns a URL that URL is fetched, and it — not the local bytes — is what
/// stays on screen. Holding the picked image on afterwards drew the photo
/// whether or not the server had kept it, so an avatar the API had already
/// lost looked exactly like one that worked and only fell back to initials on
/// some later launch, with nothing said. A URL that will not load is now
/// reported while the user is still standing in front of it.
typedef VerifyImage = Future<bool> Function(String url);

class ProfileAvatarPicker extends StatefulWidget {
  const ProfileAvatarPicker({
    required this.name,
    this.hue = 262,
    this.size = 88,
    this.pickImage,
    this.cropImage,
    this.verifyImage,
    super.key,
  });

  /// Drives the initials fallback. The edit form passes the name being typed,
  /// so the avatar keeps up with the field.
  final String name;

  final double hue;
  final double size;

  /// Overrides the real gallery/camera picker. Tests pass a stub; production
  /// leaves it null and gets the platform `ImagePicker`.
  final PickImage? pickImage;

  /// Overrides the real cropper, for the same reason as [pickImage].
  final CropImage? cropImage;

  /// Overrides the check that the uploaded URL actually resolves to an image.
  /// Tests pass a stub — under `flutter_test` every HTTP request answers 400,
  /// so a real fetch could only ever fail — and production leaves it null.
  final VerifyImage? verifyImage;

  @override
  State<ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends State<ProfileAvatarPicker> {
  /// The picked image, drawn over whatever the account's stored URL is while
  /// the upload is in flight. Cleared once the server has answered, either way
  /// — see [_settleUpload]. Null means "show the stored picture".
  Uint8List? _preview;

  /// Counts the uploads this widget has started, so the check that follows one
  /// cannot clear a preview belonging to the next.
  int _uploads = 0;

  /// True between dispatching the upload and hearing back, so an unrelated
  /// emission — a background profile refresh, say — cannot be mistaken for
  /// this widget's request finishing.
  bool _isUploading = false;

  Future<void> _choosePhoto() async {
    if (_isUploading) return;
    final colors = context.tfc;

    // No "Remove photo": the API takes a picture but has no way to clear one,
    // so offering it would be a button that cannot work.
    final result = await selectProfileImage(
      context,
      pickImage: widget.pickImage,
      cropImage: widget.cropImage,
      background: colors.surface2,
      foreground: colors.text,
      accent: colors.primary,
    );
    if (!mounted) return;

    switch (result) {
      case ProfileImagePicked(:final bytes, :final fileName):
        setState(() {
          _preview = bytes;
          _isUploading = true;
          _uploads += 1;
        });
        context.read<AuthenticationBloc>().add(
          AuthenticationProfilePhotoUpdated(
            avatar: bytes,
            avatarFileName: fileName,
          ),
        );
      case ProfileImageRemoved():
        break;
      case ProfileImageCancelled(:final errorMessage):
        // Backing out is nothing to say; a refused picker explains itself.
        if (errorMessage != null) _showMessage(errorMessage);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onAuthStateChanged(BuildContext context, AuthenticationState state) {
    if (state.isBusy || !_isUploading) return;
    final error = state.errorMessage;

    setState(() {
      _isUploading = false;
      // The upload is the only thing that made this preview worth showing —
      // if it did not land, the account still has whatever it had before.
      if (error != null) _preview = null;
    });

    if (error != null) {
      _showMessage(error);
      context.read<AuthenticationBloc>().add(
        const AuthenticationErrorDismissed(),
      );
      return;
    }

    unawaited(_settleUpload(state.user?.avatarUrl));
  }

  /// Hands the avatar back to the URL the account now stores, and says so when
  /// that URL turns out to be worth nothing.
  ///
  /// A 200 from `PATCH /users/me` only means the row was written. The picture
  /// itself lives wherever the API put it, and that is a separate thing that
  /// can be missing — the file never written, the host's disk discarded on the
  /// next restart, the URL built against the wrong public base. Fetching it
  /// once is what tells those apart from a working upload, and warms the cache
  /// so the swap away from the preview does not flash.
  Future<void> _settleUpload(String? url) async {
    final upload = _uploads;
    final served = url != null && url.isNotEmpty && await _loads(url);

    // A newer pick owns the preview by now; this one has nothing left to say.
    if (!mounted || upload != _uploads) return;

    // Dropped whether or not it loaded: the avatar is supposed to show what
    // the account actually has, and a preview that outlives its upload is
    // exactly what hid this.
    setState(() => _preview = null);
    _showMessage(
      served
          ? 'Profile photo updated'
          : 'Photo uploaded, but the server did not serve it back.',
    );
  }

  Future<bool> _loads(String url) async {
    final verify = widget.verifyImage;
    if (verify != null) return verify(url);

    var failed = false;
    // `precacheImage` completes rather than throws on a broken image, and
    // reports to `FlutterError` unless handed somewhere else to put it — so
    // the outcome has to be read off `onError`, not off the future.
    await precacheImage(
      NetworkImage(url),
      context,
      onError: (_, _) => failed = true,
    );
    return !failed;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final badge = widget.size * 0.31;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: _onAuthStateChanged,
      child: Semantics(
        button: true,
        label: 'Change profile photo',
        child: GestureDetector(
          onTap: () => unawaited(_choosePhoto()),
          // The badge overhangs the avatar, so hit-test the whole box.
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            // Room for the half of the badge that sits outside the avatar.
            width: widget.size + badge / 2,
            height: widget.size + badge / 2,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: ValueListenableBuilder<Profile>(
                    valueListenable: ProfileStore.instance.profile,
                    builder: (context, profile, _) => TFAvatar(
                      name: widget.name.trim().isEmpty ? '?' : widget.name,
                      hue: widget.hue,
                      size: widget.size,
                      imageUrl: profile.avatarUrl,
                      imageBytes: _preview,
                    ),
                  ),
                ),
                if (_isUploading)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(widget.size * 0.32),
                      ),
                      child: SizedBox(
                        width: widget.size * 0.28,
                        height: widget.size * 0.28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: c.primary,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: badge,
                    height: badge,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      // Cut out of the background rather than drawn on top of
                      // it, so the badge reads as separate from the avatar.
                      border: Border.all(color: c.bg, width: 2.5),
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: badge * 0.5,
                      color: c.primaryInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
