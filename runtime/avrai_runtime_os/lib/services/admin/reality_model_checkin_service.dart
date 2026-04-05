import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:avrai_runtime_os/kernel/interpretation/interpretation_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governed_runtime_registry_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/temporal/runtime_temporal_context_service.dart';
import 'package:get_it/get_it.dart';

enum CheckInFeedbackOutcome {
  accepted,
  rewritten;

  String get learningScope => switch (this) {
        CheckInFeedbackOutcome.accepted => 'governance_feedback_acceptance',
        CheckInFeedbackOutcome.rewritten => 'governance_feedback_rewrite',
      };

  String get repairType => switch (this) {
        CheckInFeedbackOutcome.accepted => 'none',
        CheckInFeedbackOutcome.rewritten => 'operator_rewrite',
      };
}

class RealityModelCheckInResult {
  const RealityModelCheckInResult({
    required this.response,
    required this.createdAtUtc,
    this.contract,
    this.evaluation,
    this.trace,
    this.explanation,
  });

  final String response;
  final DateTime createdAtUtc;
  final RealityModelContract? contract;
  final RealityModelEvaluation? evaluation;
  final RealityDecisionTrace? trace;
  final RealityModelExplanation? explanation;

  bool get hasRealityModelArtifacts =>
      contract != null &&
      evaluation != null &&
      trace != null &&
      explanation != null;
}

/// Runtime-backed check-in service for admin reality-system oversight pages.
///
/// Uses the app's language runtime boundary when available and falls back to
/// deterministic responses if runtime chat is unavailable.
class RealityModelCheckInService {
  static const String _logName = 'RealityModelCheckInService';
  static const String _defaultSimulationCityCode = 'simulation';
  final UrkGovernedRuntimeRegistryService? _governedRuntimeRegistryService;
  final RuntimeTemporalContextService? _runtimeTemporalContextService;
  final LanguageKernelOrchestratorService _languageKernelOrchestratorService;
  final LanguagePatternLearningService? _languageLearningService;
  final InterpretationKernelService _interpretationKernelService;
  final RealityModelPort? _realityModelPort;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;

