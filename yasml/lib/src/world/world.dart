import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yasml/src/logging/logging_observer.dart';
import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/observer/observer.dart';
import 'package:yasml/src/world/composition_manager.dart';
import 'package:yasml/src/world/plugins.dart';
import 'package:yasml/src/world/query_manager.dart';

/// The world is the context where all the application state lives in. It is responsible for managing the lifecycle of the state,
///  and providing a way to access it from the views and the view models.
/// The world is created with a list of [WorldPlugin]s that can be used to extend the functionality of the world,
///  and a list of [Observer]s that can be used to observe the events in the world.
///
///  Get started using the [World.create] factory constructor and passing the desired plugins and observers
abstract interface class World {
  factory World.create({
    required List<WorldPlugin> plugins,
    required List<Observer> observers,
  }) = WorldImpl;

  /// A Future that completes when no more queries or composition are executing
  /// If the world is already settled, calling this will return a resolved Future
  Future<void> get settled;

  /// Destroy the world and all it's associated resources;
  Future<void> destroy();

  /// @nodoc
  @internal
  QueryManager get queryManager;

  /// @nodoc
  @internal
  CompositionManager get compositionManager;

  /// A list of all the plugins that are added to the world. It can be used to access the plugins and their functionality.
  List<WorldPlugin> get plugins;

  /// A method that can be used to get a plugin by its type. It returns null if the plugin is not found.
  T? pluginByType<T>();

  /// A list of all the observers that are added to the world. It can be used to access the observers and their functionality.
  List<Observer> get observers;

  /// Used to emit an event to all the observers in the world.
  @internal
  void emit(Event event);
}

/// The world acts as the context where the application state runs in
final class WorldImpl implements World {
  /// @nodoc
  WorldImpl({required this.plugins, required this.observers}) {
    queryManager = QueryManagerImpl(this);
    compositionManager = CompositionManagerImpl(this);
    for (final plugin in plugins) {
      plugin.onInit(this);
    }

    observers.add(const LoggingObserver());

    for (final observer in observers) {
      observer.onInit(this);
    }
    emit(WorldCreatedEvent());
  }
  @override
  late final QueryManager queryManager;
  @override
  late final CompositionManager compositionManager;

  @override
  final List<WorldPlugin> plugins;

  @override
  final List<Observer> observers;

  final StreamController<void> _settledController =
      StreamController.broadcast();

  /// Returns true if all queries and compositions in the world are settled, false otherwise.
  bool get isSettled =>
      queryManager.allSettled && compositionManager.allSettled;

  @override
  Future<void> get settled {
    if (isSettled) {
      return Future.value();
    }
    return _settledController.stream.first;
  }

  /// Notifies the world that the settled state has changed.
  ///  If the world is now settled, it emits a [WorldSettledEvent] and completes the [settled] Future.
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
