import 'package:flutter/foundation.dart';

@immutable
sealed class AsyncValue<T, E> {
  bool get isLoading;
  bool get hasError;
  bool get hasData => !isLoading && !hasError;
}

@immutable
final class AsyncLoading<T, E> extends AsyncValue<T, E> {
  @override
  bool get isLoading => true;

  @override
  bool get hasError => false;
}

@immutable
final class AsyncError<T, E> extends AsyncValue<T, E> {
  @override
  bool get isLoading => false;
  @override
  bool get hasError => true;

  AsyncError(this.error, {this.stackTrace});

  final E error;
  final StackTrace? stackTrace;
}

@immutable
final class AsyncData<T, E> extends AsyncValue<T, E> {
  @override
  bool get isLoading => false;
  @override
  bool get hasError => false;

  AsyncData(this.data);
  final T data;
}
