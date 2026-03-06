import 'dart:developer' as developer;

import 'package:avrai_core/models/community.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/intake/air_gap_normalizer.dart';
import 'package:avrai_runtime_os/services/intake/entity_fit_router.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';

/// Shared runtime intake entry point for external spots, events, and communities.
class SourceIntakeOrchestrator {
  static const String _logName = 'SourceIntakeOrchestrator';

  final AirGapNormalizer _normalizer;
  final EntityFitRouter _fitRouter;
  final UniversalIntakeRepository _repository;
  final ExpertiseEventService _eventService;
  final CommunityService _communityService;
  final SpotsLocalDataSource _spotsLocalDataSource;
  final AtomicClockService _atomicClockService;
  final EntitySignatureService? _entitySignatureService;
  final RemoteSourceHealthService? _remoteSourceHealthService;

  SourceIntakeOrchestrator({
    required AirGapNormalizer normalizer,
    required EntityFitRouter fitRouter,
    required UniversalIntakeRepository repository,
    required ExpertiseEventService eventService,
    required CommunityService communityService,
    required SpotsLocalDataSource spotsLocalDataSource,
    required AtomicClockService atomicClockService,
    EntitySignatureService? entitySignatureService,
    RemoteSourceHealthService? remoteSourceHealthService,
  })  : _normalizer = normalizer,
        _fitRouter = fitRouter,
        _repository = repository,
        _eventService = eventService,
        _communityService = communityService,
        _spotsLocalDataSource = spotsLocalDataSource,
        _atomicClockService = atomicClockService,
        _entitySignatureService = entitySignatureService,
        _remoteSourceHealthService = remoteSourceHealthService;

