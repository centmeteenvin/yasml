part of '../events.dart';

sealed class CommandEvent extends Event {
  final Type commandType;
  CommandEvent({required this.commandType}) : super(componentName: 'Command - $commandType');
}

final class CommandExecutedEvent extends CommandEvent {
  CommandExecutedEvent({required super.commandType});
}

final class CommandQueryInvalidationEvent extends CommandEvent {
  final Set<Query> queriesToInvalidate;

  CommandQueryInvalidationEvent({required super.commandType, required this.queriesToInvalidate});
}
