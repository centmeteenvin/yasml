import 'package:yasml/src/logging/logging.dart';
import 'package:yasml/src/model/command.dart';
import 'package:yasml/src/observer/events.dart';
import 'package:yasml/src/observer/observer.dart';
import 'package:yasml/src/view/view.dart';
import 'package:yasml/src/view_model/mutation.dart';
import 'package:yasml/src/world/world.dart';

/// An Observer that logs all events to the [worldLog] logger or it's children.
/// It is always present when running [World.create].
final class LoggingObserver implements Observer {
  /// Default constructor
  const LoggingObserver();

  @override
  Future<void> onDispose() async {}

  /// The default formatting from a LogEvent to a string
  String baseLog(Event event) {
    return '${event.eventTime.toIso8601String()}: [${event.componentName}] -';
  }

  @override
  void onEvent(Event event) {
    switch (event) {
      case WorldEvent():
        onWorldEvent(event);
      case QueryEvent():
        onQueryEvent(event);
      case CompositionEvent():
        onCompositionEvent(event);
      case ViewEvent():
        onViewEvent(event);
      case MutationEvent():
        onMutationEvent(event);
      case CommandEvent():
        onCommandEvent(event);
    }
  }

  /// Called when [Event] is of type [WorldEvent]
  void onWorldEvent(WorldEvent event) {
    switch (event) {
      case WorldCreatedEvent():
        worldLog.info('${baseLog(event)} Created');
      case WorldDestroyedEvent():
        worldLog.info('${baseLog(event)} Destroyed');
      case WorldSettledEvent():
        worldLog.fine('${baseLog(event)} Settled');
    }
  }

  /// Called when [Event] is of type [QueryEvent]
  void onQueryEvent(QueryEvent event) {
    switch (event) {
      case QueryContainerCreatedEvent(:final reason):
        queryLog.finer(
          '${baseLog(event)} Query Container created, reason: $reason',
        );
      case QueryContainerDisposedEvent(:final reason):
        queryLog.finer(
          '${baseLog(event)} Query Container disposed, reason: $reason',
        );
      case QueryContainerNewListenerEvent(:final queryListenableType):
        queryLog.fine('${baseLog(event)} New listener: $queryListenableType ');
      case QueryContainerListenerRemovedEvent(:final queryListenableType):
        queryLog.fine(
          '${baseLog(event)} Removed listener: $queryListenableType ',
        );
      case QueryExecutedEvent():
        queryLog.info('${baseLog(event)} Executed');
      case QuerySetStateEvent(:final newState):
        queryLog.fine('${baseLog(event)} Updated state to $newState');
      case QuerySettledEvent():
        queryLog.finer('${baseLog(event)} Settled');
      case QueryInvalidatedEvent():
        queryLog.info('${baseLog(event)} Invalidated');
    }
  }

  /// Called when [Event] is of type [CompositionEvent]
  void onCompositionEvent(CompositionEvent event) {
    switch (event) {
      case CompositionContainerCreatedEvent(:final reason):
        compositionLog.finer(
          '${baseLog(event)} Query Container created, reason: $reason',
        );
      case CompositionContainerDisposedEvent(:final reason):
        compositionLog.finer(
          '${baseLog(event)} Query Container created, reason: $reason',
        );
      case CompositionContainerNewListenerEvent(
        :final compositionListenableType,
      ):
        compositionLog.fine(
          '${baseLog(event)} New listener: $compositionListenableType ',
        );
      case CompositionContainerListenerRemovedEvent(
        :final compositionListenableType,
      ):
        compositionLog.fine(
          '${baseLog(event)} New listener: $compositionListenableType ',
        );
      case CompositionExecutedEvent():
        compositionLog.info('${baseLog(event)} Executed');
      case CompositionSetStateEvent(:final newState):
        compositionLog.fine('${baseLog(event)} Updated state to $newState');
      case CompositionSettledEvent():
        compositionLog.finer('${baseLog(event)} Settled');
      case CompositionWatchEvent(:final watchingQueryKey, :final isAsync):
        compositionLog.fine(
          '${baseLog(event)} Watching query $watchingQueryKey ${isAsync ? 'asynchronously' : 'synchronously'}',
        );
      case CompositionUnsubscribeEvent(:final queryKey):
        compositionLog.fine('${baseLog(event)} Unsubscribing from $queryKey');
      case CompositionRefreshEvent(:final queriesToInvalidate):
        compositionLog.info(
          '${baseLog(event)} Refreshing by invalidating following queries:\n[${queriesToInvalidate.map((q) => q.key).join(', ')}]',
        );
    }
  }

  /// Triggered when an event at the [ViewWidget] level is triggered
  /// Logs using the [viewLog]
  void onViewEvent(ViewEvent event) {
    switch (event) {
      case ViewBuildEvent():
        viewLog.finer('${baseLog(event)} Build');
      case ViewCreatedEvent():
        viewLog.fine('${baseLog(event)} Created');
      case ViewDisposedEvent():
        viewLog.fine('${baseLog(event)} Disposed');
    }
  }

  /// Triggered when an event at the [Mutation] level is triggered
  /// Logs using the [mutationLog]
  void onMutationEvent(MutationEvent event) {
    switch (event) {
      case MutationContainerCreatedEvent():
        mutationLog.fine('${baseLog(event)} Mutation Container created');
      case MutationExecutedEvent():
        mutationLog.info('${baseLog(event)} Executed');
      case MutationInvalidationEvent(:final queriesToInvalidate):
        mutationLog.info(
          '${baseLog(event)} Following queries are being invalidated: \n[${queriesToInvalidate.map((q) => q.key).join(', ')}]',
        );
      case MutationCommandDispatchedEvent(:final commandType):
        mutationLog.fine('${baseLog(event)} Dispatching command $commandType');
      case MutationQueryReadEvent(:final queryKey, :final queryState):
        mutationLog.fine(
          '${baseLog(event)} Read query $queryKey with state $queryState',
        );
    }
  }

  /// Triggered when an event at the [Command] level is triggered
  /// Logs using the [commandLog]
  void onCommandEvent(CommandEvent event) {
    switch (event) {
      case CommandExecutedEvent():
        commandLog.info('${baseLog(event)} Executed');
      case CommandQueryInvalidationEvent(:final queriesToInvalidate):
        commandLog.info(
          '${baseLog(event)} After execution following queries are to be invalidated:\n[${queriesToInvalidate.map((q) => q.key).join(', ')}]',
        );
    }
  }

  @override
  void onInit(World world) {}
}
