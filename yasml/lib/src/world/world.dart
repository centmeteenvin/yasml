import 'dart:async';

import 'package:yasml/src/logging.dart';
import 'package:yasml/src/world/composition_manager.dart';
import 'package:yasml/src/world/query_manager.dart';

/// The world acts as the context where the application state runs in
final class World {
  late final QueryManager queryManager;
  late final CompositionManager compositionManager;

  World() {
    queryManager = QueryManagerImpl(this);
    compositionManager = CompositionManagerImpl(this);
    worldLog.info('[World]: initialized');
  }

  final StreamController<void> _settledController = StreamController.broadcast();
  bool get isSettled => queryManager.allSettled && compositionManager.allSettled;
  Future<void> get settled {
    if (isSettled) {
      return Future.value();
    }
    return _settledController.stream.first;
  }

  void notifySettledChanged() {
    if (isSettled) {
      worldLog.fine('World settled');
      _settledController.add(null);
    } else {
      worldLog.finer('[World]: a container has settled but the some not yet');
    }
  }
}
