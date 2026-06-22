import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/programs/data/datasources/programs_local_data_source.dart';
import 'package:flutter_piggypal_app/features/programs/data/repositories/programs_repository_impl.dart';
import 'package:flutter_piggypal_app/features/programs/domain/repositories/programs_repository.dart';
import 'package:flutter_piggypal_app/features/programs/domain/usecases/delete_programs.dart';
import 'package:flutter_piggypal_app/features/programs/domain/usecases/save_programs.dart';
import 'package:flutter_piggypal_app/features/programs/domain/usecases/watch_programs_list.dart';
import 'package:flutter_piggypal_app/features/programs/presentation/bloc/programs_bloc.dart';

/// Wires the programs feature into the service locator.
/// Called once from [initDependencies].
void initPrograms() {
  sl
    // Bloc — fresh per screen.
    ..registerFactory(
      () => ProgramsBloc(watchProgramsList: sl(), deletePrograms: sl()),
    )
    // Use cases.
    ..registerLazySingleton(() => WatchProgramsList(sl()))
    ..registerLazySingleton(() => SavePrograms(sl()))
    ..registerLazySingleton(() => DeletePrograms(sl()))
    // Repository.
    ..registerLazySingleton<ProgramsRepository>(
      () => ProgramsRepositoryImpl(sl()),
    )
    // Data source.
    ..registerLazySingleton<ProgramsLocalDataSource>(
      () => ProgramsLocalDataSourceImpl(sl()),
    );
}
