import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/future_query.dart';
import 'package:yasml/src/model/query/stream_query.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/world/world.dart';

abstract interface class AsyncComposer implements Composer {
  /// returns with the value when the FutureQuery returns;
  Future<T> watchFuture<T>(FutureQuery<T> query);

  /// returns with the first value of the stream when settled
  Future<T> watchStream<T>(StreamQuery<T> query);
}

abstract base class AsyncComposition<T> extends Composition<AsyncValue<T>> {
  @override
  AsyncValue<T> initialValue(World world, Composer composer) {
    return AsyncLoading();
  }

  @override
  void execute(covariant AsyncComposer composer, ValueChanged<AsyncValue<T>> setState, VoidCallback setSettled) {
    final future = compose(composer);
    future
        .then((value) {
          setState(AsyncData(value));
        })
        .onError((error, stackTrace) {
          setState(AsyncError(error ?? Exception('unknown error'), stackTrace: stackTrace));
        })
        .whenComplete(() {
          setSettled();
        });
  }

  Future<T> compose(AsyncComposer composer);
}
