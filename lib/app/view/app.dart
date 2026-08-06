import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/router/app_router.dart';
import 'package:flutter_piggypal_app/core/theme/app_theme.dart';
import 'package:flutter_piggypal_app/features/languages/presentation/language_scope.dart';
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
          return MaterialApp.router(
            title: 'Training Finance',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: Locale(language.code),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // All top-level navigation (splash → auth → home) is declared in
            // AppRouter. The Training Finance module still owns its own
            // in-shell navigation once you reach the `home` route.
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
