import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_runtime_os/kernel/interpretation/interpretation_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governed_runtime_registry_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
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

/// Runtime-backed check-in service for admin reality-system oversight pages.
///
/// Uses the app's language runtime boundary when available and falls back to
/// deterministic responses if runtime chat is unavailable.
class RealityModelCheckInService {
  static const String _logName = 'RealityModelCheckInService';
  final UrkGovernedRuntimeRegistryService? _governedRuntimeRegistryService;
  final RuntimeTemporalContextService? _runtimeTemporalContextService;
  final LanguageKernelOrchestratorService _languageKernelOrchestratorService;
  final LanguagePatternLearningService? _languageLearningService;
  final InterpretationKernelService _interpretationKernelService;

  RealityModelCheckInService({
    UrkGovernedRuntimeRegistryService? governedRuntimeRegistryService,
    RuntimeTemporalContextService? runtimeTemporalContextService,
    LanguageKernelOrchestratorService? languageKernelOrchestratorService,
    LanguagePatternLearningService? languageLearningService,
    InterpretationKernelService? interpretationKernelService,
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
            interpretationKernelService ?? InterpretationKernelService();

  Future<String> checkIn({
    required String layer,
    required String prompt,
    required Map<String, dynamic> context,
    required List<String> approvedGroupings,
  }) async {
    await _registerTopLayerRuntime(layer);
    final temporalContext = await _buildTemporalContext();
    final inboundTurn = await _processGovernancePrompt(
      layer: layer,
      prompt: prompt,
      context: context,
    );
    final languageRuntimeService = _resolveLanguageRuntimeService();
    if (languageRuntimeService == null) {
      return _fallbackResponse(
        layer: layer,
        promptEcho: _safePromptEcho(inboundTurn, prompt),
        context: context,
        approvedGroupings: approvedGroupings,
        temporalContext: temporalContext,
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
        return _fallbackResponse(
          layer: layer,
          promptEcho: _safePromptEcho(inboundTurn, prompt),
          context: context,
          approvedGroupings: approvedGroupings,
          temporalContext: temporalContext,
        );
      }
      return trimmed;
    } catch (e, st) {
      developer.log(
        'Runtime check-in failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return _fallbackResponse(
        layer: layer,
        promptEcho: _safePromptEcho(inboundTurn, prompt),
        context: context,
        approvedGroupings: approvedGroupings,
        temporalContext: temporalContext,
      );
    }
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
  }) {
    final groupingHint = approvedGroupings.isEmpty
        ? 'No approved grouping taxonomy yet.'
        : 'Approved grouping taxonomy count: ${approvedGroupings.length}.';
    final temporalHint = temporalContext.summary;

    if (layer == 'reality') {
      return 'Reality runtime is in guarded fallback mode. $groupingHint '
          '$temporalHint Focus remains on coherence, policy alignment, and updating grouping logic after human approvals. '
          'Prompt received: "$promptEcho".';
    }

    if (layer == 'universe') {
      return 'Universe runtime is in guarded fallback mode. $groupingHint '
          '$temporalHint Current prep emphasizes cluster health across clubs/communities/events with agent-level identity visibility only.';
    }

    return 'World runtime is in guarded fallback mode. $groupingHint '
        '$temporalHint Current prep emphasizes continuity across users, businesses, and service surfaces with privacy-safe agent identity only.';
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
      'outputRules': const <String>[
        'Under 140 words',
        'Actionable operational summary',
        'Mention current planning/prep direction',
        'No PII, no personal identity details',
      ],
    };
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
