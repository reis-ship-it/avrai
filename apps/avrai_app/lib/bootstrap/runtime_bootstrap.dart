import 'package:get_it/get_it.dart';

class RuntimeBootstrap {
  const RuntimeBootstrap._();

  static Future<void> initialize({
    required GetIt sl,
    required Future<void> Function() registerRuntimeServices,
  }) async {
    await registerRuntimeServices();
  }
}
