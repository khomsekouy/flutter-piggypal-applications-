import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/training_finance_app.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Training Finance',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // The Training Finance module owns its own dark-fintech theme scope.
      // PiggyPal's original shell still lives at app/view/home_shell.dart —
      // swap it back in here to restore the savings experience.
      home: const TrainingFinanceApp(),
    );
  }
}
