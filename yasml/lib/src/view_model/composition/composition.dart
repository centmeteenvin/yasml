import 'package:flutter/foundation.dart';
import 'package:yasml/src/model/query/query.dart';
import 'package:yasml/src/types/registry.dart';
import 'package:yasml/src/world/world.dart';

/// The composer is a simple dumb function that fetches
/// data from multiple queries
/// This interface is the way you need to interact with your
/// queries from a ComposerRuntime
abstract interface class Composer {
  /// watches the given query and returns with its value.
  /// It will reactively update the value when the query is invalidated and refetched.
  T watch<T>(Query<T> query);
}

/// A composition is class that uses the composer
/// to compose multiple queries into a given ViewModel
/// Additionally it should also provider an initial value
abstract base class Composition<T> implements RegisitryKey<String> {
  /// @nodoc
  const Composition();

  /// The method that will be called to execute the composition.
  ///  It should call the composer to watch the queries and set the state of the composition using the setState callback.
  void execute(Composer composer, ValueChanged<T> setState, VoidCallback setSettled);

  /// The method that will be called to get the initial value of the composition.
  /// It should return the initial value of the composition.
  T initialValue(World world, Composer composer);

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
