/// Test suite for future query execution
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yasml/yasml.dart';

import '../domain/models.dart';
import '../domain/queries.dart';
import '../helpers/event_validators.dart';
import '../helpers/mock_listener.dart';
import '../helpers/world_setup.dart';

void main() {
  group('Future Query Execution', () {
    test('AchievementsQuery loads achievements asynchronously', () async {
      final (:world, :observer) = setupWorld();

      final listener = MockQueryListener();
      final subscription = world.queryManager.subscribe(AchievementsQuery(), listener);

      await world.settled;

      final asyncValue = subscription.queryContainer.state;
      expect(asyncValue.hasData, true);
      final state = (asyncValue as AsyncData<List<Achievement>>).data;
      expect(state.length, 4);
      expect(state.first.title, 'First Blood');
      expect(state.where((a) => a.unlocked).length, 2);

      // Validate event sequence
      final validator = EventSequenceValidator(observer.events);

      // 1. QueryContainerCreatedEvent
      final createdEvent = validator.expectEvent<QueryContainerCreatedEvent>();
      QueryEventValidators.validateContainerCreated(createdEvent, key: 'Achievements', reason: 'New Listerner');

      // 2. QueryContainerNewListenerEvent
      final newListenerEvent = validator.expectEvent<QueryContainerNewListenerEvent>();
      QueryEventValidators.validateNewListener(newListenerEvent, key: 'Achievements', listenerType: MockQueryListener);

      // 3. QueryExecutedEvent
      final executedEvent = validator.expectEvent<QueryExecutedEvent>();
      QueryEventValidators.validateQueryExecuted(executedEvent, key: 'Achievements');

      // 4. QuerySetStateEvent (should be AsyncData with achievements)
      final setStateEvent = validator.expectEvent<QuerySetStateEvent>();
      QueryEventValidators.validateSetState(
        setStateEvent,
        key: 'Achievements',
        stateValidator: (state) => AsyncValueValidators.isAsyncDataWith<List<Achievement>>(
          state,
          (data) => data.length == 4 && data.first.title == 'First Blood' && data.where((a) => a.unlocked).length == 2,
        ),
        reason: 'Achievements should be AsyncData with correct data and 2 unlocked',
      );

      // 5. QuerySettledEvent
      final settledEvent = validator.expectEvent<QuerySettledEvent>();
      QueryEventValidators.validateSettled(settledEvent, key: 'Achievements');

      // Cleanup
      world.queryManager.unsubscribe(subscription);

      // 6. QueryContainerListenerRemovedEvent
      final listenerRemovedEvent = validator.skipToEvent<QueryContainerListenerRemovedEvent>();
      QueryEventValidators.validateListenerRemoved(
        listenerRemovedEvent,
        key: 'Achievements',
        listenerType: MockQueryListener,
      );

      // 7. QueryContainerDisposedEvent
      final disposedEvent = validator.skipToEvent<QueryContainerDisposedEvent>();
      QueryEventValidators.validateContainerDisposed(disposedEvent, key: 'Achievements', reason: 'No Listeners');

      await world.destroy();
    });
  });
}
