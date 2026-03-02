/// Test suite for multiple query composition and reuse
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yasml/src/observer/events.dart';

import '../domain/queries.dart';
import '../helpers/mock_listener.dart';
import '../helpers/world_setup.dart';

void main() {
  group('Multiple Query Composition', () {
    test('Multiple query types can be combined and reused', () async {
      final (:world, :observer) = setupWorld();

      observer.events.clear();

      // Phase 1: First set of subscriptions - simulate "View 1" using all 3 queries
      final sub1Stats = world.queryManager.subscribe(
        PlayerStatsQuery(),
        MockQueryListener(),
      );
      final sub1Rankings = world.queryManager.subscribe(
        RankingsStreamQuery(),
        MockQueryListener(),
      );
      final sub1Achievements = world.queryManager.subscribe(
        AchievementsQuery(),
        MockQueryListener(),
      );

      await world.settled;

      // Count queries created so far
      final createdCount = observer.events.whereType<QueryContainerCreatedEvent>().length;
      expect(createdCount, 3, reason: 'First view creates 3 unique queries');

      observer.events.clear();

      // Phase 2: Second set of subscriptions - "View 2" reuses rankings and achievements
      final sub2Rankings = world.queryManager.subscribe(
        RankingsStreamQuery(),
        MockQueryListener(),
      );
      final sub2Achievements = world.queryManager.subscribe(
        AchievementsQuery(),
        MockQueryListener(),
      );

      // No new queries should be created!
      final newCreatedEvents = observer.events.whereType<QueryContainerCreatedEvent>().toList();

      expect(
        newCreatedEvents.isEmpty,
        true,
        reason: 'Second view should reuse existing queries (0 new queries created)',
      );

      // Verify they're using the same containers
      expect(
        sub1Rankings.queryContainer,
        same(sub2Rankings.queryContainer),
        reason: 'Both views should share the same RankingsStreamQuery container',
      );

      expect(
        sub1Achievements.queryContainer,
        same(sub2Achievements.queryContainer),
        reason: 'Both views should share the same AchievementsQuery container',
      );

      // Verify data is correct
      final stats = sub1Stats.queryContainer.state;
      expect(stats.playerId, 'player_123');

      await world.destroy();
    });
  });
}
