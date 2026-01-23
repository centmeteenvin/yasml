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
  final Query<T> query;
  final World world;
  bool isSettled = false;

  QueryContainer({required this.world, required this.query});

  Option<T> _state = OptionEmpty();
  T get state {
    if (!_state.hasValue) {
      _state = OptionValue(query.initialState(world));
    }
    return _state.requireValue;
  }

  Completer<void> _settledCompleter = Completer();

  Future<void> get settled => _settledCompleter.future;

  Option<CleanupFn> cleanupFn = OptionEmpty();

  void setState(T newState) {
    world.emit(QuerySetStateEvent(queryKey: query.key, newState: newState));
    _state = OptionValue(newState);
    for (final listener in listeners) {
      listener.listeningContainer.notify();
    }
  }

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

  final Set<QuerySubscription<T>> listeners = HashSet();

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

  void invalidate() {
    world.emit(QueryInvalidatedEvent(queryKey: query.key));

    _state = OptionValue(query.initialState(world));
    isSettled = false;
    if (!_settledCompleter.isCompleted) {
      _settledCompleter.completeError(
        "Query was invalidated while some where still listening and the query was not yet settled",
      );
    }
    _settledCompleter = Completer();
    if (cleanupFn case OptionValue(:final value)) {
      value.call();
    }
    world.queryManager.notifySettledChange();
    if (listeners.isNotEmpty) {
      world.emit(QueryExecutedEvent(queryKey: query.key));
      execute();
    }
  }

  Future<void> dispose() async {
    if (listeners.isNotEmpty) {
      throw StateError("Cannot Dispose a query container that still has listeners");
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
  final QueryReachable listeningContainer;
  final QueryContainer<T> queryContainer;

  const QuerySubscription({required this.listeningContainer, required this.queryContainer});

  @override
  int get hashCode => Object.hash(listeningContainer, queryContainer);

  @override
  bool operator ==(Object other) {
    return other is QuerySubscription<T> &&
        other.queryContainer == queryContainer &&
        other.listeningContainer == listeningContainer;
  }
}

abstract interface class QueryReachable {
  /// Notifies the listener that the state of the query has changed
  void notify();
}
