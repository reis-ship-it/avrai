import 'package:avrai/apps/admin_app/ui/admin_app.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/firebase_options.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> runAdminApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  const logger =
      AppLogger(defaultTag: 'ADMIN_MAIN', minimumLevel: LogLevel.debug);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    logger.warn('Firebase initialization failed for admin app: $error');
  }

  await di.init();
  runApp(const AdminApp());
}
