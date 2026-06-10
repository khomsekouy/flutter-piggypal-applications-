part of 'programs_bloc.dart';

enum ProgramsStatus { initial, loading, success, failure }

class ProgramsState extends Equatable {
  const ProgramsState({
    this.status = ProgramsStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final ProgramsStatus status;
  final List<Program> items;
  final String? errorMessage;

  ProgramsState copyWith({
    ProgramsStatus? status,
    List<Program>? items,
    String? errorMessage,
  }) {
    return ProgramsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
