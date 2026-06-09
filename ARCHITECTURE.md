# PiggyPal — Architecture

A personal savings / money-management app built with **Clean Architecture**,
**feature-first** folders, **BLoC** for state, and **Drift (SQLite)** for
local-only persistence.

## The dependency rule

Dependencies point **inward only**. Outer layers know about inner layers; inner
layers know nothing about the outer ones.

```
presentation ──▶ domain ◀── data
   (UI/BLoC)    (pure Dart)   (Drift)
```

- **domain** is pure Dart — no Flutter, no Drift, no JSON. It is the stable core.
- **data** implements the domain's interfaces (depends on domain).
- **presentation** drives the domain through use cases (depends on domain).
- data and presentation never import each other.

Errors flow as values, not exceptions: the data layer throws `Exception`s, the
repository catches them and returns `Either<Failure, T>` (from `fpdart`), so the
UI never writes a `try/catch`.

## Folder layout

```
lib/
├── core/                         # shared across all features
│   ├── database/                 # Drift: AppDatabase + tables/
│   ├── di/                       # get_it service locator (injection_container.dart)
│   ├── error/                    # Failures (domain) + Exceptions (data)
│   ├── theme/                    # Material 3 theming
│   ├── usecases/                 # UseCase / StreamUseCase base classes
│   └── utils/                    # typedefs (ResultFuture…), money formatter
│
└── features/<feature>/
    ├── domain/                   # ← start here when adding a feature
    │   ├── entities/             # pure business objects (Equatable)
    │   ├── repositories/         # abstract interfaces (the contract)
    │   └── usecases/             # one class per action
    ├── data/
    │   ├── models/               # entity + Drift row mapping
    │   ├── datasources/          # talks to Drift, throws Exceptions
    │   └── repositories/         # implements domain interface, returns Either
    └── presentation/
        ├── bloc/                 # events / states / bloc
        ├── view/                 # pages (own the BlocProvider)
        └── widgets/              # dumb, reusable widgets
```

Two features follow this exact shape: **`features/savings_goals/`** (the piggy
banks) and **`features/transactions/`** (income & expenses). Copy either when
adding a new feature. The two tabs are hosted by `lib/app/view/home_shell.dart`,
an app-level `NavigationBar` shell (not a clean-arch feature itself).

## Data flow (example: "Add money to a goal")

```
GoalCard "Add" tap
  → ContributionAdded event
  → SavingsGoalsBloc
  → AddContribution use case
  → SavingsGoalRepository (interface)
  → SavingsGoalRepositoryImpl  (catches Exceptions → Failures)
  → SavingsGoalLocalDataSource (Drift transaction)
  → AppDatabase (SQLite)
```

The goals list refreshes automatically: the bloc subscribes to
`watchGoals()`, a live Drift stream, so any write re-emits the new list — no
manual reload after create/contribute/delete.

## Adding a new feature (e.g. `transactions`)

1. **Table** — add `core/database/tables/transactions_table.dart`, register it
   in `AppDatabase`'s `@DriftDatabase(tables: [...])`, bump `schemaVersion` and
   add a migration if the DB already shipped.
2. **Domain** — `entities/transaction.dart`, `repositories/transaction_repository.dart`
   (abstract), and a use case per action under `usecases/`.
3. **Data** — `models/transaction_model.dart` (mapping to/from the Drift row),
   `datasources/transaction_local_data_source.dart`, and
   `repositories/transaction_repository_impl.dart`.
4. **Presentation** — bloc (events/state/bloc), a page, widgets.
5. **DI** — add an `_initTransactions()` helper in `injection_container.dart`
   and call it from `initDependencies()`.
6. **Codegen** — run `dart run build_runner build` after touching any Drift table.

## Commands

```bash
dart run build_runner build        # regenerate Drift code (app_database.g.dart)
dart run build_runner watch        # regenerate on save
flutter analyze                    # lint (very_good_analysis)
flutter test                       # run the suite
flutter run --flavor development -t lib/main_development.dart
```

## Key packages

| Concern            | Package                              |
|--------------------|--------------------------------------|
| State management   | `bloc` / `flutter_bloc`              |
| Local database     | `drift` + `sqlite3_flutter_libs`     |
| Functional errors  | `fpdart` (`Either`)                  |
| Dependency injection | `get_it`                           |
| Value equality     | `equatable`                          |
| IDs                | `uuid`                               |

## Testing strategy

- **Domain / BLoC** — unit tests with `mocktail` + `bloc_test`, mocking use cases
  (see `test/.../bloc/savings_goals_bloc_test.dart`).
- **Data** — run against a real in-memory database
  (`AppDatabase.forTesting(NativeDatabase.memory())`) to validate Drift mappings
  (see `test/.../data/savings_goal_local_data_source_test.dart`).
- **Widget** — inject a `MockBloc` via the service locator so the UI renders
  without a database (see `test/app/view/app_test.dart`).
