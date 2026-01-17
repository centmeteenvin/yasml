import 'package:yasml/yasml.dart';
import 'package:yasml_example/game/game.dart';
import 'package:yasml_example/game/model/game_model.dart';

base class GameComposition extends AsyncComposition<GameState> {
  @override
  Future<GameState> compose(AsyncComposer composer) async {
    final state = await composer.watchStream(GameQuery());
    return state;
  }

  @override
  String get key => 'GameComposition';
}

base class GameMutation extends Mutation<GameComposition> {
  const GameMutation({required super.commander});

  void click() {
    commander.dispatch(GameClickCommand());
  }
}
