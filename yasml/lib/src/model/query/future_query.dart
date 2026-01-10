import 'package:flutter/rendering.dart';
import 'package:yasml/src/logging.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/world/world.dart';

abstract base class FutureQuery<T, E> extends Query<AsyncValue<T, E>> {
  @override
  AsyncValue<T, E> initialState(World world) => AsyncLoading();

  @override
  void fetch(World world, ValueChanged<AsyncValue<T, E>> setState, VoidCallback settled) {
    queryLog.fine('[FutureQuery-$key] Fetching');
    query(world)
        .then((value) {
          queryLog.fine('[FutureQuery-$key] Query result: $value');
          setState(AsyncData(value));
        })
        .onError((error, stackTrace) {
          queryLog.warning('[FutureQuery-$key] Query error', error, stackTrace);
          setState(AsyncError(parseException(error), stackTrace: stackTrace));
        })
        .whenComplete(() {
          queryLog.finer('[FutureQuery-$key] Query settled');
          settled();
        });
  }

  Future<T> query(World world);
  E parseException(Object? exception);
}
