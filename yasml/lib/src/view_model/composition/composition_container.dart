import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/future_query.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/model/query/query_container.dart';
import 'package:yasml/src/model/query/stream_query.dart';
import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/types/async_value.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/view/view.dart';
import 'package:yasml/src/view_model/composition/async_composition.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/world/world.dart';

/// Similar to the QueryContainer, the ComposerContainer
/// Manages the Composed state and subscribes themselves to the world
final class CompositionContainer<T> implements AsyncComposer, QueryReachable {
  final Composition<T> composition;
  final World world;

  Option<T> _state = OptionEmpty();

  T get state {
    if (!_state.hasValue) {
      _state = OptionValue(composition.initialValue(world, this));
    }
    return _state.requireValue;
  }

  void setState(T newState) {
    world.emit(CompositionSetStateEvent(compositionKey: composition.key, newState: newState));
    _state = OptionValue(newState);
    for (final listener in listeners) {
      listener.widget.updateState(newState);
    }
  }

  bool isSettled = false;

  CompositionContainer({required this.composition, required this.world});

  final Set<QuerySubscription> querySubscriptions = HashSet();

  @override
  QueryT watch<QueryT>(Query<QueryT> query) {
    final subscription = world.queryManager.subscribe(query, this);
    final didAdd = querySubscriptions.add(subscription);

    if (didAdd) {
      world.emit(
        CompositionWatchEvent(
          compositionKey: composition.key,
          watchingQueryKey: subscription.queryContainer.query.key,
          isAsync: false,
        ),
      );
    }

    return subscription.queryContainer.state;
  }

  @override
  Future<QueryT> watchFuture<QueryT>(FutureQuery<QueryT> query) async {
    final subscription = world.queryManager.subscribe(query, this);
    final didAdd = querySubscriptions.add(subscription);

    if (didAdd) {
      world.emit(
        CompositionWatchEvent(
          compositionKey: composition.key,
          watchingQueryKey: subscription.queryContainer.query.key,
          isAsync: true,
        ),
      );
    }

    final container = subscription.queryContainer;
    await container.settled;

    return switch (container.state) {
      AsyncLoading() => throw StateError("Aysnchronous query ${container.query.key} still in loading after settling"),
      AsyncError(:final error, :final stackTrace) => Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
      AsyncData(:final data) => data,
    };
  }

  @override
  Future<QueryT> watchStream<QueryT>(StreamQuery<QueryT> query) async {
    final subscription = world.queryManager.subscribe(query, this);
    final didAdd = querySubscriptions.add(subscription);

    if (didAdd) {
      world.emit(
        CompositionWatchEvent(
          compositionKey: composition.key,
          watchingQueryKey: subscription.queryContainer.query.key,
          isAsync: true,
        ),
      );
    }

    final container = subscription.queryContainer;
    await container.settled;

    return switch (container.state) {
      AsyncLoading() => throw StateError("Aysnchronous query ${container.query.key} after settling"),
      AsyncError(:final error, :final stackTrace) => Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
      AsyncData(:final data) => data,
    };
  }

  final Set<CompositionSubscription<T>> listeners = HashSet();

  void addListener(CompositionSubscription<T> subscription) {
    final didAdd = listeners.add(subscription);
    if (didAdd) {
      world.emit(
        CompositionContainerNewListenerEvent(
          compositionKey: composition.key,
          compositionListenableType: subscription.widget.widget.runtimeType,
        ),
      );
    }

    if (!_state.hasValue) {
      execute();
    }
  }

  void removeListener(CompositionSubscription<T> subscription) {
    final didRemove = listeners.remove(subscription);
    if (didRemove) {
      world.emit(
        CompositionContainerListenerRemovedEvent(
          compositionKey: composition.key,
          compositionListenableType: subscription.widget.widget.runtimeType,
        ),
      );
    }
  }

  void dispose() {
    for (final querySubscription in querySubscriptions) {
      world.emit(
        CompositionUnsubscribeEvent(
          compositionKey: composition.key,
          queryKey: querySubscription.queryContainer.query.key,
        ),
      );

      world.queryManager.unsubscribe(querySubscription);
    }
    // Compositions should not have a dispose function because no world resources should ever be bound to them
  }

  /// Call this to notify that the composition needs to be re-evaluated
  @override
  void notify() {
    if (listeners.isEmpty) {
      return; // Dont run composer when no one is listening
    }
    execute();
  }

  void execute() {
    world.emit(CompositionExecutedEvent(compositionKey: composition.key));

    composition.execute(this, setState, () {
      isSettled = true;

      world.emit(CompositionSettledEvent(compositionKey: composition.key));
      world.compositionManager.notifySettledChange();
    });
  }

  Future<void> refresh() {
    final subscribedQueries = querySubscriptions.map((sub) => sub.queryContainer.query).toSet();
    world.emit(CompositionRefreshEvent(compositionKey: composition.key, queriesToInvalidate: subscribedQueries));

    world.queryManager.invalidate(subscribedQueries);
    return world.settled;
  }

  @override
  int get hashCode => composition.hashCode;

  @override
  bool operator ==(Object other) {
    return other is CompositionContainer && other.composition.key == composition.key;
  }
}

@immutable
final class CompositionSubscription<T> {
  const CompositionSubscription({required this.compositionContainer, required this.widget});

  final CompositionContainer<T> compositionContainer;
  final ViewWidgetState<T, void, void> widget;

  @override
  int get hashCode => Object.hash(compositionContainer, widget);

  @override
  bool operator ==(Object other) {
    return other is CompositionSubscription &&
        other.compositionContainer == compositionContainer &&
        other.widget == widget;
  }
}
