part of 'more_bloc.dart';

enum MoreStatus { initial, loading, success, failure }

class MoreState extends Equatable {
  const MoreState({
    this.status = MoreStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final MoreStatus status;
  final List<More> items;
  final String? errorMessage;

  MoreState copyWith({
    MoreStatus? status,
    List<More>? items,
    String? errorMessage,
  }) {
    return MoreState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
