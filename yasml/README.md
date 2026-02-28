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
- [API reference](#api-reference)

---

## Quick start — a counter in five pieces

The smallest useful yasml app has exactly five moving parts: a **Query**, a **Command**, a **Composition**, a **Mutation**, and a **View**.

### 1. Query — where does the data live?

```dart
int count = 0; // the source of truth (a database, an API, a variable — anything)

base class CountQuery extends SynchronousQuery<int> {
  @override
  String get key => (CountQuery).toString();

  @override
  int query(World world) => count;
}
```

A `SynchronousQuery<T>` implements one method: `T query(World)`. The `key` uniquely identifies this query for caching and invalidation.

### 2. Command — how does the data change?

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

`execute` performs the mutation. `invalidate` returns the list of queries that are now stale — the world will automatically refetch them.

### 3. Composition — what does the view need?

```dart
base class CountComposition extends SynchronousComposition<int> {
  @override
  String get key => (CountComposition).toString();

  @override
  int compose(Composer composer) {
    return composer.watch(CountQuery());
  }
}
```

`compose` watches one or more queries and returns the projected state. When any watched query is invalidated, the composition re-runs automatically.

### 4. Mutation — what can the user do?

```dart
base class CountMutation extends Mutation<CountComposition> {
  const CountMutation({required super.commander});

  Future<void> increment(int current) =>
      commander.dispatch(UpdateCountCommand(newValue: current + 1));

  Future<void> reset() =>
      commander.dispatch(UpdateCountCommand(newValue: 0));
}
```

Mutations are the **only** way the UI triggers state changes. `commander.dispatch` executes the command, collects invalidations, and waits for the world to settle before returning.

### 5. View — put it on screen

```dart
base class SyncCountView
    extends ViewWidget<int, CountComposition, CountMutation> {
  const SyncCountView({super.key, required super.world});

  @override
  CountComposition get composition => CountComposition();

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
- `C` — the composition (`CountComposition`)
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

Every query and composition requires a `String get key`. This key is **not** a magic string — it is the identity used by the world's internal registry to cache and deduplicate instances. Two query objects with the same key are the same query. This is what allows `composer.watch(CountQuery())` to work — every call creates a new Dart object, but the registry recognizes them as the same query by key.

The recommended pattern is to derive the key from the class type:

```dart
@override
String get key => (CountQuery).toString();
```

The parentheses matter. `(CountQuery)` is a Dart type literal — wrapping it in parentheses and calling `.toString()` produces the string `"CountQuery"`. This is refactor-safe: rename the class and the key updates automatically.

For parameterized queries (see next section), include the parameter in the key so each variant is cached separately:

```dart
@override
String get key => '${(UserByIdQuery).toString()}/$id';
```

---

## Parameterized queries

Queries are descriptors — they are lightweight objects you instantiate wherever you need them. To make a query dependent on input data, add a field to the class, just like you pass data to a command:

```dart
base class UserByIdQuery extends FutureQuery<User> {
  final String id;
  UserByIdQuery({required this.id});

  @override
  String get key => '${(UserByIdQuery).toString()}/$id';

  @override
  Future<User> query(World world) async {
    final response = await world.dio.get('/users/$id');
    return User.fromJson(response.data);
  }
}
```

Because the key includes the `id`, `UserByIdQuery(id: '1')` and `UserByIdQuery(id: '2')` are two independent entries in the cache. Invalidating one does not affect the other.

Pass parameters through the composition, which receives them from the view:

```dart
base class UserComposition extends AsyncComposition<User> {
  final String userId;
  UserComposition({required this.userId});

  @override
  String get key => '${(UserComposition).toString()}/$userId';

  @override
  Future<User> compose(AsyncComposer composer) {
    return composer.watchFuture(UserByIdQuery(id: userId));
  }
}
```

The view wires it together — the composition getter is the injection point:

```dart
base class UserDetailView
    extends ViewWidget<AsyncValue<User>, UserComposition, UserMutation> {
  final String userId;
  const UserDetailView({super.key, required super.world, required this.userId});

  @override
  UserComposition get composition => UserComposition(userId: userId);

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
base class AsyncCountQuery extends FutureQuery<int> {
  @override
  String get key => (AsyncCountQuery).toString();

  @override
  Future<int> query(World world) async {
    final response = await world.dio.get('/count');
    return response.data['count'] as int;
  }
}
```

You implement `Future<T> query(World)`. The library handles cancellation, state transitions (`AsyncLoading` → `AsyncData` or `AsyncError`), and settlement signalling.

### AsyncComposition

```dart
base class AsyncCountComposition extends AsyncComposition<int> {
  @override
  String get key => (AsyncCountComposition).toString();

  @override
  Future<int> compose(AsyncComposer composer) {
    return composer.watchFuture(AsyncCountQuery());
  }
}
```

`AsyncComposition<T>` composes async queries. Use `composer.watchFuture(query)` for `FutureQuery` and `composer.watchStream(query)` for `StreamQuery`. The composition state is `AsyncValue<T>`.

### The view handles every state

```dart
base class AsyncCounterView
    extends ViewWidget<AsyncValue<int>, AsyncCountComposition, AsyncCountMutation> {
  const AsyncCounterView({super.key, required super.world});

  @override
  AsyncCountComposition get composition => AsyncCountComposition();

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
base class GameQuery extends StreamQuery<GameState> {
  @override
  String get key => (GameQuery).toString();

  @override
  Stream<GameState> query(World world, VoidCallback setSettled) {
    final stream = world.game.stream(Duration(milliseconds: 100));
    stream.first.then((_) => setSettled());
    return stream;
  }
}
```

Unlike `FutureQuery`, a `StreamQuery` receives a `setSettled` callback. You decide when the query should be considered settled — typically after the first emission. Each subsequent emission updates the state and notifies compositions.

Stream compositions use `watchStream`:

```dart
base class GameComposition extends AsyncComposition<GameState> {
  @override
  String get key => (GameComposition).toString();

  @override
  Future<GameState> compose(AsyncComposer composer) async {
    return await composer.watchStream(GameQuery());
  }
}
```

---

## Commands that don't invalidate

Not every command needs to trigger a refetch. Stream-driven queries update via the stream itself, so the command can return an empty invalidation list:

```dart
class GameClickCommand implements Command<void> {
  @override
  FutureOr<void> execute(World world) {
    world.game.click();
  }

  @override
  List<Query<dynamic>> invalidate(void result) => [];
}
```

The command fires a side-effect (sending a click event into the game loop), and the `StreamQuery` picks up the resulting state change through the stream.

---

## Reading queries from mutations

Mutations can read the current value of any query via `commander.read`:

```dart
base class SomeMutation extends Mutation<SomeComposition> {
  const SomeMutation({required super.commander});

  Future<void> doSomething() async {
    final currentUser = await commander.read(UserByIdQuery(id: '1'));
    await commander.dispatch(UpdateCommand(userId: currentUser.id));
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
base class UserByIdQuery extends FutureQuery<User> {
  final String id;
  UserByIdQuery({required this.id});

  @override
  String get key => '${(UserByIdQuery).toString()}/$id';

  @override
  Future<User> query(World world) async {
    final response = await world.dio.get('/users/$id');
    return User.fromJson(response.data);
  }
}
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

## API reference

### Query types

| Base class | You implement | State type | Use when |
|---|---|---|---|
| `SynchronousQuery<T>` | `T query(World)` | `T` | Data is available immediately |
| `FutureQuery<T>` | `Future<T> query(World)` | `AsyncValue<T>` | Data comes from an async call |
| `StreamQuery<T>` | `Stream<T> query(World, VoidCallback setSettled)` | `AsyncValue<T>` | Data is a continuous stream |

### Composition types

| Base class | You implement | Watches via | State type |
|---|---|---|---|
| `SynchronousComposition<T>` | `T compose(Composer)` | `composer.watch(query)` | `T` |
| `AsyncComposition<T>` | `Future<T> compose(AsyncComposer)` | `composer.watchFuture(query)` / `composer.watchStream(query)` | `AsyncValue<T>` |

### Command

| Method | Purpose |
|---|---|
| `FutureOr<T> execute(World)` | Perform the side-effect |
| `List<Query> invalidate(T result)` | Declare which queries are now stale |

### Mutation

| Member | Purpose |
|---|---|
| `commander.dispatch(command)` | Execute a command and collect its invalidations |
| `commander.read(query)` | Read the current settled value of a query |

### ViewWidget\<T, C, M\>

| Type parameter | Meaning |
|---|---|
| `T` | The composition state type |
| `C extends Composition<T>` | The composition class |
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
