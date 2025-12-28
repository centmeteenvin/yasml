import 'package:flutter/widgets.dart';

final class YasmlScope {
  YasmlScope();

  static YasmlScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<YasmlScopeProvider>();
    if (scope == null) {
      throw StateError("Tried to get the Yasml from context where it did not exist. Did you forget to add YasmlScope?");
    }
    return scope.yasml;
  }
}

@immutable
class YasmlScopeProvider extends InheritedWidget {
  const YasmlScopeProvider({super.key, required this.yasml, required super.child});

  final YasmlScope yasml;

  @override
  bool updateShouldNotify(YasmlScopeProvider oldWidget) => yasml != oldWidget.yasml;
}
