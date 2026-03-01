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
  /// True when all active compositions are settled
  bool get allSettled;

  /// Should be called by a [CompositionContainer] when it's settled
  /// state changes.
  void notifySettledChange();

  /// Subscribe a [ViewWidget] to a certain [Composition] and returns the Compositions
  /// initial state.
  CompositionSubscription<T> subscribe<T>(
    Composition<T> composition,
    ViewWidgetState<T, Composition<T>, void> widget,
  );

  /// Unsubscribes a [ViewWidget] from a [Composition].
  /// If the [Composition] has no listeners afterwards it will be disposed.
  void unsubscribe(CompositionSubscription<dynamic> subscription);

  /// Invalidates all queries a composition is listening to.
  ///
  /// Returns a Future that completes when the [World] is settled
  Future<void> refresh(Composition<dynamic> composition);

  /// Destroy all composition containers
  Future<void> destroy();
}

/// The implementation of [CompositionManager]
final class CompositionManagerImpl implements CompositionManager {
  ///
  CompositionManagerImpl(this.world);

  ///
  final WorldImpl world;

  /// A Registry that contains a dictionary of [Composition] : [CompositionContainer].
  final Registry<String, Composition<dynamic>, CompositionContainer<dynamic>>
  registry = Registry();

  /// Contains the previous value of [CompositionManager.allSettled]
  ///
  /// Is used to reduce notifications sent to the [World]
  Option<bool> previousSettledState = OptionEmpty();

  @override
  bool get allSettled =>
      registry.items.every((container) => container.isSettled);

  @override
  void notifySettledChange() {
    // nothing changed here
    if (previousSettledState case OptionValue(
      :final value,
    ) when value == allSettled) {
      return;
    }
    previousSettledState = OptionValue(allSettled);
    world.notifySettledChanged();
  }

  /// Fetches the [CompositionContainer] for the [Composition].
  ///
  /// If the [CompositionContainer] does not yet exist it will be created.
  ///
  /// Emits [CompositionContainerCreatedEvent].
  CompositionContainer<T> get<T>(Composition<T> composition) {
    final option = registry.get(composition);
    if (option case OptionValue(
      value: final CompositionContainer<T> container,
    )) {
      return container;
    }

    world.emit(
      CompositionContainerCreatedEvent(
        compositionKey: composition.key,
        reason: 'new Listener',
      ),
    );
    final container = CompositionContainer(
      composition: composition,
      world: world,
    );
    registry.register(composition, container);
    return container;
  }

  /// Deletes the [Composition] from the [CompositionManagerImpl.registry].
  /// Can be safely called multiple times.
  void remove(Composition<dynamic> composition) {
    registry.unregister(composition);
  }

  @override
  CompositionSubscription<T> subscribe<T>(
    Composition<T> composition,
    ViewWidgetState<T, Composition<T>, void> widget,
  ) {
    final container = get(composition);
    final subscription = CompositionSubscription(
      compositionContainer: container,
      widget: widget,
    );

    container.addListener(subscription);

    return subscription;
  }

  @override
  void unsubscribe(CompositionSubscription<dynamic> subscription) {
    final container =
        subscription.compositionContainer..removeListener(subscription);

    if (container.listeners.isEmpty) {
      registry.unregister(container.composition);

      world.emit(
        CompositionContainerDisposedEvent(
          compositionKey: container.composition.key,
          reason: 'No Listeners',
        ),
      );
      container.dispose();
      remove(container.composition);
    }
  }

  @override
  Future<void> refresh(Composition<dynamic> composition) {
    final container = get(composition);
    return container.refresh();
  }

  @override
  Future<void> destroy() async {
    registry.items
        .expand(
          (container) =>
              container.listeners.cast<CompositionSubscription<dynamic>>(),
        )
        .toList()
        .forEach(unsubscribe);
  }
}
