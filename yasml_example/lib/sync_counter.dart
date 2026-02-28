import 'package:flutter/material.dart';
import 'package:yasml/yasml.dart';

int count = 0;

final countQuery = SynchronousQuery.create((world) => count, key: 'CountQuery');

Command<void> updateCount(int newValue) => Command.create(
  (world) { count = newValue; },
  (_) => [countQuery],
);

final countComposition = SynchronousComposition.create(
  (composer) => composer.watch(countQuery),
  key: 'CountComposition',
);

base class CountMutation extends Mutation<SynchronousComposition<int>> {
  const CountMutation({required super.commander});

  Future<void> increment(int current) {
    return commander.dispatch(updateCount(current + 1));
  }

  Future<void> reset() {
    return commander.dispatch(updateCount(0));
  }
}

base class SyncCountView extends ViewWidget<int, SynchronousComposition<int>, CountMutation> {
  const SyncCountView({super.key, required super.world});

  @override
  SynchronousComposition<int> get composition => countComposition;

  @override
  MutationConstructor<CountMutation> get mutationConstructor => (dispatcher) => CountMutation(commander: dispatcher);

  @override
  Widget build(BuildContext context, int current, Notifier<CountMutation> notifier) {
    return Scaffold(
      body: Center(child: Text(current.toString())),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          FloatingActionButton(
            onPressed: () => notifier.runMutation((mutation) => mutation.increment(current)),
            child: Icon(Icons.plus_one),
          ),
          FloatingActionButton(
            onPressed: () => notifier.runMutation((mutation) => mutation.reset()),
            child: Icon(Icons.restore),
          ),
        ],
      ),
    );
  }
}
