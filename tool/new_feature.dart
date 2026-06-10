// This is a command-line tool whose whole job is to print progress and
// instructions to the console, so `print` is the right output channel here.
// ignore_for_file: avoid_print
//
// Feature scaffolding generator for PiggyPal's clean architecture.
//
// Usage:
//   dart run tool/new_feature.dart <feature_name>
//
// <feature_name> must be snake_case, e.g. `auth`, `accounts`, `user_profile`.
//
// It creates lib/features/<feature_name>/ with the full data / domain /
// presentation layer skeleton (entity, repository, use cases, model, local
// data source, repository impl, bloc, page) following the same conventions as
// the savings_goals and transactions features. Existing files are never
// overwritten. After generating, it prints the exact wiring steps (Drift table,
// DI registration, navigation).

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty || args.first == '-h' || args.first == '--help') {
    _printUsage();
    exit(args.isEmpty ? 1 : 0);
  }

  final snake = args.first.trim();
  if (!_isSnakeCase(snake)) {
    stderr.writeln(
      'Error: feature name must be snake_case (lowercase, digits, '
      'underscores), e.g. `user_profile`. Got: "$snake".',
    );
    exit(1);
  }

  final pkg = _packageName();
  final pascal = _toPascal(snake);
  final ctx = _Ctx(pkg: pkg, snake: snake, pascal: pascal);

  final featureDir = 'lib/features/$snake';
  if (Directory(featureDir).existsSync()) {
    stderr.writeln(
      'Error: $featureDir already exists. Pick a new name or delete it first.',
    );
    exit(1);
  }

  final files = _templates(ctx);
  final created = <String>[];
  files.forEach((relativePath, content) {
    final file = File('$featureDir/$relativePath');
    if (file.existsSync()) return; // never overwrite
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    created.add(file.path);
  });

  // Format the generated files so output matches the project's dart_style
  // rules (wraps long arrow bodies, etc.). Best-effort: ignore if dart isn't
  // on PATH for some reason.
  try {
    Process.runSync('dart', ['format', featureDir]);
  } on ProcessException {
    // Skip silently — the user can run `dart format` themselves.
  }

  print('✓ Created feature "$snake" with ${created.length} files:\n');
  for (final path in created..sort()) {
    print('  $path');
  }
  _printNextSteps(ctx);
}

// ---------------------------------------------------------------------------
// Templates
// ---------------------------------------------------------------------------

