# yasml

**Yet Another State Management Library** for Flutter.

yasml makes every state transition explicit, traceable, and compiler-verified.
There is no runtime reflection and no implicit rebuilds.
The type system enforces the architecture: if it compiles, the data flow is correct.

### The constitution

1. **Queries describe data.** A query is a pure descriptor — it says *what* to fetch, never *when*.
2. **Commands describe mutations.** A command executes a side-effect and declares which queries it invalidates.
3. **Compositions describe views.** A composition watches queries and projects them into view-model state.
4. **Mutations describe intent.** A mutation is the only API the UI touches — it orchestrates commands on behalf of the user.
5. **The World settles.** After every mutation the world waits until every affected query has refetched and every composition has re-evaluated before returning control. No partial updates. No race conditions.
6. **The compiler is the guardian.** `ViewWidget<T, C, M>` generics tie state, composition, and mutation together — wire them wrong and the code does not compile.

---

### Table of contents

- [Quick start — a counter in five pieces](#quick-start--a-counter-in-five-pieces)
- [The reactive loop](#the-reactive-loop)
- [Keys & identity](#keys--identity)
- [Parameterized queries](#parameterized-queries)
- [Async queries](#async-queries)
- [Stream queries](#stream-queries)
- [Commands that don't invalidate](#commands-that-dont-invalidate)
- [Reading queries from mutations](#reading-queries-from-mutations)
- [Plugins — extending the World](#plugins--extending-the-world)
- [Observers — reacting to events](#observers--reacting-to-events)
- [Debugging & logging](#debugging--logging)
- [Class-based API — when you need it](#class-based-api--when-you-need-it)
- [API reference](#api-reference)

---

## Quick start — a counter in five pieces

The smallest useful yasml app has exactly five moving parts: a **Query**, a **Command**, a **Composition**, a **Mutation**, and a **View**.

### 1. Query — where does the data live?

```dart
int count = 0; // the source of truth (a database, an API, a variable — anything)

final countQuery = SynchronousQuery.create(
  (world) => count,
  key: 'CountQuery',
);
```

`SynchronousQuery.create` takes a function `T Function(World)` and a cache key. The function says *what* to fetch — in this case, the current count. The key uniquely identifies this query for caching and invalidation.

### 2. Command — how does the data change?

```dart
Command<void> updateCount(int newValue) => Command.create(
  (world) { count = newValue; },
  (_) => [countQuery],
);
```

`updateCount` is a function that returns a new `Command`. The first argument is the execute function (the side-effect), the second declares which queries the command invalidates. After execution, the world automatically refetches every listed query.

### 3. Composition — what does the view need?

```dart
final countComposition = SynchronousComposition.create(
  (composer) => composer.watch(countQuery),
  key: 'CountComposition',
);
```

`SynchronousComposition.create` watches one or more queries and projects them into view-model state. When any watched query is invalidated, the composition re-runs automatically.

### 4. Mutation — what can the user do?

```dart
base class CountMutation extends Mutation<SynchronousComposition<int>> {
  const CountMutation({required super.commander});

  Future<void> increment(int current) =>
      commander.dispatch(updateCount(current + 1));

  Future<void> reset() =>
      commander.dispatch(updateCount(0));
}
```

Mutations are the **only** way the UI triggers state changes. They are always class-based because they define named methods — the typed contract between the view and the state layer. `commander.dispatch` executes the command, collects invalidations, and waits for the world to settle before returning.

### 5. View — put it on screen

```dart
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
    return Scaffold(
      body: Center(child: Text(current.toString())),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          FloatingActionButton(
            onPressed: () => notifier.runMutation((m) => m.increment(current)),
            child: Icon(Icons.plus_one),
          ),
          FloatingActionButton(
            onPressed: () => notifier.runMutation((m) => m.reset()),
            child: Icon(Icons.restore),
          ),
        ],
      ),
    );
  }
}
```

`ViewWidget<T, C, M>` binds three types together:
- `T` — the composition state type (`int`)
- `C` — the composition (`SynchronousComposition<int>`)
- `M` — the mutation (`CountMutation`)

Get any of these wrong and the compiler rejects the code.

The `Notifier<M>` record gives you two capabilities:
- `runMutation` — execute a mutation and wait for the world to settle
- `refresh` — manually re-fetch all queries the composition watches

### Bootstrapping the world

```dart
void main() {
  final world = World.create(plugins: [], observers: []);
  runApp(MaterialApp(home: SyncCountView(world: world)));
}
```

The `World` is the root container. Create it once, pass it to your views.

---

## The reactive loop

Every interaction follows the same cycle:

```
  View displays Composition state
       │
       ▼
  User triggers notifier.runMutation(...)
       │
       ▼
  Mutation dispatches Command(s)
       │
       ▼
  Command.execute() performs side-effect
  Command.invalidate() marks Queries stale
       │
       ▼
  Invalidated Queries automatically refetch
       │
       ▼
  World waits until ALL queries have settled
       │
       ▼
  Compositions re-evaluate with new query data
       │
       ▼
  View rebuilds with updated state
       │
       ▼
  runMutation future completes — world is settled
```

The critical guarantee: `runMutation` does not return until the world has completely settled. There is no intermediate state where some queries have updated and others have not.

---

## Keys & identity

Every query and composition requires a `key` — a string that uniquely identifies it in the world's internal registry. Two query objects with the same key are the same query. This is what allows the world to cache, deduplicate, and invalidate correctly.

With the functional API, the key is a parameter you provide:

```dart
final countQuery = SynchronousQuery.create(
  (world) => count,
  key: 'CountQuery',
);
```

For parameterized queries (see next section), include the parameter in the key so each variant is cached separately:

```dart
FutureQuery<User> userById(String id) => FutureQuery.create(
  (world) async { /* ... */ },
  key: 'UserByIdQuery/$id',
);
```

`userById('1')` and `userById('2')` produce queries with different keys — they are independent cache entries. Invalidating one does not affect the other.

---

## Parameterized queries

Queries are descriptors — lightweight objects you create wherever you need them. To make a query depend on input data, wrap the factory in a function:

```dart
FutureQuery<User> userById(String id) => FutureQuery.create(
  (world) async {
    final response = await world.dio.get('/users/$id');
    return User.fromJson(response.data);
  },
  key: 'UserByIdQuery/$id',
);
```

The parameter is captured in the closure and included in the key. Each call creates a query with the right identity — the caching system deduplicates by key.

Pass parameters through the composition the same way:

```dart
AsyncComposition<User> userComposition(String userId) => AsyncComposition.create(
  (composer) => composer.watchFuture(userById(userId)),
  key: 'UserComposition/$userId',
);
```

The view wires it together — the composition getter is the injection point:

```dart
base class UserDetailView
    extends ViewWidget<AsyncValue<User>, AsyncComposition<User>, UserMutation> {
  final String userId;
  const UserDetailView({super.key, required super.world, required this.userId});

  @override
  AsyncComposition<User> get composition => userComposition(userId);

  @override
  MutationConstructor<UserMutation> get mutationConstructor =>
      (commander) => UserMutation(commander: commander);

  @override
  Widget build(BuildContext context, AsyncValue<User> state, Notifier<UserMutation> notifier) {
    return switch (state) {
      AsyncLoading() => Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => ErrorWidget(error),
      AsyncData(:final data) => Text(data.name),
    };
  }
}
```

---

## Async queries

When data comes from a network call or database, use `FutureQuery<T>`. The composition state becomes `AsyncValue<T>`, giving you compile-time exhaustive handling of loading, error, and data states.

### FutureQuery

```dart
final asyncCountQuery = FutureQuery.create(
  (world) async {
    final response = await world.dio.get('/count');
    return response.data['count'] as int;
  },
  key: 'AsyncCountQuery',
);
```

You provide a `Future<T> Function(World)`. The library handles cancellation, state transitions (`AsyncLoading` → `AsyncData` or `AsyncError`), and settlement signalling.

### AsyncComposition

```dart
final asyncCountComposition = AsyncComposition.create(
  (composer) => composer.watchFuture(asyncCountQuery),
  key: 'AsyncCountComposition',
);
```

`AsyncComposition.create` composes async queries. Use `composer.watchFuture(query)` for `FutureQuery` and `composer.watchStream(query)` for `StreamQuery`. The composition state is `AsyncValue<T>`.

### The view handles every state

```dart
base class AsyncCounterView
    extends ViewWidget<AsyncValue<int>, AsyncComposition<int>, AsyncCountMutation> {
  const AsyncCounterView({super.key, required super.world});

  @override
  AsyncComposition<int> get composition => asyncCountComposition;

  @override
  MutationConstructor<AsyncCountMutation> get mutationConstructor =>
      (commander) => AsyncCountMutation(commander: commander);

  @override
  Widget build(
    BuildContext context,
    AsyncValue<int> composition,
    Notifier<AsyncCountMutation> notifier,
  ) {
    return switch (composition) {
      AsyncLoading() => Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => ErrorWidget(error),
      AsyncData(:final data) => Scaffold(
        body: Center(child: Text(data.toString())),
        floatingActionButton: FloatingActionButton(
          onPressed: () => notifier.runMutation((m) => m.increment(data)),
          child: Icon(Icons.plus_one),
        ),
      ),
    };
  }
}
```

`AsyncValue<T>` is a sealed class with three subtypes — `AsyncLoading`, `AsyncData`, and `AsyncError`. Dart's exhaustive switch ensures you handle every state at compile time.

---

## Stream queries

For real-time data (WebSockets, game loops, Firestore snapshots), use `StreamQuery<T>`.

```dart
final gameQuery = StreamQuery<GameState>.create(
  (world, setSettled) {
    final stream = world.game.stream(Duration(milliseconds: 100));
    stream.first.then((_) => setSettled());
    return stream;
  },
  key: 'GameQuery',
);
```

Unlike `FutureQuery`, a `StreamQuery` receives a `setSettled` callback. You decide when the query should be considered settled — typically after the first emission. Each subsequent emission updates the state and notifies compositions.

Stream compositions use `watchStream`:

```dart
final gameComposition = AsyncComposition<GameState>.create(
  (composer) => composer.watchStream(gameQuery),
  key: 'GameComposition',
);
```

---

## Commands that don't invalidate

Not every command needs to trigger a refetch. Stream-driven queries update via the stream itself, so the command can return an empty invalidation list:

```dart
final gameClickCommand = Command<void>.create(
  (world) { world.game.click(); },
  (_) => [],
);
```

The command fires a side-effect (sending a click event into the game loop), and the `StreamQuery` picks up the resulting state change through the stream.

---

## Reading queries from mutations

Mutations can read the current value of any query via `commander.read`:

```dart
base class SomeMutation extends Mutation<SomeComposition> {
  const SomeMutation({required super.commander});

  Future<void> doSomething() async {
    final currentUser = await commander.read(userById('1'));
    await commander.dispatch(updateUser(currentUser.id, {'active': true}));
  }
}
```

`read` subscribes to the query, waits for it to settle, reads the value, and unsubscribes — all in one call.

---

## Plugins — extending the World

Plugins hook into the world lifecycle to initialize and clean up external resources. A common use case is exposing an HTTP client:

```dart
final class DioPlugin implements WorldPlugin {
  late final Dio dio;

  @override
  void onInit(World world) {
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  }

  @override
  Future<void> onDispose() async {
    dio.close();
  }
}
```

Expose the plugin through a typed extension on `World` so queries can access it naturally:

```dart
extension DioPluginExtension on World {
  Dio get dio {
    final plugin = pluginByType<DioPlugin>();
    if (plugin == null) {
      throw StateError('DioPlugin was not found on the World');
    }
    return plugin.dio;
  }
}
```

Now any query can use `world.dio` to make HTTP calls:

```dart
FutureQuery<User> userById(String id) => FutureQuery.create(
  (world) async {
    final response = await world.dio.get('/users/$id');
    return User.fromJson(response.data);
  },
  key: 'UserByIdQuery/$id',
);
```

Register plugins at world creation:

```dart
final world = World.create(
  plugins: [DioPlugin()],
  observers: [],
);
```

---

## Observers — reacting to events

Observers receive every event the world emits. Use them for analytics, crash reporting, or custom devtools.

```dart
class MyObserver implements Observer {
  @override
  void onInit(World world) {}

  @override
  Future<void> onDispose() async {}

  @override
  void onEvent(Event event) {
    switch (event) {
      case QueryInvalidatedEvent():
        print('Query invalidated: ${event.componentName}');
      case MutationExecutedEvent():
        print('Mutation executed: ${event.componentName}');
      default:
        break;
    }
  }
}
```

The `Event` hierarchy is sealed and covers every lifecycle moment: world creation/destruction/settlement, query execution/invalidation, composition execution, mutation dispatch, command execution, and view creation/disposal.

Register observers at world creation:

```dart
final world = World.create(
  plugins: [],
  observers: [MyObserver()],
);
```

A `LoggingObserver` is included automatically in every world — you only need to enable the log levels.

---

## Debugging & logging

yasml uses Dart's `logging` package with hierarchical loggers. Enable them selectively:

```dart
import 'package:logging/logging.dart';
import 'package:yasml/yasml.dart';

void main() {
  hierarchicalLoggingEnabled = true;

  // Enable all yasml logs
  yasmlLog.level = Level.ALL;

  // Or target specific subsystems
  queryLog.level = Level.FINE;
  mutationLog.level = Level.INFO;
  worldLog.level = Level.INFO;

  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
  });

  final world = World.create(plugins: [DioPlugin()], observers: []);
  runApp(MyApp(world: world));
}
```

### Logger hierarchy

| Logger | Exported as | What it logs |
|--------|-------------|-------------|
| `yasml` | `yasmlLog` | Root — enables everything below |
| `yasml.world` | `worldLog` | World lifecycle, settling |
| `yasml.world.query` | — | QueryManager operations |
| `yasml.world.composition` | — | CompositionManager operations |
| `yasml.query` | `queryLog` | QueryContainer: fetch, state changes, invalidation |
| `yasml.composition` | `compositionLog` | CompositionContainer: compose, watch |
| `yasml.mutation` | `mutationLog` | MutationContainer: command dispatch |
| `yasml.command` | `commandLog` | Command execution and invalidation |
| `yasml.view` | `viewLog` | View creation, rebuild, disposal |

---

## Class-based API — when you need it

The functional factories (`.create`) cover the vast majority of use cases. All queries, commands, and compositions can alternatively extend the corresponding base classes:

```dart
base class CountQuery extends SynchronousQuery<int> {
  @override
  String get key => (CountQuery).toString();

  @override
  int query(World world) => count;
}
```

```dart
class UpdateCountCommand implements Command<void> {
  final int newValue;
  UpdateCountCommand({required this.newValue});

  @override
  FutureOr<void> execute(World world) {
    count = newValue;
  }

  @override
  List<Query<dynamic>> invalidate(void result) => [CountQuery()];
}
```

```dart
base class CountComposition extends SynchronousComposition<int> {
  @override
  String get key => (CountComposition).toString();

  @override
  int compose(Composer composer) => composer.watch(CountQuery());
}
```

The class-based approach trades brevity for two things the functional API cannot provide:

- **Stricter type discrimination.** Two functional compositions that return the same type (e.g. `SynchronousComposition<int>`) are interchangeable in the type system — the compiler cannot stop you from passing the wrong one to a view. A named class like `CountComposition` is its own type, so `ViewWidget<int, CountComposition, CountMutation>` rejects any other composition at compile time.
- **Refactor-safe keys.** Deriving the key from the class type literal — `(CountComposition).toString()` — means renaming the class automatically updates the key. With the functional API, keys are plain strings that you maintain by hand.

The class-based API is fully interchangeable with the functional API — both produce objects that the world handles identically.

---

## API reference

### Query types

| Factory | You provide | State type | Use when |
|---|---|---|---|
| `SynchronousQuery.create` | `T Function(World), key` | `T` | Data is available immediately |
| `FutureQuery.create` | `Future<T> Function(World), key` | `AsyncValue<T>` | Data comes from an async call |
| `StreamQuery.create` | `Stream<T> Function(World, VoidCallback), key` | `AsyncValue<T>` | Data is a continuous stream |

### Composition types

| Factory | You provide | Watches via | State type |
|---|---|---|---|
| `SynchronousComposition.create` | `T Function(Composer), key` | `composer.watch(query)` | `T` |
| `AsyncComposition.create` | `Future<T> Function(AsyncComposer), key` | `composer.watchFuture(q)` / `composer.watchStream(q)` | `AsyncValue<T>` |

### Command

| Parameter | Purpose |
|---|---|
| `FutureOr<T> Function(World) execute` | Perform the side-effect |
| `List<Query> Function(T) invalidate` | Declare which queries are now stale |

### Mutation

| Member | Purpose |
|---|---|
| `commander.dispatch(command)` | Execute a command and collect its invalidations |
| `commander.read(query)` | Read the current settled value of a query |

### ViewWidget\<T, C, M\>

| Type parameter | Meaning |
|---|---|
| `T` | The composition state type |
| `C extends Composition<T>` | The composition type |
| `M extends Mutation<C>` | The mutation class |

| Abstract getter/method | Purpose |
|---|---|
| `C get composition` | Provide the composition instance (can pass parameters) |
| `MutationConstructor<M> get mutationConstructor` | Provide the mutation factory |
| `Widget build(BuildContext, T, Notifier<M>)` | Build the widget from state and notifier |

### Notifier\<M\>

| Field | Type | Purpose |
|---|---|---|
| `runMutation` | `Future<R> Function<R>(FutureOr<R> Function(M))` | Execute a mutation, wait for settlement |
| `refresh` | `Future<void> Function()` | Re-fetch all watched queries |

### AsyncValue\<T\>

| Subtype | Properties | Use |
|---|---|---|
| `AsyncLoading<T>` | — | Query is fetching |
| `AsyncData<T>` | `T data` | Query succeeded |
| `AsyncError<T>` | `Object error`, `StackTrace? stackTrace` | Query failed |
