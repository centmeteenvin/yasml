import 'package:yasml/src/types/option.dart';

abstract interface class RegisitryKey<K> {
  K get key;
}

final class Registry<RK, K extends RegisitryKey<RK>, T> {
  final Map<RK, T> _map = {};

  void register(K keyable, T item) {
    _map[keyable.key] = item;
  }

  void unregister(K keyable) {
    _map.remove(keyable.key);
  }

  Iterable<T> get items => _map.values;

  Option<T> get(K keyable) {
    final value = _map[keyable.key];
    if (value == null) {
      return OptionEmpty();
    }
    return OptionValue(value);
  }
}
