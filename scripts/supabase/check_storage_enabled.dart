import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Checks whether Supabase Storage is enabled and reachable for this project.
///
/// This is a CLI utility (not production code). It expects credentials via env:
/// - `SUPABASE_URL`
/// - `SUPABASE_ANON_KEY`
///
/// Run:
/// `dart run scripts/supabase/check_storage_enabled.dart`
Future<void> main(List<String> args) async {
  final url = Platform.environment['SUPABASE_URL'];
  final anonKey = Platform.environment['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    stderr.writeln(
      'Missing env vars. Set SUPABASE_URL and SUPABASE_ANON_KEY then retry.',
    );
    exitCode = 2;
    return;
  }

  final bucketListUri = Uri.parse('$url/storage/v1/bucket/list');

  try {
    final response = await http.get(
      bucketListUri,
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final buckets = decoded is List ? decoded : const [];
      stdout.writeln('OK: Storage reachable. Buckets: ${buckets.length}');
      exitCode = 0;
      return;
    }

    stderr.writeln(
      'Storage check failed: HTTP ${response.statusCode}\n${response.body}',
    );
    exitCode = 1;
  } catch (e) {
    stderr.writeln('Storage check error: $e');
    exitCode = 1;
  }
}

