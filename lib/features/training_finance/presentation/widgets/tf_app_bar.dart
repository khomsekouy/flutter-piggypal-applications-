import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';

/// A circular icon button matching the prototype's `.iconbtn`.
class TFIconButton extends StatelessWidget {
  const TFIconButton({
    required this.icon,
    this.onTap,
    this.size = 20,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.line),
        ),
        child: Icon(icon, size: size, color: c.textMuted),
      ),
    );
  }
}

/// Large top app bar for tab roots (eyebrow + title + optional trailing).
class TFAppBar extends StatelessWidget {
  const TFAppBar({
    required this.title,
    this.eyebrow,
    this.trailing,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: TFText.mono(
                      size: 11,
                      color: c.textDim,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  title,
                  style: TFText.sans(
                    size: 27,
                    weight: FontWeight.w700,
                    color: c.text,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Compact app bar for pushed screens: a back chip + title + optional trailing.
class TFBackBar extends StatelessWidget {
  const TFBackBar({
    required this.title,
    required this.onBack,
    this.trailing,
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              height: 40,
              padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line),
              ),
              child: Icon(Icons.chevron_left, size: 22, color: c.text),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TFText.sans(
                size: 20,
                weight: FontWeight.w700,
                color: c.text,
                letterSpacing: -0.4,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Standard scrollable body wrapper for a screen: applies the radial background
/// gradient and bottom padding that clears the tab bar.
class TFScreen extends StatelessWidget {
  const TFScreen({
    required this.header,
    required this.children,
    this.bottomPadding = 108,
    this.padBody = true,
    super.key,
  });

  final Widget header;
  final List<Widget> children;
  final double bottomPadding;
  final bool padBody;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.4),
          radius: 1.1,
          colors: [
            Color.lerp(c.bg, context.tf.accent, 0.18)!,
            c.bg,
          ],
          stops: const [0, 0.6],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              if (padBody)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                )
              else
                ...children,
            ],
          ),
        ),
      ),
    );
  }
}
