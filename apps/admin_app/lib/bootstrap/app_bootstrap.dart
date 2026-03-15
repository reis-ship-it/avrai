import 'package:get_it/get_it.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize({
    required GetIt sl,
    required Future<void> Function() registerAppServices,
  }) async {
    await registerAppServices();
  }
}
