import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/notification/data/notification_store.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_rows.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_segmented.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Which items the list is showing.
enum _Filter { all, unread }

/// The notification centre: everything the app wants to tell the user, newest
/// first, grouped by day.
///
/// Front-end only — reads [NotificationStore] and pushes the related screen
/// through [TFNav]. Tapping an item marks it read; swiping it away deletes it
/// with an undo.
class NotificationPage extends StatefulWidget {
  const NotificationPage({required this.nav, super.key});

  final TFNav nav;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  _Filter _filter = _Filter.all;

  NotificationStore get _store => NotificationStore.instance;

  void _open(AppNotification item) {
    _store.markRead(item.id);
    final target = item.target;
    if (target == null) return;
    widget.nav.push(target, item.targetParams);
  }

  void _delete(AppNotification item) {
    final index = _store.remove(item.id);
    if (index < 0) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Notification deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _store.restore(item, index),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AppNotification>>(
      valueListenable: _store.items,
      builder: (context, all, _) {
        // Read once per build so every row measures its age against the same
        // instant — otherwise two rows a millisecond apart could disagree
        // about which day they belong to.
        final now = DateTime.now();
        final unread = all.where((n) => !n.read).length;
        final visible = _filter == _Filter.unread
            ? all.where((n) => !n.read).toList()
            : all;

        return TFScreen(
          // The title, the count and the filter stay put while the list moves
          // under them — scrolling away the control you just used to filter
          // reads as the screen losing its place.
          pinnedHeader: true,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TFBackBar(
                title: 'Notifications',
                onBack: widget.nav.back,
                trailing: unread == 0
                    ? null
                    : TFIconButton(
                        icon: Icons.done_all_rounded,
                        onTap: _store.markAllRead,
                      ),
              ),
              // The header sits outside the body padding, so it carries its
              // own gutter.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Summary(unread: unread, total: all.length),
                    const SizedBox(height: 12),
                    TFSegmented<_Filter>(
                      value: _filter,
                      options: _Filter.values,
                      labelOf: (f) => switch (f) {
                        _Filter.all => 'All',
                        _Filter.unread =>
                          unread == 0 ? 'Unread' : 'Unread ($unread)',
                      },
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            if (visible.isEmpty)
              TFEmptyMessage(
                _filter == _Filter.unread
                    ? 'No unread notifications.\nYou are all caught up.'
                    : 'Nothing here yet.\nAlerts about payments, budgets and '
                          'receipts\nwill land here.',
              )
            else
              // Sections render in fixed order, so an empty day simply
              // disappears instead of shuffling the ones around it.
              for (final section in NotificationSection.values)
                ..._section(section, visible, now),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// The label + card for one day-group, or nothing when it has no items.
  List<Widget> _section(
    NotificationSection section,
    List<AppNotification> visible,
    DateTime now,
  ) {
    final items = visible
        .where((n) => sectionOf(n.receivedAt, now) == section)
        .toList();
    if (items.isEmpty) return const [];
    return [
      TFSectionLabel(
        title: switch (section) {
          NotificationSection.today => 'Today',
          NotificationSection.yesterday => 'Yesterday',
          NotificationSection.earlier => 'Earlier',
        },
      ),
      TFCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Column(
          children: [
            for (final (i, item) in items.indexed)
              Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: const _DeleteBackground(),
                onDismissed: (_) => _delete(item),
                child: _NotificationRow(
                  item: item,
                  now: now,
                  first: i == 0,
                  onTap: () => _open(item),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

/// Headline count above the filter.
class _Summary extends StatelessWidget {
  const _Summary({required this.unread, required this.total});

  final int unread;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Row(
      children: [
        Expanded(
          child: Text(
            unread == 0
                ? 'You are all caught up'
                : '$unread unread notification${unread == 1 ? '' : 's'}',
            style: TFText.sans(size: 14, color: c.text),
          ),
        ),
        Text(
          '$total total',
          style: TFText.sans(size: 12.5, color: c.textDim),
        ),
      ],
    );
  }
}

/// One notification: kind badge, title + body, age, and an unread marker.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.now,
    required this.first,
    required this.onTap,
  });

  final AppNotification item;
  final DateTime now;
  final bool first;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final (icon, fg, bg) = _styleOf(item.kind, context);
    return TFRow(
      first: first,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TFGlyphBadge(
            radius: 13,
            fg: fg,
            bg: bg,
            child: Icon(icon, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TFText.sans(
                    size: 14.5,
                    // Unread titles sit at full strength and read ones step
                    // back, so the eye finds what is new without needing a
                    // second control to point at it.
                    weight: item.read ? FontWeight.w600 : FontWeight.w700,
                    color: item.read ? c.textMuted : c.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TFText.sans(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: item.read ? c.textDim : c.textMuted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeAgo(item.receivedAt, now),
                style: TFText.sans(size: 11.5, color: c.textDim),
              ),
              const SizedBox(height: 6),
              if (!item.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Icon and tint per kind. Payments and budgets borrow the semantic
/// positive/warning colours so they read the same here as on the dashboard.
(IconData, Color, Color) _styleOf(NotificationKind kind, BuildContext context) {
  final c = context.tfc;
  return switch (kind) {
    NotificationKind.payment => (Icons.payments_outlined, c.pos, c.posSoft),
    NotificationKind.budget => (
      Icons.pie_chart_outline_rounded,
      c.warn,
      c.warnSoft,
    ),
    NotificationKind.receipt => (
      Icons.receipt_long_outlined,
      c.primary,
      c.primarySoft,
    ),
    NotificationKind.program => (
      Icons.grid_view_rounded,
      tfCatColor(192),
      tfCatSoft(192),
    ),
    NotificationKind.system => (
      Icons.info_outline_rounded,
      c.textMuted,
      c.surface3,
    ),
  };
}

/// What shows behind a row while it is being swiped away.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 6),
      child: Icon(Icons.delete_outline_rounded, size: 20, color: c.neg),
    );
  }
}
