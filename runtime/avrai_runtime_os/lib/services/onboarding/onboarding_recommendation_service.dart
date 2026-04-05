import 'dart:developer' as developer;
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:get_it/get_it.dart';

/// OnboardingRecommendationService
///
/// Recommends lists and accounts to follow based on onboarding data
/// and personality dimensions.
///
/// Uses agentId internally for privacy protection per Master Plan Phase 7.3.
/// Accepts userId in public API but converts to agentId internally.
class OnboardingRecommendationService {
  static const String _logName = 'OnboardingRecommendationService';

  final AgentIdService _agentIdService;
  final HeadlessAvraiOsHost? _headlessOsHost;
  final GovernedDomainConsumerStateService? _governedDomainConsumerStateService;

  OnboardingRecommendationService({
    AgentIdService? agentIdService,
    HeadlessAvraiOsHost? headlessOsHost,
    GovernedDomainConsumerStateService? governedDomainConsumerStateService,
  })  : _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _headlessOsHost = headlessOsHost ??
            (GetIt.I.isRegistered<HeadlessAvraiOsHost>()
                ? GetIt.I<HeadlessAvraiOsHost>()
                : null),
        _governedDomainConsumerStateService =
            governedDomainConsumerStateService ??
                (GetIt.I.isRegistered<GovernedDomainConsumerStateService>()
                    ? GetIt.I<GovernedDomainConsumerStateService>()
                    : null);

