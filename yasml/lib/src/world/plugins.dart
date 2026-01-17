import 'package:yasml/src/world/world.dart';

abstract interface class WorldPlugin {
  void onInit(World world);
  Future<void> onDispose();
}
