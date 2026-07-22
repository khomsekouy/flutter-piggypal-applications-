import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';

/// A small left-aligned field label (matches the Add-category form style).
class AccountLabel extends StatelessWidget {
  const AccountLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TFText.sans(
          size: 12.5,
          weight: FontWeight.w700,
          color: context.tfc.textMuted,
        ),
      ),
    );
  }
}

/// A bordered input container matching the module's form style. Turns red when
/// [error] is set.
class AccountField extends StatelessWidget {
  const AccountField({required this.child, this.error = false, super.key});

  final Widget child;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: error ? c.neg : c.line),
      ),
      child: child,
    );
  }
}

/// A labelled single-line text input row used across the account forms.
class AccountTextField extends StatelessWidget {
  const AccountTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.error = false,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool error;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountLabel(label),
        const SizedBox(height: 9),
        AccountField(
          error: error,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: c.textMuted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  cursorColor: c.primary,
                  style: TFText.sans(size: 14, color: c.text, letterSpacing: 0),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TFText.sans(size: 14, color: c.textDim),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
