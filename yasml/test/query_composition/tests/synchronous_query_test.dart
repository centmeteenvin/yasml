/// Test suite for synchronous query execution
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yasml/src/observer/events.dart';

import '../domain/queries.dart';
import '../helpers/event_validators.dart';
import '../helpers/mock_listener.dart';
import '../helpers/world_setup.dart';

void main() {
  group('Synchronous Query Execution', () {
    test('PlayerStatsQuery executes and returns stats', () async {
      final (:world, :observer) = setupWorld();

      final listener = MockQueryListener();
      final subscription = world.queryManager.subscribe(PlayerStatsQuery(), listener);

      await world.settled;

      final state = subscription.queryContainer.state;
      expect(state.playerId, 'player_123');
      expect(state.wins, 15);
      expect(state.level, 5);

      // Validate event sequence
      final validator = EventSequenceValidator(observer.events);

      // 1. QueryContainerCreatedEvent
      final createdEvent = validator.expectEvent<QueryContainerCreatedEvent>();
      QueryEventValidators.validateContainerCreated(createdEvent,
          key: 'PlayerStats', reason: 'New Listerner');

      // 2. QueryContainerNewListenerEvent
      final newListenerEvent = validator.expectEvent<QueryContainerNewListenerEvent>();
      QueryEventValidators.validateNewListener(newListenerEvent,
          key: 'PlayerStats', listenerType: MockQueryListener);

      // 3. QueryExecutedEvent
      final executedEvent = validator.expectEvent<QueryExecutedEvent>();
      QueryEventValidators.validateQueryExecuted(executedEvent, key: 'PlayerStats');

      // 4. QuerySettledEvent (no SetStateEvent for sync queries on initial execution)
      final settledEvent = validator.expectEvent<QuerySettledEvent>();
      QueryEventValidators.validateSettled(settledEvent, key: 'PlayerStats');

      // Cleanup
      world.queryManager.unsubscribe(subscription);

      // 5. QueryContainerListenerRemovedEvent
      final listenerRemovedEvent = validator.skipToEvent<QueryContainerListenerRemovedEvent>();
      QueryEventValidators.validateListenerRemoved(listenerRemovedEvent,
          key: 'PlayerStats', listenerType: MockQueryListener);

      // 6. QueryContainerDisposedEvent
      final disposedEvent = validator.skipToEvent<QueryContainerDisposedEvent>();
      QueryEventValidators.validateContainerDisposed(disposedEvent,
          key: 'PlayerStats', reason: 'No Listeners');

      await world.destroy();
    });
  });
}
