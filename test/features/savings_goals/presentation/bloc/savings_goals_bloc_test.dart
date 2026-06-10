import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/add_contribution.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/create_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/delete_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/watch_goals.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/bloc/savings_goals_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchGoals extends Mock implements WatchGoals {}

class _MockCreateGoal extends Mock implements CreateGoal {}

class _MockAddContribution extends Mock implements AddContribution {}

class _MockDeleteGoal extends Mock implements DeleteGoal {}

void main() {
  late WatchGoals watchGoals;
  late CreateGoal createGoal;
  late AddContribution addContribution;
  late DeleteGoal deleteGoal;

  final goal = SavingsGoal(
    id: '1',
    name: 'Laptop',
    targetAmount: 1000,
    createdAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      CreateGoalParams(
        SavingsGoal(
          id: 'x',
          name: 'x',
          targetAmount: 1,
          createdAt: DateTime(2026),
        ),
      ),
    );
    registerFallbackValue(
      const AddContributionParams(goalId: 'x', amount: 1),
    );
    registerFallbackValue(const DeleteGoalParams('x'));
  });

  setUp(() {
    watchGoals = _MockWatchGoals();
    createGoal = _MockCreateGoal();
    addContribution = _MockAddContribution();
    deleteGoal = _MockDeleteGoal();
  });

  SavingsGoalsBloc buildBloc() => SavingsGoalsBloc(
    watchGoals: watchGoals,
    createGoal: createGoal,
    addContribution: addContribution,
    deleteGoal: deleteGoal,
  );

  group('SavingsGoalsBloc', () {
    blocTest<SavingsGoalsBloc, SavingsGoalsState>(
      'emits [loading, success] with goals from the stream',
      setUp: () {
        when(() => watchGoals(any())).thenAnswer((_) => Stream.value([goal]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const GoalsSubscriptionRequested()),
      expect: () => [
        const SavingsGoalsState(status: SavingsGoalsStatus.loading),
        SavingsGoalsState(
          status: SavingsGoalsStatus.success,
          goals: [goal],
        ),
      ],
    );

    blocTest<SavingsGoalsBloc, SavingsGoalsState>(
      'calls createGoal use case on GoalCreated',
      setUp: () {
        when(() => createGoal(any())).thenAnswer((_) async => Right(goal));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const GoalCreated(name: 'Laptop', targetAmount: 1000),
      ),
      verify: (_) => verify(() => createGoal(any())).called(1),
    );
  });
}
