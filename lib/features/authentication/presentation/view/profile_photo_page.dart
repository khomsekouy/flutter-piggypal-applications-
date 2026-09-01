import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/core/utils/profile_image_picker.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_step_indicator.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/profile_photo_picker.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/requires_session.dart';
import 'package:go_router/go_router.dart';

// The page owns the seam its tests inject, so it re-exports the typedef.
export 'package:flutter_piggypal_app/core/utils/profile_image_picker.dart'
    show CropImage, PickImage;

/// Last step of sign-up: an **optional** profile photo.
///
/// The account already exists by the time anyone gets here — it is created on
/// the first screen, because the number cannot be verified without a session
/// to send the code to. So the picture is its own request,
/// `PATCH /users/me` with a multipart `avatar` part, rather than something
/// that rides along with registration.
///
/// Which also means nothing here can fail the sign-up. "Continue" uploads the
/// picture and goes home; "Skip" just goes home; an upload that fails says so
/// and leaves the account exactly as it was, with a photo the user can add
/// later from their profile.
class ProfilePhotoPage extends StatefulWidget {
  const ProfilePhotoPage({
    super.key,
    this.pickImage,
    this.cropImage,
  });

  /// Overrides the real gallery/camera picker. Tests pass a stub; production
  /// leaves it null and gets the platform `ImagePicker`.
  final PickImage? pickImage;

  /// Overrides the real cropper, for the same reason as [pickImage].
  final CropImage? cropImage;

  @override
  State<ProfilePhotoPage> createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends State<ProfilePhotoPage> {
  /// The picked image, held as bytes so the preview works everywhere.
  Uint8List? _photo;

  /// The picked file's name, forwarded as the multipart part's filename so the
  /// server stores it with the right extension.
  String? _photoName;

  /// Asks where the picture should come from — camera or gallery — and keeps
  /// whatever comes back. Removing is offered only once there is a photo to
  /// remove; nothing is uploaded until "Continue".
  Future<void> _choosePhoto() async {
    if (context.read<AuthenticationBloc>().state.isBusy) return;
    final result = await selectProfileImage(
      context,
      allowRemove: _photo != null,
      pickImage: widget.pickImage,
      cropImage: widget.cropImage,
    );
    if (!mounted) return;
    switch (result) {
      case ProfileImagePicked(:final bytes, :final fileName):
        setState(() {
          _photo = bytes;
          _photoName = fileName;
        });
      case ProfileImageRemoved():
        setState(() {
          _photo = null;
          _photoName = null;
        });
      case ProfileImageCancelled():
        // Dismissed is nothing to say; a refused picker explains itself.
        showProfileImageError(context, result);
    }
  }

  void _showMessage(String message) {
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

  /// Nothing to upload — straight in, photo or not.
  void _skip() {
    if (context.read<AuthenticationBloc>().state.isBusy) return;
    context.goNamed(AppRoutes.home);
  }

  /// Uploads whatever photo is in hand, then goes home. With no photo picked
  /// there is nothing to send, so this is [_skip].
  void _finish() {
    final bloc = context.read<AuthenticationBloc>();
    if (bloc.state.isBusy) return;

    final photo = _photo;
    if (photo == null) {
      _skip();
      return;
    }
    _isUploading = true;
    bloc.add(
      AuthenticationProfilePhotoUpdated(
        avatar: photo,
        avatarFileName: _photoName,
      ),
    );
  }

  /// True between dispatching the upload and hearing back, so an unrelated
  /// emission — a background profile refresh, say — cannot be mistaken for
  /// this screen's request finishing.
  bool _isUploading = false;

  void _onAuthStateChanged(BuildContext context, AuthenticationState state) {
    final message = state.errorMessage;
    if (message != null) {
      _showMessage(message);
      context.read<AuthenticationBloc>().add(
        const AuthenticationErrorDismissed(),
      );
    }

    if (state.isBusy || !_isUploading) return;
    _isUploading = false;

    // Home either way. A picture that would not upload is worth saying so
    // (the message above did), not worth holding a finished sign-up hostage —
    // it can be added later from the profile screen.
    context.goNamed(AppRoutes.home);
  }

  /// There is nothing behind this screen worth going back to — the account is
  /// made and the number is settled — so back means the same as skip.
  void _back() {
    if (context.read<AuthenticationBloc>().state.isBusy) return;
    _skip();
  }

  @override
  Widget build(BuildContext context) {
    return RequiresSession(
      builder: (context, user) =>
          BlocConsumer<AuthenticationBloc, AuthenticationState>(
            listener: _onAuthStateChanged,
            builder: (context, state) =>
                // The name itself, not `displayName`: an account with no name
                // should fall back to the person glyph, and `displayName`
                // would hand over a phone number to make initials out of.
                _buildPage(context, user.name ?? '', state.isBusy),
          ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    String accountName,
    bool isSubmitting,
  ) {
    final hasPhoto = _photo != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(onBack: _back),
                const SizedBox(height: 20),
                Center(
                  child: ProfilePhotoPicker(
                    photo: _photo,
                    initials: initialsOf(accountName),
                    onTap: () => unawaited(_choosePhoto()),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add a Profile Photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Optional — put a face to your savings.\nYou can add or '
                  'change it later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const AuthStepIndicator(step: 4, totalSteps: 4),
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () => unawaited(_choosePhoto()),
                    icon: Icon(
                      hasPhoto ? Icons.swap_horiz : Icons.add_a_photo_outlined,
                      size: 18,
                      color: AppColors.primaryGreen,
                    ),
                    label: Text(
                      hasPhoto ? 'Change photo' : 'Upload a photo',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: hasPhoto ? 'Continue' : 'Continue without a photo',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: isSubmitting,
                  onPressed: isSubmitting ? null : _finish,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: isSubmitting ? null : _skip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
