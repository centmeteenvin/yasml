import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

/// A base class for queries that are based on a Stream. It handles the common logic of
/// managing the AsyncValue state and the cancellation of the Stream subscription when the query is invalidated
abstract base class StreamQuery<T> extends Query<AsyncValue<T>> {
  /// @nodoc
  const StreamQuery();

  /// An easier way to create a StreamQuery from a simple function.
  ///  It takes a function that receives the world and a callback to set the settled state
  ///  and returns a Stream with the query result,
  /// and a key for the query.
  const factory StreamQuery.create(
    Stream<T> Function(World world, VoidCallback setSettled) queryFn, {
    required String key,
  }) = StreamQueryFunction;

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

/// A simple implementation of a StreamQuery that takes a function and
/// a key and executes the function to get the query result.
final class StreamQueryFunction<T> extends StreamQuery<T> {
  /// @nodoc
  const StreamQueryFunction(this.queryFn, {required this.key});

  /// The function that will be called to execute the query.
  /// It should return a Stream that emits the query result.
  final Stream<T> Function(World world, VoidCallback setSettled) queryFn;

  @override
  final String key;

  @override
  Stream<T> query(World world, VoidCallback setSettled) =>
      queryFn(world, setSettled);
}
