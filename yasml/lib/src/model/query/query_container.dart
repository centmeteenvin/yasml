import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:yasml/src/logging.dart';
import 'package:yasml/src/model/query/query.dart';
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
    queryContainerLog.finer('[QueryContainer-${query.key}] state updated');
    _state = OptionValue(newState);
    for (final listener in listeners) {
      queryContainerLog.finest('[QueryContainer-${query.key}] Notifiying ${listener.listeningContainer.runtimeType}');
      listener.listeningContainer.notify();
    }
  }

  void execute() {
    queryContainerLog.fine('[QueryContainer-${query.key}] executing query');
    final cleanup = query.fetch(world, _state, setState, () {
      isSettled = true;
      queryContainerLog.finest('[QueryContainer-${query.key}] settled');
      world.queryManager.notifySettledChange();

      _settledCompleter.complete();
    });

    cleanupFn = OptionValue(cleanup);
  }

  final Set<QuerySubscription<T>> listeners = HashSet();

  void addListener(QuerySubscription<T> subscription) {
    final didAdd = listeners.add(subscription);
    if (didAdd) {
      queryContainerLog.fine(
        '[QueryContainer-${query.key}] adding ${subscription.listeningContainer.runtimeType} as listener',
      );
    } else {
      queryContainerLog.finer(
        '[QueryContainer-${query.key}] ${subscription.listeningContainer.runtimeType} already listened',
      );
    }
    if (_state case OptionEmpty()) {
      execute();
    }
  }

  void removeListener(QuerySubscription<T> subscription) {
    queryContainerLog.fine('[QueryContainer-${query.key}] removing ${subscription.listeningContainer.runtimeType}');
    listeners.remove(subscription);
  }

  void invalidate() {
    queryContainerLog.fine('[QueryContainer-${query.key}] invalidated');
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
      queryContainerLog.fine(
        '[QueryContainer-${query.key}] re-executing because following listeners are present after invalidation: $listeners',
      );
      execute();
    }
  }

  Future<void> dispose() async {
    queryContainerLog.fine('[QueryContainer-${query.key}]: Disposing container');
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
