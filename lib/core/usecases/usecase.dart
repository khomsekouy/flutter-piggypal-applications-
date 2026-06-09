import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';

/// A single unit of business logic.
///
/// Every use case takes [Params] as input and returns a [ResultFuture] of
/// [Type]. Keeping the contract uniform lets the presentation layer treat all
/// use cases the same way and keeps the domain layer independent of Flutter.
// ignore: one_member_abstracts
abstract class UseCase<T, Params> {
  const UseCase();

  ResultFuture<T> call(Params params);
}

/// A use case that emits a continuous stream rather than a one-shot result.
// ignore: one_member_abstracts
abstract class StreamUseCase<T, Params> {
  const StreamUseCase();

  ResultStream<T> call(Params params);
}

/// Placeholder for use cases that take no input.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
