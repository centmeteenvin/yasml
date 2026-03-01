# yasml

**Yet Another State Management Library** for Flutter.

yasml makes every state transition explicit, traceable, and compiler-verified.
There is no runtime reflection and no implicit rebuilds.
The type system enforces the architecture: if it compiles, the data flow is correct.

## The constitution

1. **Queries describe data.** A query is a pure descriptor — it says *what* to fetch, never *when*.
2. **Commands describe mutations.** A command executes a side-effect and declares which queries it invalidates.
3. **Compositions describe views.** A composition watches queries and projects them into view-model state.
4. **Mutations describe intent.** A mutation is the only API the UI touches — it orchestrates commands on behalf of the user.
5. **The World settles.** After every mutation the world waits until every affected query has refetched and every composition has re-evaluated before returning control. No partial updates. No race conditions.
6. **The compiler is the guardian.** `ViewWidget<T, C, M>` generics tie state, composition, and mutation together — wire them wrong and the code does not compile.

## Quick start

Add yasml to your `pubspec.yaml`:

```yaml
dependencies:
  yasml: ^0.2.0
```

Then build a counter in five pieces — a **Query**, a **Command**, a **Composition**, a **Mutation**, and a **View**:

```dart
// 1. Query — where does the data live?
int count = 0;
final countQuery = SynchronousQuery.create(
  (world) => count,
  key: 'CountQuery',
);

// 2. Command — how does the data change?
Command<void> updateCount(int newValue) => Command.create(
  (world) { count = newValue; },
  (_) => [countQuery],
);

// 3. Composition — what does the view need?
final countComposition = SynchronousComposition.create(
  (composer) => composer.watch(countQuery),
  key: 'CountComposition',
);

// 4. Mutation — what can the user do?
base class CountMutation extends Mutation<SynchronousComposition<int>> {
  const CountMutation({required super.commander});
  Future<void> increment(int current) =>
      commander.dispatch(updateCount(current + 1));
}

// 5. View — put it on screen
base class SyncCountView
    extends ViewWidget<int, SynchronousComposition<int>, CountMutation> {
  const SyncCountView({super.key, required super.world});

  @override
  SynchronousComposition<int> get composition => countComposition;

  @override
  MutationConstructor<CountMutation> get mutationConstructor =>
      (commander) => CountMutation(commander: commander);

  @override
  Widget build(BuildContext context, int current, Notifier<CountMutation> notifier) {
    return FloatingActionButton(
      onPressed: () => notifier.runMutation((m) => m.increment(current)),
      child: Text(current.toString()),
    );
  }
}
```

For the full documentation — async queries, stream queries, plugins, observers, debugging, and the class-based API — see the [package README](yasml/README.md).

## Repository structure

```
yasml/              # The library package (published to pub.dev)
yasml_example/      # Example Flutter app demonstrating all features
```

## Requirements

- Dart SDK `^3.7.0`
- Flutter `>=3.35.0`

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

## License

This project is licensed under the [GNU Lesser General Public License v2.1](LICENSE).