  Future<IntakeMaterializationResult> ingest({
    required ExternalSourceDescriptor source,
    required Map<String, dynamic> rawPayload,
  }) async {
    final now = await _now();
    final candidate =
        _normalizer.normalize(payload: rawPayload, source: source);
    final decision = _fitRouter.route(candidate);
    final updatedSource = source.copyWith(
      updatedAt: now,
      lastSyncedAt: now,
      syncState: decision.shouldPublishImmediately
          ? ExternalSyncState.active
          : ExternalSyncState.needsReview,
    );
    await _repository.upsertSource(updatedSource);
    await _publishRemoteHealthBestEffort(source: updatedSource);

    final job = ExternalSyncJob(
      id: _id('sync'),
      sourceId: source.id,
      startedAt: now,
      updatedAt: now,
      state: decision.shouldPublishImmediately
          ? ExternalSyncState.active
          : ExternalSyncState.needsReview,
      importedCount: decision.shouldPublishImmediately ? 1 : 0,
      reviewCount: decision.shouldPublishImmediately ? 0 : 1,
    );
    await _repository.upsertJob(job);

    if (!decision.shouldPublishImmediately) {
      final reviewItem = OrganizerReviewItem(
        id: _id('review'),
        sourceId: source.id,
        ownerUserId: source.ownerUserId,
        targetType: decision.primaryType == IntakeEntityType.linkedBundle
            ? decision.linkedTypes.firstOrNull ?? IntakeEntityType.review
            : decision.primaryType,
        title: candidate.title.isEmpty
            ? 'Imported source needs review'
            : candidate.title,
        summary: decision.reasons.join(' '),
        missingFields: _missingFields(candidate, decision),
        createdAt: now,
        payload: rawPayload,
      );
      await _repository.upsertReviewItem(reviewItem);
      await _publishRemoteHealthBestEffort(source: updatedSource);
      return IntakeMaterializationResult(
        decision: decision,
        reviewItem: reviewItem,
      );
    }

    String? spotId;
    String? eventId;
    String? communityId;

    final metadata = ExternalSyncMetadata(
      sourceProvider: source.sourceProvider,
      sourceUrl: source.sourceUrl,
      externalId: candidate.externalId,
      syncState: ExternalSyncState.active,
      connectionMode: source.connectionMode,
      lastSyncedAt: now,
      importedAt: now,
      ownerUserId: source.ownerUserId,
      isClaimable: source.isClaimable,
      cityCode: candidate.cityCode ?? source.cityCode,
      localityCode: candidate.localityCode ?? source.localityCode,
      sourceLabel: source.sourceLabel,
    );

    final publishTypes = decision.primaryType == IntakeEntityType.linkedBundle
        ? <IntakeEntityType>[
            if (decision.linkedTypes.contains(IntakeEntityType.community))
              IntakeEntityType.community,
            if (decision.linkedTypes.contains(IntakeEntityType.event))
              IntakeEntityType.event,
          ]
        : <IntakeEntityType>[decision.primaryType];

    for (final type in publishTypes) {
      switch (type) {
        case IntakeEntityType.spot:
          final spot = Spot(
            id: candidate.externalId ?? _id('spot'),
            name: candidate.title,
            description: candidate.description,
            latitude: candidate.latitude ?? 0.0,
            longitude: candidate.longitude ?? 0.0,
            category: candidate.category,
            rating: 4.2,
            createdBy: source.ownerUserId,
            createdAt: now,
            updatedAt: now,
            address: candidate.locationLabel,
            website: candidate.websiteUrl,
            tags: candidate.tags,
            metadata: <String, dynamic>{
              'is_external': true,
              'source_provider': source.sourceProvider,
              'source_url': source.sourceUrl,
            },
            cityCode: candidate.cityCode ?? source.cityCode,
            localityCode: candidate.localityCode ?? source.localityCode,
            externalSyncMetadata: metadata,
          );
          spotId = await _spotsLocalDataSource.createSpot(spot);
          await _repository.upsertSpotMetadata(
              spotId: spotId, metadata: metadata);
          final signatureMeta =
              await _buildSpotSignatureBestEffort(spot.copyWith(id: spotId));
          await _repository.upsertSource(
            updatedSource.copyWith(
              metadata: <String, dynamic>{
                ...updatedSource.metadata,
                ...signatureMeta,
              },
            ),
          );
          await _publishRemoteHealthBestEffort(
            source: updatedSource.copyWith(
              metadata: <String, dynamic>{
                ...updatedSource.metadata,
                ...signatureMeta,
              },
            ),
          );
          break;
        case IntakeEntityType.event:
          final event = await _eventService.importExternalEvent(
            ownerUserId: source.ownerUserId,
            title: candidate.title,
            description: candidate.description,
            category: candidate.category,
            location: candidate.locationLabel,
            latitude: candidate.latitude,
            longitude: candidate.longitude,
            cityCode: candidate.cityCode ?? source.cityCode,
            localityCode: candidate.localityCode ?? source.localityCode,
            startTime: candidate.startTime,
            endTime: candidate.endTime,
            metadata: metadata,
          );
          eventId = event.id;
          final signatureMeta = await _buildEventSignatureBestEffort(event);
          await _repository.upsertSource(
            updatedSource.copyWith(
              metadata: <String, dynamic>{
                ...updatedSource.metadata,
                ...signatureMeta,
              },
            ),
          );
          await _publishRemoteHealthBestEffort(
            source: updatedSource.copyWith(
              metadata: <String, dynamic>{
                ...updatedSource.metadata,
                ...signatureMeta,
              },
            ),
          );
          break;
        case IntakeEntityType.community:
          final community = await _communityService.importExternalCommunity(
            ownerUserId: source.ownerUserId,
            name: candidate.title,
            description: candidate.description,
            category: candidate.category,
            originalLocality:
                candidate.locationLabel ?? candidate.localityCode ?? 'Imported',
            cityCode: candidate.cityCode ?? source.cityCode,
            localityCode: candidate.localityCode ?? source.localityCode,
            externalSyncMetadata: metadata,
          );
          communityId = community.id;
          final signatureMeta =
              await _buildCommunitySignatureBestEffort(community);
          await _repository.upsertSource(
            updatedSource.copyWith(
              metadata: <String, dynamic>{
                ...updatedSource.metadata,
                ...signatureMeta,
              },
            ),
          );
          await _publishRemoteHealthBestEffort(
            source: updatedSource.copyWith(
              metadata: <String, dynamic>{
                ...updatedSource.metadata,
                ...signatureMeta,
              },
            ),
          );
          break;
        case IntakeEntityType.linkedBundle:
        case IntakeEntityType.review:
          break;
      }
    }

    return IntakeMaterializationResult(
      decision: decision,
      spotId: spotId,
      eventId: eventId,
      communityId: communityId,
    );
  }

