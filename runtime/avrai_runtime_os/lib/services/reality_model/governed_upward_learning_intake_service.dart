import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/community/community_validation.dart';
import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_core/models/reality/artifact_lifecycle.dart';
import 'package:avrai_core/models/reality/governed_learning_envelope.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/events/event_feedback.dart'
    hide PartnerRating;
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/expertise/partner_rating.dart';
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/kernel_graph/intake_kernel_graph_primitives.dart';
import 'package:avrai_runtime_os/services/kernel_graph/kernel_graph_run_ledger.dart';
import 'package:avrai_runtime_os/services/kernel_graph/kernel_graph_runner.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_signal_policy_service.dart';

class GovernedUpwardLearningIntakeResult {
  const GovernedUpwardLearningIntakeResult({
    required this.sourceId,
    required this.reviewItemId,
    required this.jobId,
    required this.temporalLineage,
    required this.convictionTier,
    required this.learningPathway,
    required this.envelope,
    this.kernelGraphSpecId,
    this.kernelGraphRunId,
    this.kernelGraphStatus,
    this.kernelGraphAdminDigest,
  });

  final String sourceId;
  final String reviewItemId;
  final String jobId;
  final Map<String, dynamic> temporalLineage;
  final String convictionTier;
  final String learningPathway;
  final GovernedLearningEnvelope envelope;
  final String? kernelGraphSpecId;
  final String? kernelGraphRunId;
  final KernelGraphRunStatus? kernelGraphStatus;
  final KernelGraphAdminDigest? kernelGraphAdminDigest;
}

class GovernedUpwardLearningIntakeService {
  GovernedUpwardLearningIntakeService({
    required UniversalIntakeRepository intakeRepository,
    required AtomicClockService atomicClockService,
    KernelGraphRunner? kernelGraphRunner,
    KernelGraphRunLedger? kernelGraphRunLedger,
    UpwardAirGapService? upwardAirGapService,
    UserGovernedLearningSignalPolicyService? signalPolicyService,
  })  : _atomicClockService = atomicClockService,
        _intakeRepository = intakeRepository,
        _upwardAirGapService =
            upwardAirGapService ?? const UpwardAirGapService(),
        _signalPolicyService = signalPolicyService,
        _kernelGraphRunner = kernelGraphRunner ??
            KernelGraphRunner(
              primitiveRegistry: IntakeKernelGraphPrimitives.buildRegistry(
                intakeRepository: intakeRepository,
              ),
              runLedger: kernelGraphRunLedger,
            );

  static const String upwardQueueKind = 'queued_for_upward_learning_review';
  static const String learningDirection =
      'upward_personal_agent_to_reality_model';
  static const String learningPathway =
      'governed_upward_reality_model_learning';
  static const String upwardKernelGraphVersion = '0.1';
  static const String upwardAirGapArtifactVersion = '0.1';
  static const String requiredAirGapNextStage =
      'governed_upward_learning_review';
  static const Set<String> callerIssuedAirGapSourceProviders = <String>{
    'personal_agent_human_intake',
    'explicit_correction_intake',
    'explicit_correction_follow_up_response_intake',
    'ai2ai_chat_intake',
    'onboarding_intake',
    'onboarding_follow_up_response_intake',
    'recommendation_feedback_intake',
    'recommendation_feedback_follow_up_response_intake',
    'event_feedback_follow_up_response_intake',
    'visit_locality_follow_up_response_intake',
    'community_follow_up_response_intake',
    'business_operator_follow_up_response_intake',
    'reservation_operational_follow_up_response_intake',
    'saved_discovery_curation_intake',
    'saved_discovery_follow_up_response_intake',
    'business_operator_input_intake',
    'community_coordination_intake',
    'community_validation_intake',
    'reservation_sharing_intake',
    'reservation_calendar_sync_intake',
    'reservation_recurrence_intake',
    'visit_observation_intake',
    'locality_observation_intake',
    'event_feedback_intake',
    'partner_rating_intake',
    'event_outcome_intake',
    'supervisor_bounded_observation_intake',
    'assistant_bounded_observation_intake',
    'kernel_offline_evidence_receipt_intake',
  };

  final AtomicClockService _atomicClockService;
  final UniversalIntakeRepository _intakeRepository;
  final UpwardAirGapService _upwardAirGapService;
  final UserGovernedLearningSignalPolicyService? _signalPolicyService;
  final KernelGraphRunner _kernelGraphRunner;

