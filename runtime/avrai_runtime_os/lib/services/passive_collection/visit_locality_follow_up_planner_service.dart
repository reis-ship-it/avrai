import 'dart:convert';

import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_suppression_memory_service.dart';
import 'package:get_it/get_it.dart';

class VisitLocalityFollowUpPromptPlan {
  const VisitLocalityFollowUpPromptPlan({
    required this.planId,
    required this.ownerUserId,
    required this.observationKind,
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
  final String observationKind;
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
      'observationKind': observationKind,
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

  factory VisitLocalityFollowUpPromptPlan.fromJson(Map<String, dynamic> json) {
    return VisitLocalityFollowUpPromptPlan(
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      observationKind: json['observationKind'] as String? ?? 'visit',
      sourceEventRef: json['sourceEventRef'] as String? ?? '',
      targetLabel: json['targetLabel'] as String? ?? '',
      occurredAtUtc:
          DateTime.tryParse(json['occurredAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      plannedAtUtc:
          DateTime.tryParse(json['plannedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'behavior_follow_up',
      promptQuestion: json['promptQuestion'] as String? ?? '',
      promptRationale: json['promptRationale'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      channelHint:
          json['channelHint'] as String? ?? 'behavior_reflection_follow_up',
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

class VisitLocalityFollowUpPromptResponse {
  const VisitLocalityFollowUpPromptResponse({
    required this.responseId,
    required this.planId,
    required this.ownerUserId,
    required this.observationKind,
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
  final String observationKind;
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
      'observationKind': observationKind,
      'targetLabel': targetLabel,
      'respondedAtUtc': respondedAtUtc.toUtc().toIso8601String(),
      'responseText': responseText,
      'sourceSurface': sourceSurface,
      'completionMode': completionMode,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory VisitLocalityFollowUpPromptResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return VisitLocalityFollowUpPromptResponse(
      responseId: json['responseId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      observationKind: json['observationKind'] as String? ?? 'visit',
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

class VisitLocalityFollowUpPromptPlannerService {
  static const String _storageKeyPrefix =
      'bham:visit_locality_follow_up_prompt_plans:v1:';
  static const String _responseStorageKeyPrefix =
      'bham:visit_locality_follow_up_prompt_responses:v1:';

  VisitLocalityFollowUpPromptPlannerService({
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

  Future<VisitLocalityFollowUpPromptPlan> createVisitPlan({
    required Visit visit,
    required String source,
  }) async {
    final ownerUserId = visit.userId.trim();
    final existingPlans = await listPlans(ownerUserId);
    final occurredAtUtc = (visit.checkOutTime ?? visit.checkInTime).toUtc();
    final sourceEventRef =
        'visit:${visit.id}:${occurredAtUtc.microsecondsSinceEpoch}';
    final existing = existingPlans.where(
      (plan) => plan.sourceEventRef == sourceEventRef,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final planTime = DateTime.now().toUtc();
    final channelHint = 'behavior_reflection_follow_up';
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((plan) => _isSameUtcDay(plan.plannedAtUtc, planTime))
          .length,
    );
    final targetLabel = visit.locationId.trim().isEmpty
        ? 'recent visit'
        : visit.locationId.trim();
    final localityCode =
        visit.metadata['localityCode']?.toString().trim().isNotEmpty == true
            ? visit.metadata['localityCode'].toString().trim()
            : null;
    final domains = _extractVisitDomains(visit: visit, source: source);
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'visit_locality_follow_up',
      targetKey: _suppressionTargetKey(
        observationKind: 'visit',
        targetLabel: targetLabel,
      ),
    );
    final plan = VisitLocalityFollowUpPromptPlan(
      planId:
          'visit_follow_up_plan_${visit.id}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      observationKind: 'visit',
      sourceEventRef: sourceEventRef,
      targetLabel: targetLabel,
      occurredAtUtc: occurredAtUtc,
      plannedAtUtc: planTime,
      sourceSurface: 'visit_observation',
      promptQuestion: _buildVisitPromptQuestion(targetLabel: targetLabel),
      promptRationale: _buildVisitPromptRationale(
        targetLabel: targetLabel,
        visit: visit,
      ),
      priority: _visitPriority(visit),
      channelHint: channelHint,
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      boundedContext: <String, dynamic>{
        'what': 'completed_visit',
        'why': visit.isRepeatVisit ? 'repeat_visit' : 'single_completed_visit',
        'how': source,
        'whenUtc': occurredAtUtc.toIso8601String(),
        'where': localityCode ?? targetLabel,
        'who': 'automatic_check_in_visit_observation',
        'observationKind': 'visit',
        'locationId': visit.locationId,
        if (localityCode != null) 'localityCode': localityCode,
        'dwellMinutes': visit.dwellTime?.inMinutes ?? 0,
        'qualityScore': visit.qualityScore,
        'isRepeatVisit': visit.isRepeatVisit,
        'sourceEventRef': sourceEventRef,
        'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
        'domains': domains,
        'suppressionTargetKey': _suppressionTargetKey(
          observationKind: 'visit',
          targetLabel: targetLabel,
        ),
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: <String>[
        'source:visit_follow_up_plan',
        'observation:visit',
        'trigger:$source',
        if (visit.isRepeatVisit) 'repeat_visit',
        if ((visit.dwellTime?.inMinutes ?? 0) > 0)
          'dwell_minutes:${visit.dwellTime!.inMinutes}',
        ...domains.map((domain) => 'domain:$domain'),
      ]..sort(),
    );
    await _storePlans(ownerUserId, <VisitLocalityFollowUpPromptPlan>[
      plan,
      ...existingPlans,
    ]);
    return plan;
  }

  Future<VisitLocalityFollowUpPromptPlan> createLocalityPlan({
    required String ownerUserId,
    required DateTime occurredAtUtc,
    required String sourceKind,
    required String localityStableKey,
    Map<String, dynamic> structuredSignals = const <String, dynamic>{},
    Map<String, dynamic> locationContext = const <String, dynamic>{},
    Map<String, dynamic> temporalContext = const <String, dynamic>{},
    String? socialContext,
    String? activityContext,
  }) async {
    final existingPlans = await listPlans(ownerUserId);
    final sourceEventRef =
        'locality:$localityStableKey:${occurredAtUtc.toUtc().microsecondsSinceEpoch}:$sourceKind';
    final existing = existingPlans.where(
      (plan) => plan.sourceEventRef == sourceEventRef,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final planTime = DateTime.now().toUtc();
    final channelHint = 'behavior_reflection_follow_up';
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((plan) => _isSameUtcDay(plan.plannedAtUtc, planTime))
          .length,
    );
    final targetLabel = localityStableKey.trim().isEmpty
        ? 'recent locality'
        : localityStableKey;
    final domains = _extractLocalityDomains(
      localityStableKey: localityStableKey,
      structuredSignals: structuredSignals,
      socialContext: socialContext,
      activityContext: activityContext,
    );
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'visit_locality_follow_up',
      targetKey: _suppressionTargetKey(
        observationKind: 'locality',
        targetLabel: targetLabel,
      ),
    );
    final plan = VisitLocalityFollowUpPromptPlan(
      planId:
          'locality_follow_up_plan_${localityStableKey}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      observationKind: 'locality',
      sourceEventRef: sourceEventRef,
      targetLabel: targetLabel,
      occurredAtUtc: occurredAtUtc.toUtc(),
      plannedAtUtc: planTime,
      sourceSurface: 'locality_observation',
      promptQuestion: _buildLocalityPromptQuestion(targetLabel: targetLabel),
      promptRationale: _buildLocalityPromptRationale(
        targetLabel: targetLabel,
        structuredSignals: structuredSignals,
        socialContext: socialContext,
      ),
      priority: _localityPriority(structuredSignals, socialContext),
      channelHint: channelHint,
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      boundedContext: <String, dynamic>{
        'what': 'locality_observation',
        'why': socialContext?.trim().isNotEmpty == true
            ? socialContext!.trim()
            : activityContext?.trim().isNotEmpty == true
                ? activityContext!.trim()
                : sourceKind,
        'how': sourceKind,
        'whenUtc': occurredAtUtc.toUtc().toIso8601String(),
        'where': targetLabel,
        'who': 'passive_locality_observation',
        'observationKind': 'locality',
        'localityStableKey': localityStableKey,
        if (socialContext?.trim().isNotEmpty ?? false)
          'socialContext': socialContext!.trim(),
        if (activityContext?.trim().isNotEmpty ?? false)
          'activityContext': activityContext!.trim(),
        if (structuredSignals.isNotEmpty)
          'structuredSignals': structuredSignals,
        if (locationContext.isNotEmpty) 'locationContext': locationContext,
        if (temporalContext.isNotEmpty) 'temporalContext': temporalContext,
        'sourceEventRef': sourceEventRef,
        'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
        'domains': domains,
        'suppressionTargetKey': _suppressionTargetKey(
          observationKind: 'locality',
          targetLabel: targetLabel,
        ),
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: <String>[
        'source:locality_follow_up_plan',
        'observation:locality',
        'source_kind:$sourceKind',
        if (socialContext?.trim().isNotEmpty ?? false)
          'social:${socialContext!.trim()}',
        if (activityContext?.trim().isNotEmpty ?? false)
          'activity:${activityContext!.trim()}',
        ...domains.map((domain) => 'domain:$domain'),
      ]..sort(),
    );
    await _storePlans(ownerUserId, <VisitLocalityFollowUpPromptPlan>[
      plan,
      ...existingPlans,
    ]);
    return plan;
  }

  Future<List<VisitLocalityFollowUpPromptPlan>> listPlans(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <VisitLocalityFollowUpPromptPlan>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <VisitLocalityFollowUpPromptPlan>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => VisitLocalityFollowUpPromptPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    } catch (_) {
      return const <VisitLocalityFollowUpPromptPlan>[];
    }
  }

  Future<List<VisitLocalityFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return const <VisitLocalityFollowUpPromptPlan>[];
    }
    final plans = <VisitLocalityFollowUpPromptPlan>[];
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

  Future<List<VisitLocalityFollowUpPromptPlan>> listPendingPlans(
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
                  'behavior_reflection_follow_up',
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
      familyKey: 'visit_locality_follow_up',
      targetKey: _suppressionTargetKey(
        observationKind: plan.observationKind,
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
      familyKey: 'visit_locality_follow_up',
      targetKey: _suppressionTargetKey(
        observationKind: plan.observationKind,
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

  Future<VisitLocalityFollowUpPromptPlan?> activeAssistantFollowUpPlan(
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

  Future<VisitLocalityFollowUpPromptResponse> completePlanWithResponse({
    required String ownerUserId,
    required String planId,
    required String responseText,
    String sourceSurface = 'data_center_follow_up_queue',
  }) async {
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () => throw StateError(
        'Unknown visit/locality follow-up plan: $planId',
      ),
    );
    final responseTime = DateTime.now().toUtc();
    final completionMode = _completionModeForSourceSurface(sourceSurface);
    final response = VisitLocalityFollowUpPromptResponse(
      responseId:
          'visit_locality_follow_up_response_${plan.planId}_${responseTime.millisecondsSinceEpoch}',
      planId: plan.planId,
      ownerUserId: ownerUserId,
      observationKind: plan.observationKind,
      targetLabel: plan.targetLabel,
      respondedAtUtc: responseTime,
      responseText: responseText.trim(),
      sourceSurface: sourceSurface,
      completionMode: completionMode,
      boundedContext: <String, dynamic>{
        'promptQuestion': plan.promptQuestion,
        'priority': plan.priority,
        'channelHint': plan.channelHint,
        'sourceEventRef': plan.sourceEventRef,
        'what': plan.boundedContext['what'],
        'why': plan.boundedContext['why'],
        'how': plan.boundedContext['how'],
        'whenUtc': plan.boundedContext['whenUtc'],
        'where': plan.boundedContext['where'],
        'who': plan.boundedContext['who'],
        'observationKind': plan.observationKind,
      },
      signalTags: <String>[
        ...plan.signalTags,
        'prompt_response:completed',
        'completion_mode:$completionMode',
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

  Future<List<VisitLocalityFollowUpPromptResponse>> listResponses(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_responseStorageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <VisitLocalityFollowUpPromptResponse>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <VisitLocalityFollowUpPromptResponse>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => VisitLocalityFollowUpPromptResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.respondedAtUtc.compareTo(a.respondedAtUtc));
    } catch (_) {
      return const <VisitLocalityFollowUpPromptResponse>[];
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
    required String observationKind,
    required String targetLabel,
  }) {
    return '$observationKind:${targetLabel.trim()}';
  }

  String _buildVisitPromptQuestion({required String targetLabel}) {
    return 'What about your visit to "$targetLabel" should AVRAI remember for future place guidance?';
  }

  String _buildVisitPromptRationale({
    required String targetLabel,
    required Visit visit,
  }) {
    final dwellMinutes = visit.dwellTime?.inMinutes ?? 0;
    return 'A completed visit to "$targetLabel" with $dwellMinutes minutes of dwell can be strong evidence, but bounded follow-up helps clarify whether it reflects a durable place preference or a one-off situation.';
  }

  String _buildLocalityPromptQuestion({required String targetLabel}) {
    return 'What was going on around "$targetLabel" that should shape future locality guidance?';
  }

  String _buildLocalityPromptRationale({
    required String targetLabel,
    required Map<String, dynamic> structuredSignals,
    required String? socialContext,
  }) {
    final dwellMinutes =
        (structuredSignals['dwellDurationMinutes'] as num?)?.toInt();
    final dwellText = dwellMinutes == null
        ? 'a passive locality observation'
        : '$dwellMinutes minutes of dwell';
    final socialText = socialContext?.trim().isNotEmpty == true
        ? ' with social context "${socialContext!.trim()}"'
        : '';
    return 'AVRAI recorded $dwellText around "$targetLabel"$socialText. A bounded follow-up keeps that signal scoped before broader locality learning.';
  }

  String _visitPriority(Visit visit) {
    if (visit.isRepeatVisit ||
        (visit.dwellTime?.inMinutes ?? 0) >= 30 ||
        visit.qualityScore >= 1.0) {
      return 'high';
    }
    return 'medium';
  }

  String _localityPriority(
    Map<String, dynamic> structuredSignals,
    String? socialContext,
  ) {
    final dwellMinutes =
        (structuredSignals['dwellDurationMinutes'] as num?)?.toInt() ?? 0;
    if (dwellMinutes >= 45 || (socialContext?.trim().isNotEmpty ?? false)) {
      return 'high';
    }
    return 'medium';
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
    required VisitLocalityFollowUpPromptPlan plan,
    required VisitLocalityFollowUpPromptResponse response,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null || response.responseText.trim().isEmpty) {
      return;
    }
    try {
      final airGapArtifact = _upwardAirGapService.issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'visit_locality_follow_up_response_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'observationKind': plan.observationKind,
          'targetLabel': plan.targetLabel,
          'promptQuestion': plan.promptQuestion,
          'promptRationale': plan.promptRationale,
          'responseText': response.responseText,
          'sourceSurface': response.sourceSurface,
          'completionMode': response.completionMode,
          'sourceEventRef': plan.sourceEventRef,
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
        },
      );
      await service.stageVisitLocalityFollowUpResponseIntake(
        ownerUserId: plan.ownerUserId,
        observationKind: plan.observationKind,
        targetLabel: plan.targetLabel,
        occurredAtUtc: response.respondedAtUtc,
        sourceSurface: response.sourceSurface,
        promptQuestion: plan.promptQuestion,
        promptRationale: plan.promptRationale,
        responseText: response.responseText,
        completionMode: response.completionMode,
        airGapArtifact: airGapArtifact,
        metadata: <String, dynamic>{
          'sourceEventRef': plan.sourceEventRef,
          'planSourceSurface': plan.sourceSurface,
          'priority': plan.priority,
          'channelHint': plan.channelHint,
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
          'domains': _extractStringList(plan.boundedContext['domains']),
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
      return VisitLocalityFollowUpPromptPlan(
        planId: plan.planId,
        ownerUserId: plan.ownerUserId,
        observationKind: plan.observationKind,
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
        boundedContext: nextBoundedContext,
        signalTags: plan.signalTags,
      );
    }).toList(growable: false);
    await _storePlans(ownerUserId, updatedPlans);
  }

  Future<void> _storePlans(
    String ownerUserId,
    List<VisitLocalityFollowUpPromptPlan> plans,
  ) async {
    await _prefs?.setString(
      _storageKey(ownerUserId),
      jsonEncode(plans.map((plan) => plan.toJson()).toList()),
    );
  }

  List<String> _extractVisitDomains({
    required Visit visit,
    required String source,
  }) {
    final domains = <String>{'locality', 'place', 'venue'};
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
    return domains.toList()..sort();
  }

  List<String> _extractLocalityDomains({
    required String localityStableKey,
    required Map<String, dynamic> structuredSignals,
    required String? socialContext,
    required String? activityContext,
  }) {
    final domains = <String>{'locality'};
    if (localityStableKey.trim().isNotEmpty) {
      domains.addAll(const <String>['place', 'venue']);
    }
    if ((socialContext?.contains('group') ?? false) ||
        (socialContext?.contains('crowd') ?? false) ||
        (structuredSignals['coPresenceDetected'] as bool?) == true) {
      domains.add('community');
    }
    if ((activityContext?.contains('walk') ?? false) ||
        (activityContext?.contains('drive') ?? false) ||
        (activityContext?.contains('transit') ?? false)) {
      domains.add('mobility');
    }
    return domains.toList()..sort();
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

  DateTime? _nextEligibleAtUtcFromPlan(VisitLocalityFollowUpPromptPlan plan) {
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
