import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:yasml/yasml.dart';
import 'package:yasml_example/async_counter.dart';
import 'package:yasml_example/external/get_it.dart';
import 'package:yasml_example/game/view/game_view.dart';
import 'package:yasml_example/game/world/game_plugin.dart';
import 'package:yasml_example/sync_counter.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  worldLog.level = Level.INFO;

  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
  });

  final world = World.create(plugins: [GamePlugin(), GetItPlugin()], observers: []);
  runApp(MainApp(world: world));
}

class MainApp extends StatelessWidget {
  final World world;
  const MainApp({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage(world: world));
  }
}

class HomePage extends HookWidget {
  final World world;
  const HomePage({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    final activeIndex = useState(0);

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.straight), label: 'sync counter'),
          BottomNavigationBarItem(icon: Icon(Icons.hourglass_bottom), label: 'async counter'),
          BottomNavigationBarItem(icon: Icon(Icons.cookie), label: 'Game'),
        ],
        currentIndex: activeIndex.value,
        onTap: (index) => activeIndex.value = index,
      ),
      body: switch (activeIndex.value) {
        0 => SyncCountView(world: world),
        1 => AsyncCounterView(world: world),
        2 => GameView(world: world),
        _ => ErrorWidget(ArgumentError.value(activeIndex.value, 'activeIndex', 'incorrect range')),
      },
    );
  }
}
