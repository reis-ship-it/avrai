import 'dart:convert';

import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_suppression_memory_service.dart';
import 'package:get_it/get_it.dart';

class BusinessOperatorFollowUpPromptPlan {
  const BusinessOperatorFollowUpPromptPlan({
    required this.planId,
    required this.ownerUserId,
    required this.businessId,
    required this.businessName,
    required this.action,
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
  final String businessId;
  final String businessName;
  final String action;
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
      'businessId': businessId,
      'businessName': businessName,
      'action': action,
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

  factory BusinessOperatorFollowUpPromptPlan.fromJson(
    Map<String, dynamic> json,
  ) {
    return BusinessOperatorFollowUpPromptPlan(
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      businessId: json['businessId'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      action: json['action'] as String? ?? 'update',
      occurredAtUtc:
          DateTime.tryParse(json['occurredAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      plannedAtUtc:
          DateTime.tryParse(json['plannedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'business_account',
      promptQuestion: json['promptQuestion'] as String? ?? '',
      promptRationale: json['promptRationale'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      channelHint: json['channelHint'] as String? ??
          'business_operator_reflection_follow_up',
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

class BusinessOperatorFollowUpPromptResponse {
  const BusinessOperatorFollowUpPromptResponse({
    required this.responseId,
    required this.planId,
    required this.ownerUserId,
    required this.businessId,
    required this.businessName,
    required this.action,
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
  final String businessId;
  final String businessName;
  final String action;
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
      'businessId': businessId,
      'businessName': businessName,
      'action': action,
      'respondedAtUtc': respondedAtUtc.toUtc().toIso8601String(),
      'responseText': responseText,
      'sourceSurface': sourceSurface,
      'completionMode': completionMode,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory BusinessOperatorFollowUpPromptResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return BusinessOperatorFollowUpPromptResponse(
      responseId: json['responseId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      businessId: json['businessId'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      action: json['action'] as String? ?? 'update',
      respondedAtUtc:
          DateTime.tryParse(json['respondedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      responseText: json['responseText'] as String? ?? '',
      sourceSurface: json['sourceSurface'] as String? ?? 'unknown',
      completionMode: json['completionMode'] as String? ??
          'business_in_app_follow_up_queue',
      boundedContext: Map<String, dynamic>.from(
        json['boundedContext'] as Map? ?? const <String, dynamic>{},
      ),
      signalTags: (json['signalTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

class BusinessOperatorFollowUpPromptPlannerService {
  static const String _storageKeyPrefix =
      'bham:business_operator_follow_up_prompt_plans:v1:';
  static const String _responseStorageKeyPrefix =
      'bham:business_operator_follow_up_prompt_responses:v1:';

  BusinessOperatorFollowUpPromptPlannerService({
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

  Future<BusinessOperatorFollowUpPromptPlan> createPlan({
    required BusinessAccount account,
    required String action,
    required DateTime occurredAtUtc,
    List<String> changedFields = const <String>[],
  }) async {
    final ownerUserId = account.ownerId.trim();
    final existingPlans = await listPlans(ownerUserId);
    final sourceEventRef =
        'business_operator:${account.id}:$action:${occurredAtUtc.toUtc().microsecondsSinceEpoch}';
    final existing = existingPlans.where(
      (plan) => plan.boundedContext['sourceEventRef'] == sourceEventRef,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final planTime = DateTime.now().toUtc();
    final channelHint = 'business_operator_reflection_follow_up';
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((plan) => _isSameUtcDay(plan.plannedAtUtc, planTime))
          .length,
    );
    final domains = _extractDomains(
      account: account,
      action: action,
      changedFields: changedFields,
    );
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'business_operator_follow_up',
      targetKey: _suppressionTargetKey(
        businessId: account.id,
        action: action,
      ),
    );
    final plan = BusinessOperatorFollowUpPromptPlan(
      planId:
          'business_follow_up_plan_${account.id}_${action}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      businessId: account.id,
      businessName: account.name,
      action: action,
      occurredAtUtc: occurredAtUtc.toUtc(),
      plannedAtUtc: planTime,
      sourceSurface: 'business_account',
      promptQuestion: _buildPromptQuestion(
        account: account,
        action: action,
        changedFields: changedFields,
      ),
      promptRationale: _buildPromptRationale(
        account: account,
        action: action,
        changedFields: changedFields,
      ),
      priority: _priorityForAction(action, changedFields),
      channelHint: channelHint,
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      boundedContext: <String, dynamic>{
        'what': action == 'create'
            ? 'business_account_created'
            : 'business_account_updated',
        'why': changedFields.isEmpty ? action : changedFields.join(','),
        'how': 'business_account_service',
        'whenUtc': occurredAtUtc.toUtc().toIso8601String(),
        'where': account.location?.trim(),
        'who': ownerUserId,
        'businessId': account.id,
        'businessName': account.name,
        'businessType': account.businessType,
        'changedFields': changedFields,
        'sourceEventRef': sourceEventRef,
        'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
        'domains': domains,
        'suppressionTargetKey': _suppressionTargetKey(
          businessId: account.id,
          action: action,
        ),
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: <String>[
        'source:business_operator_follow_up_plan',
        'action:$action',
        'business_type:${account.businessType.trim().toLowerCase().replaceAll(' ', '_')}',
        ...changedFields.map((field) => 'changed_field:$field'),
        ...domains.map((domain) => 'domain:$domain'),
      ]..sort(),
    );
    await _storePlans(ownerUserId, <BusinessOperatorFollowUpPromptPlan>[
      plan,
      ...existingPlans,
    ]);
    return plan;
  }

  Future<List<BusinessOperatorFollowUpPromptPlan>> listPlans(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <BusinessOperatorFollowUpPromptPlan>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <BusinessOperatorFollowUpPromptPlan>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => BusinessOperatorFollowUpPromptPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    } catch (_) {
      return const <BusinessOperatorFollowUpPromptPlan>[];
    }
  }

  Future<List<BusinessOperatorFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return const <BusinessOperatorFollowUpPromptPlan>[];
    }
    final plans = <BusinessOperatorFollowUpPromptPlan>[];
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

  Future<List<BusinessOperatorFollowUpPromptPlan>> listPendingPlans(
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
              plan.status != 'assistant_offered_local_bounded_follow_up' &&
              plan.status != 'completed_in_app_follow_up' &&
              plan.status != 'completed_assistant_follow_up' &&
              plan.status != 'dismissed_in_app_follow_up' &&
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

  Future<void> markPlanOfferedForAssistant({
    required String ownerUserId,
    required String planId,
  }) async {
    await _updatePlanStatus(
      ownerUserId: ownerUserId,
      planId: planId,
      nextStatus: 'assistant_offered_local_bounded_follow_up',
    );
  }

  Future<BusinessOperatorFollowUpPromptPlan?> activeAssistantFollowUpPlan(
    String ownerUserId,
  ) async {
    final plans = await listPlans(ownerUserId);
    for (final plan in plans) {
      if (plan.status == 'assistant_offered_local_bounded_follow_up') {
        return plan;
      }
    }
    return null;
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
                  'business_operator_reflection_follow_up',
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
      familyKey: 'business_operator_follow_up',
      targetKey: _suppressionTargetKey(
        businessId: plan.businessId,
        action: plan.action,
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
      familyKey: 'business_operator_follow_up',
      targetKey: _suppressionTargetKey(
        businessId: plan.businessId,
        action: plan.action,
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

  Future<BusinessOperatorFollowUpPromptResponse> completePlanWithResponse({
    required String ownerUserId,
    required String planId,
    required String responseText,
    String sourceSurface = 'business_dashboard_follow_up_queue',
  }) async {
    final trimmedResponse = responseText.trim();
    if (trimmedResponse.isEmpty) {
      throw StateError('A bounded business follow-up response is required.');
    }
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () => throw StateError('Unknown follow-up plan `$planId`.'),
    );
    final respondedAtUtc = DateTime.now().toUtc();
    final response = BusinessOperatorFollowUpPromptResponse(
      responseId:
          'business_follow_up_response_${respondedAtUtc.microsecondsSinceEpoch}',
      planId: plan.planId,
      ownerUserId: ownerUserId,
      businessId: plan.businessId,
      businessName: plan.businessName,
      action: plan.action,
      respondedAtUtc: respondedAtUtc,
      responseText: trimmedResponse,
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
        'businessType': plan.boundedContext['businessType'],
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
      nextStatus: sourceSurface == 'assistant_follow_up_chat'
          ? 'completed_assistant_follow_up'
          : 'completed_in_app_follow_up',
    );
    await _stageCompletedResponseBestEffort(plan: plan, response: response);
    return response;
  }

  Future<List<BusinessOperatorFollowUpPromptResponse>> listResponses(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_responseStorageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <BusinessOperatorFollowUpPromptResponse>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <BusinessOperatorFollowUpPromptResponse>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => BusinessOperatorFollowUpPromptResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.respondedAtUtc.compareTo(a.respondedAtUtc));
    } catch (_) {
      return const <BusinessOperatorFollowUpPromptResponse>[];
    }
  }

  Future<void> clearAll(String ownerUserId) async {
    await _prefs?.remove(_storageKey(ownerUserId));
    await _prefs?.remove(_responseStorageKey(ownerUserId));
    await _suppressionMemoryService.clearAll(ownerUserId);
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
      final nextContext = boundedContextMutator == null
          ? plan.boundedContext
          : boundedContextMutator(
              <String, dynamic>{
                ...plan.boundedContext,
                'channelHint': plan.channelHint,
              },
            )
        ..remove('channelHint');
      return BusinessOperatorFollowUpPromptPlan(
        planId: plan.planId,
        ownerUserId: plan.ownerUserId,
        businessId: plan.businessId,
        businessName: plan.businessName,
        action: plan.action,
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
    await _storePlans(ownerUserId, updatedPlans);
  }

  Future<void> _stageCompletedResponseBestEffort({
    required BusinessOperatorFollowUpPromptPlan plan,
    required BusinessOperatorFollowUpPromptResponse response,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final airGapArtifact = _upwardAirGapService.issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'business_operator_follow_up_response_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'sourceKind': 'business_operator_follow_up_response_intake',
          'businessId': plan.businessId,
          'businessName': plan.businessName,
          'action': plan.action,
          'promptQuestion': plan.promptQuestion,
          'promptRationale': plan.promptRationale,
          'responseText': response.responseText,
          'completionMode': response.completionMode,
          'sourceSurface': response.sourceSurface,
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
        },
      );
      await service.stageBusinessOperatorFollowUpResponseIntake(
        ownerUserId: response.ownerUserId,
        businessId: plan.businessId,
        businessName: plan.businessName,
        action: plan.action,
        occurredAtUtc: response.respondedAtUtc,
        sourceSurface: response.sourceSurface,
        promptQuestion: plan.promptQuestion,
        promptRationale: plan.promptRationale,
        responseText: response.responseText,
        completionMode: response.completionMode,
        airGapArtifact: airGapArtifact,
        metadata: <String, dynamic>{
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
          'domains': _extractStringList(plan.boundedContext['domains']),
        },
      );
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> _storePlans(
    String ownerUserId,
    List<BusinessOperatorFollowUpPromptPlan> plans,
  ) async {
    await _prefs?.setString(
      _storageKey(ownerUserId),
      jsonEncode(plans.map((plan) => plan.toJson()).toList(growable: false)),
    );
  }

  String _storageKey(String ownerUserId) => '$_storageKeyPrefix$ownerUserId';
  String _responseStorageKey(String ownerUserId) =>
      '$_responseStorageKeyPrefix$ownerUserId';

  DateTime? _nextEligibleAtUtcFromPlan(
      BusinessOperatorFollowUpPromptPlan plan) {
    final value = plan.boundedContext['nextEligibleAtUtc']?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  String _suppressionTargetKey({
    required String businessId,
    required String action,
  }) {
    return 'business:${businessId.trim()}:$action';
  }

  String _buildPromptQuestion({
    required BusinessAccount account,
    required String action,
    required List<String> changedFields,
  }) {
    if (action == 'create') {
      return 'What about how you set up "${account.name}" should AVRAI remember before it broadens business learning?';
    }
    if (changedFields.contains('location')) {
      return 'What about the updated location or footprint for "${account.name}" should AVRAI remember before it changes place or locality learning?';
    }
    return 'Which part of the update to "${account.name}" matters most for future business learning?';
  }

  String _buildPromptRationale({
    required BusinessAccount account,
    required String action,
    required List<String> changedFields,
  }) {
    if (action == 'create') {
      return 'A new business profile is a strong seed, but bounded follow-up helps clarify which parts of "${account.name}" should become durable business, locality, or venue guidance.';
    }
    if (changedFields.contains('location')) {
      return 'Location changes can affect locality, place, and business guidance. A bounded follow-up helps keep that scope explicit before broader learning.';
    }
    return 'Business profile updates can change future account guidance, recommendation priors, or locality assumptions. A bounded follow-up keeps that interpretation scoped.';
  }

  String _priorityForAction(String action, List<String> changedFields) {
    if (action == 'create' ||
        changedFields.contains('location') ||
        changedFields.contains('preferredCommunities')) {
      return 'high';
    }
    return 'medium';
  }

  String _completionModeForSourceSurface(String sourceSurface) {
    switch (sourceSurface) {
      case 'assistant_follow_up_chat':
        return 'business_assistant_follow_up_chat';
      case 'business_dashboard_follow_up_queue':
      case 'in_app_follow_up_queue':
        return 'business_in_app_follow_up_queue';
      default:
        return 'bounded_follow_up_response';
    }
  }

  List<String> _extractDomains({
    required BusinessAccount account,
    required String action,
    required List<String> changedFields,
  }) {
    final domains = <String>{'business'};
    if ((account.location?.trim().isNotEmpty ?? false) ||
        changedFields.contains('location')) {
      domains.addAll(const <String>['locality', 'place']);
    }
    if (account.preferredCommunities.isNotEmpty ||
        changedFields.contains('preferredCommunities')) {
      domains.add('community');
    }
    final hintText = <String>[
      account.businessType,
      account.description ?? '',
      account.location ?? '',
      ...account.categories,
      ...account.requiredExpertise,
      ...account.preferredCommunities,
      action,
      ...changedFields,
    ].join(' ').toLowerCase();
    if (hintText.contains('restaurant') ||
        hintText.contains('bar') ||
        hintText.contains('club') ||
        hintText.contains('cafe')) {
      domains.add('venue');
    }
    if (hintText.contains('event') || hintText.contains('booking')) {
      domains.add('event');
    }
    return domains.toList()..sort();
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
}
