import 'dart:developer' as developer;

import 'package:avrai_core/models/community.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_dimensions.dart';
import 'package:avrai_core/models/signatures/signature_match_result.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/services/signatures/builders/community_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/event_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/signature_builder_support.dart';
import 'package:avrai_runtime_os/services/signatures/builders/spot_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/user_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/bundles/community_event_bundle_builder.dart';
import 'package:avrai_runtime_os/services/signatures/bundles/performer_venue_event_bundle_builder.dart';
import 'package:avrai_runtime_os/services/signatures/signature_match_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_repository.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_runtime_policy.dart';
import 'package:reality_engine/reality_engine.dart';

enum NegativePreferenceIntent {
  softIgnore,
  hardNotInterested,
}

class EntitySignatureService {
  static const String _logName = 'EntitySignatureService';
  static const double _existingDnaWeight = 0.8;
  static const double _latestDnaWeight = 0.2;
  static const double _existingPheromoneWeight = 0.35;
  static const double _latestPheromoneWeight = 0.65;
  static const String _behaviorLearningStoragePrefix =
      'user_signature_learning_v1:';

  final SignatureRepository _repository;
  final StorageService _storageService;
  final SignatureMatchService _matchService;
  final UserSignatureBuilder _userSignatureBuilder;
  final SpotSignatureBuilder _spotSignatureBuilder;
  final CommunitySignatureBuilder _communitySignatureBuilder;
  final EventSignatureBuilder _eventSignatureBuilder;
  final PerformerVenueEventBundleBuilder _performerVenueEventBundleBuilder;
  final CommunityEventBundleBuilder _communityEventBundleBuilder;
  final UserVibeAnalyzer _userVibeAnalyzer;
  final PersonalityLearning _personalityLearning;
  final RemoteSourceHealthService? _remoteSourceHealthService;
  final VibeKernel _vibeKernel;

  bool get _isCanonicalAuthorityActive =>
      CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive;

  EntitySignatureService({
    required SignatureRepository repository,
    required StorageService storageService,
    required SignatureMatchService matchService,
    required UserSignatureBuilder userSignatureBuilder,
    required SpotSignatureBuilder spotSignatureBuilder,
    required CommunitySignatureBuilder communitySignatureBuilder,
    required EventSignatureBuilder eventSignatureBuilder,
    required PerformerVenueEventBundleBuilder performerVenueEventBundleBuilder,
    required CommunityEventBundleBuilder communityEventBundleBuilder,
    required UserVibeAnalyzer userVibeAnalyzer,
    required PersonalityLearning personalityLearning,
    RemoteSourceHealthService? remoteSourceHealthService,
    VibeKernel? vibeKernel,
  })  : _repository = repository,
        _storageService = storageService,
        _matchService = matchService,
        _userSignatureBuilder = userSignatureBuilder,
        _spotSignatureBuilder = spotSignatureBuilder,
        _communitySignatureBuilder = communitySignatureBuilder,
        _eventSignatureBuilder = eventSignatureBuilder,
        _performerVenueEventBundleBuilder = performerVenueEventBundleBuilder,
        _communityEventBundleBuilder = communityEventBundleBuilder,
        _userVibeAnalyzer = userVibeAnalyzer,
        _personalityLearning = personalityLearning,
        _remoteSourceHealthService = remoteSourceHealthService,
        _vibeKernel = vibeKernel ?? VibeKernel();

  Future<EntitySignature> buildUserSignature({
    required UnifiedUser user,
    PersonalityProfile? personality,
    UserVibe? userVibe,
  }) async {
    final resolvedPersonality = personality ??
        await _personalityLearning.initializePersonality(user.id);
    final resolvedUserVibe = userVibe ??
        await _userVibeAnalyzer.compileUserVibe(user.id, resolvedPersonality);
    final freshlyBuiltSignature = _userSignatureBuilder.build(
      user: user,
      personality: resolvedPersonality,
      userVibe: resolvedUserVibe,
    );
    if (_isCanonicalAuthorityActive) {
      return _canonicalizeSignature(
        fallback: freshlyBuiltSignature,
        personalAgentId: resolvedPersonality.agentId,
      );
    }
    final behaviorState = _loadBehaviorLearningState(user.id);
    final learnedSignature = behaviorState == null
        ? freshlyBuiltSignature
        : _applyBehaviorLearning(
            signature: freshlyBuiltSignature,
            behaviorState: behaviorState,
          );
    final existingSignature = _repository.get(
      entityKind: SignatureEntityKind.user,
      entityId: user.id,
    );
    final signature = existingSignature == null
        ? learnedSignature
        : _blendUserSignature(
            existing: existingSignature,
            latest: learnedSignature,
          );
    await _repository.save(signature);
    return _canonicalizeSignature(
      fallback: signature,
      personalAgentId: resolvedPersonality.agentId,
    );
  }

