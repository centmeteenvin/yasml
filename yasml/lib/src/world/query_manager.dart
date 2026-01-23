import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/model/query/query_container.dart';
import 'package:yasml/src/observer/events.dart';
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

  /// Destroy all query containers
  Future<void> destroy();
}

final class QueryManagerImpl implements QueryManager {
  QueryManagerImpl(this.world);
  final WorldImpl world;

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
      return;
    }
    previousSettledState = OptionValue(allSettled);
    world.notifySettledChanged();
  }

  QueryContainer<T> get<T>(Query<T> query) {
    final option = registry.get(query);
    if (option case OptionValue(:QueryContainer<T> value)) {
      return value;
    }

    world.emit(QueryContainerCreatedEvent(queryKey: query.key, reason: 'New Listerner'));
    final container = QueryContainer(world: world, query: query);
    registry.register(query, container);
    return container;
  }

  void remove(Query query) {
    registry.unregister(query);
  }

  @override
  QuerySubscription<T> subscribe<T>(Query<T> query, QueryReachable listeningContainer) {
    final queryContainer = get(query);
    final subscription = QuerySubscription(listeningContainer: listeningContainer, queryContainer: queryContainer);
    queryContainer.addListener(subscription);
    return subscription;
  }

  @override
  void unsubscribe(QuerySubscription subscription) {
    final container = subscription.queryContainer;
    container.removeListener(subscription);
    if (container.listeners.isEmpty) {
      world.emit(QueryContainerDisposedEvent(queryKey: container.query.key, reason: 'No Listeners'));
      container.dispose();
      remove(container.query);
    }
  }

  @override
  void invalidate(Set<Query> queries) {
    if (queries.isEmpty) return;

    for (final query in queries) {
      final container = registry.get(query);
      if (container case OptionValue(value: final container)) {
        container.invalidate();
      }
    }
  }

  @override
  Future<void> destroy() async {
    registry.items
        .expand((container) => container.listeners.cast<QuerySubscription>())
        .toList()
        .forEach(unsubscribe);
  }
}
