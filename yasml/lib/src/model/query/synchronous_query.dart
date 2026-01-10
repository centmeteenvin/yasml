import 'package:flutter/rendering.dart';
import 'package:yasml/src/logging.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/world/world.dart';

abstract base class SynchronousQuery<T> extends Query<T> {
  SynchronousQuery();

  @override
  T initialState(world) => query(world);

  @override
  void fetch(World world, ValueChanged<T> setState, VoidCallback settled) {
    queryLog.fine('[SynchronousQuery-$key] Fetching query');

    final state = query(world);

    queryLog.fine('[SynchronousQuery-$key] Query result: $state');
    setState(state);

    queryLog.finer('[SynchronousQuery-$key] Query settled');
    settled();
  }

  T query(World world);
}
