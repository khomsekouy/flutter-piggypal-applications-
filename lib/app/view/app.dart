import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_theme.dart';
import 'package:flutter_piggypal_app/features/languages/presentation/language_scope.dart';
import 'package:flutter_piggypal_app/features/splash/presentation/view/splash_page.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // LanguageScope sits above MaterialApp so the chosen language can drive
    // `locale`. The Home header chip changes it; the whole app re-localizes.
    return LanguageScope(
      child: Builder(
        builder: (context) {
          final language = LanguageScope.of(context).language;
          return MaterialApp(
            title: 'Training Finance',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: Locale(language.code),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // The Training Finance module owns its own dark-fintech theme.
            // PiggyPal's original shell still lives at app/view/home_shell.dart
            // — swap it in here to restore the savings experience. SplashPage
            // shows a black launch screen, then routes into the module.
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
