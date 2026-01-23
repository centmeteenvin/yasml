part of '../events.dart';

sealed class ViewEvent extends Event {
  final String viewId;

  ViewEvent({required this.viewId}) : super(componentName: 'View-$viewId');
}

final class ViewCreatedEvent extends ViewEvent {
  ViewCreatedEvent({required super.viewId});
}

final class ViewBuildEvent extends ViewEvent {
  ViewBuildEvent({required super.viewId});
}

final class ViewDisposedEvent extends ViewEvent {
  ViewDisposedEvent({required super.viewId});
}
