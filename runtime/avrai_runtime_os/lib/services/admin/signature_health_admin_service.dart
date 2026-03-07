import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';

class SignatureHealthAdminService {
  static const String _logName = 'SignatureHealthAdminService';

  final UniversalIntakeRepository _intakeRepository;
  final RemoteSourceHealthService? _remoteSourceHealthService;

  SignatureHealthAdminService({
    required UniversalIntakeRepository intakeRepository,
    RemoteSourceHealthService? remoteSourceHealthService,
  })  : _intakeRepository = intakeRepository,
        _remoteSourceHealthService = remoteSourceHealthService;

  Future<SignatureHealthSnapshot> getSnapshot() async {
    final sources = await _intakeRepository.getAllSources();
    final reviews = await _intakeRepository.getAllReviewItems();
    final remoteRecords = _remoteSourceHealthService == null
        ? const <SignatureHealthRecord>[]
        : await _remoteSourceHealthService.fetchRows();
    final mergedBySourceId = <String, SignatureHealthRecord>{
      for (final record in remoteRecords)
        '${record.sourceId}:${record.entityType}': record,
      for (final source in sources)
        '${source.id}:${source.metadata['entityType'] ?? source.metadata['linkedEntityType'] ?? source.entityHint?.name ?? 'unknown'}':
            _toRecord(source),
    };
    final records = mergedBySourceId.values.toList()
      ..sort((a, b) {
        final categoryCompare = _categoryPriority(
          a.healthCategory,
        ).compareTo(_categoryPriority(b.healthCategory));
        if (categoryCompare != 0) {
          return categoryCompare;
        }
        return b.confidence.compareTo(a.confidence);
      });
    final sourceRecords =
        records.where((record) => !record.isFeedbackTelemetry).toList();
    final feedbackRecords =
        records.where((record) => record.isFeedbackTelemetry).toList();

    return SignatureHealthSnapshot(
      generatedAt: DateTime.now(),
      overview: SignatureHealthOverview(
        strongCount: sourceRecords
            .where(
              (record) =>
                  record.healthCategory == SignatureHealthCategory.strong,
            )
            .length,
        weakDataCount: sourceRecords
            .where(
              (record) =>
                  record.healthCategory == SignatureHealthCategory.weakData,
            )
            .length,
        staleCount: sourceRecords
            .where(
              (record) =>
                  record.healthCategory == SignatureHealthCategory.stale,
            )
            .length,
        fallbackCount: sourceRecords
            .where(
              (record) =>
                  record.healthCategory == SignatureHealthCategory.fallback,
            )
            .length,
        reviewNeededCount: sourceRecords
            .where(
              (record) =>
                  record.healthCategory == SignatureHealthCategory.reviewNeeded,
            )
            .length,
        bundleCount: sourceRecords
            .where(
              (record) =>
                  record.healthCategory == SignatureHealthCategory.bundle,
            )
            .length,
        softIgnoreCount: feedbackRecords
            .where((record) => record.categoryLabel == 'soft_ignore')
            .length,
        hardNotInterestedCount: feedbackRecords
            .where((record) => record.categoryLabel == 'hard_not_interested')
            .length,
      ),
      records: records,
      reviewQueueCount: reviews.length,
    );
  }

