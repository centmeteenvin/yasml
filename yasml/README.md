# yasml

yasml (Yet Another State Management Library) is a Flutter state management solution that emphasizes a clear separation between data fetching, state mutation, and view composition. It provides a highly type-safe API where the compiler assists in preventing common architectural mistakes.

## Core Concepts

The library is built around several architectural pillars:

*   World: The central context that manages the lifecycle of queries and compositions. It tracks the "settled" state of the application.
*   Query: A descriptor used to fetch a specific piece of data from the world. Queries can be synchronous or asynchronous.
*   Command: A discrete unit of work that performs a mutation on the world. Commands define which queries they invalidate upon completion.
*   Mutation: A class that orchestrates one or more commands. It provides the high-level API used by the user interface to trigger changes.
*   Composition: A specialized view-model that watches multiple queries and combines them into a single state object for the view.
*   View: A reactive widget that listens to a composition and provides access to a typed mutation interface.

## The Reactive Loop

The library follows a strict unidirectional data flow:

1.  The View displays data received from a Composition.
2.  User interaction triggers a method on a Mutation class via `runMutation`.
3.  The Mutation dispatches one or more Commands to modify the world.
4.  Each Command identifies which Queries are now stale and must be invalidated.
5.  Invalidated Queries automatically refetch their data.
6.  The World waits until all fetching is complete (it settles).
7.  Compositions are re-evaluated based on the new query results.
8.  The View is notified and rebuilds with the updated state.

## Implementation Example

### Defining a Query and Command

Queries and Commands are descriptors that identify specific data or actions.

```dart
base class UserQuery extends FutureQuery<User> {
  @override
  String get key => 'user_query';

  @override
  Future<User> fetch(World world) async {
    return await api.fetchUser();
  }
}

class UpdateNameCommand implements Command<User> {
  final String newName;
  UpdateNameCommand(this.newName);

  @override
  Future<User> execute() async {
    return await api.updateName(newName);
  }

  @override
  List<Query> invalidate(User result) => [UserQuery()];
}
```

### Creating the Mutation Logic

Mutations bind to a Composition and expose methods for the UI.

```dart
class UserMutation extends Mutation<UserComposition> {
  const UserMutation({required super.dispatcher});

  Future<void> updateName(String name) async {
    await dispatcher.dispatch(UpdateNameCommand(name));
  }
}
```

### Building the View

Use `ViewWidget` to glue everything together with full type safety.

```dart
base class UserProfileView extends ViewWidget<User, UserComposition, UserMutation> {
  const UserProfileView({super.key, required super.world});

  @override
  UserComposition get composition => UserComposition();

  @override
  MutationConstructor<UserMutation> get mutationConstructor =>
      (dispatcher) => UserMutation(dispatcher: dispatcher);

  @override
  Widget build(BuildContext context, User user, MutationRunner<UserMutation> runMutation) {
    return Column(
      children: [
        Text(user.name),
        ElevatedButton(
          onPressed: () => runMutation((m) => m.updateName('New Name')),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
```

## Advanced Features

*   Asynchronous Settling: Mutations return only after the world has completely settled, preventing partial state updates.
*   Descriptor-based Keys: Queries and Compositions are identity-checked by keys, allowing for easy parameterization and caching.
*   Strong Typing: The `ViewWidget` generics ensure that the compiler verifies the relationship between state, composition, and mutation.
*   Side-effect Prevention: State changes are isolated within Commands, ensuring a predictable and testable application state.
*   Dependency Tracking: Compositions automatically track which queries they watch and only re-run when necessary.

## Debugging & Observability

yasml uses Dart's `logging` package with a hierarchical logger structure, allowing you to selectively enable debug output for specific subsystems.

### Logger Hierarchy

| Logger | Description |
|--------|-------------|
| `yasml` | Root logger for all yasml events |
| `yasml.world` | World lifecycle (initialization, settling) |
| `yasml.world.query` | QueryManager operations (subscriptions, invalidations) |
| `yasml.world.composition` | CompositionManager operations |
| `yasml.query` | QueryContainer operations (fetch, state, invalidation) |
| `yasml.composition` | CompositionContainer operations (compose, watch) |
| `yasml.mutation` | MutationContainer operations (command dispatch) |

### Enabling Logs

```dart
import 'package:logging/logging.dart';
import 'package:yasml/yasml.dart';

void main() {
  // Enable hierarchical logging
  hierarchicalLoggingEnabled = true;

  // Enable all yasml logs
  Logger('yasml').level = Level.ALL;

  // Or enable only specific subsystems
  Logger('yasml.query').level = Level.FINE;
  Logger('yasml.mutation').level = Level.INFO;

  // Subscribe to log records
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
  });

  runApp(MyApp());
}
```

### Exported Loggers

For convenience, yasml exports the logger instances directly:

```dart
import 'package:yasml/yasml.dart';

// Access loggers directly
yasmlLog.level = Level.ALL;
queryLog.level = Level.FINE;
mutationLog.level = Level.INFO;
```

