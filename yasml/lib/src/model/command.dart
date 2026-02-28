import 'dart:async';

import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/view_model/mutation_container.dart';
import 'package:yasml/src/world/world.dart';

/// A command mutates the state. Because of mutated state it is possible
/// That some queries become invalid. To reflect this an additional method
/// checks given the mutation result which queries must be invalidated
abstract interface class Command<T> {
  /// The function that is called when the [Command] is dispatched
  /// by a [Commander]
  FutureOr<T> execute(World world);

  /// Returns the a list of [Query] that are invalid.
  /// This will mark the [Query] as stale and the next is needed it will be
  /// re-executed
  List<Query<dynamic>> invalidate(T result);
}
