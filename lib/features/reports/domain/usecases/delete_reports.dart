import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/reports/domain/repositories/reports_repository.dart';

class DeleteReports extends UseCase<void, DeleteReportsParams> {
  const DeleteReports(this._repository);

  final ReportsRepository _repository;

  @override
  ResultVoid call(DeleteReportsParams params) => _repository.delete(params.id);
}

class DeleteReportsParams extends Equatable {
  const DeleteReportsParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
