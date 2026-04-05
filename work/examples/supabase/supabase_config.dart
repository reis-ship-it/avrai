class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT.supabase.co';
  static const String anonKey = 'REDACTED';
  static const String environment = 'example';
  static const bool debug = false;
  static bool get isValid =>
      url.isNotEmpty && anonKey.isNotEmpty && anonKey != 'REDACTED';
}
