import 'package:flutter/material.dart';

/// The languages the app can be displayed in.
enum AppLanguage {
  english(
    code: 'en',
    name: 'English',
    native: 'English',
    short: 'EN',
    flag: '🇬🇧',
    hue: 222,
  ),
  khmer(
    code: 'km',
    name: 'Khmer',
    native: 'ភាសាខ្មែរ',
    short: 'ខ្មែរ',
    flag: '🇰🇭',
    hue: 8,
  );

  const AppLanguage({
    required this.code,
    required this.name,
    required this.native,
    required this.short,
    required this.flag,
    required this.hue,
  });

  /// ISO 639-1 code, also usable as a [Locale] language code.
  final String code;

  /// English-facing name ("Khmer", "English").
  final String name;

  /// Name written in the language itself ("ភាសាខ្មែរ", "English").
  final String native;

  /// Compact label for the header chip ("EN", "ខ្មែរ").
  final String short;

  /// Flag emoji shown in the option badge.
  final String flag;

  /// Category hue for the option's tinted badge.
  final double hue;
}

/// Read/write access to the active [AppLanguage], via `LanguageScope.of`.
abstract class LanguageController {
  AppLanguage get language;
  void setLanguage(AppLanguage language);
}

/// Holds the chosen [AppLanguage] and lets descendants change it.
///
/// Mirrors `TFThemeScope`: drop it above the module so the home header chip and
/// any future localized strings can react to the choice. This keeps the
/// selection for the running session; persist it (e.g. SharedPreferences) and
/// feed `language.code` into `MaterialApp.locale` to make it survive restarts.
class LanguageScope extends StatefulWidget {
  const LanguageScope({
    required this.child,
    this.initial = AppLanguage.english,
    super.key,
  });

  final Widget child;
  final AppLanguage initial;

  /// The controller for the nearest scope. Subscribes the caller to changes.
  static LanguageController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_LanguageInherited>();
    assert(scope != null, 'LanguageScope is missing from the widget tree');
    return scope!.state;
  }

  /// Read the current language without subscribing — handy inside callbacks.
  static AppLanguage languageOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_LanguageInherited>()!
      .language;

  @override
  State<LanguageScope> createState() => _LanguageScopeState();
}

class _LanguageScopeState extends State<LanguageScope>
    implements LanguageController {
  late AppLanguage _language = widget.initial;

  @override
  AppLanguage get language => _language;

  @override
  void setLanguage(AppLanguage language) {
    if (language == _language) return;
    setState(() => _language = language);
  }

  @override
  Widget build(BuildContext context) {
    return _LanguageInherited(
      state: this,
      language: _language,
      child: widget.child,
    );
  }
}

class _LanguageInherited extends InheritedWidget {
  const _LanguageInherited({
    required this.state,
    required this.language,
    required super.child,
  });

  final _LanguageScopeState state;
  final AppLanguage language;

  @override
  bool updateShouldNotify(_LanguageInherited old) => old.language != language;
}
