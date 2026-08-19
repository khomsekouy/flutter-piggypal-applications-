import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:flutter_piggypal_app/features/notification/data/models/notification_model.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Maps the local data source's exceptions onto domain `Failure`s.
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._local);

  final NotificationLocalDataSource _local;

  @override
  ResultFuture<List<Notification>> getAll() async {
    try {
      return Right(await _local.getAll());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultStream<List<Notification>> watchAll() => _local.watchAll();

  @override
  ResultFuture<Notification> save(Notification item) async {
    try {
      final saved = await _local.save(NotificationModel.fromEntity(item));
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
