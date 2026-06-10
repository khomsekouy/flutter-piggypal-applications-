import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_shell.dart';

/// Entry point for the Training Finance Management System module.
///
/// Self-contained: it owns its dark-fintech theme scope (accent / light-dark /
/// density), default text + icon styling and status-bar treatment, then hosts
/// the [TFShell]. Drop it anywhere — `home:` of a `MaterialApp`, a route, or a
/// full-screen push — and it renders the whole experience.
class TrainingFinanceApp extends StatelessWidget {
  const TrainingFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return TFThemeScope(
      child: Builder(
        builder: (context) {
          final t = context.tf;
          final c = t.colors;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: t.mode == TFMode.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Theme(
              data: ThemeData(
                brightness: t.mode == TFMode.dark
                    ? Brightness.dark
                    : Brightness.light,
                scaffoldBackgroundColor: c.bg,
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
              ),
              child: DefaultTextStyle(
                style: TFText.sans(
                  size: 15,
                  weight: FontWeight.w500,
                  color: c.text,
                  height: 1.45,
                ),
                child: IconTheme(
                  data: IconThemeData(color: c.text),
                  child: const TFShell(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
