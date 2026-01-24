import 'dart:async';
import 'dart:collection';

import 'package:yasml/src/model/command.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/model/query/query_container.dart';
import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/view_model/mutation.dart';
import 'package:yasml/src/world/world.dart';

abstract interface class Commander {
  /// Read the current state of a given query
  Future<T> read<T>(Query<T> query);

  /// Execute the command, return the result
  /// and records the query invalidations
  Future<T> dispatch<T>(Command<T> command);
}

final class MutationContainer<M extends Mutation> implements Commander, QueryReachable {
  final World world;

  final MutationConstructor<M> mutationConstructor;

  MutationContainer({required this.world, required this.mutationConstructor});

  final Set<Query> queriesToInvalidate = HashSet();

  @override
  Future<K> dispatch<K>(Command<K> command) async {
    world.emit(MutationCommandDispatchedEvent(mutationType: M, commandType: command.runtimeType));
    world.emit(CommandExecutedEvent(commandType: command.runtimeType));
    final result = await command.execute(world);

    final invalidQueries = command.invalidate(result);
    queriesToInvalidate.addAll(invalidQueries);

    world.emit(
      CommandQueryInvalidationEvent(commandType: command.runtimeType, queriesToInvalidate: queriesToInvalidate),
    );
    return result;
  }

  @override
  Future<K> read<K>(Query<K> query) async {
    final subscription = world.queryManager.subscribe(query, this);
    await subscription.queryContainer.settled;

    final value = subscription.queryContainer.state;
    world.queryManager.unsubscribe(subscription);

    world.emit(MutationQueryReadEvent(mutationType: M, queryKey: query.key, queryState: value));
    return value;
  }

  Future<R> runMutation<R>(MutationDefinition<M, R> mutationFn) async {
    world.emit(MutationContainerCreatedEvent(mutationType: M));
    final mutation = mutationConstructor(this);

    world.emit(MutationExecutedEvent(mutationType: M));
    final mutationResult = await mutationFn.call(mutation);

    world.emit(MutationInvalidationEvent(mutationType: M, queriesToInvalidate: queriesToInvalidate));
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
