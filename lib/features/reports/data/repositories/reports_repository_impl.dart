import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/reports/data/datasources/reports_local_data_source.dart';
import 'package:flutter_piggypal_app/features/reports/data/models/reports_model.dart';
import 'package:flutter_piggypal_app/features/reports/domain/entities/reports.dart';
import 'package:flutter_piggypal_app/features/reports/domain/repositories/reports_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Maps the local data source's exceptions onto domain `Failure`s.
class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._local);

  final ReportsLocalDataSource _local;

  @override
  ResultFuture<List<Reports>> getAll() async {
    try {
      return Right(await _local.getAll());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultStream<List<Reports>> watchAll() => _local.watchAll();

  @override
  ResultFuture<Reports> save(Reports item) async {
    try {
      final saved = await _local.save(ReportsModel.fromEntity(item));
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
