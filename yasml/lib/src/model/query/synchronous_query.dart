import 'package:flutter/rendering.dart';
import 'package:yasml/src/logging.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

abstract base class SynchronousQuery<T> extends Query<T> {
  SynchronousQuery();

  @override
  T initialState(world) {
    queryLog.fine('[SynchronousQuery-$key] Fetching query');
    return query(world);
  }

  @override
  CleanupFn fetch(World world, Option<T> currentState, ValueChanged<T> setState, VoidCallback settled) {
    queryLog.finer('[SynchronousQuery-$key] Query settled');
    if (currentState case OptionValue(:final value)) {
      setState(value);
    }
    settled();

    return () {};
  }

  T query(World world);
}
