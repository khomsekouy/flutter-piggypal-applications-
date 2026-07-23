import 'package:flutter/material.dart';

/// Flat, `const`-usable colour tokens for the authentication screens.
///
/// These mirror the dark-mode values that `TFColors.resolve` produces in
/// `tf_theme.dart`, so the auth flow reads as part of the same system. They
/// exist as plain constants because the auth widgets use them inside `const`
/// expressions, which rules out the runtime `withValues` blends TFColors uses.
abstract final class AppColors {
  /// App scaffold background — matches `TFColors.bg` (dark).
  static const background = Color(0xFF0E1116);

  /// Card / field background — matches `TFColors.surface` (dark).
  static const surface = Color(0xFF161A21);

  /// Hairline border — `TFColors.line` (dark): white at ~7.5% opacity.
  static const surfaceBorder = Color(0x13FFFFFF);

  /// Primary body text — `TFColors.text` (dark).
  static const textPrimary = Color(0xFFE9ECF1);

  /// Secondary / label text — `TFColors.textMuted` (dark).
  static const textSecondary = Color(0xFF99A2AF);

  /// Placeholder text — `TFColors.textDim` (dark).
  static const textHint = Color(0xFF69727F);

  /// Primary brand accent — the "smart money" green.
  /// Matches `TFColors.basePos` so auth shares the app's one green.
  static const primaryGreen = Color(0xFF34C77B);

  /// Secondary accent used for coins / highlights.
  static const accentGold = Color(0xFFF5B301);

  /// Gradient fill for primary CTA buttons (Sign In, etc.).
  static const primaryButtonGradient = LinearGradient(
    colors: [Color(0xFF3AD17F), Color(0xFF23A866)],
  );

  /// Soft radial glow behind hero illustrations, tinted to [color].
  static RadialGradient glow(Color color) => RadialGradient(
    colors: [
      color.withValues(alpha: 0.28),
      color.withValues(alpha: 0),
    ],
  );
}
