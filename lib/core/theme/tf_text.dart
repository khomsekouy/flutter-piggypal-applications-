import 'package:flutter/material.dart';

/// Typography helpers for the Training Finance module.
///
/// The prototype uses Plus Jakarta Sans (body), Space Grotesk (numbers) and
/// JetBrains Mono (eyebrows). Those families are not bundled, so we fall back
/// to the platform sans-serif and lean on weight, size, letter-spacing and
/// tabular figures to reproduce the feel. Add a `fontFamily` here (or wire up
/// `google_fonts`) for an exact match.
abstract final class TFText {
  static const _tabular = [FontFeature.tabularFigures()];

  /// Tabular-figure numeric style for money and metrics.
  static TextStyle num({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double letterSpacing = -0.5,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    fontFeatures: _tabular,
    height: 1.1,
  );

  /// Monospace style for code/eyebrow labels.
  static TextStyle mono({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double letterSpacing = 0.6,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    fontFeatures: _tabular,
  );

  /// General sans body/label style.
  static TextStyle sans({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double letterSpacing = -0.2,
    double? height,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}