  /// Get recommended lists to follow based on onboarding
  ///
  /// [userId] - Authenticated user ID from UI layer
  /// [onboardingData] - User's onboarding data
  /// [personalityDimensions] - User's personality dimensions
  /// [maxRecommendations] - Maximum number of recommendations
  ///
  /// Returns list of recommended lists
  Future<List<ListRecommendation>> getRecommendedLists({
    required String userId,
    required Map<String, dynamic> onboardingData,
    required Map<String, double> personalityDimensions,
    int maxRecommendations = 10,
  }) async {
    try {
      developer.log(
        'Getting recommended lists for user: $userId',
        name: _logName,
      );

      // Convert userId → agentId for privacy-protected operations
      final agentId = await _agentIdService.getUserAgentId(userId);
      final kernelArtifact = await _buildKernelArtifact(
        agentId: agentId,
        onboardingData: onboardingData,
        personalityDimensions: personalityDimensions,
        recommendationKind: 'list',
      );
      final governedListState =
          _governedDomainConsumerStateService?.latestLiveStateFor(
        cityCode: onboardingData['cityCode']?.toString(),
        domainId: 'list',
      );

      final recommendations = <ListRecommendation>[];

      // Find lists by preferences
      final prefLists = _findListsByPreferences(
        onboardingData,
        personalityDimensions,
        kernelArtifact: kernelArtifact,
        governedListState: governedListState,
        maxRecommendations: maxRecommendations ~/ 3,
      );
      recommendations.addAll(prefLists);

      // Find lists by homebase
      if (recommendations.length < maxRecommendations) {
        final homebaseLists = _findListsByHomebase(
          onboardingData,
          personalityDimensions,
          kernelArtifact: kernelArtifact,
          governedListState: governedListState,
          maxRecommendations: maxRecommendations ~/ 3,
        );
        recommendations.addAll(homebaseLists);
      }

      // Find lists by archetype
      if (recommendations.length < maxRecommendations) {
        final archetypeLists = _findListsByArchetype(
          personalityDimensions,
          kernelArtifact: kernelArtifact,
          governedListState: governedListState,
          maxRecommendations: maxRecommendations - recommendations.length,
        );
        recommendations.addAll(archetypeLists);
      }

      // Sort by compatibility score
      recommendations
          .sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

      developer.log(
        '✅ Found ${recommendations.length} list recommendations',
        name: _logName,
      );

      return recommendations.take(maxRecommendations).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting recommended lists: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get recommended accounts to follow based on onboarding
  ///
  /// [userId] - Authenticated user ID from UI layer
  /// [onboardingData] - User's onboarding data
  /// [personalityDimensions] - User's personality dimensions
  /// [maxRecommendations] - Maximum number of recommendations
  ///
  /// Returns list of recommended accounts
  Future<List<AccountRecommendation>> getRecommendedAccounts({
    required String userId,
    required Map<String, dynamic> onboardingData,
    required Map<String, double> personalityDimensions,
    int maxRecommendations = 10,
  }) async {
    try {
      developer.log(
        'Getting recommended accounts for user: $userId',
        name: _logName,
      );

      final agentId = await _agentIdService.getUserAgentId(userId);
      final kernelArtifact = await _buildKernelArtifact(
        agentId: agentId,
        onboardingData: onboardingData,
        personalityDimensions: personalityDimensions,
        recommendationKind: 'account',
      );

      final recommendations = <AccountRecommendation>[];

      // Find accounts by interests
      final interestAccounts = _findAccountsByInterests(
        onboardingData,
        personalityDimensions,
        kernelArtifact: kernelArtifact,
        maxRecommendations: maxRecommendations ~/ 2,
      );
      recommendations.addAll(interestAccounts);

      // Find accounts by location
      if (recommendations.length < maxRecommendations) {
        final locationAccounts = _findAccountsByLocation(
          onboardingData,
          personalityDimensions,
          kernelArtifact: kernelArtifact,
          maxRecommendations: maxRecommendations - recommendations.length,
        );
        recommendations.addAll(locationAccounts);
      }

      // Sort by compatibility score
      recommendations
          .sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

      developer.log(
        '✅ Found ${recommendations.length} account recommendations',
        name: _logName,
      );

      return recommendations.take(maxRecommendations).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting recommended accounts: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Calculate compatibility score between user and list/account
  ///
  /// [userDimensions] - User's personality dimensions
  /// [listDimensions] - List/account's personality dimensions
  ///
  /// Returns compatibility score (0.0-1.0)
  double calculateCompatibility({
    required Map<String, double> userDimensions,
    required Map<String, double> listDimensions,
  }) {
    if (userDimensions.isEmpty || listDimensions.isEmpty) {
      return 0.0;
    }

    // Calculate cosine similarity or simple average difference
    double totalSimilarity = 0.0;
    int matchingDimensions = 0;

    for (final dimension in userDimensions.keys) {
      if (listDimensions.containsKey(dimension)) {
        final userValue = userDimensions[dimension] ?? 0.0;
        final listValue = listDimensions[dimension] ?? 0.0;

        // Calculate similarity (1.0 - absolute difference)
        final similarity = 1.0 - (userValue - listValue).abs();
        totalSimilarity += similarity;
        matchingDimensions++;
      }
    }

    if (matchingDimensions == 0) {
      return 0.0;
    }

    return (totalSimilarity / matchingDimensions).clamp(0.0, 1.0);
  }

  /// Find lists by preferences
  List<ListRecommendation> _findListsByPreferences(
    Map<String, dynamic> onboardingData,
    Map<String, double> personalityDimensions, {
    _OnboardingKernelArtifact? kernelArtifact,
    GovernedDomainConsumerState? governedListState,
    int maxRecommendations = 5,
  }) {
    final preferences =
        Map<String, dynamic>.from(onboardingData['preferences'] as Map? ?? {});
    if (preferences.isEmpty || maxRecommendations <= 0) {
      return [];
    }

    final recommendations = <ListRecommendation>[];
    preferences.forEach((category, values) {
      if (recommendations.length >= maxRecommendations) {
        return;
      }
      final interests = (values as List?)
              ?.map((entry) => entry.toString())
              .where((entry) => entry.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (interests.isEmpty) {
        return;
      }
      final categoryScore = _dimensionAverage(
          personalityDimensions,
          const <String>[
            'curation_tendency',
            'exploration_eagerness',
          ],
          fallback: 0.62);
      final compatibilityScore =
          _applyGovernedListBoost(categoryScore, governedListState);
      recommendations.add(
        ListRecommendation(
          listId: 'list_${_slug(category)}',
          listName: '$category Local Circuit',
          curatorName: '${interests.first} Collective',
          description: 'A starter list for ${interests.take(2).join(' and ')}.',
          compatibilityScore: compatibilityScore,
          matchingReasons: <String>[
            'Built from your $category onboarding preferences',
            if (kernelArtifact?.localityContainedInWhere == true)
              'Locality stayed inside the where kernel during bootstrap',
            if (governedListState != null)
              'Governed list curation intelligence is active for this city',
          ],
          metadata: _metadataFor(
            base: <String, dynamic>{
              'source': 'onboarding_preferences',
              'category': category,
              'interests': interests,
              'governedListIntelligenceApplied': governedListState != null,
            },
            kernelArtifact: kernelArtifact,
          ),
        ),
      );
    });
    return recommendations.take(maxRecommendations).toList(growable: false);
  }

  /// Find lists by homebase
  List<ListRecommendation> _findListsByHomebase(
    Map<String, dynamic> onboardingData,
    Map<String, double> personalityDimensions, {
    _OnboardingKernelArtifact? kernelArtifact,
    GovernedDomainConsumerState? governedListState,
    int maxRecommendations = 5,
  }) {
    final homebase = onboardingData['homebase']?.toString().trim();
    if (homebase == null || homebase.isEmpty || maxRecommendations <= 0) {
      return [];
    }

    final compatibilityScore = _applyGovernedListBoost(
      _dimensionAverage(
        personalityDimensions,
        const <String>['location_adventurousness', 'community_orientation'],
        fallback: 0.66,
      ),
      governedListState,
    );

    return <ListRecommendation>[
      ListRecommendation(
        listId: 'list_homebase_${_slug(homebase)}',
        listName: '$homebase Starter Radius',
        curatorName: 'AVRAI Locality Bootstrap',
        description: 'Places and rituals anchored around your homebase.',
        compatibilityScore: compatibilityScore,
        matchingReasons: <String>[
          'Anchored to your onboarding homebase',
          if (kernelArtifact?.governanceSummary case final summary?) summary,
          if (governedListState != null)
            'Governed list curation intelligence is active for this city',
        ],
        metadata: _metadataFor(
          base: <String, dynamic>{
            'source': 'onboarding_homebase',
            'homebase': homebase,
            'governedListIntelligenceApplied': governedListState != null,
          },
          kernelArtifact: kernelArtifact,
        ),
      ),
    ];
  }

  /// Find lists by archetype
  List<ListRecommendation> _findListsByArchetype(
    Map<String, double> personalityDimensions, {
    _OnboardingKernelArtifact? kernelArtifact,
    GovernedDomainConsumerState? governedListState,
    int maxRecommendations = 5,
  }) {
    if (maxRecommendations <= 0 || personalityDimensions.isEmpty) {
      return [];
    }
    final archetype = _inferArchetype(personalityDimensions);
    final compatibilityScore = _applyGovernedListBoost(
      _dimensionAverage(
        personalityDimensions,
        personalityDimensions.keys,
        fallback: 0.58,
      ),
      governedListState,
    );
    return <ListRecommendation>[
      ListRecommendation(
        listId: 'list_archetype_${_slug(archetype)}',
        listName: '$archetype Weekly Trail',
        curatorName: '$archetype Guides',
        description: 'A starter trail tuned to your early personality signals.',
        compatibilityScore: compatibilityScore,
        matchingReasons: <String>[
          'Derived from your early personality dimensions',
          if (governedListState != null)
            'Governed list curation intelligence is active for this city',
        ],
        metadata: _metadataFor(
          base: <String, dynamic>{
            'source': 'onboarding_archetype',
            'archetype': archetype,
            'governedListIntelligenceApplied': governedListState != null,
          },
          kernelArtifact: kernelArtifact,
        ),
      ),
    ];
  }

  /// Find accounts by interests
  List<AccountRecommendation> _findAccountsByInterests(
    Map<String, dynamic> onboardingData,
    Map<String, double> personalityDimensions, {
    _OnboardingKernelArtifact? kernelArtifact,
    int maxRecommendations = 5,
  }) {
    final preferences =
        Map<String, dynamic>.from(onboardingData['preferences'] as Map? ?? {});
    if (preferences.isEmpty || maxRecommendations <= 0) {
      return [];
    }

    final recommendations = <AccountRecommendation>[];
    preferences.forEach((category, values) {
      if (recommendations.length >= maxRecommendations) {
        return;
      }
      final interests = (values as List?)
              ?.map((entry) => entry.toString())
              .where((entry) => entry.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (interests.isEmpty) {
        return;
      }
      recommendations.add(
        AccountRecommendation(
          accountId: 'account_${_slug(interests.first)}',
          accountName: '@${_slug(interests.first)}_daily',
          displayName: '${interests.first} Daily',
          description:
              'A recommended voice for ${interests.take(2).join(' and ')}.',
          compatibilityScore: _dimensionAverage(
            personalityDimensions,
            const <String>['community_orientation', 'curation_tendency'],
            fallback: 0.64,
          ),
          matchingReasons: <String>[
            'Matches your expressed onboarding interests',
          ],
          metadata: _metadataFor(
            base: <String, dynamic>{
              'source': 'onboarding_interests',
              'category': category,
              'interests': interests,
            },
            kernelArtifact: kernelArtifact,
          ),
        ),
      );
    });
    return recommendations.take(maxRecommendations).toList(growable: false);
  }

  /// Find accounts by location
  List<AccountRecommendation> _findAccountsByLocation(
    Map<String, dynamic> onboardingData,
    Map<String, double> personalityDimensions, {
    _OnboardingKernelArtifact? kernelArtifact,
    int maxRecommendations = 5,
  }) {
    final homebase = onboardingData['homebase']?.toString().trim();
    if (homebase == null || homebase.isEmpty || maxRecommendations <= 0) {
      return [];
    }

    return <AccountRecommendation>[
      AccountRecommendation(
        accountId: 'account_local_${_slug(homebase)}',
        accountName: '@${_slug(homebase)}_signal',
        displayName: '$homebase Signal',
        description: 'Local pulse and trusted threads near your homebase.',
        compatibilityScore: _dimensionAverage(
          personalityDimensions,
          const <String>['community_orientation', 'location_adventurousness'],
          fallback: 0.67,
        ),
        matchingReasons: <String>[
          'Anchored to your homebase onboarding signal',
          if (kernelArtifact?.localityContainedInWhere == true)
            'Spatial grounding stayed within the where kernel',
        ],
        metadata: _metadataFor(
          base: <String, dynamic>{
            'source': 'onboarding_location',
            'homebase': homebase,
          },
          kernelArtifact: kernelArtifact,
        ),
      ),
    ];
  }

  Future<_OnboardingKernelArtifact?> _buildKernelArtifact({
    required String agentId,
    required Map<String, dynamic> onboardingData,
    required Map<String, double> personalityDimensions,
    required String recommendationKind,
  }) async {
    final host = _headlessOsHost;
    if (host == null) {
      return null;
    }

    try {
      await host.start();
      final now = DateTime.now().toUtc();
      final envelope = KernelEventEnvelope(
        eventId:
            'onboarding_recommendation:$recommendationKind:$agentId:${now.microsecondsSinceEpoch}',
        agentId: agentId,
        userId: agentId,
        occurredAtUtc: now,
        sourceSystem: 'onboarding_recommendation_service',
        eventType: 'onboarding_recommendation_requested',
        actionType: 'recommend_$recommendationKind',
        entityId: onboardingData['homebase']?.toString() ?? agentId,
        entityType: recommendationKind,
        context: <String, dynamic>{
          'homebase': onboardingData['homebase'],
          'preferences_count':
              (onboardingData['preferences'] as Map?)?.length ?? 0,
        },
        predictionContext: <String, dynamic>{
          'recommendation_kind': recommendationKind,
          'dimension_count': personalityDimensions.length,
        },
        runtimeContext: const <String, dynamic>{
          'workflow_stage': 'onboarding',
          'execution_path': 'onboarding_recommendation_service',
        },
      );
      final runtimeBundle =
          await host.resolveRuntimeExecution(envelope: envelope);
      final whyRequest = KernelWhyRequest(
        bundle: runtimeBundle.withoutWhy(),
        goal: 'bootstrap_onboarding_recommendations',
        predictedOutcome: 'recommendation_candidates',
        predictedConfidence: 0.72,
        actualOutcome: 'generated',
        actualOutcomeScore: 1.0,
        coreSignals: <WhySignal>[
          WhySignal(
            label: 'preferences_present',
            weight:
                ((onboardingData['preferences'] as Map?)?.isNotEmpty ?? false)
                    ? 0.9
                    : 0.3,
            source: 'onboarding',
            durable: true,
          ),
          WhySignal(
            label: 'personality_dimensions',
            weight: personalityDimensions.isEmpty ? 0.2 : 0.75,
            source: 'onboarding',
            durable: true,
          ),
        ],
      );
      final modelTruth = await host.buildModelTruth(
          envelope: envelope, whyRequest: whyRequest);
      final governance = await host.inspectGovernance(
          envelope: envelope, whyRequest: whyRequest);
      return _OnboardingKernelArtifact(
        eventId: envelope.eventId,
        localityContainedInWhere: modelTruth.localityContainedInWhere,
        governanceSummary: governance.projections.isEmpty
            ? null
            : governance.projections.first.summary,
        governanceDomains:
            governance.projections.map((entry) => entry.domain.name).toList(),
        modelTruthReady: true,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Headless onboarding recommendation artifact failed: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Map<String, dynamic> _metadataFor({
    required Map<String, dynamic> base,
    required _OnboardingKernelArtifact? kernelArtifact,
  }) {
    return <String, dynamic>{
      ...base,
      if (kernelArtifact != null) ...<String, dynamic>{
        'kernelEventId': kernelArtifact.eventId,
        'modelTruthReady': kernelArtifact.modelTruthReady,
        'localityContainedInWhere': kernelArtifact.localityContainedInWhere,
        if (kernelArtifact.governanceSummary != null)
          'governanceSummary': kernelArtifact.governanceSummary,
        'governanceDomains': kernelArtifact.governanceDomains,
      },
    };
  }

  double _dimensionAverage(
    Map<String, double> dimensions,
    Iterable<String> keys, {
    required double fallback,
  }) {
    final values = keys
        .map((key) => dimensions[key])
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) {
      return fallback;
    }
    final sum = values.fold<double>(0.0, (total, value) => total + value);
    return (sum / values.length).clamp(0.0, 1.0);
  }

  String _inferArchetype(Map<String, double> dimensions) {
    final exploration = dimensions['exploration_eagerness'] ?? 0.5;
    final curation = dimensions['curation_tendency'] ?? 0.5;
    final community = dimensions['community_orientation'] ?? 0.5;
    if (exploration >= 0.7) {
      return 'Explorer';
    }
    if (community >= 0.7) {
      return 'Connector';
    }
    if (curation >= 0.65) {
      return 'Curator';
    }
    return 'Waypoint';
  }

  String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  double _applyGovernedListBoost(
    double baseScore,
    GovernedDomainConsumerState? governedListState,
  ) {
    if (governedListState == null) {
      return baseScore;
    }
    final requestWeight =
        (governedListState.requestCount.clamp(0, 4) / 4) * 0.04;
    final confidenceWeight =
        (governedListState.averageConfidence ?? 0.0).clamp(0.0, 1.0) * 0.04;
    final freshnessWeight = governedListState.temporalFreshnessWeight();
    return (baseScore + ((requestWeight + confidenceWeight) * freshnessWeight))
        .clamp(0.0, 1.0);
  }
}

class _OnboardingKernelArtifact {
  const _OnboardingKernelArtifact({
    required this.eventId,
    required this.modelTruthReady,
    required this.localityContainedInWhere,
    required this.governanceDomains,
    this.governanceSummary,
  });

  final String eventId;
  final bool modelTruthReady;
  final bool localityContainedInWhere;
  final String? governanceSummary;
  final List<String> governanceDomains;
}

/// List Recommendation
///
/// Represents a recommended list to follow
class ListRecommendation {
  final String listId;
  final String listName;
  final String curatorName;
  final String description;
  final double compatibilityScore; // 0.0-1.0
  final List<String> matchingReasons; // Why this list matches
  final Map<String, dynamic> metadata;

  ListRecommendation({
    required this.listId,
    required this.listName,
    required this.curatorName,
    required this.description,
    required this.compatibilityScore,
    required this.matchingReasons,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'listId': listId,
      'listName': listName,
      'curatorName': curatorName,
      'description': description,
      'compatibilityScore': compatibilityScore,
      'matchingReasons': matchingReasons,
      'metadata': metadata,
    };
  }
}

/// Account Recommendation
///
/// Represents a recommended account to follow
class AccountRecommendation {
  final String accountId;
  final String accountName;
  final String displayName;
  final String description;
  final double compatibilityScore; // 0.0-1.0
  final List<String> matchingReasons; // Why this account matches
  final Map<String, dynamic> metadata;

  AccountRecommendation({
    required this.accountId,
    required this.accountName,
    required this.displayName,
    required this.description,
    required this.compatibilityScore,
    required this.matchingReasons,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'displayName': displayName,
      'description': description,
      'compatibilityScore': compatibilityScore,
      'matchingReasons': matchingReasons,
      'metadata': metadata,
    };
  }
}
