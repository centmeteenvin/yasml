part of '../events.dart';

/// Events related to the lifecycle of the world. These events are emitted when the world is created, destroyed or settled.
sealed class WorldEvent extends Event {
  WorldEvent() : super(componentName: 'world');
}

/// specific event for the creation of the world. It is emitted when a new world is created.
final class WorldCreatedEvent extends WorldEvent {
  /// @nodoc
  WorldCreatedEvent();
}

/// specific event for the destruction of the world. It is emitted when the world is destroyed, for example, when the app is killed.
final class WorldDestroyedEvent extends WorldEvent {
  /// @nodoc
  WorldDestroyedEvent();
}

/// specific event for the settling of the world. The world is considered settled when it has finished processing
///  all the pending commands, queries, etc., and its state is stable.
final class WorldSettledEvent extends WorldEvent {
  /// @nodoc
  WorldSettledEvent();
}
