part of '../events.dart';

/// Events related to the execution and lifecycle of queries. These events are emitted by the [QueryManager]
sealed class QueryEvent extends Event {
  /// @nodoc
  QueryEvent({required this.queryKey}) : super(componentName: 'Query-$queryKey');

  /// [Query.key] of the query that is the source of the event
  final String queryKey;
}

/// Specific event for the creation of a query container.
final class QueryContainerCreatedEvent extends QueryEvent {
  /// @nodoc
  QueryContainerCreatedEvent({required super.queryKey, required this.reason});

  /// The reason why the query container was created. It can be used to differentiate between different
  /// scenarios that lead to the creation of a query container.
  final String reason;
}

/// Specific event for the disposal of a query container.
final class QueryContainerDisposedEvent extends QueryEvent {
  /// @nodoc
  QueryContainerDisposedEvent({required super.queryKey, required this.reason});

  /// The reason why the query container was disposed. It can be used to differentiate between different
  /// scenarios that lead to the disposal of a query container.
  final String reason;
}

/// Specific event for the addition of a new listener to a query container.
final class QueryContainerNewListenerEvent extends QueryEvent {
  /// @nodoc
  QueryContainerNewListenerEvent({
    required super.queryKey,
    required this.queryListenableType,
  });

  /// The type of the listener that was added. It can be used to differentiate between different
  /// types of listeners, such as compositions and mutations.
  final Type queryListenableType;
}

/// Specific event for the removal of a listener from a query container.
final class QueryContainerListenerRemovedEvent extends QueryEvent {
  /// @nodoc
  QueryContainerListenerRemovedEvent({
    required super.queryKey,
    required this.queryListenableType,
  });

  /// The type of the listener that was removed. It can be used to differentiate between different
  /// types of listeners, such as compositions and mutations.
  final Type queryListenableType;
}

/// Specific event for the execution of a query.
final class QueryExecutedEvent extends QueryEvent {
  /// @nodoc
  QueryExecutedEvent({required super.queryKey});
}

/// Specific event for the update of the state of a query.
final class QuerySetStateEvent extends QueryEvent {
  /// @nodoc
  QuerySetStateEvent({required super.queryKey, required this.newState});

  /// The new state of the query after the update. It can be used to track the changes in the state of the query over time.
  final dynamic newState;
}

/// Specific event for the settling of a query. A query is considered settled when it has finished executing and its state is stable.
final class QuerySettledEvent extends QueryEvent {
  /// @nodoc
  QuerySettledEvent({required super.queryKey});
}

/// Specific event for the invalidation of a query. A query is invalidated when it needs to be re-executed,
/// for example, a command explicitly invalidates a query after mutating the state
final class QueryInvalidatedEvent extends QueryEvent {
  /// @nodoc
  QueryInvalidatedEvent({required super.queryKey});
}
