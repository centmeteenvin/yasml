part of '../events.dart';

sealed class CompositionEvent extends Event {
  final String compositionKey;
  CompositionEvent({required this.compositionKey}) : super(componentName: 'Composition - $compositionKey');
}

final class CompositionContainerCreatedEvent extends CompositionEvent {
  final String reason;
  CompositionContainerCreatedEvent({required super.compositionKey, required this.reason});
}

final class CompositionContainerDisposedEvent extends CompositionEvent {
  final String reason;
  CompositionContainerDisposedEvent({required super.compositionKey, required this.reason});
}

final class CompositionContainerNewListenerEvent extends CompositionEvent {
  final Type compositionListenableType;
  CompositionContainerNewListenerEvent({required super.compositionKey, required this.compositionListenableType});
}

final class CompositionContainerListenerRemovedEvent extends CompositionEvent {
  final Type compositionListenableType;
  CompositionContainerListenerRemovedEvent({required super.compositionKey, required this.compositionListenableType});
}

final class CompositionExecutedEvent extends CompositionEvent {
  CompositionExecutedEvent({required super.compositionKey});
}

final class CompositionSetStateEvent extends CompositionEvent {
  final dynamic newState;
  CompositionSetStateEvent({required super.compositionKey, required this.newState});
}

final class CompositionSettledEvent extends CompositionEvent {
  CompositionSettledEvent({required super.compositionKey});
}

final class CompositionWatchEvent extends CompositionEvent {
  final String watchingQueryKey;
  final bool isAsync;
  CompositionWatchEvent({required super.compositionKey, required this.watchingQueryKey, required this.isAsync});
}

final class CompositionUnsubscribeEvent extends CompositionEvent {
  final String queryKey;
  CompositionUnsubscribeEvent({required super.compositionKey, required this.queryKey});
}

final class CompositionRefreshEvent extends CompositionEvent {
  final Set<Query> queriesToInvalidate;
  CompositionRefreshEvent({required super.compositionKey, required this.queriesToInvalidate});
}
