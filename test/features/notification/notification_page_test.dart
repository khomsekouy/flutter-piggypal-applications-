import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/notification/data/notification_store.dart';
import 'package:flutter_piggypal_app/features/notification/presentation/view/notification_page.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the screen asks the shell to do, without a real shell.
class _RecordingNav implements TFNav {
  final List<(String, Map<String, Object?>)> pushes = [];
  int backs = 0;

  @override
  void push(String screen, [Map<String, Object?> params = const {}]) =>
      pushes.add((screen, params));

  @override
  void back() => backs++;

  @override
  void reset() {}

  @override
  void tab(String name) {}
}

void main() {
  group('NotificationPage', () {
    late _RecordingNav nav;

    setUp(() {
      nav = _RecordingNav();
      NotificationStore.instance.resetForTesting();
    });

    tearDown(NotificationStore.instance.resetForTesting);

    Future<void> pumpPage(
      WidgetTester tester, {
      Size size = const Size(600, 1400),
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          // A Scaffold stands in for the shell's: the page shows its
          // delete/undo through the ScaffoldMessenger.
          home: Scaffold(
            body: TFThemeScope(child: NotificationPage(nav: nav)),
          ),
        ),
      );
      await tester.pump();
    }

    int unreadInStore() =>
        NotificationStore.instance.items.value.where((n) => !n.read).length;

    testWidgets('summarises how many are unread', (tester) async {
      await pumpPage(tester);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('3 unread notifications'), findsOneWidget);
      expect(find.text('7 total'), findsOneWidget);
    });

    testWidgets('groups items by day', (tester) async {
      await pumpPage(tester);

      // The seed spans today, yesterday and last week.
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Earlier'), findsOneWidget);
    });

    testWidgets('the unread filter hides everything already read', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Payment received'), findsOneWidget);
      expect(find.text('Monthly report ready'), findsOneWidget);

      await tester.tap(find.text('Unread (3)'));
      await tester.pumpAndSettle();

      expect(find.text('Payment received'), findsOneWidget);
      expect(find.text('Monthly report ready'), findsNothing);
      // Read-only groups drop out with their items.
      expect(find.text('Earlier'), findsNothing);
    });

    testWidgets('tapping an item marks it read and opens its screen', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.text('Payment received'));
      await tester.pumpAndSettle();

      expect(nav.pushes.length, 1);
      expect(nav.pushes.single.$1, TFScreens.participant);
      expect(nav.pushes.single.$2['id'], 'u3');
      expect(unreadInStore(), 2);
      expect(find.text('2 unread notifications'), findsOneWidget);
    });

    testWidgets('an item with nowhere to go still marks read', (tester) async {
      NotificationStore.instance.items.value = [
        AppNotification(
          id: 'x1',
          kind: NotificationKind.system,
          title: 'No target here',
          body: 'Nothing to open.',
          receivedAt: DateTime.now(),
        ),
      ];
      await pumpPage(tester);

      await tester.tap(find.text('No target here'));
      await tester.pumpAndSettle();

      expect(nav.pushes, isEmpty);
      expect(unreadInStore(), 0);
    });

    testWidgets('mark-all-read clears the count and hides its own button', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.done_all_rounded));
      await tester.pumpAndSettle();

      expect(unreadInStore(), 0);
      expect(find.text('You are all caught up'), findsOneWidget);
      // Nothing left to mark, so the action goes away.
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
    });

    testWidgets('swiping an item away deletes it, with an undo', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.drag(
        find.text('Payment received'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment received'), findsNothing);
      expect(NotificationStore.instance.items.value.length, 6);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Restored where it was, so the newest item is newest again.
      expect(NotificationStore.instance.items.value.first.id, 'n1');
      expect(find.text('Payment received'), findsOneWidget);
    });

    testWidgets('the title and filter stay put while the list scrolls', (
      tester,
    ) async {
      // Short enough that the list overflows and can actually scroll.
      await pumpPage(tester, size: const Size(420, 640));

      final titleBefore = tester.getTopLeft(find.text('Notifications'));
      final filterBefore = tester.getTopLeft(find.text('All'));
      final rowBefore = tester.getTopLeft(find.text('Payment received'));

      await tester.drag(
        find.text('Payment received'),
        const Offset(0, -160),
      );
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Notifications')), titleBefore);
      expect(tester.getTopLeft(find.text('All')), filterBefore);
      // The list moved even though the header did not.
      expect(
        tester.getTopLeft(find.text('Payment received')).dy,
        lessThan(rowBefore.dy),
      );
    });

    testWidgets('back goes through the shell', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(nav.backs, 1);
    });

    testWidgets('shows a distinct empty state per filter', (tester) async {
      NotificationStore.instance.clearAll();
      await pumpPage(tester);

      expect(find.textContaining('Nothing here yet.'), findsOneWidget);

      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();

      expect(find.textContaining('You are all caught up'), findsWidgets);
    });
  });
}
