import 'dart:async';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

class RemoteSourceHealthService {
  static const String _table = 'external_source_health_v1';

  final SupabaseService _supabaseService;
  final TemporalKernel? _temporalKernel;
  final TemporalFreshnessPolicy _freshnessPolicy;

  RemoteSourceHealthService({
    required SupabaseService supabaseService,
    TemporalKernel? temporalKernel,
    TemporalFreshnessPolicy freshnessPolicy =
        const TemporalFreshnessPolicy(maxAge: Duration(days: 30)),
  })  : _supabaseService = supabaseService,
        _temporalKernel = temporalKernel,
        _freshnessPolicy = freshnessPolicy;

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
    final updatedAt = await _resolveUpdatedAt();

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
      'updated_at': updatedAt.toIso8601String(),
    });
  }

  Future<List<SignatureHealthRecord>> fetchRows() async {
    final client = _supabaseService.tryGetClient();
    if (client == null) {
      return const <SignatureHealthRecord>[];
    }

    final response = await client.from(_table).select('*');
    final rows = List<Map<String, dynamic>>.from(response as List);
    return Future.wait(rows.map(_fromRow));
  }

  Stream<List<SignatureHealthRecord>> watchRows() {
    final client = _supabaseService.tryGetClient();
    if (client == null) {
      return const Stream<List<SignatureHealthRecord>>.empty();
    }

    return client.from(_table).stream(primaryKey: ['id']).asyncMap(
      (rows) => Future.wait(
        rows.map((row) => _fromRow(Map<String, dynamic>.from(row))),
      ),
    );
  }

  Future<SignatureHealthRecord> fromRowForTest(Map<String, dynamic> row) {
    return _fromRow(row);
  }

  Future<SignatureHealthRecord> _fromRow(Map<String, dynamic> row) async {
    final categoryName = row['health_category']?.toString() ?? 'weakData';
    final originalCategory = SignatureHealthCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => SignatureHealthCategory.weakData,
    );
    final lastSyncAt = _asDateTime(row['last_sync_at']);
    final lastSignatureRebuildAt =
        _asDateTime(row['last_signature_rebuild_at']);
    final updatedAt = _asDateTime(row['updated_at']);
    final freshness = await _resolveFreshness(
      storedFreshness: _asDouble(row['freshness']),
      lastSyncAt: lastSyncAt,
      lastSignatureRebuildAt: lastSignatureRebuildAt,
      updatedAt: updatedAt,
    );
    final category = await _resolveCategoryWithKernel(
      originalCategory: originalCategory,
      confidence: _asDouble(row['confidence']),
      freshness: freshness,
      fallbackRate: _asDouble(row['fallback_rate']),
      reviewNeeded: row['review_needed'] as bool? ?? false,
      entityType: row['entity_type']?.toString() ?? 'unknown',
      lastSyncAt: lastSyncAt,
      lastSignatureRebuildAt: lastSignatureRebuildAt,
      updatedAt: updatedAt,
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
      freshness: freshness,
      fallbackRate: _asDouble(row['fallback_rate']),
      reviewNeeded: row['review_needed'] as bool? ?? false,
      lastSyncAt: lastSyncAt,
      lastSignatureRebuildAt: lastSignatureRebuildAt,
      updatedAt: updatedAt,
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

  Future<SignatureHealthCategory> _resolveCategoryWithKernel({
    required SignatureHealthCategory originalCategory,
    required double confidence,
    required double freshness,
    required double fallbackRate,
    required bool reviewNeeded,
    required String entityType,
    required DateTime? lastSyncAt,
    required DateTime? lastSignatureRebuildAt,
    required DateTime? updatedAt,
  }) async {
    final kernel = _temporalKernel;
    if (kernel == null) {
      return _resolveCategory(
        confidence: confidence,
        freshness: freshness,
        fallbackRate: fallbackRate,
        reviewNeeded: reviewNeeded,
        entityType: entityType,
      );
    }

    final reference = lastSyncAt ?? lastSignatureRebuildAt ?? updatedAt;
    if (reference == null) {
      return originalCategory;
    }

    final snapshot = _snapshotAt(reference);
    final kernelFreshness =
        await kernel.freshnessOf(snapshot, _freshnessPolicy);
    if (!kernelFreshness.isFresh) {
      return SignatureHealthCategory.stale;
    }

    return _resolveCategory(
      confidence: confidence,
      freshness: freshness,
      fallbackRate: fallbackRate,
      reviewNeeded: reviewNeeded,
      entityType: entityType,
    );
  }

  Future<double> _resolveFreshness({
    required double storedFreshness,
    required DateTime? lastSyncAt,
    required DateTime? lastSignatureRebuildAt,
    required DateTime? updatedAt,
  }) async {
    final kernel = _temporalKernel;
    if (kernel == null) {
      return storedFreshness;
    }
    final reference = lastSyncAt ?? lastSignatureRebuildAt ?? updatedAt;
    if (reference == null) {
      return storedFreshness;
    }

    final snapshot = _snapshotAt(reference);
    final freshness = await kernel.freshnessOf(snapshot, _freshnessPolicy);
    if (!freshness.isFresh) {
      return storedFreshness > 0.55 ? 0.0 : storedFreshness;
    }
    return storedFreshness;
  }

  Future<DateTime> _resolveUpdatedAt() async {
    final kernel = _temporalKernel;
    if (kernel == null) {
      return DateTime.now().toUtc();
    }
    final now = await kernel.nowCivil();
    return now.referenceTime;
  }

  TemporalSnapshot _snapshotAt(DateTime reference) {
    final instant = TemporalInstant(
      referenceTime: reference.toUtc(),
      civilTime: reference.toLocal(),
      timezoneId:
          reference.timeZoneName.isEmpty ? 'UTC' : reference.timeZoneName,
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.synchronizedServer,
        source: 'remote_source_health_row',
      ),
      uncertainty: const TemporalUncertainty.zero(),
    );
    return TemporalSnapshot(
      observedAt: instant,
      recordedAt: instant,
      effectiveAt: instant,
      semanticBand: SemanticTimeBand.unknown,
    );
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
