import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

abstract base class StreamQuery<T> extends Query<AsyncValue<T>> {
  const StreamQuery();

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

  const factory StreamQuery.create(
    Stream<T> Function(World world, VoidCallback setSettled) queryFn, {
    required String key,
  }) = StreamQueryFunction;
}

final class StreamQueryFunction<T> extends StreamQuery<T> {
  final Stream<T> Function(World world, VoidCallback setSettled) queryFn;

  @override
  final String key;

  const StreamQueryFunction(this.queryFn, {required this.key});

  @override
  Stream<T> query(World world, VoidCallback setSettled) => queryFn(world, setSettled);
}
