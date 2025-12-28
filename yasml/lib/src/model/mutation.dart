import 'package:yasml/src/model/query.dart';

abstract interface class Manager {
  void invalidate(Query query);
}

final class Mutation implements Manager {
  Mutation(this.mutation);

  final void Function(Manager) mutation;

  @override
  void invalidate(Query<dynamic> query) {
    query.invalidate();
  }
}
