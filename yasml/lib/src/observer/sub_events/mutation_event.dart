part of '../events.dart';

sealed class MutationEvent extends Event {
  final Type mutationType;
  MutationEvent({required this.mutationType}) : super(componentName: 'Mutation - $mutationType');
}

final class MutationContainerCreatedEvent extends MutationEvent {
  MutationContainerCreatedEvent({required super.mutationType});
}

final class MutationExecutedEvent extends MutationEvent {
  MutationExecutedEvent({required super.mutationType});
}

final class MutationInvalidationEvent extends MutationEvent {
  final Set<Query> queriesToInvalidate;
  MutationInvalidationEvent({required super.mutationType, required this.queriesToInvalidate});
}

final class MutationCommandDispatchedEvent extends MutationEvent {
  final Type commandType;
  MutationCommandDispatchedEvent({required super.mutationType, required this.commandType});
}

final class MutationQueryReadEvent extends MutationEvent {
  final String queryKey;
  final dynamic queryState;
  MutationQueryReadEvent({required super.mutationType, required this.queryKey, required this.queryState});
}
