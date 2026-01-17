import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:yasml_example/game/game_tick.dart';
import 'package:yasml_example/game/sample_stream_transformer.dart';

abstract interface class Game {
  Stream<GameState> stream(Duration interval);

  void click();

  void start();
  void stop();

  factory Game.create() = GameImpl;
}

class GameImpl with GameTick implements Game {
  GameState gameState = GameState(count: 0, buildings: UnmodifiableListView([]));

  final tps = 60;

  Duration get timePerTick => Duration(milliseconds: ((1 / tps) * 1000).round());

  bool isRunning = false;

  final StreamController<GameState> streamController = StreamController.broadcast();

  final List<GameEvent> events = [];

  @override
  Stream<GameState> stream(Duration interval) => streamController.stream.transform(SampleStreamTransformer(interval));

  @override
  void start() {
    isRunning = true;
    gameLoop();
  }

  @override
  void stop() {
    isRunning = false;
  }

  Future<void> gameLoop() async {
    isRunning = true;
    final startTime = DateTime.now();
    int ticksEllapsed = 0;
    int ticksToSchedule = 1;
    while (isRunning) {
      final eventsToProcess = List.of(events);
      events.clear();

      gameState = tick(ticksToSchedule, gameState, eventsToProcess);
      streamController.add(gameState);

      final endTime = DateTime.now();
      final msEllapsed = endTime.difference(startTime);

      ticksEllapsed += ticksToSchedule;
      final expectedTicksElapsed = (msEllapsed.inMilliseconds / timePerTick.inMilliseconds).floor();

      ticksToSchedule = expectedTicksElapsed - ticksEllapsed;

      if (ticksToSchedule < 1) {
        final totalDurationForNextTick = timePerTick * (expectedTicksElapsed + 1);
        final timeToNext = startTime.add(totalDurationForNextTick).difference(endTime);

        await Future.delayed(timeToNext);

        ticksToSchedule = 1;
      }
    }
  }

  @override
  void click() {
    events.add(ClickGameEvent());
  }
}

typedef BuildingEntry = ({Building building, int count});

@immutable
final class GameState {
  final double count;
  final UnmodifiableListView<BuildingEntry> buildings;

  const GameState({required this.count, required this.buildings});

  GameState copyWith({double? count, UnmodifiableListView<BuildingEntry>? buildings}) {
    return GameState(count: count ?? this.count, buildings: buildings ?? this.buildings);
  }
}

sealed class Building {
  String get name;
  double get cps;
  double get baseCost;
}

class ClickerBuilding extends Building {
  @override
  String get name => "Auto Clicker";
  @override
  double get baseCost => 100;
  @override
  double get cps => 0.1;
}

sealed class GameEvent {}

class ClickGameEvent extends GameEvent {}
