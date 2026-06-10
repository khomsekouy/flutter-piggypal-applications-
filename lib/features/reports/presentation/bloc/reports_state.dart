part of 'reports_bloc.dart';

enum ReportsStatus { initial, loading, success, failure }

class ReportsState extends Equatable {
  const ReportsState({
    this.status = ReportsStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final ReportsStatus status;
  final List<Reports> items;
  final String? errorMessage;

  ReportsState copyWith({
    ReportsStatus? status,
    List<Reports>? items,
    String? errorMessage,
  }) {
    return ReportsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
