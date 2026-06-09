import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_theme.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/view/savings_goals_page.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiggyPal',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SavingsGoalsPage(),
    );
  }
}
