import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:go_router/go_router.dart';

/// Builds [builder] with the signed-in account, or sends the user to sign-in
/// when there isn't one.
///
/// The later screens of sign-up all need a session — the account is created on
/// the first screen, and everything after it is a call against that session.
/// A deep link to one of those paths, or a session that ended while the app
/// was backgrounded, would otherwise render a screen whose every button 401s.
class RequiresSession extends StatelessWidget {
  const RequiresSession({required this.builder, super.key});

  final Widget Function(BuildContext context, AuthUser user) builder;

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthenticationBloc, AuthUser?>(
      (bloc) => bloc.state.user,
    );
    return user == null ? const _NoSession() : builder(context, user);
  }
}

/// On screen for the one frame before the redirect lands.
class _NoSession extends StatefulWidget {
  const _NoSession();

  @override
  State<_NoSession> createState() => _NoSessionState();
}

class _NoSessionState extends State<_NoSession> {
  @override
  void initState() {
    super.initState();
    // After the frame: navigating during a build is what throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.goNamed(AppRoutes.signIn);
    });
  }

  // Bare on purpose. A spinner here would be an indeterminate animation that
  // never settles — enough to hang any test that waits for the tree to rest.
  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: AppColors.background);
}
