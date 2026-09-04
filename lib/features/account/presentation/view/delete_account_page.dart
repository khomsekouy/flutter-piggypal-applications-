import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/account/presentation/widgets/account_fields.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Closes the account, behind the password that opened it.
///
/// The password is not this screen being cautious — `POST /auth/delete-account`
/// requires it, so that a borrowed or unlocked phone cannot destroy an account
/// with the session it happens to be holding.
///
/// Nothing is navigated from here on success. The deletion revokes every
/// session, the bloc goes unauthenticated, and the app-wide session watcher
/// takes the user to sign-in — which is also where the recovery date is read
/// out, since this screen no longer exists by then.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({required this.nav, super.key});

  final TFNav nav;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordController = TextEditingController();

  /// True from the moment this screen asks for the deletion until the answer
  /// lands. The bloc is app-wide, so its `isBusy` alone would also be true for
  /// somebody else's request.
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _passwordController.text.isNotEmpty && !_submitting;

  void _handleDelete() {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    context.read<AuthenticationBloc>().add(
      AuthenticationDeleteAccountRequested(
        password: _passwordController.text,
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthenticationState state) {
    if (state.isBusy || !_submitting) return;
    setState(() => _submitting = false);

    // Success takes the session with it, and the watcher above this screen
    // navigates — there is nothing to do here but report a refusal.
    final error = state.errorMessage;
    if (error == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
    context.read<AuthenticationBloc>().add(
      const AuthenticationErrorDismissed(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: _onAuthStateChanged,
      child: TFScreen(
        // Clears the always-visible bottom tab bar so the action isn't hidden.
        bottomPadding: 120,
        header: TFBackBar(title: 'Delete Account', onBack: widget.nav.back),
        children: [
          TFCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: c.neg),
                    const SizedBox(width: 9),
                    Text(
                      'This closes your account',
                      style: TFText.sans(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: c.neg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final line in const [
                  'You will be signed out on every device.',
                  'Your savings goals, transactions and profile go with it.',
                ]) ...[
                  _Bullet(line),
                  const SizedBox(height: 7),
                ],
                // No number of days here on purpose: the grace period is
                // configured on the server, so any figure this screen named
                // would be the app promising something it does not know. The
                // real date comes back with the deletion and is shown then.
                const _Bullet(
                  'For a short while afterwards you can still recover it. '
                  'The exact date is shown once the deletion goes through.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const AccountLabel('Confirm your password'),
          const SizedBox(height: 9),
          AccountField(
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: c.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    enabled: !_submitting,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _handleDelete(),
                    cursorColor: c.primary,
                    style: TFText.sans(
                      size: 14,
                      color: c.text,
                      letterSpacing: 0,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '••••••••',
                      hintStyle: TFText.sans(size: 14, color: c.textDim),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your password is asked for again so that an unlocked phone alone '
            'cannot close your account.',
            style: TFText.sans(size: 12.5, color: c.textMuted),
          ),
          const SizedBox(height: 26),

          _DangerButton(
            label: 'Delete My Account',
            isLoading: _submitting,
            onTap: _canSubmit ? _handleDelete : null,
          ),
          const SizedBox(height: 10),
          TFButton.ghost(
            label: 'Keep My Account',
            enabled: !_submitting,
            onTap: widget.nav.back,
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: c.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TFText.sans(size: 13, color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

/// [TFButton]'s shape in the destructive colour, plus the spinner it has no
/// need for elsewhere — this is the one button in the app worth showing is
/// still running rather than letting it be pressed twice.
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.isLoading,
    this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final enabled = onTap != null && !isLoading;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.neg,
            borderRadius: BorderRadius.circular(15),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TFText.sans(
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
