import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yasml/yasml.dart';

int count = 0;

base class CountQuery extends SynchronousQuery<int> {
  @override
  String get key => "CountQuery";

  @override
  int query(World world) {
    return count;
  }
}

class UpdateCountCommand implements Command<void> {
  UpdateCountCommand({required this.newValue});
  final int newValue;

  @override
  FutureOr<void> execute(World world) {
    count = newValue;
  }

  @override
  List<Query<dynamic>> invalidate(void result) {
    return [CountQuery()];
  }
}

base class CountMutation extends Mutation<CountComposition> {
  const CountMutation({required super.commander});

  Future<void> increment(int current) {
    return commander.dispatch(UpdateCountCommand(newValue: current + 1));
  }

  Future<void> reset() {
    return commander.dispatch(UpdateCountCommand(newValue: 0));
  }
}

base class CountComposition extends SynchronousComposition<int> {
  @override
  int compose(Composer composer) {
    final count = composer.watch(CountQuery());
    return count;
  }

  @override
  String get key => 'CountComposition';
}

base class SyncCountView extends ViewWidget<int, CountComposition, CountMutation> {
  const SyncCountView({super.key, required super.world});

  @override
  CountComposition get composition => CountComposition();

  @override
  MutationConstructor<CountMutation> get mutationConstructor =>
      (dispatcher) => CountMutation(commander: dispatcher);

  @override
  Widget build(BuildContext context, int current, Notifier<CountMutation> notifier) {
    return Scaffold(
      body: Center(child: Text(current.toString())),
      floatingActionButton: Column(
        mainAxisSize: .min,
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
