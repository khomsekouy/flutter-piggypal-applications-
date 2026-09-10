import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:flutter_piggypal_app/features/notification/data/models/notification_model.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';
import 'package:flutter_piggypal_app/features/notification/presentation/view/notification_page.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

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

    // In-memory database, seeded by initDependencies with the design's seven
    // items. The page resolves its bloc from the service locator, so the
    // whole locator has to be up.
    setUp(() async {
      nav = _RecordingNav();
      await setUpDependencies();
    });

    tearDown(tearDownDependencies);

    NotificationLocalDataSource local() => sl<NotificationLocalDataSource>();

    Future<List<AppNotification>> rows() => local().getAll();

    Future<int> unreadInDb() async =>
        (await rows()).where((n) => !n.read).length;

    /// Empties the table, for the tests that want a known-tiny list.
    Future<void> clearAll() async {
      for (final n in await rows()) {
        await local().delete(n.id);
      }
    }

    /// Pumps the page, runs [body] against it, then tears the tree down while
    /// the test is still going — see [PumpApp.disposeApp] for why that cannot
    /// wait for `addTearDown`.
    Future<void> withPage(
      WidgetTester tester,
      Future<void> Function() body, {
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
      // Let the bloc's first stream emission land.
      await tester.pumpAndSettle();

      await body();

      await tester.disposeApp();
    }

    testWidgets('summarises how many are unread', (tester) async {
      await withPage(tester, () async {
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('3 unread notifications'), findsOneWidget);
        expect(find.text('7 total'), findsOneWidget);
      });
    });

    testWidgets('groups items by day', (tester) async {
      await withPage(tester, () async {
        // The seed spans today, yesterday and last week.
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Yesterday'), findsOneWidget);
        expect(find.text('Earlier'), findsOneWidget);
      });
    });

    testWidgets('the unread filter hides everything already read', (
      tester,
    ) async {
      await withPage(tester, () async {
        expect(find.text('Payment received'), findsOneWidget);
        expect(find.text('Monthly report ready'), findsOneWidget);

        await tester.tap(find.text('Unread (3)'));
        await tester.pumpAndSettle();

        expect(find.text('Payment received'), findsOneWidget);
        expect(find.text('Monthly report ready'), findsNothing);
        // Read-only groups drop out with their items.
        expect(find.text('Earlier'), findsNothing);
      });
    });

    testWidgets('tapping an item marks it read and opens its screen', (
      tester,
    ) async {
      await withPage(tester, () async {
        await tester.tap(find.text('Payment received'));
        await tester.pumpAndSettle();

        expect(nav.pushes.length, 1);
        expect(nav.pushes.single.$1, TFScreens.participant);
        expect(nav.pushes.single.$2['id'], 'u3');
        // Persisted, not merely repainted.
        expect(await unreadInDb(), 2);
        expect(find.text('2 unread notifications'), findsOneWidget);
      });
    });

    testWidgets('an item with nowhere to go still marks read', (tester) async {
      await clearAll();
      await local().save(
        NotificationModel(
          id: 'x1',
          kind: NotificationKind.system,
          title: 'No target here',
          body: 'Nothing to open.',
          receivedAt: DateTime.now(),
        ),
      );

      await withPage(tester, () async {
        await tester.tap(find.text('No target here'));
        await tester.pumpAndSettle();

        expect(nav.pushes, isEmpty);
        expect(await unreadInDb(), 0);
      });
    });

    testWidgets('mark-all-read clears the count and hides its own button', (
      tester,
    ) async {
      await withPage(tester, () async {
        await tester.tap(find.byIcon(Icons.done_all_rounded));
        await tester.pumpAndSettle();

        expect(await unreadInDb(), 0);
        expect(find.text('You are all caught up'), findsOneWidget);
        // Nothing left to mark, so the action goes away.
        expect(find.byIcon(Icons.done_all_rounded), findsNothing);
      });
    });

    testWidgets('swiping an item away deletes it, with an undo', (
      tester,
    ) async {
      await withPage(tester, () async {
        await tester.drag(
          find.text('Payment received'),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Payment received'), findsNothing);
        expect((await rows()).length, 6);

        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();

        // Restored against its own timestamp, so the newest item is newest
        // again rather than landing at the end.
        expect((await rows()).first.id, 'n1');
        expect(find.text('Payment received'), findsOneWidget);
      });
    });

    testWidgets('the title and filter stay put while the list scrolls', (
      tester,
    ) async {
      await withPage(
        tester,
        () async {
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
        },
        // Short enough that the list overflows and can actually scroll.
        size: const Size(420, 640),
      );
    });

    testWidgets('back goes through the shell', (tester) async {
      await withPage(tester, () async {
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        expect(nav.backs, 1);
      });
    });

    testWidgets('shows a distinct empty state per filter', (tester) async {
      await clearAll();

      await withPage(tester, () async {
        expect(find.textContaining('Nothing here yet.'), findsOneWidget);

        await tester.tap(find.text('Unread'));
        await tester.pumpAndSettle();

        expect(find.textContaining('You are all caught up'), findsWidgets);
      });
    });
  });
}
