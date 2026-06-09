import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// An async operation that resolves to either a [Failure] or a value of [T].
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// An async operation that resolves to either a [Failure] or nothing.
typedef ResultVoid = ResultFuture<void>;

/// A stream that always emits the latest value of [T] (used for live queries).
typedef ResultStream<T> = Stream<T>;
