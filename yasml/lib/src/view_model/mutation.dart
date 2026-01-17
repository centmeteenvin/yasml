import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/view_model/mutation_container.dart';

typedef MutationConstructor<M extends Mutation> = M Function(Commander commander);

typedef MutationDefinition<M extends Mutation, R> = FutureOr<R> Function(M mutation);

typedef MutationRunner<M extends Mutation> = Future<R> Function<R>(MutationDefinition<M, R> definition);

/// Extend this method and define all valid
/// mutations for the given Composition
@immutable
abstract base class Mutation<C extends Composition> {
  const Mutation({required this.commander});
  final Commander commander;
}
