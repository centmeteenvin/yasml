import 'dart:async';

import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/world/world.dart';

/// A command mutates the state. Because of mutated state it is possible
/// That some queries become invalid. To reflect this an additional method
/// checks given the mutation result which queries must be invalidated
abstract interface class Command<T> {
  FutureOr<T> execute(World world);

  List<Query> invalidate(T result);
}
