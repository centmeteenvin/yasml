import 'package:flutter/rendering.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

abstract base class SynchronousQuery<T> extends Query<T> {
  const SynchronousQuery();

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

  const factory SynchronousQuery.create(T Function(World world) queryFn, {required String key}) =
      SynchronousQueryFunction;
}

final class SynchronousQueryFunction<T> extends SynchronousQuery<T> {
  final T Function(World world) queryFn;
  @override
  final String key;

  const SynchronousQueryFunction(this.queryFn, {required this.key});

  @override
  T query(World world) => queryFn(world);
}
