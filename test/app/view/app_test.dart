import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_piggypal_app/app/app.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/bloc/savings_goals_bloc.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/view/savings_goals_page.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockSavingsGoalsBloc
    extends MockBloc<SavingsGoalsEvent, SavingsGoalsState>
    implements SavingsGoalsBloc {}

void main() {
  late SavingsGoalsBloc bloc;

  setUp(() async {
    bloc = _MockSavingsGoalsBloc();
    whenListen(
      bloc,
      const Stream<SavingsGoalsState>.empty(),
      initialState: const SavingsGoalsState(
        status: SavingsGoalsStatus.success,
      ),
    );
    await sl.reset();
    // Inject the mock bloc so the page renders without touching the database.
    sl.registerFactory<SavingsGoalsBloc>(() => bloc);
  });

  tearDown(sl.reset);

  group('App', () {
    testWidgets('renders SavingsGoalsPage', (tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(SavingsGoalsPage), findsOneWidget);
    });
  });
}
