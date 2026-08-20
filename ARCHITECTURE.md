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
│   ├── network/                  # dio client, ApiConfig, interceptors, error mapping
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

## Talking to the API

`features/authentication/` is the worked example of a **remote** feature; the
others are local-only (Drift).

```
Sign In tap
  → AuthenticationSignInRequested event
  → AuthenticationBloc
  → SignIn use case
  → AuthenticationRepository (interface)
  → AuthenticationRepositoryImpl   (catches Exceptions → Failures, stores tokens)
  → AuthenticationRemoteDataSource (dio; throws)
  → PiggyPal mobile API
```

Five endpoints are wired, all under `ApiConfig.baseUrl`
(`http://localhost:3000/api/v1/piggypal.d` by default):

| Call              | Endpoint             | Notes                                        |
|-------------------|----------------------|----------------------------------------------|
| Sign in           | `POST /auth/login`   | `countryCode` + **national** `phone`          |
| Sign up           | `POST /auth/register`| photo goes as the multipart `avatar` part     |
| Sign out          | `POST /auth/logout`  | body carries the refresh token                |
| Refresh           | `POST /auth/refresh` | automatic, on any 401 — see below             |
| Current user      | `GET /users/me`      | bearer token; fuller than `/auth/me`          |

Point a build at another host without touching code:

```bash
flutter run --dart-define=PIGGYPAL_API_BASE_URL=http://192.168.1.10:3000/api/v1/piggypal.d
```

Two things the rest of the app relies on:

- **One `Dio`**, built in `core/network/dio_client.dart` and registered by
  `initAuthentication()`. Its `AuthInterceptor` attaches the stored bearer
  token to every request, so a new feature that takes `sl<Dio>()` is
  authenticated for free.
- **Tokens live in the repository**, not the bloc — `AuthTokenStore` keeps them
  in the Keychain / EncryptedSharedPreferences, so a restart resumes the
  session (the splash screen confirms it against `GET /users/me` before
  routing to home).

**Refresh is automatic.** The access token lasts 15 minutes; when one expires,
`RefreshInterceptor` rotates the pair and replays the failed request, so
nothing above the network layer ever sees the 401. Two rules the API enforces
that the client has to respect:

- It **rotates** — the reply carries a new refresh token, and the old one is
  dead the moment it lands. `AuthSessionRefresher` stores the new pair before
  anything is retried.
- Presenting a retired refresh token is read as a **leak**, and drops every
  session the account has. So refreshes are single-flighted: concurrent 401s
  wait on one rotation rather than each spending the token
  (`AuthSessionRefresher._inFlight`). This is also why the interceptor is a
  plain `Interceptor` — a `QueuedInterceptor` would deadlock, since the refresh
  call travels on the same client.

When a refresh is itself rejected the session is over: tokens are cleared and
`AuthenticationRepository.sessionExpired` fires, which the bloc turns into
`unauthenticated` and `_SessionWatcher` (in `app/view/app.dart`) turns into a
trip back to sign-in, from whatever screen the user was on.

## Adding a new feature

### Quick start — the generator

Scaffold the entire folder structure (all three layers + bloc + page) with one
command:

```bash
dart run tool/new_feature.dart auth          # or any snake_case name
```

It creates `lib/features/auth/` with a compiling, lint-clean skeleton
(entity, repository, use cases, model, local data source, repository impl,
bloc/event/state, page), auto-formats it, and prints the exact wiring steps
(Drift table, DI registration, navigation). Existing folders are never
overwritten. Then follow the manual steps below to fill in the real fields and
queries.

### Manual steps (what the generator leaves for you)

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
dart run tool/new_feature.dart <name>   # scaffold a new feature folder
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
| HTTP               | `dio` (interceptors, cancel tokens)  |
| Token storage      | `flutter_secure_storage`             |
| Functional errors  | `fpdart` (`Either`)                  |
| Dependency injection | `get_it`                           |
| Value equality     | `equatable`                          |
| IDs                | `uuid`                               |

## Testing strategy

- **Domain / BLoC** — unit tests with `mocktail` + `bloc_test`, mocking use cases
  (see `test/.../bloc/savings_goals_bloc_test.dart`).
- **Remote data** — run the real repository, data source and interceptors
  against `FakeAuthApi` (a stubbed dio `HttpClientAdapter`, see
  `test/helpers/fake_auth_api.dart`), so request bodies and response parsing
  are both covered without a server.
- **Data** — run against a real in-memory database
  (`AppDatabase.forTesting(NativeDatabase.memory())`) to validate Drift mappings
  (see `test/.../data/savings_goal_local_data_source_test.dart`).
- **Widget** — inject a `MockBloc` via the service locator so the UI renders
  without a database (see `test/app/view/app_test.dart`).
