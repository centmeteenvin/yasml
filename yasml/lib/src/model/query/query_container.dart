import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/world.dart';

/// The query container represents the runtime for a query
/// the container contains the state of the query
/// it also manages subscriptions from viewModels
///
/// On creation it also registers itself to world
final class QueryContainer<T> {
  /// @nodoc
  QueryContainer({required this.world, required this.query});

  /// The query that is being executed in this container
  final Query<T> query;

  /// The world that this query container is registered to
  final World world;

  /// True if the query is currently settled, false otherwise
  bool isSettled = false;

  Option<T> _state = OptionEmpty();

  /// The current state of the query. If the query is still in it's initial state,
  ///  it will be initialized with the query's [Query.initialState] method.
  T get state {
    if (!_state.hasValue) {
      _state = OptionValue(query.initialState(world));
    }
    return _state.requireValue;
  }

  Completer<void> _settledCompleter = Completer();

  /// A Future that completes when the query is settled.
  /// If the query is already settled, it will return a resolved Future.
  Future<void> get settled => _settledCompleter.future;

  /// The cleanup function returned by the query's fetch method. It is called when the query is invalidated or disposed.
  Option<CleanupFn> cleanupFn = OptionEmpty();

  /// Sets the state of the query and notifies all listeners. It also emits a [QuerySetStateEvent] to the world.
  void setState(T newState) {
    world.emit(QuerySetStateEvent(queryKey: query.key, newState: newState));
    _state = OptionValue(newState);
    for (final listener in listeners) {
      listener.listeningContainer.notify();
    }
  }

  /// Executes the query by calling the query's fetch method. It also emits a [QueryExecutedEvent] to the world.
  void execute() {
    world.emit(QueryExecutedEvent(queryKey: query.key));
    final cleanup = query.fetch(world, _state, setState, () {
      isSettled = true;
      world.emit(QuerySettledEvent(queryKey: query.key));
      world.queryManager.notifySettledChange();

      _settledCompleter.complete();
    });

    cleanupFn = OptionValue(cleanup);
  }

  /// A set of all the listeners that are currently listening to this query.
  /// It is used to notify the listeners when the state of the query changes.
  final Set<QuerySubscription<T>> listeners = HashSet();

  /// Adds a listener to this query container. If the listener is added successfully and the query is not yet settled
  /// , it will execute the query. It also emits a [QueryContainerNewListenerEvent] to the world.
  void addListener(QuerySubscription<T> subscription) {
    final didAdd = listeners.add(subscription);
    if (didAdd) {
      world.emit(
        QueryContainerNewListenerEvent(
          queryKey: query.key,
          queryListenableType: subscription.listeningContainer.runtimeType,
        ),
      );
    }

    if (_state case OptionEmpty()) {
      execute();
    }
  }

  /// Removes a listener from this query container. If the listener is removed successfully,
  ///  it also emits a [QueryContainerListenerRemovedEvent] to the world.
  void removeListener(QuerySubscription<T> subscription) {
    final didRemove = listeners.remove(subscription);

    if (didRemove) {
      world.emit(
        QueryContainerListenerRemovedEvent(
          queryKey: query.key,
          queryListenableType: subscription.listeningContainer.runtimeType,
        ),
      );
    }
  }

  /// Invalidates the query by calling the cleanup function and
  ///  setting the state to the initial state. It also emits a [QueryInvalidatedEvent] to the world.
  Future<void> invalidate() async {
    world.emit(QueryInvalidatedEvent(queryKey: query.key));

    _state = OptionValue(query.initialState(world));
    isSettled = false;
    if (!_settledCompleter.isCompleted) {
      _settledCompleter.completeError(
        'Query was invalidated while some where still listening and the query was not yet settled',
      );
    }
    _settledCompleter = Completer();
    if (cleanupFn case OptionValue(:final value)) {
      await value.call();
    }
    world.queryManager.notifySettledChange();
    if (listeners.isNotEmpty) {
      world.emit(QueryExecutedEvent(queryKey: query.key));
      execute();
    }
  }

  /// Disposes the query container by calling the cleanup function and setting
  /// the state to the initial state. It also emits a [QueryContainerDisposedEvent]
  ///  to the world.
  Future<void> dispose() async {
    if (listeners.isNotEmpty) {
      throw StateError(
        'Cannot Dispose a query container that still has listeners',
      );
    }

    isSettled = true;
    _state = OptionEmpty();
    if (cleanupFn case OptionValue(:final value)) {
      await value.call();
    }
  }

  @override
  int get hashCode => query.hashCode;

  @override
  bool operator ==(Object other) {
    return other is QueryContainer && other.query.key == query.key;
  }
}

/// The query subscription is an immutable representation of 2-way data binding between
/// a query- and composer container.
@immutable
final class QuerySubscription<T> {
  /// @nodoc
  const QuerySubscription({
    required this.listeningContainer,
    required this.queryContainer,
  });

  /// The container that is listening to the query container. It is used to notify the container when the state of the query changes.s
  final QueryReachable listeningContainer;

  /// The query container that is being listened to. It is used to get the current state of the query and to unsubscribe from the query.
  final QueryContainer<T> queryContainer;

  @override
  int get hashCode => Object.hash(listeningContainer, queryContainer);

  @override
  bool operator ==(Object other) {
    return other is QuerySubscription<T> &&
        other.queryContainer == queryContainer &&
        other.listeningContainer == listeningContainer;
  }
}

/// An interface that represents a container that can be notified when the state of a query changes.
/// It is used to create a 2-way data binding between a query container and a composer container.
abstract interface class QueryReachable {
  /// Notifies the listener that the state of the query has changed
  void notify();
}
