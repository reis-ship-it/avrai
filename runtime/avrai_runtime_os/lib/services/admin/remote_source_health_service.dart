import 'dart:async';

import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

class RemoteSourceHealthService {
  static const String _table = 'external_source_health_v1';

  final SupabaseService _supabaseService;

  RemoteSourceHealthService({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  bool get isAvailable => _supabaseService.isAvailable;

  Future<void> upsertSourceHealth({
    required String sourceId,
    required String ownerUserId,
    required String provider,
    required String entityType,
    required String categoryLabel,
    String? sourceLabel,
    String? cityCode,
    String? localityCode,
    required double confidence,
    required double freshness,
    required double fallbackRate,
    required bool reviewNeeded,
    required String syncState,
    required String summary,
    DateTime? lastSyncAt,
    DateTime? lastSignatureRebuildAt,
  }) async {
    final client = _supabaseService.tryGetClient();
    if (client == null) {
      return;
    }

    final healthCategory = _resolveCategory(
      confidence: confidence,
      freshness: freshness,
      fallbackRate: fallbackRate,
      reviewNeeded: reviewNeeded,
      entityType: entityType,
    );
    final id = '$sourceId:$entityType';

    await client.from(_table).upsert(<String, dynamic>{
      'id': id,
      'owner_user_id': ownerUserId,
      'source_id': sourceId,
      'provider': provider,
      'source_label': sourceLabel,
      'entity_type': entityType,
      'category_label': categoryLabel,
      'city_code': cityCode,
      'locality_code': localityCode,
      'confidence': confidence,
      'freshness': freshness,
      'fallback_rate': fallbackRate,
      'review_needed': reviewNeeded,
      'sync_state': syncState,
      'health_category': healthCategory.name,
      'summary': summary,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'last_signature_rebuild_at': lastSignatureRebuildAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<SignatureHealthRecord>> fetchRows() async {
    final client = _supabaseService.tryGetClient();
    if (client == null) {
      return const <SignatureHealthRecord>[];
    }

    final response = await client.from(_table).select('*');
    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(_fromRow).toList();
  }

  Stream<List<SignatureHealthRecord>> watchRows() {
    final client = _supabaseService.tryGetClient();
    if (client == null) {
      return const Stream<List<SignatureHealthRecord>>.empty();
    }

    return client.from(_table).stream(primaryKey: ['id']).map(
      (rows) =>
          rows.map((row) => _fromRow(Map<String, dynamic>.from(row))).toList(),
    );
  }

  SignatureHealthRecord _fromRow(Map<String, dynamic> row) {
    final categoryName = row['health_category']?.toString() ?? 'weakData';
    final category = SignatureHealthCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => SignatureHealthCategory.weakData,
    );
    return SignatureHealthRecord(
      sourceId: row['source_id']?.toString() ?? '',
      provider: row['provider']?.toString() ?? 'unknown',
      entityType: row['entity_type']?.toString() ?? 'unknown',
      categoryLabel: row['category_label']?.toString() ?? 'unknown',
      sourceLabel: row['source_label']?.toString(),
      cityCode: row['city_code']?.toString(),
      localityCode: row['locality_code']?.toString(),
      confidence: _asDouble(row['confidence']),
      freshness: _asDouble(row['freshness']),
      fallbackRate: _asDouble(row['fallback_rate']),
      reviewNeeded: row['review_needed'] as bool? ?? false,
      lastSyncAt: _asDateTime(row['last_sync_at']),
      lastSignatureRebuildAt: _asDateTime(row['last_signature_rebuild_at']),
      syncState: row['sync_state']?.toString() ?? 'pending',
      healthCategory: category,
      summary: row['summary']?.toString() ?? '',
    );
  }

  SignatureHealthCategory _resolveCategory({
    required double confidence,
    required double freshness,
    required double fallbackRate,
    required bool reviewNeeded,
    required String entityType,
  }) {
    if (reviewNeeded) {
      return SignatureHealthCategory.reviewNeeded;
    }
    if (fallbackRate > 0.0) {
      return SignatureHealthCategory.fallback;
    }
    if (freshness < 0.55) {
      return SignatureHealthCategory.stale;
    }
    if (confidence < 0.75) {
      return SignatureHealthCategory.weakData;
    }
    if (entityType == 'linkedBundle' || entityType == 'bundle') {
      return SignatureHealthCategory.bundle;
    }
    return SignatureHealthCategory.strong;
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  DateTime? _asDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
