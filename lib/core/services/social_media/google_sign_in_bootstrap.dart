import 'dart:async';
import 'dart:developer' as developer;

import 'package:google_sign_in/google_sign_in.dart';

/// Centralized, idempotent initializer for `google_sign_in` v7+.
///
/// `GoogleSignIn.instance.initialize()` must be called exactly once per process.
/// This helper ensures we do that safely even if multiple services call it.
class GoogleSignInBootstrap {
  static const String _logName = 'GoogleSignInBootstrap';

  static Completer<void>? _initCompleter;

  static Future<void> ensureInitialized({
    required String? clientId,
    String? serverClientId,
  }) async {
    final existing = _initCompleter;
    if (existing != null) return existing.future;

    final completer = Completer<void>();
    _initCompleter = completer;

    try {
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      completer.complete();
    } catch (e, st) {
      developer.log(
        'GoogleSignIn initialize failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      _initCompleter = null;
      completer.completeError(e, st);
      rethrow;
    }
  }
}

