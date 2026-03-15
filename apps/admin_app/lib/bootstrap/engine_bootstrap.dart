import 'package:get_it/get_it.dart';

class EngineBootstrap {
  const EngineBootstrap._();

  static Future<void> initialize({
    required GetIt sl,
    required Future<void> Function() registerEngineServices,
  }) async {
    await registerEngineServices();
  }
}
