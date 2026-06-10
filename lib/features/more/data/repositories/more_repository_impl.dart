import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/more/data/datasources/more_local_data_source.dart';
import 'package:flutter_piggypal_app/features/more/data/models/more_model.dart';
import 'package:flutter_piggypal_app/features/more/domain/entities/more.dart';
import 'package:flutter_piggypal_app/features/more/domain/repositories/more_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Maps the local data source's exceptions onto domain `Failure`s.
class MoreRepositoryImpl implements MoreRepository {
  const MoreRepositoryImpl(this._local);

  final MoreLocalDataSource _local;

  @override
  ResultFuture<List<More>> getAll() async {
    try {
      return Right(await _local.getAll());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultStream<List<More>> watchAll() => _local.watchAll();

  @override
  ResultFuture<More> save(More item) async {
    try {
      final saved = await _local.save(MoreModel.fromEntity(item));
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
