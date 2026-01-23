import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/world/world.dart';

abstract interface class Observer {
  void onInit(World world);
  Future<void> onDispose();

  void onEvent(Event event);
}
