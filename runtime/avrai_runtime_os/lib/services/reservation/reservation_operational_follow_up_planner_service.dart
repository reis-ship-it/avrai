import 'dart:convert';

import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_suppression_memory_service.dart';
import 'package:get_it/get_it.dart';

class ReservationOperationalFollowUpPromptPlan {
  const ReservationOperationalFollowUpPromptPlan({
    required this.planId,
    required this.ownerUserId,
    required this.reservationId,
    required this.reservationType,
    required this.targetId,
    required this.targetLabel,
    required this.operationKind,
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
  final String reservationId;
  final String reservationType;
  final String targetId;
  final String targetLabel;
  final String operationKind;
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
      'reservationId': reservationId,
      'reservationType': reservationType,
      'targetId': targetId,
      'targetLabel': targetLabel,
      'operationKind': operationKind,
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

  factory ReservationOperationalFollowUpPromptPlan.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReservationOperationalFollowUpPromptPlan(
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      reservationId: json['reservationId'] as String? ?? '',
      reservationType: json['reservationType'] as String? ?? 'unknown',
      targetId: json['targetId'] as String? ?? '',
      targetLabel: json['targetLabel'] as String? ?? '',
      operationKind: json['operationKind'] as String? ?? 'reservation_update',
      occurredAtUtc:
          DateTime.tryParse(json['occurredAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      plannedAtUtc:
          DateTime.tryParse(json['plannedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceSurface: json['sourceSurface'] as String? ?? 'reservation',
      promptQuestion: json['promptQuestion'] as String? ?? '',
      promptRationale: json['promptRationale'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      channelHint: json['channelHint'] as String? ??
          'reservation_operational_reflection_follow_up',
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

class ReservationOperationalFollowUpPromptResponse {
  const ReservationOperationalFollowUpPromptResponse({
    required this.responseId,
    required this.planId,
    required this.ownerUserId,
    required this.reservationId,
    required this.reservationType,
    required this.targetId,
    required this.targetLabel,
    required this.operationKind,
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
  final String reservationId;
  final String reservationType;
  final String targetId;
  final String targetLabel;
  final String operationKind;
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
      'reservationId': reservationId,
      'reservationType': reservationType,
      'targetId': targetId,
      'targetLabel': targetLabel,
      'operationKind': operationKind,
      'respondedAtUtc': respondedAtUtc.toUtc().toIso8601String(),
      'responseText': responseText,
      'sourceSurface': sourceSurface,
      'completionMode': completionMode,
      'boundedContext': boundedContext,
      'signalTags': signalTags,
    };
  }

  factory ReservationOperationalFollowUpPromptResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReservationOperationalFollowUpPromptResponse(
      responseId: json['responseId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      reservationId: json['reservationId'] as String? ?? '',
      reservationType: json['reservationType'] as String? ?? 'unknown',
      targetId: json['targetId'] as String? ?? '',
      targetLabel: json['targetLabel'] as String? ?? '',
      operationKind: json['operationKind'] as String? ?? 'reservation_update',
      respondedAtUtc:
          DateTime.tryParse(json['respondedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      responseText: json['responseText'] as String? ?? '',
      sourceSurface: json['sourceSurface'] as String? ?? 'unknown',
      completionMode: json['completionMode'] as String? ??
          'reservation_in_app_follow_up_queue',
      boundedContext: Map<String, dynamic>.from(
        json['boundedContext'] as Map? ?? const <String, dynamic>{},
      ),
      signalTags: (json['signalTags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

class ReservationOperationalFollowUpPromptPlannerService {
  static const String _storageKeyPrefix =
      'bham:reservation_operational_follow_up_prompt_plans:v1:';
  static const String _responseStorageKeyPrefix =
      'bham:reservation_operational_follow_up_prompt_responses:v1:';

  ReservationOperationalFollowUpPromptPlannerService({
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

  Future<ReservationOperationalFollowUpPromptPlan> createSharingPlan({
    required String ownerUserId,
    required Reservation reservation,
    required String action,
    required DateTime occurredAtUtc,
    String? counterpartUserId,
    String? permission,
  }) {
    return _createPlan(
      ownerUserId: ownerUserId,
      reservation: reservation,
      operationKind:
          action == 'transfer' ? 'reservation_transfer' : 'reservation_share',
      occurredAtUtc: occurredAtUtc,
      sourceSurface: 'reservation_sharing',
      extraContext: <String, dynamic>{
        'counterpartUserId': counterpartUserId,
        'permission': permission,
      },
    );
  }

  Future<ReservationOperationalFollowUpPromptPlan> createCalendarSyncPlan({
    required String ownerUserId,
    required Reservation reservation,
    required DateTime occurredAtUtc,
    required String calendarEventId,
  }) {
    return _createPlan(
      ownerUserId: ownerUserId,
      reservation: reservation,
      operationKind: 'reservation_calendar_sync',
      occurredAtUtc: occurredAtUtc,
      sourceSurface: 'reservation_calendar',
      extraContext: <String, dynamic>{
        'calendarEventId': calendarEventId,
      },
    );
  }

  Future<ReservationOperationalFollowUpPromptPlan> createRecurrencePlan({
    required String ownerUserId,
    required Reservation reservation,
    required DateTime occurredAtUtc,
    required String recurrencePattern,
    required int createdInstanceCount,
  }) {
    return _createPlan(
      ownerUserId: ownerUserId,
      reservation: reservation,
      operationKind: 'reservation_recurrence',
      occurredAtUtc: occurredAtUtc,
      sourceSurface: 'reservation_recurrence',
      extraContext: <String, dynamic>{
        'recurrencePattern': recurrencePattern,
        'createdInstanceCount': createdInstanceCount,
      },
    );
  }

  Future<ReservationOperationalFollowUpPromptPlan> _createPlan({
    required String ownerUserId,
    required Reservation reservation,
    required String operationKind,
    required DateTime occurredAtUtc,
    required String sourceSurface,
    Map<String, dynamic> extraContext = const <String, dynamic>{},
  }) async {
    final existingPlans = await listPlans(ownerUserId);
    final sourceEventRef =
        'reservation_operation:${reservation.id}:$operationKind:${occurredAtUtc.toUtc().microsecondsSinceEpoch}';
    final existing = existingPlans.where(
      (plan) => plan.boundedContext['sourceEventRef'] == sourceEventRef,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final planTime = DateTime.now().toUtc();
    final nextEligibleAtUtc = _promptPolicyService.scheduleInitialEligibility(
      plannedAtUtc: planTime,
      alreadyPlannedToday: existingPlans
          .where((plan) => _isSameUtcDay(plan.plannedAtUtc, planTime))
          .length,
    );
    final domains = _extractDomains(
      reservation: reservation,
      operationKind: operationKind,
    );
    final suppression = await _suppressionMemoryService.activeSuppression(
      ownerUserId: ownerUserId,
      familyKey: 'reservation_operational_follow_up',
      targetKey: _suppressionTargetKey(
        reservationId: reservation.id,
        operationKind: operationKind,
      ),
    );
    final plan = ReservationOperationalFollowUpPromptPlan(
      planId:
          'reservation_follow_up_plan_${reservation.id}_${operationKind}_${planTime.millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      reservationId: reservation.id,
      reservationType: reservation.type.name,
      targetId: reservation.targetId,
      targetLabel: _targetLabel(reservation),
      operationKind: operationKind,
      occurredAtUtc: occurredAtUtc.toUtc(),
      plannedAtUtc: planTime,
      sourceSurface: sourceSurface,
      promptQuestion: _buildPromptQuestion(
        reservation: reservation,
        operationKind: operationKind,
      ),
      promptRationale: _buildPromptRationale(
        reservation: reservation,
        operationKind: operationKind,
      ),
      priority: _priorityForOperation(operationKind),
      channelHint: 'reservation_operational_reflection_follow_up',
      status: suppression == null
          ? 'planned_local_bounded_follow_up'
          : 'suppressed_local_bounded_follow_up',
      boundedContext: <String, dynamic>{
        'what': operationKind,
        'why': _whyLabel(operationKind, extraContext),
        'how': sourceSurface,
        'whenUtc': occurredAtUtc.toUtc().toIso8601String(),
        'who': ownerUserId,
        'reservationId': reservation.id,
        'reservationType': reservation.type.name,
        'targetId': reservation.targetId,
        'targetLabel': _targetLabel(reservation),
        'reservationTimeUtc':
            reservation.reservationTime.toUtc().toIso8601String(),
        'sourceEventRef': sourceEventRef,
        'nextEligibleAtUtc': nextEligibleAtUtc.toIso8601String(),
        'domains': domains,
        'suppressionTargetKey': _suppressionTargetKey(
          reservationId: reservation.id,
          operationKind: operationKind,
        ),
        ...extraContext,
        if (suppression != null)
          'suppressedUntilUtc': suppression.untilUtc?.toIso8601String(),
        if (suppression != null) 'suppressionReason': suppression.reason,
      },
      signalTags: <String>[
        'source:reservation_operational_follow_up_plan',
        'operation:$operationKind',
        'reservation_type:${reservation.type.name}',
        ...domains.map((domain) => 'domain:$domain'),
      ]..sort(),
    );
    await _storePlans(ownerUserId, <ReservationOperationalFollowUpPromptPlan>[
      plan,
      ...existingPlans,
    ]);
    return plan;
  }

  Future<List<ReservationOperationalFollowUpPromptPlan>> listPlans(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_storageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <ReservationOperationalFollowUpPromptPlan>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ReservationOperationalFollowUpPromptPlan>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => ReservationOperationalFollowUpPromptPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.plannedAtUtc.compareTo(a.plannedAtUtc));
    } catch (_) {
      return const <ReservationOperationalFollowUpPromptPlan>[];
    }
  }

  Future<List<ReservationOperationalFollowUpPromptPlan>> listRecentPlans({
    int limit = 12,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return const <ReservationOperationalFollowUpPromptPlan>[];
    }
    final plans = <ReservationOperationalFollowUpPromptPlan>[];
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

  Future<List<ReservationOperationalFollowUpPromptPlan>> listPendingPlans(
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
              plan.status != 'assistant_follow_up_offered' &&
              plan.status != 'completed_in_app_follow_up' &&
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
                  'reservation_operational_reflection_follow_up',
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
      familyKey: 'reservation_operational_follow_up',
      targetKey: _suppressionTargetKey(
        reservationId: plan.reservationId,
        operationKind: plan.operationKind,
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
      familyKey: 'reservation_operational_follow_up',
      targetKey: _suppressionTargetKey(
        reservationId: plan.reservationId,
        operationKind: plan.operationKind,
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

  Future<ReservationOperationalFollowUpPromptPlan?> activeAssistantFollowUpPlan(
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

  Future<ReservationOperationalFollowUpPromptResponse>
      completePlanWithResponse({
    required String ownerUserId,
    required String planId,
    required String responseText,
    required String sourceSurface,
  }) async {
    final trimmedResponse = responseText.trim();
    if (trimmedResponse.isEmpty) {
      throw StateError('A bounded reservation follow-up response is required.');
    }
    final plans = await listPlans(ownerUserId);
    final plan = plans.firstWhere(
      (candidate) => candidate.planId == planId,
      orElse: () => throw StateError('Unknown follow-up plan `$planId`.'),
    );
    final respondedAtUtc = DateTime.now().toUtc();
    final completionMode = sourceSurface == 'assistant_follow_up_chat'
        ? 'assistant_follow_up_chat'
        : 'reservation_in_app_follow_up_queue';
    final response = ReservationOperationalFollowUpPromptResponse(
      responseId:
          'reservation_follow_up_response_${respondedAtUtc.microsecondsSinceEpoch}',
      planId: plan.planId,
      ownerUserId: ownerUserId,
      reservationId: plan.reservationId,
      reservationType: plan.reservationType,
      targetId: plan.targetId,
      targetLabel: plan.targetLabel,
      operationKind: plan.operationKind,
      respondedAtUtc: respondedAtUtc,
      responseText: trimmedResponse,
      sourceSurface: sourceSurface,
      completionMode: completionMode,
      boundedContext: plan.boundedContext,
      signalTags: <String>[
        ...plan.signalTags,
        'prompt_response:completed',
        'completion_mode:$completionMode',
      ],
    );
    await _storeResponses(
        ownerUserId, <ReservationOperationalFollowUpPromptResponse>[
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

  Future<List<ReservationOperationalFollowUpPromptResponse>> listResponses(
    String ownerUserId,
  ) async {
    final raw = _prefs?.getString(_responseStorageKey(ownerUserId));
    if (raw == null || raw.isEmpty) {
      return const <ReservationOperationalFollowUpPromptResponse>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ReservationOperationalFollowUpPromptResponse>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => ReservationOperationalFollowUpPromptResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.respondedAtUtc.compareTo(a.respondedAtUtc));
    } catch (_) {
      return const <ReservationOperationalFollowUpPromptResponse>[];
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
      return ReservationOperationalFollowUpPromptPlan(
        planId: plan.planId,
        ownerUserId: plan.ownerUserId,
        reservationId: plan.reservationId,
        reservationType: plan.reservationType,
        targetId: plan.targetId,
        targetLabel: plan.targetLabel,
        operationKind: plan.operationKind,
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

  Future<void> _stageResponseBestEffort({
    required ReservationOperationalFollowUpPromptPlan plan,
    required ReservationOperationalFollowUpPromptResponse response,
  }) async {
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final airGapArtifact = _upwardAirGapService.issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'reservation_operational_follow_up_response_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'sourceKind': 'reservation_operational_follow_up_response_intake',
          'reservationId': plan.reservationId,
          'reservationType': plan.reservationType,
          'targetId': plan.targetId,
          'targetLabel': plan.targetLabel,
          'operationKind': plan.operationKind,
          'promptQuestion': plan.promptQuestion,
          'promptRationale': plan.promptRationale,
          'responseText': response.responseText,
          'completionMode': response.completionMode,
          'sourceSurface': response.sourceSurface,
          'boundedContext': response.boundedContext,
          'signalTags': response.signalTags,
        },
      );
      await service.stageReservationOperationalFollowUpResponseIntake(
        ownerUserId: response.ownerUserId,
        reservationId: plan.reservationId,
        reservationType: plan.reservationType,
        targetId: plan.targetId,
        targetLabel: plan.targetLabel,
        operationKind: plan.operationKind,
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
    List<ReservationOperationalFollowUpPromptPlan> plans,
  ) async {
    await _prefs?.setString(
      _storageKey(ownerUserId),
      jsonEncode(plans.map((plan) => plan.toJson()).toList(growable: false)),
    );
  }

  Future<void> _storeResponses(
    String ownerUserId,
    List<ReservationOperationalFollowUpPromptResponse> responses,
  ) async {
    await _prefs?.setString(
      _responseStorageKey(ownerUserId),
      jsonEncode(
        responses.map((response) => response.toJson()).toList(growable: false),
      ),
    );
  }

  String _storageKey(String ownerUserId) => '$_storageKeyPrefix$ownerUserId';
  String _responseStorageKey(String ownerUserId) =>
      '$_responseStorageKeyPrefix$ownerUserId';

  DateTime? _nextEligibleAtUtcFromPlan(
    ReservationOperationalFollowUpPromptPlan plan,
  ) {
    final value = plan.boundedContext['nextEligibleAtUtc']?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  String _suppressionTargetKey({
    required String reservationId,
    required String operationKind,
  }) {
    return 'reservation:$reservationId:$operationKind';
  }

  String _targetLabel(Reservation reservation) {
    return '${reservation.type.name}:${reservation.targetId}';
  }

  String _buildPromptQuestion({
    required Reservation reservation,
    required String operationKind,
  }) {
    switch (operationKind) {
      case 'reservation_share':
        return 'What about sharing this ${reservation.type.name} reservation should AVRAI remember before it broadens coordination learning?';
      case 'reservation_transfer':
        return 'What about transferring this ${reservation.type.name} reservation mattered most for future coordination or trust learning?';
      case 'reservation_calendar_sync':
        return 'What about syncing this ${reservation.type.name} reservation to your calendar mattered most for future timing guidance?';
      case 'reservation_recurrence':
        return 'What about making this ${reservation.type.name} reservation recurring should AVRAI remember before it broadens timing learning?';
      default:
        return 'What about this reservation action should AVRAI remember for future coordination learning?';
    }
  }

  String _buildPromptRationale({
    required Reservation reservation,
    required String operationKind,
  }) {
    switch (operationKind) {
      case 'reservation_share':
        return 'Sharing a reservation is a bounded coordination signal, but follow-up helps clarify whether the coordination mattered for trust, logistics, or future group planning.';
      case 'reservation_transfer':
        return 'Transfers change ownership and coordination assumptions. A bounded follow-up keeps that interpretation scoped before broader reservation learning.';
      case 'reservation_calendar_sync':
        return 'Calendar sync is a strong timing signal, but follow-up helps clarify whether the sync mattered for scheduling, reminders, or reservation fit.';
      case 'reservation_recurrence':
        return 'Recurring reservations can seed durable timing patterns. A bounded follow-up keeps that pattern grounded before it broadens into future recommendation or scheduling learning.';
      default:
        return 'Reservation operations can affect timing, coordination, and trust learning. A bounded follow-up keeps that interpretation scoped.';
    }
  }

  String _priorityForOperation(String operationKind) {
    switch (operationKind) {
      case 'reservation_transfer':
      case 'reservation_recurrence':
        return 'high';
      default:
        return 'medium';
    }
  }

  String _whyLabel(String operationKind, Map<String, dynamic> extraContext) {
    switch (operationKind) {
      case 'reservation_share':
        return 'share:${extraContext['permission'] ?? 'readOnly'}';
      case 'reservation_transfer':
        return 'transfer:${extraContext['counterpartUserId'] ?? 'new_owner'}';
      case 'reservation_calendar_sync':
        return 'calendar_sync:${extraContext['calendarEventId'] ?? 'linked'}';
      case 'reservation_recurrence':
        return 'recurrence:${extraContext['recurrencePattern'] ?? 'pattern'}';
      default:
        return operationKind;
    }
  }

  List<String> _extractDomains({
    required Reservation reservation,
    required String operationKind,
  }) {
    final domains = <String>{'reservation', 'timing'};
    switch (reservation.type) {
      case ReservationType.event:
        domains.addAll(const <String>['event', 'community']);
        break;
      case ReservationType.business:
        domains.addAll(const <String>['business', 'place']);
        break;
      case ReservationType.spot:
        domains.addAll(const <String>['place', 'locality']);
        break;
    }
    if (operationKind == 'reservation_share' ||
        operationKind == 'reservation_transfer') {
      domains.add('coordination');
    }
    return domains.toList()..sort();
  }

  List<String> _extractStringList(Object? value) {
    if (value is List) {
      return value
          .map((entry) => entry?.toString().trim() ?? '')
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  bool _isSameUtcDay(DateTime a, DateTime b) {
    final aUtc = a.toUtc();
    final bUtc = b.toUtc();
    return aUtc.year == bUtc.year &&
        aUtc.month == bUtc.month &&
        aUtc.day == bUtc.day;
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
