import 'package:flutter_piggypal_app/app/app.dart';
import 'package:flutter_piggypal_app/features/receipts/presentation/view/receipts_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Training Finance navigation', () {
    testWidgets(
      'tapping "Scan receipt" opens Receipts without overflow',
      (tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // The dashboard quick action that pushes the Receipts screen.
        await tester.tap(find.text('Scan receipt'));
        await tester.pumpAndSettle();

        // Screen rendered (a RenderFlex overflow would have failed the test).
        expect(find.byType(ReceiptsPage), findsOneWidget);
        expect(find.text('Scan a receipt'), findsOneWidget);
        expect(find.text('Recent receipts'), findsOneWidget);
      },
    );
  });
}
