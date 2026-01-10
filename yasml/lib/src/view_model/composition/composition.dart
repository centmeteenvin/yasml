import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/registry.dart';
import 'package:yasml/src/world/world.dart';

/// The composer is a simple dumb function that fetches
/// data from multiple queries
/// This interface is the way you need to interact with your
/// queries from a ComposerRuntime
abstract interface class Composer {
  T watch<T>(Query<T> query);
}

/// A composition is class that uses the composer
/// to compose multiple queries into a given ViewModel
/// Additionally it should also provider an initial value
abstract base class Composition<T> implements RegisitryKey<String> {
  void compose(Composer composer, ValueChanged<T> setState, VoidCallback setSettled);

  T initialValue(World world);

  @override
  String get key;

  @nonVirtual
  @override
  int get hashCode => key.hashCode;

  @nonVirtual
  @override
  bool operator ==(Object other) {
    return other is Composition && other.key == key;
  }
}