Map<String, String> _templates(_Ctx c) {
  final p = c.pkg;
  final s = c.snake;
  final P = c.pascal;

  return {
    // ---- domain --------------------------------------------------------
    'domain/entities/$s.dart': '''
import 'package:equatable/equatable.dart';

/// Domain entity for the $s feature.
///
/// Pure Dart — no Flutter, no Drift. Replace `name` with this feature's real
/// fields.
class $P extends Equatable {
  const $P({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
''',

    'domain/repositories/${s}_repository.dart': '''
import 'package:$p/core/utils/typedefs.dart';
import 'package:$p/features/$s/domain/entities/$s.dart';

/// Domain contract for the $s feature.
///
/// The data layer provides the implementation.
abstract interface class ${P}Repository {
  ResultFuture<List<$P>> getAll();

  ResultStream<List<$P>> watchAll();

  ResultFuture<$P> save($P item);

  ResultVoid delete(String id);
}
''',

    'domain/usecases/watch_${s}_list.dart': '''
import 'package:$p/core/usecases/usecase.dart';
import 'package:$p/core/utils/typedefs.dart';
import 'package:$p/features/$s/domain/entities/$s.dart';
import 'package:$p/features/$s/domain/repositories/${s}_repository.dart';

/// Streams all $s items, re-emitting on any change.
class Watch${P}List extends StreamUseCase<List<$P>, NoParams> {
  const Watch${P}List(this._repository);

  final ${P}Repository _repository;

  @override
  ResultStream<List<$P>> call(NoParams params) => _repository.watchAll();
}
''',

    'domain/usecases/save_$s.dart': '''
import 'package:equatable/equatable.dart';
import 'package:$p/core/usecases/usecase.dart';
import 'package:$p/core/utils/typedefs.dart';
import 'package:$p/features/$s/domain/entities/$s.dart';
import 'package:$p/features/$s/domain/repositories/${s}_repository.dart';

class Save$P extends UseCase<$P, Save${P}Params> {
  const Save$P(this._repository);

  final ${P}Repository _repository;

  @override
  ResultFuture<$P> call(Save${P}Params params) => _repository.save(params.item);
}

class Save${P}Params extends Equatable {
  const Save${P}Params(this.item);

  final $P item;

  @override
  List<Object?> get props => [item];
}
''',

    'domain/usecases/delete_$s.dart': '''
import 'package:equatable/equatable.dart';
import 'package:$p/core/usecases/usecase.dart';
import 'package:$p/core/utils/typedefs.dart';
import 'package:$p/features/$s/domain/repositories/${s}_repository.dart';

class Delete$P extends UseCase<void, Delete${P}Params> {
  const Delete$P(this._repository);

  final ${P}Repository _repository;

  @override
  ResultVoid call(Delete${P}Params params) => _repository.delete(params.id);
}

class Delete${P}Params extends Equatable {
  const Delete${P}Params(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
''',

    // ---- data ----------------------------------------------------------
    'data/models/${s}_model.dart': '''
import 'package:$p/features/$s/domain/entities/$s.dart';

/// Data-layer representation of [$P].
///
/// Once you add the Drift table, give this a `fromRow(...)` factory and a
/// `toCompanion()` method (see features/transactions for a worked example).
class ${P}Model extends $P {
  const ${P}Model({required super.id, required super.name});

  factory ${P}Model.fromEntity($P entity) =>
      ${P}Model(id: entity.id, name: entity.name);
}
''',

    'data/datasources/${s}_local_data_source.dart': '''
import 'package:$p/features/$s/data/models/${s}_model.dart';

/// Local (Drift) data source for the $s feature.
///
/// Throws on failure; the repository maps exceptions to `Failure`s.
abstract interface class ${P}LocalDataSource {
  Future<List<${P}Model>> getAll();
  Stream<List<${P}Model>> watchAll();
  Future<${P}Model> save(${P}Model item);
  Future<void> delete(String id);
}

class ${P}LocalDataSourceImpl implements ${P}LocalDataSource {
  const ${P}LocalDataSourceImpl();

  // TODO(khomsekouy): inject AppDatabase and replace these stubs with real
  // Drift queries. See features/transactions for a worked example.

  @override
  Future<List<${P}Model>> getAll() async => <${P}Model>[];

  @override
  Stream<List<${P}Model>> watchAll() =>
      Stream<List<${P}Model>>.value(<${P}Model>[]);

  @override
  Future<${P}Model> save(${P}Model item) async => item;

  @override
  Future<void> delete(String id) async {}
}
''',

    'data/repositories/${s}_repository_impl.dart': '''
import 'package:$p/core/error/exceptions.dart';
import 'package:$p/core/error/failures.dart';
import 'package:$p/core/utils/typedefs.dart';
import 'package:$p/features/$s/data/datasources/${s}_local_data_source.dart';
import 'package:$p/features/$s/data/models/${s}_model.dart';
import 'package:$p/features/$s/domain/entities/$s.dart';
import 'package:$p/features/$s/domain/repositories/${s}_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Maps the local data source's exceptions onto domain `Failure`s.
class ${P}RepositoryImpl implements ${P}Repository {
  const ${P}RepositoryImpl(this._local);

  final ${P}LocalDataSource _local;

  @override
  ResultFuture<List<$P>> getAll() async {
    try {
      return Right(await _local.getAll());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultStream<List<$P>> watchAll() => _local.watchAll();

  @override
  ResultFuture<$P> save($P item) async {
    try {
      final saved = await _local.save(${P}Model.fromEntity(item));
      return Right(saved);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultVoid delete(String id) async {
    try {
      await _local.delete(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}
''',

    // ---- presentation --------------------------------------------------
    'presentation/bloc/${s}_event.dart': '''
part of '${s}_bloc.dart';

sealed class ${P}Event extends Equatable {
  const ${P}Event();

  @override
  List<Object?> get props => [];
}

/// Start listening to the live stream of items.
class ${P}SubscriptionRequested extends ${P}Event {
  const ${P}SubscriptionRequested();
}

class ${P}Deleted extends ${P}Event {
  const ${P}Deleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
''',

    'presentation/bloc/${s}_state.dart': '''
part of '${s}_bloc.dart';

enum ${P}Status { initial, loading, success, failure }

class ${P}State extends Equatable {
  const ${P}State({
    this.status = ${P}Status.initial,
    this.items = const [],
    this.errorMessage,
  });

  final ${P}Status status;
  final List<$P> items;
  final String? errorMessage;

  ${P}State copyWith({
    ${P}Status? status,
    List<$P>? items,
    String? errorMessage,
  }) {
    return ${P}State(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
''',

    'presentation/bloc/${s}_bloc.dart': '''
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:$p/core/usecases/usecase.dart';
import 'package:$p/features/$s/domain/entities/$s.dart';
import 'package:$p/features/$s/domain/usecases/delete_$s.dart';
import 'package:$p/features/$s/domain/usecases/watch_${s}_list.dart';

part '${s}_event.dart';
part '${s}_state.dart';

/// Drives the $s use cases for the UI.
///
/// The list stays fresh via a live Drift stream, so writes never need a manual
/// refresh.
class ${P}Bloc extends Bloc<${P}Event, ${P}State> {
  ${P}Bloc({
    required Watch${P}List watch${P}List,
    required Delete$P delete$P,
  })  : _watch${P}List = watch${P}List,
        _delete$P = delete$P,
        super(const ${P}State()) {
    on<${P}SubscriptionRequested>(_onSubscriptionRequested);
    on<${P}Deleted>(_onDeleted);
  }

  final Watch${P}List _watch${P}List;
  final Delete$P _delete$P;

  Future<void> _onSubscriptionRequested(
    ${P}SubscriptionRequested event,
    Emitter<${P}State> emit,
  ) async {
    emit(state.copyWith(status: ${P}Status.loading));
    await emit.forEach<List<$P>>(
      _watch${P}List(const NoParams()),
      onData: (items) => state.copyWith(
        status: ${P}Status.success,
        items: items,
      ),
      onError: (_, _) => state.copyWith(
        status: ${P}Status.failure,
        errorMessage: 'Could not load data.',
      ),
    );
  }

  Future<void> _onDeleted(
    ${P}Deleted event,
    Emitter<${P}State> emit,
  ) async {
    final result = await _delete$P(Delete${P}Params(event.id));
    result.match(
      (failure) => emit(
        state.copyWith(
          status: ${P}Status.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }
}
''',

    'presentation/view/${s}_page.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$p/core/di/injection_container.dart';
import 'package:$p/features/$s/presentation/bloc/${s}_bloc.dart';

/// Entry point for the $s feature.
///
/// Owns the bloc and starts its subscription.
class ${P}Page extends StatelessWidget {
  const ${P}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return sl<${P}Bloc>()..add(const ${P}SubscriptionRequested());
      },
      child: const _${P}View(),
    );
  }
}

