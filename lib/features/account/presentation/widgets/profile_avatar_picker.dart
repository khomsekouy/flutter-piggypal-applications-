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
class ProfileAvatarPicker extends StatefulWidget {
  const ProfileAvatarPicker({
    required this.name,
    this.hue = 262,
    this.size = 88,
    this.pickImage,
    this.cropImage,
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

  @override
  State<ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends State<ProfileAvatarPicker> {
  /// The picked image, drawn over whatever the account's stored URL is until
  /// (and after) the upload lands. Null means "show the stored picture".
  Uint8List? _preview;

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

    if (error == null) {
      _showMessage('Profile photo updated');
      return;
    }
    _showMessage(error);
    context.read<AuthenticationBloc>().add(
      const AuthenticationErrorDismissed(),
    );
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
                // Positioned(
                //   right: 0,
                //   bottom: 0,
                //   child: Container(
                //     width: badge,
                //     height: badge,
                //     alignment: Alignment.center,
                //     decoration: BoxDecoration(
                //       color: c.primary,
                //       shape: BoxShape.circle,
                //       // Cut out of the background rather than drawn on top of
                //       // it, so the badge reads as separate from the avatar.
                //       border: Border.all(color: c.bg, width: 2.5),
                //     ),
                //     child: Icon(
                //       Icons.photo_camera_rounded,
                //       size: badge * 0.5,
                //       color: c.primaryInk,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
