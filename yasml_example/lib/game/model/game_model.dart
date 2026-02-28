import 'package:yasml/yasml.dart';
import 'package:yasml_example/external/get_it.dart';
import 'package:yasml_example/game/game.dart';
import 'package:yasml_example/game/world/game_plugin.dart';

final gameQuery = StreamQuery<GameState>.create(
  (world, setSettled) {
    final stream = world.get.registerSingletonIfAbsent(
      () => world.game.stream(Duration(milliseconds: 100)),
      instanceName: 'gameStream',
    );
    stream.first.then((_) => setSettled());
    return stream;
  },
  key: 'GameQuery',
);

final gameClickCommand = Command<void>.create(
  (world) { world.game.click(); },
  (_) => [],
);