  Future<OrganizerReviewItem?> registerSourceForExistingEntity({
    required ExternalSourceDescriptor source,
    required IntakeEntityType entityType,
    required String entityId,
    required Map<String, dynamic> rawPayload,
  }) async {
    final now = await _now();
    final candidate =
        _normalizer.normalize(payload: rawPayload, source: source);
    final decision = _fitRouter.route(candidate);
    final metadata = ExternalSyncMetadata(
      sourceProvider: source.sourceProvider,
      sourceUrl: source.sourceUrl,
      externalId: candidate.externalId,
      syncState: decision.shouldPublishImmediately
          ? ExternalSyncState.active
          : ExternalSyncState.needsReview,
      connectionMode: source.connectionMode,
      lastSyncedAt: now,
      importedAt: now,
      ownerUserId: source.ownerUserId,
      isClaimable: source.isClaimable,
      cityCode: candidate.cityCode ?? source.cityCode,
      localityCode: candidate.localityCode ?? source.localityCode,
      sourceLabel: source.sourceLabel,
    );

    await _repository.upsertSource(source.copyWith(
      updatedAt: now,
      lastSyncedAt: now,
      syncState: metadata.syncState,
      metadata: <String, dynamic>{
        ...source.metadata,
        'linkedEntityType': entityType.name,
        'linkedEntityId': entityId,
      },
    ));
    await _publishRemoteHealthBestEffort(
      source: source.copyWith(
        updatedAt: now,
        lastSyncedAt: now,
        syncState: metadata.syncState,
        metadata: <String, dynamic>{
          ...source.metadata,
          'linkedEntityType': entityType.name,
          'linkedEntityId': entityId,
        },
      ),
    );
    await _repository.upsertJob(
      ExternalSyncJob(
        id: _id('sync'),
        sourceId: source.id,
        startedAt: now,
        updatedAt: now,
        state: metadata.syncState,
        importedCount: decision.shouldPublishImmediately ? 1 : 0,
        reviewCount: decision.shouldPublishImmediately ? 0 : 1,
      ),
    );

    if (entityType == IntakeEntityType.event) {
      await _eventService.attachExternalSyncMetadata(
        eventId: entityId,
        metadata: metadata,
      );
      final event = await _eventService.getEventById(entityId);
      if (event != null) {
        final signatureMeta = await _buildEventSignatureBestEffort(event);
        await _repository.upsertSource(source.copyWith(
          updatedAt: now,
          lastSyncedAt: now,
          syncState: metadata.syncState,
          metadata: <String, dynamic>{
            ...source.metadata,
            'linkedEntityType': entityType.name,
            'linkedEntityId': entityId,
            ...signatureMeta,
          },
        ));
        await _publishRemoteHealthBestEffort(
          source: source.copyWith(
            updatedAt: now,
            lastSyncedAt: now,
            syncState: metadata.syncState,
            metadata: <String, dynamic>{
              ...source.metadata,
              'linkedEntityType': entityType.name,
              'linkedEntityId': entityId,
              ...signatureMeta,
            },
          ),
        );
      }
    } else if (entityType == IntakeEntityType.community) {
      await _communityService.attachExternalSyncMetadata(
        communityId: entityId,
        metadata: metadata,
      );
      final community = await _communityService.getCommunityById(entityId);
      if (community != null) {
        final signatureMeta =
            await _buildCommunitySignatureBestEffort(community);
        await _repository.upsertSource(source.copyWith(
          updatedAt: now,
          lastSyncedAt: now,
          syncState: metadata.syncState,
          metadata: <String, dynamic>{
            ...source.metadata,
            'linkedEntityType': entityType.name,
            'linkedEntityId': entityId,
            ...signatureMeta,
          },
        ));
        await _publishRemoteHealthBestEffort(
          source: source.copyWith(
            updatedAt: now,
            lastSyncedAt: now,
            syncState: metadata.syncState,
            metadata: <String, dynamic>{
              ...source.metadata,
              'linkedEntityType': entityType.name,
              'linkedEntityId': entityId,
              ...signatureMeta,
            },
          ),
        );
      }
    }

    if (decision.shouldPublishImmediately) {
      return null;
    }

    final reviewItem = OrganizerReviewItem(
      id: _id('review'),
      sourceId: source.id,
      ownerUserId: source.ownerUserId,
      targetType: entityType,
      title: candidate.title.isEmpty ? 'Source needs review' : candidate.title,
      summary: decision.reasons.join(' '),
      missingFields: _missingFields(candidate, decision),
      createdAt: now,
      payload: <String, dynamic>{
        ...rawPayload,
        'linkedEntityType': entityType.name,
        'linkedEntityId': entityId,
      },
    );
    await _repository.upsertReviewItem(reviewItem);
    return reviewItem;
  }

