import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:yasml/src/model/command.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/view_model/mutation_container.dart';

/// A function that creates a [Mutation] from a [Commander]
typedef MutationConstructor<M extends Mutation> =
    M Function(Commander commander);

/// A user defined function that uses an instance [Mutation] to return [R].
typedef MutationDefinition<M extends Mutation, R> =
    FutureOr<R> Function(M mutation);

/// A function that sets up the context so that the passed [MutationDefinition] can be ran.
typedef MutationRunner<M extends Mutation> =
    Future<R> Function<R>(MutationDefinition<M, R> definition);

/// The base class that defines all [Mutation]s for a certain [Composition]
///
/// Extend this class to define the mutation contracts that exist for the [Composition]
/// The Methods should utilize the [Commander] to read [Query]s or dispatch [Command]s.
@immutable
abstract base class Mutation<C extends Composition<dynamic>> {
  /// The default constructor of a [Mutation]. Instantiates the [Mutation.commander] field.
  const Mutation({required this.commander});

  /// The [Commander] can be used to
  /// - Read a [Query]
  /// - Dispatch a [Command]
  final Commander commander;
}
