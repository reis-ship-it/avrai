import 'package:avrai_admin_app/ui/admin_app.dart';
import 'package:avrai_admin_app/injection_container.dart' as di;
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_admin_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> runAdminApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  const logger =
      AppLogger(defaultTag: 'ADMIN_MAIN', minimumLevel: LogLevel.debug);
  _ensureDesktopOnlyTarget();

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

void _ensureDesktopOnlyTarget() {
  if (kIsWeb) {
    throw UnsupportedError(
      'Admin app is desktop-only. Web target is disabled by policy.',
    );
  }

  const allowed = <TargetPlatform>{
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  };

  if (!allowed.contains(defaultTargetPlatform)) {
    throw UnsupportedError(
      'Admin app is desktop-only (macOS/windows/linux). '
      'Current target is not allowed: $defaultTargetPlatform',
    );
  }
}
