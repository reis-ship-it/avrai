import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_identity_redaction_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_internal_use_agreement_service.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_launch_gate_evaluator.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/device/device_capability_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/messaging/admin_support_chat_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_retention_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_learning_service.dart';
import 'package:avrai_runtime_os/services/messaging/direct_match_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class BhamAdminOperationsService {
  BhamAdminOperationsService({
    required AdminAuthService adminAuthService,
    required SharedPreferencesCompat prefs,
    AdminIdentityRedactionService? redactionService,
    DeviceCapabilityService? deviceCapabilityService,
    AdminSupportChatService? adminSupportChatService,
    DirectMatchService? directMatchService,
    BhamRouteLearningService? routeLearningService,
    BhamMessagingRetentionService? retentionService,
    CommunityService? communityService,
    ClubService? clubService,
    ExpertiseEventService? expertiseEventService,
    ListsRepository? listsRepository,
    SupabaseService? supabaseService,
    BhamExpansionGateEvaluator? launchGateEvaluator,
  })  : _adminAuthService = adminAuthService,
        _prefs = prefs,
        _redactionService =
            redactionService ?? const AdminIdentityRedactionService(),
        _deviceCapabilityService =
            deviceCapabilityService ?? DeviceCapabilityService(),
        _adminSupportChatService =
            adminSupportChatService ?? AdminSupportChatService(),
        _directMatchService = directMatchService ?? DirectMatchService(),
        _routeLearningService =
            routeLearningService ?? BhamRouteLearningService(),
        _retentionService = retentionService ?? BhamMessagingRetentionService(),
        _communityService = communityService ?? CommunityService(),
        _clubService = clubService ?? ClubService(),
        _expertiseEventService =
            expertiseEventService ?? ExpertiseEventService(),
        _listsRepository = listsRepository,
        _supabaseService = supabaseService ?? SupabaseService(),
        _launchGateEvaluator =
            launchGateEvaluator ?? const BhamExpansionGateEvaluator();

  static const String _moderationStore = 'bham_admin_moderation';
  static const String _breakGlassStore = 'bham_admin_break_glass';
  static const String _launchEvidenceStore = 'bham_launch_evidence';
  static const String _launchControlsStore = 'bham_launch_controls';

  final AdminAuthService _adminAuthService;
  final SharedPreferencesCompat _prefs;
  final AdminIdentityRedactionService _redactionService;
  final DeviceCapabilityService _deviceCapabilityService;
  final AdminSupportChatService _adminSupportChatService;
  final DirectMatchService _directMatchService;
  final BhamRouteLearningService _routeLearningService;
  final BhamMessagingRetentionService _retentionService;
  final CommunityService _communityService;
  final ClubService _clubService;
  final ExpertiseEventService _expertiseEventService;
  final ListsRepository? _listsRepository;
  final SupabaseService _supabaseService;
  final BhamExpansionGateEvaluator _launchGateEvaluator;

  Future<AdminHealthSnapshot> getHealthSnapshot({
    required Map<String, int> platformHealth,
  }) async {
    final deviceApproved = await _isDesktopDeviceApproved();
    final agreementService = AdminInternalUseAgreementService(
      prefs: _prefs,
      supabaseService: _supabaseService,
    );
    final agreementVerified =
        await agreementService.verifyCurrentSessionAgreement();
    final moderation = await listModerationQueue();
    final failures = await listDeliveryFailures();
    final feedback = await listBetaFeedbackInbox();
    final routeSummary = await summarizeRoutes();
    final routeHealth = routeSummary.isEmpty
        ? 0.0
        : routeSummary
                .map((item) => item.successRate)
                .reduce((left, right) => left + right) /
            routeSummary.length;

    final openBreakGlassCount =
        (await listBreakGlassGrants()).where((grant) => grant.active).length;

    return AdminHealthSnapshot(
      adminAvailable: _adminAuthService.isAuthenticated() &&
          agreementVerified &&
          deviceApproved,
      sessionValid: _adminAuthService.isAuthenticated(),
      deviceApproved: deviceApproved,
      internalUseAgreementVerified: agreementVerified,
      openBreakGlassCount: openBreakGlassCount,
      moderationQueueCount: moderation.length,
      quarantinedCount: moderation
          .where(
              (record) => record.state == CreationModerationState.quarantined)
          .length,
      failedDeliveryCount: failures.length,
      pendingFeedbackCount:
          feedback.where((item) => item.status.toLowerCase() == 'new').length,
      routeDeliveryHealth: routeHealth,
      platformHealth: platformHealth,
      deviceStatusLabel: deviceApproved
          ? 'Approved desktop admin device'
          : 'Admin device does not satisfy Wave 6 policy',
    );
  }

  Future<LaunchGateAdminMetrics> getLaunchGateMetrics({
    required Map<String, int> platformHealth,
  }) async {
    final health = await getHealthSnapshot(platformHealth: platformHealth);
    final decisions = await listGovernanceDecisions();
    return LaunchGateAdminMetrics(
      availability: health.adminAvailable,
      moderationQueueHealth: health.moderationQueueCount,
      quarantineCount: health.quarantinedCount,
      falsityResetCount: decisions
          .where((decision) => decision.resetDecision != ResetDecision.none)
          .length,
      breakGlassCount: health.openBreakGlassCount,
      routeDeliveryHealth: health.routeDeliveryHealth,
      platformHealth: platformHealth,
    );
  }

  Future<List<BhamManualEvidenceSlot>> listManualEvidenceSlots() async {
    final box = GetStorage(_launchEvidenceStore);
    final raw = box.read<List<dynamic>>('manual_evidence_slots_v1');
    final stored = raw == null
        ? <BhamManualEvidenceSlot>[]
        : raw
            .map(
              (entry) => BhamManualEvidenceSlot.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
    final byId = <String, BhamManualEvidenceSlot>{
      for (final slot in stored) slot.slotId: slot,
    };
    for (final slot in _defaultManualEvidenceSlots()) {
      byId.putIfAbsent(slot.slotId, () => slot);
    }
    final items = byId.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return items;
  }

  Future<void> upsertManualEvidenceSlot(BhamManualEvidenceSlot slot) async {
    final box = GetStorage(_launchEvidenceStore);
    final items = await listManualEvidenceSlots();
    final next = <BhamManualEvidenceSlot>[
      for (final item in items)
        if (item.slotId != slot.slotId) item,
      slot,
    ]..sort((a, b) => a.label.compareTo(b.label));
    await box.write(
      'manual_evidence_slots_v1',
      next.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> upsertFallbackOverride(BhamFallbackState state) async {
    final box = GetStorage(_launchControlsStore);
    final raw = box.read<List<dynamic>>('fallback_overrides_v1') ?? <dynamic>[];
    raw.removeWhere((entry) => (entry as Map)['area'] == state.area.name);
    raw.add(state.toJson());
    await box.write('fallback_overrides_v1', raw);
  }

  Future<List<BhamFallbackState>> listFallbackStates({
    required Map<String, int> platformHealth,
  }) async {
    final health = await getHealthSnapshot(platformHealth: platformHealth);
    final metrics = await getLaunchGateMetrics(platformHealth: platformHealth);
    final manualEvidence = await listManualEvidenceSlots();
    final evidence = await listGovernanceEvidence();
    final routeSummary = await summarizeRoutes();
    final now = DateTime.now().toUtc();

    BhamManualEvidenceSlot? slot(String id) {
      for (final item in manualEvidence) {
        if (item.slotId == id) {
          return item;
        }
      }
      return null;
    }

    final ai2aiSuccess = routeSummary.isEmpty
        ? null
        : routeSummary
                .map((item) => item.successRate)
                .reduce((left, right) => left + right) /
            routeSummary.length;
    final quarantinedCount = evidence
        .where((item) =>
            item.reason == QuarantineReason.maliciousPayload ||
            item.reason == QuarantineReason.safetyRisk)
        .length;
    final directUserRisk = evidence.any(
      (item) =>
          item.reason == QuarantineReason.directHumanReport &&
          (item.target.type == ModerationTargetType.user ||
              item.target.type == ModerationTargetType.agent),
    );

    final auto = <BhamFallbackState>[
      BhamFallbackState(
        area: BhamFallbackArea.adminObservability,
        status: health.adminAvailable
            ? BhamFallbackStatus.healthy
            : BhamFallbackStatus.blocked,
        reason: health.adminAvailable
            ? null
            : BhamPauseReason.adminObservabilityDegraded,
        summary: health.adminAvailable
            ? 'Admin observability is healthy.'
            : 'Admin observability is degraded. New learning should stay frozen until admin availability is restored.',
        updatedAtUtc: now,
        blocking: !health.adminAvailable,
        details: <String, dynamic>{
          'admin_available': health.adminAvailable,
          'session_valid': health.sessionValid,
          'device_approved': health.deviceApproved,
        },
      ),
      BhamFallbackState(
        area: BhamFallbackArea.ai2aiLocalExchange,
        status: ai2aiSuccess == null
            ? BhamFallbackStatus.manualReviewRequired
            : ai2aiSuccess >= 0.80
                ? BhamFallbackStatus.healthy
                : BhamFallbackStatus.paused,
        reason: ai2aiSuccess == null || ai2aiSuccess >= 0.80
            ? null
            : BhamPauseReason.ai2aiSystemFailure,
        summary: ai2aiSuccess == null
            ? 'AI2AI success-time evidence is missing. Manual review is required before launch.'
            : ai2aiSuccess >= 0.80
                ? 'AI2AI local exchange is within the Wave 7 success band.'
                : 'AI2AI local exchange is below the 80% success-time target and should remain paused for risky expansion behavior.',
        updatedAtUtc: now,
        blocking: ai2aiSuccess != null && ai2aiSuccess < 0.80,
        details: <String, dynamic>{
          'ai2ai_success_ratio': ai2aiSuccess,
        },
      ),
      BhamFallbackState(
        area: BhamFallbackArea.publicCreation,
        status: quarantinedCount >= 3
            ? BhamFallbackStatus.paused
            : quarantinedCount > 0
                ? BhamFallbackStatus.degraded
                : BhamFallbackStatus.healthy,
        reason:
            quarantinedCount > 0 ? BhamPauseReason.publicCreationAbuse : null,
        summary: quarantinedCount == 0
            ? 'Public creation moderation is within normal range.'
            : quarantinedCount >= 3
                ? 'Public creation should stay in quarantine/review mode until the active abuse cluster is resolved.'
                : 'Public creation is degraded and should be watched closely.',
        updatedAtUtc: now,
        blocking: quarantinedCount >= 3,
        details: <String, dynamic>{
          'quarantined_safety_records': quarantinedCount,
        },
      ),
      BhamFallbackState(
        area: BhamFallbackArea.localityLearning,
        status: metrics.falsityResetCount >= 2
            ? BhamFallbackStatus.paused
            : metrics.falsityResetCount > 0
                ? BhamFallbackStatus.degraded
                : BhamFallbackStatus.healthy,
        reason: metrics.falsityResetCount > 0
            ? BhamPauseReason.localityLearningUnstable
            : null,
        summary: metrics.falsityResetCount == 0
            ? 'Locality learning is stable.'
            : metrics.falsityResetCount >= 2
                ? 'Locality learning should remain paused until the falsity/reset issue is understood.'
                : 'Locality learning is degraded and needs monitoring.',
        updatedAtUtc: now,
        blocking: metrics.falsityResetCount >= 2,
        details: <String, dynamic>{
          'falsity_reset_count': metrics.falsityResetCount,
        },
      ),
      BhamFallbackState(
        area: BhamFallbackArea.directUserCompatibility,
        status: directUserRisk
            ? BhamFallbackStatus.paused
            : BhamFallbackStatus.healthy,
        reason:
            directUserRisk ? BhamPauseReason.directUserCompatibilityRisk : null,
        summary: directUserRisk
            ? 'Direct user compatibility should remain paused because a direct human report is active.'
            : 'Direct user compatibility remains within the BHAM double-opt-in boundary.',
        updatedAtUtc: now,
        blocking: directUserRisk,
      ),
      _manualFallbackState(
        area: BhamFallbackArea.onDeviceSlm,
        slot: slot('slm_fallback_validation'),
        now: now,
        healthySummary: 'On-device language fallback has been validated.',
        missingSummary:
            'On-device language fallback validation is missing and requires manual review.',
      ),
      _manualFallbackState(
        area: BhamFallbackArea.backgroundSensing,
        slot: slot('background_sensing_validation'),
        now: now,
        healthySummary: 'Background sensing validation is current.',
        missingSummary:
            'Background sensing validation is missing and requires manual review.',
      ),
      _manualFallbackState(
        area: BhamFallbackArea.offlineRecommendationQuality,
        slot: slot('offline_recommendation_quality'),
        now: now,
        healthySummary:
            'Offline recommendation quality evidence supports normal Daily Drop and Explore behavior.',
        missingSummary:
            'Offline recommendation quality evidence is missing. Riskier social recommendation behavior should stay suppressed.',
      ),
    ];

    final box = GetStorage(_launchControlsStore);
    final overridesRaw =
        box.read<List<dynamic>>('fallback_overrides_v1') ?? <dynamic>[];
    final overrides = overridesRaw
        .map(
          (entry) => BhamFallbackState.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
    final byArea = <BhamFallbackArea, BhamFallbackState>{
      for (final state in auto) state.area: state,
      for (final state in overrides) state.area: state,
    };
    return byArea.values.toList()
      ..sort((a, b) => a.area.name.compareTo(b.area.name));
  }

  Future<BhamLaunchEvidenceSnapshot> getLaunchEvidenceSnapshot({
    required Map<String, int> platformHealth,
  }) async {
    final health = await getHealthSnapshot(platformHealth: platformHealth);
    final metrics = await getLaunchGateMetrics(platformHealth: platformHealth);
    final manualEvidence = await listManualEvidenceSlots();
    final routeSummary = await summarizeRoutes();
    final evidence = await listGovernanceEvidence();
    final breakGlassAudit = await listBreakGlassAuditEvents();
    final directMatches = await listDirectMatchOutcomes();
    final ai2aiSuccess = routeSummary.isEmpty
        ? null
        : routeSummary
                .map((item) => item.successRate)
                .reduce((left, right) => left + right) /
            routeSummary.length *
            100.0;

    final quarantineReasons = <String, int>{};
    for (final item in evidence) {
      quarantineReasons.update(
        item.reason.name,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final directMatchSafe = directMatches.every(
      (result) => result.compatibilityScore >= 0.995,
    );

    final snapshot = BhamLaunchEvidenceSnapshot(
      generatedAtUtc: DateTime.now().toUtc(),
      adminAvailability: health.adminAvailable,
      offlineFirstCompletionRate:
          _manualEvidenceValue(manualEvidence, 'offline_first_completion'),
      ai2aiSuccessTimePercent: ai2aiSuccess,
      routeDeliveryHealth: metrics.routeDeliveryHealth,
      recommendationActionRate:
          _manualEvidenceValue(manualEvidence, 'recommendation_action_rate'),
      directMatchSafe: directMatchSafe,
      localityStability:
          _manualEvidenceValue(manualEvidence, 'locality_stability'),
      moderationQueueHealth: metrics.moderationQueueHealth,
      quarantineCount: metrics.quarantineCount,
      breakGlassCount: breakGlassAudit.length,
      platformHealth: platformHealth,
      quarantineReasons: quarantineReasons,
      manualEvidenceSlots: manualEvidence,
    );
    final box = GetStorage(_launchEvidenceStore);
    await box.write('latest_launch_evidence_v1', snapshot.toJson());
    return snapshot;
  }

  Future<List<BhamCriticalFlowCheckResult>> listCriticalFlowChecks({
    required Map<String, int> platformHealth,
  }) async {
    final health = await getHealthSnapshot(platformHealth: platformHealth);
    final manualEvidence = await listManualEvidenceSlots();
    final routes = await summarizeRoutes();

    BhamManualEvidenceSlot? slot(String id) {
      for (final item in manualEvidence) {
        if (item.slotId == id) {
          return item;
        }
      }
      return null;
    }

    BhamCriticalFlowCheckResult fromSlot({
      required String flowId,
      required String label,
      required String slotId,
      bool blocking = true,
    }) {
      final evidence = slot(slotId);
      if (evidence == null ||
          evidence.status == BhamManualEvidenceStatus.missing) {
        return BhamCriticalFlowCheckResult(
          flowId: flowId,
          label: label,
          status: BhamFlowCheckStatus.manualReviewRequired,
          evidenceSummary: 'Manual launch evidence is missing.',
          blocking: blocking,
          source: 'manual',
        );
      }
      if (evidence.status == BhamManualEvidenceStatus.stale) {
        return BhamCriticalFlowCheckResult(
          flowId: flowId,
          label: label,
          status: BhamFlowCheckStatus.blocked,
          evidenceSummary: 'Manual launch evidence is stale.',
          blocking: blocking,
          lastValidatedAtUtc: evidence.updatedAtUtc,
          source: 'manual',
        );
      }
      return BhamCriticalFlowCheckResult(
        flowId: flowId,
        label: label,
        status: BhamFlowCheckStatus.pass,
        evidenceSummary: evidence.summary ?? 'Manual launch evidence provided.',
        blocking: blocking,
        lastValidatedAtUtc: evidence.updatedAtUtc,
        source: 'manual',
      );
    }

    return <BhamCriticalFlowCheckResult>[
      fromSlot(
        flowId: 'approved_device_auth_bootstrap',
        label: 'Approved device auth and bootstrap restore/live bootstrap',
        slotId: 'approved_device_auth_bootstrap',
      ),
      fromSlot(
        flowId: 'onboarding_first_drop',
        label: 'BHAM onboarding through first 5-item Daily Drop',
        slotId: 'onboarding_first_drop',
      ),
      fromSlot(
        flowId: 'returning_user_daily_drop',
        label: 'Returning-user Daily Drop path',
        slotId: 'returning_user_daily_drop',
      ),
      fromSlot(
        flowId: 'daily_drop_feedback_loop',
        label: 'Daily Drop save/dismiss/why/meaningful/fun loop',
        slotId: 'daily_drop_feedback_loop',
      ),
      fromSlot(
        flowId: 'explore_five_type',
        label: 'Explore across spot/list/event/club/community',
        slotId: 'explore_five_type',
      ),
      fromSlot(
        flowId: 'offline_create_sync',
        label: 'Offline-first creation and later sync for all 5 object types',
        slotId: 'offline_create_sync',
      ),
      fromSlot(
        flowId: 'personal_ai_chat',
        label: 'Personal AI chat',
        slotId: 'personal_ai_chat',
      ),
      fromSlot(
        flowId: 'admin_support_chat',
        label: 'Admin support chat',
        slotId: 'admin_support_chat',
      ),
      fromSlot(
        flowId: 'group_chat_threads',
        label: 'Event/community/club chat',
        slotId: 'group_chat_threads',
      ),
      fromSlot(
        flowId: 'direct_match_double_opt_in',
        label: 'Direct match double opt-in only',
        slotId: 'direct_match_double_opt_in',
      ),
      BhamCriticalFlowCheckResult(
        flowId: 'route_planning_receipts',
        label: 'Route planning, winning-route receipts, duplicate suppression',
        status: routes.isEmpty
            ? BhamFlowCheckStatus.manualReviewRequired
            : BhamFlowCheckStatus.pass,
        evidenceSummary: routes.isEmpty
            ? 'No route-learning evidence recorded yet.'
            : 'Route-learning evidence exists across ${routes.length} transport modes.',
        blocking: true,
        source: routes.isEmpty ? 'automatic' : 'automatic',
      ),
      BhamCriticalFlowCheckResult(
        flowId: 'admin_wave6_surfaces',
        label:
            'Admin command center, communications, moderation, explorer, beta feedback, and launch safety screens',
        status: health.adminAvailable
            ? BhamFlowCheckStatus.pass
            : BhamFlowCheckStatus.blocked,
        evidenceSummary: health.adminAvailable
            ? 'Admin surfaces are available under the current device/session policy.'
            : 'Admin surfaces are blocked because the admin availability gate is failing.',
        blocking: true,
        source: 'automatic',
      ),
      fromSlot(
        flowId: 'governance_breakglass',
        label:
            'Quarantine, falsity/reset, moderation transitions, and break-glass audit flow',
        slotId: 'governance_breakglass',
      ),
    ];
  }

  Future<BhamLaunchGateReport> buildLaunchGateReport({
    required Map<String, int> platformHealth,
  }) async {
    final evidence = await getLaunchEvidenceSnapshot(
      platformHealth: platformHealth,
    );
    final fallbacks = await listFallbackStates(platformHealth: platformHealth);
    final flows = await listCriticalFlowChecks(platformHealth: platformHealth);
    final report = _launchGateEvaluator.evaluate(
      evidenceSnapshot: evidence,
      fallbackStates: fallbacks,
      criticalFlowChecks: flows,
      manualEvidenceSlots: evidence.manualEvidenceSlots,
    );
    final box = GetStorage(_launchControlsStore);
    await box.write('latest_launch_gate_report_v1', report.toJson());
    return report;
  }

  Future<File> exportLaunchSnapshot({
    required Map<String, int> platformHealth,
    String outputPath = 'runtime_exports/bham_launch_snapshot.json',
  }) async {
    final report = await buildLaunchGateReport(platformHealth: platformHealth);
    final file = File(outputPath);
    await file.create(recursive: true);
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
    );
    return file;
  }

  Future<List<AdminCommunicationReadModel>> listCommunicationSummaries() async {
    final items = <AdminCommunicationReadModel>[
      ...await _listAdminSupportSummaries(),
      ...await _listEventThreadSummaries(),
    ];
    items.sort((a, b) => b.lastActivityAtUtc.compareTo(a.lastActivityAtUtc));
    return items;
  }

  Future<List<AdminDeliveryFailureReadModel>> listDeliveryFailures() async {
    final failures = <AdminDeliveryFailureReadModel>[];
    final routeSignals = await _routeLearningService.getSignals();
    for (final signal in routeSignals.where((signal) => !signal.success)) {
      failures.add(
        AdminDeliveryFailureReadModel(
          messageId: signal.messageId,
          threadId: signal.metadata['thread_id'] as String? ?? 'unknown_thread',
          reason:
              signal.metadata['failure_reason'] as String? ?? 'Route failed',
          recordedAtUtc: signal.observedAtUtc,
        ),
      );
    }

    final outbox = GetStorage('friend_chat_outbox');
    final pending = outbox.read<List<dynamic>>('outbox_pending') ?? <dynamic>[];
    for (final entry in pending) {
      final map = Map<String, dynamic>.from(entry as Map);
      failures.add(
        AdminDeliveryFailureReadModel(
          messageId: map['message_id'] as String? ?? 'queued_retry',
          threadId: map['chat_id'] as String? ?? 'friend_chat',
          reason: 'Queued for retry / awaiting route winner',
          recordedAtUtc: DateTime.now().toUtc(),
        ),
      );
    }

    failures.sort((a, b) => b.recordedAtUtc.compareTo(a.recordedAtUtc));
    return failures;
  }

  Future<List<RouteDeliverySummary>> summarizeRoutes() async {
    final signals = await _routeLearningService.getSignals();
    final byMode = <TransportMode, List<RouteLearningSignal>>{};
    for (final signal in signals) {
      byMode
          .putIfAbsent(signal.mode, () => <RouteLearningSignal>[])
          .add(signal);
    }
    return byMode.entries.map((entry) {
      final attempts = entry.value.length;
      final successes = entry.value.where((signal) => signal.success).length;
      final latencies = entry.value
          .map((signal) => signal.latencyMs)
          .whereType<int>()
          .toList();
      final avg = latencies.isEmpty
          ? null
          : (latencies.reduce((left, right) => left + right) ~/
              latencies.length);
      return RouteDeliverySummary(
        mode: entry.key,
        attempts: attempts,
        successes: successes,
        averageLatencyMs: avg,
      );
    }).toList()
      ..sort((a, b) => b.attempts.compareTo(a.attempts));
  }

  Future<List<DirectMatchOutcomeView>> listDirectMatchOutcomes() async {
    final results = await _directMatchService.listAllResults();
    return results.map((result) {
      return DirectMatchOutcomeView(
        invitationId: result.invitation.invitationId,
        participantA: _redactionService.redactActor(result.invitation.userAId),
        participantB: _redactionService.redactActor(result.invitation.userBId),
        compatibilityScore: result.invitation.compatibilityScore,
        createdAtUtc: result.invitation.createdAtUtc,
        chatOpened: result.chatOpened,
        declineMessage: result.declineMessage == null
            ? null
            : _redactionService.redactText(result.declineMessage!),
      );
    }).toList()
      ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
  }

  Future<List<AdminFeedbackInboxItem>> listBetaFeedbackInbox() async {
    try {
      if (!_supabaseService.isAvailable) {
        return const <AdminFeedbackInboxItem>[];
      }
      final response = await _supabaseService.client
          .from('beta_feedback')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      final list = List<Map<String, dynamic>>.from(response);
      return list.map((row) {
        final userId = row['user_id'] as String? ?? 'anonymous_feedback';
        return AdminFeedbackInboxItem(
          id: row['id']?.toString() ?? 'feedback_unknown',
          kind: row['type'] as String? ?? 'feedback',
          content:
              _redactionService.redactText(row['content'] as String? ?? ''),
          status: row['status'] as String? ?? 'new',
          createdAtUtc:
              DateTime.tryParse(row['created_at'] as String? ?? '')?.toUtc() ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          user: _redactionService.redactActor(userId),
        );
      }).toList();
    } catch (_) {
      return const <AdminFeedbackInboxItem>[];
    }
  }

  Future<List<AdminExplorerItem>> listCreationExplorer() async {
    final explorer = <AdminExplorerItem>[];
    final moderation = await listModerationQueue();
    final stateByKey = <String, CreationModerationState>{
      for (final record in moderation)
        '${record.target.type.name}:${record.target.id}': record.state,
    };

    final lists = _listsRepository == null
        ? const <SpotList>[]
        : await _listsRepository.getPublicLists();
    for (final list in lists.take(40)) {
      explorer.add(
        AdminExplorerItem(
          entity: DiscoveryEntityReference(
            type: DiscoveryEntityType.list,
            id: list.id,
            title: list.title,
            routePath: '/list/${list.id}',
            localityLabel: list.category,
          ),
          title: list.title,
          subtitle: '${list.spots.length} spots',
          createdAtUtc: list.updatedAt.toUtc(),
          moderationState:
              stateByKey['list:${list.id}'] ?? CreationModerationState.active,
        ),
      );
    }

    final clubs = await _clubService.getAllClubs();
    for (final club in clubs.take(40)) {
      explorer.add(
        AdminExplorerItem(
          entity: DiscoveryEntityReference(
            type: DiscoveryEntityType.club,
            id: club.id,
            title: club.name,
            routePath: '/club/${club.id}',
            localityLabel: club.localityCode ?? club.cityCode,
          ),
          title: club.name,
          subtitle: club.category,
          createdAtUtc: club.updatedAt.toUtc(),
          moderationState:
              stateByKey['club:${club.id}'] ?? CreationModerationState.active,
        ),
      );
    }

    final communities = await _communityService.getAllCommunities();
    for (final community in communities.take(40)) {
      explorer.add(
        AdminExplorerItem(
          entity: DiscoveryEntityReference(
            type: DiscoveryEntityType.community,
            id: community.id,
            title: community.name,
            routePath: '/community/${community.id}',
            localityLabel: community.localityCode ?? community.cityCode,
          ),
          title: community.name,
          subtitle: community.category,
          createdAtUtc: community.updatedAt.toUtc(),
          moderationState: stateByKey['community:${community.id}'] ??
              CreationModerationState.active,
        ),
      );
    }

    final events = await _loadEvents();
    for (final event in events.take(40)) {
      explorer.add(
        AdminExplorerItem(
          entity: DiscoveryEntityReference(
            type: DiscoveryEntityType.event,
            id: event.id,
            title: event.title,
            routePath: '/event/${event.id}',
            localityLabel: event.location,
          ),
          title: event.title,
          subtitle: event.category,
          createdAtUtc: event.updatedAt.toUtc(),
          moderationState:
              stateByKey['event:${event.id}'] ?? CreationModerationState.active,
        ),
      );
    }

    explorer.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return explorer;
  }

  Future<AdminModerationRecord> applyModerationAction({
    required ModerationTargetRef target,
    required ModerationAction action,
    required String actorId,
    required String reason,
    QuarantineReason? evidenceReason,
  }) async {
    final evidence = evidenceReason == null
        ? const <GovernanceEvidence>[]
        : <GovernanceEvidence>[
            await recordEvidence(
              target: target,
              reason: evidenceReason,
              summary: reason,
              source: 'admin_action',
              confidence: 0.92,
            ),
          ];
    final record = AdminModerationRecord(
      recordId: '${target.type.name}:${target.id}',
      target: target,
      state: _stateForAction(action),
      lastAction: action,
      updatedAtUtc: DateTime.now().toUtc(),
      reason: reason,
      evidence: evidence,
      pendingCreatorExplanation: action == ModerationAction.pause ||
          action == ModerationAction.quarantine,
    );
    final box = GetStorage(_moderationStore);
    final raw = box.read<List<dynamic>>('moderation_records_v1') ?? <dynamic>[];
    raw.removeWhere((entry) => (entry as Map)['record_id'] == record.recordId);
    raw.add(_moderationRecordToJson(record));
    await box.write('moderation_records_v1', raw);

    final decisions =
        box.read<List<dynamic>>('governance_decisions_v1') ?? <dynamic>[];
    decisions.add(
      _governanceDecisionToJson(
        GovernanceDecision(
          decisionId: const Uuid().v4(),
          target: target,
          action: action,
          quarantineState: _quarantineStateForAction(action),
          decidedAtUtc: DateTime.now().toUtc(),
          actorId: actorId,
          reason: reason,
          evidenceIds: evidence.map((item) => item.evidenceId).toList(),
          resetDecision: action == ModerationAction.rollback
              ? ResetDecision.rollback
              : action == ModerationAction.reset
                  ? ResetDecision.resetAgent
                  : ResetDecision.none,
        ),
      ),
    );
    await box.write('governance_decisions_v1', decisions);
    return record;
  }

  Future<List<AdminModerationRecord>> listModerationQueue() async {
    final box = GetStorage(_moderationStore);
    final raw = box.read<List<dynamic>>('moderation_records_v1') ?? <dynamic>[];
    return raw
        .map((entry) =>
            _moderationRecordFromJson(Map<String, dynamic>.from(entry as Map)))
        .toList()
      ..sort((a, b) => b.updatedAtUtc.compareTo(a.updatedAtUtc));
  }

  Future<GovernanceEvidence> recordEvidence({
    required ModerationTargetRef target,
    required QuarantineReason reason,
    required String summary,
    required String source,
    double confidence = 0.5,
  }) async {
    final evidence = GovernanceEvidence(
      evidenceId: const Uuid().v4(),
      target: target,
      reason: reason,
      summary: _redactionService.redactText(summary),
      recordedAtUtc: DateTime.now().toUtc(),
      source: source,
      confidence: confidence,
    );
    final box = GetStorage(_moderationStore);
    final raw =
        box.read<List<dynamic>>('governance_evidence_v1') ?? <dynamic>[];
    raw.add(_evidenceToJson(evidence));
    await box.write('governance_evidence_v1', raw);
    return evidence;
  }

  Future<List<GovernanceEvidence>> listGovernanceEvidence() async {
    final box = GetStorage(_moderationStore);
    final raw =
        box.read<List<dynamic>>('governance_evidence_v1') ?? <dynamic>[];
    return raw
        .map((entry) =>
            _evidenceFromJson(Map<String, dynamic>.from(entry as Map)))
        .toList()
      ..sort((a, b) => b.recordedAtUtc.compareTo(a.recordedAtUtc));
  }

  Future<List<GovernanceDecision>> listGovernanceDecisions() async {
    final box = GetStorage(_moderationStore);
    final raw =
        box.read<List<dynamic>>('governance_decisions_v1') ?? <dynamic>[];
    return raw
        .map((entry) => _governanceDecisionFromJson(
            Map<String, dynamic>.from(entry as Map)))
        .toList()
      ..sort((a, b) => b.decidedAtUtc.compareTo(a.decidedAtUtc));
  }

  Future<BreakGlassGrant> startBreakGlass({
    required String reasonCode,
    required String justification,
    required List<String> targetIds,
    List<String> identityFields = const <String>[
      'user_id',
      'linked_identity',
    ],
    Duration duration = const Duration(hours: 2),
  }) async {
    final session = _adminAuthService.getCurrentSession();
    if (session == null) {
      throw StateError('Human admin session required for break-glass.');
    }
    final now = DateTime.now().toUtc();
    final request = BreakGlassRequest(
      requestId: const Uuid().v4(),
      actorId: session.username,
      reasonCode: reasonCode,
      justification: justification,
      createdAtUtc: now,
      scope: BreakGlassScope(
        targetIds: targetIds,
        identityFields: identityFields,
        expiresAtUtc: now.add(duration),
      ),
    );
    final grant = BreakGlassGrant(
      grantId: const Uuid().v4(),
      request: request,
      approverId: session.username,
      startedAtUtc: now,
      expiresAtUtc: now.add(duration),
    );
    final box = GetStorage(_breakGlassStore);
    final requests =
        box.read<List<dynamic>>('break_glass_requests_v1') ?? <dynamic>[];
    final grants =
        box.read<List<dynamic>>('break_glass_grants_v1') ?? <dynamic>[];
    requests.add(_breakGlassRequestToJson(request));
    grants.add(_breakGlassGrantToJson(grant));
    await box.write('break_glass_requests_v1', requests);
    await box.write('break_glass_grants_v1', grants);
    await _recordBreakGlassAudit(
      grantId: grant.grantId,
      actorId: session.username,
      eventType: BreakGlassAuditEventType.requested,
      details: <String, dynamic>{'reason_code': reasonCode},
    );
    await _recordBreakGlassAudit(
      grantId: grant.grantId,
      actorId: session.username,
      eventType: BreakGlassAuditEventType.approved,
      details: <String, dynamic>{'scope_targets': targetIds.length},
    );
    return grant;
  }

  Future<void> closeBreakGlass({
    required String grantId,
    required String actorId,
  }) async {
    final grants = await listBreakGlassGrants();
    final updated = grants.map((grant) {
      if (grant.grantId != grantId) {
        return grant;
      }
      return BreakGlassGrant(
        grantId: grant.grantId,
        request: grant.request,
        approverId: grant.approverId,
        startedAtUtc: grant.startedAtUtc,
        expiresAtUtc: grant.expiresAtUtc,
        active: false,
      );
    }).toList();
    final box = GetStorage(_breakGlassStore);
    await box.write(
      'break_glass_grants_v1',
      updated.map(_breakGlassGrantToJson).toList(),
    );
    await _recordBreakGlassAudit(
      grantId: grantId,
      actorId: actorId,
      eventType: BreakGlassAuditEventType.closed,
      details: const <String, dynamic>{},
    );
  }

  Future<List<BreakGlassGrant>> listBreakGlassGrants() async {
    final box = GetStorage(_breakGlassStore);
    final raw = box.read<List<dynamic>>('break_glass_grants_v1') ?? <dynamic>[];
    return raw
        .map((entry) =>
            _breakGlassGrantFromJson(Map<String, dynamic>.from(entry as Map)))
        .toList()
      ..sort((a, b) => b.startedAtUtc.compareTo(a.startedAtUtc));
  }

  Future<List<BreakGlassAuditEvent>> listBreakGlassAuditEvents() async {
    final box = GetStorage(_breakGlassStore);
    final raw = box.read<List<dynamic>>('break_glass_audit_v1') ?? <dynamic>[];
    return raw
        .map((entry) => _breakGlassAuditEventFromJson(
            Map<String, dynamic>.from(entry as Map)))
        .toList()
      ..sort((a, b) => b.recordedAtUtc.compareTo(a.recordedAtUtc));
  }

  Future<List<AdminCommunicationReadModel>> _listAdminSupportSummaries() async {
    final box = GetStorage('bham_admin_support_chat');
    final items = <AdminCommunicationReadModel>[];
    for (final key in box.getKeys().cast<String>()) {
      if (!key.startsWith('admin_support:')) {
        continue;
      }
      final userId = key.substring('admin_support:'.length);
      final history =
          await _adminSupportChatService.getConversationHistory(userId);
      if (history.isEmpty) {
        continue;
      }
      final last = history.last;
      if (_retentionService.isExpired(
        kind: ChatThreadKind.admin,
        lastActivityAtUtc: last.createdAtUtc,
      )) {
        continue;
      }
      items.add(
        AdminCommunicationReadModel(
          threadId: key,
          threadKind: ChatThreadKind.admin,
          displayTitle:
              'Admin support ${_redactionService.redactActor(userId).displayLabel}',
          messageCount: history.length,
          lastActivityAtUtc: last.createdAtUtc,
          lastMessagePreview: _redactionService.redactText(last.body),
          participants: <AdminRedactedView>[
            _redactionService.redactActor(userId),
          ],
          routeReceipt: last.routeReceipt,
          quarantined: last.routeReceipt?.quarantined ?? false,
        ),
      );
    }
    return items;
  }

  Future<List<AdminCommunicationReadModel>> _listEventThreadSummaries() async {
    final box = GetStorage('bham_event_chat');
    final items = <AdminCommunicationReadModel>[];
    for (final key in box.getKeys().cast<String>()) {
      final raw = box.read<List<dynamic>>(key) ?? <dynamic>[];
      final history = raw
          .map((entry) => BhamThreadMessage.fromJson(
              Map<String, dynamic>.from(entry as Map)))
          .toList()
        ..sort((a, b) => a.createdAtUtc.compareTo(b.createdAtUtc));
      if (history.isEmpty) {
        continue;
      }
      final last = history.last;
      if (_retentionService.isExpired(
        kind: last.threadKind,
        lastActivityAtUtc: last.createdAtUtc,
        pinned: last.pinned,
      )) {
        continue;
      }
      items.add(
        AdminCommunicationReadModel(
          threadId: key,
          threadKind: last.threadKind,
          displayTitle: key.startsWith('announcement:')
              ? 'Announcement ${key.split(':').last}'
              : 'Event ${key.split(':').last}',
          messageCount: history.length,
          lastActivityAtUtc: last.createdAtUtc,
          lastMessagePreview: _redactionService.redactText(last.body),
          participants: history
              .map((entry) => _redactionService.redactActor(entry.senderId))
              .toSet()
              .toList(),
          routeReceipt: last.routeReceipt,
          quarantined: last.routeReceipt?.quarantined ?? false,
        ),
      );
    }
    return items;
  }

  Future<bool> _isDesktopDeviceApproved() async {
    final caps = await _deviceCapabilityService.getCapabilities();
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      _ => caps.platform,
    };
    if (platform != 'macos' && platform != 'windows' && platform != 'linux') {
      return false;
    }
    if (caps.isLowPowerMode) {
      return false;
    }
    if (caps.totalRamMb != null && caps.totalRamMb! < 4096) {
      return false;
    }
    return true;
  }

  Future<List<ExpertiseEvent>> _loadEvents() async {
    final events = await _expertiseEventService.searchEvents(
      maxResults: 40,
      includeCommunityEvents: true,
    );
    return events;
  }

  BhamFallbackState _manualFallbackState({
    required BhamFallbackArea area,
    required BhamManualEvidenceSlot? slot,
    required DateTime now,
    required String healthySummary,
    required String missingSummary,
  }) {
    if (slot == null || slot.status == BhamManualEvidenceStatus.missing) {
      return BhamFallbackState(
        area: area,
        status: BhamFallbackStatus.manualReviewRequired,
        reason: BhamPauseReason.manualEvidenceMissing,
        summary: missingSummary,
        updatedAtUtc: now,
        source: 'manual',
      );
    }
    if (slot.status == BhamManualEvidenceStatus.stale) {
      return BhamFallbackState(
        area: area,
        status: BhamFallbackStatus.blocked,
        reason: BhamPauseReason.launchValidationMissing,
        summary: '${slot.label} is stale and must be refreshed before launch.',
        updatedAtUtc: slot.updatedAtUtc ?? now,
        blocking: true,
        source: 'manual',
      );
    }
    return BhamFallbackState(
      area: area,
      status: BhamFallbackStatus.healthy,
      summary: slot.summary ?? healthySummary,
      updatedAtUtc: slot.updatedAtUtc ?? now,
      source: 'manual',
      details: slot.value == null
          ? const <String, dynamic>{}
          : <String, dynamic>{
              'value': slot.value,
              if (slot.unit != null) 'unit': slot.unit,
            },
    );
  }

  double? _manualEvidenceValue(
    List<BhamManualEvidenceSlot> slots,
    String slotId,
  ) {
    for (final slot in slots) {
      if (slot.slotId == slotId &&
          slot.status == BhamManualEvidenceStatus.provided) {
        return slot.value;
      }
    }
    return null;
  }

  List<BhamManualEvidenceSlot> _defaultManualEvidenceSlots() =>
      const <BhamManualEvidenceSlot>[
        BhamManualEvidenceSlot(
          slotId: 'approved_device_auth_bootstrap',
          label: 'Approved-device auth and bootstrap validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'onboarding_first_drop',
          label: 'Onboarding through first Daily Drop validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'returning_user_daily_drop',
          label: 'Returning-user Daily Drop validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'daily_drop_feedback_loop',
          label: 'Daily Drop recommendation-action validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'explore_five_type',
          label: 'Explore five-type validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'offline_create_sync',
          label: 'Offline create and later sync validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'personal_ai_chat',
          label: 'Personal AI chat validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'admin_support_chat',
          label: 'Admin support chat validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'group_chat_threads',
          label: 'Event, community, and club chat validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'direct_match_double_opt_in',
          label: 'Direct-match double-opt-in validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'governance_breakglass',
          label: 'Governance, quarantine, and break-glass validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'offline_first_completion',
          label: 'Offline-first completion evidence',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
          unit: '%',
        ),
        BhamManualEvidenceSlot(
          slotId: 'recommendation_action_rate',
          label: 'Recommendation action-rate evidence',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
          unit: '%',
        ),
        BhamManualEvidenceSlot(
          slotId: 'locality_stability',
          label: 'Locality stability evidence',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
          unit: '%',
        ),
        BhamManualEvidenceSlot(
          slotId: 'slm_fallback_validation',
          label: 'On-device language fallback validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'background_sensing_validation',
          label: 'Background sensing validation',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'offline_recommendation_quality',
          label: 'Offline recommendation quality evidence',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'full_monorepo_validation',
          label: 'Full monorepo validation signoff',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'heavy_integration_suite',
          label: 'BHAM heavy consumer suite signoff',
          status: BhamManualEvidenceStatus.missing,
          requiredForLaunch: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'sev1_free_14d',
          label: 'No Sev-1 incidents for 14 days',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'zero_harmful_suggestions',
          label: 'Zero harmful or trust-breaking suggestions',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'recommendation_action_band',
          label: 'Recommendation action band and weekly engagement',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'personal_agent_coherence_80',
          label: 'Personal agent coherence at 80%',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'birmingham_locality_correct_14d',
          label: 'Birmingham locality correctness for 14 days',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'admin_views_continuous_14d',
          label: 'Admin views healthy for 14 days',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'flagged_queue_under_24h',
          label: 'Flagged queue under 24 hours for 14 days',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'weekly_use_intent_70',
          label: '70% weekly keep-using intent',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'helps_find_better_60',
          label: '60% say AVRAI helps find better places/people/events',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
        BhamManualEvidenceSlot(
          slotId: 'meaningful_offline_flow_80',
          label: '80% complete a meaningful offline-first flow',
          status: BhamManualEvidenceStatus.missing,
          requiredForExpansion: true,
        ),
      ];

  Future<void> _recordBreakGlassAudit({
    required String grantId,
    required String actorId,
    required BreakGlassAuditEventType eventType,
    required Map<String, dynamic> details,
  }) async {
    final box = GetStorage(_breakGlassStore);
    final raw = box.read<List<dynamic>>('break_glass_audit_v1') ?? <dynamic>[];
    raw.add(
      _breakGlassAuditEventToJson(
        BreakGlassAuditEvent(
          auditId: const Uuid().v4(),
          grantId: grantId,
          eventType: eventType,
          actorId: actorId,
          recordedAtUtc: DateTime.now().toUtc(),
          details: details,
        ),
      ),
    );
    await box.write('break_glass_audit_v1', raw);
  }

  CreationModerationState _stateForAction(ModerationAction action) {
    switch (action) {
      case ModerationAction.flag:
        return CreationModerationState.flagged;
      case ModerationAction.pause:
        return CreationModerationState.paused;
      case ModerationAction.quarantine:
      case ModerationAction.rollback:
      case ModerationAction.reset:
        return CreationModerationState.quarantined;
      case ModerationAction.remove:
        return CreationModerationState.removed;
      case ModerationAction.restore:
        return CreationModerationState.active;
    }
  }

  QuarantineState _quarantineStateForAction(ModerationAction action) {
    switch (action) {
      case ModerationAction.flag:
        return QuarantineState.none;
      case ModerationAction.pause:
        return QuarantineState.active;
      case ModerationAction.quarantine:
        return QuarantineState.active;
      case ModerationAction.remove:
        return QuarantineState.active;
      case ModerationAction.restore:
        return QuarantineState.released;
      case ModerationAction.rollback:
        return QuarantineState.rolledBack;
      case ModerationAction.reset:
        return QuarantineState.reset;
    }
  }

  Map<String, dynamic> _targetToJson(ModerationTargetRef target) =>
      <String, dynamic>{
        'type': target.type.name,
        'id': target.id,
        'title': target.title,
        'locality_label': target.localityLabel,
        'owner_ref': target.ownerRef,
      };

  ModerationTargetRef _targetFromJson(Map<String, dynamic> json) =>
      ModerationTargetRef(
        type: ModerationTargetType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => ModerationTargetType.community,
        ),
        id: json['id'] as String? ?? 'unknown_target',
        title: json['title'] as String? ?? 'Unknown target',
        localityLabel: json['locality_label'] as String?,
        ownerRef: json['owner_ref'] as String?,
      );

  Map<String, dynamic> _evidenceToJson(GovernanceEvidence evidence) =>
      <String, dynamic>{
        'evidence_id': evidence.evidenceId,
        'target': _targetToJson(evidence.target),
        'reason': evidence.reason.name,
        'summary': evidence.summary,
        'recorded_at_utc': evidence.recordedAtUtc.toIso8601String(),
        'source': evidence.source,
        'confidence': evidence.confidence,
        'metadata': evidence.metadata,
      };

  GovernanceEvidence _evidenceFromJson(Map<String, dynamic> json) =>
      GovernanceEvidence(
        evidenceId: json['evidence_id'] as String? ?? 'unknown_evidence',
        target: _targetFromJson(
          Map<String, dynamic>.from(json['target'] as Map? ?? const {}),
        ),
        reason: QuarantineReason.values.firstWhere(
          (value) => value.name == json['reason'],
          orElse: () => QuarantineReason.directHumanReport,
        ),
        summary: json['summary'] as String? ?? '',
        recordedAtUtc:
            DateTime.tryParse(json['recorded_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        source: json['source'] as String? ?? 'unknown',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
        metadata: Map<String, dynamic>.from(
          json['metadata'] as Map? ?? const <String, dynamic>{},
        ),
      );

  Map<String, dynamic> _moderationRecordToJson(AdminModerationRecord record) =>
      <String, dynamic>{
        'record_id': record.recordId,
        'target': _targetToJson(record.target),
        'state': record.state.name,
        'last_action': record.lastAction.name,
        'updated_at_utc': record.updatedAtUtc.toIso8601String(),
        'reason': record.reason,
        'evidence': record.evidence.map(_evidenceToJson).toList(),
        'pending_creator_explanation': record.pendingCreatorExplanation,
      };

  AdminModerationRecord _moderationRecordFromJson(Map<String, dynamic> json) =>
      AdminModerationRecord(
        recordId: json['record_id'] as String? ?? 'unknown_record',
        target: _targetFromJson(
          Map<String, dynamic>.from(json['target'] as Map? ?? const {}),
        ),
        state: CreationModerationState.values.firstWhere(
          (value) => value.name == json['state'],
          orElse: () => CreationModerationState.active,
        ),
        lastAction: ModerationAction.values.firstWhere(
          (value) => value.name == json['last_action'],
          orElse: () => ModerationAction.flag,
        ),
        updatedAtUtc: DateTime.tryParse(json['updated_at_utc'] as String? ?? '')
                ?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        reason: json['reason'] as String?,
        evidence: ((json['evidence'] as List?) ?? const <dynamic>[])
            .map((entry) => _evidenceFromJson(
                  Map<String, dynamic>.from(entry as Map),
                ))
            .toList(),
        pendingCreatorExplanation:
            json['pending_creator_explanation'] as bool? ?? false,
      );

  Map<String, dynamic> _governanceDecisionToJson(GovernanceDecision decision) =>
      <String, dynamic>{
        'decision_id': decision.decisionId,
        'target': _targetToJson(decision.target),
        'action': decision.action.name,
        'quarantine_state': decision.quarantineState.name,
        'decided_at_utc': decision.decidedAtUtc.toIso8601String(),
        'actor_id': decision.actorId,
        'reason': decision.reason,
        'evidence_ids': decision.evidenceIds,
        'reset_decision': decision.resetDecision.name,
      };

  GovernanceDecision _governanceDecisionFromJson(Map<String, dynamic> json) =>
      GovernanceDecision(
        decisionId: json['decision_id'] as String? ?? 'unknown_decision',
        target: _targetFromJson(
          Map<String, dynamic>.from(json['target'] as Map? ?? const {}),
        ),
        action: ModerationAction.values.firstWhere(
          (value) => value.name == json['action'],
          orElse: () => ModerationAction.flag,
        ),
        quarantineState: QuarantineState.values.firstWhere(
          (value) => value.name == json['quarantine_state'],
          orElse: () => QuarantineState.none,
        ),
        decidedAtUtc: DateTime.tryParse(json['decided_at_utc'] as String? ?? '')
                ?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        actorId: json['actor_id'] as String? ?? 'unknown_actor',
        reason: json['reason'] as String?,
        evidenceIds: List<String>.from(
          json['evidence_ids'] as List? ?? const <String>[],
        ),
        resetDecision: ResetDecision.values.firstWhere(
          (value) => value.name == json['reset_decision'],
          orElse: () => ResetDecision.none,
        ),
      );

  Map<String, dynamic> _breakGlassRequestToJson(BreakGlassRequest request) =>
      <String, dynamic>{
        'request_id': request.requestId,
        'actor_id': request.actorId,
        'reason_code': request.reasonCode,
        'justification': request.justification,
        'created_at_utc': request.createdAtUtc.toIso8601String(),
        'scope': <String, dynamic>{
          'target_ids': request.scope.targetIds,
          'identity_fields': request.scope.identityFields,
          'expires_at_utc': request.scope.expiresAtUtc.toIso8601String(),
        },
      };

  BreakGlassRequest _breakGlassRequestFromJson(Map<String, dynamic> json) =>
      BreakGlassRequest(
        requestId: json['request_id'] as String? ?? 'unknown_request',
        actorId: json['actor_id'] as String? ?? 'unknown_actor',
        reasonCode: json['reason_code'] as String? ?? 'unknown_reason',
        justification: json['justification'] as String? ?? '',
        createdAtUtc: DateTime.tryParse(json['created_at_utc'] as String? ?? '')
                ?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        scope: BreakGlassScope(
          targetIds: List<String>.from(
            (json['scope'] as Map?)?['target_ids'] as List? ?? const <String>[],
          ),
          identityFields: List<String>.from(
            (json['scope'] as Map?)?['identity_fields'] as List? ??
                const <String>[],
          ),
          expiresAtUtc: DateTime.tryParse(
                ((json['scope'] as Map?)?['expires_at_utc'] as String?) ?? '',
              )?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
      );

  Map<String, dynamic> _breakGlassGrantToJson(BreakGlassGrant grant) =>
      <String, dynamic>{
        'grant_id': grant.grantId,
        'request': _breakGlassRequestToJson(grant.request),
        'approver_id': grant.approverId,
        'started_at_utc': grant.startedAtUtc.toIso8601String(),
        'expires_at_utc': grant.expiresAtUtc.toIso8601String(),
        'active': grant.active,
      };

  BreakGlassGrant _breakGlassGrantFromJson(Map<String, dynamic> json) =>
      BreakGlassGrant(
        grantId: json['grant_id'] as String? ?? 'unknown_grant',
        request: _breakGlassRequestFromJson(
          Map<String, dynamic>.from(json['request'] as Map? ?? const {}),
        ),
        approverId: json['approver_id'] as String? ?? 'unknown_approver',
        startedAtUtc: DateTime.tryParse(json['started_at_utc'] as String? ?? '')
                ?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        expiresAtUtc: DateTime.tryParse(json['expires_at_utc'] as String? ?? '')
                ?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        active: json['active'] as bool? ?? false,
      );

  Map<String, dynamic> _breakGlassAuditEventToJson(
          BreakGlassAuditEvent event) =>
      <String, dynamic>{
        'audit_id': event.auditId,
        'grant_id': event.grantId,
        'event_type': event.eventType.name,
        'actor_id': event.actorId,
        'recorded_at_utc': event.recordedAtUtc.toIso8601String(),
        'details': event.details,
      };

  BreakGlassAuditEvent _breakGlassAuditEventFromJson(
    Map<String, dynamic> json,
  ) =>
      BreakGlassAuditEvent(
        auditId: json['audit_id'] as String? ?? 'unknown_audit',
        grantId: json['grant_id'] as String? ?? 'unknown_grant',
        eventType: BreakGlassAuditEventType.values.firstWhere(
          (value) => value.name == json['event_type'],
          orElse: () => BreakGlassAuditEventType.requested,
        ),
        actorId: json['actor_id'] as String? ?? 'unknown_actor',
        recordedAtUtc:
            DateTime.tryParse(json['recorded_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        details: Map<String, dynamic>.from(
          json['details'] as Map? ?? const <String, dynamic>{},
        ),
      );
}
