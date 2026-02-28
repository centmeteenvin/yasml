import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/option.dart';
import 'package:yasml/src/world/query_manager.dart';

/// A registry is a simple class that allows you to register and unregister items with a key.
/// It is used to easyily find the [QueryManager] from the [Query].
abstract interface class RegisitryKey<K> {
  /// The key that is used to register the item in the registry. It should be unique for each item.
  K get key;
}

/// A registry that allows you to register and unregister items with a key. It is used to easily find the [QueryManager] from the [Query].
final class Registry<RK, K extends RegisitryKey<RK>, T> {
  final Map<RK, T> _map = {};

  /// Registers an item in the registry with the given key. If an item with the same key already exists, it will be overwritten.
  void register(K keyable, T item) {
    _map[keyable.key] = item;
  }

  /// Unregisters an item from the registry with the given key. If no item with the given key exists, nothing happens.
  void unregister(K keyable) {
    _map.remove(keyable.key);
  }

  /// Returns an iterable of all the items in the registry.
  Iterable<T> get items => _map.values;

  /// Returns the item associated with the given key. If no item with the given key exists, it returns an empty option.
  Option<T> get(K keyable) {
    final value = _map[keyable.key];
    if (value == null) {
      return OptionEmpty();
    }
    return OptionValue(value);
  }
}
