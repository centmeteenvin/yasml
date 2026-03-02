import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/view_model/composition/composition_container.dart';
import 'package:yasml/src/view_model/mutation.dart';
import 'package:yasml/src/view_model/mutation_container.dart';
import 'package:yasml/src/world/world.dart';

/// The notifier exposes the following functions to the view:
/// - `refresh`: a function that can be called to refresh the composition.
///     It will invalidate the queries watched by the composition and refetch them,
///     which will cause the composition to re-execute and update the view with the new state.
/// - `runMutation`: a function that can be called to run a mutation.
///     It takes a [MutationDefinition] as an argument and returns a
///     Future that completes with the result of the mutation.
///     After this future completes, the composition will be refreshed to reflect the changes made by the mutation.
///     The world is guaranteed to be in a settled state when the future completes,
///     which means that all the queries that are affected by the mutation have been refetched and their state has been updated.
typedef Notifier<M extends Mutation> = ({Future<void> Function() refresh, MutationRunner<M> runMutation});

/// A base class for view widgets. It handles the common logic of subscribing to the [Composition] and running [Mutation]s.
/// It also defines the build method that will be called to build the widget based on the composition state and the notifier.
///
/// it reactively updates the widget when the composition state changes and provides
///  a [Notifier] to the build method that can be used to refresh the composition or run mutations.
@immutable
abstract base class ViewWidget<T, C extends Composition<T>, M extends Mutation<C>> extends StatefulWidget {
  /// @nodoc
  const ViewWidget({required this.world, super.key});

  /// The [World] where the composition and mutations live in.
  final World world;

  /// The [Composition] that this view widget will subscribe to. It should be a composition that emits a state of type [T].
  /// It is implemented as a getter to allow you to pass custom parameters to the composition if needed.
  ///
  /// For example, if this is a Detail ViewWidget, you should put the id as a field on the
  /// ViewWidget and pass it to the composition through this getter,
  /// so you can use it to watch queries with that id in the composition.
  C get composition;

  /// The constructor of the mutation that this view widget will use to run mutations.
  /// It should be a constructor that creates mutations of type [M].
  /// It is implemented as a getter to allow you to pass custom parameters to the mutation if needed.
  /// It is also returns a [MutationConstructor] instead of a [Mutation] because the mutation container needs
  /// to be created with a [Commander]
  MutationConstructor<M> get mutationConstructor;

  @nonVirtual
  @override
  State<ViewWidget<T, C, M>> createState() => ViewWidgetState<T, C, M>();

  /// The method that will be called to build the widget. It takes the current [composition] state and a [Notifier] as arguments.
  Widget build(BuildContext context, T composition, Notifier<M> notifier);
}

/// The state of the [ViewWidget]. It handles the subscription to the [Composition] and runs the mutations when needed.
class ViewWidgetState<T, C extends Composition<T>, M extends Mutation<C>> extends State<ViewWidget<T, C, M>> {
  /// the subscription to the composition. It is used to get the current state of the composition
  ///  and update the widget when it changes.
  late CompositionSubscription<T> compositionSubscription;

  @override
  void initState() {
    super.initState();
    compositionSubscription = widget.world.compositionManager.subscribe(
      widget.composition,
      this,
    );
  }

  @override
  void dispose() {
    widget.world.compositionManager.unsubscribe(compositionSubscription);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ViewWidget<T, C, M> oldWidget) {
    if (widget.composition != oldWidget.composition || widget.world != oldWidget.world) {
      oldWidget.world.compositionManager.unsubscribe(compositionSubscription);

      compositionSubscription = widget.world.compositionManager.subscribe(
        widget.composition,
        this,
      );
    }

    super.didUpdateWidget(oldWidget);
  }

  /// A function that can be called to update the state of the composition
  /// . It is used to notify the widget when the [Composition] state changes.
  void updateState(T newState) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.build(
    context,
    compositionSubscription.compositionContainer.state,
    (
      refresh: () => widget.world.compositionManager.refresh(widget.composition),
      runMutation: _runMutation,
    ),
  );

  Future<R> _runMutation<R>(MutationDefinition<M, R> definition) async {
    final mutationContainer = MutationContainer(
      world: widget.world,
      mutationConstructor: widget.mutationConstructor,
    );
    final result = await mutationContainer.runMutation(definition);
    return result;
  }
}
