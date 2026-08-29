import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/app/view/server_wakeup_banner.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/router/app_router.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_theme.dart';
import 'package:flutter_piggypal_app/features/account/data/profile_store.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/languages/presentation/language_scope.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';
import 'package:intl/intl.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthenticationBloc sits above the router, not inside a screen: sign-in
    // creates the session, More ends it and splash asks whether there is one,
    // so all three have to be looking at the same instance. It starts the
    // launch check immediately.
    return BlocProvider(
      create: (_) =>
          sl<AuthenticationBloc>()..add(const AuthenticationStarted()),
      child: _SessionWatcher(
        // LanguageScope sits above MaterialApp so the chosen language can
        // drive `locale`. The Home header chip changes it; the whole app
        // re-localizes.
        child: LanguageScope(
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
                // All top-level navigation (splash → auth → home) is declared
                // in AppRouter. The Training Finance module still owns its own
                // in-shell navigation once you reach the `home` route.
                routerConfig: AppRouter.router,
                // Above the router, so a cold-starting API is explained
                // wherever the user happens to be standing — most often
                // splash, waiting on the session check.
                builder: (context, child) =>
                    ServerWakeupBanner(child: child ?? const SizedBox.shrink()),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Watches the session for the whole app.
///
/// Two jobs, both of which need to happen wherever the user is standing:
/// keeping the account screens in sync with the signed-in user, and getting
/// them off a screen they are no longer entitled to when the session ends by
/// itself.
class _SessionWatcher extends StatefulWidget {
  const _SessionWatcher({required this.child});

  final Widget child;

  @override
  State<_SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<_SessionWatcher> {
  AuthenticationStatus? _previousStatus;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        _syncProfile(state.user);

        // Losing a session that *was* live means the refresh token was
        // rejected: expired, revoked, or reused. Requests refresh and retry
        // themselves, so nothing else could have caused this. Sign-out takes
        // the same path and navigates on its own; `go` replaces the stack, so
        // arriving twice is harmless.
        final wasSignedIn =
            _previousStatus == AuthenticationStatus.authenticated;
        _previousStatus = state.status;
        if (wasSignedIn &&
            state.status == AuthenticationStatus.unauthenticated) {
          AppRouter.router.goNamed(AppRoutes.signIn);
        }
      },
      child: widget.child,
    );
  }
}

/// Copies the API's account onto the profile the account screens render.
///
/// `role` and `location` are left as they were: the API has no such fields,
/// and blanking them would empty two rows of a screen that has nothing else to
/// put there.
void _syncProfile(AuthUser? user) {
  final store = ProfileStore.instance;
  if (user == null) return;

  store.current = store.current.copyWith(
    name: user.displayName,
    email: user.email ?? '',
    phone: user.phone,
    joined: user.createdAt == null
        ? store.current.joined
        : DateFormat('MMMM yyyy').format(user.createdAt!),
  );
}
