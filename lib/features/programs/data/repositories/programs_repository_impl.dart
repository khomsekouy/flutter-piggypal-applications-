import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/programs/data/datasources/programs_local_data_source.dart';
import 'package:flutter_piggypal_app/features/programs/data/models/program_model.dart';
import 'package:flutter_piggypal_app/features/programs/domain/entities/program.dart';
import 'package:flutter_piggypal_app/features/programs/domain/repositories/programs_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Maps the local data source's exceptions onto domain `Failure`s.
class ProgramsRepositoryImpl implements ProgramsRepository {
  const ProgramsRepositoryImpl(this._local);

  final ProgramsLocalDataSource _local;

  @override
  ResultFuture<List<Program>> getAll() async {
    try {
      return Right(await _local.getAll());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultStream<List<Program>> watchAll() => _local.watchAll();

  @override
  ResultFuture<Program> save(Program item) async {
    try {
      final saved = await _local.save(ProgramModel.fromEntity(item));
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
