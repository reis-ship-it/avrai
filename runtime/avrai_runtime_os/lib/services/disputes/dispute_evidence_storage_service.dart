import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:uuid/uuid.dart';

import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Stores dispute evidence (screenshots/photos) in Supabase Storage with retention lock.
///
/// Storage:
/// - Bucket: `paperwork-documents` (private)
/// - Path: `<userId>/dispute_evidence/<disputeId>/<evidenceId>.<ext>`
///
/// References:
/// - Returns `sb://paperwork-documents/<path>` refs (stable, non-expiring)
/// - Use [resolveSignedUrl] to obtain a short-lived HTTPS URL for display/download.
///
/// Auditability:
/// - Appends a v0 ledger receipt for each uploaded evidence object.
class DisputeEvidenceStorageService {
  static const String _logName = 'DisputeEvidenceStorageService';
  static const String _bucketId = 'paperwork-documents';
  static const String _supabaseScheme = 'sb';

  final SupabaseService _supabaseService;
  final LedgerRecorderServiceV0 _ledger;
  final AppLogger _logger;
  final Uuid _uuid;

  DisputeEvidenceStorageService({
    required SupabaseService supabaseService,
    required LedgerRecorderServiceV0 ledger,
    AppLogger? logger,
    Uuid? uuid,
  })  : _supabaseService = supabaseService,
        _ledger = ledger,
        _logger = logger ??
            const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug),
        _uuid = uuid ?? const Uuid();

  /// Upload one evidence image and return an `sb://...` object reference.
  ///
  /// Notes:
  /// - Requires authenticated Supabase user (RLS enforces path ownership).
  /// - Uses `upsert: false` to enforce no-overwrite retention behavior.
  Future<String> uploadEvidenceImage({
    required String userId,
    required String disputeId,
    required String eventId,
    required Uint8List bytes,
    required String contentType,
    String? fileExtension,
  }) async {
    if (_supabaseService.currentUser == null) {
      throw StateError('Not authenticated (cannot upload dispute evidence)');
    }
    if (!_supabaseService.isAvailable) {
      throw StateError(
          'Supabase not available (cannot upload dispute evidence)');
    }
    if (_supabaseService.currentUser?.id != userId) {
      throw StateError('User mismatch (cannot upload dispute evidence)');
    }

    final ext = _normalizeExtension(fileExtension, contentType: contentType);
    final evidenceId = _uuid.v4();
    final objectPath = '$userId/dispute_evidence/$disputeId/$evidenceId.$ext';

    final shaHex = sha256.convert(bytes).toString();

    _logger.info(
      'Uploading dispute evidence: dispute=$disputeId, bytes=${bytes.length}, contentType=$contentType',
      tag: _logName,
    );

    await _supabaseService.client.storage.from(_bucketId).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    final ref = '$_supabaseScheme://$_bucketId/$objectPath';

    // Best-effort ledger receipt. Never blocks the upload.
    try {
      await _ledger.append(
        domain: LedgerDomainV0.moderation,
        eventType: 'dispute_evidence_uploaded',
        occurredAt: DateTime.now(),
        entityType: 'dispute',
        entityId: disputeId,
        correlationId: evidenceId,
        source: 'paperwork_documents',
        payload: <String, Object?>{
          'dispute_id': disputeId,
          'event_id': eventId,
          'bucket_id': _bucketId,
          'object_path': objectPath,
          'object_ref': ref,
          'content_type': contentType,
          'byte_length': bytes.length,
          'sha256': shaHex,
        },
      );
    } catch (e) {
      _logger.warn(
        'Ledger append skipped/failed for dispute_evidence_uploaded: ${e.toString()}',
        tag: _logName,
      );
    }

    return ref;
  }

  /// Convert an `sb://paperwork-documents/<path>` ref into a short-lived HTTPS URL.
  Future<Uri> resolveSignedUrl(
    String documentUrl, {
    int expiresInSeconds = 60 * 10,
  }) async {
    if (_isSupabaseObjectRef(documentUrl)) {
      if (_supabaseService.currentUser == null) {
        throw StateError('Not authenticated (cannot create signed URL)');
      }
      if (!_supabaseService.isAvailable) {
        throw StateError('Supabase not available (cannot create signed URL)');
      }
      final parsed = _parseSupabaseRef(documentUrl);
      final signed = await _supabaseService.client.storage
          .from(parsed.bucket)
          .createSignedUrl(parsed.objectPath, expiresInSeconds);
      return Uri.parse(signed);
    }
    return Uri.parse(documentUrl);
  }

  bool _isSupabaseObjectRef(String url) =>
      url.startsWith('$_supabaseScheme://');

  ({String bucket, String objectPath}) _parseSupabaseRef(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != _supabaseScheme) {
      throw ArgumentError.value(url, 'url', 'Not a supabase object ref');
    }
    final bucket = uri.host;
    final objectPath =
        uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    if (bucket.isEmpty || objectPath.isEmpty) {
      throw ArgumentError.value(url, 'url', 'Invalid supabase object ref');
    }
    return (bucket: bucket, objectPath: objectPath);
  }

  String _normalizeExtension(String? fileExtension,
      {required String contentType}) {
    final ext = (fileExtension ?? '').trim().toLowerCase();
    if (ext.isNotEmpty) {
      return ext.startsWith('.') ? ext.substring(1) : ext;
    }
    // Minimal mapping for common evidence images.
    return switch (contentType.toLowerCase()) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'jpg',
    };
  }
}
