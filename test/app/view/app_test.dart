import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_piggypal_app/app/app.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/bloc/savings_goals_bloc.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/view/savings_goals_page.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/view/transactions_page.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockSavingsGoalsBloc
    extends MockBloc<SavingsGoalsEvent, SavingsGoalsState>
    implements SavingsGoalsBloc {}

class _MockTransactionsBloc
    extends MockBloc<TransactionsEvent, TransactionsState>
    implements TransactionsBloc {}

void main() {
  setUp(() async {
    await sl.reset();
    // Inject mock blocs so the shell renders without touching the database.
    sl
      ..registerFactory<SavingsGoalsBloc>(() {
        final bloc = _MockSavingsGoalsBloc();
        whenListen(
          bloc,
          const Stream<SavingsGoalsState>.empty(),
          initialState: const SavingsGoalsState(
            status: SavingsGoalsStatus.success,
          ),
        );
        return bloc;
      })
      ..registerFactory<TransactionsBloc>(() {
        final bloc = _MockTransactionsBloc();
        whenListen(
          bloc,
          const Stream<TransactionsState>.empty(),
          initialState: const TransactionsState(
            status: TransactionsStatus.success,
          ),
        );
        return bloc;
      });
  });

  tearDown(sl.reset);

  group('App', () {
    testWidgets('renders the home shell with both feature pages',
        (tester) async {
      await tester.pumpWidget(const App());
      // Transactions is the visible tab; Goals is built but offstage in the
      // IndexedStack, so it needs skipOffstage: false to be found.
      expect(find.byType(TransactionsPage), findsOneWidget);
      expect(
        find.byType(SavingsGoalsPage, skipOffstage: false),
        findsOneWidget,
      );
    });
  });
}
