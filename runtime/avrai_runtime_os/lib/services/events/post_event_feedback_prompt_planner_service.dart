import 'dart:convert';

import 'package:avrai_core/models/events/event_feedback.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_suppression_memory_service.dart';
import 'package:get_it/get_it.dart';

class PostEventFeedbackPromptPlan {
  final String planId;
  final String ownerUserId;
  final String sourceFeedbackId;
  final String eventId;
  final String eventTitle;
  final DateTime feedbackOccurredAtUtc;
  final DateTime plannedAtUtc;
  final String sourceSurface;
  final String promptQuestion;
  final String promptRationale;
  final String priority;
  final String channelHint;
  final String status;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  const PostEventFeedbackPromptPlan({
    required this.planId,
    required this.ownerUserId,
    required this.sourceFeedbackId,
    required this.eventId,
    required this.eventTitle,
    required this.feedbackOccurredAtUtc,
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
      'sourceFeedbackId': sourceFeedbackId,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'feedbackOccurredAtUtc': feedbackOccurredAtUtc.toUtc().toIso8601String(),
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

  factory PostEventFeedbackPromptPlan.fromJson(Map<String, dynamic> json) {
    return PostEventFeedbackPromptPlan(
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      sourceFeedbackId: json['sourceFeedbackId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      eventTitle: json['eventTitle'] as String? ?? '',
      feedbackOccurredAtUtc:
          DateTime.tryParse(json['feedbackOccurredAtUtc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      plannedAtUtc:
          DateTime.tryParse(json['plannedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'post_event_feedback',
      promptQuestion: json['promptQuestion'] as String? ?? '',
      promptRationale: json['promptRationale'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      channelHint: json['channelHint'] as String? ?? 'next_contextual_session',
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

class PostEventFeedbackPromptResponse {
  final String responseId;
  final String planId;
  final String ownerUserId;
  final String sourceFeedbackId;
  final String eventId;
  final String eventTitle;
  final DateTime respondedAtUtc;
  final String responseText;
  final String sourceSurface;
  final String completionMode;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  const PostEventFeedbackPromptResponse({
    required this.responseId,
    required this.planId,
    required this.ownerUserId,
    required this.sourceFeedbackId,
    required this.eventId,
    required this.eventTitle,
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
      'sourceFeedbackId': sourceFeedbackId,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'respondedAtUtc': respondedAtUtc.toUtc().toIso8601String(),
      'responseText': responseText,
      'sourceSurface': sourceSurface,
      'completionMode': completionMode,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory PostEventFeedbackPromptResponse.fromJson(Map<String, dynamic> json) {
    return PostEventFeedbackPromptResponse(
      responseId: json['responseId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      sourceFeedbackId: json['sourceFeedbackId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      eventTitle: json['eventTitle'] as String? ?? '',
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
          .toList(growable: false),
    );
  }
}

class PostEventFeedbackPromptPlannerService {
  static const String _storageKeyPrefix =
      'bham:event_feedback_prompt_plans:v1:';
  static const String _responseStorageKeyPrefix =
      'bham:event_feedback_prompt_responses:v1:';

  final SharedPreferencesCompat? _prefs;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final UpwardAirGapService _upwardAirGapService;
  final BoundedFollowUpPromptPolicyService _promptPolicyService;
  final BoundedFollowUpSuppressionMemoryService _suppressionMemoryService;

  PostEventFeedbackPromptPlannerService({
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

  Future<PostEventFeedbackPromptPlan> createPlan({
    required EventFeedback feedback,
    ExpertiseEvent? event,
  }) async {
    final existingPlans = await listPlans(feedback.userId);
    final matchingPlan = existingPlans.where(
      (plan) => plan.sourceFeedbackId == feedback.id,
    );
    if (matchingPlan.isNotEmpty) {
      return matchingPlan.first;
    }

    final feedbackTime = feedback.submittedAt.toUtc();
    final planTime = DateTime.now().toUtc();
    final channelHint = _channelHintForFeedback(feedback);
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((existing) => _isSameUtcDay(existing.plannedAtUtc, planTime))
          .length,
    );
    final eventTitle = _eventTitle(event);
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: feedback.userId,
      familyKey: 'event_feedback_follow_up',
      targetKey: _suppressionTargetKey(eventId: feedback.eventId),
    );
    final boundedContext = _buildBoundedContext(
      feedback: feedback,
      event: event,
      eventTitle: eventTitle,
      nextEligibleAtUtc: nextEligibleAtUtc,
    );
    final plan = PostEventFeedbackPromptPlan(
      planId:
          'event_feedback_prompt_plan_${feedback.id}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: feedback.userId,
      sourceFeedbackId: feedback.id,
      eventId: feedback.eventId,
      eventTitle: eventTitle,
      feedbackOccurredAtUtc: feedbackTime,
      plannedAtUtc: planTime,
      sourceSurface: 'post_event_feedback',
      promptQuestion: _buildPromptQuestion(
        feedback: feedback,
        eventTitle: eventTitle,
      ),
      promptRationale: _buildPromptRationale(
        feedback: feedback,
        eventTitle: eventTitle,
      ),
      priority: _priorityForFeedback(feedback),
      channelHint: channelHint,
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      boundedContext: <String, dynamic>{
        ...boundedContext,
        'suppressionTargetKey':
            _suppressionTargetKey(eventId: feedback.eventId),
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: _buildSignalTags(
        feedback: feedback,
        event: event,
      ),
    );

    await _prefs?.setString(
      _storageKey(feedback.userId),
      jsonEncode(
        <Map<String, dynamic>>[
          plan.toJson(),
          ...existingPlans.map((item) => item.toJson()),
        ],
      ),
    );
    return plan;
  }

  Future<List<PostEventFeedbackPromptPlan>> listPlans(
      String ownerUserId) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <PostEventFeedbackPromptPlan>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <PostEventFeedbackPromptPlan>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => PostEventFeedbackPromptPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    } catch (_) {
      return const <PostEventFeedbackPromptPlan>[];
    }
  }

  Future<List<PostEventFeedbackPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return const <PostEventFeedbackPromptPlan>[];
    }
    final plans = <PostEventFeedbackPromptPlan>[];
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

  Future<List<PostEventFeedbackPromptPlan>> listPendingPlans(
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
                  'event_reflection_follow_up',
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
      familyKey: 'event_feedback_follow_up',
      targetKey: _suppressionTargetKey(eventId: plan.eventId),
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
      familyKey: 'event_feedback_follow_up',
      targetKey: _suppressionTargetKey(eventId: plan.eventId),
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

  Future<PostEventFeedbackPromptPlan?> activeAssistantFollowUpPlan(
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

  Future<PostEventFeedbackPromptResponse> completePlanWithResponse({
    required String ownerUserId,
    required String planId,
    required String responseText,
    String sourceSurface = 'in_app_follow_up_queue',
  }) async {
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () =>
          throw StateError('Unknown event feedback prompt plan: $planId'),
    );
    final responseTime = DateTime.now().toUtc();
    final response = PostEventFeedbackPromptResponse(
      responseId:
          'event_feedback_prompt_response_${plan.planId}_${responseTime.millisecondsSinceEpoch}',
      planId: plan.planId,
      ownerUserId: ownerUserId,
      sourceFeedbackId: plan.sourceFeedbackId,
      eventId: plan.eventId,
      eventTitle: plan.eventTitle,
      respondedAtUtc: responseTime,
      responseText: responseText.trim(),
      sourceSurface: sourceSurface,
      completionMode: _completionModeForSourceSurface(sourceSurface),
      boundedContext: <String, dynamic>{
        'promptQuestion': plan.promptQuestion,
        'priority': plan.priority,
        'channelHint': plan.channelHint,
        'sourceFeedbackId': plan.sourceFeedbackId,
        'what': plan.boundedContext['what'],
        'why': plan.boundedContext['why'],
        'how': plan.boundedContext['how'],
        'whenUtc': plan.boundedContext['whenUtc'],
        'where': plan.boundedContext['where'],
        'who': plan.boundedContext['who'],
        'feedbackRole': plan.boundedContext['feedbackRole'],
        'overallRating': plan.boundedContext['overallRating'],
        'wouldAttendAgain': plan.boundedContext['wouldAttendAgain'],
        'wouldRecommend': plan.boundedContext['wouldRecommend'],
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
    await _stageCompletedResponseBestEffort(
      plan: plan,
      response: response,
    );
    return response;
  }

  Future<List<PostEventFeedbackPromptResponse>> listResponses(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_responseStorageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <PostEventFeedbackPromptResponse>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <PostEventFeedbackPromptResponse>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => PostEventFeedbackPromptResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.respondedAtUtc.compareTo(a.respondedAtUtc));
    } catch (_) {
      return const <PostEventFeedbackPromptResponse>[];
    }
  }

  String _storageKey(String ownerUserId) => '$_storageKeyPrefix$ownerUserId';

  String _responseStorageKey(String ownerUserId) =>
      '$_responseStorageKeyPrefix$ownerUserId';

  String _completionModeForSourceSurface(String sourceSurface) {
    switch (sourceSurface) {
      case 'assistant_follow_up_chat':
        return 'assistant_follow_up_chat';
      case 'in_app_follow_up_queue':
      case 'event_feedback_in_app_follow_up':
        return 'in_app_follow_up_queue';
      default:
        return 'bounded_follow_up_response';
    }
  }

  Future<void> _stageCompletedResponseBestEffort({
    required PostEventFeedbackPromptPlan plan,
    required PostEventFeedbackPromptResponse response,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null || response.responseText.trim().isEmpty) {
      return;
    }
    try {
      final airGapArtifact = _upwardAirGapService.issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'event_feedback_follow_up_response_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'eventId': plan.eventId,
          'eventTitle': plan.eventTitle,
          'sourceFeedbackId': plan.sourceFeedbackId,
          'promptQuestion': plan.promptQuestion,
          'promptRationale': plan.promptRationale,
          'responseText': response.responseText,
          'sourceSurface': response.sourceSurface,
          'completionMode': response.completionMode,
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
        },
      );
      await service.stageEventFeedbackFollowUpResponseIntake(
        ownerUserId: plan.ownerUserId,
        eventId: plan.eventId,
        eventTitle: plan.eventTitle,
        occurredAtUtc: response.respondedAtUtc,
        sourceSurface: response.sourceSurface,
        promptQuestion: plan.promptQuestion,
        promptRationale: plan.promptRationale,
        responseText: response.responseText,
        completionMode: response.completionMode,
        airGapArtifact: airGapArtifact,
        metadata: <String, dynamic>{
          'sourceFeedbackId': plan.sourceFeedbackId,
          'priority': plan.priority,
          'channelHint': plan.channelHint,
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
          'domains': (plan.boundedContext['domains'] as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
          'feedbackRole': plan.boundedContext['feedbackRole'],
          'overallRating': plan.boundedContext['overallRating'],
          'wouldAttendAgain': plan.boundedContext['wouldAttendAgain'],
          'wouldRecommend': plan.boundedContext['wouldRecommend'],
          'eventCategory': plan.boundedContext['eventCategory'],
          'localityCode': plan.boundedContext['localityCode'],
          'cityCode': plan.boundedContext['cityCode'],
        },
      );
    } catch (_) {
      // Best-effort only. Local follow-up response storage must remain durable.
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
        return PostEventFeedbackPromptPlan(
          planId: plan.planId,
          ownerUserId: plan.ownerUserId,
          sourceFeedbackId: plan.sourceFeedbackId,
          eventId: plan.eventId,
          eventTitle: plan.eventTitle,
          feedbackOccurredAtUtc: plan.feedbackOccurredAtUtc,
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
    ).toList(growable: false);
    await _prefs?.setString(
      _storageKey(ownerUserId),
      jsonEncode(updatedPlans.map((plan) => plan.toJson()).toList()),
    );
  }

  String _eventTitle(ExpertiseEvent? event) {
    final title = event?.title.trim();
    return title == null || title.isEmpty ? 'this event' : title;
  }

  String _buildPromptQuestion({
    required EventFeedback feedback,
    required String eventTitle,
  }) {
    if (!feedback.wouldAttendAgain ||
        feedback.overallRating <= 3.4 ||
        (feedback.improvements?.isNotEmpty ?? false)) {
      return 'What about "$eventTitle" should AVRAI change or avoid repeating next time?';
    }
    if (feedback.wouldRecommend ||
        feedback.overallRating >= 4.2 ||
        (feedback.highlights?.isNotEmpty ?? false)) {
      return 'What about "$eventTitle" should AVRAI preserve or generalize into future event suggestions?';
    }
    return 'What detail about "$eventTitle" most shaped how it felt for you?';
  }

  String _buildPromptRationale({
    required EventFeedback feedback,
    required String eventTitle,
  }) {
    if (!feedback.wouldAttendAgain || feedback.overallRating <= 3.4) {
      return 'A bounded follow-up can clarify why $eventTitle missed expectation after the post-event feedback signal.';
    }
    if (feedback.wouldRecommend || feedback.overallRating >= 4.2) {
      return 'A bounded follow-up can clarify what about $eventTitle should be reinforced in future event recommendations.';
    }
    return 'A bounded follow-up can clarify the strongest detail behind how $eventTitle was experienced.';
  }

  String _priorityForFeedback(EventFeedback feedback) {
    if (!feedback.wouldAttendAgain ||
        !feedback.wouldRecommend ||
        feedback.overallRating <= 3.2 ||
        (feedback.improvements?.isNotEmpty ?? false)) {
      return 'high';
    }
    if (feedback.overallRating >= 4.4 ||
        (feedback.highlights?.isNotEmpty ?? false)) {
      return 'medium';
    }
    return 'low';
  }

  String _channelHintForFeedback(EventFeedback feedback) {
    if (!feedback.wouldAttendAgain || feedback.overallRating <= 3.4) {
      return 'event_reflection_follow_up';
    }
    if (feedback.wouldRecommend || feedback.overallRating >= 4.2) {
      return 'future_event_preference_follow_up';
    }
    return 'lightweight_event_reflection';
  }

  Map<String, dynamic> _buildBoundedContext({
    required EventFeedback feedback,
    required ExpertiseEvent? event,
    required String eventTitle,
    required DateTime nextEligibleAtUtc,
  }) {
    final domains = <String>{
      'event',
      if ((event?.localityCode?.trim().isNotEmpty ?? false)) 'locality',
      if ((event?.category.trim().isNotEmpty ?? false)) 'community',
      if (feedback.categoryRatings.containsKey('venue')) 'venue',
    }.toList()
      ..sort();
    return <String, dynamic>{
      'what': 'event_feedback on ${feedback.eventId}:$eventTitle',
      'why': !feedback.wouldAttendAgain || feedback.overallRating <= 3.4
          ? 'The event feedback suggests a meaningful mismatch worth clarifying.'
          : 'The event feedback suggests a meaningful success pattern worth preserving.',
      'how': 'submitted via post_event_feedback',
      'whenUtc': feedback.submittedAt.toUtc().toIso8601String(),
      'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
      'where': event?.localityCode?.trim().isNotEmpty == true
          ? event!.localityCode!.trim()
          : event?.cityCode?.trim().isNotEmpty == true
              ? event!.cityCode!.trim()
              : 'unknown_event_locality',
      'who': 'owner_user_feedback_actor',
      'feedbackRole': feedback.userRole,
      'overallRating': feedback.overallRating,
      'wouldAttendAgain': feedback.wouldAttendAgain,
      'wouldRecommend': feedback.wouldRecommend,
      'eventCategory': event?.category,
      'localityCode': event?.localityCode,
      'cityCode': event?.cityCode,
      'domains': domains,
    };
  }

  List<String> _buildSignalTags({
    required EventFeedback feedback,
    required ExpertiseEvent? event,
  }) {
    return <String>[
      'source:event_feedback_follow_up_plan',
      'surface:post_event_feedback',
      'feedback_role:${feedback.userRole}',
      if (!feedback.wouldAttendAgain) 'would_attend_again:false',
      if (feedback.wouldRecommend) 'would_recommend:true',
      if ((event?.category.trim().isNotEmpty ?? false))
        'event_category:${event!.category.trim().toLowerCase()}',
      if ((event?.localityCode?.trim().isNotEmpty ?? false))
        'locality:${event!.localityCode!.trim()}',
      ...((feedback.categoryRatings.keys).map(
        (key) => 'rating_category:${key.trim().toLowerCase()}',
      )),
    ]..sort();
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

  String _suppressionTargetKey({
    required String eventId,
  }) {
    return 'event:$eventId';
  }

  DateTime? _nextEligibleAtUtcFromPlan(PostEventFeedbackPromptPlan plan) {
    final raw = plan.boundedContext['nextEligibleAtUtc']?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  bool _isSameUtcDay(DateTime left, DateTime right) {
    final leftUtc = left.toUtc();
    final rightUtc = right.toUtc();
    return leftUtc.year == rightUtc.year &&
        leftUtc.month == rightUtc.month &&
        leftUtc.day == rightUtc.day;
  }
}
