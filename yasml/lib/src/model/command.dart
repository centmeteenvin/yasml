import 'dart:async';

import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/view_model/mutation_container.dart';
import 'package:yasml/src/world/world.dart';

/// A command mutates the state. Because of mutated state it is possible
/// That some queries become invalid. To reflect this an additional method
/// checks given the mutation result which queries must be invalidated
abstract interface class Command<T> {
  /// An easier way to create a [Command] from simple functions.
  /// It takes an [executeFn] that receives the [World] and performs the mutation,
  /// and an [invalidateFn] that returns the list of [Query] to invalidate.
  const factory Command.create(
    FutureOr<T> Function(World world) executeFn,
    List<Query<dynamic>> Function(T result) invalidateFn,
  ) = CommandFunction<T>;

  /// The function that is called when the [Command] is dispatched
  /// by a [Commander]
  FutureOr<T> execute(World world);

  /// Returns the a list of [Query] that are invalid.
  /// This will mark the [Query] as stale and the next is needed it will be
  /// re-executed
  List<Query<dynamic>> invalidate(T result);
}

/// A simple implementation of a [Command] that takes functions for [execute] and [invalidate].
final class CommandFunction<T> implements Command<T> {
  /// @nodoc
  const CommandFunction(this.executeFn, this.invalidateFn);

  /// The function that will be called to execute the command.
  final FutureOr<T> Function(World world) executeFn;

  /// The function that returns which queries to invalidate after execution.
  final List<Query<dynamic>> Function(T result) invalidateFn;

  @override
  FutureOr<T> execute(World world) => executeFn(world);

  @override
  List<Query<dynamic>> invalidate(T result) => invalidateFn(result);
}