  Future<GovernedUpwardLearningIntakeResult> stagePersonalAgentHumanIntake({
    required String ownerUserId,
    required String actorAgentId,
    required String chatId,
    required String messageId,
    required DateTime occurredAtUtc,
    required Map<String, dynamic> boundaryMetadata,
    required UpwardAirGapArtifact airGapArtifact,
    String? cityCode,
    String? localityCode,
  }) {
    final upwardDomainHints = _extractUpwardDomainHints(
      boundaryMetadata,
      cityCode: cityCode,
      localityCode: localityCode,
    );
    final upwardReferencedEntities =
        _extractReferencedEntities(boundaryMetadata);
    final isExplicitCorrection = _isExplicitCorrection(boundaryMetadata);
    final upwardQuestions = isExplicitCorrection
        ? _extractCorrectionQuestions(boundaryMetadata)
        : _extractQuestions(boundaryMetadata);
    final upwardPreferenceSignals = _extractPreferenceSignals(boundaryMetadata);
    final upwardSignalTags = isExplicitCorrection
        ? _extractCorrectionSignalTags(
            boundaryMetadata,
            source: 'human',
            domainHints: upwardDomainHints,
          )
        : _extractSignalTags(
            boundaryMetadata,
            domainHints: upwardDomainHints,
          );
    final correctionBinding = _buildAirGapRequestBinding(<String, dynamic>{
      'correctionText': boundaryMetadata['sanitized_summary']?.toString() ??
          boundaryMetadata['summary']?.toString(),
      'targetEnvelopeId':
          boundaryMetadata['correction_target_envelope_id']?.toString(),
      'targetSourceId':
          boundaryMetadata['correction_target_source_id']?.toString(),
    });
    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: isExplicitCorrection
          ? 'explicit_correction_intake'
          : 'personal_agent_human_intake',
      sourceLabel: isExplicitCorrection
          ? 'Explicit correction upward learning'
          : 'Personal-agent human upward learning',
      title: isExplicitCorrection
          ? 'Upward learning review: explicit correction'
          : 'Upward learning review: personal-agent human intake',
      summary: isExplicitCorrection
          ? _buildCorrectionSummary(
              boundaryMetadata,
              fallback:
                  'A governed explicit correction is ready for upward learning review.',
            )
          : _safeSummary(boundaryMetadata) ??
              'A governed personal-agent human intake item is ready for upward learning review.',
      stableRef: messageId,
      occurredAtUtc: occurredAtUtc,
      cityCode: cityCode,
      localityCode: localityCode,
      convictionTier: isExplicitCorrection
          ? _correctionConvictionTier(source: 'human')
          : 'personal_agent_human_observation',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: isExplicitCorrection
          ? correctionBinding
          : _buildAirGapRequestBinding(<String, dynamic>{
              'actorAgentId': actorAgentId,
              'chatId': chatId,
              'messageId': messageId,
              'boundaryMetadata': boundaryMetadata,
            }),
      requiredAirGapBindingKeys: isExplicitCorrection
          ? correctionBinding.keys.toList(growable: false)
          : const <String>['chatId', 'messageId'],
      payload: <String, dynamic>{
        'sourceKind': isExplicitCorrection
            ? 'explicit_correction_intake'
            : 'personal_agent_human_intake',
        'actorAgentId': actorAgentId,
        'chatId': chatId,
        'messageId': messageId,
        'surface': 'chat',
        'channel': 'personality_agent',
        'boundary': boundaryMetadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
        if (isExplicitCorrection) 'correctionIntent': true,
        if (isExplicitCorrection) 'correctionSource': 'human',
        if (_safePseudonymousActorRef(boundaryMetadata) case final actorRef?)
          'pseudonymousActorRef': actorRef,
      },
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageAi2AiIntake({
    required String ownerUserId,
    required String localAgentId,
    required String senderUserId,
    required String remoteRef,
    required String messageId,
    required String scope,
    required String direction,
    required DateTime occurredAtUtc,
    required Map<String, dynamic> boundaryMetadata,
    required UpwardAirGapArtifact airGapArtifact,
  }) {
    final scopeLabel = scope == 'community' ? 'community' : 'direct';
    final upwardDomainHints = _extractUpwardDomainHints(
      boundaryMetadata,
      chatScope: scope,
    );
    final upwardReferencedEntities =
        _extractReferencedEntities(boundaryMetadata);
    final isExplicitCorrection = _isExplicitCorrection(boundaryMetadata);
    final upwardQuestions = isExplicitCorrection
        ? _extractCorrectionQuestions(boundaryMetadata)
        : _extractQuestions(boundaryMetadata);
    final upwardPreferenceSignals = _extractPreferenceSignals(boundaryMetadata);
    final upwardSignalTags = isExplicitCorrection
        ? _extractCorrectionSignalTags(
            boundaryMetadata,
            source: 'ai2ai',
            chatScope: scope,
            domainHints: upwardDomainHints,
          )
        : _extractSignalTags(
            boundaryMetadata,
            chatScope: scope,
            domainHints: upwardDomainHints,
          );
    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: isExplicitCorrection
          ? 'explicit_correction_intake'
          : 'ai2ai_chat_intake',
      sourceLabel: isExplicitCorrection
          ? 'AI2AI explicit correction upward learning'
          : 'AI2AI upward learning',
      title: isExplicitCorrection
          ? 'Upward learning review: AI2AI $scopeLabel correction'
          : 'Upward learning review: AI2AI $scopeLabel intake',
      summary: isExplicitCorrection
          ? _buildCorrectionSummary(
              boundaryMetadata,
              fallback:
                  'A governed AI2AI correction is ready for upward learning review.',
            )
          : _safeSummary(boundaryMetadata) ??
              'A governed AI2AI intake item is ready for upward learning review.',
      stableRef: '${scope}_$messageId',
      occurredAtUtc: occurredAtUtc,
      convictionTier: isExplicitCorrection
          ? _correctionConvictionTier(source: 'ai2ai')
          : 'ai2ai_peer_signal',
      hierarchyPath: const <String>[
        'ai2ai',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'localAgentId': localAgentId,
        'senderUserId': senderUserId,
        'remoteRef': remoteRef,
        'messageId': messageId,
        'scope': scope,
        'direction': direction,
        'learningMetadata': boundaryMetadata,
      }),
      requiredAirGapBindingKeys: const <String>[
        'remoteRef',
        'messageId',
        'scope',
        'direction',
      ],
      payload: <String, dynamic>{
        'sourceKind': isExplicitCorrection
            ? 'explicit_correction_intake'
            : 'ai2ai_chat_intake',
        'localAgentId': localAgentId,
        'senderUserId': senderUserId,
        'remoteRef': remoteRef,
        'messageId': messageId,
        'chatScope': scope,
        'flowDirection': direction,
        'surface': 'chat',
        'channel': scope == 'community' ? 'community_chat' : 'friend_chat',
        'boundary': boundaryMetadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
        if (isExplicitCorrection) 'correctionIntent': true,
        if (isExplicitCorrection) 'correctionSource': 'ai2ai',
        if (_safePseudonymousActorRef(boundaryMetadata) case final actorRef?)
          'pseudonymousActorRef': actorRef,
      },
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageOnboardingIntake({
    required String ownerUserId,
    required String agentId,
    required OnboardingData onboardingData,
    required UpwardAirGapArtifact airGapArtifact,
  }) {
    final upwardDomainHints = _extractOnboardingDomainHints(onboardingData);
    final upwardReferencedEntities =
        _extractOnboardingReferencedEntities(onboardingData);
    final upwardQuestions = _extractOnboardingQuestions(onboardingData);
    final upwardPreferenceSignals =
        _extractOnboardingPreferenceSignals(onboardingData);
    final upwardSignalTags = _extractOnboardingSignalTags(
      onboardingData,
      domainHints: upwardDomainHints,
    );
    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'onboarding_intake',
      sourceLabel: 'Onboarding upward learning',
      title: 'Upward learning review: onboarding intake',
      summary: _buildOnboardingSummary(onboardingData),
      stableRef: onboardingData.completedAt
          .toUtc()
          .toIso8601String()
          .replaceAll(':', '_'),
      occurredAtUtc: onboardingData.completedAt.toUtc(),
      convictionTier: 'onboarding_declared_preference',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'agentId': agentId,
        'homebase': onboardingData.homebase,
        'favoritePlaces': onboardingData.favoritePlaces,
        'baselineLists': onboardingData.baselineLists,
        'preferenceCategories': onboardingData.preferences.keys.toList()
          ..sort(),
        'questionnaireVersion': onboardingData.questionnaireVersion,
        'betaConsentAccepted': onboardingData.betaConsentAccepted,
      }),
      requiredAirGapBindingKeys: const <String>[
        'agentId',
        'questionnaireVersion',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'onboarding_intake',
        'actorAgentId': agentId,
        'surface': 'onboarding',
        'channel': 'onboarding_flow',
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
        'onboarding': <String, dynamic>{
          'homebase': onboardingData.homebase,
          'favoritePlaces': onboardingData.favoritePlaces,
          'preferenceCategories': onboardingData.preferences.keys.toList()
            ..sort(),
          'baselineLists': onboardingData.baselineLists,
          'respectedFriendsCount': onboardingData.respectedFriends.length,
          'socialPlatformsConnected': onboardingData
              .socialMediaConnected.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList()
            ..sort(),
          'dimensionValues': onboardingData.dimensionValues,
          'dimensionConfidence': onboardingData.dimensionConfidence,
          'questionnaireVersion': onboardingData.questionnaireVersion,
          'betaConsentAccepted': onboardingData.betaConsentAccepted,
          'permissionStates': onboardingData.permissionStates,
        },
      },
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageRecommendationFeedbackIntake({
    required String ownerUserId,
    required RecommendationFeedbackAction action,
    required DiscoveryEntityReference entity,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required UpwardAirGapArtifact airGapArtifact,
    RecommendationAttribution? attribution,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final upwardDomainHints = _extractRecommendationFeedbackDomainHints(
      entity: entity,
      sourceSurface: sourceSurface,
      attribution: attribution,
      metadata: metadata,
    );
    final upwardReferencedEntities = <String>[
      entity.title,
      if (entity.localityLabel?.trim().isNotEmpty ?? false)
        entity.localityLabel!.trim(),
    ]..sort();
    final upwardQuestions = <String>[
      if (action == RecommendationFeedbackAction.whyDidYouShowThis)
        'Why was this recommendation shown in this context?',
      if (action == RecommendationFeedbackAction.lessLikeThis)
        'What made this recommendation feel misaligned?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'recommendation_feedback_action',
        'value': action.name,
        'confidence': 0.86,
      },
      if (attribution != null)
        <String, dynamic>{
          'kind': 'recommendation_feedback_source',
          'value': attribution.recommendationSource,
          'confidence': attribution.confidence,
        },
    ];
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:recommendation_feedback',
      'action:${action.name}',
      'entity_type:${entity.type.name}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'recommendation_feedback_intake',
      sourceLabel: 'Recommendation feedback upward learning',
      title: 'Upward learning review: recommendation feedback',
      summary: _buildRecommendationFeedbackSummary(
        action: action,
        entity: entity,
        sourceSurface: sourceSurface,
        attribution: attribution,
      ),
      stableRef:
          '${action.name}_${entity.type.name}_${entity.id}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: _recommendationFeedbackConvictionTier(action),
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'action': action.name,
        'entity': entity.toJson(),
        'sourceSurface': sourceSurface,
        'attribution': attribution?.toJson(),
        'metadata': metadata,
      }),
      requiredAirGapBindingKeys: const <String>[
        'action',
        'entity',
        'sourceSurface',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'recommendation_feedback_intake',
        'surface': 'recommendation_feedback',
        'channel': sourceSurface,
        'feedbackAction': action.name,
        'entity': entity.toJson(),
        'attribution': attribution?.toJson(),
        'feedbackMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      localityCode: entity.localityLabel?.trim(),
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageOnboardingFollowUpResponseIntake({
    required String ownerUserId,
    required String agentId,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String promptQuestion,
    required String promptRationale,
    required String responseText,
    required String completionMode,
    required UpwardAirGapArtifact airGapArtifact,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final boundedContext = Map<String, dynamic>.from(
      metadata['boundedContext'] as Map? ?? const <String, dynamic>{},
    );
    final metadataDomains = _extractStringList(metadata['domains']);
    final homebase = metadata['homebase']?.toString().trim();
    final questionnaireVersion =
        metadata['questionnaireVersion']?.toString().trim();
    final upwardDomainHints = <String>{
      'identity',
      'preference',
      ...metadataDomains,
      if (homebase?.isNotEmpty ?? false) ...<String>['locality', 'place'],
    }.toList()
      ..sort();
    final upwardReferencedEntities = <String>{
      if (homebase?.isNotEmpty ?? false) homebase!,
      if (questionnaireVersion?.isNotEmpty ?? false) questionnaireVersion!,
      ..._extractStringList(boundedContext['topDimensions']),
      ..._extractStringList(boundedContext['preferenceCategories']),
    }.where((entry) => entry.isNotEmpty).toList()
      ..sort();
    final upwardQuestions = <String>[
      promptQuestion,
      'What from this bounded onboarding follow-up should stay durable, and what should remain provisional until more lived behavior arrives?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'onboarding_follow_up_completion_mode',
        'value': completionMode,
        'confidence': 0.95,
      },
      if ((boundedContext['why'] as String?)?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'onboarding_follow_up_why',
          'value': (boundedContext['why'] as String).trim(),
          'confidence': 0.76,
        },
      if (homebase?.isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'onboarding_follow_up_homebase',
          'value': homebase!,
          'confidence': 0.84,
        },
    ];
    final metadataSignalTags = _extractStringList(metadata['signalTags']);
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:onboarding_follow_up_response',
      'completion_mode:$completionMode',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
      ...metadataSignalTags,
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'onboarding_follow_up_response_intake',
      sourceLabel: 'Onboarding follow-up response',
      title: 'Upward learning review: onboarding follow-up response',
      summary: _buildOnboardingFollowUpResponseSummary(
        homebase: homebase,
        responseText: responseText,
      ),
      stableRef:
          'onboarding_follow_up_${agentId}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: 'bounded_onboarding_follow_up_signal',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'agentId': agentId,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'sourceSurface': sourceSurface,
        'completionMode': completionMode,
        'questionnaireVersion': questionnaireVersion,
        'homebase': homebase,
        'boundedContext': metadata['boundedContext'],
        'signalTags': metadata['signalTags'],
      }),
      requiredAirGapBindingKeys: const <String>[
        'agentId',
        'promptQuestion',
        'responseText',
        'sourceSurface',
        'completionMode',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'onboarding_follow_up_response_intake',
        'surface': 'onboarding_follow_up',
        'channel': sourceSurface,
        'agentId': agentId,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'completionMode': completionMode,
        'followUpMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      localityCode: homebase,
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageRecommendationFeedbackFollowUpResponseIntake({
    required String ownerUserId,
    required RecommendationFeedbackAction action,
    required DiscoveryEntityReference entity,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String promptQuestion,
    required String promptRationale,
    required String responseText,
    required String completionMode,
    required UpwardAirGapArtifact airGapArtifact,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final upwardDomainHints = _extractRecommendationFeedbackDomainHints(
      entity: entity,
      sourceSurface: sourceSurface,
      attribution: null,
      metadata: metadata,
    );
    final boundedContext = Map<String, dynamic>.from(
      metadata['boundedContext'] as Map? ?? const <String, dynamic>{},
    );
    final upwardReferencedEntities = <String>{
      entity.title,
      if (entity.localityLabel?.trim().isNotEmpty ?? false)
        entity.localityLabel!.trim(),
      if ((boundedContext['what'] as String?)?.trim().isNotEmpty ?? false)
        (boundedContext['what'] as String).trim(),
    }.toList()
      ..sort();
    final upwardQuestions = <String>[
      promptQuestion,
      'What does this bounded follow-up answer suggest about future recommendation alignment?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'recommendation_feedback_follow_up_action',
        'value': action.name,
        'confidence': 0.88,
      },
      <String, dynamic>{
        'kind': 'recommendation_feedback_follow_up_completion_mode',
        'value': completionMode,
        'confidence': 0.95,
      },
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'recommendation_feedback_follow_up_where',
          'value': (boundedContext['where'] as String).trim(),
          'confidence': 0.72,
        },
    ];
    final metadataSignalTags = _extractStringList(metadata['signalTags']);
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:recommendation_feedback_follow_up_response',
      'action:${action.name}',
      'entity_type:${entity.type.name}',
      'completion_mode:$completionMode',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
      ...metadataSignalTags,
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'recommendation_feedback_follow_up_response_intake',
      sourceLabel: 'Recommendation feedback follow-up response',
      title:
          'Upward learning review: recommendation feedback follow-up response',
      summary: _buildRecommendationFeedbackFollowUpResponseSummary(
        action: action,
        entity: entity,
        sourceSurface: sourceSurface,
        responseText: responseText,
      ),
      stableRef:
          'follow_up_${action.name}_${entity.type.name}_${entity.id}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: _recommendationFeedbackFollowUpConvictionTier(action),
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'entity': entity.toJson(),
        'feedbackAction': action.name,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'sourceSurface': sourceSurface,
        'completionMode': completionMode,
        'sourceEventRef': metadata['sourceEventRef'],
        'boundedContext': metadata['boundedContext'],
        'signalTags': metadata['signalTags'],
      }),
      requiredAirGapBindingKeys: const <String>[
        'entity',
        'feedbackAction',
        'promptQuestion',
        'responseText',
        'sourceSurface',
        'completionMode',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'recommendation_feedback_follow_up_response_intake',
        'surface': 'recommendation_feedback_follow_up',
        'channel': sourceSurface,
        'feedbackAction': action.name,
        'entity': entity.toJson(),
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'completionMode': completionMode,
        'followUpMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      localityCode: entity.localityLabel?.trim(),
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageSavedDiscoveryCurationIntake({
    required String ownerUserId,
    required DiscoveryEntityReference entity,
    required DateTime occurredAtUtc,
    required UpwardAirGapArtifact airGapArtifact,
    required String sourceSurface,
    required String action,
    RecommendationAttribution? attribution,
  }) {
    final upwardDomainHints = _extractSavedDiscoveryDomainHints(
      entity: entity,
      sourceSurface: sourceSurface,
      attribution: attribution,
    );
    final upwardReferencedEntities = <String>[
      entity.title,
      if (entity.localityLabel?.trim().isNotEmpty ?? false)
        entity.localityLabel!.trim(),
    ]..sort();
    final upwardQuestions = <String>[
      if (action == 'save')
        'What made this saved discovery item strong enough to keep?',
      if (action == 'unsave')
        'What changed so this discovery item should no longer stay saved?',
      'Should this curation signal adjust future place, list, or venue guidance?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'saved_discovery_action',
        'value': action,
        'confidence': 0.84,
      },
      if (attribution != null)
        <String, dynamic>{
          'kind': 'recommendation_source',
          'value': attribution.recommendationSource,
          'confidence': attribution.confidence,
        },
    ];
    final upwardSignalTags = <String>{
      'action:$action',
      'surface:$sourceSurface',
      'entity_type:${entity.type.name}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();
    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'saved_discovery_curation_intake',
      sourceLabel: 'Saved discovery curation upward learning',
      title: 'Upward learning review: saved discovery curation',
      summary: _buildSavedDiscoverySummary(
        entity: entity,
        action: action,
        sourceSurface: sourceSurface,
      ),
      stableRef:
          '${entity.type.name}_${entity.id}_${action.toString()}_${occurredAtUtc.toUtc().microsecondsSinceEpoch}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: action == 'save'
          ? 'saved_discovery_positive_curation_signal'
          : 'saved_discovery_negative_curation_signal',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'saved_discovery_curation_intake',
        'surface': sourceSurface,
        'channel': 'saved_discovery',
        'action': action,
        'entity': entity.toJson(),
        if (attribution != null) 'attribution': attribution.toJson(),
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'saved_discovery_curation_intake',
        'action': action,
        'sourceSurface': sourceSurface,
        'entityId': entity.id,
        'entityType': entity.type.name,
        'localityLabel': entity.localityLabel?.trim(),
        'recommendationSource': attribution?.recommendationSource,
      }),
      requiredAirGapBindingKeys: const <String>[
        'action',
        'sourceSurface',
        'entityId',
        'entityType',
      ],
      localityCode: entity.localityLabel,
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageExplicitCorrectionFollowUpResponseIntake({
    required String ownerUserId,
    required String targetEnvelopeId,
    required String targetSourceId,
    required String targetSummary,
    required String correctionText,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String promptQuestion,
    required String promptRationale,
    required String responseText,
    required String completionMode,
    required UpwardAirGapArtifact airGapArtifact,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final boundedContext = Map<String, dynamic>.from(
      metadata['boundedContext'] as Map? ?? const <String, dynamic>{},
    );
    final metadataDomains = _extractStringList(metadata['domains']);
    final upwardDomainHints = <String>{
      ...metadataDomains,
      ..._extractStringList(boundedContext['domainHints']),
    }.toList()
      ..sort();
    final upwardReferencedEntities = <String>{
      targetSummary.trim(),
      correctionText.trim(),
      ..._extractStringList(metadata['referencedEntities']),
      ..._extractStringList(boundedContext['referencedEntities']),
    }.where((entry) => entry.trim().isNotEmpty).toList()
      ..sort();
    final upwardQuestions = <String>[
      promptQuestion,
      'Should this correction reshape a durable preference, a situational boundary, or just a single prior recommendation?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'explicit_correction_follow_up_completion_mode',
        'value': completionMode,
        'confidence': 0.95,
      },
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'explicit_correction_follow_up_where',
          'value': (boundedContext['where'] as String).trim(),
          'confidence': 0.72,
        },
    ];
    final metadataSignalTags = _extractStringList(metadata['signalTags']);
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:explicit_correction_follow_up_response',
      'completion_mode:$completionMode',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
      ...metadataSignalTags,
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'explicit_correction_follow_up_response_intake',
      sourceLabel: 'Explicit correction follow-up response',
      title: 'Upward learning review: explicit correction follow-up response',
      summary: _buildExplicitCorrectionFollowUpResponseSummary(
        targetSummary: targetSummary,
        sourceSurface: sourceSurface,
        responseText: responseText,
      ),
      stableRef:
          'correction_follow_up_${targetEnvelopeId}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: 'explicit_correction_follow_up_signal',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'targetEnvelopeId': targetEnvelopeId,
        'targetSourceId': targetSourceId,
        'targetSummary': targetSummary,
        'correctionText': correctionText,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'sourceSurface': sourceSurface,
        'completionMode': completionMode,
        'boundedContext': metadata['boundedContext'],
        'signalTags': metadata['signalTags'],
      }),
      requiredAirGapBindingKeys: const <String>[
        'targetEnvelopeId',
        'targetSourceId',
        'targetSummary',
        'correctionText',
        'promptQuestion',
        'responseText',
        'sourceSurface',
        'completionMode',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'explicit_correction_follow_up_response_intake',
        'surface': 'explicit_correction_follow_up',
        'channel': sourceSurface,
        'targetEnvelopeId': targetEnvelopeId,
        'targetSourceId': targetSourceId,
        'targetSummary': targetSummary,
        'correctionText': correctionText,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'completionMode': completionMode,
        'followUpMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      localityCode:
          boundedContext['where']?.toString().trim().isNotEmpty == true
              ? boundedContext['where'].toString().trim()
              : null,
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageSavedDiscoveryFollowUpResponseIntake({
    required String ownerUserId,
    required DiscoveryEntityReference entity,
    required String action,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String promptQuestion,
    required String promptRationale,
    required String responseText,
    required String completionMode,
    required UpwardAirGapArtifact airGapArtifact,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final boundedContext = Map<String, dynamic>.from(
      metadata['boundedContext'] as Map? ?? const <String, dynamic>{},
    );
    final metadataDomains = _extractStringList(metadata['domains']);
    final upwardDomainHints = <String>{
      ..._extractSavedDiscoveryDomainHints(
        entity: entity,
        sourceSurface: sourceSurface,
      ),
      ...metadataDomains,
    }.toList()
      ..sort();
    final upwardReferencedEntities = <String>{
      entity.title,
      if (entity.localityLabel?.trim().isNotEmpty ?? false)
        entity.localityLabel!.trim(),
      if ((boundedContext['what'] as String?)?.trim().isNotEmpty ?? false)
        (boundedContext['what'] as String).trim(),
    }.toList()
      ..sort();
    final upwardQuestions = <String>[
      promptQuestion,
      'What should this bounded saved-discovery follow-up answer change about future curation or recommendation alignment?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'saved_discovery_follow_up_action',
        'value': action,
        'confidence': 0.88,
      },
      <String, dynamic>{
        'kind': 'saved_discovery_follow_up_completion_mode',
        'value': completionMode,
        'confidence': 0.95,
      },
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'saved_discovery_follow_up_where',
          'value': (boundedContext['where'] as String).trim(),
          'confidence': 0.72,
        },
    ];
    final metadataSignalTags = _extractStringList(metadata['signalTags']);
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:saved_discovery_follow_up_response',
      'action:$action',
      'entity_type:${entity.type.name}',
      'completion_mode:$completionMode',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
      ...metadataSignalTags,
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'saved_discovery_follow_up_response_intake',
      sourceLabel: 'Saved discovery follow-up response',
      title: 'Upward learning review: saved discovery follow-up response',
      summary: _buildSavedDiscoveryFollowUpResponseSummary(
        entity: entity,
        action: action,
        sourceSurface: sourceSurface,
        responseText: responseText,
      ),
      stableRef:
          'saved_follow_up_${action}_${entity.type.name}_${entity.id}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: action == 'unsave'
          ? 'saved_discovery_follow_up_correction_signal'
          : 'saved_discovery_follow_up_preference_signal',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      payload: <String, dynamic>{
        'sourceKind': 'saved_discovery_follow_up_response_intake',
        'surface': 'saved_discovery_follow_up',
        'channel': sourceSurface,
        'action': action,
        'entity': entity.toJson(),
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'completionMode': completionMode,
        'followUpMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      localityCode: entity.localityLabel?.trim(),
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageVisitLocalityFollowUpResponseIntake({
    required String ownerUserId,
    required String observationKind,
    required String targetLabel,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String promptQuestion,
    required String promptRationale,
    required String responseText,
    required String completionMode,
    required UpwardAirGapArtifact airGapArtifact,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final boundedContext = Map<String, dynamic>.from(
      metadata['boundedContext'] as Map? ?? const <String, dynamic>{},
    );
    final metadataDomains = _extractStringList(metadata['domains']);
    final upwardDomainHints = <String>{
      if (observationKind == 'visit') ...<String>['locality', 'place', 'venue'],
      if (observationKind == 'locality') ...<String>[
        'community',
        'locality',
        'place',
        'venue'
      ],
      ...metadataDomains,
    }.toList()
      ..sort();
    final upwardReferencedEntities = <String>{
      targetLabel.trim(),
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ?? false)
        (boundedContext['where'] as String).trim(),
    }.where((entry) => entry.isNotEmpty).toList()
      ..sort();
    final upwardQuestions = <String>[
      promptQuestion,
      observationKind == 'visit'
          ? 'What should this bounded visit follow-up answer change about future place or venue guidance?'
          : 'What should this bounded locality follow-up answer change about locality, community, or mobility guidance?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'visit_locality_follow_up_observation_kind',
        'value': observationKind,
        'confidence': 0.9,
      },
      <String, dynamic>{
        'kind': 'visit_locality_follow_up_completion_mode',
        'value': completionMode,
        'confidence': 0.95,
      },
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'visit_locality_follow_up_where',
          'value': (boundedContext['where'] as String).trim(),
          'confidence': 0.72,
        },
    ];
    final metadataSignalTags = _extractStringList(metadata['signalTags']);
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:visit_locality_follow_up_response',
      'observation_kind:$observationKind',
      'completion_mode:$completionMode',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
      ...metadataSignalTags,
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'visit_locality_follow_up_response_intake',
      sourceLabel: 'Visit/locality follow-up response',
      title: 'Upward learning review: visit/locality follow-up response',
      summary: _buildVisitLocalityFollowUpResponseSummary(
        observationKind: observationKind,
        targetLabel: targetLabel,
        sourceSurface: sourceSurface,
        responseText: responseText,
      ),
      stableRef:
          'visit_locality_follow_up_${observationKind}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: observationKind == 'locality'
          ? 'locality_follow_up_preference_signal'
          : 'visit_follow_up_preference_signal',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'observationKind': observationKind,
        'targetLabel': targetLabel,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'sourceSurface': sourceSurface,
        'completionMode': completionMode,
        'boundedContext': metadata['boundedContext'],
        'signalTags': metadata['signalTags'],
      }),
      requiredAirGapBindingKeys: const <String>[
        'observationKind',
        'targetLabel',
        'promptQuestion',
        'responseText',
        'sourceSurface',
        'completionMode',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'visit_locality_follow_up_response_intake',
        'surface': 'visit_locality_follow_up',
        'channel': sourceSurface,
        'observationKind': observationKind,
        'targetLabel': targetLabel,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'completionMode': completionMode,
        'followUpMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      localityCode:
          boundedContext['where']?.toString().trim().isNotEmpty == true
              ? boundedContext['where'].toString().trim()
              : null,
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageCommunityFollowUpResponseIntake({
    required String ownerUserId,
    required String followUpKind,
    required String targetLabel,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String promptQuestion,
    required String promptRationale,
    required String responseText,
    required String completionMode,
    required UpwardAirGapArtifact airGapArtifact,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final boundedContext = Map<String, dynamic>.from(
      metadata['boundedContext'] as Map? ?? const <String, dynamic>{},
    );
    final metadataDomains = _extractStringList(metadata['domains']);
    final upwardDomainHints = <String>{
      'community',
      ...metadataDomains,
      if (followUpKind == 'community_validation') ...<String>[
        'place',
        'venue',
      ],
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ?? false)
        'locality',
    }.toList()
      ..sort();
    final upwardReferencedEntities = <String>{
      targetLabel.trim(),
      if ((boundedContext['communityName'] as String?)?.trim().isNotEmpty ??
          false)
        (boundedContext['communityName'] as String).trim(),
      if ((boundedContext['spotName'] as String?)?.trim().isNotEmpty ?? false)
        (boundedContext['spotName'] as String).trim(),
    }.where((entry) => entry.isNotEmpty).toList()
      ..sort();
    final upwardQuestions = <String>[
      promptQuestion,
      followUpKind == 'community_validation'
          ? 'What should this bounded community validation follow-up answer change about future place or community trust learning?'
          : 'What should this bounded community follow-up answer change about future community participation or coordination learning?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'community_follow_up_kind',
        'value': followUpKind,
        'confidence': 0.92,
      },
      <String, dynamic>{
        'kind': 'community_follow_up_completion_mode',
        'value': completionMode,
        'confidence': 0.95,
      },
      if ((boundedContext['why'] as String?)?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'community_follow_up_why',
          'value': (boundedContext['why'] as String).trim(),
          'confidence': 0.74,
        },
    ];
    final metadataSignalTags = _extractStringList(metadata['signalTags']);
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:community_follow_up_response',
      'follow_up_kind:$followUpKind',
      'completion_mode:$completionMode',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
      ...metadataSignalTags,
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'community_follow_up_response_intake',
      sourceLabel: 'Community follow-up response',
      title: 'Upward learning review: community follow-up response',
      summary: _buildCommunityFollowUpResponseSummary(
        followUpKind: followUpKind,
        targetLabel: targetLabel,
        sourceSurface: sourceSurface,
        responseText: responseText,
      ),
      stableRef:
          'community_follow_up_${followUpKind}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: followUpKind == 'community_validation'
          ? 'community_validation_follow_up_signal'
          : 'community_coordination_follow_up_signal',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'community',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'followUpKind': followUpKind,
        'targetLabel': targetLabel,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'sourceSurface': sourceSurface,
        'completionMode': completionMode,
        'boundedContext': metadata['boundedContext'],
        'signalTags': metadata['signalTags'],
      }),
      requiredAirGapBindingKeys: const <String>[
        'followUpKind',
        'targetLabel',
        'promptQuestion',
        'responseText',
        'sourceSurface',
        'completionMode',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'community_follow_up_response_intake',
        'surface': 'community_follow_up',
        'channel': sourceSurface,
        'followUpKind': followUpKind,
        'targetLabel': targetLabel,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'completionMode': completionMode,
        'followUpMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      localityCode:
          boundedContext['where']?.toString().trim().isNotEmpty == true
              ? boundedContext['where'].toString().trim()
              : null,
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageBusinessOperatorFollowUpResponseIntake({
    required String ownerUserId,
    required String businessId,
    required String businessName,
    required String action,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String promptQuestion,
    required String promptRationale,
    required String responseText,
    required String completionMode,
    required UpwardAirGapArtifact airGapArtifact,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final boundedContext = Map<String, dynamic>.from(
      metadata['boundedContext'] as Map? ?? const <String, dynamic>{},
    );
    final metadataDomains = _extractStringList(metadata['domains']);
    final upwardDomainHints = <String>{
      'business',
      ...metadataDomains,
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ??
          false) ...<String>['locality', 'place'],
      if ((boundedContext['businessType'] as String?)?.trim().isNotEmpty ??
          false)
        ..._extractBusinessOperatorFollowUpDomainHints(
          businessType: (boundedContext['businessType'] as String).trim(),
          action: action,
          where: boundedContext['where']?.toString(),
          why: boundedContext['why']?.toString(),
        ),
    }.toList()
      ..sort();
    final upwardReferencedEntities = <String>{
      businessId.trim(),
      businessName.trim(),
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ?? false)
        (boundedContext['where'] as String).trim(),
      if ((boundedContext['businessType'] as String?)?.trim().isNotEmpty ??
          false)
        (boundedContext['businessType'] as String).trim(),
    }.where((entry) => entry.isNotEmpty).toList()
      ..sort();
    final upwardQuestions = <String>[
      promptQuestion,
      action == 'create'
          ? 'What should this bounded business setup follow-up change about durable business or place seeding?'
          : 'What should this bounded business update follow-up change about future business, locality, or venue learning?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'business_operator_follow_up_action',
        'value': action,
        'confidence': 0.92,
      },
      <String, dynamic>{
        'kind': 'business_operator_follow_up_completion_mode',
        'value': completionMode,
        'confidence': 0.95,
      },
      if ((boundedContext['businessType'] as String?)?.trim().isNotEmpty ??
          false)
        <String, dynamic>{
          'kind': 'business_type',
          'value': (boundedContext['businessType'] as String).trim(),
          'confidence': 0.86,
        },
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'business_operator_follow_up_where',
          'value': (boundedContext['where'] as String).trim(),
          'confidence': 0.76,
        },
    ];
    final metadataSignalTags = _extractStringList(metadata['signalTags']);
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:business_operator_follow_up_response',
      'action:$action',
      'completion_mode:$completionMode',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
      ...metadataSignalTags,
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'business_operator_follow_up_response_intake',
      sourceLabel: 'Business/operator follow-up response',
      title: 'Upward learning review: business/operator follow-up response',
      summary: _buildBusinessOperatorFollowUpResponseSummary(
        businessName: businessName,
        action: action,
        sourceSurface: sourceSurface,
        responseText: responseText,
      ),
      stableRef:
          'business_follow_up_${businessId}_${action}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: action == 'create'
          ? 'business_operator_follow_up_seed_signal'
          : 'business_operator_follow_up_update_signal',
      hierarchyPath: const <String>[
        'human',
        'business',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'businessId': businessId,
        'businessName': businessName,
        'action': action,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'sourceSurface': sourceSurface,
        'completionMode': completionMode,
        'boundedContext': metadata['boundedContext'],
        'signalTags': metadata['signalTags'],
      }),
      requiredAirGapBindingKeys: const <String>[
        'businessId',
        'businessName',
        'action',
        'promptQuestion',
        'responseText',
        'sourceSurface',
        'completionMode',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'business_operator_follow_up_response_intake',
        'surface': 'business_operator_follow_up',
        'channel': sourceSurface,
        'businessId': businessId,
        'businessName': businessName,
        'action': action,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'completionMode': completionMode,
        'followUpMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      localityCode:
          boundedContext['where']?.toString().trim().isNotEmpty == true
              ? boundedContext['where'].toString().trim()
              : null,
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageBusinessOperatorInputIntake({
    required BusinessAccount account,
    required String action,
    required DateTime occurredAtUtc,
    required UpwardAirGapArtifact airGapArtifact,
    List<String> changedFields = const <String>[],
    String? operatorUserId,
  }) {
    final upwardDomainHints = _extractBusinessOperatorDomainHints(
      account: account,
      action: action,
      changedFields: changedFields,
    );
    final upwardReferencedEntities = <String>[
      account.id,
      account.name,
      account.businessType,
      if (account.location?.trim().isNotEmpty ?? false)
        account.location!.trim(),
      ...account.categories,
      ...account.preferredCommunities,
      ...account.requiredExpertise,
    ]..sort();
    final upwardQuestions = <String>[
      if (action == 'create')
        'Which business profile assumptions should seed the strongest initial business or place convictions?',
      if (changedFields.contains('location'))
        'Should this location change alter locality, place, or venue convictions?',
      if (changedFields.contains('categories'))
        'Do these category changes shift how the business should be modeled?',
      if (changedFields.contains('requiredExpertise'))
        'Should these expertise needs influence business intelligence or simulation planning?',
      if (changedFields.contains('preferredCommunities'))
        'Should these community preferences reopen community or business propagation lanes?',
      if (changedFields.contains('attractionDimensions'))
        'Do these attraction-dimension changes warrant stronger simulation validation?',
      if (changedFields.contains('isVerified'))
        'Should the verification-state change alter trust or conviction weighting?',
    ]..sort();
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'business_operator_action',
        'value': action,
        'confidence': 0.9,
      },
      <String, dynamic>{
        'kind': 'business_type',
        'value': account.businessType,
        'confidence': 0.88,
      },
      <String, dynamic>{
        'kind': 'business_category_count',
        'value': account.categories.length.toString(),
        'confidence': 0.82,
      },
      if (account.location?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'business_location',
          'value': account.location!.trim(),
          'confidence': 0.8,
        },
      if (account.preferredCommunities.isNotEmpty)
        <String, dynamic>{
          'kind': 'preferred_communities_count',
          'value': account.preferredCommunities.length.toString(),
          'confidence': 0.8,
        },
      if (account.requiredExpertise.isNotEmpty)
        <String, dynamic>{
          'kind': 'required_expertise_count',
          'value': account.requiredExpertise.length.toString(),
          'confidence': 0.8,
        },
      if (changedFields.isNotEmpty)
        <String, dynamic>{
          'kind': 'changed_fields',
          'value': changedFields.join(','),
          'confidence': 0.84,
        },
      if (account.isVerified)
        <String, dynamic>{
          'kind': 'business_verified',
          'value': 'true',
          'confidence': 0.86,
        },
    ];
    final upwardSignalTags = <String>{
      'action:$action',
      'source:business_operator_input',
      'surface:business_account',
      'business_type:${account.businessType.trim().toLowerCase().replaceAll(' ', '_')}',
      if (account.isVerified) 'verified_business',
      if (!account.isActive) 'inactive_business',
      ...changedFields.map((field) => 'changed_field:$field'),
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: operatorUserId ?? account.ownerId,
      sourceProvider: 'business_operator_input_intake',
      sourceLabel: 'Business/operator upward learning',
      title: 'Upward learning review: business/operator input',
      summary: _buildBusinessOperatorSummary(
        account: account,
        action: action,
        changedFields: changedFields,
      ),
      stableRef:
          '${account.id}_${action}_${occurredAtUtc.toUtc().microsecondsSinceEpoch}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: action == 'create'
          ? 'business_operator_profile_seed'
          : 'business_operator_update_signal',
      hierarchyPath: const <String>[
        'human',
        'business',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'business_operator_input_intake',
        'businessId': account.id,
        'action': action,
        'businessType': account.businessType,
        'changedFields': changedFields,
        'location': account.location?.trim(),
        'isVerified': account.isVerified,
      }),
      requiredAirGapBindingKeys: const <String>[
        'businessId',
        'action',
        'businessType',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'business_operator_input_intake',
        'surface': 'business_account',
        'channel': action,
        'action': action,
        'changedFields': changedFields,
        'businessAccountSummary': _safeBusinessAccountSummary(account),
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      localityCode: account.location?.trim(),
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageCommunityCoordinationIntake({
    required Community community,
    required String action,
    required String actorUserId,
    required DateTime occurredAtUtc,
    required UpwardAirGapArtifact airGapArtifact,
    String? affectedRef,
    String? sourceEventId,
  }) {
    final upwardDomainHints = _extractCommunityCoordinationDomainHints(
      community: community,
      action: action,
      sourceEventId: sourceEventId,
    );
    final upwardReferencedEntities = <String>[
      community.id,
      community.name,
      community.category,
      community.originalLocality,
      ...community.currentLocalities,
      if (affectedRef?.trim().isNotEmpty ?? false) affectedRef!.trim(),
      if (sourceEventId?.trim().isNotEmpty ?? false) sourceEventId!.trim(),
    ]..sort();
    final upwardQuestions = <String>[
      if (action == 'create')
        'Should this new community seed stronger community or locality convictions?',
      if (action == 'create_from_event')
        'Did this event-to-community transition reveal a durable coordination pattern?',
      if (action == 'add_member')
        'Should this new membership strengthen community coordination or place affinity signals?',
      if (action == 'remove_member')
        'Does this departure challenge the current community cohesion assumptions?',
      if (action == 'add_event')
        'Should this added event increase community activity or event coordination confidence?',
    ]..sort();
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'community_coordination_action',
        'value': action,
        'confidence': 0.88,
      },
      <String, dynamic>{
        'kind': 'community_member_count',
        'value': community.memberCount.toString(),
        'confidence': 0.82,
      },
      <String, dynamic>{
        'kind': 'community_event_count',
        'value': community.eventCount.toString(),
        'confidence': 0.8,
      },
      <String, dynamic>{
        'kind': 'community_activity_level',
        'value': community.activityLevel.name,
        'confidence': 0.78,
      },
    ];
    final upwardSignalTags = <String>{
      'action:$action',
      'source:community_coordination',
      'surface:community_service',
      'activity_level:${community.activityLevel.name}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: actorUserId,
      sourceProvider: 'community_coordination_intake',
      sourceLabel: 'Community coordination upward learning',
      title: 'Upward learning review: community coordination',
      summary: _buildCommunityCoordinationSummary(
        community: community,
        action: action,
        affectedRef: affectedRef,
      ),
      stableRef:
          '${community.id}_${action}_${occurredAtUtc.toUtc().microsecondsSinceEpoch}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: _communityCoordinationConvictionTier(action),
      hierarchyPath: const <String>[
        'human',
        'community',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'community_coordination_intake',
        'communityId': community.id,
        'action': action,
        'category': community.category,
        'memberCount': community.memberCount,
        'eventCount': community.eventCount,
        'localityCode': community.localityCode,
        'sourceEventId': sourceEventId?.trim(),
      }),
      requiredAirGapBindingKeys: const <String>[
        'communityId',
        'action',
        'category',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'community_coordination_intake',
        'surface': 'community_service',
        'channel': action,
        'action': action,
        'communitySummary': _safeCommunitySummary(community),
        if (affectedRef != null) 'affectedRef': affectedRef,
        if (sourceEventId != null) 'sourceEventId': sourceEventId,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      cityCode: community.cityCode,
      localityCode: community.localityCode ?? community.originalLocality,
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageCommunityValidationIntake({
    required CommunityValidation validation,
    required DateTime occurredAtUtc,
    required UpwardAirGapArtifact airGapArtifact,
    String? spotName,
  }) {
    final upwardDomainHints = _extractCommunityValidationDomainHints(
      validation: validation,
    );
    final upwardReferencedEntities = <String>[
      validation.spotId,
      validation.validatorId,
      if (spotName?.trim().isNotEmpty ?? false) spotName!.trim(),
      ...validation.criteriaChecked.map((criteria) => criteria.name),
    ]..sort();
    final upwardQuestions = <String>[
      if (validation.status == ValidationStatus.needsReview)
        'What should be reviewed before this spot or place signal is trusted again?',
      if (validation.status == ValidationStatus.rejected)
        'Which prior place or venue belief should this rejection challenge?',
      if (validation.status == ValidationStatus.validated)
        'Should this community validation strengthen current place or venue convictions?',
    ]..sort();
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'community_validation_status',
        'value': validation.status.name,
        'confidence': validation.confidenceScore,
      },
      <String, dynamic>{
        'kind': 'community_validation_level',
        'value': validation.level.name,
        'confidence': validation.trustScore,
      },
      <String, dynamic>{
        'kind': 'community_validation_criteria_count',
        'value': validation.criteriaChecked.length.toString(),
        'confidence': 0.78,
      },
    ];
    final upwardSignalTags = <String>{
      'source:community_validation',
      'surface:community_validation',
      'status:${validation.status.name}',
      'level:${validation.level.name}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: validation.validatorId,
      sourceProvider: 'community_validation_intake',
      sourceLabel: 'Community validation upward learning',
      title: 'Upward learning review: community validation',
      summary: _buildCommunityValidationSummary(
        validation: validation,
        spotName: spotName,
      ),
      stableRef: validation.id,
      occurredAtUtc: occurredAtUtc,
      convictionTier: _communityValidationConvictionTier(validation),
      hierarchyPath: const <String>[
        'human',
        'community',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'community_validation_intake',
        'validationId': validation.id,
        'spotId': validation.spotId,
        'status': validation.status.name,
        'level': validation.level.name,
        'confidenceScore': validation.confidenceScore,
        'trustScore': validation.trustScore,
        'spotName': spotName?.trim(),
      }),
      requiredAirGapBindingKeys: const <String>[
        'validationId',
        'spotId',
        'status',
        'level',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'community_validation_intake',
        'surface': 'community_validation',
        'channel': validation.level.name,
        'validationSummary': _safeCommunityValidationSummary(validation),
        if (spotName != null) 'spotName': spotName,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageReservationSharingIntake({
    required String ownerUserId,
    required Reservation reservation,
    required String action,
    required DateTime occurredAtUtc,
    required UpwardAirGapArtifact airGapArtifact,
    String? counterpartUserId,
    String? permission,
    double? compatibilityScore,
  }) {
    final upwardDomainHints = _extractReservationDomainHints(
      reservation: reservation,
      action: action,
      extraText: <String>[
        if (permission?.trim().isNotEmpty ?? false) permission!.trim(),
      ],
    );
    final upwardReferencedEntities = <String>[
      reservation.id,
      reservation.targetId,
      if (reservation.seatId?.trim().isNotEmpty ?? false)
        reservation.seatId!.trim(),
      if (reservation.metadata['localityCode']?.toString().trim().isNotEmpty ??
          false)
        reservation.metadata['localityCode'].toString().trim(),
      if (counterpartUserId?.trim().isNotEmpty ?? false)
        counterpartUserId!.trim(),
    ]..sort();
    final upwardQuestions = <String>[
      if (action == 'share')
        'Should this reservation sharing action strengthen community, place, or venue coordination assumptions?',
      if (action == 'transfer')
        'Does this reservation transfer challenge or reinforce current compatibility and reassignment assumptions?',
      if (permission == 'fullAccess')
        'Should full-access sharing be treated as a stronger coordination conviction than read-only sharing?',
      if (compatibilityScore != null)
        'Does the transfer compatibility score warrant stronger simulation or corroboration review?',
    ]..sort();
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'reservation_sharing_action',
        'value': action,
        'confidence': 0.86,
      },
      <String, dynamic>{
        'kind': 'reservation_type',
        'value': reservation.type.name,
        'confidence': 0.84,
      },
      <String, dynamic>{
        'kind': 'reservation_party_size',
        'value': reservation.partySize.toString(),
        'confidence': 0.82,
      },
      <String, dynamic>{
        'kind': 'reservation_ticket_count',
        'value': reservation.ticketCount.toString(),
        'confidence': 0.82,
      },
      if (permission?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'sharing_permission',
          'value': permission!.trim(),
          'confidence': 0.84,
        },
      if (compatibilityScore != null)
        <String, dynamic>{
          'kind': 'transfer_compatibility_score',
          'value': compatibilityScore.toStringAsFixed(3),
          'confidence': compatibilityScore.clamp(0.0, 1.0),
        },
    ];
    final upwardSignalTags = <String>{
      'source:reservation_sharing',
      'surface:reservation_sharing',
      'action:$action',
      'reservation_type:${reservation.type.name}',
      if (permission?.trim().isNotEmpty ?? false)
        'permission:${permission!.trim().toLowerCase()}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'reservation_sharing_intake',
      sourceLabel: 'Reservation sharing upward learning',
      title: 'Upward learning review: reservation sharing',
      summary: _buildReservationSharingSummary(
        reservation: reservation,
        action: action,
        permission: permission,
      ),
      stableRef:
          '${reservation.id}_${action}_${occurredAtUtc.toUtc().microsecondsSinceEpoch}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: _reservationSharingConvictionTier(
        action: action,
        permission: permission,
      ),
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'reservation_sharing_intake',
        'reservationId': reservation.id,
        'targetId': reservation.targetId,
        'action': action,
        'permission': permission,
        'compatibilityScore': compatibilityScore,
        'reservationType': reservation.type.name,
        'localityCode': reservation.metadata['localityCode']?.toString().trim(),
      }),
      requiredAirGapBindingKeys: const <String>[
        'reservationId',
        'targetId',
        'action',
        'reservationType',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'reservation_sharing_intake',
        'surface': 'reservation_sharing',
        'channel': action,
        'action': action,
        'reservationSummary': _safeReservationSummary(reservation),
        if (counterpartUserId != null) 'counterpartUserId': counterpartUserId,
        if (permission != null) 'permission': permission,
        if (compatibilityScore != null)
          'compatibilityScore': compatibilityScore,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      cityCode: reservation.metadata['cityCode']?.toString(),
      localityCode: reservation.metadata['localityCode']?.toString(),
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageReservationCalendarIntake({
    required String ownerUserId,
    required Reservation reservation,
    required DateTime occurredAtUtc,
    required UpwardAirGapArtifact airGapArtifact,
    required String calendarEventId,
    String calendarId = 'default',
  }) {
    final upwardDomainHints = _extractReservationDomainHints(
      reservation: reservation,
      action: 'calendar_sync',
      extraText: <String>[calendarId],
    );
    final upwardReferencedEntities = <String>[
      reservation.id,
      reservation.targetId,
      calendarEventId,
      if (reservation.metadata['localityCode']?.toString().trim().isNotEmpty ??
          false)
        reservation.metadata['localityCode'].toString().trim(),
    ]..sort();
    final upwardQuestions = <String>[
      'Should this calendar sync strengthen planning, recurrence, or timing convictions for this reservation target?',
      if (reservation.calendarEventId == null)
        'Does first-time calendar sync indicate stronger commitment than prior reservation-only intent?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'reservation_calendar_sync',
        'value': calendarId,
        'confidence': 0.84,
      },
      <String, dynamic>{
        'kind': 'reservation_type',
        'value': reservation.type.name,
        'confidence': 0.82,
      },
      <String, dynamic>{
        'kind': 'reservation_party_size',
        'value': reservation.partySize.toString(),
        'confidence': 0.8,
      },
    ];
    final upwardSignalTags = <String>{
      'source:reservation_calendar_sync',
      'surface:reservation_calendar',
      'calendar:$calendarId',
      'reservation_type:${reservation.type.name}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'reservation_calendar_sync_intake',
      sourceLabel: 'Reservation calendar sync upward learning',
      title: 'Upward learning review: reservation calendar sync',
      summary: _buildReservationCalendarSummary(
        reservation: reservation,
        calendarId: calendarId,
      ),
      stableRef:
          '${reservation.id}_calendar_sync_${occurredAtUtc.toUtc().microsecondsSinceEpoch}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: 'reservation_calendar_sync_signal',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'reservation_calendar_sync_intake',
        'reservationId': reservation.id,
        'targetId': reservation.targetId,
        'calendarEventId': calendarEventId,
        'calendarId': calendarId,
        'reservationType': reservation.type.name,
        'localityCode': reservation.metadata['localityCode']?.toString().trim(),
      }),
      requiredAirGapBindingKeys: const <String>[
        'reservationId',
        'targetId',
        'calendarEventId',
        'calendarId',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'reservation_calendar_sync_intake',
        'surface': 'reservation_calendar',
        'channel': 'calendar_sync',
        'reservationSummary': _safeReservationSummary(reservation),
        'calendarEventId': calendarEventId,
        'calendarId': calendarId,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      cityCode: reservation.metadata['cityCode']?.toString(),
      localityCode: reservation.metadata['localityCode']?.toString(),
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageReservationRecurrenceIntake({
    required String ownerUserId,
    required Reservation baseReservation,
    required DateTime occurredAtUtc,
    required UpwardAirGapArtifact airGapArtifact,
    required String seriesId,
    required String patternType,
    required int interval,
    required List<String> createdReservationIds,
    DateTime? endDate,
    int? maxOccurrences,
    List<int>? daysOfWeek,
    int? dayOfMonth,
  }) {
    final upwardDomainHints = _extractReservationDomainHints(
      reservation: baseReservation,
      action: 'recurrence',
      extraText: <String>[patternType],
    );
    final upwardReferencedEntities = <String>[
      baseReservation.id,
      baseReservation.targetId,
      seriesId,
      ...createdReservationIds,
      if (baseReservation.metadata['localityCode']
              ?.toString()
              .trim()
              .isNotEmpty ??
          false)
        baseReservation.metadata['localityCode'].toString().trim(),
    ]..sort();
    final upwardQuestions = <String>[
      'Does this recurring reservation pattern indicate a durable habit that should strengthen future simulations?',
      if ((maxOccurrences ?? createdReservationIds.length) >= 3)
        'Should this stronger recurrence cadence raise conviction more than a one-off reservation?',
      if (daysOfWeek?.isNotEmpty ?? false)
        'Do these weekly recurrence choices reveal stable timing or locality preferences?',
    ]..sort();
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'reservation_recurrence_pattern',
        'value': patternType,
        'confidence': 0.86,
      },
      <String, dynamic>{
        'kind': 'reservation_recurrence_interval',
        'value': interval.toString(),
        'confidence': 0.82,
      },
      <String, dynamic>{
        'kind': 'reservation_recurrence_instances',
        'value': createdReservationIds.length.toString(),
        'confidence': 0.84,
      },
      <String, dynamic>{
        'kind': 'reservation_type',
        'value': baseReservation.type.name,
        'confidence': 0.8,
      },
    ];
    final upwardSignalTags = <String>{
      'source:reservation_recurrence',
      'surface:reservation_recurrence',
      'pattern:$patternType',
      'reservation_type:${baseReservation.type.name}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'reservation_recurrence_intake',
      sourceLabel: 'Reservation recurrence upward learning',
      title: 'Upward learning review: reservation recurrence',
      summary: _buildReservationRecurrenceSummary(
        reservation: baseReservation,
        patternType: patternType,
        createdCount: createdReservationIds.length,
      ),
      stableRef: seriesId,
      occurredAtUtc: occurredAtUtc,
      convictionTier: 'reservation_recurrence_pattern_signal',
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'reservation_recurrence_intake',
        'seriesId': seriesId,
        'patternType': patternType,
        'interval': interval,
        'createdReservationCount': createdReservationIds.length,
        'baseReservationId': baseReservation.id,
        'localityCode':
            baseReservation.metadata['localityCode']?.toString().trim(),
      }),
      requiredAirGapBindingKeys: const <String>[
        'seriesId',
        'patternType',
        'interval',
        'baseReservationId',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'reservation_recurrence_intake',
        'surface': 'reservation_recurrence',
        'channel': patternType,
        'seriesId': seriesId,
        'reservationSummary': _safeReservationSummary(baseReservation),
        'pattern': <String, dynamic>{
          'type': patternType,
          'interval': interval,
          if (endDate != null) 'endDateUtc': endDate.toUtc().toIso8601String(),
          if (maxOccurrences != null) 'maxOccurrences': maxOccurrences,
          if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
          if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
        },
        'createdReservationIds': createdReservationIds,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      cityCode: baseReservation.metadata['cityCode']?.toString(),
      localityCode: baseReservation.metadata['localityCode']?.toString(),
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageReservationOperationalFollowUpResponseIntake({
    required String ownerUserId,
    required String reservationId,
    required String reservationType,
    required String targetId,
    required String targetLabel,
    required String operationKind,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String promptQuestion,
    required String promptRationale,
    required String responseText,
    required String completionMode,
    required UpwardAirGapArtifact airGapArtifact,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final metadataDomains = _extractStringList(metadata['domains']);
    final normalizedReservationType = reservationType.trim().toLowerCase();
    final upwardDomainHints = <String>{
      'reservation',
      'timing',
      ...metadataDomains,
      if (normalizedReservationType == 'event') ...<String>[
        'event',
        'community'
      ],
      if (normalizedReservationType == 'business') ...<String>[
        'business',
        'place'
      ],
      if (normalizedReservationType == 'spot') ...<String>['place', 'locality'],
      if (operationKind == 'reservation_share' ||
          operationKind == 'reservation_transfer')
        'coordination',
    }.toList()
      ..sort();
    final upwardReferencedEntities = <String>{
      reservationId.trim(),
      targetId.trim(),
      targetLabel.trim(),
    }.where((entry) => entry.isNotEmpty).toList()
      ..sort();
    final upwardQuestions = <String>[
      promptQuestion,
      operationKind == 'reservation_calendar_sync'
          ? 'What should this bounded reservation calendar-sync follow-up change about future timing or reminder learning?'
          : operationKind == 'reservation_recurrence'
              ? 'What should this bounded reservation recurrence follow-up change about future timing or repeat-pattern learning?'
              : 'What should this bounded reservation coordination follow-up change about future trust, logistics, or sharing learning?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'reservation_follow_up_operation_kind',
        'value': operationKind,
        'confidence': 0.94,
      },
      <String, dynamic>{
        'kind': 'reservation_follow_up_completion_mode',
        'value': completionMode,
        'confidence': 0.95,
      },
      <String, dynamic>{
        'kind': 'reservation_type',
        'value': normalizedReservationType,
        'confidence': 0.88,
      },
    ];
    final metadataSignalTags = _extractStringList(metadata['signalTags']);
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:reservation_operational_follow_up_response',
      'operation:$operationKind',
      'reservation_type:$normalizedReservationType',
      'completion_mode:$completionMode',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
      ...metadataSignalTags,
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'reservation_operational_follow_up_response_intake',
      sourceLabel: 'Reservation operational follow-up response',
      title:
          'Upward learning review: reservation operational follow-up response',
      summary:
          'The user answered a bounded reservation follow-up about `$targetLabel` after a `$operationKind` operation from `$sourceSurface`.',
      stableRef:
          'reservation_follow_up_${reservationId}_${operationKind}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: operationKind == 'reservation_calendar_sync'
          ? 'reservation_calendar_follow_up_signal'
          : operationKind == 'reservation_recurrence'
              ? 'reservation_recurrence_follow_up_signal'
              : 'reservation_coordination_follow_up_signal',
      hierarchyPath: const <String>[
        'human',
        'reservation',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'reservationId': reservationId,
        'reservationType': reservationType,
        'targetId': targetId,
        'targetLabel': targetLabel,
        'operationKind': operationKind,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'sourceSurface': sourceSurface,
        'completionMode': completionMode,
        'boundedContext': metadata['boundedContext'],
        'signalTags': metadata['signalTags'],
      }),
      requiredAirGapBindingKeys: const <String>[
        'reservationId',
        'reservationType',
        'targetId',
        'targetLabel',
        'operationKind',
        'promptQuestion',
        'responseText',
        'sourceSurface',
        'completionMode',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'reservation_operational_follow_up_response_intake',
        'surface': 'reservation_operational_follow_up',
        'channel': sourceSurface,
        'reservationId': reservationId,
        'reservationType': reservationType,
        'targetId': targetId,
        'targetLabel': targetLabel,
        'operationKind': operationKind,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'completionMode': completionMode,
        'followUpMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageExternalConfirmationIntake({
    required ExternalSourceDescriptor source,
    required ExternalSyncMetadata metadata,
    required IntakeEntityType entityType,
    required String entityId,
    required DateTime occurredAtUtc,
    required String action,
    Map<String, dynamic> boundedPayload = const <String, dynamic>{},
  }) {
    final upwardDomainHints = _extractExternalConfirmationDomainHints(
      source: source,
      metadata: metadata,
      entityType: entityType,
      action: action,
      boundedPayload: boundedPayload,
    );
    final upwardReferencedEntities = <String>[
      source.id,
      entityId,
      if (metadata.externalId?.trim().isNotEmpty ?? false)
        metadata.externalId!.trim(),
      if (source.sourceLabel?.trim().isNotEmpty ?? false)
        source.sourceLabel!.trim(),
      if (source.cityCode?.trim().isNotEmpty ?? false) source.cityCode!.trim(),
      if (source.localityCode?.trim().isNotEmpty ?? false)
        source.localityCode!.trim(),
    ]..sort();
    final upwardQuestions = <String>[
      'Should this external confirmation or import materially strengthen current convictions for `${entityType.name}`?',
      if (action == 'linked_existing_entity')
        'Does this external source corroborate the already-existing AVRAI entity strongly enough to reopen related simulations?',
      if (action == 'materialized_import')
        'Should this imported external source seed stronger simulations or follow-up corroboration planning?',
      if (metadata.connectionMode == ExternalConnectionMode.feed ||
          metadata.connectionMode == ExternalConnectionMode.api)
        'Does this recurring external source merit stronger freshness weighting than a one-off manual import?',
    ]..sort();
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'external_source_provider',
        'value': source.sourceProvider,
        'confidence': 0.82,
      },
      <String, dynamic>{
        'kind': 'external_connection_mode',
        'value': metadata.connectionMode.name,
        'confidence': 0.82,
      },
      <String, dynamic>{
        'kind': 'external_entity_type',
        'value': entityType.name,
        'confidence': 0.84,
      },
      <String, dynamic>{
        'kind': 'external_action',
        'value': action,
        'confidence': 0.84,
      },
      if (metadata.syncState == ExternalSyncState.active)
        <String, dynamic>{
          'kind': 'external_sync_state',
          'value': metadata.syncState.name,
          'confidence': 0.86,
        },
      if (metadata.isClaimable)
        <String, dynamic>{
          'kind': 'external_claimable',
          'value': 'true',
          'confidence': 0.72,
        },
    ];
    final upwardSignalTags = <String>{
      'source:external_confirmation',
      'provider:${source.sourceProvider.trim().toLowerCase()}',
      'connection:${metadata.connectionMode.name}',
      'entity_type:${entityType.name}',
      'action:$action',
      if (metadata.isClaimable) 'claimable_external_source',
      if (source.isOneWaySync) 'one_way_sync',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: source.ownerUserId,
      sourceProvider: 'external_confirmation_import_intake',
      sourceLabel: 'External confirmation/import upward learning',
      title: 'Upward learning review: external confirmation/import',
      summary: _buildExternalConfirmationSummary(
        source: source,
        metadata: metadata,
        entityType: entityType,
        action: action,
      ),
      stableRef: '${source.id}_${entityType.name}_${entityId}_$action',
      occurredAtUtc: occurredAtUtc,
      convictionTier: _externalConfirmationConvictionTier(
        metadata: metadata,
        action: action,
      ),
      hierarchyPath: const <String>[
        'external_world',
        'personal_agent',
        'reality_model_agent',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'external_confirmation_import_intake',
        'surface': 'external_source_sync',
        'channel': source.connectionMode.name,
        'action': action,
        'entityType': entityType.name,
        'entityId': entityId,
        'externalSource': _safeExternalSourceSummary(source),
        'externalSyncMetadata': metadata.toJson(),
        'boundedPayload': boundedPayload,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      cityCode: metadata.cityCode ?? source.cityCode,
      localityCode: metadata.localityCode ?? source.localityCode,
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageVisitObservationIntake({
    required String ownerUserId,
    required Visit visit,
    required UpwardAirGapArtifact airGapArtifact,
    required String source,
  }) {
    final upwardDomainHints = _extractVisitDomainHints(
      visit: visit,
      source: source,
    );
    final upwardReferencedEntities = <String>[
      visit.locationId,
      if ((visit.metadata['localityCode']?.toString().trim().isNotEmpty ??
          false))
        visit.metadata['localityCode'].toString().trim(),
    ]..sort();
    final upwardQuestions = <String>[
      if ((visit.dwellTime?.inMinutes ?? 0) < 10)
        'Was this visit a transient stop or a meaningful locality signal?',
      if (visit.isRepeatVisit)
        'Should this repeat visit strengthen a locality or place conviction?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'visit_quality_score',
        'value': visit.qualityScore.toStringAsFixed(2),
        'confidence': 0.82,
      },
      <String, dynamic>{
        'kind': 'visit_dwell_minutes',
        'value': (visit.dwellTime?.inMinutes ?? 0).toString(),
        'confidence': 0.9,
      },
      <String, dynamic>{
        'kind': 'visit_source',
        'value': source,
        'confidence': 0.86,
      },
      if (visit.isRepeatVisit)
        <String, dynamic>{
          'kind': 'repeat_visit',
          'value': 'true',
          'confidence': 0.88,
        },
    ];
    final upwardSignalTags = <String>{
      'surface:automatic_check_in',
      'source:visit_observation',
      'trigger:$source',
      if (visit.isAutomatic) 'automatic_visit',
      if (visit.isRepeatVisit) 'repeat_visit',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'visit_observation_intake',
      sourceLabel: 'Visit observation upward learning',
      title: 'Upward learning review: visit observation',
      summary: _buildVisitSummary(visit: visit, source: source),
      stableRef: visit.id,
      occurredAtUtc: (visit.checkOutTime ?? visit.checkInTime).toUtc(),
      convictionTier: _visitConvictionTier(visit),
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'locality',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'visit_observation_intake',
        'triggerSource': source,
        'visitId': visit.id,
        'locationId': visit.locationId,
        'isAutomatic': visit.isAutomatic,
        'isRepeatVisit': visit.isRepeatVisit,
        'qualityScore': visit.qualityScore,
        'dwellMinutes': visit.dwellTime?.inMinutes ?? 0,
        'localityCode': visit.metadata['localityCode']?.toString().trim(),
      }),
      requiredAirGapBindingKeys: const <String>[
        'triggerSource',
        'visitId',
        'locationId',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'visit_observation_intake',
        'surface': 'automatic_check_in',
        'channel': source,
        'visit': visit.toJson(),
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      localityCode: visit.metadata['localityCode']?.toString().trim(),
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageLocalityObservationIntake({
    required String ownerUserId,
    required DateTime occurredAtUtc,
    required UpwardAirGapArtifact airGapArtifact,
    required String sourceKind,
    required String localityStableKey,
    Map<String, dynamic> structuredSignals = const <String, dynamic>{},
    Map<String, dynamic> locationContext = const <String, dynamic>{},
    Map<String, dynamic> temporalContext = const <String, dynamic>{},
    String? socialContext,
    String? activityContext,
    String? lineageRef,
  }) {
    final upwardDomainHints = _extractLocalityObservationDomainHints(
      localityStableKey: localityStableKey,
      structuredSignals: structuredSignals,
      socialContext: socialContext,
      activityContext: activityContext,
    );
    final upwardReferencedEntities = <String>[
      localityStableKey,
      ..._extractStringList(locationContext['placeRefs']),
      ..._extractStringList(locationContext['entities']),
    ]..sort();
    final upwardQuestions = <String>[
      if ((structuredSignals['coPresenceDetected'] as bool?) == true)
        'Did this locality observation represent a repeat social pattern or a one-off anomaly?',
      if ((structuredSignals['dwellDurationMinutes'] as num?)?.toInt()
          case final minutes? when minutes >= 30)
        'Should this sustained dwell strengthen locality or place convictions?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      if (socialContext != null && socialContext.trim().isNotEmpty)
        <String, dynamic>{
          'kind': 'locality_social_context',
          'value': socialContext.trim(),
          'confidence': 0.68,
        },
      if (activityContext != null && activityContext.trim().isNotEmpty)
        <String, dynamic>{
          'kind': 'locality_activity_context',
          'value': activityContext.trim(),
          'confidence': 0.66,
        },
      if (structuredSignals['placeVibeLabel']?.toString().trim().isNotEmpty ??
          false)
        <String, dynamic>{
          'kind': 'place_vibe_label',
          'value': structuredSignals['placeVibeLabel'].toString().trim(),
          'confidence': (structuredSignals['crowdRecognitionScore'] as num?)
                  ?.toDouble() ??
              0.6,
        },
      if (structuredSignals['dwellDurationMinutes'] != null)
        <String, dynamic>{
          'kind': 'dwell_duration_minutes',
          'value': structuredSignals['dwellDurationMinutes'].toString(),
          'confidence': 0.88,
        },
    ];
    final upwardSignalTags = <String>{
      'surface:locality_observation',
      'source:$sourceKind',
      if (socialContext?.trim().isNotEmpty ?? false)
        'social:${socialContext!.trim()}',
      if (activityContext?.trim().isNotEmpty ?? false)
        'activity:${activityContext!.trim()}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'locality_observation_intake',
      sourceLabel: 'Locality observation upward learning',
      title: 'Upward learning review: locality observation',
      summary: _buildLocalityObservationSummary(
        sourceKind: sourceKind,
        localityStableKey: localityStableKey,
        structuredSignals: structuredSignals,
        socialContext: socialContext,
      ),
      stableRef:
          '${sourceKind}_${localityStableKey}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: _localityObservationConvictionTier(structuredSignals),
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'locality',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'locality_observation_intake',
        'sensorSource': sourceKind,
        'localityStableKey': localityStableKey,
        'durationMinutes': temporalContext['durationMinutes'] ??
            structuredSignals['dwellDurationMinutes'],
        'socialContext': socialContext?.trim(),
      }),
      requiredAirGapBindingKeys: const <String>[
        'sourceKind',
        'sensorSource',
        'localityStableKey',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'locality_observation_intake',
        'surface': 'locality_observation',
        'channel': sourceKind,
        'lineageRef': lineageRef,
        'localityStableKey': localityStableKey,
        'structuredSignals': structuredSignals,
        'locationContext': locationContext,
        'temporalContext': temporalContext,
        'socialContext': socialContext,
        'activityContext': activityContext,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      localityCode: localityStableKey,
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageEventFeedbackIntake({
    required EventFeedback feedback,
    required UpwardAirGapArtifact airGapArtifact,
    ExpertiseEvent? event,
  }) {
    final upwardDomainHints = _extractEventFeedbackDomainHints(
      feedback: feedback,
      event: event,
    );
    final upwardReferencedEntities = <String>[
      feedback.eventId,
      if (event?.title.trim().isNotEmpty ?? false) event!.title.trim(),
      ...?feedback.highlights,
    ]..sort();
    final upwardQuestions = <String>[
      if ((feedback.improvements?.isNotEmpty ?? false))
        'Which improvements should become strongest event or venue correction signals?',
      if (feedback.wouldAttendAgain == false)
        'What made the event feel misaligned with the attendee expectation?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'event_overall_rating',
        'value': feedback.overallRating.toStringAsFixed(1),
        'confidence': 0.88,
      },
      <String, dynamic>{
        'kind': 'would_attend_again',
        'value': feedback.wouldAttendAgain.toString(),
        'confidence': 0.84,
      },
      <String, dynamic>{
        'kind': 'would_recommend',
        'value': feedback.wouldRecommend.toString(),
        'confidence': 0.84,
      },
      for (final entry in feedback.categoryRatings.entries)
        <String, dynamic>{
          'kind': 'event_category_rating',
          'value': '${entry.key}:${entry.value.toStringAsFixed(1)}',
          'confidence': 0.8,
        },
    ];
    final upwardSignalTags = <String>{
      'surface:post_event_feedback',
      'source:event_feedback',
      'role:${feedback.userRole}',
      if (feedback.wouldAttendAgain) 'would_attend_again',
      if (feedback.wouldRecommend) 'would_recommend',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: feedback.userId,
      sourceProvider: 'event_feedback_intake',
      sourceLabel: 'Post-event feedback upward learning',
      title: 'Upward learning review: event feedback',
      summary: _buildEventFeedbackSummary(feedback: feedback, event: event),
      stableRef: feedback.id,
      occurredAtUtc: feedback.submittedAt.toUtc(),
      convictionTier: _eventFeedbackConvictionTier(feedback),
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'event',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'event_feedback_intake',
        'eventId': feedback.eventId,
        'overallRating': feedback.overallRating,
        'wouldAttendAgain': feedback.wouldAttendAgain,
        'wouldRecommend': feedback.wouldRecommend,
        'userRole': feedback.userRole,
        'eventCategory': event?.category,
        'localityCode': event?.localityCode?.trim(),
      }),
      requiredAirGapBindingKeys: const <String>[
        'eventId',
        'overallRating',
        'wouldAttendAgain',
        'wouldRecommend',
        'userRole',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'event_feedback_intake',
        'surface': 'post_event_feedback',
        'channel': 'attendee_feedback',
        'eventFeedback': feedback.toJson(),
        'eventSummary': event == null ? null : _safeEventSummary(event),
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      cityCode: event?.cityCode,
      localityCode: event?.localityCode,
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageEventFeedbackFollowUpResponseIntake({
    required String ownerUserId,
    required String eventId,
    required String eventTitle,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    required String promptQuestion,
    required String promptRationale,
    required String responseText,
    required String completionMode,
    required UpwardAirGapArtifact airGapArtifact,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final boundedContext = metadata['boundedContext'] is Map
        ? Map<String, dynamic>.from(metadata['boundedContext'] as Map)
        : const <String, dynamic>{};
    final metadataDomains = _extractStringList(metadata['domains']);
    final localityCode = metadata['localityCode']?.toString() ??
        boundedContext['where']?.toString();
    final cityCode = metadata['cityCode']?.toString();
    final eventCategory = metadata['eventCategory']?.toString();
    final hasLocalityScope =
        (localityCode != null && localityCode.trim().isNotEmpty) ||
            (cityCode != null && cityCode.trim().isNotEmpty);
    final hasEventCategory =
        eventCategory != null && eventCategory.trim().isNotEmpty;
    final upwardDomainHints = <String>{
      'event',
      ...metadataDomains,
      if (hasLocalityScope) 'locality',
      if (hasEventCategory) 'community',
      if ((responseText.toLowerCase().contains('venue')) ||
          metadataDomains.contains('venue'))
        'venue',
    }.toList()
      ..sort();
    final upwardReferencedEntities = <String>{
      eventId,
      if (eventTitle.trim().isNotEmpty) eventTitle.trim(),
      if ((boundedContext['what'] as String?)?.trim().isNotEmpty ?? false)
        (boundedContext['what'] as String).trim(),
    }.toList()
      ..sort();
    final upwardQuestions = <String>[
      promptQuestion,
      'What should this bounded follow-up answer change about future event, venue, or locality learning?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'event_feedback_follow_up_completion_mode',
        'value': completionMode,
        'confidence': 0.95,
      },
      if (metadata['overallRating'] != null)
        <String, dynamic>{
          'kind': 'event_feedback_follow_up_overall_rating',
          'value': metadata['overallRating'].toString(),
          'confidence': 0.84,
        },
      if (metadata['wouldAttendAgain'] != null)
        <String, dynamic>{
          'kind': 'event_feedback_follow_up_would_attend_again',
          'value': metadata['wouldAttendAgain'].toString(),
          'confidence': 0.84,
        },
      if ((boundedContext['where'] as String?)?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'event_feedback_follow_up_where',
          'value': (boundedContext['where'] as String).trim(),
          'confidence': 0.72,
        },
    ];
    final metadataSignalTags = _extractStringList(metadata['signalTags']);
    final upwardSignalTags = <String>{
      'surface:$sourceSurface',
      'source:event_feedback_follow_up_response',
      'completion_mode:$completionMode',
      if ((metadata['feedbackRole']?.toString().trim().isNotEmpty ?? false))
        'role:${metadata['feedbackRole'].toString().trim()}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
      ...metadataSignalTags,
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'event_feedback_follow_up_response_intake',
      sourceLabel: 'Post-event feedback follow-up response',
      title: 'Upward learning review: event feedback follow-up response',
      summary: _buildEventFeedbackFollowUpResponseSummary(
        eventTitle: eventTitle,
        sourceSurface: sourceSurface,
        responseText: responseText,
      ),
      stableRef:
          'event_follow_up_${eventId}_${occurredAtUtc.toUtc().toIso8601String().replaceAll(':', '_')}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: _eventFeedbackFollowUpConvictionTier(metadata),
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'event',
        'reality_model_agent',
      ],
      airGapArtifact: airGapArtifact,
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'eventId': eventId,
        'eventTitle': eventTitle,
        'sourceFeedbackId': metadata['sourceFeedbackId'],
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'sourceSurface': sourceSurface,
        'completionMode': completionMode,
        'boundedContext': metadata['boundedContext'],
        'signalTags': metadata['signalTags'],
      }),
      requiredAirGapBindingKeys: const <String>[
        'eventId',
        'eventTitle',
        'promptQuestion',
        'responseText',
        'sourceSurface',
        'completionMode',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'event_feedback_follow_up_response_intake',
        'surface': 'event_feedback_follow_up',
        'channel': sourceSurface,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'promptQuestion': promptQuestion,
        'promptRationale': promptRationale,
        'responseText': responseText,
        'completionMode': completionMode,
        'followUpMetadata': metadata,
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      cityCode: cityCode,
      localityCode: localityCode,
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stagePartnerRatingIntake({
    required PartnerRating rating,
    required UpwardAirGapArtifact airGapArtifact,
    ExpertiseEvent? event,
  }) {
    final upwardDomainHints = _extractPartnerRatingDomainHints(
      rating: rating,
      event: event,
    );
    final upwardReferencedEntities = <String>[
      rating.eventId,
      rating.ratedId,
      rating.raterId,
      if (event?.title.trim().isNotEmpty ?? false) event!.title.trim(),
    ]..sort();
    final upwardQuestions = <String>[
      if ((rating.improvements?.trim().isNotEmpty ?? false))
        'Which partnership improvements should become strongest business or event correction signals?',
      if (rating.wouldPartnerAgain < 3.5)
        'What caused partnership confidence to degrade?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'partner_overall_rating',
        'value': rating.overallRating.toStringAsFixed(1),
        'confidence': 0.86,
      },
      <String, dynamic>{
        'kind': 'would_partner_again',
        'value': rating.wouldPartnerAgain.toStringAsFixed(1),
        'confidence': 0.86,
      },
      <String, dynamic>{
        'kind': 'partnership_role',
        'value': rating.partnershipRole,
        'confidence': 0.84,
      },
    ];
    final upwardSignalTags = <String>{
      'surface:post_event_partner_rating',
      'source:partner_rating',
      'role:${rating.partnershipRole}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: rating.raterId,
      sourceProvider: 'partner_rating_intake',
      sourceLabel: 'Partner rating upward learning',
      title: 'Upward learning review: partner rating',
      summary: _buildPartnerRatingSummary(rating: rating, event: event),
      stableRef: rating.id,
      occurredAtUtc: rating.submittedAt.toUtc(),
      convictionTier: _partnerRatingConvictionTier(rating),
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'business',
        'event',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'partner_rating_intake',
        'eventId': rating.eventId,
        'ratedId': rating.ratedId,
        'overallRating': rating.overallRating,
        'wouldPartnerAgain': rating.wouldPartnerAgain,
        'partnershipRole': rating.partnershipRole,
        'eventCategory': event?.category,
        'localityCode': event?.localityCode?.trim(),
      }),
      requiredAirGapBindingKeys: const <String>[
        'eventId',
        'ratedId',
        'overallRating',
        'wouldPartnerAgain',
        'partnershipRole',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'partner_rating_intake',
        'surface': 'post_event_feedback',
        'channel': 'partner_rating',
        'partnerRating': rating.toJson(),
        'eventSummary': event == null ? null : _safeEventSummary(event),
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      cityCode: event?.cityCode,
      localityCode: event?.localityCode,
    );
  }

  Future<GovernedUpwardLearningIntakeResult> stageEventOutcomeIntake({
    required ExpertiseEvent event,
    required EventCreationLearningSignal signal,
    required UpwardAirGapArtifact airGapArtifact,
  }) {
    final payload = signal.boundedPayload;
    final upwardDomainHints = _extractEventOutcomeDomainHints(
      event: event,
      payload: payload,
    );
    final upwardReferencedEntities = <String>[
      event.id,
      event.title,
      event.category,
      ...event.spots.map((spot) => spot.id),
    ]..sort();
    final upwardQuestions = <String>[
      'Did the real-world event outcome corroborate the planning assumptions?',
      if ((payload['average_rating'] as num?)?.toDouble() case final rating?
          when rating < 4.0)
        'Which aspects of the event outcome should challenge current event or venue convictions?',
    ];
    final upwardPreferenceSignals = <Map<String, dynamic>>[
      if (payload['attendance_rate'] != null)
        <String, dynamic>{
          'kind': 'event_attendance_rate',
          'value': payload['attendance_rate'].toString(),
          'confidence': 0.84,
        },
      if (payload['average_rating'] != null)
        <String, dynamic>{
          'kind': 'event_average_rating',
          'value': payload['average_rating'].toString(),
          'confidence': 0.84,
        },
      if (payload['would_attend_again_rate'] != null)
        <String, dynamic>{
          'kind': 'event_return_intent_rate',
          'value': payload['would_attend_again_rate'].toString(),
          'confidence': 0.82,
        },
    ];
    final upwardSignalTags = <String>{
      'surface:event_outcome_learning',
      'source:event_outcome',
      'signal:${signal.kind.name}',
      ...upwardDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: signal.hostUserId,
      sourceProvider: 'event_outcome_intake',
      sourceLabel: 'Event outcome upward learning',
      title: 'Upward learning review: event outcome',
      summary: _buildEventOutcomeSummary(event: event, payload: payload),
      stableRef: signal.signalId,
      occurredAtUtc: signal.createdAt.toUtc(),
      convictionTier: _eventOutcomeConvictionTier(payload),
      hierarchyPath: const <String>[
        'human',
        'personal_agent',
        'event',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'sourceKind': 'event_outcome_intake',
        'eventId': event.id,
        'signalKind': signal.kind.name,
        ...payload,
      }),
      requiredAirGapBindingKeys: const <String>['eventId', 'signalKind'],
      payload: <String, dynamic>{
        'sourceKind': 'event_outcome_intake',
        'surface': 'event_outcome_learning',
        'channel': signal.kind.name,
        'eventLearningSignal': signal.toJson(),
        'upwardDomainHints': upwardDomainHints,
        'upwardReferencedEntities': upwardReferencedEntities,
        'upwardQuestions': upwardQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': upwardSignalTags,
      },
      airGapArtifact: airGapArtifact,
      cityCode: event.cityCode,
      localityCode: event.localityCode,
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageSupervisorAssistantObservationIntake({
    required String observerId,
    required String observerKind,
    required DateTime occurredAtUtc,
    required String summary,
    required UpwardAirGapArtifact airGapArtifact,
    String? environmentId,
    String? cityCode,
    String? localityCode,
    String? observationKind,
    List<String> upwardDomainHints = const <String>[],
    List<String> upwardReferencedEntities = const <String>[],
    List<String> upwardQuestions = const <String>[],
    List<Map<String, dynamic>> upwardPreferenceSignals =
        const <Map<String, dynamic>>[],
    List<String> upwardSignalTags = const <String>[],
    Map<String, dynamic> boundedMetadata = const <String, dynamic>{},
  }) {
    final normalizedObserverKind = observerKind.trim().toLowerCase();
    final sourceProvider = normalizedObserverKind == 'assistant'
        ? 'assistant_bounded_observation_intake'
        : 'supervisor_bounded_observation_intake';
    final normalizedObservationKind =
        (observationKind?.trim().isNotEmpty ?? false)
            ? observationKind!.trim()
            : 'bounded_observation';
    final normalizedDomainHints = <String>{
      normalizedObserverKind,
      ...upwardDomainHints.map((value) => value.trim()).where(
            (value) => value.isNotEmpty,
          ),
    }.toList()
      ..sort();
    final normalizedReferencedEntities = upwardReferencedEntities
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final normalizedQuestions = upwardQuestions
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final normalizedSignalTags = <String>{
      'source:$normalizedObserverKind',
      'observation_kind:$normalizedObservationKind',
      ...upwardSignalTags.map((value) => value.trim()).where(
            (value) => value.isNotEmpty,
          ),
      ...normalizedDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: observerId,
      sourceProvider: sourceProvider,
      sourceLabel:
          '${normalizedObserverKind[0].toUpperCase()}${normalizedObserverKind.substring(1)} bounded observation upward learning',
      title:
          'Upward learning review: $normalizedObserverKind bounded observation',
      summary: summary.trim(),
      stableRef:
          '${normalizedObserverKind}_${normalizedObservationKind}_${occurredAtUtc.toUtc().microsecondsSinceEpoch}',
      occurredAtUtc: occurredAtUtc,
      convictionTier: '${normalizedObserverKind}_bounded_observation_signal',
      hierarchyPath: <String>[
        normalizedObserverKind,
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'observationKind': normalizedObservationKind,
        'summary': summary.trim(),
        'boundedMetadata': boundedMetadata,
        'upwardDomainHints': normalizedDomainHints,
        'upwardReferencedEntities': normalizedReferencedEntities,
        'upwardQuestions': normalizedQuestions,
        'upwardSignalTags': normalizedSignalTags,
        'environmentId': environmentId,
        'cityCode': cityCode,
        'localityCode': localityCode,
      }),
      requiredAirGapBindingKeys: const <String>[
        'observationKind',
        'summary',
      ],
      payload: <String, dynamic>{
        'sourceKind': sourceProvider,
        'surface': '${normalizedObserverKind}_bounded_observation',
        'channel': normalizedObservationKind,
        'environmentId': environmentId,
        'observationKind': normalizedObservationKind,
        'boundedMetadata': boundedMetadata,
        'upwardDomainHints': normalizedDomainHints,
        'upwardReferencedEntities': normalizedReferencedEntities,
        'upwardQuestions': normalizedQuestions,
        'upwardPreferenceSignals': upwardPreferenceSignals,
        'upwardSignalTags': normalizedSignalTags,
      },
      airGapArtifact: airGapArtifact,
      cityCode: cityCode,
      localityCode: localityCode,
    );
  }

  Future<GovernedUpwardLearningIntakeResult>
      stageKernelOfflineEvidenceReceiptIntake({
    required String ownerUserId,
    required KernelOfflineEvidenceReceipt receipt,
    required UpwardAirGapArtifact airGapArtifact,
  }) {
    final normalizedDomainHints = <String>{
      'kernel',
      'offline',
      if (receipt.kernelId?.trim().isNotEmpty ?? false) 'runtime_kernel',
      if (receipt.localityCode?.trim().isNotEmpty ?? false) 'locality',
    }.toList()
      ..sort();
    final normalizedReferencedEntities = <String>[
      receipt.receiptId,
      receipt.receiptKind,
      receipt.sourceSystem,
      if (receipt.kernelId?.trim().isNotEmpty ?? false)
        receipt.kernelId!.trim(),
      if (receipt.requestId?.trim().isNotEmpty ?? false)
        receipt.requestId!.trim(),
      if (receipt.lineageRef?.trim().isNotEmpty ?? false)
        receipt.lineageRef!.trim(),
    ]..sort();
    final normalizedQuestions = <String>[
      'Should this kernel or offline evidence receipt materially reinforce an existing conviction or only remain as corroborating evidence?',
      if (receipt.temporalLineage.isNotEmpty)
        'Does the receipt timing show delayed sync, offline custody, or another temporal condition the reality model should preserve?',
      if ((receipt.boundedEvidence['validationStatus']
              ?.toString()
              .trim()
              .isNotEmpty ??
          false))
        'Should the bounded validation status from this receipt reopen any review or simulation lane?',
    ]..sort();
    final normalizedPreferenceSignals = <Map<String, dynamic>>[
      <String, dynamic>{
        'kind': 'kernel_offline_receipt_kind',
        'value': receipt.receiptKind,
        'confidence': 0.84,
      },
      <String, dynamic>{
        'kind': 'kernel_offline_source_system',
        'value': receipt.sourceSystem,
        'confidence': 0.82,
      },
      <String, dynamic>{
        'kind': 'kernel_offline_source_plane',
        'value': receipt.sourcePlane,
        'confidence': 0.82,
      },
      if (receipt.actorScope?.trim().isNotEmpty ?? false)
        <String, dynamic>{
          'kind': 'kernel_offline_actor_scope',
          'value': receipt.actorScope!.trim(),
          'confidence': 0.78,
        },
    ];
    final normalizedSignalTags = <String>{
      'source:kernel_offline_evidence_receipt',
      'receipt_kind:${receipt.receiptKind}',
      'source_system:${receipt.sourceSystem}',
      'source_plane:${receipt.sourcePlane}',
      ...receipt.signalTags.map((value) => value.trim()).where(
            (value) => value.isNotEmpty,
          ),
      ...normalizedDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();

    return _stage(
      ownerUserId: ownerUserId,
      sourceProvider: 'kernel_offline_evidence_receipt_intake',
      sourceLabel: 'Kernel/offline evidence receipt upward learning',
      title: 'Upward learning review: kernel/offline evidence receipt',
      summary:
          'Kernel/offline evidence receipt `${receipt.receiptKind}` from `${receipt.sourceSystem}` observed at ${receipt.observedAtUtc.toUtc().toIso8601String()}.',
      stableRef: receipt.receiptId,
      occurredAtUtc: receipt.observedAtUtc,
      convictionTier: 'kernel_offline_evidence_receipt_signal',
      hierarchyPath: const <String>[
        'kernel',
        'reality_model_agent',
      ],
      airGapRequestBinding: _buildAirGapRequestBinding(<String, dynamic>{
        'receiptId': receipt.receiptId,
        'receiptKind': receipt.receiptKind,
        'sourceSystem': receipt.sourceSystem,
        'kernelId': receipt.kernelId,
        'requestId': receipt.requestId,
      }),
      requiredAirGapBindingKeys: const <String>[
        'receiptId',
        'receiptKind',
        'sourceSystem',
      ],
      payload: <String, dynamic>{
        'sourceKind': 'kernel_offline_evidence_receipt_intake',
        'surface': 'kernel_offline_receipt',
        'channel': receipt.receiptKind,
        'kernelOfflineEvidenceReceipt': receipt.toJson(),
        'upwardDomainHints': normalizedDomainHints,
        'upwardReferencedEntities': normalizedReferencedEntities,
        'upwardQuestions': normalizedQuestions,
        'upwardPreferenceSignals': normalizedPreferenceSignals,
        'upwardSignalTags': normalizedSignalTags,
      },
      airGapArtifact: airGapArtifact,
      cityCode: receipt.cityCode,
      localityCode: receipt.localityCode,
    );
  }

  Future<GovernedUpwardLearningIntakeResult> _stage({
    required String ownerUserId,
    required String sourceProvider,
    required String sourceLabel,
    required String title,
    required String summary,
    required String stableRef,
    required DateTime occurredAtUtc,
    required String convictionTier,
    required List<String> hierarchyPath,
    UpwardAirGapArtifact? airGapArtifact,
    Map<String, dynamic> airGapRequestBinding = const <String, dynamic>{},
    List<String> requiredAirGapBindingKeys = const <String>[],
    required Map<String, dynamic> payload,
    String? cityCode,
    String? localityCode,
  }) async {
    final atomic = await _atomicClockService.getAtomicTimestamp();
    final stagedAtUtc = atomic.serverTime.toUtc();
    final sourceId = '$sourceProvider:$ownerUserId:$stableRef';
    final jobId = '$sourceId:job';
    final reviewItemId = '$sourceId:review';
    final governedLearningEnvelopeId = 'gle:$sourceId';
    final kernelGraphSpecId = 'kernel_graph:$sourceId';
    final kernelGraphRunId = '$kernelGraphSpecId:run';
    final temporalLineage = <String, dynamic>{
      'originOccurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
      'localStateCapturedAtUtc': atomic.deviceTime.toUtc().toIso8601String(),
      'kernelReviewedAtUtc': stagedAtUtc.toIso8601String(),
      'upwardQueuedAtUtc': stagedAtUtc.toIso8601String(),
      'atomicTimestamp': atomic.toJson(),
    };
    final sourceKind = payload['sourceKind']?.toString() ?? sourceProvider;
    final blockedSignalKey = _signalPolicyService?.buildSignalKey(
      convictionTier: convictionTier,
      sourceProvider: sourceProvider,
    );
    final signalBlocked = _signalPolicyService == null
        ? false
        : await _signalPolicyService.isSignalBlocked(
            ownerUserId: ownerUserId,
            convictionTier: convictionTier,
            sourceProvider: sourceProvider,
          );
    final requiresCallerIssuedAirGap =
        callerIssuedAirGapSourceProviders.contains(sourceProvider);
    if (requiresCallerIssuedAirGap && airGapArtifact == null) {
      throw StateError(
        'caller-issued airGapArtifact is required for $sourceProvider',
      );
    }
    final effectiveAirGapArtifact = airGapArtifact ??
        _upwardAirGapService.issueArtifact(
          originPlane: _deriveOriginPlane(
            sourceProvider: sourceProvider,
            hierarchyPath: hierarchyPath,
          ),
          sourceKind: sourceKind,
          sourceScope: hierarchyPath.isEmpty ? 'unknown' : hierarchyPath.first,
          destinationCeiling: 'reality_model_agent',
          issuedAtUtc: stagedAtUtc,
          sanitizedPayload: <String, dynamic>{
            'ownerUserIdHashRef': _pseudonymousOwnerRef(ownerUserId),
            'sourceProvider': sourceProvider,
            'sourceKind': sourceKind,
            'convictionTier': convictionTier,
            'hierarchyPath': hierarchyPath,
            if (cityCode != null) 'cityCode': cityCode,
            if (localityCode != null) 'localityCode': localityCode,
            'payload': payload,
          },
          pseudonymousActorRef: _safePseudonymousActorRef(payload),
        );
    final airGapViolations = _upwardAirGapService.validateArtifact(
      artifact: effectiveAirGapArtifact,
      nowUtc: stagedAtUtc,
      destinationCeiling: 'reality_model_agent',
      requiredNextStage: requiredAirGapNextStage,
    );
    if (airGapViolations.isNotEmpty) {
      throw StateError(
        'Invalid airGapArtifact for $sourceProvider: ${airGapViolations.join(' | ')}',
      );
    }
    final airGapBindingViolations = _validateAirGapRequestBinding(
      artifact: effectiveAirGapArtifact,
      requestBinding: airGapRequestBinding,
      requiredKeys: requiredAirGapBindingKeys,
    );
    if (airGapBindingViolations.isNotEmpty) {
      throw StateError(
        'airGapArtifact request binding mismatch for $sourceProvider: ${airGapBindingViolations.join(' | ')}',
      );
    }
    final reviewArtifactLifecycle = _buildGovernedArtifactLifecycle(
      sourceProvider: sourceProvider,
      hierarchyPath: hierarchyPath,
      sourceRefs: <String>[
        effectiveAirGapArtifact.receiptId,
        sourceId,
      ],
      evaluationRefs: <String>[
        kernelGraphSpecId,
        kernelGraphRunId,
      ],
    );
    final jobArtifactLifecycle = _buildGovernedJobLifecycle(
      sourceProvider: sourceProvider,
      hierarchyPath: hierarchyPath,
      sourceRefs: <String>[
        sourceId,
        reviewItemId,
      ],
      evaluationRefs: <String>[
        kernelGraphSpecId,
        kernelGraphRunId,
      ],
    );
    final sharedPayload = <String, dynamic>{
      'queueKind': upwardQueueKind,
      'learningDirection': learningDirection,
      'learningPathway': learningPathway,
      'convictionTier': convictionTier,
      'hierarchyPath': hierarchyPath,
      'safeSummary': summary,
      'kernelExchangePhase': 'queued_upward_learning_review',
      'temporalLineage': temporalLineage,
      'governedLearningEnvelopeId': governedLearningEnvelopeId,
      'kernelGraphSpecId': kernelGraphSpecId,
      'kernelGraphRunId': kernelGraphRunId,
      'kernelGraphVersion': upwardKernelGraphVersion,
      'kernelGraphKind': KernelGraphKind.learningIntake.name,
      'kernelGraphEnvironment': KernelGraphExecutionEnvironment.runtime.name,
      'kernelGraphRequiresHumanReview': true,
      'airGapRequired': true,
      'airGapArtifactVersion': upwardAirGapArtifactVersion,
      'airGapReceiptId': effectiveAirGapArtifact.receiptId,
      'airGapContentSha256': effectiveAirGapArtifact.contentSha256,
      'airGapIssuedAtUtc':
          effectiveAirGapArtifact.issuedAtUtc.toIso8601String(),
      'airGapExpiresAtUtc':
          effectiveAirGapArtifact.expiresAtUtc.toIso8601String(),
      'airGapOriginPlane': effectiveAirGapArtifact.originPlane,
      'airGapAllowedNextStages': effectiveAirGapArtifact.allowedNextStages,
      'airGapAttestation': effectiveAirGapArtifact.attestation,
      'airGapArtifact': effectiveAirGapArtifact.toJson(),
      'artifactLifecycle': reviewArtifactLifecycle.toJson(),
      if (signalBlocked) 'signalSuppressedByUserPolicy': true,
      if (blockedSignalKey != null) 'blockedSignalKey': blockedSignalKey,
      ...payload,
    };
    if (signalBlocked) {
      final envelope = _buildGovernedLearningEnvelope(
        envelopeId: governedLearningEnvelopeId,
        ownerUserId: ownerUserId,
        sourceId: sourceId,
        reviewItemId: reviewItemId,
        jobId: jobId,
        sourceProvider: sourceProvider,
        sourceKind: sourceKind,
        sourceLabel: sourceLabel,
        title: title,
        summary: summary,
        occurredAtUtc: occurredAtUtc,
        stagedAtUtc: stagedAtUtc,
        convictionTier: convictionTier,
        hierarchyPath: hierarchyPath,
        temporalLineage: <String, dynamic>{
          ...temporalLineage,
          'signalSuppressedAtUtc': stagedAtUtc.toIso8601String(),
        },
        sharedPayload: sharedPayload,
        airGapArtifact: effectiveAirGapArtifact,
        kernelGraphSpecId: kernelGraphSpecId,
        kernelGraphRunId: kernelGraphRunId,
        kernelGraphStatus: KernelGraphRunStatus.failed,
        kernelGraphAdminDigest: KernelGraphAdminDigest(
          runId: kernelGraphRunId,
          specId: kernelGraphSpecId,
          graphTitle: 'Governed upward learning intake',
          kind: KernelGraphKind.learningIntake,
          status: KernelGraphRunStatus.failed,
          summary:
              'Governed upward learning intake was suppressed by user policy before kernel graph execution.',
          requiresHumanReview: false,
          completedNodeCount: 0,
          totalNodeCount: 0,
          lineageRefs: <String>[sourceId],
          rollbackRefs: <String>['$kernelGraphRunId:rollback'],
          metadata: <String, dynamic>{
            'signalSuppressedByUserPolicy': true,
            if (blockedSignalKey != null) 'blockedSignalKey': blockedSignalKey,
            'suppressedAtUtc': stagedAtUtc.toIso8601String(),
          },
        ),
        cityCode: cityCode,
        localityCode: localityCode,
      ).copyWith(
        kernelGraphSpecId: null,
        kernelGraphRunId: null,
        kernelGraphStatus: null,
        kernelGraphAdminDigest: null,
        metadata: <String, dynamic>{
          ...sharedPayload,
          'signalSuppressedByUserPolicy': true,
          if (blockedSignalKey != null) 'blockedSignalKey': blockedSignalKey,
        },
      );

      return GovernedUpwardLearningIntakeResult(
        sourceId: sourceId,
        reviewItemId: reviewItemId,
        jobId: jobId,
        temporalLineage: <String, dynamic>{
          ...temporalLineage,
          'signalSuppressedAtUtc': stagedAtUtc.toIso8601String(),
        },
        convictionTier: convictionTier,
        learningPathway: learningPathway,
        envelope: envelope,
      );
    }

    final sourceDescriptor = ExternalSourceDescriptor(
      id: sourceId,
      ownerUserId: ownerUserId,
      sourceProvider: sourceProvider,
      connectionMode: ExternalConnectionMode.manual,
      entityHint: IntakeEntityType.review,
      sourceLabel: sourceLabel,
      cityCode: cityCode,
      localityCode: localityCode,
      createdAt: stagedAtUtc,
      updatedAt: stagedAtUtc,
      lastSyncedAt: stagedAtUtc,
      syncState: ExternalSyncState.needsReview,
      metadata: sharedPayload,
      lifecycle: reviewArtifactLifecycle,
    );
    final syncJob = ExternalSyncJob(
      id: jobId,
      sourceId: sourceId,
      startedAt: stagedAtUtc,
      updatedAt: stagedAtUtc,
      state: ExternalSyncState.needsReview,
      importedCount: 0,
      reviewCount: 1,
      lifecycle: jobArtifactLifecycle,
    );
    final reviewItem = OrganizerReviewItem(
      id: reviewItemId,
      sourceId: sourceId,
      ownerUserId: ownerUserId,
      targetType: IntakeEntityType.review,
      title: title,
      summary: summary,
      missingFields: const <String>[],
      createdAt: stagedAtUtc,
      payload: sharedPayload,
      lifecycle: reviewArtifactLifecycle,
    );
    final kernelGraphSpec = _buildUpwardLearningKernelGraphSpec(
      specId: kernelGraphSpecId,
      title: title,
      ownerUserId: ownerUserId,
      sourceDescriptor: sourceDescriptor,
      syncJob: syncJob,
      reviewItem: reviewItem,
      lineageRefs: <String>[
        sourceId,
        jobId,
        reviewItemId,
      ],
    );
    final kernelGraphResult = await _kernelGraphRunner.executeSpec(
      kernelGraphSpec,
      runId: kernelGraphRunId,
      rollbackDescriptor: KernelGraphRollbackDescriptor(
        id: '$kernelGraphRunId:rollback',
        strategy: 'idempotent_intake_review_upserts',
        refs: <String>[
          sourceId,
          jobId,
          reviewItemId,
        ],
        metadata: <String, dynamic>{
          'ownerUserId': ownerUserId,
          'learningPathway': learningPathway,
          'artifactLifecycle': jobArtifactLifecycle.toJson(),
        },
      ),
      initialState: <String, dynamic>{
        'ownerUserId': ownerUserId,
        'sourceId': sourceId,
        'jobId': jobId,
        'reviewItemId': reviewItemId,
      },
      runMetadata: <String, dynamic>{
        'ownerUserId': ownerUserId,
        'sourceId': sourceId,
        'jobId': jobId,
        'reviewItemId': reviewItemId,
        'sourceProvider': sourceProvider,
        'sourceLabel': sourceLabel,
        'sourceKind': sourceKind,
        'learningDirection': learningDirection,
        'learningPathway': learningPathway,
        'convictionTier': convictionTier,
        'queueKind': upwardQueueKind,
        'airGapReceiptId': effectiveAirGapArtifact.receiptId,
        'airGapContentSha256': effectiveAirGapArtifact.contentSha256,
        if (cityCode != null) 'cityCode': cityCode,
        if (localityCode != null) 'localityCode': localityCode,
      },
    );
    final envelope = _buildGovernedLearningEnvelope(
      envelopeId: governedLearningEnvelopeId,
      ownerUserId: ownerUserId,
      sourceId: sourceId,
      reviewItemId: reviewItemId,
      jobId: jobId,
      sourceProvider: sourceProvider,
      sourceKind: sourceKind,
      sourceLabel: sourceLabel,
      title: title,
      summary: summary,
      occurredAtUtc: occurredAtUtc,
      stagedAtUtc: stagedAtUtc,
      convictionTier: convictionTier,
      hierarchyPath: hierarchyPath,
      temporalLineage: temporalLineage,
      sharedPayload: sharedPayload,
      airGapArtifact: effectiveAirGapArtifact,
      kernelGraphSpecId: kernelGraphSpecId,
      kernelGraphRunId: kernelGraphRunId,
      kernelGraphStatus: kernelGraphResult.receipt.status,
      kernelGraphAdminDigest: kernelGraphResult.adminDigest,
      cityCode: cityCode,
      localityCode: localityCode,
    );
    await _persistGovernedLearningEnvelope(
      sourceDescriptor: sourceDescriptor,
      reviewItem: reviewItem,
      sharedPayload: sharedPayload,
      stagedAtUtc: stagedAtUtc,
      envelope: envelope,
    );

    return GovernedUpwardLearningIntakeResult(
      sourceId: sourceId,
      reviewItemId: reviewItemId,
      jobId: jobId,
      temporalLineage: temporalLineage,
      convictionTier: convictionTier,
      learningPathway: learningPathway,
      envelope: envelope,
      kernelGraphSpecId: kernelGraphSpecId,
      kernelGraphRunId: kernelGraphRunId,
      kernelGraphStatus: kernelGraphResult.receipt.status,
      kernelGraphAdminDigest: kernelGraphResult.adminDigest,
    );
  }

  GovernedLearningEnvelope _buildGovernedLearningEnvelope({
    required String envelopeId,
    required String ownerUserId,
    required String sourceId,
    required String reviewItemId,
    required String jobId,
    required String sourceProvider,
    required String sourceKind,
    required String sourceLabel,
    required String title,
    required String summary,
    required DateTime occurredAtUtc,
    required DateTime stagedAtUtc,
    required String convictionTier,
    required List<String> hierarchyPath,
    required Map<String, dynamic> temporalLineage,
    required Map<String, dynamic> sharedPayload,
    required UpwardAirGapArtifact airGapArtifact,
    required String kernelGraphSpecId,
    required String kernelGraphRunId,
    required KernelGraphRunStatus kernelGraphStatus,
    required KernelGraphAdminDigest kernelGraphAdminDigest,
    String? cityCode,
    String? localityCode,
  }) {
    return GovernedLearningEnvelope(
      id: envelopeId,
      ownerUserId: ownerUserId,
      sourceId: sourceId,
      reviewItemId: reviewItemId,
      jobId: jobId,
      sourceProvider: sourceProvider,
      sourceKind: sourceKind,
      sourceLabel: sourceLabel,
      title: title,
      safeSummary: summary,
      queueKind: upwardQueueKind,
      learningDirection: learningDirection,
      learningPathway: learningPathway,
      convictionTier: convictionTier,
      hierarchyPath: List<String>.from(hierarchyPath),
      occurredAtUtc: occurredAtUtc.toUtc(),
      stagedAtUtc: stagedAtUtc.toUtc(),
      requiresHumanReview: true,
      temporalLineage: Map<String, dynamic>.from(temporalLineage),
      cityCode: cityCode,
      localityCode: localityCode,
      surface: sharedPayload['surface']?.toString(),
      channel: sharedPayload['channel']?.toString(),
      domainHints: _stringListValue(sharedPayload['upwardDomainHints']),
      referencedEntities: _stringListValue(
        sharedPayload['upwardReferencedEntities'],
      ),
      questions: _stringListValue(sharedPayload['upwardQuestions']),
      preferenceSignals: _mapListValue(
        sharedPayload['upwardPreferenceSignals'],
      ),
      signalTags: _stringListValue(sharedPayload['upwardSignalTags']),
      kernelGraphSpecId: kernelGraphSpecId,
      kernelGraphRunId: kernelGraphRunId,
      kernelGraphStatus: kernelGraphStatus,
      kernelGraphAdminDigest: kernelGraphAdminDigest,
      airGap: GovernedLearningAirGapSummary(
        artifactVersion: airGapArtifact.artifactVersion,
        receiptId: airGapArtifact.receiptId,
        contentSha256: airGapArtifact.contentSha256,
        originPlane: airGapArtifact.originPlane,
        sourceScope: airGapArtifact.sourceScope,
        destinationCeiling: airGapArtifact.destinationCeiling,
        issuedAtUtc: airGapArtifact.issuedAtUtc,
        expiresAtUtc: airGapArtifact.expiresAtUtc,
        allowedNextStages: airGapArtifact.allowedNextStages,
        pseudonymousActorRef: airGapArtifact.pseudonymousActorRef,
      ),
      metadata: <String, dynamic>{
        'kernelExchangePhase':
            sharedPayload['kernelExchangePhase']?.toString() ??
                'queued_upward_learning_review',
        'artifactLifecycle': sharedPayload['artifactLifecycle'],
        if (sharedPayload['correctionIntent'] != null)
          'correctionIntent': sharedPayload['correctionIntent'],
        if (sharedPayload['correctionSource'] != null)
          'correctionSource': sharedPayload['correctionSource'],
      },
    );
  }

  Future<void> _persistGovernedLearningEnvelope({
    required ExternalSourceDescriptor sourceDescriptor,
    required OrganizerReviewItem reviewItem,
    required Map<String, dynamic> sharedPayload,
    required DateTime stagedAtUtc,
    required GovernedLearningEnvelope envelope,
  }) async {
    final persistedPayload = Map<String, dynamic>.from(sharedPayload)
      ..['governedLearningEnvelope'] = envelope.toJson()
      ..['kernelGraphStatus'] = envelope.kernelGraphStatus?.name
      ..['kernelGraphAdminDigest'] = envelope.kernelGraphAdminDigest?.toJson();
    await _intakeRepository.upsertSource(
      sourceDescriptor.copyWith(
        updatedAt: stagedAtUtc,
        lastSyncedAt: stagedAtUtc,
        metadata: persistedPayload,
      ),
    );
    await _intakeRepository.upsertReviewItem(
      OrganizerReviewItem(
        id: reviewItem.id,
        sourceId: reviewItem.sourceId,
        ownerUserId: reviewItem.ownerUserId,
        targetType: reviewItem.targetType,
        title: reviewItem.title,
        summary: reviewItem.summary,
        missingFields: reviewItem.missingFields,
        createdAt: reviewItem.createdAt,
        payload: persistedPayload,
        lifecycle: reviewItem.lifecycle,
      ),
    );
  }

  ArtifactLifecycleMetadata _buildGovernedArtifactLifecycle({
    required String sourceProvider,
    required List<String> hierarchyPath,
    List<String> sourceRefs = const <String>[],
    List<String> evaluationRefs = const <String>[],
  }) {
    return ArtifactLifecycleMetadata(
      artifactClass: ArtifactLifecycleClass.canonical,
      artifactState: ArtifactLifecycleState.candidate,
      retentionPolicy: const ArtifactRetentionPolicy(
        mode: ArtifactRetentionMode.keepForever,
      ),
      artifactFamily: 'governed_upward_learning_review',
      sourceScope: hierarchyPath.isEmpty ? 'unknown' : hierarchyPath.first,
      provenanceRefs: _normalizedLifecycleRefs(<String>[
        sourceProvider,
        ...sourceRefs,
      ]),
      evaluationRefs: _normalizedLifecycleRefs(evaluationRefs),
      containsRawPersonalPayload: _sourceProviderContainsRawPersonalPayload(
        sourceProvider,
      ),
      containsMessageContent: _sourceProviderContainsMessageContent(
        sourceProvider,
      ),
    );
  }

  ArtifactLifecycleMetadata _buildGovernedJobLifecycle({
    required String sourceProvider,
    required List<String> hierarchyPath,
    List<String> sourceRefs = const <String>[],
    List<String> evaluationRefs = const <String>[],
  }) {
    return ArtifactLifecycleMetadata(
      artifactClass: ArtifactLifecycleClass.staging,
      artifactState: ArtifactLifecycleState.accepted,
      retentionPolicy: const ArtifactRetentionPolicy(
        mode: ArtifactRetentionMode.keepForever,
      ),
      artifactFamily: 'governed_upward_learning_job',
      sourceScope: hierarchyPath.isEmpty ? 'unknown' : hierarchyPath.first,
      provenanceRefs: _normalizedLifecycleRefs(<String>[
        sourceProvider,
        ...sourceRefs,
      ]),
      evaluationRefs: _normalizedLifecycleRefs(evaluationRefs),
      containsRawPersonalPayload: false,
      containsMessageContent: false,
    );
  }

  Map<String, dynamic> _buildAirGapRequestBinding(
    Map<String, dynamic> rawBinding,
  ) {
    final binding = <String, dynamic>{};
    for (final entry in rawBinding.entries) {
      if (entry.value == null) {
        continue;
      }
      binding[entry.key] = entry.value;
    }
    return binding;
  }

  List<String> _validateAirGapRequestBinding({
    required UpwardAirGapArtifact artifact,
    required Map<String, dynamic> requestBinding,
    required List<String> requiredKeys,
  }) {
    if (requestBinding.isEmpty && requiredKeys.isEmpty) {
      return const <String>[];
    }
    final normalizedPayload = _normalizeAirGapBindingMap(
      artifact.sanitizedPayload,
    );
    final normalizedRequest = _normalizeAirGapBindingMap(requestBinding);
    final requiredKeySet = requiredKeys.map((value) => value.trim()).toSet()
      ..removeWhere((value) => value.isEmpty);
    final violations = <String>[];
    final availableBindingKeys = <String>{
      ...normalizedPayload.keys,
    }.intersection(<String>{
      ...normalizedRequest.keys,
      ...requiredKeySet,
    });

    if (availableBindingKeys.isEmpty) {
      return const <String>[];
    }

    for (final key in requiredKeySet) {
      if (!normalizedRequest.containsKey(key)) {
        violations.add('request binding omitted required key `$key`');
        continue;
      }
      if (!normalizedPayload.containsKey(key)) {
        violations.add('sanitizedPayload missing required binding `$key`');
        continue;
      }
      if (!_airGapBindingValuesEqual(
        normalizedPayload[key],
        normalizedRequest[key],
      )) {
        violations
            .add('sanitizedPayload `$key` does not match current request');
      }
    }

    for (final entry in normalizedRequest.entries) {
      if (requiredKeySet.contains(entry.key)) {
        continue;
      }
      if (!normalizedPayload.containsKey(entry.key)) {
        continue;
      }
      if (!_airGapBindingValuesEqual(
        normalizedPayload[entry.key],
        entry.value,
      )) {
        violations.add(
          'sanitizedPayload `${entry.key}` does not match current request',
        );
      }
    }

    return violations;
  }

  Map<String, dynamic> _normalizeAirGapBindingMap(
      Map<String, dynamic> payload) {
    final keys = payload.keys.toList()..sort();
    final normalized = <String, dynamic>{};
    for (final key in keys) {
      final value = payload[key];
      if (value == null) {
        continue;
      }
      normalized[key] = _normalizeAirGapBindingValue(value);
    }
    return normalized;
  }

  dynamic _normalizeAirGapBindingValue(dynamic value) {
    if (value is Map) {
      return _normalizeAirGapBindingMap(
        Map<String, dynamic>.from(
          value.map(
            (key, nestedValue) => MapEntry(key.toString(), nestedValue),
          ),
        ),
      );
    }
    if (value is List) {
      return value.map(_normalizeAirGapBindingValue).toList(growable: false);
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    return value;
  }

  bool _airGapBindingValuesEqual(dynamic left, dynamic right) {
    if (left is Map<String, dynamic> && right is Map<String, dynamic>) {
      if (left.length != right.length) {
        return false;
      }
      for (final entry in left.entries) {
        if (!right.containsKey(entry.key)) {
          return false;
        }
        if (!_airGapBindingValuesEqual(right[entry.key], entry.value)) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) {
        return false;
      }
      for (var index = 0; index < left.length; index++) {
        if (!_airGapBindingValuesEqual(left[index], right[index])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }

  List<String> _normalizedLifecycleRefs(List<String> refs) {
    return refs
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  bool _sourceProviderContainsRawPersonalPayload(String sourceProvider) {
    return sourceProvider.startsWith('personal_agent_') ||
        sourceProvider == 'onboarding_intake' ||
        sourceProvider == 'recommendation_feedback_intake' ||
        sourceProvider == 'recommendation_feedback_follow_up_response_intake' ||
        sourceProvider == 'explicit_correction_follow_up_response_intake' ||
        sourceProvider == 'visit_locality_follow_up_response_intake' ||
        sourceProvider == 'community_follow_up_response_intake' ||
        sourceProvider == 'business_operator_follow_up_response_intake' ||
        sourceProvider == 'saved_discovery_curation_intake' ||
        sourceProvider == 'business_operator_input_intake' ||
        sourceProvider == 'community_coordination_intake' ||
        sourceProvider == 'community_validation_intake' ||
        sourceProvider == 'reservation_sharing_intake' ||
        sourceProvider == 'reservation_calendar_sync_intake' ||
        sourceProvider == 'reservation_recurrence_intake' ||
        sourceProvider == 'visit_observation_intake' ||
        sourceProvider == 'locality_observation_intake' ||
        sourceProvider == 'event_feedback_intake' ||
        sourceProvider == 'partner_rating_intake' ||
        sourceProvider == 'event_outcome_intake' ||
        sourceProvider == 'explicit_correction_intake';
  }

  bool _sourceProviderContainsMessageContent(String sourceProvider) {
    return sourceProvider == 'ai2ai_chat_intake' ||
        sourceProvider == 'personal_agent_human_intake';
  }

  KernelGraphSpec _buildUpwardLearningKernelGraphSpec({
    required String specId,
    required String title,
    required String ownerUserId,
    required ExternalSourceDescriptor sourceDescriptor,
    required ExternalSyncJob syncJob,
    required OrganizerReviewItem reviewItem,
    required List<String> lineageRefs,
  }) {
    return KernelGraphSpec(
      id: specId,
      title: 'Governed upward learning intake: $title',
      kind: KernelGraphKind.learningIntake,
      version: upwardKernelGraphVersion,
      executionPolicy: const KernelGraphExecutionPolicy(
        environment: KernelGraphExecutionEnvironment.runtime,
        requiresHumanReview: true,
        allowedMutableSurfaces: <String>[
          'intake_repository.sources',
          'intake_repository.jobs',
          'intake_repository.reviews',
        ],
        maxStepCount: 3,
      ),
      metadata: <String, dynamic>{
        'ownerUserId': ownerUserId,
        'learningPathway': learningPathway,
        'queueKind': upwardQueueKind,
        'lineageRefs': lineageRefs,
      },
      nodes: <KernelGraphNodeSpec>[
        KernelGraphNodeSpec(
          id: 'persist_source_descriptor',
          primitiveId: IntakeKernelGraphPrimitives.upsertSourceDescriptor,
          label: 'Persist source descriptor',
          config: <String, dynamic>{
            'descriptor': sourceDescriptor.toJson(),
          },
        ),
        KernelGraphNodeSpec(
          id: 'persist_sync_job',
          primitiveId: IntakeKernelGraphPrimitives.upsertSyncJob,
          label: 'Persist sync job',
          config: <String, dynamic>{
            'job': syncJob.toJson(),
          },
        ),
        KernelGraphNodeSpec(
          id: 'queue_review_item',
          primitiveId: IntakeKernelGraphPrimitives.upsertReviewItem,
          label: 'Queue review item',
          config: <String, dynamic>{
            'reviewItem': reviewItem.toJson(),
          },
        ),
      ],
      edges: const <KernelGraphEdgeSpec>[
        KernelGraphEdgeSpec(
          fromNodeId: 'persist_source_descriptor',
          toNodeId: 'persist_sync_job',
          label: 'source_to_job',
        ),
        KernelGraphEdgeSpec(
          fromNodeId: 'persist_sync_job',
          toNodeId: 'queue_review_item',
          label: 'job_to_review',
        ),
      ],
    );
  }

  List<String> _stringListValue(Object? value) {
    if (value is List) {
      return value
          .map((entry) => entry.toString())
          .where((entry) => entry.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  List<Map<String, dynamic>> _mapListValue(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  String _deriveOriginPlane({
    required String sourceProvider,
    required List<String> hierarchyPath,
  }) {
    if (sourceProvider == 'external_confirmation_import_intake') {
      return 'external_source';
    }
    if (hierarchyPath.contains('ai2ai')) {
      return 'ai2ai_peer';
    }
    if (hierarchyPath.contains('business')) {
      return 'business_operator';
    }
    if (hierarchyPath.contains('community')) {
      return 'community_operator';
    }
    return 'personal_device';
  }

  String _pseudonymousOwnerRef(String ownerUserId) {
    final normalized = ownerUserId.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'owner_anon';
    }
    final compact = normalized.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final prefix = compact.length <= 12 ? compact : compact.substring(0, 12);
    return 'owner_$prefix';
  }

  String? _safeSummary(Map<String, dynamic> boundaryMetadata) {
    final summary =
        boundaryMetadata['sanitized_summary'] ?? boundaryMetadata['summary'];
    final normalized = summary?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String? _safePseudonymousActorRef(Map<String, dynamic> boundaryMetadata) {
    final actorRef = boundaryMetadata['pseudonymous_actor_ref'] ??
        boundaryMetadata['pseudonymousActorRef'];
    final normalized = actorRef?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  List<String> _extractUpwardDomainHints(
    Map<String, dynamic> boundaryMetadata, {
    String? chatScope,
    String? cityCode,
    String? localityCode,
  }) {
    final domains = <String>{};
    if ((localityCode?.trim().isNotEmpty ?? false) ||
        (cityCode?.trim().isNotEmpty ?? false)) {
      domains.add('locality');
    }
    if (chatScope == 'community') {
      domains.add('community');
    }

    void addDomainValue(Object? value) {
      final normalized = value?.toString().trim().toLowerCase();
      if (normalized != null && normalized.isNotEmpty) {
        domains.add(normalized);
      }
    }

    addDomainValue(boundaryMetadata['domain']);
    for (final domain in _extractStringList(boundaryMetadata['domains'])) {
      addDomainValue(domain);
    }

    final hintText = <String>[
      boundaryMetadata['summary']?.toString() ?? '',
      boundaryMetadata['sanitized_summary']?.toString() ?? '',
      ..._extractReferencedEntities(boundaryMetadata),
      ..._extractQuestions(boundaryMetadata),
      ..._extractPreferenceSignals(boundaryMetadata)
          .map((entry) => entry['value']?.toString() ?? ''),
      ..._extractStringList(boundaryMetadata['safe_questions']),
      ..._extractStringList(boundaryMetadata['reason_codes']),
    ].join(' ').toLowerCase();

    void addIfMatches(String domainId, List<String> keywords) {
      for (final keyword in keywords) {
        if (hintText.contains(keyword)) {
          domains.add(domainId);
          return;
        }
      }
    }

    addIfMatches(
        'event', <String>['event', 'concert', 'festival', 'show', 'gig']);
    addIfMatches('place', <String>[
      'place',
      'spot',
      'restaurant',
      'coffee',
      'cafe',
      'park',
      'museum',
      'neighborhood',
      'neighbourhood',
    ]);
    addIfMatches('venue', <String>[
      'venue',
      'capacity',
      'occupancy',
      'door policy',
      'entry line',
      'bar',
      'club',
    ]);
    addIfMatches('business', <String>[
      'business',
      'merchant',
      'owner',
      'store',
      'shop',
      'company',
      'sales',
      'revenue',
      'customer',
      'api',
    ]);
    addIfMatches('list', <String>[
      'list',
      'curation',
      'saved places',
      'top picks',
      'collection',
      'ranked',
    ]);
    addIfMatches('mobility', <String>[
      'mobility',
      'traffic',
      'route',
      'transit',
      'bus',
      'parking',
      'walk',
      'drive',
    ]);
    addIfMatches('community', <String>[
      'community',
      'group',
      'club',
      'member',
      'neighbors',
      'neighbours',
    ]);

    final ordered = domains.toList()..sort();
    return ordered;
  }

  List<String> _extractReferencedEntities(
      Map<String, dynamic> boundaryMetadata) {
    final entities = <String>{
      ..._extractStringList(boundaryMetadata['referenced_entities']),
    };
    final sanitizedArtifact = boundaryMetadata['sanitized_artifact'];
    if (sanitizedArtifact is Map) {
      entities.addAll(_extractStringList(sanitizedArtifact['safe_claims']));
    }
    final ordered = entities.where((entry) => entry.trim().isNotEmpty).toList()
      ..sort();
    return ordered;
  }

  List<String> _extractQuestions(Map<String, dynamic> boundaryMetadata) {
    final questions = <String>{
      ..._extractStringList(boundaryMetadata['questions']),
      ..._extractStringList(boundaryMetadata['safe_questions']),
    };
    final sanitizedArtifact = boundaryMetadata['sanitized_artifact'];
    if (sanitizedArtifact is Map) {
      questions.addAll(_extractStringList(sanitizedArtifact['safe_questions']));
    }
    final ordered = questions.where((entry) => entry.trim().isNotEmpty).toList()
      ..sort();
    return ordered;
  }

  List<Map<String, dynamic>> _extractPreferenceSignals(
    Map<String, dynamic> boundaryMetadata,
  ) {
    final entries = <Map<String, dynamic>>[];
    final seenKeys = <String>{};

    void addEntries(Object? raw) {
      if (raw is! List) {
        return;
      }
      for (final entry in raw) {
        if (entry is! Map) {
          continue;
        }
        final json = Map<String, dynamic>.from(entry);
        final kind = json['kind']?.toString().trim() ?? 'unknown';
        final value = json['value']?.toString().trim() ?? '';
        final key = '$kind::$value';
        if (value.isEmpty || !seenKeys.add(key)) {
          continue;
        }
        entries.add(<String, dynamic>{
          'kind': kind,
          'value': value,
          'confidence': (json['confidence'] as num?)?.toDouble() ?? 0.0,
        });
      }
    }

    addEntries(boundaryMetadata['preference_signals']);
    addEntries(boundaryMetadata['safe_preference_signals']);
    final sanitizedArtifact = boundaryMetadata['sanitized_artifact'];
    if (sanitizedArtifact is Map) {
      addEntries(sanitizedArtifact['safe_preference_signals']);
    }
    entries.sort((a, b) {
      final kindA = a['kind']?.toString() ?? '';
      final kindB = b['kind']?.toString() ?? '';
      final kindComparison = kindA.compareTo(kindB);
      if (kindComparison != 0) {
        return kindComparison;
      }
      return (a['value']?.toString() ?? '')
          .compareTo(b['value']?.toString() ?? '');
    });
    return entries;
  }

  List<String> _extractSignalTags(
    Map<String, dynamic> boundaryMetadata, {
    String? chatScope,
    required List<String> domainHints,
  }) {
    final tags = <String>{};
    final intent = boundaryMetadata['intent']?.toString().trim();
    if (intent != null && intent.isNotEmpty) {
      tags.add('intent:$intent');
    }
    final channel = boundaryMetadata['channel']?.toString().trim();
    if (channel != null && channel.isNotEmpty) {
      tags.add('channel:$channel');
    }
    final surface = boundaryMetadata['surface']?.toString().trim();
    if (surface != null && surface.isNotEmpty) {
      tags.add('surface:$surface');
    }
    if (chatScope != null && chatScope.isNotEmpty) {
      tags.add('scope:$chatScope');
    }
    if (boundaryMetadata['share_intent'] == true) {
      tags.add('share_intent');
    }
    if (boundaryMetadata['asks_for_recommendation'] == true) {
      tags.add('asks_for_recommendation');
    }
    if (boundaryMetadata['asks_for_action'] == true) {
      tags.add('asks_for_action');
    }
    if (boundaryMetadata['asks_for_explanation'] == true) {
      tags.add('asks_for_explanation');
    }
    for (final domainId in domainHints) {
      tags.add('domain:$domainId');
    }
    final ordered = tags.toList()..sort();
    return ordered;
  }

  bool _isExplicitCorrection(Map<String, dynamic> boundaryMetadata) {
    return boundaryMetadata['intent']?.toString().trim().toLowerCase() ==
        'correct';
  }

  String _correctionConvictionTier({required String source}) {
    return source == 'ai2ai'
        ? 'ai2ai_explicit_correction_signal'
        : 'explicit_correction_signal';
  }

  String _buildCorrectionSummary(
    Map<String, dynamic> boundaryMetadata, {
    required String fallback,
  }) {
    final summary = _safeSummary(boundaryMetadata);
    if (summary == null) {
      return fallback;
    }
    return 'A governed explicit correction is ready for upward learning review: $summary';
  }

  List<String> _extractCorrectionQuestions(
    Map<String, dynamic> boundaryMetadata,
  ) {
    final questions = <String>{
      ..._extractQuestions(boundaryMetadata),
      'What prior belief or recommendation should this correction challenge?',
      'What bounded evidence would corroborate or contradict this correction?',
    };
    final ordered = questions.toList()..sort();
    return ordered;
  }

  List<String> _extractCorrectionSignalTags(
    Map<String, dynamic> boundaryMetadata, {
    required String source,
    String? chatScope,
    required List<String> domainHints,
  }) {
    final tags = <String>{
      ..._extractSignalTags(
        boundaryMetadata,
        chatScope: chatScope,
        domainHints: domainHints,
      ),
      'correction:intent',
      'correction_source:$source',
    };
    final ordered = tags.toList()..sort();
    return ordered;
  }

  List<String> _extractStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  String _buildOnboardingSummary(OnboardingData onboardingData) {
    final placeCount = onboardingData.favoritePlaces.length;
    final categoryCount = onboardingData.preferences.length;
    final baselineListCount = onboardingData.baselineLists.length;
    final hasDimensions = onboardingData.hasDimensionValues;
    return 'A governed onboarding intake is ready for upward learning review with '
        '$placeCount favorite place signals, $categoryCount preference categories, '
        '$baselineListCount baseline list seeds, and '
        '${hasDimensions ? 'device-computed personality dimensions' : 'declared onboarding preferences'}.';
  }

  String _buildOnboardingFollowUpResponseSummary({
    required String? homebase,
    required String responseText,
  }) {
    final trimmed = responseText.trim();
    final preview =
        trimmed.length > 96 ? '${trimmed.substring(0, 93)}...' : trimmed;
    if (homebase?.trim().isNotEmpty ?? false) {
      return 'A bounded onboarding follow-up response about `${homebase!.trim()}` is ready for upward learning review. The bounded response `$preview` is available for hierarchy review.';
    }
    return 'A bounded onboarding follow-up response is ready for upward learning review. The bounded response `$preview` is available for hierarchy review.';
  }

  List<String> _extractOnboardingDomainHints(OnboardingData onboardingData) {
    final domains = <String>{};
    if ((onboardingData.homebase?.trim().isNotEmpty ?? false)) {
      domains.add('locality');
    }
    if (onboardingData.favoritePlaces.isNotEmpty) {
      domains.add('place');
    }
    if (onboardingData.baselineLists.isNotEmpty) {
      domains.add('list');
    }

    final hintText = <String>[
      onboardingData.homebase ?? '',
      ...onboardingData.favoritePlaces,
      ...onboardingData.baselineLists,
      ...onboardingData.preferences.keys,
      ...onboardingData.preferences.values.expand((values) => values),
      ...onboardingData.openResponses.values,
    ].join(' ').toLowerCase();

    void addIfMatches(String domainId, List<String> keywords) {
      for (final keyword in keywords) {
        if (hintText.contains(keyword)) {
          domains.add(domainId);
          return;
        }
      }
    }

    addIfMatches('community', <String>[
      'community',
      'group',
      'club',
      'friends',
      'neighbors',
      'neighbours',
    ]);
    addIfMatches(
        'event', <String>['event', 'concert', 'festival', 'show', 'gig']);
    addIfMatches('venue', <String>[
      'venue',
      'bar',
      'club',
      'capacity',
      'door policy',
    ]);
    addIfMatches('business', <String>[
      'business',
      'shop',
      'store',
      'company',
      'merchant',
      'owner',
    ]);
    addIfMatches('mobility', <String>[
      'mobility',
      'route',
      'transit',
      'bus',
      'parking',
      'walk',
      'drive',
    ]);

    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildBusinessOperatorSummary({
    required BusinessAccount account,
    required String action,
    required List<String> changedFields,
  }) {
    final changeSummary = changedFields.isEmpty
        ? 'no scoped field delta metadata'
        : '${changedFields.length} changed field${changedFields.length == 1 ? '' : 's'}';
    return 'A governed business/operator input is ready for upward learning review for '
        '${account.name} (${account.businessType}) via $action with $changeSummary.';
  }

  String _buildBusinessOperatorFollowUpResponseSummary({
    required String businessName,
    required String action,
    required String sourceSurface,
    required String responseText,
  }) {
    final trimmedResponse = responseText.trim();
    final responseExcerpt = trimmedResponse.length <= 96
        ? trimmedResponse
        : '${trimmedResponse.substring(0, 93)}...';
    return 'A bounded business/operator follow-up response about '
        '`$businessName` after `$action` from `$sourceSurface` is ready for upward learning review. '
        'The bounded response `$responseExcerpt` is available for hierarchy review.';
  }

  Map<String, dynamic> _safeBusinessAccountSummary(BusinessAccount account) {
    final attractionDimensionKeys =
        account.attractionDimensions?.keys.toList() ?? <String>[];
    attractionDimensionKeys.sort();
    return <String, dynamic>{
      'id': account.id,
      'name': account.name,
      'businessType': account.businessType,
      'location': account.location,
      'categories': account.categories,
      'requiredExpertise': account.requiredExpertise,
      'preferredCommunities': account.preferredCommunities,
      'preferredLocation': account.preferredLocation,
      'minExpertLevel': account.minExpertLevel,
      'isVerified': account.isVerified,
      'isActive': account.isActive,
      'sharedAgentId': account.sharedAgentId,
      'attractionDimensionKeys': attractionDimensionKeys,
      'updatedAtUtc': account.updatedAt.toUtc().toIso8601String(),
    };
  }

  List<String> _extractBusinessOperatorDomainHints({
    required BusinessAccount account,
    required String action,
    required List<String> changedFields,
  }) {
    final domains = <String>{'business'};
    if ((account.location?.trim().isNotEmpty ?? false) ||
        changedFields.contains('location')) {
      domains.add('locality');
      domains.add('place');
    }
    if (account.preferredCommunities.isNotEmpty ||
        changedFields.contains('preferredCommunities')) {
      domains.add('community');
    }

    final hintText = <String>[
      account.businessType,
      ...account.categories,
      ...account.requiredExpertise,
      ...account.preferredCommunities,
      account.description ?? '',
      account.location ?? '',
      account.preferredLocation ?? '',
      action,
      ...changedFields,
    ].join(' ').toLowerCase();

    void addIfMatches(String domainId, List<String> keywords) {
      for (final keyword in keywords) {
        if (hintText.contains(keyword)) {
          domains.add(domainId);
          return;
        }
      }
    }

    addIfMatches('venue', <String>[
      'venue',
      'bar',
      'club',
      'restaurant',
      'cafe',
      'coffee',
      'nightlife',
      'hospitality',
    ]);
    addIfMatches('event', <String>[
      'event',
      'festival',
      'concert',
      'show',
      'private dining',
      'booking',
    ]);
    addIfMatches('list', <String>[
      'list',
      'curation',
      'collection',
      'guide',
    ]);
    addIfMatches('mobility', <String>[
      'parking',
      'traffic',
      'transit',
      'delivery',
      'pickup',
    ]);

    final ordered = domains.toList()..sort();
    return ordered;
  }

  List<String> _extractBusinessOperatorFollowUpDomainHints({
    required String businessType,
    required String action,
    String? where,
    String? why,
  }) {
    final domains = <String>{'business'};
    final hintText = <String>[
      businessType,
      action,
      where ?? '',
      why ?? '',
    ].join(' ').toLowerCase();
    if (where?.trim().isNotEmpty ?? false) {
      domains.addAll(const <String>['locality', 'place']);
    }
    if (hintText.contains('restaurant') ||
        hintText.contains('bar') ||
        hintText.contains('club') ||
        hintText.contains('cafe') ||
        hintText.contains('venue')) {
      domains.add('venue');
    }
    if (hintText.contains('community')) {
      domains.add('community');
    }
    if (hintText.contains('event') || hintText.contains('booking')) {
      domains.add('event');
    }
    return domains.toList()..sort();
  }

  String _buildCommunityCoordinationSummary({
    required Community community,
    required String action,
    String? affectedRef,
  }) {
    final affected = affectedRef?.trim();
    return 'A governed community coordination action is ready for upward learning review for '
        '${community.name}: $action${affected == null || affected.isEmpty ? '' : ' ($affected)'}.';
  }

  String _communityCoordinationConvictionTier(String action) {
    switch (action) {
      case 'create':
      case 'create_from_event':
        return 'community_coordination_seed_signal';
      case 'add_member':
        return 'community_membership_positive_signal';
      case 'remove_member':
        return 'community_membership_negative_signal';
      case 'add_event':
        return 'community_activity_signal';
      default:
        return 'community_coordination_signal';
    }
  }

  Map<String, dynamic> _safeCommunitySummary(Community community) {
    final currentLocalities = List<String>.from(community.currentLocalities)
      ..sort();
    return <String, dynamic>{
      'id': community.id,
      'name': community.name,
      'category': community.category,
      'originalLocality': community.originalLocality,
      'currentLocalities': currentLocalities,
      'memberCount': community.memberCount,
      'eventCount': community.eventCount,
      'activityLevel': community.activityLevel.name,
      'engagementScore': community.engagementScore,
      'diversityScore': community.diversityScore,
      'cityCode': community.cityCode,
      'localityCode': community.localityCode,
      'updatedAtUtc': community.updatedAt.toUtc().toIso8601String(),
    };
  }

  List<String> _extractCommunityCoordinationDomainHints({
    required Community community,
    required String action,
    String? sourceEventId,
  }) {
    final domains = <String>{'community'};
    if ((community.originalLocality.trim().isNotEmpty)) {
      domains.add('locality');
    }
    if (sourceEventId?.trim().isNotEmpty ?? false || action == 'add_event') {
      domains.add('event');
    }

    final hintText = <String>[
      community.category,
      community.name,
      community.description ?? '',
      community.originalLocality,
      ...community.currentLocalities,
      action,
    ].join(' ').toLowerCase();

    void addIfMatches(String domainId, List<String> keywords) {
      for (final keyword in keywords) {
        if (hintText.contains(keyword)) {
          domains.add(domainId);
          return;
        }
      }
    }

    addIfMatches('place', <String>[
      'neighborhood',
      'neighbourhood',
      'local',
      'district',
      'cafe',
      'restaurant',
      'park',
    ]);
    addIfMatches('venue', <String>[
      'venue',
      'club',
      'bar',
      'nightlife',
    ]);
    addIfMatches('business', <String>[
      'business',
      'merchant',
      'shop',
      'store',
    ]);

    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildCommunityValidationSummary({
    required CommunityValidation validation,
    String? spotName,
  }) {
    final target = spotName?.trim().isNotEmpty ?? false
        ? spotName!.trim()
        : validation.spotId;
    return 'A governed community validation is ready for upward learning review for '
        '$target with status ${validation.status.name}.';
  }

  String _communityValidationConvictionTier(CommunityValidation validation) {
    switch (validation.status) {
      case ValidationStatus.validated:
        return 'community_validation_positive_signal';
      case ValidationStatus.rejected:
        return 'community_validation_rejection_signal';
      case ValidationStatus.needsReview:
        return 'community_validation_review_signal';
      case ValidationStatus.pending:
        return 'community_validation_pending_signal';
    }
  }

  Map<String, dynamic> _safeCommunityValidationSummary(
    CommunityValidation validation,
  ) {
    final criteria =
        validation.criteriaChecked.map((entry) => entry.name).toList()..sort();
    return <String, dynamic>{
      'id': validation.id,
      'spotId': validation.spotId,
      'validatorId': validation.validatorId,
      'status': validation.status.name,
      'level': validation.level.name,
      'feedback': validation.feedback,
      'criteria': criteria,
      'confidenceScore': validation.confidenceScore,
      'validatedAtUtc': validation.validatedAt.toUtc().toIso8601String(),
    };
  }

  List<String> _extractCommunityValidationDomainHints({
    required CommunityValidation validation,
  }) {
    final domains = <String>{'community'};
    final criteriaNames =
        validation.criteriaChecked.map((criteria) => criteria.name).join(' ');
    final hintText = <String>[
      validation.spotId,
      validation.feedback ?? '',
      criteriaNames,
      validation.metadata['validation_source']?.toString() ?? '',
    ].join(' ').toLowerCase();

    domains.add('place');
    if (hintText.contains('communityrelevance')) {
      domains.add('community');
    }
    if (hintText.contains('safetyinformation')) {
      domains.add('venue');
    }

    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildReservationSharingSummary({
    required Reservation reservation,
    required String action,
    String? permission,
  }) {
    final actionLabel = action == 'transfer' ? 'transferred' : 'shared';
    return 'A reservation was $actionLabel for `${reservation.targetId}`'
        '${permission == null || permission.trim().isEmpty ? '' : ' with ${permission.trim()} permission'}'
        ' and is ready for upward learning review.';
  }

  String _reservationSharingConvictionTier({
    required String action,
    String? permission,
  }) {
    if (action == 'transfer') {
      return 'reservation_transfer_signal';
    }
    if (permission == 'fullAccess') {
      return 'reservation_sharing_full_access_signal';
    }
    return 'reservation_sharing_signal';
  }

  String _buildReservationCalendarSummary({
    required Reservation reservation,
    required String calendarId,
  }) {
    return 'A reservation calendar sync for `${reservation.targetId}` '
        'to `$calendarId` is ready for upward learning review.';
  }

  String _buildReservationRecurrenceSummary({
    required Reservation reservation,
    required String patternType,
    required int createdCount,
  }) {
    return 'A `$patternType` recurring reservation pattern for `${reservation.targetId}` '
        'created $createdCount instance${createdCount == 1 ? '' : 's'} and is ready for upward learning review.';
  }

  Map<String, dynamic> _safeReservationSummary(Reservation reservation) {
    final metadataKeys = reservation.metadata.keys.toList()..sort();
    return <String, dynamic>{
      'id': reservation.id,
      'type': reservation.type.name,
      'targetId': reservation.targetId,
      'reservationTimeUtc':
          reservation.reservationTime.toUtc().toIso8601String(),
      'partySize': reservation.partySize,
      'ticketCount': reservation.ticketCount,
      'status': reservation.status.name,
      'seatId': reservation.seatId,
      'calendarEventId': reservation.calendarEventId,
      'hasSpecialRequests':
          reservation.specialRequests?.trim().isNotEmpty ?? false,
      'metadataKeys': metadataKeys,
    };
  }

  List<String> _extractReservationDomainHints({
    required Reservation reservation,
    String? action,
    List<String> extraText = const <String>[],
  }) {
    final domains = <String>{};
    switch (reservation.type) {
      case ReservationType.spot:
        domains.addAll(const <String>['place', 'venue']);
      case ReservationType.business:
        domains.addAll(const <String>['business', 'place']);
      case ReservationType.event:
        domains.addAll(const <String>['event', 'venue']);
    }
    if ((reservation.metadata['localityCode']?.toString().trim().isNotEmpty ??
            false) ||
        (reservation.metadata['cityCode']?.toString().trim().isNotEmpty ??
            false)) {
      domains.add('locality');
    }

    final hintText = <String>[
      reservation.targetId,
      reservation.specialRequests ?? '',
      reservation.seatId ?? '',
      action ?? '',
      ...extraText,
      ...reservation.metadata.values.map((value) => value.toString()),
    ].join(' ').toLowerCase();

    void addIfMatches(String domainId, List<String> keywords) {
      for (final keyword in keywords) {
        if (hintText.contains(keyword)) {
          domains.add(domainId);
          return;
        }
      }
    }

    addIfMatches('community', <String>[
      'community',
      'group',
      'share',
      'transfer',
      'club',
    ]);
    addIfMatches('mobility', <String>[
      'parking',
      'traffic',
      'transit',
      'route',
      'mobility',
      'pickup',
      'dropoff',
    ]);

    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildExternalConfirmationSummary({
    required ExternalSourceDescriptor source,
    required ExternalSyncMetadata metadata,
    required IntakeEntityType entityType,
    required String action,
  }) {
    final label = source.sourceLabel?.trim().isNotEmpty ?? false
        ? source.sourceLabel!.trim()
        : source.sourceProvider;
    return 'An external `${source.sourceProvider}` source'
        ' (${metadata.connectionMode.name}) $action for `${entityType.name}`'
        ' via `$label` and is ready for upward learning review.';
  }

  String _externalConfirmationConvictionTier({
    required ExternalSyncMetadata metadata,
    required String action,
  }) {
    if (action == 'linked_existing_entity') {
      return 'external_confirmation_signal';
    }
    if (metadata.connectionMode == ExternalConnectionMode.api ||
        metadata.connectionMode == ExternalConnectionMode.feed ||
        metadata.connectionMode == ExternalConnectionMode.oauth) {
      return 'external_import_confirmation_signal';
    }
    return 'external_import_signal';
  }

  Map<String, dynamic> _safeExternalSourceSummary(
    ExternalSourceDescriptor source,
  ) {
    final metadataKeys = source.metadata.keys.toList()..sort();
    return <String, dynamic>{
      'id': source.id,
      'sourceProvider': source.sourceProvider,
      'sourceUrl': source.sourceUrl,
      'connectionMode': source.connectionMode.name,
      'entityHint': source.entityHint?.name,
      'sourceLabel': source.sourceLabel,
      'cityCode': source.cityCode,
      'localityCode': source.localityCode,
      'isOneWaySync': source.isOneWaySync,
      'isClaimable': source.isClaimable,
      'syncState': source.syncState.name,
      'metadataKeys': metadataKeys,
    };
  }

  List<String> _extractExternalConfirmationDomainHints({
    required ExternalSourceDescriptor source,
    required ExternalSyncMetadata metadata,
    required IntakeEntityType entityType,
    required String action,
    required Map<String, dynamic> boundedPayload,
  }) {
    final domains = <String>{};
    switch (entityType) {
      case IntakeEntityType.spot:
        domains.addAll(const <String>['place', 'venue']);
      case IntakeEntityType.event:
        domains.add('event');
      case IntakeEntityType.community:
        domains.add('community');
      case IntakeEntityType.linkedBundle:
        domains.addAll(const <String>['community', 'event']);
      case IntakeEntityType.review:
        break;
    }
    if ((metadata.cityCode?.trim().isNotEmpty ?? false) ||
        (metadata.localityCode?.trim().isNotEmpty ?? false) ||
        (source.cityCode?.trim().isNotEmpty ?? false) ||
        (source.localityCode?.trim().isNotEmpty ?? false)) {
      domains.add('locality');
    }

    final hintText = <String>[
      source.sourceProvider,
      source.sourceLabel ?? '',
      source.sourceUrl ?? '',
      metadata.sourceLabel ?? '',
      metadata.sourceProvider,
      metadata.syncNotes ?? '',
      action,
      ...boundedPayload.values.map((value) => value.toString()),
    ].join(' ').toLowerCase();

    void addIfMatches(String domainId, List<String> keywords) {
      for (final keyword in keywords) {
        if (hintText.contains(keyword)) {
          domains.add(domainId);
          return;
        }
      }
    }

    addIfMatches('business', <String>[
      'business',
      'merchant',
      'restaurant',
      'shop',
      'store',
      'company',
    ]);
    addIfMatches('place', <String>[
      'place',
      'spot',
      'neighborhood',
      'neighbourhood',
      'venue',
      'park',
    ]);
    addIfMatches('list', <String>[
      'list',
      'guide',
      'collection',
      'curation',
    ]);

    final ordered = domains.toList()..sort();
    return ordered;
  }

  List<String> _extractOnboardingReferencedEntities(
      OnboardingData onboardingData) {
    final entities = <String>{
      ...onboardingData.favoritePlaces,
      ...onboardingData.baselineLists,
      ...onboardingData.preferences.keys,
    };
    final ordered = entities.where((entry) => entry.trim().isNotEmpty).toList()
      ..sort();
    return ordered;
  }

  List<String> _extractOnboardingQuestions(OnboardingData onboardingData) {
    final questions = <String>[];
    if (onboardingData.favoritePlaces.isNotEmpty) {
      questions.add(
          'Which favorite places should most strongly seed early guidance?');
    }
    if (onboardingData.baselineLists.isNotEmpty) {
      questions.add(
          'Which onboarding baseline lists should be treated as strongest initial curation signals?');
    }
    if (onboardingData.preferences.isNotEmpty) {
      questions.add(
          'Which declared onboarding preference categories should become strongest initial convictions?');
    }
    return questions;
  }

  List<Map<String, dynamic>> _extractOnboardingPreferenceSignals(
    OnboardingData onboardingData,
  ) {
    final signals = <Map<String, dynamic>>[];
    for (final category in onboardingData.preferences.keys.toList()..sort()) {
      final values = List<String>.from(
          onboardingData.preferences[category] ?? const <String>[])
        ..sort();
      if (values.isEmpty) {
        continue;
      }
      signals.add(<String, dynamic>{
        'kind': 'onboarding_preference_category',
        'value': '$category:${values.join(', ')}',
        'confidence': 0.72,
      });
    }
    if (onboardingData.baselineLists.isNotEmpty) {
      signals.add(<String, dynamic>{
        'kind': 'onboarding_baseline_lists',
        'value': onboardingData.baselineLists.join(', '),
        'confidence': 0.7,
      });
    }
    if (onboardingData.homebase?.trim().isNotEmpty ?? false) {
      signals.add(<String, dynamic>{
        'kind': 'onboarding_homebase',
        'value': onboardingData.homebase!.trim(),
        'confidence': 0.82,
      });
    }
    return signals;
  }

  String _buildSavedDiscoverySummary({
    required DiscoveryEntityReference entity,
    required String action,
    required String sourceSurface,
  }) {
    final verb = action == 'unsave' ? 'removed' : 'saved';
    return 'A governed discovery curation signal is ready for upward learning review because ${entity.title} was $verb from $sourceSurface.';
  }

  String _buildSavedDiscoveryFollowUpResponseSummary({
    required DiscoveryEntityReference entity,
    required String action,
    required String sourceSurface,
    required String responseText,
  }) {
    final verb = action == 'unsave' ? 'removed' : 'saved';
    final trimmed = responseText.trim();
    final preview =
        trimmed.length > 96 ? '${trimmed.substring(0, 93)}...' : trimmed;
    return 'A bounded saved-discovery follow-up response is ready for upward learning review because ${entity.title} was $verb from $sourceSurface and the owner added: "$preview"';
  }

  List<String> _extractSavedDiscoveryDomainHints({
    required DiscoveryEntityReference entity,
    required String sourceSurface,
    RecommendationAttribution? attribution,
  }) {
    final domains = <String>{
      switch (entity.type) {
        DiscoveryEntityType.spot => 'place',
        DiscoveryEntityType.list => 'list',
        DiscoveryEntityType.event => 'event',
        DiscoveryEntityType.club => 'community',
        DiscoveryEntityType.community => 'community',
      },
      if (entity.localityLabel?.trim().isNotEmpty ?? false) 'locality',
    };
    final hintText = <String>[
      entity.title,
      entity.localityLabel ?? '',
      sourceSurface,
      attribution?.why ?? '',
      attribution?.whyDetails ?? '',
      attribution?.recommendationSource ?? '',
    ].join(' ').toLowerCase();

    void addIfMatches(String domainId, List<String> keywords) {
      for (final keyword in keywords) {
        if (hintText.contains(keyword)) {
          domains.add(domainId);
          return;
        }
      }
    }

    addIfMatches('venue', <String>[
      'venue',
      'bar',
      'club',
      'door',
      'line',
      'capacity',
    ]);
    addIfMatches('business', <String>[
      'business',
      'merchant',
      'shop',
      'store',
      'restaurant',
      'cafe',
      'coffee',
    ]);
    addIfMatches('place', <String>[
      'place',
      'spot',
      'neighborhood',
      'neighbourhood',
      'park',
      'museum',
    ]);

    final ordered = domains.toList()..sort();
    return ordered;
  }

  List<String> _extractOnboardingSignalTags(
    OnboardingData onboardingData, {
    required List<String> domainHints,
  }) {
    final tags = <String>{
      'surface:onboarding',
      'channel:onboarding_flow',
      'intent:declare_preferences',
      'source:onboarding',
      if (onboardingData.hasDimensionValues) 'has_dimension_values',
      if (onboardingData.betaConsentAccepted) 'beta_consent_accepted',
      if (onboardingData.questionnaireVersion?.trim().isNotEmpty ?? false)
        'questionnaire:${onboardingData.questionnaireVersion!.trim()}',
    };
    for (final domainId in domainHints) {
      tags.add('domain:$domainId');
    }
    final ordered = tags.toList()..sort();
    return ordered;
  }

  String _buildRecommendationFeedbackSummary({
    required RecommendationFeedbackAction action,
    required DiscoveryEntityReference entity,
    required String sourceSurface,
    RecommendationAttribution? attribution,
  }) {
    final actionLabel = switch (action) {
      RecommendationFeedbackAction.save => 'saved',
      RecommendationFeedbackAction.dismiss => 'dismissed',
      RecommendationFeedbackAction.moreLikeThis => 'asked for more like this',
      RecommendationFeedbackAction.lessLikeThis => 'asked for less like this',
      RecommendationFeedbackAction.whyDidYouShowThis =>
        'asked why this was shown',
      RecommendationFeedbackAction.meaningful => 'marked meaningful',
      RecommendationFeedbackAction.fun => 'marked fun',
      RecommendationFeedbackAction.opened => 'opened',
    };
    return 'A user $actionLabel the ${entity.type.name} recommendation '
        '`${entity.title}` from `$sourceSurface`${attribution == null ? '' : ' with bounded attribution context'} and it is ready for upward learning review.';
  }

  String _recommendationFeedbackConvictionTier(
    RecommendationFeedbackAction action,
  ) {
    return switch (action) {
      RecommendationFeedbackAction.lessLikeThis ||
      RecommendationFeedbackAction.whyDidYouShowThis =>
        'recommendation_feedback_correction_signal',
      RecommendationFeedbackAction.save ||
      RecommendationFeedbackAction.meaningful ||
      RecommendationFeedbackAction.fun =>
        'recommendation_feedback_positive_signal',
      _ => 'recommendation_feedback_observation',
    };
  }

  String _buildRecommendationFeedbackFollowUpResponseSummary({
    required RecommendationFeedbackAction action,
    required DiscoveryEntityReference entity,
    required String sourceSurface,
    required String responseText,
  }) {
    final trimmedResponse = responseText.trim();
    final responseExcerpt = trimmedResponse.length <= 96
        ? trimmedResponse
        : '${trimmedResponse.substring(0, 93)}...';
    return 'A user answered a bounded follow-up about the '
        '${entity.type.name} recommendation `${entity.title}` after `${action.name}` '
        'from `$sourceSurface`. The bounded response `$responseExcerpt` is ready '
        'for upward learning review.';
  }

  String _recommendationFeedbackFollowUpConvictionTier(
    RecommendationFeedbackAction action,
  ) {
    return switch (action) {
      RecommendationFeedbackAction.lessLikeThis ||
      RecommendationFeedbackAction.whyDidYouShowThis =>
        'recommendation_feedback_follow_up_correction_signal',
      RecommendationFeedbackAction.save ||
      RecommendationFeedbackAction.meaningful ||
      RecommendationFeedbackAction.fun ||
      RecommendationFeedbackAction.moreLikeThis =>
        'recommendation_feedback_follow_up_preference_signal',
      _ => 'recommendation_feedback_follow_up_observation',
    };
  }

  List<String> _extractRecommendationFeedbackDomainHints({
    required DiscoveryEntityReference entity,
    required String sourceSurface,
    required RecommendationAttribution? attribution,
    required Map<String, dynamic> metadata,
  }) {
    final domains = <String>{};
    switch (entity.type) {
      case DiscoveryEntityType.spot:
        domains.add('place');
        domains.add('venue');
      case DiscoveryEntityType.list:
        domains.add('list');
      case DiscoveryEntityType.event:
        domains.add('event');
      case DiscoveryEntityType.club:
        domains.add('community');
      case DiscoveryEntityType.community:
        domains.add('community');
    }
    if (entity.localityLabel?.trim().isNotEmpty ?? false) {
      domains.add('locality');
    }
    final metadataDomains = _extractStringList(metadata['domains']);
    domains.addAll(metadataDomains);
    final hintText = <String>[
      entity.title,
      sourceSurface,
      attribution?.why ?? '',
      attribution?.whyDetails ?? '',
      attribution?.recommendationSource ?? '',
      ...metadata.values.map((value) => value.toString()),
    ].join(' ').toLowerCase();

    void addIfMatches(String domainId, List<String> keywords) {
      for (final keyword in keywords) {
        if (hintText.contains(keyword)) {
          domains.add(domainId);
          return;
        }
      }
    }

    addIfMatches('business', <String>[
      'business',
      'merchant',
      'owner',
      'company',
      'shop',
      'store',
      'sales',
      'revenue',
    ]);
    addIfMatches('mobility', <String>[
      'route',
      'traffic',
      'parking',
      'transit',
      'walk',
      'drive',
      'mobility',
    ]);

    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildVisitSummary({
    required Visit visit,
    required String source,
  }) {
    final dwellMinutes = visit.dwellTime?.inMinutes ?? 0;
    return 'A ${visit.isAutomatic ? 'runtime-captured' : 'recorded'} visit to '
        '`${visit.locationId}` from `$source` completed with '
        '$dwellMinutes minutes of dwell and quality '
        '${visit.qualityScore.toStringAsFixed(2)}, and it is ready for upward learning review.';
  }

  String _visitConvictionTier(Visit visit) {
    final dwellMinutes = visit.dwellTime?.inMinutes ?? 0;
    if (visit.isRepeatVisit ||
        dwellMinutes >= 30 ||
        visit.qualityScore >= 1.0) {
      return 'visit_behavior_confirmation';
    }
    return 'visit_behavior_observation';
  }

  List<String> _extractVisitDomainHints({
    required Visit visit,
    required String source,
  }) {
    final domains = <String>{
      'locality',
      'place',
      'venue',
    };
    final hintText = <String>[
      visit.locationId,
      source,
      ...visit.metadata.values.map((value) => value.toString()),
    ].join(' ').toLowerCase();
    if (hintText.contains('community') || hintText.contains('club')) {
      domains.add('community');
    }
    if (hintText.contains('event')) {
      domains.add('event');
    }
    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildLocalityObservationSummary({
    required String sourceKind,
    required String localityStableKey,
    required Map<String, dynamic> structuredSignals,
    required String? socialContext,
  }) {
    final dwellMinutes =
        (structuredSignals['dwellDurationMinutes'] as num?)?.toInt();
    final coPresence = structuredSignals['coPresenceDetected'] == true;
    return 'A `$sourceKind` locality observation for `$localityStableKey`'
        '${dwellMinutes == null ? '' : ' with $dwellMinutes minutes of dwell'}'
        '${socialContext == null || socialContext.trim().isEmpty ? '' : ' and social context `${socialContext.trim()}`'}'
        '${coPresence ? ' including co-presence evidence' : ''}'
        ' is ready for upward learning review.';
  }

  String _localityObservationConvictionTier(
    Map<String, dynamic> structuredSignals,
  ) {
    final dwellMinutes =
        (structuredSignals['dwellDurationMinutes'] as num?)?.toInt() ?? 0;
    if ((structuredSignals['coPresenceDetected'] as bool?) == true ||
        dwellMinutes >= 30) {
      return 'locality_behavior_signal';
    }
    return 'locality_observation_signal';
  }

  List<String> _extractLocalityObservationDomainHints({
    required String localityStableKey,
    required Map<String, dynamic> structuredSignals,
    required String? socialContext,
    required String? activityContext,
  }) {
    final domains = <String>{'locality'};
    if (localityStableKey.isNotEmpty) {
      domains.add('place');
    }
    if ((structuredSignals['coPresenceDetected'] as bool?) == true ||
        (socialContext?.contains('group') ?? false) ||
        (socialContext?.contains('crowd') ?? false)) {
      domains.add('community');
    }
    if ((structuredSignals['placeVibeLabel']?.toString().trim().isNotEmpty ??
        false)) {
      domains.add('venue');
    }
    if ((activityContext?.contains('transit') ?? false) ||
        (activityContext?.contains('walk') ?? false) ||
        (activityContext?.contains('drive') ?? false)) {
      domains.add('mobility');
    }
    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildEventFeedbackSummary({
    required EventFeedback feedback,
    required ExpertiseEvent? event,
  }) {
    return 'Post-event feedback for `${event?.title ?? feedback.eventId}` '
        'was submitted with overall rating ${feedback.overallRating.toStringAsFixed(1)} '
        'and is ready for upward learning review.';
  }

  String _eventFeedbackConvictionTier(EventFeedback feedback) {
    if (!feedback.wouldAttendAgain ||
        !feedback.wouldRecommend ||
        feedback.overallRating < 3.5) {
      return 'event_feedback_correction_signal';
    }
    if (feedback.overallRating >= 4.5 &&
        feedback.wouldAttendAgain &&
        feedback.wouldRecommend) {
      return 'event_feedback_positive_signal';
    }
    return 'event_feedback_observation';
  }

  String _buildExplicitCorrectionFollowUpResponseSummary({
    required String targetSummary,
    required String sourceSurface,
    required String responseText,
  }) {
    final trimmedTarget = targetSummary.trim();
    final trimmedResponse = responseText.trim();
    final responseSnippet = trimmedResponse.length > 160
        ? '${trimmedResponse.substring(0, 157)}...'
        : trimmedResponse;
    return 'Explicit correction follow-up for "$trimmedTarget" from $sourceSurface: $responseSnippet';
  }

  String _buildVisitLocalityFollowUpResponseSummary({
    required String observationKind,
    required String targetLabel,
    required String sourceSurface,
    required String responseText,
  }) {
    final trimmedResponse = responseText.trim();
    final responseExcerpt = trimmedResponse.length <= 96
        ? trimmedResponse
        : '${trimmedResponse.substring(0, 93)}...';
    return 'A bounded $observationKind follow-up about '
        '`$targetLabel` from `$sourceSurface` is ready for upward learning review. '
        'The bounded response `$responseExcerpt` is available for hierarchy review.';
  }

  String _buildCommunityFollowUpResponseSummary({
    required String followUpKind,
    required String targetLabel,
    required String sourceSurface,
    required String responseText,
  }) {
    final trimmedResponse = responseText.trim();
    final responseExcerpt = trimmedResponse.length <= 96
        ? trimmedResponse
        : '${trimmedResponse.substring(0, 93)}...';
    return 'A bounded $followUpKind follow-up about '
        '`$targetLabel` from `$sourceSurface` is ready for upward learning review. '
        'The bounded response `$responseExcerpt` is available for hierarchy review.';
  }

  String _buildEventFeedbackFollowUpResponseSummary({
    required String eventTitle,
    required String sourceSurface,
    required String responseText,
  }) {
    final trimmedResponse = responseText.trim();
    final responseExcerpt = trimmedResponse.length <= 96
        ? trimmedResponse
        : '${trimmedResponse.substring(0, 93)}...';
    return 'A user answered a bounded follow-up about the event '
        '`$eventTitle` from `$sourceSurface`. The bounded response '
        '`$responseExcerpt` is ready for upward learning review.';
  }

  String _eventFeedbackFollowUpConvictionTier(Map<String, dynamic> metadata) {
    final overallRating = (metadata['overallRating'] as num?)?.toDouble();
    final wouldAttendAgain = metadata['wouldAttendAgain'] == true;
    final wouldRecommend = metadata['wouldRecommend'] == true;
    if ((overallRating != null && overallRating < 3.5) ||
        metadata['wouldAttendAgain'] == false ||
        metadata['wouldRecommend'] == false) {
      return 'event_feedback_follow_up_correction_signal';
    }
    if ((overallRating != null && overallRating >= 4.3) &&
        wouldAttendAgain &&
        wouldRecommend) {
      return 'event_feedback_follow_up_preference_signal';
    }
    return 'event_feedback_follow_up_observation';
  }

  List<String> _extractEventFeedbackDomainHints({
    required EventFeedback feedback,
    required ExpertiseEvent? event,
  }) {
    final domains = <String>{'event'};
    if (event?.localityCode?.trim().isNotEmpty ?? false) {
      domains.add('locality');
    }
    if ((event?.spots.isNotEmpty ?? false)) {
      domains.add('place');
      domains.add('venue');
      if (event!.spots.any((spot) => spot.metadata['businessId'] != null)) {
        domains.add('business');
      }
    }
    final text = <String>[
      feedback.comments ?? '',
      ...?feedback.highlights,
      ...?feedback.improvements,
      ...feedback.categoryRatings.keys,
      event?.category ?? '',
    ].join(' ').toLowerCase();
    if (text.contains('community') || text.contains('group')) {
      domains.add('community');
    }
    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildPartnerRatingSummary({
    required PartnerRating rating,
    required ExpertiseEvent? event,
  }) {
    return 'Partner rating for `${event?.title ?? rating.eventId}` '
        'targeting `${rating.ratedId}` with overall rating ${rating.overallRating.toStringAsFixed(1)} '
        'is ready for upward learning review.';
  }

  String _partnerRatingConvictionTier(PartnerRating rating) {
    if (rating.overallRating < 3.5 || rating.wouldPartnerAgain < 3.5) {
      return 'partner_rating_correction_signal';
    }
    if (rating.overallRating >= 4.5 && rating.wouldPartnerAgain >= 4.0) {
      return 'partner_rating_positive_signal';
    }
    return 'partner_rating_observation';
  }

  List<String> _extractPartnerRatingDomainHints({
    required PartnerRating rating,
    required ExpertiseEvent? event,
  }) {
    final domains = <String>{'business', 'event'};
    if (event?.localityCode?.trim().isNotEmpty ?? false) {
      domains.add('locality');
    }
    if ((event?.spots.isNotEmpty ?? false)) {
      domains.add('venue');
      domains.add('place');
    }
    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildEventOutcomeSummary({
    required ExpertiseEvent event,
    required Map<String, dynamic> payload,
  }) {
    return 'Bounded event outcome learning for `${event.title}` '
        'with signal `${payload['signal_kind'] ?? 'eventCompleted'}` is ready for upward learning review.';
  }

  String _eventOutcomeConvictionTier(Map<String, dynamic> payload) {
    final attendanceRate =
        (payload['attendance_rate'] as num?)?.toDouble() ?? 0.0;
    final averageRating =
        (payload['average_rating'] as num?)?.toDouble() ?? 0.0;
    if (attendanceRate >= 0.8 && averageRating >= 4.2) {
      return 'event_outcome_confirmation_signal';
    }
    if (attendanceRate < 0.5 || averageRating < 3.8) {
      return 'event_outcome_correction_signal';
    }
    return 'event_outcome_observation';
  }

  List<String> _extractEventOutcomeDomainHints({
    required ExpertiseEvent event,
    required Map<String, dynamic> payload,
  }) {
    final domains = <String>{'event'};
    if (event.localityCode?.trim().isNotEmpty ?? false) {
      domains.add('locality');
    }
    if (event.spots.isNotEmpty) {
      domains.add('place');
      domains.add('venue');
      if (event.spots.any((spot) => spot.metadata['businessId'] != null)) {
        domains.add('business');
      }
    }
    final text = <String>[
      event.category,
      ..._extractStringList(payload['intent_tags']),
      ..._extractStringList(payload['vibe_tags']),
      ..._extractStringList(payload['insight_lines']),
    ].join(' ').toLowerCase();
    if (text.contains('community') || text.contains('families')) {
      domains.add('community');
    }
    final ordered = domains.toList()..sort();
    return ordered;
  }

  Map<String, dynamic> _safeEventSummary(ExpertiseEvent event) {
    return <String, dynamic>{
      'eventId': event.id,
      'title': event.title,
      'category': event.category,
      'cityCode': event.cityCode,
      'localityCode': event.localityCode,
      'spotCount': event.spots.length,
    };
  }
}
