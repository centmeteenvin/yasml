/// Logging infrastructure for yasml.
///
/// yasml uses a hierarchical logging structure that allows users to
/// selectively enable debug output for specific subsystems.
///
/// ## Logger Hierarchy
///
///
///
/// ## Usage
///
/// To enable logging in your application:
///
/// ```dart
/// import 'package:logging/logging.dart';
///
/// void main() {
///   // Enable hierarchical logging so each logger can have its own level
///   hierarchicalLoggingEnabled = true;
///

///   Logger('yasml').level = Level.ALL;
///
///   // Or enable only specific subsystems
///   Logger('yasml.query').level = Level.FINE;
///   Logger('yasml.mutation').level = Level.INFO;
///
///   // Subscribe to log records
///   Logger.root.onRecord.listen((record) {
///     print('${record.level.name}: ${record.loggerName}: ${record.message}');
///   });
///
///   runApp(MyApp());
/// }
/// ```
library;

import 'package:logging/logging.dart';

/// Root logger for all yasml events.
final Logger yasmlLog = Logger('yasml');

/// Logger for [World] lifecycle events (settling, disposal).
final Logger worldLog = Logger('yasml.world');

/// Logger for [QueryManager] operations (subscriptions, invalidations).
final Logger queryManagerLog = Logger('yasml.world.query');

/// Logger for [QueryContainer] operations (fetch, state changes, invalidation).
final Logger queryContainerLog = Logger('yasml.world.query.container');

/// Logger for [Query] definition events (execution, state, settling).
final Logger queryLog = Logger('yasml.world.query.container.definition');

/// Logger for [CompositionManager] operations.
final Logger compositionManagerLog = Logger('yasml.world.composition');

/// Logger for [CompositionContainer] operations (compose, watch).
final Logger compositionContainerLog = Logger('yasml.world.composition.container');

/// Logger for [Composition] definition events.
final Logger compositionLog = Logger('yasml.world.composition.container.definition');

/// Logger for [MutationContainer] operations (command dispatch, mutation runs).
final Logger mutationContainerLog = Logger('yasml.world.mutation.container');

/// Logger for [Mutation] definition events.
final Logger mutationLog = Logger('yasml.world.mutation.container.definition');

/// Logger for [Command] execution and invalidation.
final Logger commandLog = Logger('yasml.world.command.definition');
