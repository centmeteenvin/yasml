import 'package:flutter/rendering.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

/// A base class for queries that are based on a synchronous computation. It handles the common logic of
/// managing the state and the execution of the query when the query container is executed or invalidated
abstract base class SynchronousQuery<T> extends Query<T> {
  @override
  T initialState(World world) {
    return query(world);
  }

  @override
  CleanupFn fetch(World world, Option<T> currentState, ValueChanged<T> setState, VoidCallback settled) {
    if (currentState case OptionValue(:final value)) {
      setState(value);
    }
    settled();

    return () {};
  }

  /// The method that will be called to execute the query. It should return the result of the query.
  T query(World world);
}
