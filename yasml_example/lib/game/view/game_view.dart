import 'package:flutter/material.dart';
import 'package:yasml/yasml.dart';
import 'package:yasml_example/game/game.dart';
import 'package:yasml_example/game/view/game_view_buildings.dart';
import 'package:yasml_example/game/view_model/game_view_model.dart';

base class GameView extends ViewWidget<AsyncValue<GameState>, GameComposition, GameMutation> {
  const GameView({super.key, required super.world});

  @override
  GameComposition get composition => GameComposition();

  @override
  MutationConstructor<GameMutation> get mutationConstructor =>
      (commander) => GameMutation(commander: commander);

  @override
  Widget build(BuildContext context, AsyncValue<GameState> composition, Notifier<GameMutation> notifier) {
    return switch (composition) {
      AsyncLoading() => Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => () {
        return ErrorWidget(error);
      }(),
      AsyncData(:final data) => GameViewData(gameState: data, notifier: notifier),
    };
  }
}

class GameViewData extends StatelessWidget {
  final GameState gameState;
  final Notifier<GameMutation> notifier;
  const GameViewData({super.key, required this.gameState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final colorscheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                clipBehavior: .hardEdge,
                decoration: BoxDecoration(shape: .circle, color: colorscheme.primaryContainer),

                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      notifier.runMutation((mutation) => mutation.click());
                    },
                    child: Container(padding: EdgeInsets.all(50), child: Text(gameState.count.toString())),
                  ),
                ),
              ),
            ),
          ),
          Expanded(flex: 1, child: GameViewBuildings(gameState: gameState)),
        ],
      ),
    );
  }
}