  Future<EntitySignature> initializeUserSignatureFromOnboarding({
    required String userId,
    required OnboardingData onboardingData,
    required PersonalityProfile personality,
    String? displayName,
    String? email,
    UserVibe? userVibe,
  }) async {
    final seededUser = _buildOnboardingSeedUser(
      userId: userId,
      onboardingData: onboardingData,
      displayName: displayName,
      email: email,
    );
    final signature = await buildUserSignature(
      user: seededUser,
      personality: personality,
      userVibe: userVibe,
    );
    final enrichedSignature = signature.copyWith(
      summary: _buildOnboardingSummary(
        personality: personality,
        onboardingData: onboardingData,
      ),
      sourceTrace: _mergeSourceTrace(
        signature.sourceTrace,
        <SignatureSourceTrace>[
          const SignatureSourceTrace(
            kind: SignatureSourceKind.derived,
            label: 'onboarding self-definition',
            weight: 0.6,
          ),
          if ((onboardingData.homebase ?? '').trim().isNotEmpty)
            const SignatureSourceTrace(
              kind: SignatureSourceKind.locality,
              label: 'onboarding homebase',
              weight: 0.35,
            ),
        ],
      ),
    );
    if (!_isCanonicalAuthorityActive) {
      await _repository.save(enrichedSignature);
    }
    return _canonicalizeSignature(
      fallback: enrichedSignature,
      personalAgentId: personality.agentId,
    );
  }

  Future<EntitySignature> buildSpotSignature({
    required Spot spot,
  }) async {
    final signature = _spotSignatureBuilder.build(spot: spot);
    await _persistSignatureCompatibilityIfAllowed(signature);
    _syncSignatureToVibeKernel(signature);
    return _canonicalizeSignature(fallback: signature);
  }

  Future<EntitySignature> buildCommunitySignature({
    required Community community,
  }) async {
    final signature = _communitySignatureBuilder.build(community: community);
    await _persistSignatureCompatibilityIfAllowed(signature);
    _syncSignatureToVibeKernel(signature);
    return _canonicalizeSignature(fallback: signature);
  }

