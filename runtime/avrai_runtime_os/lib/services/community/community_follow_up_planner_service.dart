import 'dart:convert';

import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/community/community_validation.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_suppression_memory_service.dart';
import 'package:get_it/get_it.dart';

class CommunityFollowUpPromptPlan {
  const CommunityFollowUpPromptPlan({
    required this.planId,
    required this.ownerUserId,
    required this.followUpKind,
    required this.sourceEventRef,
    required this.targetLabel,
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

  final String planId;
  final String ownerUserId;
  final String followUpKind;
  final String sourceEventRef;
  final String targetLabel;
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'planId': planId,
      'ownerUserId': ownerUserId,
      'followUpKind': followUpKind,
      'sourceEventRef': sourceEventRef,
      'targetLabel': targetLabel,
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

  factory CommunityFollowUpPromptPlan.fromJson(Map<String, dynamic> json) {
    return CommunityFollowUpPromptPlan(
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      followUpKind: json['followUpKind'] as String? ?? 'community_coordination',
      sourceEventRef: json['sourceEventRef'] as String? ?? '',
      targetLabel: json['targetLabel'] as String? ?? '',
      occurredAtUtc:
          DateTime.tryParse(json['occurredAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      plannedAtUtc:
          DateTime.tryParse(json['plannedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface:
          json['sourceSurface'] as String? ?? 'community_follow_up_planner',
      promptQuestion: json['promptQuestion'] as String? ?? '',
      promptRationale: json['promptRationale'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      channelHint:
          json['channelHint'] as String? ?? 'community_reflection_follow_up',
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

class CommunityFollowUpPromptResponse {
  const CommunityFollowUpPromptResponse({
    required this.responseId,
    required this.planId,
    required this.ownerUserId,
    required this.followUpKind,
    required this.targetLabel,
    required this.respondedAtUtc,
    required this.responseText,
    required this.sourceSurface,
    required this.completionMode,
    this.boundedContext = const <String, dynamic>{},
    this.signalTags = const <String>[],
  });

  final String responseId;
  final String planId;
  final String ownerUserId;
  final String followUpKind;
  final String targetLabel;
  final DateTime respondedAtUtc;
  final String responseText;
  final String sourceSurface;
  final String completionMode;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'responseId': responseId,
      'planId': planId,
      'ownerUserId': ownerUserId,
      'followUpKind': followUpKind,
      'targetLabel': targetLabel,
      'respondedAtUtc': respondedAtUtc.toUtc().toIso8601String(),
      'responseText': responseText,
      'sourceSurface': sourceSurface,
      'completionMode': completionMode,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory CommunityFollowUpPromptResponse.fromJson(Map<String, dynamic> json) {
    return CommunityFollowUpPromptResponse(
      responseId: json['responseId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      followUpKind: json['followUpKind'] as String? ?? 'community_coordination',
      targetLabel: json['targetLabel'] as String? ?? '',
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

class CommunityFollowUpPromptPlannerService {
  static const String _storageKeyPrefix =
      'bham:community_follow_up_prompt_plans:v1:';
  static const String _responseStorageKeyPrefix =
      'bham:community_follow_up_prompt_responses:v1:';

  CommunityFollowUpPromptPlannerService({
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

  final SharedPreferencesCompat? _prefs;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final UpwardAirGapService _upwardAirGapService;
  final BoundedFollowUpPromptPolicyService _promptPolicyService;
  final BoundedFollowUpSuppressionMemoryService _suppressionMemoryService;

  Future<CommunityFollowUpPromptPlan> createCoordinationPlan({
    required Community community,
    required String action,
    required String actorUserId,
    String? affectedRef,
    String? sourceEventId,
  }) async {
    final ownerUserId = actorUserId.trim();
    final existingPlans = await listPlans(ownerUserId);
    final occurredAtUtc = community.updatedAt.toUtc();
    final sourceEventRef =
        'community_coordination:${community.id}:$action:${affectedRef?.trim().isNotEmpty == true ? affectedRef!.trim() : ownerUserId}:${occurredAtUtc.microsecondsSinceEpoch}';
    final existing = existingPlans.where(
      (plan) => plan.sourceEventRef == sourceEventRef,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final planTime = DateTime.now().toUtc();
    final channelHint = 'community_reflection_follow_up';
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((plan) => _isSameUtcDay(plan.plannedAtUtc, planTime))
          .length,
    );
    final domains = <String>{
      'community',
      if ((community.localityCode?.trim().isNotEmpty ?? false)) 'locality',
      if (action == 'create_from_event') 'event',
    }.toList()
      ..sort();
    final targetLabel =
        community.name.trim().isEmpty ? community.id : community.name.trim();
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'community_follow_up',
      targetKey: _suppressionTargetKey(
        followUpKind: 'community_coordination',
        targetLabel: targetLabel,
      ),
    );
    final plan = CommunityFollowUpPromptPlan(
      planId:
          'community_follow_up_plan_${community.id}_${action}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      followUpKind: 'community_coordination',
      sourceEventRef: sourceEventRef,
      targetLabel: targetLabel,
      occurredAtUtc: occurredAtUtc,
      plannedAtUtc: planTime,
      sourceSurface: 'community_coordination',
      promptQuestion: _buildCoordinationPromptQuestion(
        communityName: targetLabel,
        action: action,
      ),
      promptRationale: _buildCoordinationPromptRationale(
        communityName: targetLabel,
        action: action,
      ),
      priority: _coordinationPriority(action),
      channelHint: channelHint,
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      boundedContext: <String, dynamic>{
        'what': 'community_coordination',
        'why': action,
        'how': 'community_service',
        'whenUtc': occurredAtUtc.toIso8601String(),
        'where': community.localityCode ?? community.originalLocality,
        'who': ownerUserId,
        'followUpKind': 'community_coordination',
        'communityId': community.id,
        'communityName': targetLabel,
        'communityCategory': community.category,
        'action': action,
        if (affectedRef?.trim().isNotEmpty ?? false)
          'affectedRef': affectedRef!.trim(),
        if (sourceEventId?.trim().isNotEmpty ?? false)
          'sourceEventId': sourceEventId!.trim(),
        'sourceEventRef': sourceEventRef,
        'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
        'domains': domains,
        'suppressionTargetKey': _suppressionTargetKey(
          followUpKind: 'community_coordination',
          targetLabel: targetLabel,
        ),
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: <String>[
        'source:community_follow_up_plan',
        'kind:community_coordination',
        'action:$action',
        if (sourceEventId?.trim().isNotEmpty ?? false)
          'source_event:${sourceEventId!.trim()}',
        ...domains.map((domain) => 'domain:$domain'),
      ]..sort(),
    );
    await _storePlans(ownerUserId, <CommunityFollowUpPromptPlan>[
      plan,
      ...existingPlans,
    ]);
    return plan;
  }

  Future<CommunityFollowUpPromptPlan> createValidationPlan({
    required CommunityValidation validation,
    required String spotName,
  }) async {
    final ownerUserId = validation.validatorId.trim();
    final existingPlans = await listPlans(ownerUserId);
    final occurredAtUtc = validation.validatedAt.toUtc();
    final sourceEventRef =
        'community_validation:${validation.id}:${occurredAtUtc.microsecondsSinceEpoch}';
    final existing = existingPlans.where(
      (plan) => plan.sourceEventRef == sourceEventRef,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final planTime = DateTime.now().toUtc();
    final channelHint = 'community_reflection_follow_up';
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((plan) => _isSameUtcDay(plan.plannedAtUtc, planTime))
          .length,
    );
    final domains = <String>['community', 'place', 'venue']..sort();
    final targetLabel = spotName.trim().isEmpty ? validation.spotId : spotName;
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'community_follow_up',
      targetKey: _suppressionTargetKey(
        followUpKind: 'community_validation',
        targetLabel: targetLabel,
      ),
    );
    final plan = CommunityFollowUpPromptPlan(
      planId:
          'community_validation_follow_up_plan_${validation.id}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      followUpKind: 'community_validation',
      sourceEventRef: sourceEventRef,
      targetLabel: targetLabel,
      occurredAtUtc: occurredAtUtc,
      plannedAtUtc: planTime,
      sourceSurface: 'community_validation',
      promptQuestion: _buildValidationPromptQuestion(
        spotName: targetLabel,
        status: validation.status.name,
      ),
      promptRationale: _buildValidationPromptRationale(
        spotName: targetLabel,
        status: validation.status.name,
      ),
      priority: _validationPriority(validation.status.name),
      channelHint: channelHint,
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      boundedContext: <String, dynamic>{
        'what': 'community_validation',
        'why': validation.status.name,
        'how': 'community_validation_service',
        'whenUtc': occurredAtUtc.toIso8601String(),
        'where': targetLabel,
        'who': ownerUserId,
        'followUpKind': 'community_validation',
        'spotId': validation.spotId,
        'spotName': targetLabel,
        'validationId': validation.id,
        'validationLevel': validation.level.name,
        'validationStatus': validation.status.name,
        'sourceEventRef': sourceEventRef,
        'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
        'domains': domains,
        'suppressionTargetKey': _suppressionTargetKey(
          followUpKind: 'community_validation',
          targetLabel: targetLabel,
        ),
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: <String>[
        'source:community_follow_up_plan',
        'kind:community_validation',
        'validation_status:${validation.status.name}',
        'validation_level:${validation.level.name}',
        ...domains.map((domain) => 'domain:$domain'),
      ]..sort(),
    );
    await _storePlans(ownerUserId, <CommunityFollowUpPromptPlan>[
      plan,
      ...existingPlans,
    ]);
    return plan;
  }

  Future<List<CommunityFollowUpPromptPlan>> listPlans(
      String ownerUserId) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <CommunityFollowUpPromptPlan>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <CommunityFollowUpPromptPlan>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => CommunityFollowUpPromptPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    } catch (_) {
      return const <CommunityFollowUpPromptPlan>[];
    }
  }

  Future<List<CommunityFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return const <CommunityFollowUpPromptPlan>[];
    }
    final plans = <CommunityFollowUpPromptPlan>[];
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

  Future<List<CommunityFollowUpPromptPlan>> listPendingPlans(
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
                  'community_reflection_follow_up',
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
      familyKey: 'community_follow_up',
      targetKey: _suppressionTargetKey(
        followUpKind: plan.followUpKind,
        targetLabel: plan.targetLabel,
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
      familyKey: 'community_follow_up',
      targetKey: _suppressionTargetKey(
        followUpKind: plan.followUpKind,
        targetLabel: plan.targetLabel,
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

  Future<CommunityFollowUpPromptPlan?> activeAssistantFollowUpPlan(
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

  Future<CommunityFollowUpPromptResponse> completePlanWithResponse({
    required String ownerUserId,
    required String planId,
    required String responseText,
    required String sourceSurface,
  }) async {
    final trimmedResponse = responseText.trim();
    if (trimmedResponse.isEmpty) {
      throw StateError('A bounded follow-up response is required.');
    }
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () => throw StateError('Unknown follow-up plan `$planId`.'),
    );
    final respondedAtUtc = DateTime.now().toUtc();
    final completionMode = sourceSurface == 'assistant_follow_up_chat'
        ? 'assistant_follow_up_chat'
        : 'in_app_follow_up_queue';
    final response = CommunityFollowUpPromptResponse(
      responseId:
          'community_follow_up_response_${respondedAtUtc.microsecondsSinceEpoch}',
      planId: plan.planId,
      ownerUserId: ownerUserId,
      followUpKind: plan.followUpKind,
      targetLabel: plan.targetLabel,
      respondedAtUtc: respondedAtUtc,
      responseText: trimmedResponse,
      sourceSurface: sourceSurface,
      completionMode: completionMode,
      boundedContext: plan.boundedContext,
      signalTags: plan.signalTags,
    );
    await _storeResponses(ownerUserId, <CommunityFollowUpPromptResponse>[
      response,
      ...await listResponses(ownerUserId),
    ]);
    await _updatePlanStatus(
      ownerUserId: ownerUserId,
      planId: planId,
      nextStatus: 'completed_in_app_follow_up',
    );
    await _stageResponseBestEffort(plan: plan, response: response);
    return response;
  }

  Future<List<CommunityFollowUpPromptResponse>> listResponses(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_responseStorageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <CommunityFollowUpPromptResponse>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <CommunityFollowUpPromptResponse>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => CommunityFollowUpPromptResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.respondedAtUtc.compareTo(a.respondedAtUtc));
    } catch (_) {
      return const <CommunityFollowUpPromptResponse>[];
    }
  }

  Future<void> clearAll() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final keys = prefs.getKeys().toList(growable: false);
    for (final key in keys) {
      if (key.startsWith(_storageKeyPrefix) ||
          key.startsWith(_responseStorageKeyPrefix)) {
        await prefs.remove(key);
      }
    }
    final ownerIds = keys
        .where((key) => key.startsWith(_storageKeyPrefix))
        .map((key) => key.substring(_storageKeyPrefix.length))
        .where((ownerUserId) => ownerUserId.isNotEmpty)
        .toSet();
    for (final ownerUserId in ownerIds) {
      await _suppressionMemoryService.clearAll(ownerUserId);
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
    final updated = plans.map((plan) {
      if (plan.planId != planId) {
        return plan;
      }
      final nextContext = boundedContextMutator == null
          ? plan.boundedContext
          : boundedContextMutator(plan.boundedContext);
      return CommunityFollowUpPromptPlan(
        planId: plan.planId,
        ownerUserId: plan.ownerUserId,
        followUpKind: plan.followUpKind,
        sourceEventRef: plan.sourceEventRef,
        targetLabel: plan.targetLabel,
        occurredAtUtc: plan.occurredAtUtc,
        plannedAtUtc: plan.plannedAtUtc,
        sourceSurface: plan.sourceSurface,
        promptQuestion: plan.promptQuestion,
        promptRationale: plan.promptRationale,
        priority: plan.priority,
        channelHint: plan.channelHint,
        status: nextStatus,
        boundedContext: nextContext,
        signalTags: plan.signalTags,
      );
    }).toList(growable: false);
    await _storePlans(ownerUserId, updated);
  }

  Future<void> _storePlans(
    String ownerUserId,
    List<CommunityFollowUpPromptPlan> plans,
  ) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setString(
      _storageKey(ownerUserId),
      jsonEncode(plans.map((plan) => plan.toJson()).toList(growable: false)),
    );
  }

  Future<void> _storeResponses(
    String ownerUserId,
    List<CommunityFollowUpPromptResponse> responses,
  ) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setString(
      _responseStorageKey(ownerUserId),
      jsonEncode(
        responses.map((response) => response.toJson()).toList(growable: false),
      ),
    );
  }

  Future<void> _stageResponseBestEffort({
    required CommunityFollowUpPromptPlan plan,
    required CommunityFollowUpPromptResponse response,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final airGapArtifact = _upwardAirGapService.issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'community_follow_up_response_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: response.respondedAtUtc,
        sanitizedPayload: <String, dynamic>{
          'sourceKind': 'community_follow_up_response_intake',
          'followUpKind': plan.followUpKind,
          'targetLabel': plan.targetLabel,
          'promptQuestion': plan.promptQuestion,
          'promptRationale': plan.promptRationale,
          'responseText': response.responseText,
          'completionMode': response.completionMode,
          'sourceSurface': response.sourceSurface,
          'boundedContext': plan.boundedContext,
          'signalTags': plan.signalTags,
        },
      );
      await service.stageCommunityFollowUpResponseIntake(
        ownerUserId: response.ownerUserId,
        followUpKind: plan.followUpKind,
        targetLabel: plan.targetLabel,
        occurredAtUtc: response.respondedAtUtc,
        sourceSurface: response.sourceSurface,
        promptQuestion: plan.promptQuestion,
        promptRationale: plan.promptRationale,
        responseText: response.responseText,
        completionMode: response.completionMode,
        airGapArtifact: airGapArtifact,
        metadata: <String, dynamic>{
          'boundedContext': plan.boundedContext,
          'signalTags': plan.signalTags,
          'domains': _extractStringList(plan.boundedContext['domains']),
        },
      );
    } catch (_) {
      // Best-effort only.
    }
  }

  String _storageKey(String ownerUserId) => '$_storageKeyPrefix$ownerUserId';

  String _responseStorageKey(String ownerUserId) =>
      '$_responseStorageKeyPrefix$ownerUserId';

  String _suppressionTargetKey({
    required String followUpKind,
    required String targetLabel,
  }) {
    return '$followUpKind:${targetLabel.trim()}';
  }

  DateTime? _nextEligibleAtUtcFromPlan(CommunityFollowUpPromptPlan plan) {
    final value = plan.boundedContext['nextEligibleAtUtc']?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  bool _isSameUtcDay(DateTime a, DateTime b) {
    final left = a.toUtc();
    final right = b.toUtc();
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  int _priorityRank(String priority) {
    switch (priority) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  List<String> _extractStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw.whereType<String>().toList(growable: false);
  }

  String _buildCoordinationPromptQuestion({
    required String communityName,
    required String action,
  }) {
    if (action == 'remove_member') {
      return 'What about "$communityName" made leaving feel right, and what should AVRAI remember from that?';
    }
    if (action == 'add_member') {
      return 'What about "$communityName" made joining feel right, and what should AVRAI remember from that?';
    }
    return 'What about "$communityName" should AVRAI remember from this community action?';
  }

  String _buildCoordinationPromptRationale({
    required String communityName,
    required String action,
  }) {
    return 'A bounded follow-up can clarify what the $action action around "$communityName" should mean before broader community learning.';
  }

  String _buildValidationPromptQuestion({
    required String spotName,
    required String status,
  }) {
    return 'What should AVRAI remember about "$spotName" from your $status validation?';
  }

  String _buildValidationPromptRationale({
    required String spotName,
    required String status,
  }) {
    return 'A bounded follow-up can clarify what your $status validation for "$spotName" should change before broader community data learning.';
  }

  String _coordinationPriority(String action) {
    switch (action) {
      case 'remove_member':
        return 'high';
      case 'create_from_event':
        return 'medium';
      default:
        return 'medium';
    }
  }

  String _validationPriority(String status) {
    switch (status) {
      case 'rejected':
      case 'needsReview':
        return 'high';
      default:
        return 'medium';
    }
  }
}
