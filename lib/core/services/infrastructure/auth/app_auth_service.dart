import 'package:supabase_flutter/supabase_flutter.dart';

/// App-level authentication contract (separate from social OAuth linking).
abstract class AppAuthService {
  /// Current authenticated app user ID, or null when signed out.
  String? get currentUserId;

  /// Whether an app user session is active.
  bool get isAuthenticated;

  /// Stream of app auth state user IDs.
  Stream<String?> authStateUserIdStream();
}

/// Supabase-backed implementation for app login/session state.
class SupabaseAppAuthService implements AppAuthService {
  final SupabaseClient _client;

  SupabaseAppAuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  bool get isAuthenticated => _client.auth.currentUser != null;

  @override
  Stream<String?> authStateUserIdStream() {
    return _client.auth.onAuthStateChange
        .map((event) => event.session?.user.id);
  }
}