  Future<EntitySignature> buildEventSignature({
    required ExpertiseEvent event,
    Community? linkedCommunity,
  }) async {
    EntitySignature? bundleSignature;
    try {
      if (event.spots.isNotEmpty) {
        final hostPersonality =
            await _personalityLearning.initializePersonality(event.host.id);
        final hostVibe = await _userVibeAnalyzer.compileUserVibe(
            event.host.id, hostPersonality);
        bundleSignature = _performerVenueEventBundleBuilder.build(
          event: event,
          performer: event.host,
          performerVibe: hostVibe,
          performerPersonality: hostPersonality,
          venue: event.spots.first,
        );
      } else if (linkedCommunity != null) {
        bundleSignature = _communityEventBundleBuilder.build(
          community: linkedCommunity,
          event: event,
        );
      }
    } catch (e, st) {
      developer.log(
        'Bundle signature build failed for event ${event.id}: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }

    if (bundleSignature != null) {
      await _persistSignatureCompatibilityIfAllowed(bundleSignature);
      _syncSignatureToVibeKernel(bundleSignature);
      bundleSignature = _canonicalizeSignature(fallback: bundleSignature);
    }

    final signature = _eventSignatureBuilder.build(
      event: event,
      bundleSignature: bundleSignature,
    );
    await _persistSignatureCompatibilityIfAllowed(signature);
    _syncSignatureToVibeKernel(signature);
    return _canonicalizeSignature(fallback: signature);
  }

  Future<void> _persistSignatureCompatibilityIfAllowed(
    EntitySignature signature,
  ) async {
    if (_isCanonicalAuthorityActive) {
      return;
    }
    await _repository.save(signature);
  }

  void _syncSignatureToVibeKernel(EntitySignature signature) {
    try {
      _vibeKernel.ingestEntityObservation(
        entityId: signature.entityId,
        entityType: signature.entityKind.name,
        dimensions: signature.dna,
        provenanceTags: const <String>['entity_signature_sync'],
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to sync entity signature to VibeKernel: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  EntitySignature _canonicalizeSignature({
    required EntitySignature fallback,
    String? personalAgentId,
  }) {
    try {
      if (fallback.entityKind == SignatureEntityKind.user &&
          personalAgentId != null) {
        final snapshot = _vibeKernel.getUserSnapshot(personalAgentId);
        return _signatureFromCanonicalSnapshot(
          snapshot: snapshot,
          entityId: fallback.entityId,
          entityKind: fallback.entityKind,
          fallback: fallback,
        );
      }
      final entitySnapshot = _vibeKernel.getEntitySnapshot(
        entityId: fallback.entityId,
        entityType: fallback.entityKind.name,
      );
      return _signatureFromCanonicalSnapshot(
        snapshot: entitySnapshot.vibe,
        entityId: fallback.entityId,
        entityKind: fallback.entityKind,
        fallback: fallback,
      );
    } catch (_) {
      return fallback;
    }
  }

  EntitySignature _signatureFromCanonicalSnapshot({
    required VibeStateSnapshot snapshot,
    required String entityId,
    required SignatureEntityKind entityKind,
    required EntitySignature fallback,
  }) {
    return fallback.copyWith(
      signatureId: 'canonical:${entityKind.name}:$entityId',
      dna: snapshot.coreDna.dimensions,
      pheromones: snapshot.pheromones.vectors,
      confidence: snapshot.confidence,
      freshness: (1.0 - (snapshot.freshnessHours / 168.0)).clamp(0.0, 1.0),
      updatedAt: snapshot.updatedAtUtc,
      summary: 'Canonical ${entityKind.name} vibe projection from VibeKernel.',
      sourceTrace: _mergeSourceTrace(
        fallback.sourceTrace,
        const <SignatureSourceTrace>[
          SignatureSourceTrace(
            kind: SignatureSourceKind.derived,
            label: 'canonical_vibe_kernel',
            weight: 1.0,
          ),
        ],
      ),
    );
  }

  EntitySignature? getStoredSignature({
    required SignatureEntityKind entityKind,
    required String entityId,
  }) {
    return _repository.get(entityKind: entityKind, entityId: entityId);
  }

  SignatureMatchResult match({
    required EntitySignature userSignature,
    required EntitySignature entitySignature,
    required double fallbackScore,
  }) {
    return _matchService.match(
      userSignature: userSignature,
      entitySignature: entitySignature,
      fallbackScore: fallbackScore,
    );
  }

  Future<SignatureMatchResult> matchUserToSpot({
    required UnifiedUser user,
    required Spot spot,
    required double fallbackScore,
    PersonalityProfile? personality,
  }) async {
    final userSignature = await buildUserSignature(
      user: user,
      personality: personality,
    );
    final entitySignature = await buildSpotSignature(spot: spot);
    return match(
      userSignature: userSignature,
      entitySignature: entitySignature,
      fallbackScore: fallbackScore,
    );
  }

  Future<SignatureMatchResult> matchUserToCommunity({
    required UnifiedUser user,
    required Community community,
    required double fallbackScore,
    PersonalityProfile? personality,
  }) async {
    final userSignature = await buildUserSignature(
      user: user,
      personality: personality,
    );
    final entitySignature = await buildCommunitySignature(community: community);
    return match(
      userSignature: userSignature,
      entitySignature: entitySignature,
      fallbackScore: fallbackScore,
    );
  }

  Future<SignatureMatchResult> matchUserToEvent({
    required UnifiedUser user,
    required ExpertiseEvent event,
    required double fallbackScore,
    PersonalityProfile? personality,
    Community? linkedCommunity,
  }) async {
    final userSignature = await buildUserSignature(
      user: user,
      personality: personality,
    );
    final entitySignature = await buildEventSignature(
      event: event,
      linkedCommunity: linkedCommunity,
    );
    return match(
      userSignature: userSignature,
      entitySignature: entitySignature,
      fallbackScore: fallbackScore,
    );
  }

  Future<EntitySignature> recordSpotViewSignal({
    required UnifiedUser user,
    required Spot spot,
    PersonalityProfile? personality,
  }) async {
    final spotSignature = await buildSpotSignature(spot: spot);
    return _recordBehaviorSignal(
      user: user,
      targetSignature: spotSignature,
      signalType: 'spot_view',
      dnaInfluence: 0.03,
      pheromoneInfluence: 0.18,
      personality: personality,
    );
  }

  Future<EntitySignature> recordSpotSearchSelectionSignal({
    required String userId,
    required Spot spot,
    String? query,
    PersonalityProfile? personality,
  }) async {
    final user = _buildMinimalUser(
      userId: userId,
      location: spot.localityCode ?? spot.cityCode,
      tags: query == null || query.trim().isEmpty
          ? const <String>[]
          : <String>[query.trim()],
    );
    final spotSignature = await buildSpotSignature(spot: spot);
    return _recordBehaviorSignal(
      user: user,
      targetSignature: spotSignature,
      signalType: 'spot_search_select',
      dnaInfluence: 0.02,
      pheromoneInfluence: 0.16,
      personality: personality,
    );
  }

  Future<EntitySignature> recordSpotBrowseSelectionSignal({
    required String userId,
    required Spot spot,
    PersonalityProfile? personality,
  }) async {
    final user = _buildMinimalUser(
      userId: userId,
      location: spot.localityCode ?? spot.cityCode,
      tags: <String>[spot.category],
    );
    final spotSignature = await buildSpotSignature(spot: spot);
    return _recordBehaviorSignal(
      user: user,
      targetSignature: spotSignature,
      signalType: 'spot_browse_select',
      dnaInfluence: 0.02,
      pheromoneInfluence: 0.16,
      personality: personality,
    );
  }

  Future<EntitySignature> recordSpotReservationIntentSignal({
    required String userId,
    required Spot spot,
    PersonalityProfile? personality,
  }) async {
    final user = _buildMinimalUser(
      userId: userId,
      location: spot.localityCode ?? spot.cityCode,
    );
    final spotSignature = await buildSpotSignature(spot: spot);
    return _recordBehaviorSignal(
      user: user,
      targetSignature: spotSignature,
      signalType: 'spot_reservation_intent',
      dnaInfluence: 0.05,
      pheromoneInfluence: 0.28,
      personality: personality,
    );
  }

  Future<EntitySignature> recordCommunityViewSignal({
    required UnifiedUser user,
    required Community community,
    PersonalityProfile? personality,
  }) async {
    final communitySignature =
        await buildCommunitySignature(community: community);
    return _recordBehaviorSignal(
      user: user,
      targetSignature: communitySignature,
      signalType: 'community_view',
      dnaInfluence: 0.04,
      pheromoneInfluence: 0.22,
      personality: personality,
    );
  }

  Future<EntitySignature> recordCommunityBrowseSelectionSignal({
    required String userId,
    required Community community,
    PersonalityProfile? personality,
  }) async {
    final user = _buildMinimalUser(
      userId: userId,
      location: community.localityCode ?? community.cityCode,
      tags: <String>[community.category],
    );
    final communitySignature =
        await buildCommunitySignature(community: community);
    return _recordBehaviorSignal(
      user: user,
      targetSignature: communitySignature,
      signalType: 'community_browse_select',
      dnaInfluence: 0.02,
      pheromoneInfluence: 0.16,
      personality: personality,
    );
  }

  Future<EntitySignature> recordCommunityJoinSignal({
    required UnifiedUser user,
    required Community community,
    PersonalityProfile? personality,
  }) async {
    final communitySignature =
        await buildCommunitySignature(community: community);
    return _recordBehaviorSignal(
      user: user,
      targetSignature: communitySignature,
      signalType: 'community_join',
      dnaInfluence: 0.09,
      pheromoneInfluence: 0.34,
      personality: personality,
    );
  }

  Future<EntitySignature> recordEventViewSignal({
    required UnifiedUser user,
    required ExpertiseEvent event,
    PersonalityProfile? personality,
    Community? linkedCommunity,
  }) async {
    final eventSignature = await buildEventSignature(
      event: event,
      linkedCommunity: linkedCommunity,
    );
    return _recordBehaviorSignal(
      user: user,
      targetSignature: eventSignature,
      signalType: 'event_view',
      dnaInfluence: 0.03,
      pheromoneInfluence: 0.2,
      personality: personality,
    );
  }

  Future<EntitySignature> recordEventAttendanceSignal({
    required UnifiedUser user,
    required ExpertiseEvent event,
    PersonalityProfile? personality,
    Community? linkedCommunity,
  }) async {
    final eventSignature = await buildEventSignature(
      event: event,
      linkedCommunity: linkedCommunity,
    );
    return _recordBehaviorSignal(
      user: user,
      targetSignature: eventSignature,
      signalType: 'event_attend',
      dnaInfluence: 0.1,
      pheromoneInfluence: 0.38,
      personality: personality,
    );
  }

  Future<EntitySignature> recordEventReservationIntentSignal({
    required String userId,
    required ExpertiseEvent event,
    PersonalityProfile? personality,
    Community? linkedCommunity,
  }) async {
    final user = _buildMinimalUser(
      userId: userId,
      location: event.localityCode ?? event.cityCode ?? event.location,
      tags: <String>[event.category, event.eventType.name],
    );
    final eventSignature = await buildEventSignature(
      event: event,
      linkedCommunity: linkedCommunity,
    );
    return _recordBehaviorSignal(
      user: user,
      targetSignature: eventSignature,
      signalType: 'event_reservation_intent',
      dnaInfluence: 0.06,
      pheromoneInfluence: 0.3,
      personality: personality,
    );
  }

  Future<EntitySignature> recordEventBrowseSelectionSignal({
    required String userId,
    required ExpertiseEvent event,
    PersonalityProfile? personality,
    Community? linkedCommunity,
  }) async {
    final user = _buildMinimalUser(
      userId: userId,
      location: event.localityCode ?? event.cityCode ?? event.location,
      tags: <String>[event.category, event.eventType.name],
    );
    final eventSignature = await buildEventSignature(
      event: event,
      linkedCommunity: linkedCommunity,
    );
    return _recordBehaviorSignal(
      user: user,
      targetSignature: eventSignature,
      signalType: 'event_browse_select',
      dnaInfluence: 0.02,
      pheromoneInfluence: 0.16,
      personality: personality,
    );
  }

  Future<EntitySignature> recordChatReflectionSignal({
    required String userId,
    required String messageText,
    PersonalityProfile? personality,
  }) async {
    final normalizedMessage = messageText.trim();
    final user = _buildMinimalUser(
      userId: userId,
      tags: normalizedMessage.isEmpty
          ? const <String>[]
          : <String>[normalizedMessage],
    );
    final reflectionSignature = EntitySignature(
      signatureId: 'chat-reflection:$userId',
      entityId: userId,
      entityKind: SignatureEntityKind.user,
      dna: heuristicDimensionsFromText(
        title: normalizedMessage,
      ),
      pheromones: heuristicDimensionsFromText(
        title: normalizedMessage,
      ),
      confidence: normalizedMessage.isEmpty ? 0.35 : 0.6,
      freshness: 0.95,
      updatedAt: DateTime.now(),
      summary: 'Chat reflection signal',
      sourceTrace: const <SignatureSourceTrace>[
        SignatureSourceTrace(
          kind: SignatureSourceKind.derived,
          label: 'chat self-report',
          weight: 0.45,
        ),
      ],
    );
    return _recordBehaviorSignal(
      user: user,
      targetSignature: reflectionSignature,
      signalType: 'chat_reflection',
      dnaInfluence: 0.08,
      pheromoneInfluence: 0.22,
      personality: personality,
    );
  }

  Future<EntitySignature> recordNegativePreferenceSignal({
    required String userId,
    required String title,
    String? subtitle,
    String? category,
    List<String> tags = const <String>[],
    PersonalityProfile? personality,
    NegativePreferenceIntent intent =
        NegativePreferenceIntent.hardNotInterested,
    String entityType = 'user_feedback',
    String? cityCode,
    String? localityCode,
  }) async {
    final user = _buildMinimalUser(
      userId: userId,
      tags: <String>[
        title,
        if (category != null) category,
        ...tags,
      ],
    );
    final negativeSignature = EntitySignature(
      signatureId: 'negative-preference:$userId:${title.hashCode}',
      entityId: userId,
      entityKind: SignatureEntityKind.user,
      dna: heuristicDimensionsFromText(
        title: title,
        subtitle: subtitle,
        category: category,
        tags: tags,
      ),
      pheromones: heuristicDimensionsFromText(
        title: title,
        subtitle: subtitle,
        category: category,
        tags: tags,
      ),
      confidence: 0.68,
      freshness: 0.92,
      updatedAt: DateTime.now(),
      summary: 'Negative preference signal',
      sourceTrace: const <SignatureSourceTrace>[
        SignatureSourceTrace(
          kind: SignatureSourceKind.derived,
          label: 'negative preference signal',
          weight: 0.5,
        ),
      ],
    );
    final updatedSignature = await _recordBehaviorSignal(
      user: user,
      targetSignature: negativeSignature,
      signalType: switch (intent) {
        NegativePreferenceIntent.softIgnore => 'soft_ignore',
        NegativePreferenceIntent.hardNotInterested => 'hard_not_interested',
      },
      dnaInfluence: switch (intent) {
        NegativePreferenceIntent.softIgnore => 0.025,
        NegativePreferenceIntent.hardNotInterested => 0.06,
      },
      pheromoneInfluence: switch (intent) {
        NegativePreferenceIntent.softIgnore => 0.12,
        NegativePreferenceIntent.hardNotInterested => 0.24,
      },
      personality: personality,
      isPositiveSignal: false,
    );
    await _recordNegativeIntentTelemetry(
      userId: userId,
      intent: intent,
      entityType: entityType,
      title: title,
      cityCode: cityCode,
      localityCode: localityCode,
    );
    return updatedSignature;
  }

  EntitySignature _blendUserSignature({
    required EntitySignature existing,
    required EntitySignature latest,
  }) {
    return latest.copyWith(
      dna: SignatureDimensions.weightedBlend(
        <Map<String, double>>[
          existing.dna,
          latest.dna,
        ],
        weights: const <double>[
          _existingDnaWeight,
          _latestDnaWeight,
        ],
      ),
      pheromones: SignatureDimensions.weightedBlend(
        <Map<String, double>>[
          existing.pheromones,
          latest.pheromones,
        ],
        weights: const <double>[
          _existingPheromoneWeight,
          _latestPheromoneWeight,
        ],
      ),
      confidence: ((existing.confidence * 0.35) + (latest.confidence * 0.65))
          .clamp(0.0, 1.0),
      freshness: ((existing.freshness * 0.2) + (latest.freshness * 0.8))
          .clamp(0.0, 1.0),
      updatedAt: latest.updatedAt,
      summary: latest.summary,
      sourceTrace: _mergeSourceTrace(existing.sourceTrace, latest.sourceTrace),
      cityCode: latest.cityCode ?? existing.cityCode,
      localityCode: latest.localityCode ?? existing.localityCode,
      bundleEntityIds: <String>{
        ...existing.bundleEntityIds,
        ...latest.bundleEntityIds,
      }.toList(),
    );
  }

  UnifiedUser _buildOnboardingSeedUser({
    required String userId,
    required OnboardingData onboardingData,
    String? displayName,
    String? email,
  }) {
    final seedTags = <String>{
      ...onboardingData.favoritePlaces.map(_cleanSeedLabel),
      ...onboardingData.baselineLists.map(_cleanSeedLabel),
      ...onboardingData.preferences.keys.map(_cleanSeedLabel),
      ...onboardingData.preferences.values
          .expand((values) => values)
          .map(_cleanSeedLabel),
      ...onboardingData.socialMediaConnected.entries
          .where((entry) => entry.value)
          .map((entry) => _cleanSeedLabel(entry.key)),
      ...onboardingData.openResponses.keys.map(_cleanSeedLabel),
    }.where((tag) => tag.isNotEmpty).take(24).toList();

    final expertiseMap = <String, String>{
      for (final category in onboardingData.preferences.keys)
        if (category.trim().isNotEmpty) category.trim(): 'stated_preference',
    };

    return UnifiedUser(
      id: userId,
      email: email ?? '$userId@local.avrai',
      displayName: displayName,
      location: onboardingData.homebase,
      createdAt: onboardingData.completedAt,
      updatedAt: onboardingData.completedAt,
      hasCompletedOnboarding: true,
      expertise: onboardingData.preferences.keys.isEmpty
          ? null
          : onboardingData.preferences.keys.first,
      locations: onboardingData.homebase == null
          ? null
          : <String>[onboardingData.homebase!],
      tags: seedTags,
      expertiseMap: expertiseMap,
      friends: onboardingData.respectedFriends,
      isAgeVerified: (onboardingData.age ?? 0) >= 18,
      birthday: onboardingData.birthday,
    );
  }

  String _buildOnboardingSummary({
    required PersonalityProfile personality,
    required OnboardingData onboardingData,
  }) {
    final homebase = onboardingData.homebase?.trim();
    if (homebase != null && homebase.isNotEmpty) {
      return '${personality.archetype} baseline seeded from onboarding in $homebase.';
    }
    return '${personality.archetype} baseline seeded from onboarding.';
  }

  List<SignatureSourceTrace> _mergeSourceTrace(
    List<SignatureSourceTrace> existing,
    List<SignatureSourceTrace> incoming,
  ) {
    final merged = <String, SignatureSourceTrace>{};
    for (final trace in <SignatureSourceTrace>[...existing, ...incoming]) {
      final key = '${trace.kind.name}:${trace.label}:${trace.sourceId ?? ''}';
      merged[key] = trace;
    }
    return merged.values.toList();
  }

  String _cleanSeedLabel(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.length <= 40 ? normalized : normalized.substring(0, 40);
  }

  UnifiedUser _buildMinimalUser({
    required String userId,
    String? location,
    List<String> tags = const <String>[],
  }) {
    return UnifiedUser(
      id: userId,
      email: '$userId@avrai.local',
      location: location,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.now(),
      hasCompletedOnboarding: true,
      hasReceivedStarterLists: true,
      tags: tags.map(_cleanSeedLabel).where((tag) => tag.isNotEmpty).toList(),
    );
  }

  Future<EntitySignature> _recordBehaviorSignal({
    required UnifiedUser user,
    required EntitySignature targetSignature,
    required String signalType,
    required double dnaInfluence,
    required double pheromoneInfluence,
    PersonalityProfile? personality,
    bool isPositiveSignal = true,
  }) async {
    if (_isCanonicalAuthorityActive) {
      _recordBehaviorSignalInVibeKernel(
        userId: user.id,
        personalAgentId: personality?.agentId,
        targetSignature: targetSignature,
        signalType: signalType,
        dnaInfluence: dnaInfluence,
        pheromoneInfluence: pheromoneInfluence,
        isPositiveSignal: isPositiveSignal,
      );
      return buildUserSignature(
        user: user,
        personality: personality,
      );
    }
    final behaviorState = _updateBehaviorLearningState(
      existing: _loadBehaviorLearningState(user.id),
      targetSignature: targetSignature,
      signalType: signalType,
      dnaInfluence: dnaInfluence,
      pheromoneInfluence: pheromoneInfluence,
      isPositiveSignal: isPositiveSignal,
    );
    await _saveBehaviorLearningState(user.id, behaviorState);
    return buildUserSignature(
      user: user,
      personality: personality,
    );
  }

  void _recordBehaviorSignalInVibeKernel({
    required String userId,
    required String? personalAgentId,
    required EntitySignature targetSignature,
    required String signalType,
    required double dnaInfluence,
    required double pheromoneInfluence,
    required bool isPositiveSignal,
  }) {
    final subjectId = personalAgentId ?? targetSignature.entityId;
    final signals = <String, double>{
      ..._salientBehaviorSignals(
        prefix: '$signalType:dna',
        dimensions: targetSignature.dna,
        influence: dnaInfluence,
        isPositiveSignal: isPositiveSignal,
      ),
      ..._salientBehaviorSignals(
        prefix: '$signalType:pheromone',
        dimensions: targetSignature.pheromones,
        influence: pheromoneInfluence,
        isPositiveSignal: isPositiveSignal,
      ),
      '$signalType:polarity': isPositiveSignal ? 1.0 : 0.0,
    };

    _vibeKernel.ingestBehaviorObservation(
      subjectId: subjectId,
      behaviorSignals: signals,
      provenanceTags: <String>[
        'entity_signature_behavior',
        'user:$userId',
        'signal:$signalType',
        if (!isPositiveSignal) 'negative',
      ],
    );
  }

  Map<String, double> _salientBehaviorSignals({
    required String prefix,
    required Map<String, double> dimensions,
    required double influence,
    required bool isPositiveSignal,
  }) {
    final entries = dimensions.entries.toList(growable: false)
      ..sort(
        (left, right) =>
            (right.value - 0.5).abs().compareTo((left.value - 0.5).abs()),
      );
    final normalizedInfluence = influence.clamp(0.0, 1.0);
    final selected = entries.take(6);
    return <String, double>{
      for (final entry in selected)
        '$prefix:${entry.key}': ((isPositiveSignal ? entry.value : 1.0 - entry.value) *
                normalizedInfluence)
            .clamp(0.0, 1.0),
    };
  }

  EntitySignature _applyBehaviorLearning({
    required EntitySignature signature,
    required _UserSignatureBehaviorState behaviorState,
  }) {
    final dnaInfluence =
        (0.03 + (behaviorState.signalCount * 0.01)).clamp(0.03, 0.15);
    final pheromoneInfluence =
        (0.18 + (behaviorState.signalCount * 0.03)).clamp(0.18, 0.45);
    return signature.copyWith(
      dna: SignatureDimensions.weightedBlend(
        <Map<String, double>>[
          signature.dna,
          behaviorState.dna,
        ],
        weights: <double>[
          1.0 - dnaInfluence,
          dnaInfluence,
        ],
      ),
      pheromones: SignatureDimensions.weightedBlend(
        <Map<String, double>>[
          signature.pheromones,
          behaviorState.pheromones,
        ],
        weights: <double>[
          1.0 - pheromoneInfluence,
          pheromoneInfluence,
        ],
      ),
      sourceTrace: _mergeSourceTrace(
        signature.sourceTrace,
        <SignatureSourceTrace>[
          SignatureSourceTrace(
            kind: SignatureSourceKind.derived,
            label: 'behavioral learning signals (${behaviorState.signalCount})',
            sourceId: behaviorState.lastSignalType,
            weight: pheromoneInfluence,
          ),
        ],
      ),
    );
  }

  _UserSignatureBehaviorState _updateBehaviorLearningState({
    required _UserSignatureBehaviorState? existing,
    required EntitySignature targetSignature,
    required String signalType,
    required double dnaInfluence,
    required double pheromoneInfluence,
    required bool isPositiveSignal,
  }) {
    final signalDna = isPositiveSignal
        ? targetSignature.dna
        : _invertDimensions(targetSignature.dna);
    final signalPheromones = isPositiveSignal
        ? targetSignature.pheromones
        : _invertDimensions(targetSignature.pheromones);
    if (existing == null) {
      return _UserSignatureBehaviorState(
        dna: signalDna,
        pheromones: signalPheromones,
        signalCount: 1,
        lastSignalType: signalType,
      );
    }

    return _UserSignatureBehaviorState(
      dna: SignatureDimensions.weightedBlend(
        <Map<String, double>>[
          existing.dna,
          signalDna,
        ],
        weights: <double>[
          1.0 - dnaInfluence,
          dnaInfluence,
        ],
      ),
      pheromones: SignatureDimensions.weightedBlend(
        <Map<String, double>>[
          existing.pheromones,
          signalPheromones,
        ],
        weights: <double>[
          1.0 - pheromoneInfluence,
          pheromoneInfluence,
        ],
      ),
      signalCount: existing.signalCount + 1,
      lastSignalType: signalType,
    );
  }

  Map<String, double> _invertDimensions(Map<String, double> dimensions) {
    final normalized = SignatureDimensions.normalize(dimensions);
    final inverted = <String, double>{};
    for (final entry in normalized.entries) {
      inverted[entry.key] = (1.0 - entry.value).clamp(0.0, 1.0);
    }
    return SignatureDimensions.normalize(inverted);
  }

  Future<void> _recordNegativeIntentTelemetry({
    required String userId,
    required NegativePreferenceIntent intent,
    required String entityType,
    required String title,
    String? cityCode,
    String? localityCode,
  }) async {
    final remoteService = _remoteSourceHealthService;
    if (remoteService == null || !remoteService.isAvailable) {
      return;
    }
    final now = DateTime.now();
    final intentLabel = switch (intent) {
      NegativePreferenceIntent.softIgnore => 'soft_ignore',
      NegativePreferenceIntent.hardNotInterested => 'hard_not_interested',
    };
    try {
      await remoteService.upsertSourceHealth(
        sourceId: 'feedback:$intentLabel:$userId:${now.microsecondsSinceEpoch}',
        ownerUserId: userId,
        provider: 'user_feedback',
        entityType: entityType,
        categoryLabel: intentLabel,
        sourceLabel: title,
        cityCode: cityCode,
        localityCode: localityCode,
        confidence: 1.0,
        freshness: 1.0,
        fallbackRate: 0.0,
        reviewNeeded: false,
        syncState: 'captured',
        summary: switch (intent) {
          NegativePreferenceIntent.softIgnore =>
            '$entityType softly ignored by user feedback.',
          NegativePreferenceIntent.hardNotInterested =>
            '$entityType explicitly rejected by user feedback.',
        },
        lastSyncAt: now,
        lastSignatureRebuildAt: now,
      );
    } catch (e, st) {
      developer.log(
        'Failed to record negative intent telemetry',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  _UserSignatureBehaviorState? _loadBehaviorLearningState(String userId) {
    if (_isCanonicalAuthorityActive) {
      return null;
    }
    final raw = _storageService.getObject<Map<dynamic, dynamic>>(
      '$_behaviorLearningStoragePrefix$userId',
    );
    if (raw == null) {
      return null;
    }

    return _UserSignatureBehaviorState.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<void> _saveBehaviorLearningState(
    String userId,
    _UserSignatureBehaviorState state,
  ) async {
    if (_isCanonicalAuthorityActive) {
      return;
    }
    await _storageService.setObject(
      '$_behaviorLearningStoragePrefix$userId',
      state.toJson(),
    );
  }
}

class _UserSignatureBehaviorState {
  final Map<String, double> dna;
  final Map<String, double> pheromones;
  final int signalCount;
  final String lastSignalType;

  const _UserSignatureBehaviorState({
    required this.dna,
    required this.pheromones,
    required this.signalCount,
    required this.lastSignalType,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dna': SignatureDimensions.normalize(dna),
      'pheromones': SignatureDimensions.normalize(pheromones),
      'signalCount': signalCount,
      'lastSignalType': lastSignalType,
    };
  }

  factory _UserSignatureBehaviorState.fromJson(Map<String, dynamic> json) {
    Map<String, double> parseDimensions(Object? raw) {
      if (raw is! Map) {
        return SignatureDimensions.normalize(const <String, double>{});
      }

      final parsed = <String, double>{};
      for (final entry in raw.entries) {
        if (entry.value is num) {
          parsed[entry.key.toString()] = (entry.value as num).toDouble();
        }
      }
      return SignatureDimensions.normalize(parsed);
    }

    return _UserSignatureBehaviorState(
      dna: parseDimensions(json['dna']),
      pheromones: parseDimensions(json['pheromones']),
      signalCount: (json['signalCount'] as num?)?.toInt() ?? 0,
      lastSignalType: json['lastSignalType'] as String? ?? 'unknown',
    );
  }
}
