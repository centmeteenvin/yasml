/// Mock listener for query notifications
library;

import 'package:yasml/src/model/query/query_container.dart';

/// Mock listener to track query updates
class MockQueryListener implements QueryReachable {
  int notifyCount = 0;

  @override
  void notify() {
    notifyCount++;
  }
}
