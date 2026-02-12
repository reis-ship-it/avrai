import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global test bootstrap for `flutter test`.
///
/// This ensures StorageService + SharedPreferencesCompat are initialized for tests
/// that rely on GetIt registrations.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Prevent google_fonts from trying to fetch fonts over the network in tests.
  GoogleFonts.config.allowRuntimeFetching = false;

  await testMain();
}


