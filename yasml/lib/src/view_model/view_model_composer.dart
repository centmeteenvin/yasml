import 'package:yasml/src/model/query.dart';

abstract interface class ViewModelComposer {
  T watch<T>(Query<T> query);
}
