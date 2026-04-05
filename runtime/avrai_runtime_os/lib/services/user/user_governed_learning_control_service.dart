import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_envelope.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_control_contract.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_signal_policy_service.dart';

class UserGovernedLearningControlService {
  UserGovernedLearningControlService({
    required UniversalIntakeRepository intakeRepository,
    required GovernedUpwardLearningIntakeService
        governedUpwardLearningIntakeService,
    required AgentIdService agentIdService,
    required UserGovernedLearningSignalPolicyService signalPolicyService,
    UserGovernedLearningAdoptionService? adoptionService,
    UpwardAirGapService? upwardAirGapService,
    UserGovernedLearningCorrectionFollowUpPromptPlannerService?
        correctionFollowUpPlannerService,
  })  : _intakeRepository = intakeRepository,
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService,
        _agentIdService = agentIdService,
        _signalPolicyService = signalPolicyService,
        _adoptionService = adoptionService,
        _upwardAirGapService =
            upwardAirGapService ?? const UpwardAirGapService(),
        _correctionFollowUpPlannerService = correctionFollowUpPlannerService;

  final UniversalIntakeRepository _intakeRepository;
  final GovernedUpwardLearningIntakeService
      _governedUpwardLearningIntakeService;
  final AgentIdService _agentIdService;
  final UserGovernedLearningSignalPolicyService _signalPolicyService;
  final UserGovernedLearningAdoptionService? _adoptionService;
  final UpwardAirGapService _upwardAirGapService;
  final UserGovernedLearningCorrectionFollowUpPromptPlannerService?
      _correctionFollowUpPlannerService;

  static const Set<String> _eventEligibilityTerms = <String>{
    'event',
    'nightlife',
    'music',
    'concert',
    'festival',
    'show',
    'party',
    'club',
    'bar',
    'social',
  };

  Future<bool> forgetRecord({
    required String ownerUserId,
    required String envelopeId,
  }) async {
    final match =
        await _findSource(ownerUserId: ownerUserId, envelopeId: envelopeId);
    if (match == null) {
      return false;
    }
    final now = DateTime.now().toUtc();
    final envelope = match.envelope.copyWith(
      title: 'Forgotten governed learning record',
      safeSummary: '[Forgotten by user]',
      requiresHumanReview: false,
      domainHints: const <String>[],
      referencedEntities: const <String>[],
      questions: const <String>[],
      preferenceSignals: const <Map<String, dynamic>>[],
      signalTags: const <String>[],
      metadata: <String, dynamic>{
        ...match.envelope.metadata,
        governedLearningControlMetadataKey: <String, dynamic>{
          governedLearningControlStateKey:
              governedLearningControlStateForgotten,
          governedLearningControlForgottenAtKey: now.toIso8601String(),
        },
      },
    );
    final source = match.source.copyWith(
      updatedAt: now,
      syncState: ExternalSyncState.paused,
      metadata: <String, dynamic>{
        ...match.source.metadata,
        'summary': '[Forgotten by user]',
        'safeSummary': '[Forgotten by user]',
        'upwardDomainHints': const <String>[],
        'upwardReferencedEntities': const <String>[],
        'upwardQuestions': const <String>[],
        'upwardPreferenceSignals': const <Map<String, dynamic>>[],
        'upwardSignalTags': const <String>[],
        'governedLearningEnvelope': envelope.toJson(),
        governedLearningControlMetadataKey: <String, dynamic>{
          governedLearningControlStateKey:
              governedLearningControlStateForgotten,
          governedLearningControlForgottenAtKey: now.toIso8601String(),
        },
      },
    );
    await _intakeRepository.upsertSource(source);
    await _intakeRepository.deleteReviewItem(match.envelope.reviewItemId);
    return true;
  }

  Future<GovernedUpwardLearningIntakeResult?> submitCorrection({
    required String ownerUserId,
    required String envelopeId,
    required String correctionText,
  }) async {
    final normalizedCorrection = correctionText.trim();
    if (normalizedCorrection.isEmpty) {
      return null;
    }
    final match =
        await _findSource(ownerUserId: ownerUserId, envelopeId: envelopeId);
    if (match == null) {
      return null;
    }
    final agentId = await _agentIdService.getUserAgentId(ownerUserId);
    final occurredAtUtc = DateTime.now().toUtc();
    final airGapArtifact = _upwardAirGapService.issueArtifact(
      originPlane: 'personal_device',
      sourceKind: 'explicit_correction_intake',
      sourceScope: 'human',
      destinationCeiling: 'reality_model_agent',
      issuedAtUtc: DateTime.now().toUtc(),
      sanitizedPayload: <String, dynamic>{
        'correctionText': normalizedCorrection,
        'targetEnvelopeId': match.envelope.id,
        'targetSourceId': match.source.id,
      },
      pseudonymousActorRef: match.envelope.airGap?.pseudonymousActorRef,
    );
    final result = await _governedUpwardLearningIntakeService
        .stagePersonalAgentHumanIntake(
      ownerUserId: ownerUserId,
      actorAgentId: agentId,
      chatId: 'data_center_correction',
      messageId:
          '${match.envelope.id}:correction:${occurredAtUtc.microsecondsSinceEpoch}',
      occurredAtUtc: occurredAtUtc,
      airGapArtifact: airGapArtifact,
      cityCode: match.source.cityCode ?? match.envelope.cityCode,
      localityCode: match.source.localityCode ?? match.envelope.localityCode,
      boundaryMetadata: <String, dynamic>{
        'intent': 'correct',
        'summary': normalizedCorrection,
        'sanitized_summary': normalizedCorrection,
        'referenced_entities': match.envelope.referencedEntities,
        'questions': <String>[
          'What prior belief or recommendation should this correction challenge?',
        ],
        'accepted': true,
        'learning_allowed': true,
        'correction_target_envelope_id': match.envelope.id,
        'correction_target_source_id': match.source.id,
        'correction_target_summary': match.envelope.safeSummary,
        if (match.envelope.airGap?.pseudonymousActorRef != null)
          'pseudonymous_actor_ref': match.envelope.airGap!.pseudonymousActorRef,
      },
    );
    await _recordCorrectionAdoptionReceipts(
      ownerUserId: ownerUserId,
      result: result,
    );
    try {
      await _correctionFollowUpPlannerService?.createPlan(
        ownerUserId: ownerUserId,
        targetEnvelopeId: match.envelope.id,
        targetSourceId: match.source.id,
        targetSummary: match.envelope.safeSummary,
        correctionText: normalizedCorrection,
        occurredAtUtc: occurredAtUtc,
        sourceSurface: 'data_center_correction',
        domainHints: match.envelope.domainHints,
        referencedEntities: match.envelope.referencedEntities,
        localityCode: match.source.localityCode ?? match.envelope.localityCode,
        cityCode: match.source.cityCode ?? match.envelope.cityCode,
        sourceProvider: 'explicit_correction_intake',
      );
    } catch (_) {
      // Best-effort only. The correction staging path must remain durable.
    }
    return result;
  }

