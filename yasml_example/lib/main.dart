import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:yasml/yasml.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  worldLog.level = Level.FINE;

  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
  });

  final world = World();
  runApp(MainApp(world: world));
}

class MainApp extends StatelessWidget {
  final World world;
  const MainApp({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: CountViewWidget(world: world));
  }
}

int count = 0;

base class CountQuery extends SynchronousQuery {
  @override
  String get key => "CountQuery";

  @override
  query(World world) {
    return count;
  }
}

class UpdateCountCommand implements Command<void> {
  UpdateCountCommand({required this.newValue});
  final int newValue;

  @override
  FutureOr<void> execute() {
    count = newValue;
  }

  @override
  List<Query<dynamic>> invalidate(void result) {
    return [CountQuery()];
  }
}

base class CountComposition extends Composition<int> {
  @override
  void compose(Composer composer, ValueChanged<int> setState, VoidCallback setSettled) {
    final count = composer.watch(CountQuery());
    setState(count);
    setSettled();
  }

  @override
  int initialValue(World world) {
    return 0;
  }

  @override
  String get key => 'CountComposition';
}

class CountMutation extends Mutation<CountComposition> {
  const CountMutation({required super.dispatcher});

  Future<void> increment(int current) {
    return dispatcher.dispatch(UpdateCountCommand(newValue: current + 1));
  }
}

base class CountViewWidget extends ViewWidget<int, CountComposition, CountMutation> {
  const CountViewWidget({super.key, required super.world});

  @override
  CountComposition get composition => CountComposition();

  @override
  MutationConstructor<CountMutation> get mutationConstructor =>
      (dispatcher) => CountMutation(dispatcher: dispatcher);

  @override
  Widget build(BuildContext context, int current, MutationRunner<CountMutation> runMutation) {
    return Scaffold(
      body: Center(child: Text(current.toString())),
      floatingActionButton: FloatingActionButton(
        onPressed: () => runMutation((mutation) => mutation.increment(current)),
      ),
    );
  }
}
