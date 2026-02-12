import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Minimal storage health CLI.
/// Usage (env-driven):
/// SUPABASE_URL=... SUPABASE_ANON_KEY=... BUCKETS=user-avatars,spot-images,list-images dart run scripts/storage_health_check.dart
void main() async {
  final env = Platform.environment;
  final url = env['SUPABASE_URL'];
  final anon = env['SUPABASE_ANON_KEY'];
  final bucketsCsv = env['BUCKETS'] ?? 'user-avatars,spot-images,list-images';
  final requireCanary = (env['REQUIRE_CANARY'] ?? 'false').toLowerCase() == 'true';
  final canaryPath = env['CANARY_PATH'] ?? 'health/_canary.txt';

  if (url == null || anon == null) {
    stderr.writeln('SUPABASE_URL and SUPABASE_ANON_KEY environment variables are required');
    exit(2);
  }

  final buckets = bucketsCsv
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  var failed = false;

  for (final b in buckets) {
    final resp = await http.post(
      Uri.parse('$url/storage/v1/object/list/$b'),
      headers: {
        'apikey': anon,
        'Authorization': 'Bearer $anon',
        'Content-Type': 'application/json',
      },
      body: json.encode({'prefix': ''}),
    );
    if (resp.statusCode != 200) {
      stderr.writeln('Bucket "$b" check failed: ${resp.statusCode} ${resp.body}');
      failed = true;
    } else {
      stdout.writeln('Bucket "$b": OK');
    }

    if (requireCanary) {
      final canaryUrl = '$url/storage/v1/object/public/$b/$canaryPath';
      final head = await http.get(Uri.parse(canaryUrl), headers: {'apikey': anon});
      if (head.statusCode != 200) {
        stderr.writeln('Canary missing for "$b": ${head.statusCode}');
        failed = true;
      } else {
        stdout.writeln('Canary for "$b": OK');
      }
    }
  }

  if (failed) exit(1);
}


