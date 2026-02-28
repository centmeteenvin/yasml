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
