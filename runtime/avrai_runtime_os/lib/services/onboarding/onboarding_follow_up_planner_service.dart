import 'dart:convert';

import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_suppression_memory_service.dart';
import 'package:get_it/get_it.dart';

class OnboardingFollowUpPromptPlan {
  const OnboardingFollowUpPromptPlan({
    required this.planId,
    required this.ownerUserId,
    required this.agentId,
    required this.occurredAtUtc,
    required this.plannedAtUtc,
    required this.sourceSurface,
    required this.promptQuestion,
    required this.promptRationale,
    required this.priority,
    required this.channelHint,
    required this.status,
    this.homebase,
    this.questionnaireVersion,
    this.boundedContext = const <String, dynamic>{},
    this.signalTags = const <String>[],
  });

  final String planId;
  final String ownerUserId;
  final String agentId;
  final DateTime occurredAtUtc;
  final DateTime plannedAtUtc;
  final String sourceSurface;
  final String promptQuestion;
  final String promptRationale;
  final String priority;
  final String channelHint;
  final String status;
  final String? homebase;
  final String? questionnaireVersion;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'planId': planId,
      'ownerUserId': ownerUserId,
      'agentId': agentId,
      'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
      'plannedAtUtc': plannedAtUtc.toUtc().toIso8601String(),
      'sourceSurface': sourceSurface,
      'promptQuestion': promptQuestion,
      'promptRationale': promptRationale,
      'priority': priority,
      'channelHint': channelHint,
      'status': status,
      'homebase': homebase,
      'questionnaireVersion': questionnaireVersion,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory OnboardingFollowUpPromptPlan.fromJson(Map<String, dynamic> json) {
    return OnboardingFollowUpPromptPlan(
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      occurredAtUtc:
          DateTime.tryParse(json['occurredAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      plannedAtUtc:
          DateTime.tryParse(json['plannedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'onboarding',
      promptQuestion: json['promptQuestion'] as String? ?? '',
      promptRationale: json['promptRationale'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      channelHint:
          json['channelHint'] as String? ?? 'onboarding_reflection_follow_up',
      status: json['status'] as String? ?? 'planned_local_bounded_follow_up',
      homebase: json['homebase'] as String?,
      questionnaireVersion: json['questionnaireVersion'] as String?,
      boundedContext: Map<String, dynamic>.from(
        json['boundedContext'] as Map? ?? const <String, dynamic>{},
      ),
      signalTags: (json['signalTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

class OnboardingFollowUpPromptResponse {
  const OnboardingFollowUpPromptResponse({
    required this.responseId,
    required this.planId,
    required this.ownerUserId,
    required this.agentId,
    required this.respondedAtUtc,
    required this.responseText,
    required this.sourceSurface,
    required this.completionMode,
    this.homebase,
    this.boundedContext = const <String, dynamic>{},
    this.signalTags = const <String>[],
  });

  final String responseId;
  final String planId;
  final String ownerUserId;
  final String agentId;
  final DateTime respondedAtUtc;
  final String responseText;
  final String sourceSurface;
  final String completionMode;
  final String? homebase;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'responseId': responseId,
      'planId': planId,
      'ownerUserId': ownerUserId,
      'agentId': agentId,
      'respondedAtUtc': respondedAtUtc.toUtc().toIso8601String(),
      'responseText': responseText,
      'sourceSurface': sourceSurface,
      'completionMode': completionMode,
      'homebase': homebase,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory OnboardingFollowUpPromptResponse.fromJson(Map<String, dynamic> json) {
    return OnboardingFollowUpPromptResponse(
      responseId: json['responseId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      respondedAtUtc:
          DateTime.tryParse(json['respondedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      responseText: json['responseText'] as String? ?? '',
      sourceSurface: json['sourceSurface'] as String? ?? 'unknown',
      completionMode:
          json['completionMode'] as String? ?? 'onboarding_in_app_follow_up',
      homebase: json['homebase'] as String?,
      boundedContext: Map<String, dynamic>.from(
        json['boundedContext'] as Map? ?? const <String, dynamic>{},
      ),
      signalTags: (json['signalTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

class OnboardingFollowUpPromptPlannerService {
  static const String _storageKeyPrefix =
      'bham:onboarding_follow_up_prompt_plans:v1:';
  static const String _responseStorageKeyPrefix =
      'bham:onboarding_follow_up_prompt_responses:v1:';

  OnboardingFollowUpPromptPlannerService({
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

  Future<OnboardingFollowUpPromptPlan> createPlan({
    required String ownerUserId,
    required OnboardingData onboardingData,
    List<String> suggestionSurfaces = const <String>[],
  }) async {
    final existingPlans = await listPlans(ownerUserId);
    final sourceEventRef =
        'onboarding:${onboardingData.questionnaireVersion ?? 'unknown'}:${onboardingData.completedAt.toUtc().microsecondsSinceEpoch}';
    final existing = existingPlans.where(
      (plan) => plan.boundedContext['sourceEventRef'] == sourceEventRef,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final planTime = DateTime.now().toUtc();
    final channelHint = 'onboarding_reflection_follow_up';
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((plan) => _isSameUtcDay(plan.plannedAtUtc, planTime))
          .length,
    );
    final domains = _extractDomains(onboardingData);
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'onboarding_follow_up',
      targetKey: _suppressionTargetKey(onboardingData.agentId),
    );
    final plan = OnboardingFollowUpPromptPlan(
      planId:
          'onboarding_follow_up_${onboardingData.agentId}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      agentId: onboardingData.agentId,
      occurredAtUtc: onboardingData.completedAt.toUtc(),
      plannedAtUtc: planTime,
      sourceSurface: 'onboarding_completion',
      promptQuestion: _buildPromptQuestion(onboardingData),
      promptRationale: _buildPromptRationale(onboardingData),
      priority: _priorityFor(onboardingData),
      channelHint: channelHint,
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      homebase: onboardingData.homebase?.trim(),
      questionnaireVersion: onboardingData.questionnaireVersion,
      boundedContext: <String, dynamic>{
        'what': 'onboarding_completed',
        'why': _whySummary(onboardingData),
        'how': 'onboarding_data_service',
        'whenUtc': onboardingData.completedAt.toUtc().toIso8601String(),
        'where': onboardingData.homebase?.trim(),
        'who': ownerUserId,
        'sourceEventRef': sourceEventRef,
        'questionnaireVersion': onboardingData.questionnaireVersion,
        'betaConsentAccepted': onboardingData.betaConsentAccepted,
        'favoritePlaces': onboardingData.favoritePlaces,
        'baselineLists': onboardingData.baselineLists,
        'preferenceCategories': onboardingData.preferences.keys.toList()
          ..sort(),
        'topDimensions': _topDimensions(onboardingData),
        'suggestionSurfaces': suggestionSurfaces.toList()..sort(),
        'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
        'domains': domains,
        'suppressionTargetKey': _suppressionTargetKey(onboardingData.agentId),
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: <String>[
        'source:onboarding_follow_up_plan',
        'surface:onboarding_completion',
        if (onboardingData.homebase?.trim().isNotEmpty ?? false) 'has:homebase',
        if (onboardingData.favoritePlaces.isNotEmpty) 'has:favorite_places',
        if (onboardingData.preferences.isNotEmpty) 'has:preferences',
        if (onboardingData.hasDimensionValues) 'has:dimensions',
        if (onboardingData.respectedFriends.isNotEmpty) 'has:respected_friends',
        if (onboardingData.baselineLists.isNotEmpty) 'has:baseline_lists',
        ...domains.map((domain) => 'domain:$domain'),
        ...suggestionSurfaces.map(
          (surface) => 'suggestion_surface:${surface.trim().toLowerCase()}',
        ),
      ]..sort(),
    );
    await _storePlans(ownerUserId, <OnboardingFollowUpPromptPlan>[
      plan,
      ...existingPlans,
    ]);
    return plan;
  }

  Future<List<OnboardingFollowUpPromptPlan>> listPlans(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <OnboardingFollowUpPromptPlan>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <OnboardingFollowUpPromptPlan>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => OnboardingFollowUpPromptPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    } catch (_) {
      return const <OnboardingFollowUpPromptPlan>[];
    }
  }

  Future<List<OnboardingFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return const <OnboardingFollowUpPromptPlan>[];
    }
    final plans = <OnboardingFollowUpPromptPlan>[];
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

  Future<List<OnboardingFollowUpPromptPlan>> listPendingPlans(
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

  Future<OnboardingFollowUpPromptPlan?> activeAssistantFollowUpPlan(
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
                  'onboarding_reflection_follow_up',
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
      familyKey: 'onboarding_follow_up',
      targetKey: _suppressionTargetKey(plan.agentId),
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
      familyKey: 'onboarding_follow_up',
      targetKey: _suppressionTargetKey(plan.agentId),
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

  Future<OnboardingFollowUpPromptResponse> completePlanWithResponse({
    required String ownerUserId,
    required String planId,
    required String responseText,
    String sourceSurface = 'data_center_follow_up_queue',
  }) async {
    final trimmedResponse = responseText.trim();
    if (trimmedResponse.isEmpty) {
      throw StateError('A bounded onboarding follow-up response is required.');
    }
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () => throw StateError('Unknown follow-up plan `$planId`.'),
    );
    final respondedAtUtc = DateTime.now().toUtc();
    final response = OnboardingFollowUpPromptResponse(
      responseId:
          'onboarding_follow_up_response_${respondedAtUtc.microsecondsSinceEpoch}',
      planId: plan.planId,
      ownerUserId: ownerUserId,
      agentId: plan.agentId,
      respondedAtUtc: respondedAtUtc,
      responseText: trimmedResponse,
      sourceSurface: sourceSurface,
      completionMode: _completionModeForSourceSurface(sourceSurface),
      homebase: plan.homebase,
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
        'questionnaireVersion': plan.questionnaireVersion,
        'topDimensions': plan.boundedContext['topDimensions'],
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

  Future<List<OnboardingFollowUpPromptResponse>> listResponses(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_responseStorageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <OnboardingFollowUpPromptResponse>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <OnboardingFollowUpPromptResponse>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => OnboardingFollowUpPromptResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.respondedAtUtc.compareTo(a.respondedAtUtc));
    } catch (_) {
      return const <OnboardingFollowUpPromptResponse>[];
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
      return OnboardingFollowUpPromptPlan(
        planId: plan.planId,
        ownerUserId: plan.ownerUserId,
        agentId: plan.agentId,
        occurredAtUtc: plan.occurredAtUtc,
        plannedAtUtc: plan.plannedAtUtc,
        sourceSurface: plan.sourceSurface,
        promptQuestion: plan.promptQuestion,
        promptRationale: plan.promptRationale,
        priority: plan.priority,
        channelHint: plan.channelHint,
        status: nextStatus,
        homebase: plan.homebase,
        questionnaireVersion: plan.questionnaireVersion,
        boundedContext: nextContext,
        signalTags: plan.signalTags,
      );
    }).toList(growable: false);
    await _storePlans(ownerUserId, updatedPlans);
  }

  Future<void> _stageCompletedResponseBestEffort({
    required OnboardingFollowUpPromptPlan plan,
    required OnboardingFollowUpPromptResponse response,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final airGapArtifact = _upwardAirGapService.issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'onboarding_follow_up_response_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'sourceKind': 'onboarding_follow_up_response_intake',
          'agentId': plan.agentId,
          'promptQuestion': plan.promptQuestion,
          'promptRationale': plan.promptRationale,
          'responseText': response.responseText,
          'completionMode': response.completionMode,
          'sourceSurface': response.sourceSurface,
          'homebase': plan.homebase,
          'questionnaireVersion': plan.questionnaireVersion,
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
        },
      );
      await service.stageOnboardingFollowUpResponseIntake(
        ownerUserId: response.ownerUserId,
        agentId: plan.agentId,
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
          'homebase': plan.homebase,
          'questionnaireVersion': plan.questionnaireVersion,
        },
      );
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> _storePlans(
    String ownerUserId,
    List<OnboardingFollowUpPromptPlan> plans,
  ) async {
    await _prefs?.setString(
      _storageKey(ownerUserId),
      jsonEncode(plans.map((plan) => plan.toJson()).toList(growable: false)),
    );
  }

  String _storageKey(String ownerUserId) => '$_storageKeyPrefix$ownerUserId';
  String _responseStorageKey(String ownerUserId) =>
      '$_responseStorageKeyPrefix$ownerUserId';

  DateTime? _nextEligibleAtUtcFromPlan(OnboardingFollowUpPromptPlan plan) {
    final value = plan.boundedContext['nextEligibleAtUtc']?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  String _suppressionTargetKey(String agentId) => 'onboarding:$agentId';

  String _buildPromptQuestion(OnboardingData data) {
    if ((data.homebase?.trim().isNotEmpty ?? false) &&
        data.favoritePlaces.isNotEmpty) {
      return 'Which part of what you told AVRAI about ${data.homebase!.trim()} and the places you named should stay durable, and which part is still exploratory?';
    }
    if (data.hasDimensionValues) {
      return 'Which part of your onboarding profile should AVRAI treat as durable, and which part should stay exploratory while it keeps learning?';
    }
    return 'What from your onboarding should AVRAI hold strongly already, and what should it still treat as provisional?';
  }

  String _buildPromptRationale(OnboardingData data) {
    if (data.hasDimensionValues) {
      return 'Onboarding is a strong seed, but a bounded follow-up helps separate durable self-declared signal from exploratory signal before broader profile learning hardens.';
    }
    return 'Onboarding seeds early personal guidance. A bounded follow-up helps AVRAI avoid over-hardening first-pass preferences before more lived behavior arrives.';
  }

  String _priorityFor(OnboardingData data) {
    if (data.hasDimensionValues ||
        (data.homebase?.trim().isNotEmpty ?? false)) {
      return 'high';
    }
    return 'medium';
  }

  String _whySummary(OnboardingData data) {
    if (data.hasDimensionValues) {
      final topDimensions = _topDimensions(data);
      if (topDimensions.isNotEmpty) {
        return 'direct_onboarding_dimensions:${topDimensions.join(',')}';
      }
    }
    if (data.preferences.isNotEmpty) {
      return 'declared_preferences:${data.preferences.keys.join(',')}';
    }
    return 'completed_onboarding_seed';
  }

  List<String> _topDimensions(OnboardingData data) {
    final dimensions = data.dimensionValues;
    if (dimensions == null || dimensions.isEmpty) {
      return const <String>[];
    }
    final entries = dimensions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((entry) => entry.key).toList(growable: false);
  }

  List<String> _extractDomains(OnboardingData data) {
    final domains = <String>{'identity', 'preference'};
    if ((data.homebase?.trim().isNotEmpty ?? false) ||
        data.favoritePlaces.isNotEmpty) {
      domains.addAll(const <String>['locality', 'place']);
    }
    if (data.baselineLists.isNotEmpty) {
      domains.add('list');
    }
    if (data.respectedFriends.isNotEmpty) {
      domains.add('community');
    }
    return domains.toList()..sort();
  }

  String _completionModeForSourceSurface(String sourceSurface) {
    switch (sourceSurface) {
      case 'assistant_follow_up_chat':
        return 'onboarding_assistant_follow_up_chat';
      case 'data_center_follow_up_queue':
      case 'in_app_follow_up_queue':
        return 'onboarding_in_app_follow_up_queue';
      default:
        return 'bounded_follow_up_response';
    }
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
