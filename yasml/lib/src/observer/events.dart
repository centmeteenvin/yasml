import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/command.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/view/view.dart';
import 'package:yasml/src/view_model/composition/async_composition.dart'
    show AsyncComposer;
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/view_model/composition/composition_container.dart';
import 'package:yasml/src/view_model/mutation.dart';
import 'package:yasml/src/view_model/mutation_container.dart';
import 'package:yasml/src/world/composition_manager.dart';
import 'package:yasml/src/world/query_manager.dart';
import 'package:yasml/yasml.dart' show AsyncComposer;

part 'sub_events/command_event.dart';
part 'sub_events/composition_event.dart';
part 'sub_events/mutation_event.dart';
part 'sub_events/query_event.dart';
part 'sub_events/view_event.dart';
part 'sub_events/world_event.dart';

/// A base class for all events that can be emitted by the world.
/// It contains the common properties of all events, such as the time
/// of the event and the name of the component that emitted the event.
sealed class Event {
  Event({required this.componentName});

  /// The time when the event was emitted. It is set to the current time when the event is created.
  final DateTime eventTime = DateTime.now();

  /// The name of the component that emitted the event. It is used to identify the source of the event.
  final String componentName;
}
