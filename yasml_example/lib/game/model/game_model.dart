import 'dart:async';
import 'dart:ui';

import 'package:yasml/yasml.dart';
import 'package:yasml_example/external/get_it.dart';
import 'package:yasml_example/game/game.dart';
import 'package:yasml_example/game/world/game_plugin.dart';

base class GameQuery extends StreamQuery<GameState> {
  @override
  String get key => 'GameQuery';

  @override
  Stream<GameState> query(World world, VoidCallback setSettled) {
    final stream = world.get.registerSingletonIfAbsent(
      () => world.game.stream(Duration(milliseconds: 100)),
      instanceName: 'gameStream',
    );

    // final stream = world.game.stream;
    stream.first.then((_) => setSettled());
    return stream;
  }
}

class GameClickCommand implements Command<void> {
  @override
  FutureOr<void> execute(World world) {
    world.game.click();
  }

  @override
  List<Query<dynamic>> invalidate(void result) => [];
}
