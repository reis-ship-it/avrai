import 'supabase/check_storage_enabled.dart' as supabase_script;

/// Convenience wrapper so both entrypoints work:
/// - `dart run scripts/check_storage_enabled.dart`
/// - `dart run scripts/supabase/check_storage_enabled.dart`
Future<void> main(List<String> args) => supabase_script.main(args);
