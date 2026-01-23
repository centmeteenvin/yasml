part of '../events.dart';

sealed class QueryEvent extends Event {
  final String queryKey;
  QueryEvent({required this.queryKey}) : super(componentName: 'Query-$queryKey');
}

final class QueryContainerCreatedEvent extends QueryEvent {
  final String reason;
  QueryContainerCreatedEvent({required super.queryKey, required this.reason});
}

final class QueryContainerDisposedEvent extends QueryEvent {
  final String reason;
  QueryContainerDisposedEvent({required super.queryKey, required this.reason});
}

final class QueryContainerNewListenerEvent extends QueryEvent {
  final Type queryListenableType;
  QueryContainerNewListenerEvent({required super.queryKey, required this.queryListenableType});
}

final class QueryContainerListenerRemovedEvent extends QueryEvent {
  final Type queryListenableType;

  QueryContainerListenerRemovedEvent({required super.queryKey, required this.queryListenableType});
}

final class QueryExecutedEvent extends QueryEvent {
  QueryExecutedEvent({required super.queryKey});
}

final class QuerySetStateEvent extends QueryEvent {
  final dynamic newState;
  QuerySetStateEvent({required super.queryKey, required this.newState});
}

final class QuerySettledEvent extends QueryEvent {
  QuerySettledEvent({required super.queryKey});
}

final class QueryInvalidatedEvent extends QueryEvent {
  QueryInvalidatedEvent({required super.queryKey});
}
