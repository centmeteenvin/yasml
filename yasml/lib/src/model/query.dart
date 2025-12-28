import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/view_model/view_model_manager.dart';

abstract class Query<T> {
  T get initialState;

  Option<T> _state = OptionEmpty();

  void setState(T newState) {
    _state = OptionValue(newState);
    for (final listener in listeners) {
      listener.viewModelNotifier.notify();
    }
  }

  T get state => _state.getOr(initialState);

  void execute();
  final Set<QuerySubscription> listeners = HashSet();

  QuerySubscription subscribe(ViewModelManager viewModelNotifier) {
    final subscription = QuerySubscription(viewModelNotifier: viewModelNotifier, repository: this);
    listeners.add(subscription);

    return subscription;
  }

  void unsubscribe(ViewModelManager viewModelNotifier) {
    final subscription = QuerySubscription(viewModelNotifier: viewModelNotifier, repository: this);
    listeners.remove(subscription);
  }

  void invalidate() {
    _state = OptionEmpty();
    reset();
  }

  void reset();
}

@immutable
final class QuerySubscription {
  final ViewModelManager viewModelNotifier;
  final Query repository;

  const QuerySubscription({required this.viewModelNotifier, required this.repository});

  @override
  int get hashCode => Object.hash(viewModelNotifier, repository);

  @override
  bool operator ==(Object other) {
    return other is QuerySubscription && other.repository == repository && other.viewModelNotifier == viewModelNotifier;
  }
}

// final class FutureRepository<T, E> extends Query<AsyncValue<T, E>> {
//   FutureRepository({required this.fetch});

//   @override
//   void execute() {
//     fetch().then((result) {
//       result.when(
//         data: (data) => setState(AsyncData(data)),
//         error: (error, stacktrace) => setState(AsyncError(error, stackTrace: stacktrace)),
//       );
//     });
//   }

//   final Future<Result<T, E>> Function() fetch;

//   @override
//   get initialState => AsyncLoading();
// }
