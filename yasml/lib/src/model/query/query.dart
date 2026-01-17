import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/types/registry.dart';
import 'package:yasml/src/world/world.dart';

typedef CleanupFn = FutureOr<void> Function();

/// A query defines an interface where T is the return type of the query
/// and a method that can construct it from it's own definition.
/// Aside from that it should also define an initial state
@immutable
abstract base class Query<T> implements RegisitryKey<String> {
  T initialState(World world);
  CleanupFn fetch(World world, Option<T> currentState, ValueChanged<T> setState, VoidCallback settled);

  @nonVirtual
  @override
  int get hashCode => key.hashCode;

  @nonVirtual
  @override
  bool operator ==(Object other) {
    return other is Query && other.key == key;
  }
}