  Stream<SignatureHealthSnapshot> watchSnapshot() {
    late final StreamController<SignatureHealthSnapshot> controller;
    StreamSubscription<List<ExternalSourceDescriptor>>? sourceSubscription;
    StreamSubscription<List<OrganizerReviewItem>>? reviewSubscription;
    StreamSubscription<List<SignatureHealthRecord>>? remoteSubscription;

    Future<void> emitSnapshot() async {
      try {
        controller.add(await getSnapshot());
      } catch (e, st) {
        developer.log(
          'Failed to refresh signature health snapshot',
          name: _logName,
          error: e,
          stackTrace: st,
        );
        controller.addError(e, st);
      }
    }

    controller = StreamController<SignatureHealthSnapshot>.broadcast(
      onListen: () async {
        await emitSnapshot();
        sourceSubscription = _intakeRepository.watchSources().listen(
              (_) => emitSnapshot(),
            );
        reviewSubscription = _intakeRepository.watchReviewItems().listen(
              (_) => emitSnapshot(),
            );
        remoteSubscription = _remoteSourceHealthService?.watchRows().listen(
              (_) => emitSnapshot(),
            );
      },
      onCancel: () async {
        await sourceSubscription?.cancel();
        await reviewSubscription?.cancel();
        await remoteSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  SignatureHealthRecord _toRecord(ExternalSourceDescriptor source) {
    final metadata = source.metadata;
    final confidence = _asDouble(metadata['signatureConfidence']);
    final freshness = _asDouble(metadata['signatureFreshness']);
    final fallbackRate = _asDouble(metadata['fallbackRate']);
    final reviewNeeded = source.syncState == ExternalSyncState.needsReview ||
        metadata['reviewNeeded'] == true ||
        metadata['signatureReviewNeeded'] == true;
    final entityType = metadata['entityType']?.toString() ??
        source.entityHint?.name ??
        'unknown';
    final categoryLabel = metadata['category']?.toString() ??
        metadata['signatureCategory']?.toString() ??
        entityType;
    final lastSignatureRebuildAt = _asDateTime(
      metadata['signatureUpdatedAt'] ?? metadata['lastSignatureRebuildAt'],
    );
    final fallbackState = metadata['signatureMode'] == 'fallback' ||
        metadata['usedSignaturePrimary'] == false ||
        fallbackRate > 0.0;
    final isBundle = entityType == IntakeEntityType.linkedBundle.name ||
        metadata['bundleEntityIds'] != null;

    final healthCategory = _resolveCategory(
      confidence: confidence,
      freshness: freshness,
      fallbackState: fallbackState,
      reviewNeeded: reviewNeeded,
      isBundle: isBundle,
    );

    return SignatureHealthRecord(
      sourceId: source.id,
      provider: source.sourceProvider,
      entityType: entityType,
      categoryLabel: categoryLabel,
      sourceLabel: source.sourceLabel,
      cityCode: source.cityCode,
      localityCode: source.localityCode,
      confidence: confidence,
      freshness: freshness,
      fallbackRate: fallbackRate,
      reviewNeeded: reviewNeeded,
      lastSyncAt: source.lastSyncedAt,
      lastSignatureRebuildAt: lastSignatureRebuildAt,
      updatedAt: source.updatedAt,
      syncState: source.syncState.name,
      healthCategory: healthCategory,
      summary: _buildSummary(
        source: source,
        healthCategory: healthCategory,
        confidence: confidence,
        freshness: freshness,
        fallbackState: fallbackState,
      ),
    );
  }

  SignatureHealthCategory _resolveCategory({
    required double confidence,
    required double freshness,
    required bool fallbackState,
    required bool reviewNeeded,
    required bool isBundle,
  }) {
    if (reviewNeeded) {
      return SignatureHealthCategory.reviewNeeded;
    }
    if (fallbackState) {
      return SignatureHealthCategory.fallback;
    }
    if (freshness < 0.55) {
      return SignatureHealthCategory.stale;
    }
    if (confidence < 0.75) {
      return SignatureHealthCategory.weakData;
    }
    if (isBundle) {
      return SignatureHealthCategory.bundle;
    }
    return SignatureHealthCategory.strong;
  }

  String _buildSummary({
    required ExternalSourceDescriptor source,
    required SignatureHealthCategory healthCategory,
    required double confidence,
    required double freshness,
    required bool fallbackState,
  }) {
    final label = source.sourceLabel ?? source.sourceProvider;
    switch (healthCategory) {
      case SignatureHealthCategory.reviewNeeded:
        return '$label needs operator review before trust can rise.';
      case SignatureHealthCategory.fallback:
        return '$label is leaning on fallback ranking instead of signature-primary.';
      case SignatureHealthCategory.stale:
        return '$label has gone stale and should rebuild its live pheromones.';
      case SignatureHealthCategory.weakData:
        return '$label has weak signature confidence (${(confidence * 100).round()}%).';
      case SignatureHealthCategory.bundle:
        return '$label is a linked bundle with blended confidence ${(confidence * 100).round()}% and freshness ${(freshness * 100).round()}%.';
      case SignatureHealthCategory.strong:
        return '$label is signature-healthy with confidence ${(confidence * 100).round()}% and freshness ${(freshness * 100).round()}%.';
    }
  }

  int _categoryPriority(SignatureHealthCategory category) {
    switch (category) {
      case SignatureHealthCategory.reviewNeeded:
        return 0;
      case SignatureHealthCategory.fallback:
        return 1;
      case SignatureHealthCategory.stale:
        return 2;
      case SignatureHealthCategory.weakData:
        return 3;
      case SignatureHealthCategory.bundle:
        return 4;
      case SignatureHealthCategory.strong:
        return 5;
    }
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble().clamp(0.0, 1.0);
    }
    if (value is String) {
      return double.tryParse(value)?.clamp(0.0, 1.0).toDouble() ?? 0.0;
    }
    return 0.0;
  }

  DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
