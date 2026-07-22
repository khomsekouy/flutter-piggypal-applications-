import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/account/presentation/widgets/account_fields.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';

/// Change-password form: current + new + confirm, with show/hide toggles and
/// inline validation. Front-end only — Save validates then pops.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({required this.nav, super.key});

  final TFNav nav;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _new => _newCtrl.text;
  String get _confirm => _confirmCtrl.text;

  bool get _lengthOk => _new.length >= 8;
  bool get _matchOk => _confirm.isNotEmpty && _new == _confirm;
  bool get _currentOk => _currentCtrl.text.isNotEmpty;

  /// Rough 0–3 strength score for the meter.
  int get _strength {
    if (_new.isEmpty) return 0;
    var s = 0;
    if (_new.length >= 8) s++;
    if (RegExp('[A-Z]').hasMatch(_new) && RegExp('[a-z]').hasMatch(_new)) s++;
    if (RegExp(r'[0-9!@#$%^&*]').hasMatch(_new)) s++;
    return s;
  }

  bool get _canSave => _currentOk && _lengthOk && _matchOk;

  void _save() {
    setState(() => _submitted = true);
    if (!_canSave) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Password changed')));
    widget.nav.back();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;

    final confirmError = _submitted && _confirm.isNotEmpty && !_matchOk;

    return TFScreen(
      // Clears the always-visible bottom tab bar so the action isn't hidden.
      bottomPadding: 120,
      header: TFBackBar(title: 'Change Password', onBack: widget.nav.back),
      children: [
        Text(
          'Use at least 8 characters. A mix of letters, numbers and symbols '
          'makes it stronger.',
          style: TFText.sans(size: 13, color: c.textMuted),
        ),
        const SizedBox(height: 22),

        _PasswordField(
          label: 'Current Password',
          controller: _currentCtrl,
          error: _submitted && !_currentOk,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 18),

        _PasswordField(
          label: 'New Password',
          controller: _newCtrl,
          error: _submitted && !_lengthOk,
          onChanged: () => setState(() {}),
        ),
        if (_new.isNotEmpty) ...[
          const SizedBox(height: 10),
          _StrengthMeter(strength: _strength),
        ],
        const SizedBox(height: 18),

        _PasswordField(
          label: 'Confirm New Password',
          controller: _confirmCtrl,
          error: confirmError,
          onChanged: () => setState(() {}),
        ),
        if (confirmError) ...[
          const SizedBox(height: 8),
          const _ErrorText("Passwords don't match"),
        ],
        const SizedBox(height: 28),

        TFButton.primary(
          label: 'Update Password',
          icon: Icons.check,
          onTap: _save,
        ),
      ],
    );
  }
}

/// An obscured input with a show/hide eye toggle, built on [AccountField].
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.error = false,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool error;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountLabel(widget.label),
        const SizedBox(height: 9),
        AccountField(
          error: widget.error,
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: c.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: _obscure,
                  onChanged: (_) => widget.onChanged(),
                  cursorColor: c.primary,
                  style: TFText.sans(size: 14, color: c.text, letterSpacing: 0),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '••••••••',
                    hintStyle: TFText.sans(size: 14, color: c.textDim),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A three-segment strength meter with a label.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final (color, label) = switch (strength) {
      >= 3 => (c.pos, 'Strong'),
      2 => (c.warn, 'Fair'),
      _ => (c.neg, 'Weak'),
    };
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i < strength ? color : c.surface3,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
        const SizedBox(width: 10),
        Text(
          label,
          style: TFText.sans(size: 12, color: color),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Row(
      children: [
        Icon(Icons.error_outline, size: 14, color: c.neg),
        const SizedBox(width: 6),
        Text(text, style: TFText.sans(size: 12.5, color: c.neg)),
      ],
    );
  }
}
