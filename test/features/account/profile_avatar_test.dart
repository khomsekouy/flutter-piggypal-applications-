import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/features/account/data/profile_store.dart';
import 'package:flutter_piggypal_app/features/more/presentation/view/more_page.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

/// The URL the account's picture is rendered from, or null when the avatar
/// fell back to initials.
String? renderedImageUrl(WidgetTester tester) {
  final images = tester.widgetList<Image>(find.byType(Image));
  if (images.isEmpty) return null;
  return (images.first.image as NetworkImage).url;
}

Future<void> pumpAvatar(WidgetTester tester, {String? imageUrl}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: TFAvatar(name: 'Dara Sok', imageUrl: imageUrl)),
      ),
    ),
  );
}

void main() {
  group('TFAvatar', () {
    testWidgets('renders the uploaded picture when the account has one', (
      tester,
    ) async {
      const url = 'http://localhost:3000/uploads/avatars/dara.jpg';
      await pumpAvatar(tester, imageUrl: url);

      expect(renderedImageUrl(tester), url);
    });

    testWidgets('falls back to initials with no picture', (tester) async {
      await pumpAvatar(tester);

      expect(renderedImageUrl(tester), isNull);
      expect(find.text('DS'), findsOneWidget);
    });

    testWidgets('keeps the initials behind the picture while it loads', (
      tester,
    ) async {
      // Underneath rather than instead of: a picture that never arrives —
      // offline, a dead URL — must leave something readable on the screen.
      await pumpAvatar(tester, imageUrl: 'http://localhost:3000/nope.jpg');

      expect(find.text('DS'), findsOneWidget);
    });

    testWidgets('treats a blank URL as no picture', (tester) async {
      await pumpAvatar(tester, imageUrl: '   ');

      expect(renderedImageUrl(tester), isNull);
      expect(find.text('DS'), findsOneWidget);
    });
  });

  group('Profile.copyWith', () {
    const withPicture = Profile(
      name: 'Dara Sok',
      email: 'dara@piggypal.test',
      phone: '+85512345678',
      role: 'Finance Manager',
      location: 'Phnom Penh',
      joined: 'January 2026',
      avatarUrl: 'http://localhost:3000/uploads/avatars/dara.jpg',
    );

    test('leaves the picture alone when the field is omitted', () {
      expect(withPicture.copyWith(name: 'Sok Dara').avatarUrl, isNotNull);
    });

    test('clears the picture only when asked to', () {
      // Signing in as an account with no photo has to drop the last one, or
      // the previous user's face outlives their session.
      expect(withPicture.copyWith(clearAvatarUrl: true).avatarUrl, isNull);
    });
  });

  group('the signed-in account', () {
    tearDown(tearDownDependencies);

    testWidgets('shows the picture the API returned', (tester) async {
      final api = await setUpDependencies();
      api.avatarUrl = 'http://localhost:3000/uploads/avatars/dara.jpg';

      await tester.pumpAppToHome();
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      expect(find.byType(MorePage), findsOneWidget);

      // The whole path in one assertion: the API's `avatarUrl`, through
      // `AuthUser` and `_syncProfile`, onto the avatar the More tab renders.
      expect(renderedImageUrl(tester), api.avatarUrl);
    });

    // One `pumpAppToHome` per file, and this is it: `AppRouter.router` is a
    // static, so a second run resumes where the first ended rather than at
    // sign-in. The picture-less case is covered above, against TFAvatar.
  });
}
