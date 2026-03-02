part of '../events.dart';

/// Events associated with [Composition] lifecycle
sealed class CompositionEvent extends Event {
  ///
  CompositionEvent({required this.compositionKey}) : super(componentName: 'Composition - $compositionKey');

  /// The [Composition.key] that identifies the composition.
  final String compositionKey;
}

/// When a new [CompositionContainer] is created due to a subscription to it.
final class CompositionContainerCreatedEvent extends CompositionEvent {
  ///
  CompositionContainerCreatedEvent({
    required super.compositionKey,
    required this.reason,
  });

  /// The reason the container was created
  final String reason;
}

/// When an existing [CompositionContainer] is disposed.
final class CompositionContainerDisposedEvent extends CompositionEvent {
  ///
  CompositionContainerDisposedEvent({
    required super.compositionKey,
    required this.reason,
  });

  /// The reason the container was disposed.
  final String reason;
}

/// When a [CompositionContainer] get a new listener
final class CompositionContainerNewListenerEvent extends CompositionEvent {
  ///
  CompositionContainerNewListenerEvent({
    required super.compositionKey,
    required this.compositionListenableType,
  });

  /// The runtimeType of the new listener.
  final Type compositionListenableType;
}

/// When a listener is removed form a [CompositionContainer].
final class CompositionContainerListenerRemovedEvent extends CompositionEvent {
  ///
  CompositionContainerListenerRemovedEvent({
    required super.compositionKey,
    required this.compositionListenableType,
  });

  /// The runtimeType of the listener that was removed.
  final Type compositionListenableType;
}

/// When the [Composition.execute] method is called.
final class CompositionExecutedEvent extends CompositionEvent {
  ///
  CompositionExecutedEvent({required super.compositionKey});
}

/// When the [Composition.execute] method calls [CompositionContainer.setState]
final class CompositionSetStateEvent extends CompositionEvent {
  ///
  CompositionSetStateEvent({
    required super.compositionKey,
    required this.newState,
  });

  /// The value of the state that was set.
  final dynamic newState;
}

/// When the [Composition.execute] method notifies that it is settled: [CompositionContainer.isSettled].
final class CompositionSettledEvent extends CompositionEvent {
  ///
  CompositionSettledEvent({required super.compositionKey});
}

/// When the [Composition.execute] method calls [Composer.watch] to watch a [Query]
final class CompositionWatchEvent extends CompositionEvent {
  ///
  CompositionWatchEvent({
    required super.compositionKey,
    required this.watchingQueryKey,
    required this.isAsync,
  });

  /// The key of the query that is being watched.
  final String watchingQueryKey;

  /// Indicates it the watching happens asynchronously or not.
  /// This is the difference between [Composer.watch] or [AsyncComposer.watchFuture]
  final bool isAsync;
}

/// when the [CompositionManager.unsubscribe] method is called
final class CompositionUnsubscribeEvent extends CompositionEvent {
  ///
  CompositionUnsubscribeEvent({
    required super.compositionKey,
    required this.queryKey,
  });

  /// The [Query.key] that is unsubscribing.
  final String queryKey;
}

/// when the [Notifier] refresh method is called.
final class CompositionRefreshEvent extends CompositionEvent {
  ///
  CompositionRefreshEvent({
    required super.compositionKey,
    required this.queriesToInvalidate,
  });

  /// The [Query] that the composition was subscribed to that are now being invalidated.
  final Set<Query<dynamic>> queriesToInvalidate;
}
