import 'package:flutter/rendering.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

/// A base class for queries that are based on a synchronous computation. It handles the common logic of
/// managing the state and the execution of the query when the query container is executed or invalidated
abstract base class SynchronousQuery<T> extends Query<T> {
  /// @nodoc
  const SynchronousQuery();

  /// An easier way to create a SynchronousQuery from a simple function.
  ///  It takes a function that receives the world and returns the query result,
  /// and a key for the query.
  const factory SynchronousQuery.create(
    T Function(World world) queryFn, {
    required String key,
  }) = SynchronousQueryFunction;
  @override
  T initialState(World world) {
    return query(world);
  }

  @override
  CleanupFn fetch(
    World world,
    Option<T> currentState,
    ValueChanged<T> setState,
    VoidCallback settled,
  ) {
    if (currentState case OptionValue(:final value)) {
      setState(value);
    }
    settled();

    return () {};
  }

  /// The method that will be called to execute the query. It should return the result of the query.
  T query(World world);
}

/// A simple implementation of a SynchronousQuery that takes a function and a key and executes the function to get the query result.
final class SynchronousQueryFunction<T> extends SynchronousQuery<T> {
  /// @nodoc
  const SynchronousQueryFunction(this.queryFn, {required this.key});

  /// The function that will be called to execute the query. It should return the result of the query.
  final T Function(World world) queryFn;
  @override
  final String key;

  @override
  T query(World world) => queryFn(world);
}
