part of '../events.dart';

/// Events related to the lifecycle of a [ViewWidget]
sealed class ViewEvent extends Event {
  /// @nodoc
  ViewEvent({required this.viewId}) : super(componentName: 'View-$viewId');

  /// The [ViewWidget] of the view that is the source of the event
  final String viewId;
}

/// Specific event for the creation of a view. It is emitted when a new [ViewWidget] is created.
final class ViewCreatedEvent extends ViewEvent {
  /// @nodoc
  ViewCreatedEvent({required super.viewId});
}

/// Specific event for the build of a view. It is emitted when a [ViewWidget] is built.
final class ViewBuildEvent extends ViewEvent {
  /// @nodoc
  ViewBuildEvent({required super.viewId});
}

/// Specific event for the disposal of a view. It is emitted when a [ViewWidget] is disposed.
final class ViewDisposedEvent extends ViewEvent {
  /// @nodoc
  ViewDisposedEvent({required super.viewId});
}
