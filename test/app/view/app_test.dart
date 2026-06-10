import 'package:flutter_piggypal_app/app/app.dart';
import 'package:flutter_piggypal_app/features/dashboard/presentation/view/dashboard_page.dart';
import 'package:flutter_piggypal_app/features/training_finance/training_finance_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('renders the Training Finance module on the dashboard', (
      tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pump(); // settle the entrance animation frame

      expect(find.byType(TrainingFinanceApp), findsOneWidget);
      expect(find.byType(DashboardPage), findsOneWidget);
      // Dashboard header + a KPI tile prove the screen rendered with mock data.
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Cash on hand'), findsOneWidget);
    });
  });
}
