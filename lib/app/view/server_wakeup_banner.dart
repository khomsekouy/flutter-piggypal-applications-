import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/network/server_wakeup.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';

/// Overlays [child] with an explanation whenever a request has been running
/// long enough to look stuck.
///
/// The API sleeps when idle, and the first request after a quiet period waits
/// on a cold start — most visibly on splash, where the session check is the
/// only thing between the user and their dashboard. Naming the wait is the
/// difference between "loading" and "frozen".
///
/// Wraps the whole app rather than living on a screen because the slow request
/// can be in flight anywhere, and it is [ServerWakeupNotifier] — not the
/// current route — that knows about it. Purely informational: it never takes a
/// pointer, so whatever is underneath stays usable.
class ServerWakeupBanner extends StatelessWidget {
  const ServerWakeupBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: ValueListenableBuilder<bool>(
            valueListenable: ServerWakeupNotifier.instance,
            builder: (context, isWaking, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: isWaking
                  ? const _WakeupCard()
                  : const SizedBox.shrink(key: ValueKey('idle')),
            ),
          ),
        ),
      ],
    );
  }
}

class _WakeupCard extends StatelessWidget {
  const _WakeupCard() : super(key: const ValueKey('waking'));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.serverWakingTitle,
                      style: TFText.sans(
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.serverWakingMessage,
                      style: TFText.sans(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
