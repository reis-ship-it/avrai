import 'dart:typed_data';

import 'package:supabase/supabase.dart';

abstract class ReplaySupabaseStorageGateway {
  Future<void> uploadObject({
    required String bucket,
    required String objectPath,
    required Uint8List bytes,
    required String contentType,
  });

  Future<void> upsertRows({
    required String table,
    required List<Map<String, dynamic>> rows,
    String? onConflict,
  });
}

class ReplaySupabaseStorageGatewayImpl implements ReplaySupabaseStorageGateway {
  ReplaySupabaseStorageGatewayImpl({
    required SupabaseClient client,
    required String schema,
  })  : _client = client,
        _schema = schema;

  final SupabaseClient _client;
  final String _schema;

  @override
  Future<void> uploadObject({
    required String bucket,
    required String objectPath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
  }

  @override
  Future<void> upsertRows({
    required String table,
    required List<Map<String, dynamic>> rows,
    String? onConflict,
  }) async {
    if (rows.isEmpty) {
      return;
    }

    await _client
        .schema(_schema)
        .from(table)
        .upsert(rows, onConflict: onConflict);
  }
}
