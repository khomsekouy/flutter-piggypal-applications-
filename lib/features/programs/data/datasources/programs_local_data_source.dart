import 'package:drift/drift.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/features/programs/data/models/program_model.dart';

/// Talks to the local Drift database for training programs.
///
/// Throws [DatabaseException] on failure; the repository turns these into
/// `Failure`s.
abstract interface class ProgramsLocalDataSource {
  Future<List<ProgramModel>> getAll();
  Stream<List<ProgramModel>> watchAll();
  Future<ProgramModel> save(ProgramModel item);
  Future<void> delete(String id);
}

class ProgramsLocalDataSourceImpl implements ProgramsLocalDataSource {
  const ProgramsLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<ProgramModel>> getAll() async {
    try {
      final rows = await (_db.select(
        _db.programs,
      )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
      return rows.map(ProgramModel.fromRow).toList();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Stream<List<ProgramModel>> watchAll() {
    return (_db.select(_db.programs)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .map((rows) => rows.map(ProgramModel.fromRow).toList());
  }

  @override
  Future<ProgramModel> save(ProgramModel item) async {
    try {
      await _db.into(_db.programs).insertOnConflictUpdate(item.toCompanion());
      return item;
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (_db.delete(_db.programs)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }
}
