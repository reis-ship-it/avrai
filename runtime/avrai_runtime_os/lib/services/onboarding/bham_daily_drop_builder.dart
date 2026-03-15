import 'dart:convert';

import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/feed/daily_serendipity_drop.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/controllers/base/controller_result.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';
import 'package:avrai_runtime_os/services/prediction/swarm_prior_loader.dart';
import 'package:avrai_runtime_os/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart';
import 'package:get_it/get_it.dart';

class BhamDailyDropBuilder {
  static const String _legacyDropKey = 'latest_daily_serendipity_drop';
  static const String _logName = 'BhamDailyDropBuilder';

  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final SwarmPriorLoader _priorLoader;
  final SharedPreferencesCompat? _prefs;

  BhamDailyDropBuilder({
    SwarmPriorLoader? priorLoader,
    SharedPreferencesCompat? prefs,
  })  : _priorLoader = priorLoader ?? SwarmPriorLoader(),
        _prefs = prefs ??
            (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                ? GetIt.instance<SharedPreferencesCompat>()
                : null);

  Future<OsBackedFlowResult<DailySerendipityDrop>> buildInitialDrop({
    required String userId,
    required OnboardingData onboardingData,
    HeadlessAvraiOsBootstrapSnapshot? restoredHeadlessOsBootstrapSnapshot,
    RealityKernelFusionInput? realityKernelFusionInput,
    KernelGovernanceReport? kernelGovernanceReport,
  }) async {
    final missingKeys = _missingMandatoryQuestionKeys(onboardingData);
    if (missingKeys.isNotEmpty) {
      return OsBackedFlowResult<DailySerendipityDrop>.failure(
        error:
            'Missing required BHAM questionnaire responses: ${missingKeys.join(", ")}',
        errorCode: 'BHAM_QUESTIONNAIRE_INCOMPLETE',
        restoredHeadlessOsBootstrapSnapshot:
            restoredHeadlessOsBootstrapSnapshot,
        degraded: true,
      );
    }

    if (!onboardingData.betaConsentAccepted) {
      return OsBackedFlowResult<DailySerendipityDrop>.failure(
        error:
            'BHAM beta consent must be accepted before building the first drop.',
        errorCode: 'BHAM_CONSENT_REQUIRED',
        restoredHeadlessOsBootstrapSnapshot:
            restoredHeadlessOsBootstrapSnapshot,
        degraded: true,
      );
    }

    final now = DateTime.now().toUtc();
    final prior = _priorLoader.getPriorForCity('birmingham');
    final bootstrapReady = restoredHeadlessOsBootstrapSnapshot != null;
    final topic = _topicFor(onboardingData);
    final neighborhood = _neighborhoodFor(onboardingData);
    final exploringBias = prior[UserEngagementPhase.onboarding]
            ?[UserEngagementPhase.exploring] ??
        0;
    final connectingBias = prior[UserEngagementPhase.onboarding]
            ?[UserEngagementPhase.connecting] ??
        0;
    final routeReceipt =
        TransportRouteReceiptCompatibilityTranslator.buildLocalOnly(
      receiptId: 'daily_drop:$userId:${now.microsecondsSinceEpoch}',
      channel: 'bham_daily_drop_builder',
      status: 'persisted',
      recordedAtUtc: now,
      metadata: <String, dynamic>{
        'beta_program': BhamBetaDefaults.betaProgram,
        'storage_key': DailySerendipityDropStorage.latestDropKey,
        'legacy_drop_key_cleared': true,
      },
    );

    final drop = DailySerendipityDrop(
      date: now,
      cityName: 'Birmingham',
      llmContextualInsight: _buildInsight(
        topic: topic,
        neighborhood: neighborhood,
        bootstrapReady: bootstrapReady,
        exploringBias: exploringBias,
        connectingBias: connectingBias,
      ),
      generatedAtUtc: now,
      expiresAtUtc: now.add(const Duration(hours: 24)),
      refreshReason: 'onboarding_completion',
      spot: DropSpot(
        id: 'spot_${now.millisecondsSinceEpoch}',
        title: '$neighborhood reset spot',
        subtitle: 'A low-friction Birmingham door built around $topic.',
        category: 'Spot',
        distanceMiles: 2.4,
        archetypeAffinity: 0.91,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.spot,
          id: 'spot_${now.millisecondsSinceEpoch}',
          title: '$neighborhood reset spot',
          routePath: '/spot/create',
          localityLabel: neighborhood,
        ),
        attribution: RecommendationAttribution(
          why: 'This spot gives you a low-friction first move in Birmingham.',
          whyDetails:
              'The first slice prioritizes places that fit your onboarding signal and locality.',
          projectedEnjoyabilityPercent: 91,
          recommendationSource: 'bham_initial_drop',
          confidence: 0.91,
        ),
        signatureSummary:
            'Start with a Birmingham place that matches what you want more of right now.',
      ),
      list: DropList(
        id: 'list_${now.millisecondsSinceEpoch}',
        title: 'A Birmingham list for $topic',
        subtitle: 'Five grounded doors to try without overplanning.',
        itemCount: 5,
        curatorNote:
            'Generated from your BHAM onboarding answers and Birmingham priors.',
        archetypeAffinity: 0.93,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.list,
          id: 'list_${now.millisecondsSinceEpoch}',
          title: 'A Birmingham list for $topic',
          routePath: '/list/create',
          localityLabel: neighborhood,
        ),
        attribution: RecommendationAttribution(
          why:
              'This list turns your onboarding signal into a small set of usable doors.',
          whyDetails:
              'The list slot is the one explicit AI-generated category when graph density is still low.',
          projectedEnjoyabilityPercent: 93,
          recommendationSource: 'bham_initial_drop',
          confidence: 0.93,
        ),
        generatedByAi: true,
        signatureSummary:
            'This list is the AI-generated category in your first BHAM drop.',
      ),
      event: DropEvent(
        id: 'event_${now.millisecondsSinceEpoch}',
        title: '$neighborhood check-in event',
        subtitle: 'A Birmingham outing that keeps the first move easy.',
        time: now.add(const Duration(hours: 18)),
        locationName: neighborhood,
        archetypeAffinity: 0.88,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.event,
          id: 'event_${now.millisecondsSinceEpoch}',
          title: '$neighborhood check-in event',
          routePath: '/event/create',
          localityLabel: neighborhood,
        ),
        attribution: RecommendationAttribution(
          why:
              'This event keeps momentum high without overcommitting your first beta day.',
          whyDetails:
              'The first BHAM event recommendation favors exploration and realistic follow-through.',
          projectedEnjoyabilityPercent: 88,
          recommendationSource: 'bham_initial_drop',
          confidence: 0.88,
        ),
        signatureSummary:
            'This first event favors exploration without demanding too much commitment.',
      ),
      club: DropClub(
        id: 'club_${now.millisecondsSinceEpoch}',
        title: '$topic club starter',
        subtitle:
            'A Birmingham club door that can exist before the graph is dense.',
        applicationStatus: 'Open',
        vibe: 'Grounded and local',
        archetypeAffinity: 0.84,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.club,
          id: 'club_${now.millisecondsSinceEpoch}',
          title: '$topic club starter',
          routePath: '/club/create',
          localityLabel: neighborhood,
        ),
        attribution: RecommendationAttribution(
          why:
              'This club slot keeps a structured social option explicit in the beta.',
          whyDetails:
              'Clubs stay creation-friendly until the real Birmingham club graph becomes dense enough.',
          projectedEnjoyabilityPercent: 84,
          recommendationSource: 'bham_initial_drop',
          confidence: 0.84,
        ),
        isPlaceholder: false,
        signatureSummary:
            'Clubs are still sparse in wave 1, so this slot stays creation-friendly but explicit.',
      ),
      community: DropCommunity(
        id: 'community_${now.millisecondsSinceEpoch}',
        title: 'Birmingham $topic community',
        subtitle: 'A people-shaped door rather than a content feed.',
        memberCount: 18,
        commonInterests: <String>[
          topic,
          _normalizedAnswer(onboardingData.openResponses['values']),
          'Birmingham',
        ],
        archetypeAffinity: 0.9,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.community,
          id: 'community_${now.millisecondsSinceEpoch}',
          title: 'Birmingham $topic community',
          routePath: '/community/create',
          localityLabel: neighborhood,
        ),
        attribution: RecommendationAttribution(
          why:
              'This community matches the social direction you pointed to during onboarding.',
          whyDetails:
              'The first community slot leans toward locality and shared values rather than generic feeds.',
          projectedEnjoyabilityPercent: 90,
          recommendationSource: 'bham_initial_drop',
          confidence: 0.9,
        ),
        signatureSummary:
            'This community slot leans toward the social direction your onboarding answers pointed to.',
      ),
    );

    final envelope = KernelEventEnvelope(
      eventId: 'daily_drop_generated:$userId:${now.microsecondsSinceEpoch}',
      occurredAtUtc: now,
      userId: userId,
      agentId: onboardingData.agentId,
      sourceSystem: 'bham_daily_drop_builder',
      eventType: 'daily_drop_generated',
      actionType: 'build_initial_drop',
      entityId: onboardingData.agentId,
      entityType: 'agent',
      primarySliceId: BhamBetaDefaults.firstSliceId,
      relatedSliceIds: const <String>[
        BhamBetaDefaults.betaProgram,
        'onboarding',
        'daily_drop',
      ],
      routeReceipt: routeReceipt,
      adminProvenance: <String, dynamic>{
        'beta_program': BhamBetaDefaults.betaProgram,
        'questionnaire_version': onboardingData.questionnaireVersion,
        'beta_consent_version': onboardingData.betaConsentVersion,
        'model_truth_ready': realityKernelFusionInput != null,
        'governance_ready': kernelGovernanceReport != null,
      },
      context: <String, dynamic>{
        'homebase': onboardingData.homebase ?? BhamBetaDefaults.defaultHomebase,
        'topic': topic,
        'neighborhood': neighborhood,
      },
      predictionContext: <String, dynamic>{
        'exploring_bias': exploringBias,
        'connecting_bias': connectingBias,
      },
      runtimeContext: <String, dynamic>{
        'bootstrap_restored': bootstrapReady,
        'locality_contained_in_where':
            realityKernelFusionInput?.localityContainedInWhere ?? false,
      },
    );

    try {
      await persistDrop(drop);
      await invalidateLegacyDropCache();
      return OsBackedFlowResult<DailySerendipityDrop>.success(
        data: drop,
        degraded: false,
        restoredHeadlessOsBootstrapSnapshot:
            restoredHeadlessOsBootstrapSnapshot,
        kernelEventEnvelope: envelope,
        routeReceipt: routeReceipt,
        metadata: <String, dynamic>{
          'questionnaireVersion': onboardingData.questionnaireVersion,
          'betaConsentVersion': onboardingData.betaConsentVersion,
          'storageKey': DailySerendipityDropStorage.latestDropKey,
          'city': 'Birmingham',
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to persist BHAM initial daily drop',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return OsBackedFlowResult<DailySerendipityDrop>.failure(
        error: 'Failed to persist the BHAM first daily drop: $e',
        errorCode: 'BHAM_DROP_PERSISTENCE_FAILED',
        restoredHeadlessOsBootstrapSnapshot:
            restoredHeadlessOsBootstrapSnapshot,
        kernelEventEnvelope: envelope,
        routeReceipt: routeReceipt,
        degraded: true,
      );
    }
  }

  Future<OsBackedFlowResult<DailySerendipityDrop>> buildRefreshDrop({
    required String userId,
    String cityName = 'Birmingham',
    Map<String, dynamic> context = const <String, dynamic>{},
  }) async {
    final now = DateTime.now().toUtc();
    final insightTopic = _normalizedAnswer(context['topic']?.toString());
    final drop = DailySerendipityDrop(
      date: now,
      cityName: cityName,
      llmContextualInsight:
          'Today\'s Birmingham drop keeps the signal small and useful so you can act on it in real life.',
      generatedAtUtc: now,
      expiresAtUtc: now.add(const Duration(hours: 24)),
      refreshReason: 'manual_refresh',
      spot: DropSpot(
        id: 'spot_refresh_${now.millisecondsSinceEpoch}',
        title:
            '${context['neighborhood'] ?? 'Highland Park'} follow-through spot',
        subtitle: 'A place to keep momentum instead of starting from zero.',
        category: 'Spot',
        distanceMiles: 1.8,
        archetypeAffinity: 0.82,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.spot,
          id: 'spot_refresh_${now.millisecondsSinceEpoch}',
          title:
              '${context['neighborhood'] ?? 'Highland Park'} follow-through spot',
          routePath: '/spot/create',
          localityLabel: context['neighborhood']?.toString(),
        ),
        attribution: RecommendationAttribution(
          why:
              'This spot keeps your Birmingham loop moving without resetting from zero.',
          whyDetails: 'Refresh drops prefer practical follow-through options.',
          projectedEnjoyabilityPercent: 82,
          recommendationSource: 'bham_refresh_drop',
          confidence: 0.82,
        ),
        signatureSummary:
            'Refresh drops keep the same 5-slot BHAM contract as onboarding.',
      ),
      list: DropList(
        id: 'list_refresh_${now.millisecondsSinceEpoch}',
        title: 'A refreshed Birmingham list',
        subtitle:
            'A smaller set of doors around ${insightTopic.isEmpty ? 'your current signal' : insightTopic}.',
        itemCount: 5,
        curatorNote: 'Refresh contract reused from the BHAM first slice.',
        archetypeAffinity: 0.85,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.list,
          id: 'list_refresh_${now.millisecondsSinceEpoch}',
          title: 'A refreshed Birmingham list',
          routePath: '/list/create',
          localityLabel: context['neighborhood']?.toString(),
        ),
        attribution: RecommendationAttribution(
          why:
              'This refreshed list keeps the recommendation loop small and actionable.',
          whyDetails:
              'Lists remain the explicit AI-generated slot when needed.',
          projectedEnjoyabilityPercent: 85,
          recommendationSource: 'bham_refresh_drop',
          confidence: 0.85,
        ),
        generatedByAi: true,
        signatureSummary:
            'The list slot remains the one AI-generated category if the graph is thin.',
      ),
      event: DropEvent(
        id: 'event_refresh_${now.millisecondsSinceEpoch}',
        title: 'Birmingham keep-moving event',
        subtitle: 'A light-weight event door for the next cycle.',
        time: now.add(const Duration(hours: 12)),
        locationName: '${context['neighborhood'] ?? 'Birmingham'}',
        archetypeAffinity: 0.8,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.event,
          id: 'event_refresh_${now.millisecondsSinceEpoch}',
          title: 'Birmingham keep-moving event',
          routePath: '/event/create',
          localityLabel: context['neighborhood']?.toString(),
        ),
        attribution: RecommendationAttribution(
          why:
              'This event keeps the next social step light enough to follow through on.',
          whyDetails:
              'Refresh events favor practical momentum over novelty spikes.',
          projectedEnjoyabilityPercent: 80,
          recommendationSource: 'bham_refresh_drop',
          confidence: 0.8,
        ),
        signatureSummary:
            'Refresh events stay aligned with the same BHAM contract and storage key.',
      ),
      club: DropClub(
        id: 'club_refresh_${now.millisecondsSinceEpoch}',
        title: 'Birmingham club follow-up',
        subtitle:
            'A club lane that remains explicit even when the graph is sparse.',
        applicationStatus: 'Open',
        vibe: 'Warm and local',
        archetypeAffinity: 0.79,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.club,
          id: 'club_refresh_${now.millisecondsSinceEpoch}',
          title: 'Birmingham club follow-up',
          routePath: '/club/create',
          localityLabel: context['neighborhood']?.toString(),
        ),
        attribution: RecommendationAttribution(
          why:
              'This club suggestion keeps structure available without forcing it.',
          whyDetails:
              'Club density is still low, so the slot stays explicit and creation-friendly.',
          projectedEnjoyabilityPercent: 79,
          recommendationSource: 'bham_refresh_drop',
          confidence: 0.79,
        ),
        signatureSummary:
            'This slot remains creation-friendly until real club density improves.',
      ),
      community: DropCommunity(
        id: 'community_refresh_${now.millisecondsSinceEpoch}',
        title: 'Birmingham community follow-up',
        subtitle: 'A community door that holds on to the real-world loop.',
        memberCount: 22,
        commonInterests: <String>[
          if (insightTopic.isNotEmpty) insightTopic,
          'Birmingham',
        ],
        archetypeAffinity: 0.83,
        objectRef: DiscoveryEntityReference(
          type: DiscoveryEntityType.community,
          id: 'community_refresh_${now.millisecondsSinceEpoch}',
          title: 'Birmingham community follow-up',
          routePath: '/community/create',
          localityLabel: context['neighborhood']?.toString(),
        ),
        attribution: RecommendationAttribution(
          why: 'This community keeps the social loop grounded in Birmingham.',
          whyDetails:
              'Refresh communities still prioritize locality and real-world participation.',
          projectedEnjoyabilityPercent: 83,
          recommendationSource: 'bham_refresh_drop',
          confidence: 0.83,
        ),
        signatureSummary:
            'Refresh communities still use the explicit 5-category BHAM contract.',
      ),
    );

    try {
      await persistDrop(drop);
      await invalidateLegacyDropCache();
      return OsBackedFlowResult<DailySerendipityDrop>.success(
        data: drop,
        metadata: <String, dynamic>{
          'storageKey': DailySerendipityDropStorage.latestDropKey,
          'city': cityName,
        },
      );
    } catch (e) {
      return OsBackedFlowResult<DailySerendipityDrop>.failure(
        error: 'Failed to persist refreshed BHAM drop: $e',
        errorCode: 'BHAM_REFRESH_DROP_FAILED',
        degraded: true,
      );
    }
  }

  Future<void> persistDrop(DailySerendipityDrop drop) async {
    final prefs = await _resolvePrefs();
    await prefs.setString(
      DailySerendipityDropStorage.latestDropKey,
      jsonEncode(drop.toJson()),
    );
  }

  Future<void> invalidateLegacyDropCache() async {
    final prefs = await _resolvePrefs();
    if (prefs.containsKey(_legacyDropKey)) {
      await prefs.remove(_legacyDropKey);
    }
  }

  Future<DailySerendipityDrop?> loadLatestDrop() async {
    final prefs = await _resolvePrefs();
    final raw = prefs.getString(DailySerendipityDropStorage.latestDropKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      return DailySerendipityDrop.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(raw) as Map,
        ),
      );
    } catch (e) {
      _logger.warn(
        'Invalid BHAM drop cache detected. Clearing stale payload.',
        tag: _logName,
      );
      await prefs.remove(DailySerendipityDropStorage.latestDropKey);
      return null;
    }
  }

  Future<SharedPreferencesCompat> _resolvePrefs() async {
    if (_prefs != null) {
      return _prefs;
    }
    return SharedPreferencesCompat.getInstance();
  }

  List<String> _missingMandatoryQuestionKeys(OnboardingData onboardingData) {
    return BhamBetaDefaults.mandatoryQuestionKeys
        .where((key) => !_hasResponse(onboardingData.openResponses[key]))
        .toList();
  }

  bool _hasResponse(String? value) => value != null && value.trim().isNotEmpty;

  String _topicFor(OnboardingData onboardingData) {
    final values = <String>[
      onboardingData.openResponses['interests'] ?? '',
      onboardingData.openResponses['fun'] ?? '',
      onboardingData.openResponses['bio'] ?? '',
    ].join(' ').toLowerCase();

    if (values.contains('music')) {
      return 'music';
    }
    if (values.contains('run') || values.contains('walk')) {
      return 'movement';
    }
    if (values.contains('art') || values.contains('design')) {
      return 'creative energy';
    }
    if (values.contains('food') || values.contains('coffee')) {
      return 'food and coffee';
    }
    if (values.contains('faith') || values.contains('spiritual')) {
      return 'grounded community';
    }
    return 'your current season';
  }

  String _neighborhoodFor(OnboardingData onboardingData) {
    final combined = <String>[
      onboardingData.homebase ?? '',
      onboardingData.openResponses['favorite_places'] ?? '',
      onboardingData.openResponses['bio'] ?? '',
    ].join(' ').toLowerCase();

    if (combined.contains('avondale')) return 'Avondale';
    if (combined.contains('homewood')) return 'Homewood';
    if (combined.contains('five points')) return 'Five Points South';
    if (combined.contains('railroad')) return 'Railroad Park';
    return 'Highland Park';
  }

  String _buildInsight({
    required String topic,
    required String neighborhood,
    required bool bootstrapReady,
    required int exploringBias,
    required int connectingBias,
  }) {
    final bootstrapPhrase = bootstrapReady
        ? 'Your restored AVRAI runtime is already carrying forward context.'
        : 'Your live AVRAI runtime just established its first Birmingham context.';
    final biasPhrase = exploringBias >= connectingBias
        ? 'This first drop leans toward exploration before deeper social commitment.'
        : 'This first drop leans toward social doors that can become repeating patterns.';
    return '$bootstrapPhrase $biasPhrase It starts in $neighborhood and stays anchored to $topic.';
  }

  String _normalizedAnswer(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'what matters right now';
    }
    if (trimmed.length <= 48) {
      return trimmed;
    }
    return '${trimmed.substring(0, 45).trim()}...';
  }
}