  Future<bool> stopUsingSignal({
    required String ownerUserId,
    required String envelopeId,
  }) async {
    final match =
        await _findSource(ownerUserId: ownerUserId, envelopeId: envelopeId);
    if (match == null) {
      return false;
    }
    final now = DateTime.now().toUtc();
    final blockedSignalKey = _signalPolicyService.buildSignalKey(
      convictionTier: match.envelope.convictionTier,
      sourceProvider: match.envelope.sourceProvider,
    );
    await _signalPolicyService.blockSignal(
      ownerUserId: ownerUserId,
      convictionTier: match.envelope.convictionTier,
      sourceProvider: match.envelope.sourceProvider,
    );
    final controlMetadata = <String, dynamic>{
      governedLearningControlFutureSignalUseBlockedKey: true,
      governedLearningControlSignalBlockedAtKey: now.toIso8601String(),
      governedLearningControlBlockedSignalKey: blockedSignalKey,
    };
    final envelope = match.envelope.copyWith(
      requiresHumanReview: false,
      metadata: <String, dynamic>{
        ...match.envelope.metadata,
        governedLearningControlMetadataKey: controlMetadata,
      },
    );
    final source = match.source.copyWith(
      updatedAt: now,
      syncState: ExternalSyncState.paused,
      metadata: <String, dynamic>{
        ...match.source.metadata,
        'governedLearningEnvelope': envelope.toJson(),
        governedLearningControlMetadataKey: controlMetadata,
      },
    );
    await _intakeRepository.upsertSource(source);
    await _intakeRepository.deleteReviewItem(match.envelope.reviewItemId);
    return true;
  }

  Future<_SourceEnvelopeMatch?> _findSource({
    required String ownerUserId,
    required String envelopeId,
  }) async {
    final sources = await _intakeRepository.getSourcesForOwner(ownerUserId);
    for (final source in sources) {
      final rawEnvelope = source.metadata['governedLearningEnvelope'];
      if (rawEnvelope is! Map) {
        continue;
      }
      final envelope = GovernedLearningEnvelope.fromJson(
        Map<String, dynamic>.from(rawEnvelope),
      );
      if (envelope.id == envelopeId) {
        return _SourceEnvelopeMatch(source: source, envelope: envelope);
      }
    }
    return null;
  }

  Future<void> _recordCorrectionAdoptionReceipts({
    required String ownerUserId,
    required GovernedUpwardLearningIntakeResult result,
  }) async {
    final adoptionService = _adoptionService;
    if (adoptionService == null) {
      return;
    }
    final recordedAtUtc = DateTime.now().toUtc();
    final receipts = <GovernedLearningAdoptionReceipt>[
      GovernedLearningAdoptionReceipt(
        id: '${result.envelope.id}:accepted_for_learning',
        ownerUserId: ownerUserId,
        envelopeId: result.envelope.id,
        sourceId: result.sourceId,
        status: GovernedLearningAdoptionStatus.acceptedForLearning,
        recordedAtUtc: recordedAtUtc,
        reason:
            'The explicit correction was accepted into governed learning for bounded local use.',
      ),
    ];
    if (_isEventsEligible(result.envelope)) {
      receipts.add(
        GovernedLearningAdoptionReceipt(
          id: '${result.envelope.id}:events_personalized:queued_for_surface_refresh',
          ownerUserId: ownerUserId,
          envelopeId: result.envelope.id,
          sourceId: result.sourceId,
          status: GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
          recordedAtUtc: recordedAtUtc,
          surface: 'events_personalized',
          decisionFamily: 'event_recommendation',
          reason:
              'This explicit correction is queued for the personalized events surface.',
        ),
      );
    }
    await adoptionService.recordReceipts(receipts);
  }

  bool _isEventsEligible(GovernedLearningEnvelope envelope) {
    final haystack = <String>[
      envelope.title,
      envelope.safeSummary,
      ...envelope.domainHints,
      ...envelope.referencedEntities,
    ]
        .map(_normalizeForEligibility)
        .where((entry) => entry.isNotEmpty)
        .join(' ');
    for (final term in _eventEligibilityTerms) {
      if (haystack.contains(term)) {
        return true;
      }
    }
    return false;
  }

  String _normalizeForEligibility(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _SourceEnvelopeMatch {
  const _SourceEnvelopeMatch({
    required this.source,
    required this.envelope,
  });

  final ExternalSourceDescriptor source;
  final GovernedLearningEnvelope envelope;
}
