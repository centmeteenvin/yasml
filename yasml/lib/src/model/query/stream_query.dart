import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

/// A base class for queries that are based on a Stream. It handles the common logic of
/// managing the AsyncValue state and the cancellation of the Stream subscription when the query is invalidated
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

  /// The method that will be called to execute the query. It should return a Stream that emits the query result.
  Stream<T> query(World world, VoidCallback setSettled);
}
