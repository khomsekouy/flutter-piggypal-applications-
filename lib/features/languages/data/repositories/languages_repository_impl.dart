import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/languages/data/datasources/languages_local_data_source.dart';
import 'package:flutter_piggypal_app/features/languages/data/models/languages_model.dart';
import 'package:flutter_piggypal_app/features/languages/domain/entities/languages.dart';
import 'package:flutter_piggypal_app/features/languages/domain/repositories/languages_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Maps the local data source's exceptions onto domain `Failure`s.
class LanguagesRepositoryImpl implements LanguagesRepository {
  const LanguagesRepositoryImpl(this._local);

  final LanguagesLocalDataSource _local;

  @override
  ResultFuture<List<Languages>> getAll() async {
    try {
      return Right(await _local.getAll());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultStream<List<Languages>> watchAll() => _local.watchAll();

  @override
  ResultFuture<Languages> save(Languages item) async {
    try {
      final saved = await _local.save(LanguagesModel.fromEntity(item));
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
