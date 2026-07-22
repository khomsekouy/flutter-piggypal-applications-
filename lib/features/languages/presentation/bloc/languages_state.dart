part of 'languages_bloc.dart';

enum LanguagesStatus { initial, loading, success, failure }

class LanguagesState extends Equatable {
  const LanguagesState({
    this.status = LanguagesStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final LanguagesStatus status;
  final List<Languages> items;
  final String? errorMessage;

  LanguagesState copyWith({
    LanguagesStatus? status,
    List<Languages>? items,
    String? errorMessage,
  }) {
    return LanguagesState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
