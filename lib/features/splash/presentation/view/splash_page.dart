import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:go_router/go_router.dart';

/// Black-background launch screen shown while the app warms up.
///
/// Fades the app mark in, holds briefly, then routes on — to home if the
/// stored session is still good, otherwise to sign-in. It waits for both the
/// hold *and* the session check ([AuthenticationStarted], dispatched by
/// `App`), so a returning user never sees sign-in flash past on the way to
/// their own dashboard. Keeps its own black scaffold + light status-bar
/// treatment so the transition into the dark-fintech module is seamless.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// How long the mark stays on screen before routing forward.
  static const _hold = Duration(milliseconds: 1800);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  // Only the tagline/wordmark fades in; the icon is shown instantly so it
  // continues seamlessly from the native launch screen (no flash/re-entry).
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_scheduleNext());
  }

  Future<void> _scheduleNext() async {
    await Future<void>.delayed(SplashPage._hold);
    if (!mounted) return;

    final bloc = context.read<AuthenticationBloc>();
    // The check is normally done long before the hold is; this only matters on
    // a cold start against a slow network.
    if (!bloc.state.isResolved) {
      await bloc.stream.firstWhere((state) => state.isResolved);
      if (!mounted) return;
    }

    // Replace the splash route so back doesn't return here.
    context.goNamed(
      bloc.state.isAuthenticated ? AppRoutes.home : AppRoutes.signIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Icon stays centered exactly where the native launch screen
            // placed it, so the handoff is invisible.
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Wordmark + tagline fade in just below the centered icon.
            Align(
              alignment: const Alignment(0, 0.32),
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PiggyPal',
                      style: TFText.sans(
                        size: 26,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smarter money, made simple',
                      style: TFText.sans(
                        size: 13,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
