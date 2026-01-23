import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

abstract base class StreamQuery<T> extends Query<AsyncValue<T>> {
  @override
  AsyncValue<T> initialState(World world) {
    return AsyncLoading();
  }

  @override
  CleanupFn fetch(
    World world,
    Option<AsyncValue<T>> currentState,
    ValueChanged<AsyncValue<T>> setState,
    VoidCallback settled,
  ) {
    final stream = query(world, settled);

    final subscription = stream.listen(
      cancelOnError: true,
      (event) {
        setState(AsyncData(event));
      },
      onError: (Object error, StackTrace stackTrace) {
        setState(AsyncError(error as Exception, stackTrace: stackTrace));
        settled();
      },
      onDone: () {},
    );

    return subscription.cancel;
  }

  Stream<T> query(World world, VoidCallback setSettled);
}
