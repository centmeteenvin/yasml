import 'package:yasml/src/model/query.dart';

final class SynchronousQuery<T> extends Query<T> {
  SynchronousQuery({required this.fetch});

  final T Function() fetch;

  @override
  T get initialState => fetch();

  @override
  void execute() {
    // Do nothing since the initial state already executes the fetch
  }

  @override
  void reset() {
    // Do nothing since the value is recalculated after state is reset;
  }
}
