/// Test suite for stream query execution
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yasml/yasml.dart';

import '../domain/models.dart';
import '../domain/queries.dart';
import '../helpers/event_validators.dart';
import '../helpers/mock_listener.dart';
import '../helpers/world_setup.dart';

void main() {
  group('Stream Query Execution', () {
    test('RankingsStreamQuery emits ranking data', () async {
      final (:world, :observer) = setupWorld();

      final listener = MockQueryListener();
      final subscription = world.queryManager.subscribe(RankingsStreamQuery(), listener);

      await world.settled;

      final asyncValue = subscription.queryContainer.state;
      expect(asyncValue.hasData, true);
      final state = (asyncValue as AsyncData<List<RankEntry>>).data;
      expect(state.length, 3);
      expect(state.first.playerName, 'Alice');
      expect(state[1].playerName, 'Bob');

      // Validate event sequence
      final validator = EventSequenceValidator(observer.events);

      // 1. QueryContainerCreatedEvent
      final createdEvent = validator.expectEvent<QueryContainerCreatedEvent>();
      QueryEventValidators.validateContainerCreated(createdEvent, key: 'Rankings', reason: 'New Listerner');

      // 2. QueryContainerNewListenerEvent
      final newListenerEvent = validator.expectEvent<QueryContainerNewListenerEvent>();
      QueryEventValidators.validateNewListener(newListenerEvent, key: 'Rankings', listenerType: MockQueryListener);

      // 3. QueryExecutedEvent
      final executedEvent = validator.expectEvent<QueryExecutedEvent>();
      QueryEventValidators.validateQueryExecuted(executedEvent, key: 'Rankings');

      // 4. QuerySettledEvent (called from setSettled in async* generator)
      final settledEvent = validator.skipToEvent<QuerySettledEvent>();
      QueryEventValidators.validateSettled(settledEvent, key: 'Rankings');

      // 5. QuerySetStateEvent (emitted when stream yields data, may be after settled)
      final setStateEvent = validator.skipToEvent<QuerySetStateEvent>();
      QueryEventValidators.validateSetState(
        setStateEvent,
        key: 'Rankings',
        stateValidator: (state) => AsyncValueValidators.isAsyncDataWith<List<RankEntry>>(
          state,
          (data) => data.length == 3 && data.first.playerName == 'Alice',
        ),
        reason: 'Rankings should be AsyncData with correct data',
      );

      // Cleanup
      world.queryManager.unsubscribe(subscription);

      // 6. QueryContainerListenerRemovedEvent
      final listenerRemovedEvent = validator.skipToEvent<QueryContainerListenerRemovedEvent>();
      QueryEventValidators.validateListenerRemoved(
        listenerRemovedEvent,
        key: 'Rankings',
        listenerType: MockQueryListener,
      );

      // 7. QueryContainerDisposedEvent
      final disposedEvent = validator.skipToEvent<QueryContainerDisposedEvent>();
      QueryEventValidators.validateContainerDisposed(disposedEvent, key: 'Rankings', reason: 'No Listeners');

      await world.destroy();
    });
  });
}
