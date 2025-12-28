import 'package:flutter/foundation.dart';

@immutable
sealed class Result<T, E> {
  bool get hasError;
  bool get hasData => !hasError;

  const Result();

  factory Result.tryCatch(T Function() function, E Function(Exception exception) parseException) {
    try {
      return ResultData(function());
    } on Exception catch (e, s) {
      return ResultError(parseException(e), stackTrace: s);
    }
  }

  void when({required void Function(T data) data, required void Function(E error, StackTrace? stacktrace) error}) {
    switch (this) {
      case ResultError<T, E>(error: final err, :final stackTrace):
        error(err, stackTrace);
      case ResultData<T, E>(data: final d):
        data(d);
    }
  }
}

@immutable
final class ResultError<T, E> extends Result<T, E> {
  @override
  bool get hasError => true;

  const ResultError(this.error, {this.stackTrace});
  final E error;
  final StackTrace? stackTrace;
}

@immutable
final class ResultData<T, E> extends Result<T, E> {
  @override
  bool get hasError => false;

  const ResultData(this.data);

  final T data;
}
