/// Event validation utilities for testing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yasml/yasml.dart';

/// Validates event sequences and properties
class EventSequenceValidator {
  final List<Event> events;
  int _currentIndex = 0;

  EventSequenceValidator(this.events);

  /// Gets the current event without advancing
  Event get current => events[_currentIndex];

  /// Gets remaining events
  List<Event> get remaining => events.skip(_currentIndex).toList();

  /// Validates the next event is of type T
  T expectEvent<T extends Event>() {
    expect(_currentIndex < events.length, true, reason: 'Expected event of type $T but no more events available');
    final event = events[_currentIndex];
    expect(event, isA<T>(), reason: 'Expected $T but got ${event.runtimeType}');
    _currentIndex++;
    return event as T;
  }

  /// Validates the next event of type T matches the predicate
  T expectEventWhere<T extends Event>(bool Function(T) predicate, [String? reason]) {
    final event = expectEvent<T>();
    expect(predicate(event), true, reason: reason ?? 'Event predicate failed for $event');
    return event;
  }

  /// Skips events until finding one of type T
  T skipToEvent<T extends Event>() {
    while (_currentIndex < events.length) {
      final event = events[_currentIndex];
      if (event is T) {
        _currentIndex++;
        return event;
      }
      _currentIndex++;
    }
    fail('Expected to find event of type $T but reached end of events');
  }

  /// Verifies no more events remain
  void expectNoMoreEvents() {
    expect(
      _currentIndex,
      events.length,
      reason: 'Expected no more events but found ${remaining.length} remaining: $remaining',
    );
  }

  /// Gets all events of type T
  List<T> getAllEvents<T extends Event>() {
    return events.whereType<T>().toList();
  }

  /// Resets the validator to the beginning
  void reset() {
    _currentIndex = 0;
  }
}

/// Validators for query-specific events
class QueryEventValidators {
  /// Validates QueryContainerCreatedEvent properties
  static void validateContainerCreated(
    QueryContainerCreatedEvent event, {
    required String key,
    required String reason,
  }) {
    expect(event.queryKey, key, reason: 'QueryContainerCreatedEvent key mismatch');
    expect(event.reason, reason, reason: 'QueryContainerCreatedEvent reason mismatch');
  }

  /// Validates QueryContainerNewListenerEvent properties
  static void validateNewListener(
    QueryContainerNewListenerEvent event, {
    required String key,
    required Type listenerType,
  }) {
    expect(event.queryKey, key, reason: 'QueryContainerNewListenerEvent key mismatch');
    expect(event.queryListenableType, listenerType, reason: 'QueryContainerNewListenerEvent listener type mismatch');
  }

  /// Validates QueryExecutedEvent properties
  static void validateQueryExecuted(QueryExecutedEvent event, {required String key}) {
    expect(event.queryKey, key, reason: 'QueryExecutedEvent key mismatch');
  }

  /// Validates QuerySetStateEvent properties
  static void validateSetState(
    QuerySetStateEvent event, {
    required String key,
    required bool Function(dynamic) stateValidator,
    String? reason,
  }) {
    expect(event.queryKey, key, reason: 'QuerySetStateEvent key mismatch');
    expect(stateValidator(event.newState), true, reason: reason ?? 'QuerySetStateEvent state validation failed');
  }

  /// Validates QuerySettledEvent properties
  static void validateSettled(QuerySettledEvent event, {required String key}) {
    expect(event.queryKey, key, reason: 'QuerySettledEvent key mismatch');
  }

  /// Validates QueryContainerListenerRemovedEvent properties
  static void validateListenerRemoved(
    QueryContainerListenerRemovedEvent event, {
    required String key,
    required Type listenerType,
  }) {
    expect(event.queryKey, key, reason: 'QueryContainerListenerRemovedEvent key mismatch');
    expect(
      event.queryListenableType,
      listenerType,
      reason: 'QueryContainerListenerRemovedEvent listener type mismatch',
    );
  }

  /// Validates QueryContainerDisposedEvent properties
  static void validateContainerDisposed(
    QueryContainerDisposedEvent event, {
    required String key,
    required String reason,
  }) {
    expect(event.queryKey, key, reason: 'QueryContainerDisposedEvent key mismatch');
    expect(event.reason, reason, reason: 'QueryContainerDisposedEvent reason mismatch');
  }
}

/// Helper validators for AsyncValue states
class AsyncValueValidators {
  /// Checks if state is AsyncLoading
  static bool isAsyncLoading(dynamic state) {
    return state is AsyncLoading;
  }

  /// Checks if state is AsyncData
  static bool isAsyncData(dynamic state) {
    return state is AsyncData;
  }

  /// Checks if state is AsyncError
  static bool isAsyncError(dynamic state) {
    return state is AsyncError;
  }

  /// Checks if state is AsyncData with data matching predicate
  static bool isAsyncDataWith<T>(dynamic state, bool Function(T) predicate) {
    if (state is! AsyncData<T>) return false;
    return predicate(state.data);
  }
}
