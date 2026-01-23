import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

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
    completerOperation.value
        .then((value) {
          setState(AsyncData(value));
        })
        .onError((error, stackTrace) {
          setState(AsyncError(error as Exception, stackTrace: stackTrace));
        })
        .whenComplete(() {
          settled();
        });

    return completerOperation.cancel;
  }

  Future<T> query(World world);
}
