import 'package:flutter_piggypal_app/features/dashboard/presentation/view/dashboard_page.dart';
import 'package:flutter_piggypal_app/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:flutter_piggypal_app/features/training_finance/training_finance_app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group('App', () {
    testWidgets('renders the Training Finance module on the dashboard', (
      tester,
    ) async {
      await tester.pumpAppToHome();

      expect(find.byType(TrainingFinanceApp), findsOneWidget);
      expect(find.byType(DashboardPage), findsOneWidget);
      // The header label proves the dashboard actually laid itself out, not
      // just that its widget type mounted. Rendered uppercase by the header.
      expect(find.text('OVERVIEW'), findsOneWidget);
      expect(find.byType(DashboardSearchField), findsOneWidget);
    });
  });
}
