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
final Logger queryLog = Logger('yasml.world.query');

/// Logger for [CompositionManager] operations.
final Logger compositionLog = Logger('yasml.world.composition');

/// Logger for [Mutation] definition events.
final Logger mutationLog = Logger('yasml.world.mutation');

/// Logger for [Command] execution and invalidation.
final Logger commandLog = Logger('yasml.world.command');

final Logger viewLog = Logger('yasml.world.view');
