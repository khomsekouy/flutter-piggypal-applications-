import 'package:flutter_piggypal_app/features/programs/data/datasources/programs_local_data_source.dart';
import 'package:flutter_piggypal_app/features/programs/data/models/program_model.dart';
import 'package:flutter_piggypal_app/features/programs/domain/entities/program.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart'
    as tf;

/// Builds the initial program rows from the design's mock dataset.
///
/// Sourced from [TFData] so the (still mock-backed) program detail / dashboard
/// screens stay perfectly in sync with the now Drift-backed programs list —
/// same ids, same figures.
List<Program> buildProgramSeed() {
  return [
    for (final (i, p) in TFData.instance.programs.indexed)
      Program(
        id: p.id,
        name: p.name,
        code: p.code,
        category: p.category,
        status: _mapStatus(p.status),
        hue: p.hue,
        start: p.start,
        end: p.end,
        weeks: p.weeks,
        location: p.location,
        trainer: p.trainer,
        capacity: p.capacity,
        enrolled: p.enrolled,
        fee: p.fee,
        budget: p.budget,
        income: p.income,
        spent: p.spent,
        sortOrder: i,
      ),
  ];
}

/// Inserts the seed rows once, on an empty table. Safe to call on every launch.
Future<void> seedPrograms(ProgramsLocalDataSource local) async {
  if ((await local.getAll()).isNotEmpty) return;
  for (final p in buildProgramSeed()) {
    await local.save(ProgramModel.fromEntity(p));
  }
}

ProgramStatus _mapStatus(tf.ProgramStatus s) => switch (s) {
  tf.ProgramStatus.active => ProgramStatus.active,
  tf.ProgramStatus.upcoming => ProgramStatus.upcoming,
  tf.ProgramStatus.completed => ProgramStatus.completed,
};
