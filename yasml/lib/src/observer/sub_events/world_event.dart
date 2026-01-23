part of '../events.dart';

sealed class WorldEvent extends Event {
  WorldEvent() : super(componentName: 'world');
}

final class WorldCreatedEvent extends WorldEvent {
  WorldCreatedEvent();
}

final class WorldDestroyedEvent extends WorldEvent {
  WorldDestroyedEvent();
}

final class WorldSettledEvent extends WorldEvent {
  WorldSettledEvent();
}