class _${P}View extends StatelessWidget {
  const _${P}View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$P')),
      body: BlocBuilder<${P}Bloc, ${P}State>(
        builder: (context, state) {
          if (state.status == ${P}Status.loading ||
              state.status == ${P}Status.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return const Center(child: Text('Nothing here yet.'));
          }
          return ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return ListTile(
                title: Text(item.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      context.read<${P}Bloc>().add(${P}Deleted(item.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
''',
  };
}

// ---------------------------------------------------------------------------
// Next-steps output
// ---------------------------------------------------------------------------

void _printNextSteps(_Ctx c) {
  final s = c.snake;
  final P = c.pascal;
  print('''

Next steps to wire it up:

1) Drift table — create lib/core/database/tables/${s}_table.dart, then add it to
   @DriftDatabase(tables: [...]) in app_database.dart, bump schemaVersion, add a
   migration, and run:  dart run build_runner build

2) Data source — in ${s}_local_data_source.dart, inject AppDatabase and replace
   the stub methods with real Drift queries.

3) DI — in lib/core/di/injection_container.dart add a call to _init$P() inside
   initDependencies(), and paste this helper:

void _init$P() {
  sl
    ..registerFactory(
      () => ${P}Bloc(watch${P}List: sl(), delete$P: sl()),
    )
    ..registerLazySingleton(() => Watch${P}List(sl()))
    ..registerLazySingleton(() => Save$P(sl()))
    ..registerLazySingleton(() => Delete$P(sl()))
    ..registerLazySingleton<${P}Repository>(
      () => ${P}RepositoryImpl(sl()),
    )
    ..registerLazySingleton<${P}LocalDataSource>(
      () => const ${P}LocalDataSourceImpl(),
    );
}

4) Navigation — add ${P}Page() to lib/app/view/home_shell.dart (or push it).

Tip: run `dart format lib/features/$s` and `flutter analyze` to confirm.
''');
}

void _printUsage() {
  print('''
Generate a clean-architecture feature folder.

Usage:
  dart run tool/new_feature.dart <feature_name>

<feature_name> must be snake_case, e.g.:
  dart run tool/new_feature.dart auth
  dart run tool/new_feature.dart user_profile
''');
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _Ctx {
  const _Ctx({required this.pkg, required this.snake, required this.pascal});

  final String pkg;
  final String snake;
  final String pascal;
}

bool _isSnakeCase(String s) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(s);

String _toPascal(String snake) => snake
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join();

String _packageName() {
  final pubspec = File('pubspec.yaml');
  if (pubspec.existsSync()) {
    for (final line in pubspec.readAsLinesSync()) {
      final match = RegExp(r'^name:\s*(\S+)').firstMatch(line);
      if (match != null) return match.group(1)!;
    }
  }
  return 'flutter_piggypal_app';
}
