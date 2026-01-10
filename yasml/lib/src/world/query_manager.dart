import 'package:yasml/src/logging.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/model/query/query_container.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/types/registry.dart';
import 'package:yasml/src/world/world.dart';

/// The query manager handles the instantiation of query containers and the invalidation
/// and settlings of those query containers.
abstract interface class QueryManager {
  void notifySettledChange();
  bool get allSettled;

  /// Creates a subscription and handles the query and composerContainers subscriptions
  QuerySubscription<T> subscribe<T>(Query<T> query, QueryReachable listeningContainer);
  void unsubscribe(QuerySubscription subscription);

  void invalidate(Set<Query> queries);
}

final class QueryManagerImpl implements QueryManager {
  QueryManagerImpl(this.world);
  final World world;

  final Registry<String, Query, QueryContainer> registry = Registry();

  Option<bool> previousSettledState = OptionEmpty();

  @override
  bool get allSettled => registry.items.every((container) => container.isSettled);

  /// Called by the queryContainer any time the query is settled
  /// If the settled state of the query manager changed the world will be notified.
  @override
  void notifySettledChange() {
    // The entire settled state is still the same
    if (previousSettledState case OptionValue(:final value) when value == allSettled) {
      queryManagerLog.finer('[QueryManager]: A query settled but not all queries are settled currently');
      return;
    }
    queryManagerLog.fine('[QueryManager]: settled: $allSettled');
    previousSettledState = OptionValue(allSettled);
    world.notifySettledChanged();
  }

  QueryContainer<T> get<T>(Query<T> query) {
    final option = registry.get(query);
    if (option case OptionValue(:QueryContainer<T> value)) {
      return value;
    }
    queryManagerLog.fine('[QueryManager]: Creating QueryContainer for ${query.key}');
    final container = QueryContainer(world: world, query: query);
    registry.register(query, container);
    return container;
  }

  void remove(Query query) {
    queryManagerLog.fine('[QueryManager]: Removing QueryContainer for ${query.key}');
    registry.unregister(query);
  }

  @override
  QuerySubscription<T> subscribe<T>(Query<T> query, QueryReachable listeningContainer) {
    queryManagerLog.fine('[QueryManager]: ${listeningContainer.runtimeType} subscribing to query ${query.key}');
    final queryContainer = get(query);
    final subscription = QuerySubscription(listeningContainer: listeningContainer, queryContainer: queryContainer);
    queryContainer.addListener(subscription);
    return subscription;
  }

  @override
  void unsubscribe(QuerySubscription subscription) {
    queryManagerLog.fine(
      '[QueryManager]: ${subscription.listeningContainer.runtimeType} unsubscribing from query ${subscription.queryContainer.query.key}',
    );
    subscription.queryContainer.removeListener(subscription);
    if (subscription.queryContainer.listeners.isEmpty) {
      queryManagerLog.fine(
        '[QueryManager]: ${subscription.queryContainer.query.key} has no listeners any more, disposing container',
      );
      // TODO dispose container
    }
  }

  @override
  void invalidate(Set<Query> queries) {
    if (queries.isEmpty) return;
    queryManagerLog.fine('Invalidating queries: ${queries.map((q) => q.key).join(', ')}');
    for (final query in queries) {
      final container = registry.get(query);
      if (container case OptionValue(value: final container)) {
        container.invalidate();
      }
    }
  }
}
