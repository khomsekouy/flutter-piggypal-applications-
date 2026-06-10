import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/reports/domain/entities/reports.dart';
import 'package:flutter_piggypal_app/features/reports/domain/repositories/reports_repository.dart';

class SaveReports extends UseCase<Reports, SaveReportsParams> {
  const SaveReports(this._repository);

  final ReportsRepository _repository;

  @override
  ResultFuture<Reports> call(SaveReportsParams params) =>
      _repository.save(params.item);
}

class SaveReportsParams extends Equatable {
  const SaveReportsParams(this.item);

  final Reports item;

  @override
  List<Object?> get props => [item];
}
