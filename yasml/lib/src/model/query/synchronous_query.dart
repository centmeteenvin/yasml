import 'package:flutter/rendering.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

abstract base class SynchronousQuery<T> extends Query<T> {
  SynchronousQuery();

  @override
  T initialState(world) {
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

  T query(World world);
}
