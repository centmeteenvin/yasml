import 'package:flutter/cupertino.dart';

@immutable
sealed class Option<T> {
  const Option();

  bool get hasValue;

  T getOr(T defaultValue) {
    if (this case OptionValue(:final value)) {
      return value;
    }
    return defaultValue;
  }
}

@immutable
final class OptionValue<T> extends Option<T> {
  @override
  bool get hasValue => true;

  final T value;

  const OptionValue(this.value);
}

@immutable
final class OptionEmpty<T> extends Option<T> {
  @override
  bool get hasValue => false;
}
