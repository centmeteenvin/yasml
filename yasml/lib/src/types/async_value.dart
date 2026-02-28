import 'package:flutter/foundation.dart';

/// A class that represents the state of an asynchronous operation. It can be in one of three states: loading, error or data.
/// It is used to represent the state of a query that is based on a Future or a
/// Stream, and it is used to manage the state of the query in the query container.
@immutable
sealed class AsyncValue<T> {
  /// Whether the asynchronous operation is still loading. It is true when the operation is still in progress,
  ///  and false when it has completed (either with [AsyncData] or [AsyncError]).
  bool get isLoading;

  /// Whether the asynchronous operation has completed with an [AsyncError].
  bool get hasError;

  /// Whether the asynchronous operation has completed with an [AsyncData].
  bool get hasData => !isLoading && !hasError;
}

/// A class that represents the loading state of an asynchronous operation. It is used when the operation is still in progress.
@immutable
final class AsyncLoading<T> extends AsyncValue<T> {
  @override
  bool get isLoading => true;

  @override
  bool get hasError => false;
}

/// A class that represents the error state of an asynchronous operation. It is used when the operation has completed with an error.
@immutable
final class AsyncError<T> extends AsyncValue<T> {
  /// Creates an [AsyncError] with the given error and
  ///  stack trace. The error can be any object, but it is recommended to use an
  ///  [Exception] to represent the error message.
  ///
  /// The stack trace is optional but it can be very useful for debugging purposes.
  /// If you do not have access to the stack trace, you can access it via [StackTrace.current] at the point where you create the [AsyncError].
  AsyncError(this.error, {this.stackTrace});
  @override
  bool get isLoading => false;
  @override
  bool get hasError => true;

  /// The error that occurred during the asynchronous operation. It can be any object,
  /// but it is recommended to use an [Exception] to represent the error message.
  final Object error;

  /// The stack trace of the error. It is optional but it can be very useful for debugging purposes.
  final StackTrace? stackTrace;
}

/// A class that represents the data state of an asynchronous operation.
/// It is used when the operation has completed successfully with data.
@immutable
final class AsyncData<T> extends AsyncValue<T> {
  /// @nodoc
  AsyncData(this.data);
  @override
  bool get isLoading => false;
  @override
  bool get hasError => false;

  /// The data that was returned by the asynchronous operation.
  final T data;
}
