import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/world/world.dart';

/// A base class for all observers that can be added to the world. It defines the common interface for all observers
abstract interface class Observer {
  /// A method that is called when the observer is added to the world. It can be used to initialize any resources
  /// that the observer needs to function. It is called before any events are emitted by the world, so it can be used
  /// to set up any necessary state or subscriptions to the world.
  void onInit(World world);

  /// A method that is called when the observer is removed from the world. It can be used to clean up any resources
  /// that the observer was using. It is called after the observer is removed from the world,
  /// so it should not attempt to access the world or any of its resources.
  Future<void> onDispose();

  /// A method that is called when an event is emitted by the world. It can be used to react to any events that
  /// the world emits, such as queries being executed, compositions being created, mutations being applied, etc.
  void onEvent(Event event);
}
