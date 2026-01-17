import 'package:flutter/foundation.dart';

@immutable
sealed class AsyncValue<T> {
  bool get isLoading;
  bool get hasError;
  bool get hasData => !isLoading && !hasError;
}

@immutable
final class AsyncLoading<T> extends AsyncValue<T> {
  @override
  bool get isLoading => true;

  @override
  bool get hasError => false;
}

@immutable
final class AsyncError<T> extends AsyncValue<T> {
  @override
  bool get isLoading => false;
  @override
  bool get hasError => true;

  AsyncError(this.error, {this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;
}

@immutable
final class AsyncData<T> extends AsyncValue<T> {
  @override
  bool get isLoading => false;
  @override
  bool get hasError => false;

  AsyncData(this.data);
  final T data;
}
