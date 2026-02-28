import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yasml/yasml.dart';

int counter = 0;
Future<void> sleep() {
  return Future.delayed(Durations.long4);
}

final asyncCountQuery = FutureQuery.create(
  (world) async {
    await sleep();
    return counter;
  },
  key: 'AsyncCountQuery',
);

Command<void> updateAsyncCount(int newValue) => Command.create(
  (world) async {
    await sleep();
    counter = newValue;
  },
  (_) => [asyncCountQuery],
);

final asyncCountComposition = AsyncComposition.create(
  (composer) => composer.watchFuture(asyncCountQuery),
  key: 'AsyncCountComposition',
);

base class AsyncCountMutation extends Mutation<AsyncComposition<int>> {
  const AsyncCountMutation({required super.commander});

  Future<void> increment(int current) async {
    await commander.dispatch(updateAsyncCount(current + 1));
  }

  Future<void> reset() async {
    await commander.dispatch(updateAsyncCount(0));
  }
}

base class AsyncCounterView extends ViewWidget<AsyncValue<int>, AsyncComposition<int>, AsyncCountMutation> {
  const AsyncCounterView({super.key, required super.world});

  @override
  AsyncComposition<int> get composition => asyncCountComposition;

  @override
  MutationConstructor<AsyncCountMutation> get mutationConstructor =>
      (commander) => AsyncCountMutation(commander: commander);

  @override
  Widget build(BuildContext context, AsyncValue<int> composition, Notifier<AsyncCountMutation> notifier) {
    return switch (composition) {
      AsyncLoading() => Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => ErrorWidget(error),
      AsyncData(:final data) => Scaffold(
        body: Center(child: Text(data.toString())),
        floatingActionButton: AsyncCounterActions(current: data, notifier: notifier),
      ),
    };
  }
}

class AsyncCounterActions extends HookWidget {
  final int current;
  final Notifier<AsyncCountMutation> notifier;
  const AsyncCounterActions({super.key, required this.current, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);

    Future<void> handleIncrement() async {
      isLoading.value = true;
      await notifier.runMutation((mutation) => mutation.increment(current));
      isLoading.value = false;
    }

    Future<void> handleReset() async {
      isLoading.value = true;
      await notifier.runMutation((mutation) => mutation.reset());
      isLoading.value = false;
    }

    if (isLoading.value) {
      return CircularProgressIndicator();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        FloatingActionButton(onPressed: handleIncrement, child: Icon(Icons.plus_one)),
        FloatingActionButton(onPressed: handleReset, child: Icon(Icons.restore)),
      ],
    );
  }
}
