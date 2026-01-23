import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/types/registry.dart';
import 'package:yasml/src/view/view.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/view_model/composition/composition_container.dart';
import 'package:yasml/src/world/world.dart';

/// Handles the inizialitzation of compositionContainers as well as
/// subscribing and settling of them
abstract interface class CompositionManager {
  bool get allSettled;
  void notifySettledChange();

  CompositionSubscription<T> subscribe<T>(Composition<T> composition, ViewWidgetState<T, Composition<T>, void> widget);
  void unsubscribe(CompositionSubscription subscription);

  /// Invalidates all queries a composition is listening to
  Future<void> refresh(Composition composition);

  /// Destroy all composition containers
  Future<void> destroy();
}

final class CompositionManagerImpl implements CompositionManager {
  final WorldImpl world;
  CompositionManagerImpl(this.world);

  final Registry<String, Composition, CompositionContainer> registry = Registry();

  Option<bool> previousSettledState = OptionEmpty();

  @override
  bool get allSettled => registry.items.every((container) => container.isSettled);

  @override
  void notifySettledChange() {
    // nothing changed here
    if (previousSettledState case OptionValue(:final value) when value == allSettled) {
      return;
    }
    previousSettledState = OptionValue(allSettled);
    world.notifySettledChanged();
  }

  CompositionContainer<T> get<T>(Composition<T> composition) {
    final option = registry.get(composition);
    if (option case OptionValue(value: CompositionContainer<T> container)) {
      return container;
    }

    world.emit(CompositionContainerCreatedEvent(compositionKey: composition.key, reason: 'new Listener'));
    final container = CompositionContainer(composition: composition, world: world);
    registry.register(composition, container);
    return container;
  }

  void remove(Composition composition) {
    registry.unregister(composition);
  }

  @override
  CompositionSubscription<T> subscribe<T>(Composition<T> composition, ViewWidgetState<T, Composition<T>, void> widget) {
    final container = get(composition);
    final subscription = CompositionSubscription(compositionContainer: container, widget: widget);

    container.addListener(subscription);

    return subscription;
  }

  @override
  void unsubscribe(CompositionSubscription<dynamic> subscription) {
    final container = subscription.compositionContainer;
    container.removeListener(subscription);

    if (container.listeners.isEmpty) {
      registry.unregister(container.composition);

      world.emit(CompositionContainerDisposedEvent(compositionKey: container.composition.key, reason: 'No Listeners'));
      container.dispose();
      remove(container.composition);
    }
  }

  @override
  Future<void> refresh(Composition composition) {
    final container = get(composition);
    return container.refresh();
  }

  @override
  Future<void> destroy() async {
    registry.items
        .expand((container) => container.listeners.cast<CompositionSubscription>())
        .toList()
        .forEach(unsubscribe);
  }
}
