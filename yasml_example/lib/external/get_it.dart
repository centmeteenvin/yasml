import 'package:get_it/get_it.dart';
import 'package:yasml/yasml.dart';

final getIt = GetIt.instance();

final class GetItPlugin implements WorldPlugin {
  late final GetIt getIt;

  @override
  void onInit(World world) {
    getIt = GetIt.asNewInstance();
  }

  @override
  Future<void> onDispose() {
    return getIt.reset();
  }
}

extension GetItPluginExtension on World {
  GetIt get get {
    final plugin = pluginByType<GetItPlugin>();
    if (plugin == null) {
      throw StateError('GetIt Plugin not found on World');
    }

    return plugin.getIt;
  }
}
