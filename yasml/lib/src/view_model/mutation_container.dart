import 'dart:async';
import 'dart:collection';

import 'package:yasml/src/model/command.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/model/query/query_container.dart';
import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/view_model/mutation.dart';
import 'package:yasml/src/world/world.dart';

/// The [Commander] is the de-facto way to interract with
/// [Query] and [Command] from a [Mutation] method. It can be used to:
/// - Read a [Query] with [Commander.read]
/// - Dispatch a [Command] with [Commander.dispatch]
abstract interface class Commander {
  /// Read the value of a [Query]
  /// If the [Query] has not yet been executed it will be ran here.
  ///
  /// Returns a Future that completes with the first query state after it has
  /// settled.
  Future<T> read<T>(Query<T> query);

  /// Execute the given [Command].
  /// After successfull execution it runs the [Command.invalidate] method
  /// and collects all [Query] that need to be invalidated and stores them in
  /// the [Mutation] context.
  Future<T> dispatch<T>(Command<T> command);
}

/// The runtime of a [Mutation]. Handles the lifecycle of running a mutation by handling the
/// dispatching of commands while collecting their queries they would invalidate. Then after the user code
/// the queries will be invalidated and await the settling of the world.
final class MutationContainer<M extends Mutation>
    implements Commander, QueryReachable {
  ///
  MutationContainer({required this.world, required this.mutationConstructor});

  /// The [World] where the [Mutation] runs in.
  final World world;

  /// A Function that can take a [Commander] and returns a user defined [Mutation]
  final MutationConstructor<M> mutationConstructor;

  /// A growing set of [Query] that remember which are queries are to be invalidated
  /// When dispatching a [Command].
  final Set<Query<dynamic>> queriesToInvalidate = HashSet();

  @override
  Future<K> dispatch<K>(Command<K> command) async {
    world
      ..emit(
        MutationCommandDispatchedEvent(
          mutationType: M,
          commandType: command.runtimeType,
        ),
      )
      ..emit(CommandExecutedEvent(commandType: command.runtimeType));
    final result = await command.execute(world);

    final invalidQueries = command.invalidate(result);
    queriesToInvalidate.addAll(invalidQueries);

    world.emit(
      CommandQueryInvalidationEvent(
        commandType: command.runtimeType,
        queriesToInvalidate: queriesToInvalidate,
      ),
    );
    return result;
  }

  @override
  Future<K> read<K>(Query<K> query) async {
    final subscription = world.queryManager.subscribe(query, this);
    await subscription.queryContainer.settled;

    final value = subscription.queryContainer.state;
    world.queryManager.unsubscribe(subscription);

    world.emit(
      MutationQueryReadEvent(
        mutationType: M,
        queryKey: query.key,
        queryState: value,
      ),
    );
    return value;
  }

  /// The user suplies a function that uses the [Mutation] to run some code related to a [Composition]
  /// Then we create an instance of the [Mutation] which we pass to the user supplied [mutationFn].
  /// Then the result is awaited followed by the invalidation of [Query]'s.
  ///
  /// Returns a Future that completes with the result [R] of [mutationFn] after the [World] is settled.
  Future<R> runMutation<R>(MutationDefinition<M, R> mutationFn) async {
    world.emit(MutationContainerCreatedEvent(mutationType: M));
    final mutation = mutationConstructor(this);

    world.emit(MutationExecutedEvent(mutationType: M));
    final mutationResult = await mutationFn.call(mutation);

    world.emit(
      MutationInvalidationEvent(
        mutationType: M,
        queriesToInvalidate: queriesToInvalidate,
      ),
    );
    world.queryManager.invalidate(queriesToInvalidate);

    await world.settled;

    return mutationResult;
  }

  @override
  void notify() {
    // We don't actually have to rerun anything as we already asynchronously await the settled to indentify the running
    // of the query
  }
}
