import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/languages/presentation/language_scope.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';

/// Display name for [language] in the current locale.
String localizedLanguageName(BuildContext context, AppLanguage language) =>
    switch (language) {
      AppLanguage.english => context.l10n.languageEnglishName,
      AppLanguage.khmer => context.l10n.languageKhmerName,
    };

/// Compact header control that shows the active language and opens a chooser.
///
/// Reads the nearest [LanguageScope]; tapping it presents [showLanguageSheet].
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final lang = LanguageScope.of(context).language;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showLanguageSheet(context),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 6),
            Text(
              lang.short,
              style: TFText.sans(
                size: 12.5,
                weight: FontWeight.w700,
                color: c.text,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: c.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents the bottom-sheet language chooser and applies the pick to the
/// nearest [LanguageScope].
Future<void> showLanguageSheet(BuildContext context) {
  final controller = LanguageScope.of(context);
  // The sheet mounts on the navigator overlay, above the module's TFThemeScope,
  // so re-provide it seeded with the active theme for the sheet's subtree.
  final seed = context.tf;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    builder: (sheetContext) => TFThemeScope(
      seed: seed,
      child: _LanguageSheet(
        current: controller.language,
        onPick: (lang) {
          controller.setLanguage(lang);
          Navigator.of(sheetContext).pop();
        },
      ),
    ),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.current,
    required this.onPick,
  });

  final AppLanguage current;
  final ValueChanged<AppLanguage> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.lineStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              context.l10n.languageTitle,
              style: TFText.sans(
                size: 16,
                weight: FontWeight.w700,
                color: c.text,
                letterSpacing: -0.3,
              ),
            ),
          ),
          for (final lang in AppLanguage.values) ...[
            _LanguageOption(
              language: lang,
              selected: lang == current,
              onTap: () => onPick(lang),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
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
      color: selected ? c.primarySoft : c.surface2,
      onTap: onTap,
      child: Row(
        children: [
          TFGlyphBadge(
            size: 44,
            radius: 14,
            hue: language.hue,
            child: Text(language.flag, style: const TextStyle(fontSize: 21)),
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
          if (selected)
            Icon(Icons.check_circle_rounded, size: 22, color: c.primary)
          else
            Icon(Icons.circle_outlined, size: 22, color: c.lineStrong),
        ],
      ),
    );
  }
}
