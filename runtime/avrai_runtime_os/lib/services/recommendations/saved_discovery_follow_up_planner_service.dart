import 'dart:convert';

import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_suppression_memory_service.dart';
import 'package:get_it/get_it.dart';

class SavedDiscoveryFollowUpPromptPlan {
  final String planId;
  final String ownerUserId;
  final String sourceEventRef;
  final DiscoveryEntityReference entity;
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

  const SavedDiscoveryFollowUpPromptPlan({
    required this.planId,
    required this.ownerUserId,
    required this.sourceEventRef,
    required this.entity,
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'planId': planId,
      'ownerUserId': ownerUserId,
      'sourceEventRef': sourceEventRef,
      'entity': entity.toJson(),
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

  factory SavedDiscoveryFollowUpPromptPlan.fromJson(Map<String, dynamic> json) {
    return SavedDiscoveryFollowUpPromptPlan(
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      sourceEventRef: json['sourceEventRef'] as String? ?? '',
      entity: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['entity'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      action: json['action'] as String? ?? 'save',
      occurredAtUtc:
          DateTime.tryParse(json['occurredAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      plannedAtUtc:
          DateTime.tryParse(json['plannedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'saved_discovery',
      promptQuestion: json['promptQuestion'] as String? ?? '',
      promptRationale: json['promptRationale'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      channelHint:
          json['channelHint'] as String? ?? 'lightweight_in_app_reflection',
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

class SavedDiscoveryFollowUpPromptResponse {
  final String responseId;
  final String planId;
  final String ownerUserId;
  final DiscoveryEntityReference entity;
  final String action;
  final DateTime respondedAtUtc;
  final String responseText;
  final String sourceSurface;
  final String completionMode;
  final Map<String, dynamic> boundedContext;
  final List<String> signalTags;

  const SavedDiscoveryFollowUpPromptResponse({
    required this.responseId,
    required this.planId,
    required this.ownerUserId,
    required this.entity,
    required this.action,
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
      'action': action,
      'respondedAtUtc': respondedAtUtc.toUtc().toIso8601String(),
      'responseText': responseText,
      'sourceSurface': sourceSurface,
      'completionMode': completionMode,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory SavedDiscoveryFollowUpPromptResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return SavedDiscoveryFollowUpPromptResponse(
      responseId: json['responseId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      entity: DiscoveryEntityReference.fromJson(
        Map<String, dynamic>.from(
          json['entity'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      action: json['action'] as String? ?? 'save',
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

class SavedDiscoveryFollowUpPromptPlannerService {
  static const String _storageKeyPrefix =
      'bham:saved_discovery_follow_up_prompt_plans:v1:';
  static const String _responseStorageKeyPrefix =
      'bham:saved_discovery_follow_up_prompt_responses:v1:';

  final SharedPreferencesCompat? _prefs;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final UpwardAirGapService _upwardAirGapService;
  final BoundedFollowUpPromptPolicyService _promptPolicyService;
  final BoundedFollowUpSuppressionMemoryService _suppressionMemoryService;

  SavedDiscoveryFollowUpPromptPlannerService({
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

  Future<SavedDiscoveryFollowUpPromptPlan> createPlan({
    required String ownerUserId,
    required DiscoveryEntityReference entity,
    required String action,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    RecommendationAttribution? attribution,
  }) async {
    final existingPlans = await listPlans(ownerUserId);
    final sourceEventRef =
        '${entity.type.name}:${entity.id}:$action:${occurredAtUtc.toUtc().millisecondsSinceEpoch}';
    final existing = existingPlans.where(
      (plan) => plan.sourceEventRef == sourceEventRef,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final planTime = DateTime.now().toUtc();
    final channelHint = _channelHintForAction(action);
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((plan) => _isSameUtcDay(plan.plannedAtUtc, planTime))
          .length,
    );
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'saved_discovery_follow_up',
      targetKey: _suppressionTargetKey(entity: entity, action: action),
    );
    final boundedContext = _buildBoundedContext(
      entity: entity,
      action: action,
      occurredAtUtc: occurredAtUtc.toUtc(),
      nextEligibleAtUtc: nextEligibleAtUtc,
      sourceSurface: sourceSurface,
      attribution: attribution,
    );
    final plan = SavedDiscoveryFollowUpPromptPlan(
      planId:
          'saved_discovery_follow_up_plan_${entity.type.name}_${entity.id}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      sourceEventRef: sourceEventRef,
      entity: entity,
      action: action,
      occurredAtUtc: occurredAtUtc.toUtc(),
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
      ),
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

  Future<List<SavedDiscoveryFollowUpPromptPlan>> listPlans(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <SavedDiscoveryFollowUpPromptPlan>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <SavedDiscoveryFollowUpPromptPlan>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => SavedDiscoveryFollowUpPromptPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    } catch (_) {
      return const <SavedDiscoveryFollowUpPromptPlan>[];
    }
  }

  Future<List<SavedDiscoveryFollowUpPromptPlan>> listPendingPlans(
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
                  'saved_discovery_reflection_follow_up',
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
      familyKey: 'saved_discovery_follow_up',
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
      familyKey: 'saved_discovery_follow_up',
      targetKey: _suppressionTargetKey(
        entity: plan.entity,
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

  Future<SavedDiscoveryFollowUpPromptPlan?> activeAssistantFollowUpPlan(
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

  Future<SavedDiscoveryFollowUpPromptResponse> completePlanWithResponse({
    required String ownerUserId,
    required String planId,
    required String responseText,
    String sourceSurface = 'in_app_follow_up_queue',
  }) async {
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () =>
          throw StateError('Unknown saved discovery follow-up plan: $planId'),
    );
    final responseTime = DateTime.now().toUtc();
    final response = SavedDiscoveryFollowUpPromptResponse(
      responseId:
          'saved_discovery_follow_up_response_${plan.planId}_${responseTime.millisecondsSinceEpoch}',
      planId: plan.planId,
      ownerUserId: ownerUserId,
      entity: plan.entity,
      action: plan.action,
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

  Future<List<SavedDiscoveryFollowUpPromptResponse>> listResponses(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_responseStorageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <SavedDiscoveryFollowUpPromptResponse>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <SavedDiscoveryFollowUpPromptResponse>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => SavedDiscoveryFollowUpPromptResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.respondedAtUtc.compareTo(a.respondedAtUtc));
    } catch (_) {
      return const <SavedDiscoveryFollowUpPromptResponse>[];
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

  String _completionModeForSourceSurface(String sourceSurface) {
    switch (sourceSurface) {
      case 'assistant_follow_up_chat':
        return 'assistant_follow_up_chat';
      case 'saved_discovery_in_app_follow_up':
      case 'in_app_follow_up_queue':
        return 'in_app_follow_up_queue';
      default:
        return 'bounded_follow_up_response';
    }
  }

  Future<void> _stageCompletedResponseBestEffort({
    required SavedDiscoveryFollowUpPromptPlan plan,
    required SavedDiscoveryFollowUpPromptResponse response,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null || response.responseText.trim().isEmpty) {
      return;
    }
    try {
      final airGapArtifact = _upwardAirGapService.issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'saved_discovery_follow_up_response_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'entity': plan.entity.toJson(),
          'action': plan.action,
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
      await service.stageSavedDiscoveryFollowUpResponseIntake(
        ownerUserId: plan.ownerUserId,
        entity: plan.entity,
        action: plan.action,
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
              .toList(growable: false),
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
      return SavedDiscoveryFollowUpPromptPlan(
        planId: plan.planId,
        ownerUserId: plan.ownerUserId,
        sourceEventRef: plan.sourceEventRef,
        entity: plan.entity,
        action: plan.action,
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

  String _buildPromptQuestion({
    required DiscoveryEntityReference entity,
    required String action,
    RecommendationAttribution? attribution,
  }) {
    if (action == 'unsave') {
      return 'What changed about "${entity.title}" enough for you to remove it from saved discovery?';
    }
    if (attribution?.why.isNotEmpty ?? false) {
      return 'What made "${entity.title}" worth keeping after AVRAI framed it as "${attribution!.why}"?';
    }
    return 'What made "${entity.title}" worth saving for later?';
  }

  String _buildPromptRationale({
    required DiscoveryEntityReference entity,
    required String action,
    required String sourceSurface,
    RecommendationAttribution? attribution,
  }) {
    final verb = action == 'unsave' ? 'removed from' : 'saved from';
    final whyFragment = _preferredAttributionContext(attribution);
    final reason = whyFragment == null || whyFragment.isEmpty
        ? 'The runtime already knows the save or unsave action and where it happened.'
        : 'The runtime already recorded the explanation as "$whyFragment".';
    return 'A bounded follow-up can clarify why ${entity.title} was $verb $sourceSurface so future discovery curation stays grounded. $reason';
  }

  String _priorityForAction(String action) {
    return action == 'unsave' ? 'high' : 'medium';
  }

  String _channelHintForAction(String action) {
    return action == 'unsave'
        ? 'saved_discovery_unsave_follow_up'
        : 'saved_discovery_reflection_follow_up';
  }

  Map<String, dynamic> _buildBoundedContext({
    required DiscoveryEntityReference entity,
    required String action,
    required DateTime occurredAtUtc,
    required DateTime nextEligibleAtUtc,
    required String sourceSurface,
    RecommendationAttribution? attribution,
  }) {
    return <String, dynamic>{
      'what': '$action on ${entity.type.name}:${entity.id}:${entity.title}',
      'why': _preferredAttributionContext(attribution) ??
          'The runtime already knows the save or unsave action and where it happened.',
      if ((attribution?.whyDetails ?? '').isNotEmpty)
        'whyDetails': attribution!.whyDetails,
      'how': attribution == null
          ? 'curated via $sourceSurface'
          : '${attribution.recommendationSource} via $sourceSurface',
      'whenUtc': occurredAtUtc.toIso8601String(),
      'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
      'where': entity.localityLabel ?? 'unknown_locality',
      'who': 'owner_user_saved_discovery_actor',
      'action': action,
      'domains': _baseDomainsForEntity(entity),
    };
  }

  List<String> _buildSignalTags({
    required DiscoveryEntityReference entity,
    required String action,
    required String sourceSurface,
    RecommendationAttribution? attribution,
  }) {
    return <String>[
      'source:saved_discovery_follow_up_plan',
      'action:$action',
      'entity_type:${entity.type.name}',
      'surface:$sourceSurface',
      if (entity.localityLabel?.isNotEmpty == true)
        'locality:${entity.localityLabel}',
      if ((attribution?.recommendationSource ?? '').isNotEmpty)
        'recommendation_source:${attribution!.recommendationSource}',
      ..._baseDomainsForEntity(entity).map((domain) => 'domain:$domain'),
    ]..sort();
  }

  List<String> _baseDomainsForEntity(DiscoveryEntityReference entity) {
    return <String>[
      switch (entity.type) {
        DiscoveryEntityType.spot => 'place',
        DiscoveryEntityType.list => 'list',
        DiscoveryEntityType.event => 'event',
        DiscoveryEntityType.club => 'community',
        DiscoveryEntityType.community => 'community',
      },
      if (entity.localityLabel?.trim().isNotEmpty ?? false) 'locality',
    ]..sort();
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

  DateTime? _nextEligibleAtUtcFromPlan(SavedDiscoveryFollowUpPromptPlan plan) {
    final raw = plan.boundedContext['nextEligibleAtUtc']?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  String _suppressionTargetKey({
    required DiscoveryEntityReference entity,
    required String action,
  }) {
    return '${entity.type.name}:${entity.id}:$action';
  }

  bool _isSameUtcDay(DateTime left, DateTime right) {
    final leftUtc = left.toUtc();
    final rightUtc = right.toUtc();
    return leftUtc.year == rightUtc.year &&
        leftUtc.month == rightUtc.month &&
        leftUtc.day == rightUtc.day;
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
}
