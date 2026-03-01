import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/view_model/composition/async_composition.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/world/world.dart';

/// A base class for compositions that are based on a synchronous computation. It handles the common logic of
/// managing the state and the execution of the composition when the composition container is executed or invalidated
abstract base class SynchronousComposition<T> extends Composition<T> {
  /// @nodoc
  const SynchronousComposition();

  /// An easier way to create a SynchronousComposition from a simple function.
  /// It takes a function that receives the [Composer] and returns the composition result,
  /// and a key for the composition.
  const factory SynchronousComposition.create(
    T Function(Composer composer) composeFn, {
    required String key,
  }) = SynchronousCompositionFunction;
  @nonVirtual
  @override
  void execute(
    Composer composer,
    ValueChanged<T> setState,
    VoidCallback setSettled,
  ) {
    // here we do re-execute the compose function because it should be cheap
    // in the synchronous query we ommit it because we know the initial value is already the correct one
    final value = compose(composer);
    setState(value);

    setSettled();
  }

  @nonVirtual
  @override
  T initialValue(World world, Composer composer) {
    return compose(composer);
  }

  /// The method that will be called to execute the composition. It should return the result of the composition.
  /// The [Composer] passed to the method can be used to watch [Query]s and get their values,
  ///
  /// If you want to access async [Query]s in your composition, you can use the [AsyncComposition] instead,
  ///  which will automatically manage the state of the composition based on the state of the watched async queries.
  T compose(Composer composer);
}

/// A simple implementation of a SynchronousComposition that takes a function and a key
/// and executes the function to get the composition result.
final class SynchronousCompositionFunction<T>
    extends SynchronousComposition<T> {
  /// @nodoc
  const SynchronousCompositionFunction(this.composeFn, {required this.key});

  /// The function that will be called to execute the composition.
  /// It should return the result of the composition.
  final T Function(Composer composer) composeFn;

  @override
  final String key;

  @override
  T compose(Composer composer) => composeFn(composer);
}
