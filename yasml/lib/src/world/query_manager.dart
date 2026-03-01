import 'dart:async';

import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/model/query/query_container.dart';
import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/types/registry.dart';
import 'package:yasml/src/world/world.dart';

/// The query manager handles the instantiation of query containers and the invalidation
/// and settlings of those query containers.
abstract interface class QueryManager {
  /// Should be called by a [QueryContainer] when it's settled
  /// state changes.
  void notifySettledChange();

  /// True when all active [Query]s are settled
  bool get allSettled;

  /// Subscribes a [QueryReachable] to a certain [Query] and returns
  /// with the query's initialState
  QuerySubscription<T> subscribe<T>(
    Query<T> query,
    QueryReachable listeningContainer,
  );

  /// Unsubscribes a [QueryReachable] from a certain [Query]. If the query
  /// has no more listeners after unsubscribing, the query will be disposed.
  void unsubscribe(QuerySubscription<dynamic> subscription);

  /// Invalidates the given [Query]s. If the [Query] still has listeners
  /// it will be re-executed.
  void invalidate(Set<Query<dynamic>> queries);

  /// Destroy all query containers
  Future<void> destroy();
}

/// The implementation of the [QueryManager]
final class QueryManagerImpl implements QueryManager {
  ///
  QueryManagerImpl(this.world);

  ///
  final WorldImpl world;

  /// A Registry that contains a dictionary of [Query] : [QueryContainer].
  final Registry<String, Query<dynamic>, QueryContainer<dynamic>> registry =
      Registry();

  /// Contains the previous value of [QueryManager.allSettled]
  ///
  /// Is used to reduce notifications sent to the [World]
  Option<bool> previousSettledState = OptionEmpty();

  @override
  bool get allSettled =>
      registry.items.every((container) => container.isSettled);

  /// Called by the queryContainer any time the query is settled
  /// If the settled state of the query manager changed the world will be notified.
  @override
  void notifySettledChange() {
    // The entire settled state is still the same
    if (previousSettledState case OptionValue(
      :final value,
    ) when value == allSettled) {
      return;
    }
    previousSettledState = OptionValue(allSettled);
    world.notifySettledChanged();
  }

  /// Fetch the container for the query, if it does not exist create it instead.
  QueryContainer<T> get<T>(Query<T> query) {
    final option = registry.get(query);
    if (option case OptionValue(:final QueryContainer<T> value)) {
      return value;
    }

    world.emit(
      QueryContainerCreatedEvent(queryKey: query.key, reason: 'New Listerner'),
    );
    final container = QueryContainer(world: world, query: query);
    registry.register(query, container);
    return container;
  }

  /// Delete the container of the query, if it was not present nothing happens
  void remove(Query<dynamic> query) {
    registry.unregister(query);
  }

  @override
  QuerySubscription<T> subscribe<T>(
    Query<T> query,
    QueryReachable listeningContainer,
  ) {
    final queryContainer = get(query);
    final subscription = QuerySubscription(
      listeningContainer: listeningContainer,
      queryContainer: queryContainer,
    );
    queryContainer.addListener(subscription);
    return subscription;
  }

  @override
  void unsubscribe(QuerySubscription<dynamic> subscription) {
    final container = subscription.queryContainer;

    container.removeListener(subscription);
    if (container.listeners.isEmpty) {
      world.emit(
        QueryContainerDisposedEvent(
          queryKey: container.query.key,
          reason: 'No Listeners',
        ),
      );
      unawaited(container.dispose());
      remove(container.query);
    }
  }

  @override
  void invalidate(Set<Query<dynamic>> queries) {
    if (queries.isEmpty) return;

    for (final query in queries) {
      final container = registry.get(query);
      if (container case OptionValue(value: final container)) {
        unawaited(container.invalidate());
      }
    }
  }

  @override
  Future<void> destroy() async {
    registry.items
        .expand(
          (container) => container.listeners.cast<QuerySubscription<dynamic>>(),
        )
        .toList()
        .forEach(unsubscribe);
  }
}
