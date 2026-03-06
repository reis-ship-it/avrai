import 'package:avrai_core/models/payment/tax_document.dart';
import 'package:get_storage/get_storage.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/data/repositories/repository_patterns.dart';

/// Tax Document Repository
///
/// Handles persistence of tax documents using Sembast database.
/// Local-only repository - no remote operations.
class TaxDocumentRepository extends SimplifiedRepositoryBase {
  static const AppLogger _logger =
      AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  static const String _defaultStoreName = 'tax_documents';
  final String _storeName;

  TaxDocumentRepository({String? storeName})
      : _storeName = storeName ?? _defaultStoreName,
        super(connectivity: null); // Local-only, no connectivity needed

  GetStorage get _box => GetStorage(_storeName);

  /// Save tax document
  Future<void> saveTaxDocument(TaxDocument document) async {
    try {
      await _box.write('tax_doc_${document.id}', document.toJson());

      // Also maintain per-user index for filtering
      final userKey = 'tax_docs_user_${document.userId}';
      final List<dynamic> userDocs = _box.read<List<dynamic>>(userKey) ?? [];
      // Remove existing entry with same id (update case)
      userDocs.removeWhere((e) => (e as Map)['id'] == document.id);
      userDocs.add(document.toJson());
      await _box.write(userKey, userDocs);

      _logger.info('Tax document saved: ${document.id}',
          tag: 'TaxDocumentRepository');
    } catch (e) {
      _logger.error('Failed to save tax document',
          error: e, tag: 'TaxDocumentRepository');
      rethrow;
    }
  }

  /// Get tax document by ID
  Future<TaxDocument?> getTaxDocument(String documentId) async {
    return executeLocalOnly<TaxDocument?>(
      localOperation: () async {
        final data = _box.read<Map<String, dynamic>>('tax_doc_$documentId');
        if (data == null) return null;
        return TaxDocument.fromJson(data);
      },
    );
  }

  /// Get tax documents for user and year
  Future<List<TaxDocument>> getTaxDocuments(String userId, int year) async {
    return executeLocalOnly<List<TaxDocument>>(
      localOperation: () async {
        final userKey = 'tax_docs_user_$userId';
        final List<dynamic> userDocs = _box.read<List<dynamic>>(userKey) ?? [];

        return userDocs
            .map((e) =>
                TaxDocument.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((doc) => doc.taxYear == year)
            .toList();
      },
    );
  }

  /// Get all tax documents for a user
  Future<List<TaxDocument>> getAllTaxDocuments(String userId) async {
    return executeLocalOnly<List<TaxDocument>>(
      localOperation: () async {
        final userKey = 'tax_docs_user_$userId';
        final List<dynamic> userDocs = _box.read<List<dynamic>>(userKey) ?? [];

        return userDocs
            .map((e) =>
                TaxDocument.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );
  }

  /// Get all tax documents for a year
  Future<List<TaxDocument>> getTaxDocumentsForYear(int year) async {
    return executeLocalOnly<List<TaxDocument>>(
      localOperation: () async {
        // Need to scan all user doc lists - collect from all known user keys
        final allKeys = _box.getKeys<Iterable<String>>();
        final results = <TaxDocument>[];

        for (final key in allKeys) {
          if (key.startsWith('tax_docs_user_')) {
            final List<dynamic> docs = _box.read<List<dynamic>>(key) ?? [];
            for (final doc in docs) {
              final taxDoc =
                  TaxDocument.fromJson(Map<String, dynamic>.from(doc as Map));
              if (taxDoc.taxYear == year) {
                results.add(taxDoc);
              }
            }
          }
        }

        return results;
      },
    );
  }

  /// Get users with earnings >= threshold for a year
  Future<List<String>> getUsersWithEarningsAboveThreshold(
      int year, double threshold) async {
    return executeLocalOnly<List<String>>(
      localOperation: () async {
        final allKeys = _box.getKeys<Iterable<String>>();
        final userIds = <String>{};

        for (final key in allKeys) {
          if (key.startsWith('tax_docs_user_')) {
            final List<dynamic> docs = _box.read<List<dynamic>>(key) ?? [];
            for (final doc in docs) {
              final taxDoc =
                  TaxDocument.fromJson(Map<String, dynamic>.from(doc as Map));
              if (taxDoc.taxYear == year && taxDoc.totalEarnings >= threshold) {
                userIds.add(taxDoc.userId);
              }
            }
          }
        }

        return userIds.toList();
      },
    );
  }

  /// Delete tax document
  Future<void> deleteTaxDocument(String documentId) async {
    return executeLocalOnly(
      localOperation: () async {
        // Get the doc first to know the userId for index cleanup
        final data = _box.read<Map<String, dynamic>>('tax_doc_$documentId');
        if (data != null) {
          final userId = data['userId'] as String?;
          if (userId != null) {
            final userKey = 'tax_docs_user_$userId';
            final List<dynamic> userDocs =
                _box.read<List<dynamic>>(userKey) ?? [];
            userDocs.removeWhere((e) => (e as Map)['id'] == documentId);
            await _box.write(userKey, userDocs);
          }
        }
        await _box.remove('tax_doc_$documentId');
        _logger.info('Tax document deleted: $documentId',
            tag: 'TaxDocumentRepository');
      },
    );
  }
}
