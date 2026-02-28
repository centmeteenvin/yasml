import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/future_query.dart';
import 'package:yasml/src/model/query/stream_query.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/world/world.dart';

/// an extension of [Composer] which additionally exposes methods for watching
/// [FutureQuery] and [StreamQuery] while conveniently expsosing there values as
/// Futures instead of [AsyncValue]s. It is used in the [AsyncComposition]
abstract interface class AsyncComposer implements Composer {
  /// returns with the value when the FutureQuery returns;
  Future<T> watchFuture<T>(FutureQuery<T> query);

  /// returns with the first value of the stream when settled
  Future<T> watchStream<T>(StreamQuery<T> query);
}

/// A [Composition] that is created for composing Queries that expose [AsyncValue]s, such as [FutureQuery] and [StreamQuery].
/// the [AsyncComposition.compose] method returns a Future while the Composition emits a single [AsyncValue] that represents the state of the Future,
/// which can be loading, error or data. It is used to easily compose multiple async queries' [AsyncValue]s together and manage their state in a single [AsyncValue].
abstract base class AsyncComposition<T> extends Composition<AsyncValue<T>> {
  /// @nodoc
  const AsyncComposition();

  /// An easier way to create an AsyncComposition from a simple function.
  /// It takes a function that receives the [AsyncComposer] and returns a Future with the composition result,
  /// and a key for the composition.
  const factory AsyncComposition.create(
    Future<T> Function(AsyncComposer composer) composeFn, {
    required String key,
  }) = AsyncCompositionFunction;

  @override
  AsyncValue<T> initialValue(World world, Composer composer) {
    return AsyncLoading();
  }

  @override
  void execute(covariant AsyncComposer composer, ValueChanged<AsyncValue<T>> setState, VoidCallback setSettled) {
    final future = compose(composer);
    unawaited(
      future
          .then((value) {
            setState(AsyncData(value));
          })
          .onError((error, stackTrace) {
            setState(AsyncError(error ?? Exception('unknown error'), stackTrace: stackTrace));
          })
          .whenComplete(() {
            setSettled();
          }),
    );
  }

  /// The method that will be called to execute the composition. It should return a Future that completes with the composition result.
  /// The [AsyncComposer] passed to the method can be used to watch [FutureQuery]s and [StreamQuery]s and get their values as Futures,
  /// which will automatically manage the state of the composition based on the state of the watched queries.
  Future<T> compose(AsyncComposer composer);
}

/// A simple implementation of an AsyncComposition that takes a function and a key
/// and executes the function to get the composition result.
final class AsyncCompositionFunction<T> extends AsyncComposition<T> {
  /// @nodoc
  const AsyncCompositionFunction(this.composeFn, {required this.key});

  /// The function that will be called to execute the composition.
  /// It should return a Future that completes with the composition result.
  final Future<T> Function(AsyncComposer composer) composeFn;

  @override
  final String key;

  @override
  Future<T> compose(AsyncComposer composer) => composeFn(composer);
}
