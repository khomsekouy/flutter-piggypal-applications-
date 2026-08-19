import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/auth_step_indicator.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/profile_photo_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Picks one image, or `null` when the user backs out of the picker.
/// Injectable so widget tests don't need the platform channel.
typedef PickImage = Future<XFile?> Function(ImageSource source);

/// Second and last step of sign-up: an **optional** profile photo.
///
/// Reached from [AppRoutes.createAccount] with the details already collected.
/// The photo is a nicety, so this screen can always be cleared — "Continue"
/// with a picture, "Skip for now" without one; both land on number
/// verification.
class ProfilePhotoPage extends StatefulWidget {
  const ProfilePhotoPage({
    required this.phoneNumber,
    super.key,
    this.fullName = '',
    this.pickImage,
  });

  /// The number from step one, already formatted with its dial code. Carried
  /// through so verification knows where to send the code.
  final String phoneNumber;

  /// The name from step one. Only used for the initials placeholder.
  final String fullName;

  /// Overrides the real gallery/camera picker. Tests pass a stub; production
  /// leaves it null and gets [ImagePicker].
  final PickImage? pickImage;

  @override
  State<ProfilePhotoPage> createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends State<ProfilePhotoPage> {
  /// The picked image, held as bytes so the preview works everywhere.
  Uint8List? _photo;
  bool _isSubmitting = false;

  /// Downscaled on the way in: this only ever renders as a small avatar, and
  /// a full-resolution camera shot would be megabytes to hold and upload.
  static Future<XFile?> _defaultPickImage(ImageSource source) =>
      ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

  Future<void> _pick(ImageSource source) async {
    final pick = widget.pickImage ?? _defaultPickImage;
    try {
      final file = await pick(source);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = bytes);
    } on PlatformException catch (_) {
      if (!mounted) return;
      // Most often a denied camera/photos permission, which only the user can
      // undo — so say what to do rather than silently doing nothing.
      _showMessage(
        source == ImageSource.camera
            ? 'Camera unavailable. Check the app permissions and try again.'
            : 'Photos unavailable. Check the app permissions and try again.',
      );
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

  void _openPhotoSourceSheet() {
    if (_isSubmitting) return;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _SheetAction(
                icon: Icons.photo_camera_outlined,
                label: 'Take a photo',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_pick(ImageSource.camera));
                },
              ),
              _SheetAction(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_pick(ImageSource.gallery));
                },
              ),
              if (_photo != null)
                _SheetAction(
                  icon: Icons.delete_outline,
                  label: 'Remove photo',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    setState(() => _photo = null);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Drops a photo picked before the user changed their mind, then finishes.
  Future<void> _skip() async {
    if (_isSubmitting) return;
    setState(() => _photo = null);
    await _finish();
  }

  /// Finishes sign-up with whatever photo is in hand and moves on to
  /// verification.
  Future<void> _finish() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    // TODO(auth): replace with the real sign-up call — the details from step
    // one plus `_photo` when it is non-null; today this only simulates the
    // round trip.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    unawaited(
      context.pushNamed(
        AppRoutes.verifyNumber,
        queryParameters: {'phone': widget.phoneNumber},
      ),
    );
  }

  /// Back to step one, or to sign-in when this page was opened as a deep link
  /// with nothing to pop.
  void _back() {
    if (_isSubmitting) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    initials: initialsOf(widget.fullName),
                    onTap: _openPhotoSourceSheet,
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
                const AuthStepIndicator(step: 2, totalSteps: 2),
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: _isSubmitting ? null : _openPhotoSourceSheet,
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
                  isLoading: _isSubmitting,
                  onPressed: _finish,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: _isSubmitting ? null : _skip,
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

/// One row of the pick-a-source bottom sheet.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
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
