import 'dart:convert';

import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_suppression_memory_service.dart';
import 'package:get_it/get_it.dart';

class RecommendationFeedbackPromptPlan {
  final String planId;
  final String ownerUserId;
  final String sourceEventRef;
  final DiscoveryEntityReference entity;
  final RecommendationFeedbackAction action;
  final DateTime eventOccurredAtUtc;
  final DateTime plannedAtUtc;
  final String sourceSurface;
  final String promptQuestion;
  final String promptRationale;
  final String priority;
  final String channelHint;
  final String status;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  const RecommendationFeedbackPromptPlan({
    required this.planId,
    required this.ownerUserId,
    required this.sourceEventRef,
    required this.entity,
    required this.action,
    required this.eventOccurredAtUtc,
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
      'sourceEventRef': sourceEventRef,
      'entity': entity.toJson(),
      'action': action.name,
      'eventOccurredAtUtc': eventOccurredAtUtc.toUtc().toIso8601String(),
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

  factory RecommendationFeedbackPromptPlan.fromJson(Map<String, dynamic> json) {
    return RecommendationFeedbackPromptPlan(
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      sourceEventRef: json['sourceEventRef'] as String? ?? '',
      entity: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['entity'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      action: RecommendationFeedbackAction.values.firstWhere(
        (value) => value.name == json['action'],
        orElse: () => RecommendationFeedbackAction.opened,
      ),
      eventOccurredAtUtc:
          DateTime.tryParse(json['eventOccurredAtUtc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      plannedAtUtc:
          DateTime.tryParse(json['plannedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'unknown',
      promptQuestion: json['promptQuestion'] as String? ?? '',
      promptRationale: json['promptRationale'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      channelHint: json['channelHint'] as String? ?? 'next_contextual_session',
      status: json['status'] as String? ?? 'planned',
      boundedContext: Map<String, dynamic>.from(
        json['boundedContext'] as Map? ?? const <String, dynamic>{},
      ),
      signalTags: (json['signalTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
    );
  }
}

class RecommendationFeedbackPromptResponse {
  final String responseId;
  final String planId;
  final String ownerUserId;
  final DiscoveryEntityReference entity;
  final DateTime respondedAtUtc;
  final String responseText;
  final String sourceSurface;
  final String completionMode;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  const RecommendationFeedbackPromptResponse({
    required this.responseId,
    required this.planId,
    required this.ownerUserId,
    required this.entity,
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
      'entity': entity.toJson(),
      'respondedAtUtc': respondedAtUtc.toUtc().toIso8601String(),
      'responseText': responseText,
      'sourceSurface': sourceSurface,
      'completionMode': completionMode,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory RecommendationFeedbackPromptResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecommendationFeedbackPromptResponse(
      responseId: json['responseId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      entity: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['entity'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      respondedAtUtc:
          DateTime.tryParse(json['respondedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      responseText: json['responseText'] as String? ?? '',
      sourceSurface: json['sourceSurface'] as String? ?? 'unknown',
      completionMode: json['completionMode'] as String? ?? 'in_app_follow_up',
      boundedContext: Map<String, dynamic>.from(
        json['boundedContext'] as Map? ?? const <String, dynamic>{},
      ),
      signalTags: (json['signalTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
    );
  }
}

class RecommendationFeedbackPromptPlannerService {
  static const String _storageKeyPrefix =
      'bham:recommendation_feedback_prompt_plans:v1:';
  static const String _responseStorageKeyPrefix =
      'bham:recommendation_feedback_prompt_responses:v1:';

  final SharedPreferencesCompat? _prefs;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final UpwardAirGapService _upwardAirGapService;
  final BoundedFollowUpPromptPolicyService _promptPolicyService;
  final BoundedFollowUpSuppressionMemoryService _suppressionMemoryService;

  RecommendationFeedbackPromptPlannerService({
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

  Future<RecommendationFeedbackPromptPlan> createPlan({
    required String ownerUserId,
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    RecommendationAttribution? attribution,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final eventTime = occurredAtUtc.toUtc();
    final planTime = DateTime.now().toUtc();
    final channelHint = _channelHintForAction(action);
    final existingPlans = await listPlans(ownerUserId);
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((existing) => _isSameUtcDay(existing.plannedAtUtc, planTime))
          .length,
    );
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'recommendation_feedback_follow_up',
      targetKey: _suppressionTargetKey(entity: entity, action: action),
    );
    final sourceEventRef =
        '${entity.type.name}:${entity.id}:${action.name}:${eventTime.millisecondsSinceEpoch}';
    final boundedContext = _buildBoundedContext(
      entity: entity,
      action: action,
      occurredAtUtc: eventTime,
      nextEligibleAtUtc: nextEligibleAtUtc,
      sourceSurface: sourceSurface,
      attribution: attribution,
      metadata: metadata,
    );
    final plan = RecommendationFeedbackPromptPlan(
      planId:
          'feedback_prompt_plan_${entity.type.name}_${entity.id}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      sourceEventRef: sourceEventRef,
      entity: entity,
      action: action,
      eventOccurredAtUtc: eventTime,
      plannedAtUtc: planTime,
      sourceSurface: sourceSurface,
      promptQuestion: _buildPromptQuestion(
        entity: entity,
        action: action,
        attribution: attribution,
      ),
      promptRationale: _buildPromptRationale(
        entity: entity,
        action: action,
        sourceSurface: sourceSurface,
        attribution: attribution,
      ),
      priority: _priorityForAction(action),
      channelHint: channelHint,
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      boundedContext: <String, dynamic>{
        ...boundedContext,
        'suppressionTargetKey':
            _suppressionTargetKey(entity: entity, action: action),
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: _buildSignalTags(
        entity: entity,
        action: action,
        sourceSurface: sourceSurface,
        attribution: attribution,
        metadata: metadata,
      ),
    );

    await _prefs?.setString(
      _storageKey(ownerUserId),
      jsonEncode(
        <Map<String, dynamic>>[
          plan.toJson(),
          ...existingPlans.map((existing) => existing.toJson()),
        ],
      ),
    );
    return plan;
  }

  Future<List<RecommendationFeedbackPromptPlan>> listPlans(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <RecommendationFeedbackPromptPlan>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <RecommendationFeedbackPromptPlan>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => RecommendationFeedbackPromptPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    } catch (_) {
      return const <RecommendationFeedbackPromptPlan>[];
    }
  }

  Future<List<RecommendationFeedbackPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return const <RecommendationFeedbackPromptPlan>[];
    }
    final plans = <RecommendationFeedbackPromptPlan>[];
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

  Future<void> clearAll(String ownerUserId) async {
    await _prefs?.remove(_storageKey(ownerUserId));
    await _prefs?.remove(_responseStorageKey(ownerUserId));
    await _suppressionMemoryService.clearAll(ownerUserId);
  }

  Future<List<RecommendationFeedbackPromptPlan>> listPendingPlans(
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
        .toList();
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
                  'next_contextual_session',
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
      familyKey: 'recommendation_feedback_follow_up',
      targetKey:
          _suppressionTargetKey(entity: plan.entity, action: plan.action),
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
      familyKey: 'recommendation_feedback_follow_up',
      targetKey:
          _suppressionTargetKey(entity: plan.entity, action: plan.action),
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

  Future<RecommendationFeedbackPromptPlan?> activeAssistantFollowUpPlan(
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

  Future<RecommendationFeedbackPromptResponse> completePlanWithResponse({
    required String ownerUserId,
    required String planId,
    required String responseText,
    String sourceSurface = 'in_app_follow_up_queue',
  }) async {
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () => throw StateError('Unknown feedback prompt plan: $planId'),
    );
    final responseTime = DateTime.now().toUtc();
    final response = RecommendationFeedbackPromptResponse(
      responseId:
          'feedback_prompt_response_${plan.planId}_${responseTime.millisecondsSinceEpoch}',
      planId: plan.planId,
      ownerUserId: ownerUserId,
      entity: plan.entity,
      respondedAtUtc: responseTime,
      responseText: responseText.trim(),
      sourceSurface: sourceSurface,
      completionMode: _completionModeForSourceSurface(sourceSurface),
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
      },
      signalTags: <String>[
        ...plan.signalTags,
        'prompt_response:completed',
        'completion_mode:in_app_follow_up_queue',
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
    await _stageCompletedResponseBestEffort(
      plan: plan,
      response: response,
    );
    return response;
  }

  Future<List<RecommendationFeedbackPromptResponse>> listResponses(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_responseStorageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <RecommendationFeedbackPromptResponse>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <RecommendationFeedbackPromptResponse>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => RecommendationFeedbackPromptResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.respondedAtUtc.compareTo(a.respondedAtUtc));
    } catch (_) {
      return const <RecommendationFeedbackPromptResponse>[];
    }
  }

  String _storageKey(String ownerUserId) => '$_storageKeyPrefix$ownerUserId';
  String _responseStorageKey(String ownerUserId) =>
      '$_responseStorageKeyPrefix$ownerUserId';

  String _completionModeForSourceSurface(String sourceSurface) {
    switch (sourceSurface) {
      case 'assistant_follow_up_chat':
        return 'assistant_follow_up_chat';
      case 'explore_in_app_follow_up':
      case 'in_app_follow_up_queue':
        return 'in_app_follow_up_queue';
      default:
        return 'bounded_follow_up_response';
    }
  }

  Future<void> _stageCompletedResponseBestEffort({
    required RecommendationFeedbackPromptPlan plan,
    required RecommendationFeedbackPromptResponse response,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null || response.responseText.trim().isEmpty) {
      return;
    }
    try {
      final airGapArtifact = _upwardAirGapService.issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'recommendation_feedback_follow_up_response_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'entity': plan.entity.toJson(),
          'feedbackAction': plan.action.name,
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
      await service.stageRecommendationFeedbackFollowUpResponseIntake(
        ownerUserId: plan.ownerUserId,
        action: plan.action,
        entity: plan.entity,
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
          'domains': response.signalTags
              .where((tag) => tag.startsWith('domain:'))
              .map((tag) => tag.substring('domain:'.length))
              .toList(),
        },
      );
    } catch (_) {
      // Best-effort only. Prompt response storage must not fail if upward staging is unavailable.
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
    final updatedPlans = plans.map(
      (plan) {
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
        return RecommendationFeedbackPromptPlan(
          planId: plan.planId,
          ownerUserId: plan.ownerUserId,
          sourceEventRef: plan.sourceEventRef,
          entity: plan.entity,
          action: plan.action,
          eventOccurredAtUtc: plan.eventOccurredAtUtc,
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
      },
    ).toList();
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

  String _buildPromptQuestion({
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
    RecommendationAttribution? attribution,
  }) {
    final explanationHeadline = _preferredAttributionHeadline(
      attribution,
      preferExplanationHeadline:
          action == RecommendationFeedbackAction.whyDidYouShowThis,
    );
    switch (action) {
      case RecommendationFeedbackAction.dismiss:
      case RecommendationFeedbackAction.lessLikeThis:
        return 'What felt off about "${entity.title}" for you right then?';
      case RecommendationFeedbackAction.moreLikeThis:
        return 'What about "${entity.title}" should AVRAI generalize into more recommendations like this?';
      case RecommendationFeedbackAction.whyDidYouShowThis:
        return explanationHeadline == null
            ? 'Did AVRAI explain why "${entity.title}" was shown to you accurately enough?'
            : 'AVRAI told you "${entity.title}" was shown because "$explanationHeadline". What did it get right or wrong?';
      case RecommendationFeedbackAction.meaningful:
        return 'What made "${entity.title}" feel meaningful in that moment?';
      case RecommendationFeedbackAction.fun:
        return 'What specifically made "${entity.title}" feel fun for you?';
      case RecommendationFeedbackAction.opened:
        return 'What made "${entity.title}" worth opening when you saw it?';
      case RecommendationFeedbackAction.save:
        return attribution?.why.isNotEmpty == true
            ? 'What made "${entity.title}" worth saving after AVRAI framed it as "${attribution!.why}"?'
            : 'What made "${entity.title}" worth saving for you?';
    }
  }

  String _buildPromptRationale({
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
    required String sourceSurface,
    RecommendationAttribution? attribution,
  }) {
    final whyFragment = _preferredAttributionContext(attribution);
    final reason = whyFragment == null || whyFragment.isEmpty
        ? 'The runtime already knows what happened and where it surfaced.'
        : action == RecommendationFeedbackAction.whyDidYouShowThis
            ? 'The runtime already recorded the explanation as "$whyFragment".'
            : 'The runtime already knows it was surfaced because "$whyFragment".';
    return 'A bounded follow-up can clarify why ${entity.title} led to a ${action.name} signal on $sourceSurface. $reason';
  }

  String _priorityForAction(RecommendationFeedbackAction action) {
    switch (action) {
      case RecommendationFeedbackAction.lessLikeThis:
      case RecommendationFeedbackAction.whyDidYouShowThis:
      case RecommendationFeedbackAction.meaningful:
      case RecommendationFeedbackAction.fun:
        return 'high';
      case RecommendationFeedbackAction.dismiss:
      case RecommendationFeedbackAction.moreLikeThis:
      case RecommendationFeedbackAction.save:
        return 'medium';
      case RecommendationFeedbackAction.opened:
        return 'low';
    }
  }

  String _channelHintForAction(RecommendationFeedbackAction action) {
    switch (action) {
      case RecommendationFeedbackAction.lessLikeThis:
      case RecommendationFeedbackAction.dismiss:
        return 'next_contextual_session';
      case RecommendationFeedbackAction.whyDidYouShowThis:
        return 'explanation_clarification_follow_up';
      case RecommendationFeedbackAction.meaningful:
      case RecommendationFeedbackAction.fun:
      case RecommendationFeedbackAction.moreLikeThis:
      case RecommendationFeedbackAction.save:
        return 'lightweight_in_app_reflection';
      case RecommendationFeedbackAction.opened:
        return 'low_priority_session_follow_up';
    }
  }

  Map<String, dynamic> _buildBoundedContext({
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
    required DateTime occurredAtUtc,
    required DateTime nextEligibleAtUtc,
    required String sourceSurface,
    RecommendationAttribution? attribution,
    required Map<String, dynamic> metadata,
  }) {
    final localityContext = entity.localityLabel ??
        metadata['localityLabel'] as String? ??
        metadata['cityCode'] as String? ??
        metadata['city_code'] as String? ??
        'unknown_locality';
    final domains = (metadata['domains'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toList();
    return <String, dynamic>{
      'what':
          '${action.name} on ${entity.type.name}:${entity.id}:${entity.title}',
      'why': attribution == null
          ? 'No explicit recommendation attribution was attached.'
          : _preferredAttributionContext(attribution),
      if ((attribution?.whyDetails ?? '').isNotEmpty)
        'whyDetails': attribution!.whyDetails,
      'how': attribution == null
          ? 'surfaced via $sourceSurface'
          : '${attribution.recommendationSource} via $sourceSurface',
      'whenUtc': occurredAtUtc.toIso8601String(),
      'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
      'where': localityContext,
      'who': 'owner_user_feedback_actor',
      'domains': domains,
      'projectedEnjoyabilityPercent': attribution?.projectedEnjoyabilityPercent,
      'confidence': attribution?.confidence,
      'metadata': metadata,
    };
  }

  List<String> _buildSignalTags({
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
    required String sourceSurface,
    RecommendationAttribution? attribution,
    required Map<String, dynamic> metadata,
  }) {
    return <String>[
      'feedback_action:${action.name}',
      'entity_type:${entity.type.name}',
      'source_surface:$sourceSurface',
      if (entity.localityLabel?.isNotEmpty == true)
        'locality:${entity.localityLabel}',
      if ((attribution?.recommendationSource ?? '').isNotEmpty)
        'recommendation_source:${attribution!.recommendationSource}',
      ...((metadata['domains'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .map((domain) => 'domain:$domain')),
    ];
  }

  String? _preferredAttributionHeadline(
    RecommendationAttribution? attribution, {
    bool preferExplanationHeadline = false,
  }) {
    if (attribution == null) {
      return null;
    }
    final headline = attribution.why.trim();
    final details = (attribution.whyDetails ?? '').trim();
    if (preferExplanationHeadline && headline.isNotEmpty) {
      return headline;
    }
    if (_isEvidenceBackedExplanation(headline)) {
      return headline;
    }
    if (details.isNotEmpty) {
      return details;
    }
    return headline.isEmpty ? null : headline;
  }

  String? _preferredAttributionContext(RecommendationAttribution? attribution) {
    if (attribution == null) {
      return null;
    }
    final headline = attribution.why.trim();
    final details = (attribution.whyDetails ?? '').trim();
    if (_isEvidenceBackedExplanation(headline)) {
      return headline;
    }
    if (details.isNotEmpty) {
      return details;
    }
    return headline.isEmpty ? null : headline;
  }

  bool _isEvidenceBackedExplanation(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return normalized.startsWith('a recent signal that ') ||
        normalized.startsWith('a recent ') &&
            (normalized.contains('boosted this recommendation') ||
                normalized.contains('helped boost this spot'));
  }

  DateTime? _nextEligibleAtUtcFromPlan(
    RecommendationFeedbackPromptPlan plan,
  ) {
    final raw = plan.boundedContext['nextEligibleAtUtc']?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  String _suppressionTargetKey({
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
  }) {
    return '${entity.type.name}:${entity.id}:${action.name}';
  }

  bool _isSameUtcDay(DateTime left, DateTime right) {
    final leftUtc = left.toUtc();
    final rightUtc = right.toUtc();
    return leftUtc.year == rightUtc.year &&
        leftUtc.month == rightUtc.month &&
        leftUtc.day == rightUtc.day;
  }
}
