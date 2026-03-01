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
import 'package:yasml/src/world/query_manager.dart';
import 'package:yasml/src/world/world.dart';

/// Similar to the [QueryContainer], the [CompositionContainer]
/// Manages the [Composition] state and subscribes themselves to the [World]
final class CompositionContainer<T> implements AsyncComposer, QueryReachable {
  /// Initialize the [CompositionContainer] with a [Composition] and a [World]
  ///
  /// No logic is run on initialization.
  CompositionContainer({required this.composition, required this.world});

  /// The [Composition] associated with the [CompositionContainer]
  final Composition<T> composition;

  /// The [World] in which the [CompositionContainer] exists.
  final World world;

  Option<T> _state = OptionEmpty();

  /// The current state of the [Composition].
  ///
  /// if [CompositionContainer._state] is not yet initialized the [Composition.initialValue]
  /// method is returned. Meanwhile the [CompositionContainer._state] will also be set.
  T get state {
    if (!_state.hasValue) {
      _state = OptionValue(composition.initialValue(world, this));
    }
    return _state.requireValue;
  }

  /// Updateds the [CompositionContainer.state] and notifies all [CompositionContainer.listeners]
  ///
  /// Emits a [CompositionSetStateEvent]
  void setState(T newState) {
    world.emit(
      CompositionSetStateEvent(
        compositionKey: composition.key,
        newState: newState,
      ),
    );
    _state = OptionValue(newState);
    for (final listener in listeners) {
      listener.widget.updateState(newState);
    }
  }

  /// Wheter the [CompositionContainer] has settled.
  /// A settled state is an indication from the developer that
  /// The most interesting value is now being present in the [CompositionContainer.state]
  bool isSettled = false;

  /// The current Set of [Query] that are being watched by the [CompositionContainer.composition]
  /// represented by a set of [QuerySubscription]
  final Set<QuerySubscription<dynamic>> querySubscriptions = HashSet();

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
      AsyncLoading() =>
        throw StateError(
          'Aysnchronous query ${container.query.key} still in loading after settling',
        ),
      AsyncError(:final error, :final stackTrace) => Error.throwWithStackTrace(
        error,
        stackTrace ?? StackTrace.current,
      ),
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
      AsyncLoading() =>
        throw StateError(
          'Aysnchronous query ${container.query.key} after settling',
        ),
      AsyncError(:final error, :final stackTrace) => Error.throwWithStackTrace(
        error,
        stackTrace ?? StackTrace.current,
      ),
      AsyncData(:final data) => data,
    };
  }

  /// The set of [ViewWidget] that are watching this [CompositionContainer.composition]
  /// represented by a set of [CompositionSubscription]
  final Set<CompositionSubscription<T>> listeners = HashSet();

  /// Subscribes a [ViewWidget] to the [CompositionContainer.composition]
  /// Emits a [CompositionContainerNewListenerEvent] if the listener was new
  ///
  /// When the [CompositionContainer.state] has not yet been initialized runs
  /// the [CompositionContainer.execute] methods
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

  /// Removes a [ViewWidget] from the [CompositionContainer.composition].
  ///
  /// Emits a [CompositionContainerListenerRemovedEvent] if the listener was new
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

  /// Cleans up all the associated resources from the [CompositionContainer]
  /// For each [CompositionContainer.querySubscriptions] emits a [CompositionUnsubscribeEvent]
  /// and call [QueryManager.unsubscribe].
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

  @override
  void notify() {
    if (listeners.isEmpty) {
      return; // Dont run composer when no one is listening
    }
    execute();
  }

  /// Starts the execution of the [Composition.execute] method while emitting a
  /// [CompositionExecutedEvent].
  void execute() {
    world.emit(CompositionExecutedEvent(compositionKey: composition.key));

    composition.execute(this, setState, () {
      isSettled = true;

      world.emit(CompositionSettledEvent(compositionKey: composition.key));
      world.compositionManager.notifySettledChange();
    });
  }

  /// Invalidates all [CompositionContainer.querySubscriptions] queries and emits a
  /// [CompositionRefreshEvent].
  ///
  /// Returns a Future that resolves when the [CompositionContainer.world] is settled.
  Future<void> refresh() {
    final subscribedQueries =
        querySubscriptions.map((sub) => sub.queryContainer.query).toSet();
    world.emit(
      CompositionRefreshEvent(
        compositionKey: composition.key,
        queriesToInvalidate: subscribedQueries,
      ),
    );

    world.queryManager.invalidate(subscribedQueries);
    return world.settled;
  }

  @override
  int get hashCode => composition.hashCode;

  @override
  bool operator ==(Object other) {
    return other is CompositionContainer &&
        other.composition.key == composition.key;
  }
}

/// Represents a Listening relation between a [ViewWidget] and a [CompositionContainer]
@immutable
final class CompositionSubscription<T> {
  ///
  const CompositionSubscription({
    required this.compositionContainer,
    required this.widget,
  });

  /// the [CompositionContainer] that is being subscribed to
  final CompositionContainer<T> compositionContainer;

  /// the [ViewWidget] that is listening
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
