import 'package:flutter/widgets.dart';
import 'package:yasml/src/view_model/view_model_manager.dart';

abstract class ViewWidget<T> extends StatefulWidget {
  const ViewWidget({super.key});

  ViewModelManager<T> get viewModel;

  @override
  State<ViewWidget<T>> createState() => ViewWidgetState<T>();

  Widget build(BuildContext context, T viewModel);
}

class ViewWidgetState<T> extends State<ViewWidget<T>> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.subscribe(this);
  }

  @override
  void dispose() {
    widget.viewModel.unsubscribe(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ViewWidget<T> oldWidget) {
    if (widget.viewModel != oldWidget.viewModel) {
      oldWidget.viewModel.unsubscribe(this);
      widget.viewModel.subscribe(this);
    }

    super.didUpdateWidget(oldWidget);
  }

  void updateState(T newState) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.build(context, widget.viewModel.state);
}
