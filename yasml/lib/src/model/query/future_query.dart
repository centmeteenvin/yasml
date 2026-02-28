import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

/// A base class for queries that are based on a Future. It handles the common logic of
/// managing the AsyncValue state and the cancellation of the Future when the query is invalidated.
abstract base class FutureQuery<T> extends Query<AsyncValue<T>> {
  /// @nodoc
  const FutureQuery();

  /// An easier way to create a FutureQuery from a simple function.
  ///  It takes a function that receives the world and returns a Future with the query result,
  /// and a key for the query.
  const factory FutureQuery.create(Future<T> Function(World world) queryFn, {required String key}) =
      FutureQueryFunction;

  @override
  AsyncValue<T> initialState(World world) => AsyncLoading();

  @override
  CleanupFn fetch(
    World world,
    Option<AsyncValue<T>> currentState,
    ValueChanged<AsyncValue<T>> setState,
    VoidCallback settled,
  ) {
    final fetchFuture = query(world);

    final completerOperation = CancelableOperation.fromFuture(fetchFuture);
    unawaited(
      completerOperation.value
          .then((value) {
            setState(AsyncData(value));
          })
          .onError((error, stackTrace) {
            setState(AsyncError(error as Exception? ?? Exception('Unknown error'), stackTrace: stackTrace));
          })
          .whenComplete(() {
            settled();
          }),
    );

    return completerOperation.cancel;
  }

  /// The method that will be called to execute the query. It should return a Future that completes with the query result.
  Future<T> query(World world);
}

/// A simple implementation of a FutureQuery that takes a function and a key
///  and executes the function to get the query result.
final class FutureQueryFunction<T> extends FutureQuery<T> {
  /// @nodoc
  const FutureQueryFunction(this.queryFn, {required this.key});

  /// The function that will be called to execute the query.
  /// It should return a Future that completes with the query result.
  final Future<T> Function(World world) queryFn;

  @override
  final String key;

  @override
  Future<T> query(World world) => queryFn(world);
}
