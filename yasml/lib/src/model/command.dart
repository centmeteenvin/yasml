import 'dart:async';

import 'package:yasml/src/model/query/query.dart';

/// A command mutates the state. Because of mutated state it is possible
/// That some queries become invalid. To reflect this an additional method
/// checks given the mutation result which queries must be invalidated
abstract interface class Command<T> {
  FutureOr<T> execute();

  List<Query> invalidate(T result);
}
