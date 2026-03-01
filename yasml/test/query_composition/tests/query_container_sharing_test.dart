/// Test suite for query container sharing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yasml/src/observer/events.dart';

import '../domain/queries.dart';
import '../helpers/mock_listener.dart';
import '../helpers/world_setup.dart';

void main() {
  group('Query Container Sharing', () {
    test('Identical queries share the same container', () async {
      final (:world, :observer) = setupWorld();

      observer.events.clear();

      // Phase 1: First subscription to RankingsStreamQuery
      final sub1 = world.queryManager.subscribe(
        RankingsStreamQuery(),
        MockQueryListener(),
      );
      await world.settled;

      final createdCount1 =
          observer.events
              .whereType<QueryContainerCreatedEvent>()
              .where((e) => e.queryKey == 'Rankings')
              .length;

      expect(createdCount1, 1, reason: 'First subscription creates the query');

      observer.events.clear();

      // Phase 2: Second subscription to identical query
      final sub2 = world.queryManager.subscribe(
        RankingsStreamQuery(),
        MockQueryListener(),
      );

      final createdCount2 =
          observer.events
              .whereType<QueryContainerCreatedEvent>()
              .where((e) => e.queryKey == 'Rankings')
              .length;

      expect(
        createdCount2,
        0,
        reason: 'Second subscription reuses the container (0 new created)',
      );

      // Both subscriptions share the same container
      expect(
        sub1.queryContainer,
        same(sub2.queryContainer),
        reason: 'Identical queries should share the same container',
      );

      // Same data accessible from both
      expect(
        sub1.queryContainer.state,
        equals(sub2.queryContainer.state),
        reason: 'Both subscriptions see the same query state',
      );

      observer.events.clear();

      // Phase 3: Cleanup
      world.queryManager.unsubscribe(sub1);

      // Should see one ListenerRemoved event but NO disposal yet
      final firstUnsubEventCount =
          observer.events
              .whereType<QueryContainerListenerRemovedEvent>()
              .where((e) => e.queryKey == 'Rankings')
              .length;

      final firstDisposeEventCount =
          observer.events
              .whereType<QueryContainerDisposedEvent>()
              .where((e) => e.queryKey == 'Rankings')
              .length;

      expect(
        firstUnsubEventCount,
        1,
        reason: 'First unsubscribe removes a listener',
      );
      expect(
        firstDisposeEventCount,
        0,
        reason: 'Container should not dispose while second listener exists',
      );

      observer.events.clear();

      // Second unsubscribe should dispose
      world.queryManager.unsubscribe(sub2);

      final secondUnsubEventCount =
          observer.events
              .whereType<QueryContainerListenerRemovedEvent>()
              .where((e) => e.queryKey == 'Rankings')
              .length;

      final secondDisposeEventCount =
          observer.events
              .whereType<QueryContainerDisposedEvent>()
              .where((e) => e.queryKey == 'Rankings')
              .length;

      expect(
        secondUnsubEventCount,
        1,
        reason: 'Second unsubscribe removes the last listener',
      );
      expect(
        secondDisposeEventCount,
        1,
        reason: 'Container should dispose after last listener is removed',
      );

      await world.destroy();
    });
  });
}
