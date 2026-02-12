import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/core/services/infrastructure/supabase_service.dart';

/// Tax Document Storage Service
///
/// Handles secure storage of tax documents (PDFs).
///
/// **Storage Options:**
/// - Firebase Storage (production)
/// - Local file system (development/fallback)
///
/// **Philosophy Alignment:**
/// - Opens doors to secure document storage
/// - Protects sensitive tax documents
/// - Enables document retrieval for users
class TaxDocumentStorageService {
  static const AppLogger _logger =
      AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  static const String _bucketId = 'tax-documents';
  static const String _supabaseScheme = 'sb';
  static const bool _retainPaperworkDocs = true;

  final firebase_storage.FirebaseStorage? _firebaseStorage;
  final bool _useFirebase;
  final SupabaseService _supabaseService;
  final bool _useSupabase;

  TaxDocumentStorageService({
    firebase_storage.FirebaseStorage? firebaseStorage,
    bool useFirebase = true,
    SupabaseService? supabaseService,
    bool useSupabase = true,
  })  : _firebaseStorage = firebaseStorage,
        _useFirebase = useFirebase,
        _supabaseService = supabaseService ?? SupabaseService(),
        _useSupabase = useSupabase;

  /// Upload tax document PDF
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `documentId`: Document ID
  /// - `taxYear`: Tax year
  /// - `pdfBytes`: PDF document bytes
  ///
  /// **Returns:**
  /// URL to access the stored document
  Future<String> uploadTaxDocument({
    required String userId,
    required String documentId,
    required int taxYear,
    required Uint8List pdfBytes,
  }) async {
    try {
      _logger.info(
        'Uploading tax document: doc=$documentId, user=$userId, year=$taxYear',
        tag: 'TaxDocumentStorageService',
      );

      if (_useSupabase) {
        final res = await _uploadToSupabase(
          userId: userId,
          documentId: documentId,
          taxYear: taxYear,
          pdfBytes: pdfBytes,
        );
        if (res != null) return res;
      }

      if (_useFirebase && _firebaseStorage != null) {
        return await _uploadToFirebase(
          userId: userId,
          documentId: documentId,
          taxYear: taxYear,
          pdfBytes: pdfBytes,
        );
      } else {
        return await _uploadToLocal(
          userId: userId,
          documentId: documentId,
          taxYear: taxYear,
          pdfBytes: pdfBytes,
        );
      }
    } catch (e) {
      _logger.error('Failed to upload tax document',
          error: e, tag: 'TaxDocumentStorageService');
      rethrow;
    }
  }

  /// Download tax document PDF
  ///
  /// **Parameters:**
  /// - `documentUrl`: URL to the stored document
  ///
  /// **Returns:**
  /// PDF document bytes
  Future<Uint8List> downloadTaxDocument(String documentUrl) async {
    try {
      _logger.info('Downloading tax document: $documentUrl',
          tag: 'TaxDocumentStorageService');

      if (_isSupabaseObjectRef(documentUrl)) {
        return await _downloadFromSupabase(documentUrl);
      }

      if (documentUrl.startsWith('gs://') || documentUrl.contains('firebase')) {
        return await _downloadFromFirebase(documentUrl);
      } else {
        return await _downloadFromLocal(documentUrl);
      }
    } catch (e) {
      _logger.error('Failed to download tax document',
          error: e, tag: 'TaxDocumentStorageService');
      rethrow;
    }
  }

  /// Delete tax document
  Future<void> deleteTaxDocument(String documentUrl) async {
    try {
      if (_retainPaperworkDocs) {
        _logger.warn(
          'Paperwork retention enabled; skipping delete for tax document: $documentUrl',
          tag: 'TaxDocumentStorageService',
        );
        return;
      }

      _logger.info('Deleting tax document: $documentUrl',
          tag: 'TaxDocumentStorageService');

      if (_isSupabaseObjectRef(documentUrl)) {
        await _deleteFromSupabase(documentUrl);
        return;
      }

      if (documentUrl.startsWith('gs://') || documentUrl.contains('firebase')) {
        if (_firebaseStorage == null) {
          _logger.warn(
            'FirebaseStorage not configured; cannot delete Firebase documentUrl=$documentUrl',
            tag: 'TaxDocumentStorageService',
          );
          return;
        }
        await _deleteFromFirebase(documentUrl);
      } else {
        await _deleteFromLocal(documentUrl);
      }
    } catch (e) {
      _logger.error('Failed to delete tax document',
          error: e, tag: 'TaxDocumentStorageService');
      rethrow;
    }
  }

  // Firebase Storage methods

