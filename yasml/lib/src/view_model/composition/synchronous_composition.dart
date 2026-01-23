import 'package:flutter/foundation.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/world/world.dart';

abstract base class SynchronousComposition<T> extends Composition<T> {
  @nonVirtual
  @override
  void execute(Composer composer, ValueChanged<T> setState, VoidCallback setSettled) {
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

  T compose(Composer composer);
}
