import 'package:flutter/material.dart';

/// Dark/light appearance for the Training Finance module.
enum TFMode { dark, light }

/// Row/card spacing density (the prototype's "density" tweak).
enum TFDensity { compact, regular, comfortable }

/// Resolved design tokens for one accent + mode combination.
///
/// Mirrors the CSS custom properties in the prototype's `styles.css`. Soft/line
/// variants that the prototype produced with `color-mix(... transparent)` are
/// approximated here with alpha blends, which read identically against the
/// near-black surfaces.
@immutable
class TFColors {
  const TFColors({
    required this.primary,
    required this.primaryInk,
    required this.primarySoft,
    required this.primaryLine,
    required this.pos,
    required this.posSoft,
    required this.neg,
    required this.negSoft,
    required this.warn,
    required this.warnSoft,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.textMuted,
    required this.textDim,
    required this.navBg,
    required this.shadow,
  });

  /// Builds the full token set from an [accent] colour and [mode].
  factory TFColors.resolve(Color accent, TFMode mode) {
    final dark = mode == TFMode.dark;
    return TFColors(
      primary: accent,
      primaryInk: Colors.white,
      primarySoft: accent.withValues(alpha: 0.16),
      primaryLine: accent.withValues(alpha: 0.34),
      pos: basePos,
      posSoft: basePos.withValues(alpha: 0.16),
      neg: baseNeg,
      negSoft: baseNeg.withValues(alpha: 0.15),
      warn: baseWarn,
      warnSoft: baseWarn.withValues(alpha: 0.16),
      bg: dark ? const Color(0xFF0E1116) : const Color(0xFFF3F4F7),
      surface: dark ? const Color(0xFF161A21) : const Color(0xFFFFFFFF),
      surface2: dark ? const Color(0xFF1B2029) : const Color(0xFFF6F7FA),
      surface3: dark ? const Color(0xFF222936) : const Color(0xFFEEF0F5),
      line: dark
          ? Colors.white.withValues(alpha: 0.075)
          : const Color(0xFF0F141E).withValues(alpha: 0.08),
      lineStrong: dark
          ? Colors.white.withValues(alpha: 0.13)
          : const Color(0xFF0F141E).withValues(alpha: 0.14),
      text: dark ? const Color(0xFFE9ECF1) : const Color(0xFF161A22),
      textMuted: dark ? const Color(0xFF99A2AF) : const Color(0xFF5D6675),
      textDim: dark ? const Color(0xFF69727F) : const Color(0xFF8A93A3),
      navBg: dark
          ? const Color(0xFF101318).withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.92),
      shadow: dark
          ? Colors.black.withValues(alpha: 0.45)
          : const Color(0xFF141828).withValues(alpha: 0.12),
    );
  }

  final Color primary;
  final Color primaryInk;
  final Color primarySoft;
  final Color primaryLine;

  final Color pos; // income / positive
  final Color posSoft;
  final Color neg; // expense / negative
  final Color negSoft;
  final Color warn; // budget warning
  final Color warnSoft;

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color line;
  final Color lineStrong;

  final Color text;
  final Color textMuted;
  final Color textDim;

  final Color navBg;
  final Color shadow;

  static const basePos = Color(0xFF34C77B);
  static const baseNeg = Color(0xFFFF6B6B);
  static const baseWarn = Color(0xFFF4B740);
}

/// Theme bundle: resolved colours + density, plus a few derived helpers.
@immutable
class TFTheme {
  const TFTheme({
    required this.accent,
    required this.mode,
    required this.density,
    required this.colors,
  });

  factory TFTheme.from(Color accent, TFMode mode, TFDensity density) => TFTheme(
    accent: accent,
    mode: mode,
    density: density,
    colors: TFColors.resolve(accent, mode),
  );

  final Color accent;
  final TFMode mode;
  final TFDensity density;
  final TFColors colors;

  /// Vertical padding for list rows, per density.
  double get rowPadV => switch (density) {
    TFDensity.compact => 10,
    TFDensity.regular => 13,
    TFDensity.comfortable => 16,
  };

  /// Inner padding for cards, per density.
  double get cardPad => switch (density) {
    TFDensity.compact => 13,
    TFDensity.regular => 16,
    TFDensity.comfortable => 19,
  };

  /// The five accent swatches offered in the prototype's Tweaks panel.
  static const accents = <Color>[
    Color(0xFF6C5CE7),
    Color(0xFF4F8CFF),
    Color(0xFF1FB6A6),
    Color(0xFFE8617D),
    Color(0xFFF0A330),
  ];

  static const defaultAccent = Color(0xFF6C5CE7);
}

/// Hue helpers for category colours (`hsl(h 62% 62%)` in the prototype).
Color tfCatColor(double hue) =>
    HSLColor.fromAHSL(1, hue % 360, 0.62, 0.62).toColor();

Color tfCatSoft(double hue) =>
    HSLColor.fromAHSL(0.16, hue % 360, 0.55, 0.60).toColor();

/// Mutators for the active [TFTheme], exposed via [TFThemeScope.of].
abstract class TFThemeController {
  void setAccent(Color c);
  void setMode(TFMode m);
  void setDensity(TFDensity d);
}

/// Provides the active [TFTheme] to the subtree and exposes mutators so the
/// More → Appearance controls can re-tint the whole module live.
class TFThemeScope extends StatefulWidget {
  const TFThemeScope({required this.child, super.key});

  final Widget child;

  static TFThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TFInherited>();
    assert(scope != null, 'TFThemeScope is missing from the widget tree');
    return scope!.state;
  }

  /// Read the theme without subscribing — handy inside callbacks.
  static TFTheme themeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TFInherited>()!.theme;

  @override
  State<TFThemeScope> createState() => _TFThemeScopeState();
}

class _TFThemeScopeState extends State<TFThemeScope>
    implements TFThemeController {
  Color _accent = TFTheme.defaultAccent;
  TFMode _mode = TFMode.dark;
  TFDensity _density = TFDensity.regular;

  TFTheme get theme => TFTheme.from(_accent, _mode, _density);

  @override
  void setAccent(Color c) => setState(() => _accent = c);
  @override
  void setMode(TFMode m) => setState(() => _mode = m);
  @override
  void setDensity(TFDensity d) => setState(() => _density = d);

  @override
  Widget build(BuildContext context) {
    return _TFInherited(
      state: this,
      theme: theme,
      child: widget.child,
    );
  }
}

class _TFInherited extends InheritedWidget {
  const _TFInherited({
    required this.state,
    required this.theme,
    required super.child,
  });

  final _TFThemeScopeState state;
  final TFTheme theme;

  @override
  bool updateShouldNotify(_TFInherited old) => old.theme != theme;
}

/// Convenience accessor: `context.tf` → active [TFTheme].
extension TFThemeContext on BuildContext {
  TFTheme get tf => TFThemeScope.themeOf(this);
  TFColors get tfc => tf.colors;
}
