import 'package:yasml_example/game/game.dart';

mixin GameTick {
  GameState tick(int numberOfTicks, GameState current, List<GameEvent> events) {
    GameState newState = events.fold(current, handleEvent);
    newState = newState.buildings.fold(newState, (state, entry) => handleBuilding(numberOfTicks, current, entry));
    return newState;
  }

  GameState handleEvent(GameState current, GameEvent event) => switch (event) {
    ClickGameEvent() => current.copyWith(count: current.count + 1),
  };

  GameState handleBuilding(int numberOfTicks, GameState current, BuildingEntry entry) {
    return current.copyWith(count: entry.building.cps * entry.count * numberOfTicks);
  }
}
