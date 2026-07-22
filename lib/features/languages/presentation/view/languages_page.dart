import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/languages/presentation/language_scope.dart';
import 'package:flutter_piggypal_app/features/languages/presentation/widgets/language_menu_button.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';

/// Full-page variant of the language chooser (Khmer or English).
///
/// Applies the pick to the nearest [LanguageScope] and pops with the chosen
/// [AppLanguage]. The Home header's [LanguageMenuButton] is the quick variant.
class LanguagesPage extends StatelessWidget {
  const LanguagesPage({this.initial = AppLanguage.english, super.key});

  /// The language shown as selected when the page opens.
  final AppLanguage initial;

  @override
  Widget build(BuildContext context) {
    // Render inside its own theme scope so the page looks right even when it is
    // pushed on the root navigator, outside the Training Finance module.
    return TFThemeScope(
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: context.tfc.bg,
          body: _LanguagesView(initial: initial),
        ),
      ),
    );
  }
}

class _LanguagesView extends StatefulWidget {
  const _LanguagesView({required this.initial});

  final AppLanguage initial;

  @override
  State<_LanguagesView> createState() => _LanguagesViewState();
}

class _LanguagesViewState extends State<_LanguagesView> {
  late AppLanguage _selected = widget.initial;

  void _confirm() {
    LanguageScope.of(context).setLanguage(_selected);
    unawaited(Navigator.of(context).maybePop(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;

    return TFScreen(
      header: TFBackBar(
        title: context.l10n.languageTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 18),
          child: Text(
            context.l10n.languagePrompt,
            style: TFText.sans(
              size: 13.5,
              weight: FontWeight.w500,
              color: c.textMuted,
              letterSpacing: 0,
            ),
          ),
        ),
        for (final lang in AppLanguage.values) ...[
          _LanguageOption(
            language: lang,
            selected: _selected == lang,
            onTap: () => setState(() => _selected = lang),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        TFButton.primary(
          label: context.l10n.continueAction,
          icon: Icons.check_rounded,
          onTap: _confirm,
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return TFCard(
      padding: const EdgeInsets.all(13),
      radius: 18,
      borderColor: selected ? c.primaryLine : c.line,
      color: selected ? c.primarySoft : null,
      onTap: onTap,
      child: Row(
        children: [
          TFGlyphBadge(
            size: 46,
            radius: 14,
            hue: language.hue,
            child: Text(

              language.flag,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  language.native,
                  style: TFText.sans(
                    size: 15.5,
                    weight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  localizedLanguageName(context, language),
                  style: TFText.sans(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: c.textMuted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          _SelectionDot(selected: selected),
        ],
      ),
    );
  }
}

/// Radio-style indicator: a filled, checked disc when selected, a hollow ring
/// otherwise.
class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? c.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? c.primary : c.lineStrong,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 15, color: c.primaryInk)
          : null,
    );
  }
}
