import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

/// Tappable avatar used to pick the sign-up profile photo.
///
/// Holds the picked image as bytes rather than a `File` so the same widget
/// works on every platform (and in widget tests) without touching the file
/// system. Empty state falls back to the user's initials, or a person glyph
/// when the name is not known yet.
class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({
    required this.onTap,
    super.key,
    this.photo,
    this.initials = '',
    this.size = 160,
  });

  /// The picked image, or `null` while the user has not chosen one.
  final Uint8List? photo;

  /// Shown in the empty state — up to two letters taken from the full name.
  final String initials;

  final VoidCallback onTap;
  final double size;

  bool get _hasPhoto => photo != null;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.28;

    return Semantics(
      button: true,
      label: _hasPhoto ? 'Change profile photo' : 'Add profile photo',
      child: GestureDetector(
        onTap: onTap,
        // The badge overflows the glow circle, so hit-test the whole box.
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.glow(AppColors.primaryGreen),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: size * 0.75,
                  height: size * 0.75,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _hasPhoto
                          ? AppColors.primaryGreen
                          : AppColors.surfaceBorder,
                      width: _hasPhoto ? 2 : 1,
                    ),
                  ),
                  child: ClipOval(child: _buildContent()),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButtonGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 3),
                  ),
                  child: Icon(
                    _hasPhoto ? Icons.edit : Icons.add_a_photo_outlined,
                    color: Colors.white,
                    size: badgeSize * 0.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final image = photo;
    if (image != null) {
      return Image.memory(image, fit: BoxFit.cover);
    }
    if (initials.isEmpty) {
      return Icon(
        Icons.person_outline,
        color: AppColors.textSecondary,
        size: size * 0.3,
      );
    }
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontSize: size * 0.24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// First letters of the first and last word of [fullName], upper-cased.
/// Returns an empty string when there is nothing to initial.
String initialsOf(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+'))
    ..removeWhere((word) => word.isEmpty);
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first.characters.first.toUpperCase();
  return (words.first.characters.first + words.last.characters.first)
      .toUpperCase();
}
