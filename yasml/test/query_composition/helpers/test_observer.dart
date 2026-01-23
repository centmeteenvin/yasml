/// Test observer for capturing events
library;

import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/observer/observer.dart';
import 'package:yasml/yasml.dart';

/// Captures all events emitted by the world for testing
class TestObserver implements Observer {
  final List<Event> events = [];

  @override
  void onInit(World world) {}

  @override
  Future<void> onDispose() async {}

  @override
  void onEvent(Event event) {
    events.add(event);
  }

  /// Clears all recorded events
  void clear() => events.clear();

  /// Gets all events of a specific type
  List<T> getEventsOfType<T extends Event>() {
    return events.whereType<T>().toList();
  }
}
