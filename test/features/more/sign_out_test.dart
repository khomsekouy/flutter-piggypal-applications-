import 'package:flutter_piggypal_app/features/authentication/presentation/view/sign_in_page.dart';
import 'package:flutter_piggypal_app/features/more/presentation/view/more_page.dart';
import 'package:flutter_piggypal_app/features/training_finance/training_finance_app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group('Sign out', () {
    testWidgets('confirming leaves the module for sign-in', (tester) async {
      await tester.pumpAppToHome();

      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      expect(find.byType(MorePage), findsOneWidget);

      await tester.ensureVisible(find.text('Sign Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Dialog is up; confirm with its primary button.
      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
      // The whole module is gone, not just the More tab.
      expect(find.byType(TrainingFinanceApp), findsNothing);
      expect(find.byType(MorePage), findsNothing);
    });
  });
}
