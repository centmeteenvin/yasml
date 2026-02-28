part of '../events.dart';

/// All events relating [Mutation]
sealed class MutationEvent extends Event {
  ///
  MutationEvent({required this.mutationType}) : super(componentName: 'Mutation - $mutationType');

  /// The runtimeType of the [Mutation] related to the event
  final Type mutationType;
}

/// When a [MutationContainer] is created
final class MutationContainerCreatedEvent extends MutationEvent {
  ///
  MutationContainerCreatedEvent({required super.mutationType});
}

/// When a [Mutation] method is being ran by a [Notifier]
final class MutationExecutedEvent extends MutationEvent {
  ///
  MutationExecutedEvent({required super.mutationType});
}

/// After a [Mutation] Execution is finished and it is invalidating [Query]s
final class MutationInvalidationEvent extends MutationEvent {
  ///
  MutationInvalidationEvent({required super.mutationType, required this.queriesToInvalidate});

  /// The list of [Query] that is being invalidated
  final Set<Query<dynamic>> queriesToInvalidate;
}

/// When a [Mutation] execution dispatches a [Command] through the [Commander]
final class MutationCommandDispatchedEvent extends MutationEvent {
  ///
  MutationCommandDispatchedEvent({required super.mutationType, required this.commandType});

  /// The runtimeType of the [Command] that is being dispatched
  final Type commandType;
}

/// When a [Mutation] execution reads a [Query]
final class MutationQueryReadEvent extends MutationEvent {
  ///
  MutationQueryReadEvent({required super.mutationType, required this.queryKey, required this.queryState});

  /// The [Query.key] that is being read
  final String queryKey;

  /// The state of the query that is being returned
  final dynamic queryState;
}
