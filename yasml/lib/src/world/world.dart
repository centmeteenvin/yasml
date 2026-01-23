import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yasml/src/logging/logging_observer.dart';
import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/observer/observer.dart';
import 'package:yasml/src/world/composition_manager.dart';
import 'package:yasml/src/world/plugins.dart';
import 'package:yasml/src/world/query_manager.dart';

abstract interface class World {
  /// A Future that completes when no more queries or composition are executing
  /// If the world is already settled, calling this will return a resolved Future
  Future<void> get settled;

  factory World.create({required List<WorldPlugin> plugins, required List<Observer> observers}) = WorldImpl;

  /// Destroy the world and all it's associated resources;
  Future<void> destroy();

  @internal
  QueryManager get queryManager;
  @internal
  CompositionManager get compositionManager;

  List<WorldPlugin> get plugins;
  T? pluginByType<T>();

  List<Observer> get observers;

  @internal
  void emit(Event event);
}

/// The world acts as the context where the application state runs in
final class WorldImpl implements World {
  @override
  late final QueryManager queryManager;
  @override
  late final CompositionManager compositionManager;

  @override
  final List<WorldPlugin> plugins;

  @override
  final List<Observer> observers;

  WorldImpl({required this.plugins, required this.observers}) {
    queryManager = QueryManagerImpl(this);
    compositionManager = CompositionManagerImpl(this);
    for (final plugin in plugins) {
      plugin.onInit(this);
    }

    observers.add(LoggingObserver());

    for (final observer in observers) {
      observer.onInit(this);
    }
    emit(WorldCreatedEvent());
  }

  final StreamController<void> _settledController = StreamController.broadcast();
  bool get isSettled => queryManager.allSettled && compositionManager.allSettled;
  @override
  Future<void> get settled {
    if (isSettled) {
      return Future.value();
    }
    return _settledController.stream.first;
  }

  void notifySettledChanged() {
    if (isSettled) {
      emit(WorldSettledEvent());
      _settledController.add(null);
    }
  }

  @override
  Future<void> destroy() async {
    emit(WorldDestroyedEvent());
    for (final plugin in plugins) {
      await plugin.onDispose();
    }

    await compositionManager.destroy();
    await queryManager.destroy();
  }

  @override
  T? pluginByType<T>() {
    return plugins.whereType<T>().firstOrNull;
  }

  @override
  void emit(Event event) {
    for (final observer in observers) {
      observer.onEvent(event);
    }
  }
}
