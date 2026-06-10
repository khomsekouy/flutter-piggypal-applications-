import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';

/// Full-width action button in primary (filled) or ghost (outlined) style.
class TFButton extends StatelessWidget {
  const TFButton.primary({
    required this.label,
    this.icon,
    this.onTap,
    this.enabled = true,
    super.key,
  }) : _primary = true;

  const TFButton.ghost({
    required this.label,
    this.icon,
    this.onTap,
    this.enabled = true,
    super.key,
  }) : _primary = false;

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool _primary;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final fg = _primary ? c.primaryInk : c.text;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary ? c.primary : c.surface,
            borderRadius: BorderRadius.circular(15),
            border: _primary ? null : Border.all(color: c.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TFText.sans(
                  size: 15,
                  weight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
