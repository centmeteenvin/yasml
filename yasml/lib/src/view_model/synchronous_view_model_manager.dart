import 'package:yasml/src/view_model/view_model_composer.dart';
import 'package:yasml/src/view_model/view_model_manager.dart';

final class SynchronousViewModelManager<ViewModel> extends ViewModelManager<ViewModel> {
  final ViewModel Function(ViewModelComposer composer) compose;

  SynchronousViewModelManager(this.compose);

  @override
  ViewModel get initialValue => compose(this);

  @override
  void execute() {
    final newState = compose(this);
    setState(newState);
  }
}
