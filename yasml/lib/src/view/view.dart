import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:yasml/src/view_model/composition/composition.dart';
import 'package:yasml/src/view_model/composition/composition_container.dart';
import 'package:yasml/src/view_model/mutation.dart';
import 'package:yasml/src/view_model/mutation_container.dart';
import 'package:yasml/src/world/world.dart';

typedef Notifier<M extends Mutation> = ({Future<void> Function() refresh, MutationRunner<M> runMutation});

@immutable
abstract base class ViewWidget<T, C extends Composition<T>, M extends Mutation<C>> extends StatefulWidget {
  const ViewWidget({super.key, required this.world});

  final World world;

  C get composition;
  MutationConstructor<M> get mutationConstructor;

  @nonVirtual
  @override
  State<ViewWidget<T, C, M>> createState() => ViewWidgetState<T, C, M>();

  Widget build(BuildContext context, T composition, Notifier<M> notifier);
}

class ViewWidgetState<T, C extends Composition<T>, M extends Mutation<C>> extends State<ViewWidget<T, C, M>> {
  late CompositionSubscription<T> compositionSubscription;

  @override
  void initState() {
    super.initState();
    compositionSubscription = widget.world.compositionManager.subscribe(widget.composition, this);
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

      compositionSubscription = widget.world.compositionManager.subscribe(widget.composition, this);
    }

    super.didUpdateWidget(oldWidget);
  }

  void updateState(T newState) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.build(context, compositionSubscription.compositionContainer.state, (
    refresh: () => widget.world.compositionManager.refresh(widget.composition),
    runMutation: _runMutation,
  ));

  Future<R> _runMutation<R>(MutationDefinition<M, R> definition) async {
    final mutationContainer = MutationContainer(world: widget.world, mutationConstructor: widget.mutationConstructor);
    final result = await mutationContainer.runMutation(definition);
    return result;
  }
}
