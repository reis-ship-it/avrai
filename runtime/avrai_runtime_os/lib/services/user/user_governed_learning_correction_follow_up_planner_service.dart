import 'dart:convert';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_suppression_memory_service.dart';
import 'package:get_it/get_it.dart';

class UserGovernedLearningCorrectionFollowUpPlan {
  final String planId;
  final String ownerUserId;
  final String targetEnvelopeId;
  final String targetSourceId;
  final String targetSummary;
  final String correctionText;
  final DateTime occurredAtUtc;
  final DateTime plannedAtUtc;
  final String sourceSurface;
  final String promptQuestion;
  final String promptRationale;
  final String priority;
  final String channelHint;
  final String status;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  const UserGovernedLearningCorrectionFollowUpPlan({
    required this.planId,
    required this.ownerUserId,
    required this.targetEnvelopeId,
    required this.targetSourceId,
    required this.targetSummary,
    required this.correctionText,
    required this.occurredAtUtc,
    required this.plannedAtUtc,
    required this.sourceSurface,
    required this.promptQuestion,
    required this.promptRationale,
    required this.priority,
    required this.channelHint,
    required this.status,
    this.boundedContext = const <String, dynamic>{},
    this.signalTags = const <String>[],
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'planId': planId,
      'ownerUserId': ownerUserId,
      'targetEnvelopeId': targetEnvelopeId,
      'targetSourceId': targetSourceId,
      'targetSummary': targetSummary,
      'correctionText': correctionText,
      'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
      'plannedAtUtc': plannedAtUtc.toUtc().toIso8601String(),
      'sourceSurface': sourceSurface,
      'promptQuestion': promptQuestion,
      'promptRationale': promptRationale,
      'priority': priority,
      'channelHint': channelHint,
      'status': status,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory UserGovernedLearningCorrectionFollowUpPlan.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserGovernedLearningCorrectionFollowUpPlan(
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      targetEnvelopeId: json['targetEnvelopeId'] as String? ?? '',
      targetSourceId: json['targetSourceId'] as String? ?? '',
      targetSummary: json['targetSummary'] as String? ?? '',
      correctionText: json['correctionText'] as String? ?? '',
      occurredAtUtc:
          DateTime.tryParse(json['occurredAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      plannedAtUtc:
          DateTime.tryParse(json['plannedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'data_center',
      promptQuestion: json['promptQuestion'] as String? ?? '',
      promptRationale: json['promptRationale'] as String? ?? '',
      priority: json['priority'] as String? ?? 'high',
      channelHint: json['channelHint'] as String? ??
          'bounded_correction_scope_follow_up',
      status: json['status'] as String? ?? 'planned_local_bounded_follow_up',
      boundedContext: Map<String, dynamic>.from(
        json['boundedContext'] as Map? ?? const <String, dynamic>{},
      ),
      signalTags: (json['signalTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

class UserGovernedLearningCorrectionFollowUpResponse {
  final String responseId;
  final String planId;
  final String ownerUserId;
  final String targetEnvelopeId;
  final String targetSourceId;
  final String targetSummary;
  final String correctionText;
  final DateTime respondedAtUtc;
  final String responseText;
  final String sourceSurface;
  final String completionMode;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  const UserGovernedLearningCorrectionFollowUpResponse({
    required this.responseId,
    required this.planId,
    required this.ownerUserId,
    required this.targetEnvelopeId,
    required this.targetSourceId,
    required this.targetSummary,
    required this.correctionText,
    required this.respondedAtUtc,
    required this.responseText,
    required this.sourceSurface,
    required this.completionMode,
    this.boundedContext = const <String, dynamic>{},
    this.signalTags = const <String>[],
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'responseId': responseId,
      'planId': planId,
      'ownerUserId': ownerUserId,
      'targetEnvelopeId': targetEnvelopeId,
      'targetSourceId': targetSourceId,
      'targetSummary': targetSummary,
      'correctionText': correctionText,
      'respondedAtUtc': respondedAtUtc.toUtc().toIso8601String(),
      'responseText': responseText,
      'sourceSurface': sourceSurface,
      'completionMode': completionMode,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory UserGovernedLearningCorrectionFollowUpResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserGovernedLearningCorrectionFollowUpResponse(
      responseId: json['responseId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      targetEnvelopeId: json['targetEnvelopeId'] as String? ?? '',
      targetSourceId: json['targetSourceId'] as String? ?? '',
      targetSummary: json['targetSummary'] as String? ?? '',
      correctionText: json['correctionText'] as String? ?? '',
      respondedAtUtc:
          DateTime.tryParse(json['respondedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      responseText: json['responseText'] as String? ?? '',
      sourceSurface: json['sourceSurface'] as String? ?? 'unknown',
      completionMode:
          json['completionMode'] as String? ?? 'in_app_follow_up_queue',
      boundedContext: Map<String, dynamic>.from(
        json['boundedContext'] as Map? ?? const <String, dynamic>{},
      ),
      signalTags: (json['signalTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

class UserGovernedLearningCorrectionFollowUpPromptPlannerService {
  static const String _storageKeyPrefix =
      'bham:user_governed_learning_correction_follow_up_plans:v1:';
  static const String _responseStorageKeyPrefix =
      'bham:user_governed_learning_correction_follow_up_responses:v1:';

  final SharedPreferencesCompat? _prefs;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final UpwardAirGapService _upwardAirGapService;
  final BoundedFollowUpPromptPolicyService _promptPolicyService;
  final BoundedFollowUpSuppressionMemoryService _suppressionMemoryService;

  UserGovernedLearningCorrectionFollowUpPromptPlannerService({
    SharedPreferencesCompat? prefs,
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
    UpwardAirGapService? upwardAirGapService,
    BoundedFollowUpPromptPolicyService? promptPolicyService,
    BoundedFollowUpSuppressionMemoryService? suppressionMemoryService,
  })  : _prefs = prefs ??
            (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                ? GetIt.instance<SharedPreferencesCompat>()
                : null),
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.instance
                        .isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.instance<GovernedUpwardLearningIntakeService>()
                    : null),
        _upwardAirGapService =
            upwardAirGapService ?? const UpwardAirGapService(),
        _promptPolicyService =
            promptPolicyService ?? BoundedFollowUpPromptPolicyService(),
        _suppressionMemoryService = suppressionMemoryService ??
            BoundedFollowUpSuppressionMemoryService(
              prefs: prefs,
              promptPolicyService:
                  promptPolicyService ?? BoundedFollowUpPromptPolicyService(),
            );

  Future<UserGovernedLearningCorrectionFollowUpPlan> createPlan({
    required String ownerUserId,
    required String targetEnvelopeId,
    required String targetSourceId,
    required String targetSummary,
    required String correctionText,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    List<String> domainHints = const <String>[],
    List<String> referencedEntities = const <String>[],
    String? localityCode,
    String? cityCode,
    String? sourceProvider,
  }) async {
    final existingPlans = await listPlans(ownerUserId);
    final sourceEventRef =
        '$targetEnvelopeId:${occurredAtUtc.toUtc().millisecondsSinceEpoch}:correction_follow_up';
    final existing = existingPlans.where(
      (plan) =>
          plan.targetEnvelopeId == targetEnvelopeId &&
          plan.correctionText == correctionText &&
          plan.boundedContext['sourceEventRef'] == sourceEventRef,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final planTime = DateTime.now().toUtc();
    final channelHint = 'bounded_correction_scope_follow_up';
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((plan) => _isSameUtcDay(plan.plannedAtUtc, planTime))
          .length,
    );
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'explicit_correction_follow_up',
      targetKey: _suppressionTargetKey(targetEnvelopeId: targetEnvelopeId),
    );
    final plan = UserGovernedLearningCorrectionFollowUpPlan(
      planId:
          'correction_follow_up_plan_${targetEnvelopeId}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      targetEnvelopeId: targetEnvelopeId,
      targetSourceId: targetSourceId,
      targetSummary: targetSummary,
      correctionText: correctionText,
      occurredAtUtc: occurredAtUtc.toUtc(),
      plannedAtUtc: planTime,
      sourceSurface: sourceSurface,
      promptQuestion: _buildPromptQuestion(targetSummary: targetSummary),
      promptRationale: _buildPromptRationale(targetSummary: targetSummary),
      priority: 'high',
      channelHint: channelHint,
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      boundedContext: <String, dynamic>{
        'what': correctionText,
        'why': targetSummary,
        'how': sourceSurface,
        'whenUtc': occurredAtUtc.toUtc().toIso8601String(),
        'where': localityCode?.trim().isNotEmpty == true
            ? localityCode!.trim()
            : cityCode?.trim().isNotEmpty == true
                ? cityCode!.trim()
                : 'unknown_locality',
        'who': 'governed_learning_user_correction',
        'sourceProvider': sourceProvider ?? 'explicit_correction_intake',
        'targetEnvelopeId': targetEnvelopeId,
        'targetSourceId': targetSourceId,
        'sourceEventRef': sourceEventRef,
        'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
        'domainHints': domainHints,
        'referencedEntities': referencedEntities,
        'suppressionTargetKey': _suppressionTargetKey(
          targetEnvelopeId: targetEnvelopeId,
        ),
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: <String>[
        'source:explicit_correction_follow_up_plan',
        'action:correct',
        'priority:high',
        if (sourceProvider?.trim().isNotEmpty ?? false)
          'source_provider:${sourceProvider!.trim()}',
        ...domainHints.map((domain) => 'domain:$domain'),
      ]..sort(),
    );
    await _prefs?.setString(
      _storageKey(ownerUserId),
      jsonEncode(
        <Map<String, dynamic>>[
          plan.toJson(),
          ...existingPlans.map((item) => item.toJson()),
        ],
      ),
    );
    return plan;
  }

  Future<List<UserGovernedLearningCorrectionFollowUpPlan>> listPlans(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <UserGovernedLearningCorrectionFollowUpPlan>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <UserGovernedLearningCorrectionFollowUpPlan>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => UserGovernedLearningCorrectionFollowUpPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    } catch (_) {
      return const <UserGovernedLearningCorrectionFollowUpPlan>[];
    }
  }

  Future<List<UserGovernedLearningCorrectionFollowUpPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return const <UserGovernedLearningCorrectionFollowUpPlan>[];
    }
    final plans = <UserGovernedLearningCorrectionFollowUpPlan>[];
    final keys = prefs.getKeys().toList()..sort();
    for (final key in keys) {
      if (!key.startsWith(_storageKeyPrefix)) {
        continue;
      }
      final ownerUserId = key.substring(_storageKeyPrefix.length);
      if (ownerUserId.isEmpty) {
        continue;
      }
      plans.addAll(await listPlans(ownerUserId));
    }
    plans.sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    if (limit <= 0 || plans.length <= limit) {
      return plans;
    }
    return plans.take(limit).toList(growable: false);
  }

  Future<List<UserGovernedLearningCorrectionFollowUpPlan>> listPendingPlans(
    String ownerUserId, {
    int limit = 3,
  }) async {
    final clampedLimit = _promptPolicyService.clampPendingLimit(limit);
    final nowUtc = DateTime.now().toUtc();
    final pending = (await listPlans(ownerUserId))
        .where(
          (plan) =>
              plan.status != 'suppressed_local_bounded_follow_up' &&
              plan.status != 'dont_ask_again_local_bounded_follow_up' &&
              plan.status != 'completed_in_app_follow_up' &&
              plan.status != 'dismissed_in_app_follow_up' &&
              plan.status != 'assistant_follow_up_offered' &&
              _promptPolicyService.isEligible(
                nextEligibleAtUtc: _nextEligibleAtUtcFromPlan(plan),
                nowUtc: nowUtc,
              ),
        )
        .toList(growable: false);
    pending.sort((a, b) {
      final priorityCompare =
          _priorityRank(b.priority) - _priorityRank(a.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return b.plannedAtUtc.compareTo(a.plannedAtUtc);
    });
    if (clampedLimit <= 0 || pending.length <= clampedLimit) {
      return pending;
    }
    return pending.take(clampedLimit).toList(growable: false);
  }

  Future<void> deferPlan({
    required String ownerUserId,
    required String planId,
  }) async {
    await _updatePlanStatus(
      ownerUserId: ownerUserId,
      planId: planId,
      nextStatus: 'deferred_in_app_follow_up',
      boundedContextMutator: (current) => <String, dynamic>{
        ...current,
        'nextEligibleAtUtc': _promptPolicyService
            .scheduleDeferredEligibility(
              deferredAtUtc: DateTime.now().toUtc(),
              channelHint: current['channelHint']?.toString() ??
                  'bounded_correction_scope_follow_up',
            )
            .toIso8601String(),
      },
    );
  }

  Future<void> dismissPlan({
    required String ownerUserId,
    required String planId,
  }) async {
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () => throw StateError('Unknown follow-up plan `$planId`.'),
    );
    await _suppressionMemoryService.suppressForDismissal(
      ownerUserId: ownerUserId,
      familyKey: 'explicit_correction_follow_up',
      targetKey: _suppressionTargetKey(
        targetEnvelopeId: plan.targetEnvelopeId,
      ),
      channelHint: plan.channelHint,
    );
    await _updatePlanStatus(
      ownerUserId: ownerUserId,
      planId: planId,
      nextStatus: 'dismissed_in_app_follow_up',
    );
  }

  Future<void> dontAskAgainForPlan({
    required String ownerUserId,
    required String planId,
  }) async {
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () => throw StateError('Unknown follow-up plan `$planId`.'),
    );
    await _suppressionMemoryService.suppressForDismissal(
      ownerUserId: ownerUserId,
      familyKey: 'explicit_correction_follow_up',
      targetKey: _suppressionTargetKey(
        targetEnvelopeId: plan.targetEnvelopeId,
      ),
      channelHint: plan.channelHint,
      permanent: true,
      reason: 'dont_ask_again_local_bounded_follow_up',
    );
    await _updatePlanStatus(
      ownerUserId: ownerUserId,
      planId: planId,
      nextStatus: 'dont_ask_again_local_bounded_follow_up',
      boundedContextMutator: (current) => <String, dynamic>{
        ...current,
        'suppressedPermanently': true,
        'suppressionReason': 'dont_ask_again_local_bounded_follow_up',
      },
    );
  }

  Future<void> markPlanOfferedForAssistant({
    required String ownerUserId,
    required String planId,
  }) async {
    await _updatePlanStatus(
      ownerUserId: ownerUserId,
      planId: planId,
      nextStatus: 'assistant_follow_up_offered',
    );
  }

  Future<UserGovernedLearningCorrectionFollowUpPlan?>
      activeAssistantFollowUpPlan(
    String ownerUserId,
  ) async {
    final plans = await listPlans(ownerUserId);
    for (final plan in plans) {
      if (plan.status == 'assistant_follow_up_offered') {
        return plan;
      }
    }
    return null;
  }

  Future<UserGovernedLearningCorrectionFollowUpResponse>
      completePlanWithResponse({
    required String ownerUserId,
    required String planId,
    required String responseText,
    String sourceSurface = 'data_center_follow_up_queue',
  }) async {
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () => throw StateError(
        'Unknown correction follow-up plan: $planId',
      ),
    );
    final responseTime = DateTime.now().toUtc();
    final response = UserGovernedLearningCorrectionFollowUpResponse(
      responseId:
          'correction_follow_up_response_${plan.planId}_${responseTime.millisecondsSinceEpoch}',
      planId: plan.planId,
      ownerUserId: ownerUserId,
      targetEnvelopeId: plan.targetEnvelopeId,
      targetSourceId: plan.targetSourceId,
      targetSummary: plan.targetSummary,
      correctionText: plan.correctionText,
      respondedAtUtc: responseTime,
      responseText: responseText.trim(),
      sourceSurface: sourceSurface,
      completionMode: _completionModeForSourceSurface(sourceSurface),
      boundedContext: <String, dynamic>{
        'promptQuestion': plan.promptQuestion,
        'priority': plan.priority,
        'channelHint': plan.channelHint,
        'sourceEventRef': plan.boundedContext['sourceEventRef'],
        'what': plan.boundedContext['what'],
        'why': plan.boundedContext['why'],
        'how': plan.boundedContext['how'],
        'whenUtc': plan.boundedContext['whenUtc'],
        'where': plan.boundedContext['where'],
        'who': plan.boundedContext['who'],
      },
      signalTags: <String>[
        ...plan.signalTags,
        'prompt_response:completed',
        'completion_mode:${_completionModeForSourceSurface(sourceSurface)}',
      ],
    );
    final responses = await listResponses(ownerUserId);
    await _prefs?.setString(
      _responseStorageKey(ownerUserId),
      jsonEncode(
        <Map<String, dynamic>>[
          response.toJson(),
          ...responses.map((item) => item.toJson()),
        ],
      ),
    );
    await _updatePlanStatus(
      ownerUserId: ownerUserId,
      planId: planId,
      nextStatus: 'completed_in_app_follow_up',
    );
    await _stageCompletedResponseBestEffort(plan: plan, response: response);
    return response;
  }

  Future<List<UserGovernedLearningCorrectionFollowUpResponse>> listResponses(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_responseStorageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <UserGovernedLearningCorrectionFollowUpResponse>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <UserGovernedLearningCorrectionFollowUpResponse>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => UserGovernedLearningCorrectionFollowUpResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.respondedAtUtc.compareTo(a.respondedAtUtc));
    } catch (_) {
      return const <UserGovernedLearningCorrectionFollowUpResponse>[];
    }
  }

  Future<void> clearAll(String ownerUserId) async {
    await _prefs?.remove(_storageKey(ownerUserId));
    await _prefs?.remove(_responseStorageKey(ownerUserId));
    await _suppressionMemoryService.clearAll(ownerUserId);
  }

  String _storageKey(String ownerUserId) => '$_storageKeyPrefix$ownerUserId';
  String _responseStorageKey(String ownerUserId) =>
      '$_responseStorageKeyPrefix$ownerUserId';

  String _suppressionTargetKey({
    required String targetEnvelopeId,
  }) {
    return 'correction:${targetEnvelopeId.trim()}';
  }

  String _buildPromptQuestion({
    required String targetSummary,
  }) {
    return 'Should I treat your correction about "$targetSummary" as durable, or only for a specific situation?';
  }

  String _buildPromptRationale({
    required String targetSummary,
  }) {
    return 'Explicit corrections are strong, but bounded follow-up helps clarify whether "$targetSummary" should change a durable preference, a narrow situational rule, or just one earlier recommendation.';
  }

  String _completionModeForSourceSurface(String sourceSurface) {
    switch (sourceSurface) {
      case 'assistant_follow_up_chat':
        return 'assistant_follow_up_chat';
      case 'data_center_follow_up_queue':
      case 'in_app_follow_up_queue':
        return 'in_app_follow_up_queue';
      default:
        return 'bounded_follow_up_response';
    }
  }

  Future<void> _stageCompletedResponseBestEffort({
    required UserGovernedLearningCorrectionFollowUpPlan plan,
    required UserGovernedLearningCorrectionFollowUpResponse response,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null || response.responseText.trim().isEmpty) {
      return;
    }
    try {
      final airGapArtifact = _upwardAirGapService.issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'explicit_correction_follow_up_response_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'targetEnvelopeId': plan.targetEnvelopeId,
          'targetSourceId': plan.targetSourceId,
          'targetSummary': plan.targetSummary,
          'correctionText': plan.correctionText,
          'promptQuestion': plan.promptQuestion,
          'promptRationale': plan.promptRationale,
          'responseText': response.responseText,
          'sourceSurface': response.sourceSurface,
          'completionMode': response.completionMode,
          'sourceEventRef': plan.boundedContext['sourceEventRef'],
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
        },
      );
      await service.stageExplicitCorrectionFollowUpResponseIntake(
        ownerUserId: plan.ownerUserId,
        targetEnvelopeId: plan.targetEnvelopeId,
        targetSourceId: plan.targetSourceId,
        targetSummary: plan.targetSummary,
        correctionText: plan.correctionText,
        occurredAtUtc: response.respondedAtUtc,
        sourceSurface: response.sourceSurface,
        promptQuestion: plan.promptQuestion,
        promptRationale: plan.promptRationale,
        responseText: response.responseText,
        completionMode: response.completionMode,
        airGapArtifact: airGapArtifact,
        metadata: <String, dynamic>{
          'sourceEventRef': plan.boundedContext['sourceEventRef'],
          'planSourceSurface': plan.sourceSurface,
          'priority': plan.priority,
          'channelHint': plan.channelHint,
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
          'domains': plan.signalTags
              .where((tag) => tag.startsWith('domain:'))
              .map((tag) => tag.substring('domain:'.length))
              .toList(growable: false),
          'referencedEntities':
              _extractStringList(plan.boundedContext['referencedEntities']),
        },
      );
    } catch (_) {
      // Best-effort only. Local response storage must remain durable.
    }
  }

  Future<void> _updatePlanStatus({
    required String ownerUserId,
    required String planId,
    required String nextStatus,
    Map<String, dynamic> Function(Map<String, dynamic> current)?
        boundedContextMutator,
  }) async {
    final plans = await listPlans(ownerUserId);
    final updatedPlans = plans.map((plan) {
      if (plan.planId != planId) {
        return plan;
      }
      final nextBoundedContext = boundedContextMutator == null
          ? plan.boundedContext
          : boundedContextMutator(
              <String, dynamic>{
                ...plan.boundedContext,
                'channelHint': plan.channelHint,
              },
            )
        ..remove('channelHint');
      return UserGovernedLearningCorrectionFollowUpPlan(
        planId: plan.planId,
        ownerUserId: plan.ownerUserId,
        targetEnvelopeId: plan.targetEnvelopeId,
        targetSourceId: plan.targetSourceId,
        targetSummary: plan.targetSummary,
        correctionText: plan.correctionText,
        occurredAtUtc: plan.occurredAtUtc,
        plannedAtUtc: plan.plannedAtUtc,
        sourceSurface: plan.sourceSurface,
        promptQuestion: plan.promptQuestion,
        promptRationale: plan.promptRationale,
        priority: plan.priority,
        channelHint: plan.channelHint,
        status: nextStatus,
        boundedContext: nextBoundedContext,
        signalTags: plan.signalTags,
      );
    }).toList(growable: false);
    await _prefs?.setString(
      _storageKey(ownerUserId),
      jsonEncode(updatedPlans.map((plan) => plan.toJson()).toList()),
    );
  }

  int _priorityRank(String priority) {
    switch (priority) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  DateTime? _nextEligibleAtUtcFromPlan(
    UserGovernedLearningCorrectionFollowUpPlan plan,
  ) {
    final raw = plan.boundedContext['nextEligibleAtUtc']?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  bool _isSameUtcDay(DateTime a, DateTime b) {
    final utcA = a.toUtc();
    final utcB = b.toUtc();
    return utcA.year == utcB.year &&
        utcA.month == utcB.month &&
        utcA.day == utcB.day;
  }

  List<String> _extractStringList(dynamic value) {
    return (value as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .where((entry) => entry.trim().isNotEmpty)
        .map((entry) => entry.trim())
        .toList(growable: false);
  }
}