  Future<String> _uploadToFirebase({
    required String userId,
    required String documentId,
    required int taxYear,
    required Uint8List pdfBytes,
  }) async {
    final storageRef = _firebaseStorage!.ref();
    final documentRef =
        storageRef.child('tax_documents/$userId/$taxYear/$documentId.pdf');

    await documentRef.putData(
      pdfBytes,
      firebase_storage.SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'userId': userId,
          'documentId': documentId,
          'taxYear': taxYear.toString(),
        },
      ),
    );

    final downloadUrl = await documentRef.getDownloadURL();
    return downloadUrl;
  }

  Future<Uint8List> _downloadFromFirebase(String documentUrl) async {
    final ref = _firebaseStorage!.refFromURL(documentUrl);
    final bytes = await ref.getData();

    if (bytes == null) {
      throw Exception('Failed to download document from Firebase');
    }

    return bytes;
  }

  Future<void> _deleteFromFirebase(String documentUrl) async {
    final ref = _firebaseStorage!.refFromURL(documentUrl);
    await ref.delete();
  }

  // Supabase Storage methods

  bool _isSupabaseObjectRef(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == _supabaseScheme && uri.host == _bucketId;
    } catch (_) {
      return false;
    }
  }

  /// Convert a supabase object ref (`sb://tax-documents/<path>`) to bucket path.
  String _supabaseObjectPath(String documentUrl) {
    final uri = Uri.parse(documentUrl);
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    return path;
  }

  Future<String?> _uploadToSupabase({
    required String userId,
    required String documentId,
    required int taxYear,
    required Uint8List pdfBytes,
  }) async {
    try {
      if (!_supabaseService.isAvailable) return null;
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return null;
      if (currentUser.id != userId) {
        // Client writes are user-scoped; server-side (service role) should handle admin uploads.
        return null;
      }

      final objectPath = '$userId/$taxYear/$documentId.pdf';
      await _supabaseService.client.storage.from(_bucketId).uploadBinary(
            objectPath,
            pdfBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              // Paperwork retention: never overwrite existing objects.
              upsert: false,
            ),
          );

      // Store a stable reference, not a signed URL (signed URLs expire).
      return '$_supabaseScheme://$_bucketId/$objectPath';
    } catch (e, st) {
      developer.log(
        'Supabase tax document upload failed',
        name: 'TaxDocumentStorageService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<Uint8List> _downloadFromSupabase(String documentUrl) async {
    final objectPath = _supabaseObjectPath(documentUrl);
    final bytes = await _supabaseService.client.storage
        .from(_bucketId)
        .download(objectPath);
    return bytes;
  }

  Future<void> _deleteFromSupabase(String documentUrl) async {
    final objectPath = _supabaseObjectPath(documentUrl);
    await _supabaseService.client.storage.from(_bucketId).remove([objectPath]);
  }

  /// Resolve a document URL into something launchable (HTTPS), if needed.
  ///
  /// - Firebase URLs: returned as-is.
  /// - Supabase object refs: returns a signed URL (short-lived) suitable for `url_launcher`.
  Future<Uri> resolveLaunchUrl(
    String documentUrl, {
    Duration expiresIn = const Duration(hours: 2),
  }) async {
    if (_isSupabaseObjectRef(documentUrl)) {
      if (!_supabaseService.isAvailable ||
          _supabaseService.currentUser == null) {
        throw Exception('Supabase not available (cannot create signed URL)');
      }
      final objectPath = _supabaseObjectPath(documentUrl);
      final signedUrl = await _supabaseService.client.storage
          .from(_bucketId)
          .createSignedUrl(objectPath, expiresIn.inSeconds);
      return Uri.parse(signedUrl);
    }
    return Uri.parse(documentUrl);
  }

  // Local file system methods (fallback)

  Future<String> _uploadToLocal({
    required String userId,
    required String documentId,
    required int taxYear,
    required Uint8List pdfBytes,
  }) async {
    // In production, would use path_provider to get documents directory
    // For now, return a placeholder URL
    _logger.warn(
      'Using local file storage (fallback). In production, use Firebase Storage.',
      tag: 'TaxDocumentStorageService',
    );

    return 'file://tax_documents/$userId/$taxYear/$documentId.pdf';
  }

  Future<Uint8List> _downloadFromLocal(String documentUrl) async {
    // In production, would read from local file system
    throw Exception(
        'Local file download not implemented. Use Firebase Storage in production.');
  }

  Future<void> _deleteFromLocal(String documentUrl) async {
    // In production, would delete from local file system
    _logger.warn('Local file deletion not implemented',
        tag: 'TaxDocumentStorageService');
  }
}
