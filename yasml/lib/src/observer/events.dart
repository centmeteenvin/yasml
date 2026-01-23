import 'package:yasml/src/model/query/query.dart';

part 'sub_events/command_event.dart';
part 'sub_events/composition_event.dart';
part 'sub_events/mutation_event.dart';
part 'sub_events/query_event.dart';
part 'sub_events/view_event.dart';
part 'sub_events/world_event.dart';

sealed class Event {
  final DateTime eventTime = DateTime.now();
  final String componentName;

  Event({required this.componentName});
}
