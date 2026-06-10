import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';

/// A segmented pill toggle. The selected segment fills with the accent and gets
/// a soft glow (matching the prototype's tweak that ties segments to primary).
class TFSegmented<T> extends StatelessWidget {
  const TFSegmented({
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (final opt in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: opt == value ? c.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: opt == value
                        ? [
                            BoxShadow(
                              color: c.primary.withValues(alpha: 0.36),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labelOf(opt),
                    style: TFText.sans(
                      size: 13,
                      color: opt == value ? c.primaryInk : c.textMuted,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
