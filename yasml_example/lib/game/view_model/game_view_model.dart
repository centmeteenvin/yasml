import 'package:yasml/yasml.dart';
import 'package:yasml_example/game/game.dart';
import 'package:yasml_example/game/model/game_model.dart';

final gameComposition = AsyncComposition<GameState>.create(
  (composer) => composer.watchStream(gameQuery),
  key: 'GameComposition',
);

base class GameMutation extends Mutation<AsyncComposition<GameState>> {
  const GameMutation({required super.commander});

  void click() {
    commander.dispatch(gameClickCommand);
  }
}
