import 'dart:async';
import 'dart:collection';

import 'package:yasml/src/model/query/query_container.dart';
import 'package:yasml/yasml.dart';

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
    mutationContainerLog.fine('[MutationContainer-$M]: Dispatching command ${command.runtimeType}');
    final result = await command.execute(world);

    final invalidQueries = command.invalidate(result);
    queriesToInvalidate.addAll(invalidQueries);

    mutationContainerLog.fine(
      '[MutationContainer-$M]: After Dispatching command ${command.runtimeType} the following queries are to be invalidated $invalidQueries',
    );
    return result;
  }

  @override
  Future<K> read<K>(Query<K> query) async {
    mutationContainerLog.finer('[MutationContainer-$M]: subcribing to query ${query.key}');
    final subscription = world.queryManager.subscribe(query, this);
    await subscription.queryContainer.settled;

    mutationContainerLog.fine('[MutationContainer-$M]: ${query.key} settled emitting value');

    final value = subscription.queryContainer.state;
    world.queryManager.unsubscribe(subscription);
    return value;
  }

  Future<R> runMutation<R>(MutationDefinition<M, R> mutationFn) async {
    mutationContainerLog.finer('[MutationContainer-$M]: Creating Mutation Object');
    final mutation = mutationConstructor(this);

    mutationContainerLog.fine('[MutationContainer-$M]: Running Mutation definition');
    final mutationResult = await mutationFn.call(mutation);
    mutationContainerLog.finer(
      '[MutationContainer-$M]: Mutation completed, following queries invalidated $queriesToInvalidate',
    );
    world.queryManager.invalidate(queriesToInvalidate);

    await world.settled;
    mutationLog.fine('[MutationContainer-$M]: Mutation completed, world settled');

    return mutationResult;
  }

  @override
  void notify() {
    // We don't actually have to rerun anything as we already asynchronously await the settled to indentify the running
    // of the query
  }
}