  RealityModelCheckInService({
    UrkGovernedRuntimeRegistryService? governedRuntimeRegistryService,
    RuntimeTemporalContextService? runtimeTemporalContextService,
    LanguageKernelOrchestratorService? languageKernelOrchestratorService,
    LanguagePatternLearningService? languageLearningService,
    InterpretationKernelService? interpretationKernelService,
    RealityModelPort? realityModelPort,
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
  })  : _governedRuntimeRegistryService = governedRuntimeRegistryService ??
            (GetIt.instance.isRegistered<UrkGovernedRuntimeRegistryService>()
                ? GetIt.instance<UrkGovernedRuntimeRegistryService>()
                : null),
        _runtimeTemporalContextService = runtimeTemporalContextService ??
            (GetIt.instance.isRegistered<TemporalKernelAdminService>()
                ? RuntimeTemporalContextService(
                    temporalKernelAdminService:
                        GetIt.instance<TemporalKernelAdminService>(),
                  )
                : null),
        _languageKernelOrchestratorService =
            languageKernelOrchestratorService ??
                LanguageKernelOrchestratorService(),
        _languageLearningService = languageLearningService ??
            (GetIt.instance.isRegistered<LanguagePatternLearningService>()
                ? GetIt.instance<LanguagePatternLearningService>()
                : null),
        _interpretationKernelService =
            interpretationKernelService ?? InterpretationKernelService(),
        _realityModelPort = realityModelPort ??
            (GetIt.instance.isRegistered<RealityModelPort>()
                ? GetIt.instance<RealityModelPort>()
                : null),
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.instance
                        .isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.instance<GovernedUpwardLearningIntakeService>()
                    : null);

  Future<String> checkIn({
    required String layer,
    required String prompt,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
  }) async {
    final result = await runCheckIn(
      layer: layer,
      prompt: prompt,
      context: context,
      approvedGroupings: approvedGroupings,
    );
    return result.response;
  }

  Future<RealityModelCheckInResult> runCheckIn({
    required String layer,
    required String prompt,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
  }) async {
    await _registerTopLayerRuntime(layer);
    final profileTarget = _resolveGovernanceProfileTarget(
      layer: layer,
      context: context,
    );
    final temporalContext = await _buildTemporalContext();
    final inboundTurn = await _processGovernancePrompt(
      layer: layer,
      prompt: prompt,
      context: context,
    );
    final activeContract = await _loadActiveContract();
    final realityArtifacts = await _buildRealityModelArtifacts(
      layer: layer,
      prompt: prompt,
      context: context,
      approvedGroupings: approvedGroupings,
      inboundTurn: inboundTurn,
      activeContract: activeContract,
    );
    final result = await _runCheckInResponse(
      layer: layer,
      prompt: prompt,
      context: context,
      approvedGroupings: approvedGroupings,
      temporalContext: temporalContext,
      inboundTurn: inboundTurn,
      activeContract: activeContract,
      realityArtifacts: realityArtifacts,
    );

    await _stageAssistantObservation(
      observerId: profileTarget.profileRef,
      layer: layer,
      occurredAtUtc: result.createdAtUtc,
      environmentId: _firstStringValue(context, const <String>[
        'environmentId',
        'replayEnvironmentId',
      ]),
      cityCode: _resolveCityCode(context),
      localityCode: _resolveLocalityCode(layer, context),
      observationKind: 'admin_reality_checkin_response',
      summary: result.response,
      upwardDomainHints: <String>[
        'admin_oversight',
        'reality_checkin',
        layer.trim().toLowerCase(),
      ],
      upwardReferencedEntities: <String>[
        if (result.contract != null)
          'reality_contract:${result.contract!.contractId}',
      ],
      upwardQuestions: _assistantQuestionsFromTurn(inboundTurn),
      upwardSignalTags: <String>[
        'surface:admin_reality_system_check_in',
        'channel:admin_console',
        if (result.hasRealityModelArtifacts)
          'reality_model_artifacts:present'
        else
          'reality_model_artifacts:absent',
      ],
      boundedMetadata: <String, dynamic>{
        'surface': 'admin_reality_system_check_in',
        'layer': layer,
        'approvedGroupingCount': approvedGroupings.length,
        'promptSummary': _assistantPromptSummary(inboundTurn),
        'reasonCodes': inboundTurn?.boundary.reasonCodes ?? const <String>[],
        'realityModelContractId': result.contract?.contractId,
        'realityModelDisposition': result.trace?.disposition.name,
        'realityModelConfidence': result.evaluation?.confidence,
        'realityModelScore': result.evaluation?.score,
      },
    );

    return result;
  }

  Future<List<String>> proposeGroupings({
    required String layer,
    required List<String> observedTypes,
    required List<String> approvedGroupings,
  }) async {
    await _registerTopLayerRuntime(layer);
    if (observedTypes.isEmpty) {
      return const <String>[];
    }

    final proposals = await _runGroupingProposal(
      layer: layer,
      observedTypes: observedTypes,
      approvedGroupings: approvedGroupings,
    );
    await _stageAssistantObservation(
      observerId: _resolveGovernanceProfileTarget(
        layer: layer,
        context: const <String, dynamic>{},
      ).profileRef,
      layer: layer,
      occurredAtUtc: DateTime.now().toUtc(),
      cityCode: _defaultSimulationCityCode,
      localityCode: '${_defaultSimulationCityCode}_$layer',
      observationKind: 'admin_reality_grouping_proposal',
      summary: proposals.isEmpty
          ? 'No new grouping proposals were emitted for $layer oversight.'
          : 'Proposed ${proposals.length} grouping candidates for $layer oversight taxonomy.',
      upwardDomainHints: <String>[
        'admin_oversight',
        'taxonomy',
        layer.trim().toLowerCase(),
      ],
      upwardReferencedEntities: proposals
          .take(4)
          .map((group) => 'grouping:${_normalizeSignalToken(group)}')
          .toList(growable: false),
      upwardSignalTags: const <String>[
        'surface:admin_reality_grouping_proposal',
        'format:json_array_strings',
      ],
      boundedMetadata: <String, dynamic>{
        'surface': 'admin_reality_grouping_proposal',
        'layer': layer,
        'observedTypes': observedTypes,
        'approvedGroupings': approvedGroupings,
        'proposedGroupings': proposals,
      },
    );
    return proposals;
  }

  String resolveGovernanceProfileRef({
    required String layer,
    required Map<String, dynamic> context,
  }) {
    return _resolveGovernanceProfileTarget(
      layer: layer,
      context: context,
    ).profileRef;
  }

  Future<void> recordCheckInFeedback({
    required String layer,
    required String prompt,
    required String modelResponse,
    required String approvedResponse,
    required CheckInFeedbackOutcome outcome,
    required Map<String, dynamic> context,
  }) async {
    final trimmedApprovedResponse = approvedResponse.trim();
    if (trimmedApprovedResponse.isEmpty) {
      return;
    }

    final profileTarget = _resolveGovernanceProfileTarget(
      layer: layer,
      context: context,
    );
    final feedbackTurn =
        await _languageKernelOrchestratorService.processHumanText(
      actorAgentId: profileTarget.actorAgentId,
      rawText: trimmedApprovedResponse,
      consentScopes: const <String>{'governance_runtime_learning'},
      privacyMode: BoundaryPrivacyMode.governance,
      surface: 'admin_reality_system_check_in_feedback',
      channel: 'admin_console',
    );

    _interpretationKernelService.recordInteractionOutcome(
      outcome: outcome.name,
      repairType: outcome.repairType,
    );

    final learningService = _languageLearningService;
    if (feedbackTurn.boundary.learningAllowed && learningService != null) {
      await learningService.analyzeSanitizedArtifact(
        profileRef: profileTarget.profileRef,
        displayRef: profileTarget.displayRef,
        artifact: feedbackTurn.boundary.sanitizedArtifact,
        learningScope: outcome.learningScope,
        surface: 'admin_reality_system_check_in_feedback',
      );
    }

    developer.log(
      'Recorded admin check-in feedback: layer=$layer, outcome=${outcome.name}, promptLength=${prompt.length}, modelLength=${modelResponse.length}, approvedLength=${trimmedApprovedResponse.length}',
      name: _logName,
    );
  }

  Future<RealityModelCheckInResult> _runCheckInResponse({
    required String layer,
    required String prompt,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
    required RuntimeTemporalContext temporalContext,
    required HumanLanguageKernelTurn? inboundTurn,
    required RealityModelContract? activeContract,
    required _RealityModelArtifacts? realityArtifacts,
  }) async {
    final languageRuntimeService = _resolveLanguageRuntimeService();
    if (languageRuntimeService == null) {
      return RealityModelCheckInResult(
        response: _fallbackResponse(
          layer: layer,
          promptEcho: _safePromptEcho(inboundTurn, prompt),
          context: context,
          approvedGroupings: approvedGroupings,
          temporalContext: temporalContext,
          activeContract: activeContract,
          explanation: realityArtifacts?.explanation,
        ),
        createdAtUtc: DateTime.now().toUtc(),
        contract: activeContract,
        evaluation: realityArtifacts?.evaluation,
        trace: realityArtifacts?.trace,
        explanation: realityArtifacts?.explanation,
      );
    }

    final messages = <LanguageTurnMessage>[
      LanguageTurnMessage(
        role: LanguageTurnRole.system,
        content:
            'You are the AVRAI internal oversight model interface for admins. '
            'Respond only with operational insights. Never reveal personal data. '
            'Only agent identity and aggregate metrics are allowed.',
      ),
      LanguageTurnMessage(
        role: LanguageTurnRole.user,
        content: jsonEncode(
          _buildRuntimePromptPayload(
            layer: layer,
            context: context,
            approvedGroupings: approvedGroupings,
            temporalContext: temporalContext,
            inboundTurn: inboundTurn,
            rawPrompt: prompt,
            activeContract: activeContract,
            evaluation: realityArtifacts?.evaluation,
            trace: realityArtifacts?.trace,
            explanation: realityArtifacts?.explanation,
          ),
        ),
      ),
    ];

    try {
      final response = await languageRuntimeService.chat(
        messages: messages,
        context: LanguageRuntimeContext(
          preferences: <String, dynamic>{
            'surface': 'admin_reality_system',
            'layer': layer,
            'privacy_mode': 'agent_identity_only',
          },
        ),
        temperature: 0.25,
        maxTokens: 280,
      );

      final trimmed = response.trim();
      if (trimmed.isEmpty) {
        return RealityModelCheckInResult(
          response: _fallbackResponse(
            layer: layer,
            promptEcho: _safePromptEcho(inboundTurn, prompt),
            context: context,
            approvedGroupings: approvedGroupings,
            temporalContext: temporalContext,
            activeContract: activeContract,
            explanation: realityArtifacts?.explanation,
          ),
          createdAtUtc: DateTime.now().toUtc(),
          contract: activeContract,
          evaluation: realityArtifacts?.evaluation,
          trace: realityArtifacts?.trace,
          explanation: realityArtifacts?.explanation,
        );
      }
      return RealityModelCheckInResult(
        response: trimmed,
        createdAtUtc: DateTime.now().toUtc(),
        contract: activeContract,
        evaluation: realityArtifacts?.evaluation,
        trace: realityArtifacts?.trace,
        explanation: realityArtifacts?.explanation,
      );
    } catch (e, st) {
      developer.log(
        'Runtime check-in failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return RealityModelCheckInResult(
        response: _fallbackResponse(
          layer: layer,
          promptEcho: _safePromptEcho(inboundTurn, prompt),
          context: context,
          approvedGroupings: approvedGroupings,
          temporalContext: temporalContext,
          activeContract: activeContract,
          explanation: realityArtifacts?.explanation,
        ),
        createdAtUtc: DateTime.now().toUtc(),
        contract: activeContract,
        evaluation: realityArtifacts?.evaluation,
        trace: realityArtifacts?.trace,
        explanation: realityArtifacts?.explanation,
      );
    }
  }

  Future<List<String>> _runGroupingProposal({
    required String layer,
    required List<String> observedTypes,
    required List<String> approvedGroupings,
  }) async {
    final languageRuntimeService = _resolveLanguageRuntimeService();
    if (languageRuntimeService == null) {
      return _fallbackGroupingProposals(
        layer: layer,
        observedTypes: observedTypes,
        approvedGroupings: approvedGroupings,
      );
    }

    final messages = <LanguageTurnMessage>[
      LanguageTurnMessage(
        role: LanguageTurnRole.system,
        content: 'Propose concise taxonomy groups for admin oversight. '
            'Return strict JSON array of strings only. '
            'No prose and no personal data.',
      ),
      LanguageTurnMessage(
        role: LanguageTurnRole.user,
        content: jsonEncode(<String, dynamic>{
          'layer': layer,
          'observedTypes': observedTypes,
          'approvedGroupings': approvedGroupings,
          'targetCount': 6,
          'format': 'json_array_strings',
        }),
      ),
    ];

    try {
      final response = await languageRuntimeService.chat(
        messages: messages,
        context: LanguageRuntimeContext(
          preferences: <String, dynamic>{
            'surface': 'admin_reality_grouping_proposal',
            'layer': layer,
            'privacy_mode': 'agent_identity_only',
          },
        ),
        temperature: 0.35,
        maxTokens: 220,
      );

      final parsed = _parseJsonStringList(response);
      if (parsed.isEmpty) {
        return _fallbackGroupingProposals(
          layer: layer,
          observedTypes: observedTypes,
          approvedGroupings: approvedGroupings,
        );
      }

      return parsed
          .where((group) => !approvedGroupings.contains(group))
          .take(8)
          .toList();
    } catch (e, st) {
      developer.log(
        'Grouping proposal failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return _fallbackGroupingProposals(
        layer: layer,
        observedTypes: observedTypes,
        approvedGroupings: approvedGroupings,
      );
    }
  }

  Future<void> _stageAssistantObservation({
    required String observerId,
    required String layer,
    required DateTime occurredAtUtc,
    required String observationKind,
    required String summary,
    required Map<String, dynamic> boundedMetadata,
    List<String> upwardDomainHints = const <String>[],
    List<String> upwardReferencedEntities = const <String>[],
    List<String> upwardQuestions = const <String>[],
    List<String> upwardSignalTags = const <String>[],
    String? environmentId,
    String? cityCode,
    String? localityCode,
  }) async {
    final intakeService = _governedUpwardLearningIntakeService;
    if (intakeService == null) {
      return;
    }
    final normalizedObservationKind = observationKind.trim().isNotEmpty
        ? observationKind.trim()
        : 'bounded_observation';
    final normalizedDomainHints = <String>{
      'assistant',
      ...upwardDomainHints
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
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
      'source:assistant',
      'observation_kind:$normalizedObservationKind',
      ...upwardSignalTags
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
      ...normalizedDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();
    try {
      final airGapArtifact = const UpwardAirGapService().issueArtifact(
        issuedAtUtc: DateTime.now().toUtc(),
        sourceKind: 'assistant_bounded_observation_intake',
        sourceScope: 'assistant',
        originPlane: 'admin_assistant_service',
        sanitizedPayload: <String, dynamic>{
          'observationKind': normalizedObservationKind,
          'summary': summary,
          'layer': layer,
          'boundedMetadata': boundedMetadata,
          'upwardDomainHints': normalizedDomainHints,
          'upwardReferencedEntities': normalizedReferencedEntities,
          'upwardQuestions': normalizedQuestions,
          'upwardSignalTags': normalizedSignalTags,
          if (environmentId != null) 'environmentId': environmentId,
          if (cityCode != null) 'cityCode': cityCode,
          if (localityCode != null) 'localityCode': localityCode,
        },
        pseudonymousActorRef: observerId,
        destinationCeiling: 'reality_model_agent',
        allowedNextStages: const <String>[
          'governed_upward_learning_review',
          'hierarchy_synthesis',
          'reality_model_agent',
        ],
      );
      await intakeService.stageSupervisorAssistantObservationIntake(
        observerId: observerId,
        observerKind: 'assistant',
        occurredAtUtc: occurredAtUtc,
        summary: summary,
        airGapArtifact: airGapArtifact,
        environmentId: environmentId,
        cityCode: cityCode,
        localityCode: localityCode,
        observationKind: normalizedObservationKind,
        upwardDomainHints: normalizedDomainHints,
        upwardReferencedEntities: normalizedReferencedEntities,
        upwardQuestions: normalizedQuestions,
        upwardSignalTags: normalizedSignalTags,
        boundedMetadata: boundedMetadata,
      );
    } catch (e, st) {
      developer.log(
        'Assistant upward observation staging failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  String? _assistantPromptSummary(HumanLanguageKernelTurn? inboundTurn) {
    final sanitizedArtifact = inboundTurn?.boundary.sanitizedArtifact;
    final summary = sanitizedArtifact?.summary.trim();
    if (summary != null && summary.isNotEmpty) {
      return summary;
    }
    final redactedText = sanitizedArtifact?.redactedText.trim();
    if (redactedText != null && redactedText.isNotEmpty) {
      return redactedText;
    }
    return null;
  }

  List<String> _assistantQuestionsFromTurn(
    HumanLanguageKernelTurn? inboundTurn,
  ) {
    return inboundTurn?.boundary.sanitizedArtifact.safeQuestions
            .map((question) => question.trim())
            .where((question) => question.isNotEmpty)
            .toSet()
            .toList(growable: false) ??
        const <String>[];
  }

  LanguageRuntimeService? _resolveLanguageRuntimeService() {
    try {
      if (GetIt.instance.isRegistered<LanguageRuntimeService>()) {
        return GetIt.instance<LanguageRuntimeService>();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _fallbackResponse({
    required String layer,
    required String promptEcho,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
    required RuntimeTemporalContext temporalContext,
    required RealityModelContract? activeContract,
    required RealityModelExplanation? explanation,
  }) {
    final groupingHint = approvedGroupings.isEmpty
        ? 'No approved grouping taxonomy yet.'
        : 'Approved grouping taxonomy count: ${approvedGroupings.length}.';
    final temporalHint = temporalContext.summary;
    final contractHint = activeContract == null
        ? 'Reality-model contract unavailable.'
        : 'Active contract ${activeContract.contractId} (${activeContract.version}) allows ${activeContract.maxEvidenceRefs} evidence refs.';
    final explanationHint = explanation == null
        ? ''
        : ' Reality model summary: ${explanation.summary}';

    if (layer == 'reality') {
      return 'Reality runtime is in guarded fallback mode. $groupingHint '
          '$contractHint$explanationHint $temporalHint Focus remains on coherence, policy alignment, and updating grouping logic after human approvals. '
          'Prompt received: "$promptEcho".';
    }

    if (layer == 'universe') {
      return 'Universe runtime is in guarded fallback mode. $groupingHint '
          '$contractHint$explanationHint $temporalHint Current prep emphasizes cluster health across clubs/communities/events with agent-level identity visibility only.';
    }

    return 'World runtime is in guarded fallback mode. $groupingHint '
        '$contractHint$explanationHint $temporalHint Current prep emphasizes continuity across users, businesses, and service surfaces with privacy-safe agent identity only.';
  }

  Future<RuntimeTemporalContext> _buildTemporalContext() async {
    final service = _runtimeTemporalContextService;
    if (service == null) {
      return RuntimeTemporalContext.empty();
    }
    try {
      return await service.buildContext();
    } catch (e, st) {
      developer.log(
        'Temporal context build failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return RuntimeTemporalContext.empty();
    }
  }

  List<String> _fallbackGroupingProposals({
    required String layer,
    required List<String> observedTypes,
    required List<String> approvedGroupings,
  }) {
    final uniqueObserved = observedTypes.toSet().toList()..sort();
    final proposals = <String>[];

    for (final type in uniqueObserved.take(6)) {
      final prefix = layer == 'universe' ? 'Universe' : 'World';
      proposals.add('$prefix logical cluster: $type');
    }

    return proposals
        .where((proposal) => !approvedGroupings.contains(proposal))
        .toList();
  }

  List<String> _parseJsonStringList(String response) {
    final trimmed = response.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {
      final match = RegExp(r'\[[\s\S]*\]').firstMatch(trimmed);
      if (match == null) return const <String>[];
      try {
        final decoded = jsonDecode(match.group(0)!);
        if (decoded is List) {
          return decoded
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
      } catch (_) {
        return const <String>[];
      }
    }
    return const <String>[];
  }

  Future<void> _registerTopLayerRuntime(String layer) async {
    final registry = _governedRuntimeRegistryService;
    final stratum = _resolveTopLayerStratum(layer);
    if (registry == null || stratum == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    final runtimeIds =
        UrkGovernedRuntimeRegistryService.canonicalTopLayerRuntimeIds(
      stratum: stratum,
      layer: layer,
    );
    for (final runtimeId in runtimeIds) {
      await registry.upsertBinding(
        UrkGovernedRuntimeBinding(
          runtimeId: runtimeId,
          stratum: stratum,
          userId: null,
          aiSignature: null,
          agentId: null,
          source: 'reality_model_checkin_runtime',
          updatedAt: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            isSynchronized: true,
            serverTime: now,
          ),
        ),
      );
    }
  }

  GovernanceStratum? _resolveTopLayerStratum(String layer) {
    switch (layer.trim().toLowerCase()) {
      case 'world':
        return GovernanceStratum.world;
      case 'universe':
      case 'reality':
      case 'universal':
        return GovernanceStratum.universal;
      default:
        return null;
    }
  }

  Future<HumanLanguageKernelTurn?> _processGovernancePrompt({
    required String layer,
    required String prompt,
    required Map<String, dynamic> context,
  }) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return null;
    }

    final profileTarget = _resolveGovernanceProfileTarget(
      layer: layer,
      context: context,
    );
    final turn = await _languageKernelOrchestratorService.processHumanText(
      actorAgentId: profileTarget.actorAgentId,
      rawText: trimmedPrompt,
      consentScopes: const <String>{'governance_runtime_learning'},
      privacyMode: BoundaryPrivacyMode.governance,
      surface: 'admin_reality_system_check_in',
      channel: 'admin_console',
    );

    final learningService = _languageLearningService;
    if (turn.boundary.learningAllowed && learningService != null) {
      await learningService.analyzeSanitizedArtifact(
        profileRef: profileTarget.profileRef,
        displayRef: profileTarget.displayRef,
        artifact: turn.boundary.sanitizedArtifact,
        learningScope: 'governance',
        surface: 'admin_reality_system_check_in',
      );
    }

    return turn;
  }

  Map<String, dynamic> _buildRuntimePromptPayload({
    required String layer,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
    required RuntimeTemporalContext temporalContext,
    required HumanLanguageKernelTurn? inboundTurn,
    required String rawPrompt,
    required RealityModelContract? activeContract,
    required RealityModelEvaluation? evaluation,
    required RealityDecisionTrace? trace,
    required RealityModelExplanation? explanation,
  }) {
    final sanitizedArtifact = inboundTurn?.boundary.sanitizedArtifact;
    return <String, dynamic>{
      'requestType': 'admin_reality_system_check_in',
      'layer': layer,
      'prompt': sanitizedArtifact?.redactedText ?? rawPrompt,
      'promptSummary': sanitizedArtifact?.summary ?? rawPrompt,
      'promptQuestions': sanitizedArtifact?.safeQuestions ?? const <String>[],
      'promptPreferenceSignals': sanitizedArtifact?.safePreferenceSignals
              .map((entry) => entry.toJson())
              .toList(growable: false) ??
          const <Map<String, dynamic>>[],
      'promptBoundary': <String, dynamic>{
        'reasonCodes': inboundTurn?.boundary.reasonCodes ?? const <String>[],
        'disposition':
            inboundTurn?.boundary.disposition.toWireValue() ?? 'local_only',
        'learningAllowed': inboundTurn?.boundary.learningAllowed ?? false,
        'accepted': inboundTurn?.boundary.accepted ?? false,
      },
      'approvedGroupings': approvedGroupings,
      'context': context,
      'temporalContext': temporalContext.toJson(),
      'realityModelContract': activeContract?.toJson(),
      'realityModelEvaluation': evaluation?.toJson(),
      'realityDecisionTrace': trace?.toJson(),
      'realityModelExplanation': explanation?.toJson(),
      'outputRules': const <String>[
        'Under 140 words',
        'Actionable operational summary',
        'Mention current planning/prep direction',
        'No PII, no personal identity details',
      ],
    };
  }

  Future<RealityModelContract?> _loadActiveContract() async {
    final port = _realityModelPort;
    if (port == null) {
      return null;
    }
    try {
      return await port.getActiveContract();
    } catch (e, st) {
      developer.log(
        'Reality-model contract load failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<_RealityModelArtifacts?> _buildRealityModelArtifacts({
    required String layer,
    required String prompt,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
    required HumanLanguageKernelTurn? inboundTurn,
    required RealityModelContract? activeContract,
  }) async {
    final port = _realityModelPort;
    if (port == null || activeContract == null) {
      return null;
    }
    try {
      final profileTarget = _resolveGovernanceProfileTarget(
        layer: layer,
        context: context,
      );
      final request = RealityModelEvaluationRequest(
        requestId:
            'admin_check_in_${layer}_${DateTime.now().toUtc().millisecondsSinceEpoch}',
        subjectId: profileTarget.profileRef,
        domain: _resolveRealityModelDomain(layer),
        candidateRef: 'admin_surface:$layer',
        localityCode: _resolveLocalityCode(layer, context),
        cityCode: _resolveCityCode(context),
        signalTags: _buildRealityModelSignalTags(
          layer: layer,
          context: context,
          approvedGroupings: approvedGroupings,
          inboundTurn: inboundTurn,
        ),
        evidenceRefs: _buildRealityModelEvidenceRefs(
          context: context,
          approvedGroupings: approvedGroupings,
          inboundTurn: inboundTurn,
        ),
        requestedAtUtc: DateTime.now().toUtc(),
        metadata: <String, dynamic>{
          'surface': 'admin_reality_system_check_in',
          'layer': layer,
          if (prompt.trim().isNotEmpty) 'promptPresent': true,
        },
      );
      final evaluation = await port.evaluate(request);
      final disposition = _resolveRealityModelDisposition(
        activeContract: activeContract,
        evaluation: evaluation,
      );
      final trace = await port.traceDecision(
        request: request,
        evaluation: evaluation,
        disposition: disposition,
        evidenceRefs: evaluation.supportingEvidenceRefs,
        localityCode: evaluation.localityCode,
        metadata: <String, dynamic>{
          'surface': 'admin_reality_system_check_in',
          'layer': layer,
        },
      );
      final explanation = await port.buildExplanation(
        trace: trace,
        evaluation: evaluation,
        rendererKind: activeContract.rendererKinds.isEmpty
            ? RealityExplanationRendererKind.template
            : activeContract.rendererKinds.first,
      );
      return _RealityModelArtifacts(
        evaluation: evaluation,
        trace: trace,
        explanation: explanation,
      );
    } catch (e, st) {
      developer.log(
        'Reality-model artifact build failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  RealityDecisionDisposition _resolveRealityModelDisposition({
    required RealityModelContract activeContract,
    required RealityModelEvaluation evaluation,
  }) {
    if (evaluation.confidence < 0.35 || evaluation.score < 0.35) {
      return RealityDecisionDisposition.observe;
    }
    if (evaluation.confidence < 0.55) {
      return activeContract.uncertaintyDisposition ==
              RealityUncertaintyDisposition.askFollowUp
          ? RealityDecisionDisposition.askFollowUp
          : RealityDecisionDisposition.observe;
    }
    if (evaluation.score >= 0.8 && evaluation.confidence >= 0.7) {
      return RealityDecisionDisposition.recommend;
    }
    if (evaluation.score >= 0.6) {
      return RealityDecisionDisposition.compare;
    }
    return RealityDecisionDisposition.observe;
  }

  String _safePromptEcho(
    HumanLanguageKernelTurn? inboundTurn,
    String rawPrompt,
  ) {
    final sanitizedArtifact = inboundTurn?.boundary.sanitizedArtifact;
    if (sanitizedArtifact != null) {
      final safePrompt = sanitizedArtifact.redactedText.trim();
      if (safePrompt.isNotEmpty) {
        return safePrompt;
      }
    }
    return rawPrompt.trim();
  }

  _GovernanceProfileTarget _resolveGovernanceProfileTarget({
    required String layer,
    required Map<String, dynamic> context,
  }) {
    final candidate = _firstStringValue(context, const <String>[
          'operatorUserId',
          'operatorAgentId',
          'operatorId',
          'adminId',
          'actorId',
          'inspectorId',
        ]) ??
        _resolveCurrentAdminOperatorToken() ??
        'layer_$layer';
    final normalized = _normalizeProfileToken(candidate);
    return _GovernanceProfileTarget(
      actorAgentId: 'agt_governance_$normalized',
      profileRef: 'governance_operator_$normalized',
      displayRef: 'governance_operator_$normalized',
    );
  }

  String? _firstStringValue(
    Map<String, dynamic> context,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = context[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _resolveCurrentAdminOperatorToken() {
    try {
      if (GetIt.instance.isRegistered<AdminAuthService>()) {
        final session = GetIt.instance<AdminAuthService>().getCurrentSession();
        final username = session?.username.trim();
        if (username != null && username.isNotEmpty) {
          return 'admin:$username';
        }
      }
    } catch (_) {
      // Best effort only.
    }

    try {
      if (GetIt.instance.isRegistered<SupabaseService>()) {
        final userId = GetIt.instance<SupabaseService>().currentUser?.id.trim();
        if (userId != null && userId.isNotEmpty) {
          return 'user:$userId';
        }
      }
    } catch (_) {
      // Best effort only.
    }

    return null;
  }

  String _normalizeProfileToken(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        );
    return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  RealityModelDomain _resolveRealityModelDomain(String layer) {
    switch (layer.trim().toLowerCase()) {
      case 'reality':
        return RealityModelDomain.locality;
      case 'universe':
        return RealityModelDomain.community;
      case 'world':
        return RealityModelDomain.business;
      default:
        return RealityModelDomain.locality;
    }
  }

  String _resolveCityCode(Map<String, dynamic> context) {
    return _firstStringValue(context, const <String>[
          'cityCode',
          'city',
          'city_code',
        ]) ??
        _defaultSimulationCityCode;
  }

  String _resolveLocalityCode(String layer, Map<String, dynamic> context) {
    return _firstStringValue(context, const <String>[
          'localityCode',
          'locality',
          'locality_code',
        ]) ??
        '${_defaultSimulationCityCode}_$layer';
  }

  List<String> _buildRealityModelSignalTags({
    required String layer,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
    required HumanLanguageKernelTurn? inboundTurn,
  }) {
    final tags = <String>{
      'layer:${_normalizeSignalToken(layer)}',
    };

    for (final grouping in approvedGroupings.take(3)) {
      final token = _normalizeSignalToken(grouping);
      if (token.isNotEmpty) {
        tags.add('group:$token');
      }
    }

    final boundary = inboundTurn?.boundary;
    if (boundary != null) {
      for (final code in boundary.reasonCodes.take(2)) {
        final token = _normalizeSignalToken(code);
        if (token.isNotEmpty) {
          tags.add('boundary:$token');
        }
      }
      final artifact = boundary.sanitizedArtifact;
      for (final signal in artifact.safePreferenceSignals.take(2)) {
        final token = _normalizeSignalToken(signal.kind);
        if (token.isNotEmpty) {
          tags.add('pref:$token');
        }
      }
    }

    for (final key in _boundedContextKeys(context).take(3)) {
      tags.add('ctx:$key');
    }

    return tags.toList(growable: false);
  }

  List<String> _buildRealityModelEvidenceRefs({
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
    required HumanLanguageKernelTurn? inboundTurn,
  }) {
    final refs = <String>[];
    for (final grouping in approvedGroupings.take(2)) {
      final token = _normalizeSignalToken(grouping);
      if (token.isNotEmpty) {
        refs.add('group:$token');
      }
    }
    for (final key in _boundedContextKeys(context).take(2)) {
      refs.add('ctx:$key');
    }
    final boundary = inboundTurn?.boundary;
    if (boundary != null) {
      for (final code in boundary.reasonCodes.take(2)) {
        final token = _normalizeSignalToken(code);
        if (token.isNotEmpty) {
          refs.add('boundary:$token');
        }
      }
    }
    return refs;
  }

  List<String> _boundedContextKeys(Map<String, dynamic> context) {
    return context.keys
        .map(_normalizeSignalToken)
        .where((entry) => entry.isNotEmpty)
        .take(6)
        .toList(growable: false);
  }

  String _normalizeSignalToken(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

class _GovernanceProfileTarget {
  const _GovernanceProfileTarget({
    required this.actorAgentId,
    required this.profileRef,
    required this.displayRef,
  });

  final String actorAgentId;
  final String profileRef;
  final String displayRef;
}

class _RealityModelArtifacts {
  const _RealityModelArtifacts({
    required this.evaluation,
    required this.trace,
    required this.explanation,
  });

  final RealityModelEvaluation evaluation;
  final RealityDecisionTrace trace;
  final RealityModelExplanation explanation;
}
