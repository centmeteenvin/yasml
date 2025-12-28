import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/view/view.dart';
import 'package:yasml/src/view_model/view_model_composer.dart';

abstract class ViewModelManager<ViewModel> implements ViewModelComposer {
  ViewModel get initialValue;

  Option<ViewModel> _state = OptionEmpty();

  ViewModel get state => _state.getOr(initialValue);

  void setState(ViewModel newState) {
    _state = OptionValue(newState);
    for (final listener in listeners) {
      listener.widget.updateState(newState);
    }
  }

  final Set<ViewModelNotifierSubscription> listeners = HashSet();
  final Set<QuerySubscription> repositorySubscriptions = HashSet();

  ViewModelNotifierSubscription subscribe(ViewWidgetState<ViewModel> widget) {
    final subscription = ViewModelNotifierSubscription(viewModelNotifier: this, widget: widget);
    listeners.add(subscription);
    return subscription;
  }

  void notify() {
    if (listeners.isNotEmpty) {
      execute();
    }
  }

  void execute();

  void unsubscribe(ViewWidgetState<ViewModel> widget) {
    final subscription = ViewModelNotifierSubscription(viewModelNotifier: this, widget: widget);
    listeners.remove(subscription);
    if (listeners.isEmpty) {
      dispose();
    }
  }

  void dispose() {
    for (final repositorySubscription in repositorySubscriptions) {
      repositorySubscription.repository.unsubscribe(this);
    }
  }

  @override
  T watch<T>(Query<T> repository) {
    repository.subscribe(this);
    return repository.state;
  }
}

@immutable
final class ViewModelNotifierSubscription {
  const ViewModelNotifierSubscription({required this.viewModelNotifier, required this.widget});

  final ViewModelManager viewModelNotifier;
  final ViewWidgetState widget;

  @override
  int get hashCode => Object.hash(viewModelNotifier, widget);

  @override
  bool operator ==(Object other) {
    return other is ViewModelNotifierSubscription &&
        other.viewModelNotifier == viewModelNotifier &&
        other.widget == widget;
  }
}
