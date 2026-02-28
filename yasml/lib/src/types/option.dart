import 'package:flutter/cupertino.dart';

/// The Option type can either be an [OptionValue] or an [OptionEmpty].
///
/// Implemented as a sealed class enabling switch expressions and case matching.
@immutable
sealed class Option<T> {
  const Option();

  /// Returns true if the option is [OptionValue], false when [OptionEmpty].
  /// If it returns true, [Option.requireValue] returns without throwing.
  ///
  /// It is a convenience method, pattern matching is often the preferred method
  /// of interacting with the Option type.
  bool get hasValue;

  /// Return the [OptionValue.value] if this is [OptionValue] otherwise
  /// [defaultValue]
  T getOr(T defaultValue) {
    if (this case OptionValue(:final value)) {
      return value;
    }
    return defaultValue;
  }

  /// returns [OptionValue.value] if this is [OptionValue] otherwise throws
  /// an [AssertionError]
  T get requireValue {
    assert(this is OptionValue, 'option.requireValue must have a value');
    return (this as OptionValue<T>).value;
  }
}

/// Case when [Option] has a value.
@immutable
final class OptionValue<T> extends Option<T> {
  /// Create an [Option] that has a value
  const OptionValue(this.value);
  @override
  bool get hasValue => true;

  /// The value of the [Option]
  final T value;
}

/// Case when [Option] has no value
@immutable
final class OptionEmpty<T> extends Option<T> {
  @override
  bool get hasValue => false;
}
