import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/notification/data/notification_store.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The unread count as a pill, for settings rows that link to the centre.
/// Renders nothing when there is nothing unread.
class NotificationUnreadPill extends StatelessWidget {
  const NotificationUnreadPill({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationStore.instance.unreadCount,
      builder: (context, unread, _) => unread == 0
          ? const SizedBox.shrink()
          : TFPill(label: '$unread new', tone: PillTone.primary),
    );
  }
}

/// The header bell, with a count badge while anything is unread.
///
/// Listens to [NotificationStore.unreadCount] on its own, so the screens that
/// place it never have to rebuild for a badge change.
class NotificationBell extends StatelessWidget {
  const NotificationBell({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return ValueListenableBuilder<int>(
      valueListenable: NotificationStore.instance.unreadCount,
      builder: (context, unread, _) {
        return Stack(
          // The badge overhangs the button's top-right corner, so the stack
          // must not clip it.
          clipBehavior: Clip.none,
          children: [
            TFIconButton(
              icon: unread == 0
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_rounded,
              onTap: onTap,
            ),
            if (unread > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.neg,
                    borderRadius: BorderRadius.circular(999),
                    // Punches the badge out of the header behind it, so the
                    // count stays legible against the button's border.
                    border: Border.all(color: c.bg, width: 2),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: TFText.num(size: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
