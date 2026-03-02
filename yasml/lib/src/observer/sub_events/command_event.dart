part of '../events.dart';

/// All events associated with [Command]
sealed class CommandEvent extends Event {
  CommandEvent({required this.commandType}) : super(componentName: 'Command - $commandType');

  /// The type of the command that generated the event
  final Type commandType;
}

/// Event when the [Command.execute] method is called
final class CommandExecutedEvent extends CommandEvent {
  @internal
  ///
  CommandExecutedEvent({required super.commandType});
}

/// Event with [Command.invalidate] methods queries.
final class CommandQueryInvalidationEvent extends CommandEvent {
  @internal
  ///
  CommandQueryInvalidationEvent({
    required super.commandType,
    required this.queriesToInvalidate,
  });

  /// The queries that are invalidated by the [Command.invalidate] method
  final Set<Query<dynamic>> queriesToInvalidate;
}