  Future<DateTime> _now() async {
    try {
      final stamp = await _atomicClockService.getAtomicTimestamp();
      return stamp.serverTime;
    } catch (e, st) {
      developer.log(
        'Atomic time unavailable, falling back to device clock: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return DateTime.now();
    }
  }

  List<String> _missingFields(
    IntakeCandidate candidate,
    IntakeRouteDecision decision,
  ) {
    return <String>[
      if (!candidate.hasWho) 'who',
      if (!candidate.hasWhat) 'what',
      if (!candidate.hasWhere) 'where',
      if (!candidate.hasWhen &&
          decision.primaryType != IntakeEntityType.community)
        'when',
    ];
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch.toString()}';

  Future<Map<String, dynamic>> _buildSpotSignatureBestEffort(Spot spot) async {
    if (_entitySignatureService == null) {
      return const <String, dynamic>{};
    }

    final signature =
        await _entitySignatureService.buildSpotSignature(spot: spot);
    return _signatureMetadata(signature);
  }

  Future<Map<String, dynamic>> _buildEventSignatureBestEffort(
    ExpertiseEvent event,
  ) async {
    if (_entitySignatureService == null) {
      return const <String, dynamic>{};
    }

    final signature =
        await _entitySignatureService.buildEventSignature(event: event);
    return _signatureMetadata(signature);
  }

  Future<Map<String, dynamic>> _buildCommunitySignatureBestEffort(
    Community community,
  ) async {
    if (_entitySignatureService == null) {
      return const <String, dynamic>{};
    }

    final signature = await _entitySignatureService.buildCommunitySignature(
        community: community);
    return _signatureMetadata(signature);
  }

  Map<String, dynamic> _signatureMetadata(EntitySignature signature) {
    return <String, dynamic>{
      'entityType': signature.entityKind.name,
      'signatureConfidence': signature.confidence,
      'signatureFreshness': signature.freshness,
      'signatureUpdatedAt': signature.updatedAt.toIso8601String(),
      'signatureSummary': signature.summary,
    };
  }

  Future<void> _publishRemoteHealthBestEffort({
    required ExternalSourceDescriptor source,
  }) async {
    final remoteService = _remoteSourceHealthService;
    if (remoteService == null) {
      return;
    }

    try {
      final metadata = source.metadata;
      final entityType = metadata['entityType']?.toString() ??
          metadata['linkedEntityType']?.toString() ??
          source.entityHint?.name ??
          'unknown';
      final categoryLabel = metadata['category']?.toString() ??
          metadata['signatureCategory']?.toString() ??
          entityType;
      final summary = metadata['signatureSummary']?.toString() ??
          '${source.sourceLabel ?? source.sourceProvider} sync is ${source.syncState.name}.';
      await remoteService.upsertSourceHealth(
        sourceId: source.id,
        ownerUserId: source.ownerUserId,
        provider: source.sourceProvider,
        entityType: entityType,
        categoryLabel: categoryLabel,
        sourceLabel: source.sourceLabel,
        cityCode: source.cityCode,
        localityCode: source.localityCode,
        confidence:
            (metadata['signatureConfidence'] as num?)?.toDouble() ?? 0.0,
        freshness: (metadata['signatureFreshness'] as num?)?.toDouble() ?? 0.0,
        fallbackRate: (metadata['fallbackRate'] as num?)?.toDouble() ?? 0.0,
        reviewNeeded: source.syncState == ExternalSyncState.needsReview ||
            metadata['reviewNeeded'] == true,
        syncState: source.syncState.name,
        summary: summary,
        lastSyncAt: source.lastSyncedAt,
        lastSignatureRebuildAt: metadata['signatureUpdatedAt'] is String
            ? DateTime.tryParse(metadata['signatureUpdatedAt'] as String)
            : null,
      );
    } catch (e, st) {
      developer.log(
        'Remote source health publish failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}

extension on List<IntakeEntityType> {
  IntakeEntityType? get firstOrNull => isEmpty ? null : first;
}
