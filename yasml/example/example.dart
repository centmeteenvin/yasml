import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yasml/yasml.dart';

// --- Model ---

class Todo {
  const Todo({required this.id, required this.title, required this.completed});

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'] as int,
    title: json['title'] as String,
    completed: json['completed'] as bool,
  );

  final int id;
  final String title;
  final bool completed;
}

// --- Data layer ---

final Dio dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));

// 1. Query — fetches the todo list from the API
final FutureQuery<List<Todo>> todosQuery = FutureQuery.create(
  (world) async {
    final response = await dio.get<List<dynamic>>('/todos?_limit=10');
    return response.data!.map((dynamic e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
  },
  key: 'TodosQuery',
);

// 2. Command — toggles a todo's completion and invalidates the query
Command<void> toggleTodo(Todo todo) => Command.create(
  (world) async {
    await dio.patch<void>('/todos/${todo.id}', data: {'completed': !todo.completed});
  },
  (_) => [todosQuery],
);

// 3. Composition — watches the query and projects it into view-model state
final AsyncComposition<List<Todo>> todosComposition = AsyncComposition.create(
  (composer) => composer.watchFuture(todosQuery),
  key: 'TodosComposition',
);

// 4. Mutation — the only API the UI touches
base class TodosMutation extends Mutation<AsyncComposition<List<Todo>>> {
  const TodosMutation({required super.commander});

  Future<void> toggle(Todo todo) => commander.dispatch(toggleTodo(todo));
}

// 5. View — binds composition + mutation to a widget
base class TodosView extends ViewWidget<AsyncValue<List<Todo>>, AsyncComposition<List<Todo>>, TodosMutation> {
  const TodosView({required super.world, super.key});

  @override
  AsyncComposition<List<Todo>> get composition => todosComposition;

  @override
  MutationConstructor<TodosMutation> get mutationConstructor => (commander) => TodosMutation(commander: commander);

  @override
  Widget build(BuildContext context, AsyncValue<List<Todo>> state, Notifier<TodosMutation> notifier) {
    return switch (state) {
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => Center(child: Text('Error: $error')),
      AsyncData(:final data) => ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final todo = data[index];
          return CheckboxListTile(
            value: todo.completed,
            title: Text(todo.title),
            onChanged: (_) => notifier.runMutation((m) => m.toggle(todo)),
          );
        },
      ),
    };
  }
}

// Bootstrap
void main() {
  final world = World.create(plugins: [], observers: []);
  runApp(MaterialApp(home: Scaffold(body: TodosView(world: world))));
}
