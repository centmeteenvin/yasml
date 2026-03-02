/// World setup utilities for tests
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yasml/yasml.dart';

import 'test_observer.dart';

/// Creates a new world with observer for testing
/// Validates world creation was successful before returning
/// Returns a record with (world, observer) bound to this test
({World world, TestObserver observer}) setupWorld() {
  final observer = TestObserver();
  final world = World.create(plugins: [], observers: [observer]);

  // Validate world creation
  expect(
    observer.events.isNotEmpty,
    true,
    reason: 'World creation should emit events',
  );
  final worldCreatedEvents = observer.events.whereType<WorldCreatedEvent>().toList();
  expect(
    worldCreatedEvents.isNotEmpty,
    true,
    reason: 'World creation should emit WorldCreatedEvent',
  );

  // Clear events for test to focus on query-specific events
  observer.events.clear();

  return (world: world, observer: observer);
}
