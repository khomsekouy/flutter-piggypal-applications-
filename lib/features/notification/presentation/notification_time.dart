/// Which day-group a notification falls into on the list.
enum NotificationSection { today, yesterday, earlier }

/// Which day-group [at] belongs to, relative to [now].
NotificationSection sectionOf(DateTime at, DateTime now) {
  final startOfToday = DateTime(now.year, now.month, now.day);
  if (!at.isBefore(startOfToday)) return NotificationSection.today;
  if (!at.isBefore(startOfToday.subtract(const Duration(days: 1)))) {
    return NotificationSection.yesterday;
  }
  return NotificationSection.earlier;
}

/// Short relative age — "now", "25m", "3h", "4d".
String timeAgo(DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}w';
}
