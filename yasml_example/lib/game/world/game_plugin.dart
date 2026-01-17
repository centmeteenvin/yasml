import 'package:yasml/yasml.dart';
import 'package:yasml_example/game/game.dart';

final class GamePlugin implements WorldPlugin {
  late final Game game;

  @override
  Future<void> onDispose() async {
    game.stop();
  }

  @override
  void onInit(World world) {
    game = Game.create();
    game.start();
  }
}

extension GamePluginExtension on World {
  Game get game {
    final plugin = pluginByType<GamePlugin>();
    if (plugin == null) {
      throw StateError('GamePlugin was not found on the World');
    }
    return plugin.game;
  }
}
