import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:yasml/src/logging.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/model/query/query_container.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/view/view.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/world/world.dart';

/// Similar to the QueryContainer, the ComposerContainer
/// Manages the Composed state and subscribes themselves to the world
final class CompositionContainer<T> implements Composer, QueryReachable {
  final Composition<T> composition;
  final World world;

  Option<T> _state = OptionEmpty();

  T get state {
    if (!_state.hasValue) {
      _state = OptionValue(composition.initialValue(world));
    }
    return _state.requireValue;
  }

  void setState(T newState) {
    compositionContainerLog.finer('[Composition-${composition.key}] state updated');
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
    compositionContainerLog.finer('[Composition-${composition.key}] watching query ${query.key}');
    final subscription = world.queryManager.subscribe(query, this);
    querySubscriptions.add(subscription);
    return subscription.queryContainer.state;
  }

  final Set<CompositionSubscription<T>> listeners = HashSet();

  void addListener(CompositionSubscription<T> subscription) {
    final didAdd = listeners.add(subscription);
    if (didAdd) {
      compositionContainerLog.fine(
        '[Composition-${composition.key}]  adding ${subscription.widget.widget.runtimeType} as listener',
      );
    } else {
      compositionContainerLog.finer(
        '[Composition-${composition.key}] ${subscription.widget.widget.runtimeType} already listened',
      );
    }

    if (!_state.hasValue) {
      execute();
    }
  }

  void removeListener(CompositionSubscription<T> subscription) {
    compositionContainerLog.fine(
      '[Composition-${composition.key}] removing ${subscription.widget.widget.runtimeType} from listener',
    );
    listeners.remove(subscription);
  }

  void dispose() {
    compositionContainerLog.fine('[Composition-${composition.key}] disposing self');
    for (final querySubscription in querySubscriptions) {
      compositionContainerLog.finer(
        '[Composition-${composition.key}] unsubscribing from ${querySubscription.queryContainer.query.key}',
      );
      world.queryManager.unsubscribe(querySubscription);
    }
  }

  /// Call this to notify that the composition needs to be re-evaluated
  @override
  void notify() {
    if (listeners.isEmpty) {
      return; // Dont run composer when no one is listening
    }
    compositionContainerLog.finest('[Composition-${composition.key}] notified by query');
    execute();
  }

  void execute() {
    compositionContainerLog.fine('[Composition-${composition.key}] executing composition');
    composition.compose(this, setState, () {
      isSettled = true;
      compositionLog.fine('[Composition-${composition.key}] settled');
      world.compositionManager.notifySettledChange();
    });
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
