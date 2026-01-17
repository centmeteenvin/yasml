import 'package:flutter/foundation.dart';
import 'package:yasml/src/logging.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/world/world.dart';

abstract base class SynchronousComposition<T> extends Composition<T> {
  @nonVirtual
  @override
  void execute(Composer composer, ValueChanged<T> setState, VoidCallback setSettled) {
    // here we do re-execute the compose function because it should be cheap
    // in the synchronous query we ommit it because we know the initial value is already the correct one
    compositionLog.fine('[SynchronousComposition-$key]: executing');
    final value = compose(composer);
    setState(value);

    compositionLog.finer('[SynchronousComposition-$key]: settled');
    setSettled();
  }

  @nonVirtual
  @override
  T initialValue(World world, Composer composer) {
    compositionLog.finer('[SynchronousComposition-$key]: executing composition for initialState');
    return compose(composer);
  }

  T compose(Composer composer);
}
