// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:convert';

import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_communication_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_service.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_runtime_os/ml/predictive_analytics.dart';
import 'package:avrai_core/models/expertise/expertise_progress.dart';
import 'package:avrai_runtime_os/monitoring/connection_monitor.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';
import 'package:avrai_runtime_os/monitoring/network_analytics.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_core/models/community/collaborative_activity_metrics.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/p2p/federated_learning.dart' as federated;
import 'package:avrai_runtime_os/services/admin/permissions/admin_permission_checker.dart';
import 'package:avrai_runtime_os/services/admin/permissions/admin_access_control.dart';
import 'package:avrai_runtime_os/services/admin/user/admin_user_management_service.dart';
import 'package:avrai_runtime_os/services/admin/analytics/admin_analytics_service.dart';
import 'package:avrai_runtime_os/services/admin/monitoring/admin_system_monitoring_service.dart';
import 'package:avrai_runtime_os/services/admin/export/admin_data_export_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governed_runtime_registry_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governance_inspection_service.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_governance_inspection_contract.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_break_glass_governance_contract.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_quantum_atomic_time_validity_contract.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_core/models/misc/break_glass_governance_directive.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';

/// Runtime Governance Admin Service (Orchestrator)
/// Provides comprehensive real-time access to all system data
/// Requires admin runtime governance authentication
/// Phase 1.6: Refactored to use orchestrator pattern with modular services
class AdminRuntimeGovernanceService {
  final AdminAuthService _authService;
  final AdminCommunicationService _communicationService;
  final BusinessAccountService _businessService;
  final ClubService _clubService;
  // ignore: unused_field
  final CommunityService _communityService; // Reserved for future use
  final PredictiveAnalytics _predictiveAnalytics;
  final ConnectionMonitor _connectionMonitor;
  final AI2AIChatAnalyzer? _chatAnalyzer;
  final SupabaseService _supabaseService;
  // ignore: unused_field
  final ExpertiseService _expertiseService; // Reserved for future use
  final federated.FederatedLearningSystem? _federatedLearningSystem;
  final NetworkAnalytics? _networkAnalytics;
  final NetworkActivityMonitor? _networkActivityMonitor;
  final MeshRouteLedger? _meshRouteLedger;
  final MeshCustodyOutbox? _meshCustodyOutbox;
  final MeshAnnounceLedger? _meshAnnounceLedger;
  final MeshInterfaceRegistry? _meshInterfaceRegistry;
  final MeshRuntimeStateFrameService? _meshRuntimeStateFrameService;
  final Ai2AiRuntimeStateFrameService? _ai2aiRuntimeStateFrameService;
  final Ai2AiRendezvousScheduler? _ai2aiRendezvousScheduler;
  final AmbientSocialRealityLearningService? _ambientSocialRealityLearningService;
  final MeshSegmentCredentialRefreshService? _meshCredentialRefreshService;
  final MeshSegmentRevocationStore? _meshRevocationStore;
  final BackgroundWakeExecutionRunRecordStore? _backgroundWakeRunRecordStore;
  final DomainExecutionFieldScenarioProofStore? _fieldScenarioProofStore;
  final DomainExecutionFieldScenarioRunner? _fieldScenarioRunner;

  // Phase 1.6: Service modules
  late final AdminPermissionChecker _permissionChecker;
  late final AdminAccessControl _accessControl;
  late final AdminUserManagementService _userManagementService;
  late final AdminAnalyticsService _analyticsService;
  late final AdminSystemMonitoringService _monitoringService;
  late final AdminDataExportService _dataExportService;
  final UrkGovernedRuntimeRegistryService _governedRuntimeRegistryService;
  final UrkGovernanceInspectionService _governanceInspectionService;

  AdminRuntimeGovernanceService({
    required AdminAuthService authService,
    required AdminCommunicationService communicationService,
    required BusinessAccountService businessService,
    ClubService? clubService,
    CommunityService? communityService,
    required PredictiveAnalytics predictiveAnalytics,
    required ConnectionMonitor connectionMonitor,
    AI2AIChatAnalyzer? chatAnalyzer,
    SupabaseService? supabaseService,
    ExpertiseService? expertiseService,
    NetworkAnalytics? networkAnalytics,
    NetworkActivityMonitor? networkActivityMonitor,
    federated.FederatedLearningSystem? federatedLearningSystem,
    MeshRouteLedger? meshRouteLedger,
    MeshCustodyOutbox? meshCustodyOutbox,
    MeshAnnounceLedger? meshAnnounceLedger,
    MeshInterfaceRegistry? meshInterfaceRegistry,
    MeshRuntimeStateFrameService? meshRuntimeStateFrameService,
    Ai2AiRuntimeStateFrameService? ai2aiRuntimeStateFrameService,
    Ai2AiRendezvousScheduler? ai2aiRendezvousScheduler,
    AmbientSocialRealityLearningService? ambientSocialRealityLearningService,
    MeshSegmentCredentialRefreshService? meshCredentialRefreshService,
    MeshSegmentRevocationStore? meshRevocationStore,
    BackgroundWakeExecutionRunRecordStore? backgroundWakeRunRecordStore,
    DomainExecutionFieldScenarioProofStore? fieldScenarioProofStore,
    DomainExecutionFieldScenarioRunner? fieldScenarioRunner,
    UrkGovernedRuntimeRegistryService? governedRuntimeRegistryService,
    UrkGovernanceInspectionService? governanceInspectionService,
  })  : _authService = authService,
        _communicationService = communicationService,
        _businessService = businessService,
        _clubService = clubService ?? ClubService(),
        _communityService = communityService ?? CommunityService(),
        _predictiveAnalytics = predictiveAnalytics,
        _connectionMonitor = connectionMonitor,
        _chatAnalyzer = chatAnalyzer,
        _supabaseService = supabaseService ?? SupabaseService(),
        _expertiseService = expertiseService ?? ExpertiseService(),
        _networkAnalytics = networkAnalytics,
        _networkActivityMonitor = networkActivityMonitor,
        _federatedLearningSystem = federatedLearningSystem,
        _meshRouteLedger = meshRouteLedger,
        _meshCustodyOutbox = meshCustodyOutbox,
        _meshAnnounceLedger = meshAnnounceLedger,
        _meshInterfaceRegistry = meshInterfaceRegistry,
        _meshRuntimeStateFrameService = meshRuntimeStateFrameService,
        _ai2aiRuntimeStateFrameService = ai2aiRuntimeStateFrameService,
        _ai2aiRendezvousScheduler = ai2aiRendezvousScheduler,
        _ambientSocialRealityLearningService = ambientSocialRealityLearningService,
        _meshCredentialRefreshService = meshCredentialRefreshService,
        _meshRevocationStore = meshRevocationStore,
        _backgroundWakeRunRecordStore = backgroundWakeRunRecordStore,
        _fieldScenarioProofStore = fieldScenarioProofStore,
        _fieldScenarioRunner = fieldScenarioRunner,
        _governedRuntimeRegistryService = governedRuntimeRegistryService ??
            UrkGovernedRuntimeRegistryService(),
        _governanceInspectionService =
            governanceInspectionService ?? UrkGovernanceInspectionService() {
    // Phase 1.6: Initialize service modules
    _permissionChecker = AdminPermissionChecker(authService: _authService);
    _accessControl = AdminAccessControl(permissionChecker: _permissionChecker);
    _userManagementService = AdminUserManagementService(
      accessControl: _accessControl,
      supabaseService: _supabaseService,
      predictiveAnalytics: _predictiveAnalytics,
    );
    _analyticsService = AdminAnalyticsService(
      accessControl: _accessControl,
      supabaseService: _supabaseService,
      connectionMonitor: _connectionMonitor,
      networkAnalytics: _networkAnalytics,
      chatAnalyzer: _chatAnalyzer,
      federatedLearningSystem: _federatedLearningSystem,
    );
    _monitoringService = AdminSystemMonitoringService(
      accessControl: _accessControl,
      supabaseService: _supabaseService,
      predictiveAnalytics: _predictiveAnalytics,
    );
    _dataExportService = AdminDataExportService(
      accessControl: _accessControl,
      supabaseService: _supabaseService,
      businessService: _businessService,
      clubService: _clubService,
      communityService: _communityService,
      communicationService: _communicationService,
      connectionMonitor: _connectionMonitor,
    );
  }

  /// Check if runtime governance access is authorized
  bool get isAuthorized => _permissionChecker.isAuthorized;

  /// Get real-time user data stream
  Stream<UserDataSnapshot> watchUserData(String userId) {
    return _userManagementService.watchUserData(userId);
  }

  /// Get real-time AI data stream
  Stream<AIDataSnapshot> watchAIData(String aiSignature) {
    return _monitoringService.watchAIData(aiSignature);
  }

  /// Get real-time communications stream
  Stream<CommunicationsSnapshot> watchCommunications({
    String? userId,
    String? connectionId,
  }) {
    return _dataExportService.watchCommunications(
      userId: userId,
      connectionId: connectionId,
    );
  }

  Stream<MeshTrustDiagnosticsSnapshot> watchMeshTrustDiagnostics({
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
  }) {
    _accessControl.requireAuthorization();
    return Stream<void>.periodic(
      const Duration(seconds: 3),
      (_) {},
    ).asyncMap(
        (_) => getMeshTrustDiagnosticsSnapshot(privacyMode: privacyMode));
  }

  Stream<Ai2AiRendezvousDiagnosticsSnapshot> watchAi2AiRendezvousDiagnostics() {
    _accessControl.requireAuthorization();
    return Stream<void>.periodic(
      const Duration(seconds: 3),
      (_) {},
    ).asyncMap((_) => getAi2AiRendezvousDiagnosticsSnapshot());
  }

  Stream<AmbientSocialLearningDiagnosticsSnapshot>
      watchAmbientSocialLearningDiagnostics() {
    _accessControl.requireAuthorization();
    return Stream<void>.periodic(
      const Duration(seconds: 3),
      (_) {},
    ).asyncMap((_) => getAmbientSocialLearningDiagnosticsSnapshot());
  }

  bool get canRunControlledTrustValidation => _fieldScenarioRunner != null;

  Future<MeshTrustDiagnosticsSnapshot> getMeshTrustDiagnosticsSnapshot({
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
  }) async {
    _accessControl.requireAuthorization();
    final frameService = _meshRuntimeStateFrameService;
    final routeLedger = _meshRouteLedger;
    final announceLedger = _meshAnnounceLedger;
    final interfaceRegistry = _meshInterfaceRegistry;
    final now = DateTime.now().toUtc();
    final frame = frameService != null &&
            routeLedger != null &&
            announceLedger != null &&
            interfaceRegistry != null
        ? frameService.buildFrame(
            routeLedger: routeLedger,
            custodyOutbox: _meshCustodyOutbox,
            announceLedger: announceLedger,
            interfaceRegistry: interfaceRegistry,
            privacyMode: privacyMode,
            capturedAtUtc: now,
            credentialRefreshService: _meshCredentialRefreshService,
            revocationStore: _meshRevocationStore,
          )
        : MeshRuntimeStateFrame(
            capturedAtUtc: now,
            routeDestinationCount: 0,
            routeEntryCount: 0,
            interfaceEnabledCounts: const <String, int>{},
            interfaceTotalCounts: const <String, int>{},
            activeAnnounceCount: 0,
            trustedActiveAnnounceCount: 0,
            expiredAnnounceCount: 0,
            rejectedAnnounceCount: 0,
            pendingCustodyCount: 0,
            dueCustodyCount: 0,
            encryptedAtRest: false,
            announceTriggeredReplayCount: 0,
            announceRefreshReplayCount: 0,
            interfaceRecoveredReplayCount: 0,
            trustedReplayTriggerCount: 0,
            trustedReplayTriggerSourceCounts: const <String, int>{},
            rejectionReasonCounts: const <String, int>{},
            queuedPayloadKindCounts: const <String, int>{},
            activeAnnounceSourceCounts: const <String, int>{},
            rejectedAnnounceSourceCounts: const <String, int>{},
            activeCredentialCount: 0,
            expiringSoonCredentialCount: 0,
            revokedCredentialCount: 0,
            destinations: const <MeshRuntimeDestinationState>[],
          );
    return MeshTrustDiagnosticsSnapshot(
      capturedAtUtc: now,
      trustedActiveAnnounceCount: frame.trustedActiveAnnounceCount,
      rejectedAnnounceCount: frame.rejectedAnnounceCount,
      rejectionReasonCounts: frame.rejectionReasonCounts,
      trustedReplayTriggerCount: frame.trustedReplayTriggerCount,
      trustedReplayTriggerSourceCounts: frame.trustedReplayTriggerSourceCounts,
      activeCredentialCount: frame.activeCredentialCount,
      expiringSoonCredentialCount: frame.expiringSoonCredentialCount,
      revokedCredentialCount: frame.revokedCredentialCount,
      activeAnnounceSourceCounts: frame.activeAnnounceSourceCounts,
      rejectedAnnounceSourceCounts: frame.rejectedAnnounceSourceCounts,
      recentHeadlessRuns:
          _backgroundWakeRunRecordStore?.recentRecords(limit: 6) ??
              const <BackgroundWakeExecutionRunRecord>[],
      recentProofs: _fieldScenarioProofStore?.recentProofs(limit: 4) ??
          const <DomainExecutionFieldScenarioProof>[],
    );
  }

  Future<Ai2AiRendezvousDiagnosticsSnapshot>
      getAi2AiRendezvousDiagnosticsSnapshot() async {
    _accessControl.requireAuthorization();
    final scheduler = _ai2aiRendezvousScheduler;
    final ai2aiFrameService = _ai2aiRuntimeStateFrameService;
    final networkActivityMonitor = _networkActivityMonitor;
    final frame = ai2aiFrameService != null && networkActivityMonitor != null
        ? ai2aiFrameService.buildFrameFromMonitor(networkActivityMonitor)
        : null;
    return Ai2AiRendezvousDiagnosticsSnapshot(
      capturedAtUtc: DateTime.now().toUtc(),
      activeRendezvousCount: scheduler?.activeRendezvousCount ?? 0,
      releasedTicketCount: scheduler?.releasedTicketCount ?? 0,
      blockedByConditionCount: scheduler?.blockedByConditionCount ?? 0,
      trustedRouteUnavailableBlockCount:
          scheduler?.trustedRouteUnavailableBlockCount ?? 0,
      peerReceivedCount: frame?.peerReceivedCount ?? 0,
      peerValidatedCount: frame?.peerValidatedCount ?? 0,
      peerConsumedCount: frame?.peerConsumedCount ?? 0,
      peerAppliedCount: frame?.peerAppliedCount ?? 0,
      lastReleaseReason: scheduler?.lastReleaseReason,
      lastBlockedReason: scheduler?.lastBlockedReason,
      recentHeadlessRuns:
          _backgroundWakeRunRecordStore?.recentRecords(limit: 6) ??
              const <BackgroundWakeExecutionRunRecord>[],
      recentProofs: _fieldScenarioProofStore?.recentProofs(limit: 4) ??
          const <DomainExecutionFieldScenarioProof>[],
    );
  }

  Future<AmbientSocialLearningDiagnosticsSnapshot>
      getAmbientSocialLearningDiagnosticsSnapshot() async {
    _accessControl.requireAuthorization();
    return _ambientSocialRealityLearningService?.snapshot(
          capturedAtUtc: DateTime.now().toUtc(),
        ) ??
        AmbientSocialLearningDiagnosticsSnapshot(
          capturedAtUtc: DateTime.now().toUtc(),
          normalizedObservationCount: 0,
          candidateCoPresenceObservationCount: 0,
          confirmedInteractionPromotionCount: 0,
          duplicateMergeCount: 0,
          rejectedInteractionPromotionCount: 0,
          crowdUpgradeCount: 0,
          whatIngestionCount: 0,
          localityVibeUpdateCount: 0,
          personalDnaAuthorizedCount: 0,
          personalDnaAppliedCount: 0,
          latestNearbyPeerCount: 0,
          latestConfirmedInteractivePeerCount: 0,
        );
  }

  String exportRecentFieldValidationProofs({int limit = 8}) {
    _accessControl.requireAuthorization();
    return _fieldScenarioProofStore?.exportRecentProofBundles(limit: limit) ??
        '{"exported_at_utc":"${DateTime.now().toUtc().toIso8601String()}","proofs":[]}';
  }

  Future<DomainExecutionFieldScenarioProof> runFieldValidationScenario(
    DomainExecutionFieldScenario scenario,
  ) async {
    _accessControl.requireAuthorization();
    final runner = _fieldScenarioRunner;
    if (runner == null) {
      throw StateError('field_validation_runner_unavailable');
    }
    return runner.run(scenario);
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      runControlledPrivateMeshTrustValidation() async {
    _accessControl.requireAuthorization();
    final proofs = <DomainExecutionFieldScenarioProof>[];
    for (final scenario in const <DomainExecutionFieldScenario>[
      DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
      DomainExecutionFieldScenario.untrustedAnnounceRejected,
      DomainExecutionFieldScenario
          .deferredRendezvousBlockedByTrustedRouteUnavailable,
    ]) {
      proofs.add(await runFieldValidationScenario(scenario));
    }
    return proofs;
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      runControlledPrivateMeshMultiHopValidation() async {
    _accessControl.requireAuthorization();
    final proofs = <DomainExecutionFieldScenarioProof>[];
    for (final scenario in const <DomainExecutionFieldScenario>[
      DomainExecutionFieldScenario.trustedHeardForwardRoutable,
      DomainExecutionFieldScenario.trustedRelayRefreshRoutable,
    ]) {
      proofs.add(await runFieldValidationScenario(scenario));
    }
    return proofs;
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      runControlledPrivateMeshFieldAcceptanceValidation() async {
    _accessControl.requireAuthorization();
    final proofs = <DomainExecutionFieldScenarioProof>[];
    proofs.addAll(await runControlledPrivateMeshTrustValidation());
    proofs.addAll(await runControlledPrivateMeshMultiHopValidation());
    proofs.addAll(await runControlledAi2AiPeerTruthValidation());
    proofs.addAll(await runControlledAmbientSocialValidation());
    return proofs;
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      runControlledAi2AiPeerTruthValidation() async {
    _accessControl.requireAuthorization();
    return <DomainExecutionFieldScenarioProof>[
      await runFieldValidationScenario(
        DomainExecutionFieldScenario.deferredExchangePeerTruthAfterRelease,
      ),
    ];
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      runControlledAmbientSocialValidation() async {
    _accessControl.requireAuthorization();
    final proofs = <DomainExecutionFieldScenarioProof>[];
    for (final scenario in const <DomainExecutionFieldScenario>[
      DomainExecutionFieldScenario.ambientPassiveNearbyCandidateOnly,
      DomainExecutionFieldScenario
          .ambientTrustedInteractionPromotesConfirmedPresence,
      DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged,
      DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted,
    ]) {
      proofs.add(await runFieldValidationScenario(scenario));
    }
    return proofs;
  }

  Future<int> forceMeshSegmentRefresh({
    Duration threshold = const Duration(days: 3650),
  }) async {
    _accessControl.requireAuthorization();
    final refreshService = _meshCredentialRefreshService;
    if (refreshService == null) {
      throw StateError('mesh_segment_refresh_service_unavailable');
    }
    return refreshService.refreshExpiringTrustMaterial(threshold: threshold);
  }

  Future<void> revokeMeshCredential(
    String credentialId, {
    required String reason,
  }) async {
    _accessControl.requireAuthorization();
    final revocationStore = _meshRevocationStore;
    if (revocationStore == null) {
      throw StateError('mesh_segment_revocation_store_unavailable');
    }
    revocationStore.revokeCredential(credentialId, reason: reason);
  }

  Future<void> revokeMeshAttestation(
    String attestationId, {
    required String reason,
  }) async {
    _accessControl.requireAuthorization();
    final revocationStore = _meshRevocationStore;
    if (revocationStore == null) {
      throw StateError('mesh_segment_revocation_store_unavailable');
    }
    revocationStore.revokeAttestation(attestationId, reason: reason);
  }

  String exportMeshSegmentInventory() {
    _accessControl.requireAuthorization();
    final refreshService = _meshCredentialRefreshService;
    final revocationStore = _meshRevocationStore;
    final payload = <String, dynamic>{
      'exported_at_utc': DateTime.now().toUtc().toIso8601String(),
      'credentials': refreshService
              ?.allCredentials()
              .map((entry) => entry.toJson())
              .toList(growable: false) ??
          const <dynamic>[],
      'attestations': refreshService
              ?.allAttestations()
              .map((entry) => entry.toJson())
              .toList(growable: false) ??
          const <dynamic>[],
      'revocations': revocationStore
              ?.allRecords()
              .map((entry) => entry.toJson())
              .toList(growable: false) ??
          const <dynamic>[],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Get user progress data
  /// Privacy-preserving: Only returns progress metrics, NO personal data
  Future<UserProgressData> getUserProgress(String userId) async {
    return _userManagementService.getUserProgress(userId);
  }

  /// Get user predictions
  /// Privacy-preserving: Only returns AI predictions, NO personal data
  Future<UserPredictionsData> getUserPredictions(String userId) async {
    return _userManagementService.getUserPredictions(userId);
  }

  /// Get all business accounts
  Future<List<BusinessAccountData>> getAllBusinessAccounts() async {
    return _dataExportService.getAllBusinessAccounts();
  }

  /// Get all clubs and communities
  /// Privacy-preserving: Returns club/community data with member AI agent information
  /// Follows AdminPrivacyFilter principles (AI data only, no personal info)
  Future<List<ClubCommunityData>> getAllClubsAndCommunities() async {
    return _dataExportService.getAllClubsAndCommunities();
  }

  /// Get club/community by ID with member AI agents
  /// Privacy-preserving: Returns AI agent data only, no personal info
  Future<ClubCommunityData?> getClubOrCommunityById(String id) async {
    return _dataExportService.getClubOrCommunityById(id);
  }

  /// Get all active AI agents with location and predictions
  /// Privacy-preserving: Returns AI agent data with location and predicted actions
  /// Follows AdminPrivacyFilter principles (AI data only, no personal info)
  Future<List<ActiveAIAgentData>> getAllActiveAIAgents() async {
    return _monitoringService.getAllActiveAIAgents();
  }

  /// Get follower count for a user
  /// Returns number of users following this user
  Future<int> getFollowerCount(String userId) async {
    return _userManagementService.getFollowerCount(userId);
  }

  /// Get users who have a following (follower count >= threshold)
  /// Returns list of user IDs with their follower counts
  Future<Map<String, int>> getUsersWithFollowing({int minFollowers = 1}) async {
    return _userManagementService.getUsersWithFollowing(
        minFollowers: minFollowers);
  }

  /// Search users by AI signature or user ID only
  /// Privacy-preserving: No personal data (name, email, phone, address) is returned
  Future<List<UserSearchResult>> searchUsers({
    String? query, // Search by user ID or AI signature only
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    return _userManagementService.searchUsers(
      query: query,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
    );
  }

  /// Get aggregate privacy metrics (mean privacy score across all users)
  /// Returns the average privacy metrics for all users in the system
  Future<AggregatePrivacyMetrics> getAggregatePrivacyMetrics() async {
    return _analyticsService.getAggregatePrivacyMetrics();
  }

  /// Get comprehensive dashboard data
  Future<GodModeDashboardData> getDashboardData() async {
    return _analyticsService.getDashboardData();
  }

  /// Inspect an individual governed runtime/agent with explicit audited visibility.
  Future<GovernanceInspectionResponse> inspectGovernedAgent({
    required GovernanceInspectionRequest request,
    required UrkGovernanceInspectionSnapshot snapshot,
    required UrkGovernanceInspectionPolicy policy,
    GovernanceWhoKernelPayload? whoKernel,
    GovernanceWhatKernelPayload? whatKernel,
    GovernanceWhenKernelPayload? whenKernel,
    GovernanceWhereKernelPayload? whereKernel,
    GovernanceWhyKernelPayload? whyKernel,
    GovernanceHowKernelPayload? howKernel,
    GovernanceInspectionPolicyState policyState =
        const GovernanceInspectionPolicyState(),
    List<GovernanceInspectionProvenanceEntry> provenance =
        const <GovernanceInspectionProvenanceEntry>[],
  }) async {
    _accessControl.requireViewRealTimeData();
    _accessControl.requireViewAIData();
    _accessControl.requireAccessAuditLogs();

    final kernelPayload = await _buildInspectionKernelPayload(
      request: request,
      snapshot: snapshot,
      policy: policy,
    );

    return _governanceInspectionService.inspect(
      request: request,
      snapshot: snapshot,
      policy: policy,
      whoKernel: whoKernel ?? kernelPayload.whoKernel,
      whatKernel: whatKernel ?? kernelPayload.whatKernel,
      whenKernel: whenKernel ?? kernelPayload.whenKernel,
      whereKernel: whereKernel ?? kernelPayload.whereKernel,
      whyKernel: whyKernel ?? kernelPayload.whyKernel,
      howKernel: howKernel ?? kernelPayload.howKernel,
      policyState: kernelPayload.policyState.merge(policyState),
      provenance: <GovernanceInspectionProvenanceEntry>[
        ...kernelPayload.provenance,
        ...provenance,
      ],
    );
  }

  /// Evaluate a signed break-glass directive through explicit governance lanes.
  Future<BreakGlassGovernanceReceipt> evaluateBreakGlassDirective({
    required BreakGlassGovernanceDirective directive,
    required UrkBreakGlassGovernanceSnapshot breakGlassSnapshot,
    required UrkBreakGlassGovernancePolicy breakGlassPolicy,
    required UrkQuantumAtomicTimeValiditySnapshot quantumTimeSnapshot,
    required UrkQuantumAtomicTimeValidityPolicy quantumTimePolicy,
  }) async {
    _accessControl.requireViewRealTimeData();
    _accessControl.requireModifyAIData();
    _accessControl.requireAccessAuditLogs();

    return _governanceInspectionService.evaluateDirective(
      directive: directive,
      breakGlassSnapshot: breakGlassSnapshot,
      breakGlassPolicy: breakGlassPolicy,
      quantumTimeSnapshot: quantumTimeSnapshot,
      quantumTimePolicy: quantumTimePolicy,
    );
  }

  /// List recent governed-agent inspection artifacts for audit and review.
  Future<List<GovernanceInspectionResponse>> listRecentGovernanceInspections({
    int limit = 25,
    GovernanceStratum? stratum,
    String? runtimeId,
  }) async {
    _accessControl.requireViewRealTimeData();
    _accessControl.requireViewAIData();
    _accessControl.requireAccessAuditLogs();

    return _governanceInspectionService.listRecentInspectionResponses(
      limit: limit,
      stratum: stratum,
      runtimeId: runtimeId,
    );
  }

  /// List recent break-glass directives/receipts for audit and review.
  Future<List<BreakGlassGovernanceReceipt>> listRecentBreakGlassReceipts({
    int limit = 25,
    GovernanceStratum? stratum,
    String? runtimeId,
  }) async {
    _accessControl.requireViewRealTimeData();
    _accessControl.requireAccessAuditLogs();

    return _governanceInspectionService.listRecentBreakGlassReceipts(
      limit: limit,
      stratum: stratum,
      runtimeId: runtimeId,
    );
  }

  Future<_InspectionKernelPayload> _buildInspectionKernelPayload({
    required GovernanceInspectionRequest request,
    required UrkGovernanceInspectionSnapshot snapshot,
    required UrkGovernanceInspectionPolicy policy,
  }) async {
    final runtimeContext = await getGovernedRuntimeContext(
      runtimeId: request.targetRuntimeId,
      stratum: request.targetStratum,
      auditLimit: 10,
    );
    final matchedAgents = runtimeContext.matchedAgents;
    final persistedBinding = runtimeContext.persistedBinding;
    final dashboard = runtimeContext.dashboard;

    return _InspectionKernelPayload(
      whoKernel: GovernanceWhoKernelPayload(
        inspectionActorId: request.actorId,
        isHumanActor: request.isHumanActor,
        targetRuntimeId: request.targetRuntimeId,
        targetStratum: request.targetStratum.name,
        matchedAgentCount: matchedAgents.length,
        matchedAgents: matchedAgents
            .map(
              (agent) => GovernanceWhoKernelAgentMatch(
                userId: agent.userId,
                aiSignature: agent.aiSignature,
                isOnline: agent.isOnline,
              ),
            )
            .toList(growable: false),
        bindingSource: persistedBinding?.source,
        actorLabel: request.actorId,
      ),
      whatKernel: GovernanceWhatKernelPayload(
        inspectionCountForRuntime: runtimeContext.inspections.length,
        breakGlassCountForRuntime: runtimeContext.breakGlassReceipts.length,
        dashboardActiveConnections: dashboard.activeConnections,
        dashboardTotalCommunications: dashboard.totalCommunications,
        operationalScore: matchedAgents.isEmpty
            ? 0.0
            : matchedAgents
                    .map((agent) => agent.confidence)
                    .reduce((left, right) => left + right) /
                matchedAgents.length,
        matchedAgentStates: matchedAgents
            .map(
              (agent) => GovernanceWhatKernelAgentState(
                aiStatus: agent.aiStatus,
                currentStage: agent.currentStage,
                aiConnections: agent.aiConnections,
                topPredictedAction: agent.topPredictedAction,
              ),
            )
            .toList(growable: false),
      ),
      whenKernel: GovernanceWhenKernelPayload(
        requestedAt: request.requestedAt.serverTime.toIso8601String(),
        requestedAtSynchronized: request.requestedAt.isSynchronized,
        quantumAtomicTimeRequired: true,
        bindingRegisteredAt:
            persistedBinding?.updatedAt.serverTime.toIso8601String(),
        clockState: request.requestedAt.isSynchronized
            ? 'synchronized'
            : 'unsynchronized',
      ),
      whereKernel: GovernanceWhereKernelPayload(
        runtimeId: request.targetRuntimeId,
        governanceStratum: request.targetStratum.name,
        resolutionMode: runtimeContext.resolutionMode.name,
        bindingRuntimeId: persistedBinding?.runtimeId,
        scope: request.targetRuntimeId,
      ),
      whyKernel: GovernanceWhyKernelPayload(
        justification: request.justification,
        summaryVisibilityCoveragePct:
            snapshot.observedSummaryVisibilityCoveragePct,
        governanceCoveragePct: snapshot.observedGovernanceStrataCoveragePct,
        breakGlassAuditCoveragePct: snapshot.observedBreakGlassAuditCoveragePct,
        requiredSummaryVisibilityCoveragePct:
            policy.requiredSummaryVisibilityCoveragePct,
        requiredGovernanceCoveragePct:
            policy.requiredGovernanceStrataCoveragePct,
        convictionTier: 'governed_review',
      ),
      howKernel: GovernanceHowKernelPayload(
        visibilityTier: request.visibilityTier.name,
        inspectionPath: 'admin_runtime_governance_service',
        auditMode: 'explicit',
        resolutionMode: runtimeContext.resolutionMode.name,
        failClosedOnPolicyViolation: true,
        governanceChannel: 'human_oversight_lane',
      ),
      policyState: GovernanceInspectionPolicyState(
        maxUnauditedBreakGlassInspections:
            policy.maxUnauditedBreakGlassInspections,
        maxHiddenInspectionPaths: policy.maxHiddenInspectionPaths,
        observedUnauditedBreakGlassInspections:
            snapshot.observedUnauditedBreakGlassInspections,
        observedHiddenInspectionPaths: snapshot.observedHiddenInspectionPaths,
      ),
      provenance: <GovernanceInspectionProvenanceEntry>[
        GovernanceInspectionProvenanceEntry(
          kind: 'governed_runtime_context',
          reference: request.targetRuntimeId,
          subject: request.targetRuntimeId,
        ),
        if (persistedBinding != null)
          GovernanceInspectionProvenanceEntry(
            kind: 'runtime_binding_source',
            reference: persistedBinding.source,
            subject: persistedBinding.runtimeId,
          ),
      ],
    );
  }

  /// Resolve linked control-plane context for a governed runtime.
  Future<GovernedRuntimeContext> getGovernedRuntimeContext({
    required String runtimeId,
    GovernanceStratum? stratum,
    int auditLimit = 25,
  }) async {
    _accessControl.requireViewRealTimeData();
    _accessControl.requireViewAIData();
    _accessControl.requireAccessAuditLogs();

    final dashboardFuture = _analyticsService.getDashboardData().catchError(
          (_) => _fallbackDashboardData(),
        );
    final activeAgentsFuture =
        _monitoringService.getAllActiveAIAgents().catchError(
              (_) => <ActiveAIAgentData>[],
            );
    final inspectionFuture =
        _governanceInspectionService.listRecentInspectionResponses(
      limit: auditLimit,
      stratum: stratum,
      runtimeId: runtimeId,
    );
    final breakGlassFuture =
        _governanceInspectionService.listRecentBreakGlassReceipts(
      limit: auditLimit,
      stratum: stratum,
      runtimeId: runtimeId,
    );

    final results = await Future.wait<dynamic>([
      dashboardFuture,
      activeAgentsFuture,
      inspectionFuture,
      breakGlassFuture,
    ]);

    final activeAgents = results[1] as List<ActiveAIAgentData>;
    final persistedBinding =
        await _governedRuntimeRegistryService.getBinding(runtimeId);
    final matchedAgents = await _resolveGovernedRuntimeMatches(
      runtimeId: runtimeId,
      persistedBinding: persistedBinding,
      activeAgents: activeAgents,
    );

    return GovernedRuntimeContext(
      runtimeId: runtimeId,
      stratum: stratum,
      dashboard: results[0] as GodModeDashboardData,
      persistedBinding: persistedBinding,
      matchedAgents: matchedAgents,
      inspections: results[2] as List<GovernanceInspectionResponse>,
      breakGlassReceipts: results[3] as List<BreakGlassGovernanceReceipt>,
      resolutionMode: _resolutionModeFor(
        persistedBinding: persistedBinding,
        matchedAgents: matchedAgents,
      ),
    );
  }

  /// Get all federated learning rounds with participant details
  /// Shows active and completed rounds across the entire network
  Future<List<GodModeFederatedRoundInfo>> getAllFederatedLearningRounds({
    bool? includeCompleted,
  }) async {
    return _analyticsService.getAllFederatedLearningRounds(
      includeCompleted: includeCompleted,
    );
  }

  /// Get collaborative activity metrics
  /// Phase 7 Week 40: Privacy-safe aggregate metrics on collaborative patterns
  Future<CollaborativeActivityMetrics> getCollaborativeActivityMetrics() async {
    return _analyticsService.getCollaborativeActivityMetrics();
  }

  /// Dispose and cleanup
  /// Phase 1.6: Simplified - services handle their own cleanup
  void dispose() {
    // Services handle their own cleanup internally
    // No shared state to clean up after refactoring
  }

  bool _matchesRuntimeScope(String runtimeId, String candidate) {
    final left = runtimeId.trim().toLowerCase();
    final right = candidate.trim().toLowerCase();
    if (left.isEmpty || right.isEmpty) {
      return false;
    }
    return left == right ||
        left.contains(right) ||
        right.contains(left) ||
        _runtimeFragments(left).any((fragment) => right.contains(fragment));
  }

  Set<String> _runtimeFragments(String value) {
    return value
        .split(RegExp(r'[^a-z0-9]+'))
        .where((part) => part.length >= 4)
        .toSet();
  }

  Future<List<GovernedRuntimeAgentMatch>> _resolveGovernedRuntimeMatches({
    required String runtimeId,
    required UrkGovernedRuntimeBinding? persistedBinding,
    required List<ActiveAIAgentData> activeAgents,
  }) async {
    final exactMatches = activeAgents.where((agent) {
      if (persistedBinding == null) {
        return false;
      }
      if (persistedBinding.userId != null &&
          agent.userId == persistedBinding.userId) {
        return true;
      }
      if (persistedBinding.aiSignature != null &&
          agent.aiSignature == persistedBinding.aiSignature) {
        return true;
      }
      return false;
    }).toList();
    if (exactMatches.isNotEmpty) {
      return exactMatches.map(_toRuntimeMatch).toList();
    }

    final heuristicMatches = activeAgents.where((agent) {
      return _matchesRuntimeScope(runtimeId, agent.userId) ||
          _matchesRuntimeScope(runtimeId, agent.aiSignature);
    }).toList();
    if (heuristicMatches.isNotEmpty) {
      await _seedRuntimeBindingsFromHeuristic(
        runtimeId: runtimeId,
        matches: heuristicMatches,
      );
    }
    return heuristicMatches.map(_toRuntimeMatch).toList();
  }

  GovernedRuntimeAgentMatch _toRuntimeMatch(ActiveAIAgentData agent) {
    return GovernedRuntimeAgentMatch(
      userId: agent.userId,
      aiSignature: agent.aiSignature,
      isOnline: agent.isOnline,
      lastActive: agent.lastActive,
      aiConnections: agent.aiConnections,
      aiStatus: agent.aiStatus,
      currentStage: agent.currentStage,
      confidence: agent.confidence,
      topPredictedAction: agent.topPredictedAction?.action,
    );
  }

  Future<void> _seedRuntimeBindingsFromHeuristic({
    required String runtimeId,
    required List<ActiveAIAgentData> matches,
  }) async {
    final now = DateTime.now().toUtc();
    for (final agent in matches) {
      await _governedRuntimeRegistryService.upsertBinding(
        UrkGovernedRuntimeBinding(
          runtimeId: runtimeId,
          stratum: null,
          userId: agent.userId,
          aiSignature: agent.aiSignature,
          agentId: agent.aiSignature,
          source: 'heuristic_admin_context',
          updatedAt: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            isSynchronized: true,
            serverTime: now,
          ),
        ),
      );
    }
  }

  GovernedRuntimeResolutionMode _resolutionModeFor({
    required UrkGovernedRuntimeBinding? persistedBinding,
    required List<GovernedRuntimeAgentMatch> matchedAgents,
  }) {
    if (persistedBinding != null && matchedAgents.isNotEmpty) {
      return GovernedRuntimeResolutionMode.registryExact;
    }
    if (matchedAgents.isNotEmpty) {
      return GovernedRuntimeResolutionMode.heuristicAgentMatch;
    }
    return GovernedRuntimeResolutionMode.auditOnly;
  }

  GodModeDashboardData _fallbackDashboardData() {
    return GodModeDashboardData(
      totalUsers: 0,
      activeUsers: 0,
      totalBusinessAccounts: 0,
      activeConnections: 0,
      totalCommunications: 0,
      systemHealth: 0,
      aggregatePrivacyMetrics: AggregatePrivacyMetrics(
        meanOverallPrivacyScore: 0,
        meanAnonymizationLevel: 0,
        meanDataSecurityScore: 0,
        meanEncryptionStrength: 0,
        meanComplianceRate: 0,
        totalPrivacyViolations: 0,
        userCount: 0,
        lastUpdated: DateTime.now().toUtc(),
      ),
      authMix: AuthMixSummary.empty(),
      lastUpdated: DateTime.now().toUtc(),
    );
  }
}

// Data models for runtime governance admin

/// User data snapshot for admin viewing
/// Privacy-preserving: Contains AI-related data and location data (vibe indicators)
/// Excludes: name, email, phone, home address
class UserDataSnapshot {
  final String userId; // User's unique ID only
  final bool isOnline;
  final DateTime lastActive;
  final Map<String, dynamic>
      data; // AI-related and location data, NO personal info

  UserDataSnapshot({
    required this.userId,
    required this.isOnline,
    required this.lastActive,
    required this.data, // Must not contain: name, email, phone, home_address
    // Location data IS allowed (core vibe indicator)
  });

  /// Validate that no personal data is included
  /// Location data is allowed, but home address is forbidden
  bool get isValid {
    final forbiddenKeys = [
      'name',
      'email',
      'phone',
      'home_address',
      'homeaddress',
      'personal'
    ];
    final forbiddenLocationKeys = [
      'home_address',
      'homeaddress',
      'residential_address'
    ];

    for (final key in data.keys) {
      final lowerKey = key.toLowerCase();

      // Check for forbidden home address
      if (forbiddenLocationKeys
          .any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }

      // Check for other forbidden personal data
      if (forbiddenKeys.any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }
    }

    return true;
  }
}

class AIDataSnapshot {
  final String aiSignature;
  final bool isActive;
  final int connections;
  final Map<String, dynamic> data;

  AIDataSnapshot({
    required this.aiSignature,
    required this.isActive,
    required this.connections,
    required this.data,
  });
}

class CommunicationsSnapshot {
  final int totalMessages;
  final List<dynamic> recentMessages;
  final int activeConnections;
  final DateTime lastUpdated;

  CommunicationsSnapshot({
    required this.totalMessages,
    required this.recentMessages,
    required this.activeConnections,
    required this.lastUpdated,
  });
}

class MeshTrustDiagnosticsSnapshot {
  final DateTime capturedAtUtc;
  final int trustedActiveAnnounceCount;
  final int rejectedAnnounceCount;
  final Map<String, int> rejectionReasonCounts;
  final int trustedReplayTriggerCount;
  final Map<String, int> trustedReplayTriggerSourceCounts;
  final int activeCredentialCount;
  final int expiringSoonCredentialCount;
  final int revokedCredentialCount;
  final Map<String, int> activeAnnounceSourceCounts;
  final Map<String, int> rejectedAnnounceSourceCounts;
  final List<BackgroundWakeExecutionRunRecord> recentHeadlessRuns;
  final List<DomainExecutionFieldScenarioProof> recentProofs;

  MeshTrustDiagnosticsSnapshot({
    required this.capturedAtUtc,
    required this.trustedActiveAnnounceCount,
    required this.rejectedAnnounceCount,
    required this.rejectionReasonCounts,
    required this.trustedReplayTriggerCount,
    this.trustedReplayTriggerSourceCounts = const <String, int>{},
    required this.activeCredentialCount,
    required this.expiringSoonCredentialCount,
    required this.revokedCredentialCount,
    this.activeAnnounceSourceCounts = const <String, int>{},
    this.rejectedAnnounceSourceCounts = const <String, int>{},
    this.recentHeadlessRuns = const <BackgroundWakeExecutionRunRecord>[],
    this.recentProofs = const <DomainExecutionFieldScenarioProof>[],
  });
}

class Ai2AiRendezvousDiagnosticsSnapshot {
  final DateTime capturedAtUtc;
  final int activeRendezvousCount;
  final int releasedTicketCount;
  final int blockedByConditionCount;
  final int trustedRouteUnavailableBlockCount;
  final int peerReceivedCount;
  final int peerValidatedCount;
  final int peerConsumedCount;
  final int peerAppliedCount;
  final String? lastReleaseReason;
  final String? lastBlockedReason;
  final List<BackgroundWakeExecutionRunRecord> recentHeadlessRuns;
  final List<DomainExecutionFieldScenarioProof> recentProofs;

  Ai2AiRendezvousDiagnosticsSnapshot({
    required this.capturedAtUtc,
    required this.activeRendezvousCount,
    required this.releasedTicketCount,
    required this.blockedByConditionCount,
    required this.trustedRouteUnavailableBlockCount,
    this.peerReceivedCount = 0,
    this.peerValidatedCount = 0,
    this.peerConsumedCount = 0,
    this.peerAppliedCount = 0,
    this.lastReleaseReason,
    this.lastBlockedReason,
    this.recentHeadlessRuns = const <BackgroundWakeExecutionRunRecord>[],
    this.recentProofs = const <DomainExecutionFieldScenarioProof>[],
  });
}

class UserProgressData {
  final String userId;
  final List<ExpertiseProgress> expertiseProgress;
  final int totalContributions;
  final int pinsEarned;
  final int listsCreated;
  final int spotsAdded;
  final DateTime lastUpdated;

  UserProgressData({
    required this.userId,
    required this.expertiseProgress,
    required this.totalContributions,
    required this.pinsEarned,
    required this.listsCreated,
    required this.spotsAdded,
    required this.lastUpdated,
  });
}

class UserPredictionsData {
  final String userId;
  final String currentStage;
  final List<PredictionAction> predictedActions;
  final List<JourneyStep> journeyPath;
  final double confidence;
  final Duration timeframe;
  final DateTime lastUpdated;

  UserPredictionsData({
    required this.userId,
    required this.currentStage,
    required this.predictedActions,
    required this.journeyPath,
    required this.confidence,
    required this.timeframe,
    required this.lastUpdated,
  });
}

class PredictionAction {
  final String action;
  final double probability;
  final String category;

  PredictionAction({
    required this.action,
    required this.probability,
    required this.category,
  });
}

class JourneyStep {
  final String description;
  final Duration estimatedTime;
  final double likelihood;

  JourneyStep({
    required this.description,
    required this.estimatedTime,
    required this.likelihood,
  });
}

class BusinessAccountData {
  final BusinessAccount account;
  final bool isVerified;
  final int connectedExperts;
  final DateTime lastActivity;

  BusinessAccountData({
    required this.account,
    required this.isVerified,
    required this.connectedExperts,
    required this.lastActivity,
  });
}

class UserSearchResult {
  final String userId;
  final String aiSignature; // Only AI signature, no personal data
  final DateTime createdAt;
  final bool isActive;

  UserSearchResult({
    required this.userId,
    required this.aiSignature,
    required this.createdAt,
    required this.isActive,
  });
}

class GodModeDashboardData {
  final int totalUsers;
  final int activeUsers;
  final int totalBusinessAccounts;
  final int activeConnections;
  final int totalCommunications;
  final double systemHealth;
  final AggregatePrivacyMetrics aggregatePrivacyMetrics;
  final AuthMixSummary authMix;
  final DateTime lastUpdated;

  GodModeDashboardData({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalBusinessAccounts,
    required this.activeConnections,
    required this.totalCommunications,
    required this.systemHealth,
    required this.aggregatePrivacyMetrics,
    required this.authMix,
    required this.lastUpdated,
  });
}

class AuthMixSummary {
  final Map<String, int> signupProviderCounts;
  final AuthMixBucket lastSignInProviderCounts;
  final AuthMixBucket lastSignInPlatformCounts;

  AuthMixSummary({
    required this.signupProviderCounts,
    required this.lastSignInProviderCounts,
    required this.lastSignInPlatformCounts,
  });

  factory AuthMixSummary.empty() {
    return AuthMixSummary(
      signupProviderCounts: const {},
      lastSignInProviderCounts: AuthMixBucket.empty(),
      lastSignInPlatformCounts: AuthMixBucket.empty(),
    );
  }
}

class AuthMixBucket {
  final Map<String, int> totalCounts;
  final Map<String, int> recentCounts;

  AuthMixBucket({
    required this.totalCounts,
    required this.recentCounts,
  });

  factory AuthMixBucket.empty() {
    return AuthMixBucket(
      totalCounts: const {},
      recentCounts: const {},
    );
  }
}

/// Aggregate privacy metrics showing mean privacy scores across all users
class AggregatePrivacyMetrics {
  /// Mean overall privacy score (0.0-1.0) across all users
  final double meanOverallPrivacyScore;

  /// Mean anonymization level across all users
  final double meanAnonymizationLevel;

  /// Mean data security score across all users
  final double meanDataSecurityScore;

  /// Mean encryption strength across all users
  final double meanEncryptionStrength;

  /// Mean compliance rate across all users
  final double meanComplianceRate;

  /// Total privacy violations across all users
  final int totalPrivacyViolations;

  /// Number of users included in this aggregate
  final int userCount;

  /// When this aggregate was calculated
  final DateTime lastUpdated;

  AggregatePrivacyMetrics({
    required this.meanOverallPrivacyScore,
    required this.meanAnonymizationLevel,
    required this.meanDataSecurityScore,
    required this.meanEncryptionStrength,
    required this.meanComplianceRate,
    required this.totalPrivacyViolations,
    required this.userCount,
    required this.lastUpdated,
  });

  /// Get color indicator for privacy score
  String get scoreLabel {
    if (meanOverallPrivacyScore >= 0.95) return 'Excellent';
    if (meanOverallPrivacyScore >= 0.85) return 'Good';
    if (meanOverallPrivacyScore >= 0.75) return 'Fair';
    return 'Needs Improvement';
  }
}

/// Active AI Agent data for map display
/// Privacy-preserving: Contains AI agent data with location and predictions, NO personal information
class ActiveAIAgentData {
  final String userId;
  final String aiSignature;
  final double latitude;
  final double longitude;
  final bool isOnline;
  final DateTime lastActive;
  final int aiConnections;
  final String aiStatus;
  final List<PredictionAction> predictedActions;
  final String currentStage;
  final double confidence;

  ActiveAIAgentData({
    required this.userId,
    required this.aiSignature,
    required this.latitude,
    required this.longitude,
    required this.isOnline,
    required this.lastActive,
    required this.aiConnections,
    required this.aiStatus,
    required this.predictedActions,
    required this.currentStage,
    required this.confidence,
  });

  /// Get top predicted action
  PredictionAction? get topPredictedAction {
    if (predictedActions.isEmpty) return null;
    return predictedActions
        .reduce((a, b) => a.probability > b.probability ? a : b);
  }
}

/// Club/Community data for admin viewing
/// Privacy-preserving: Contains AI agent data for members, NO personal information
class ClubCommunityData {
  final String id;
  final String name;
  final String? description;
  final String category;
  final bool isClub;
  final int memberCount;
  final int eventCount;
  final String founderId;
  final List<String>? leaders; // Only for clubs
  final List<String>? adminTeam; // Only for clubs
  final DateTime createdAt;
  final DateTime? lastEventAt;
  final Map<String, Map<String, dynamic>>
      memberAIAgents; // AI agent data per member (privacy-filtered)

  ClubCommunityData({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.isClub,
    required this.memberCount,
    required this.eventCount,
    required this.founderId,
    this.leaders,
    this.adminTeam,
    required this.createdAt,
    this.lastEventAt,
    required this.memberAIAgents,
  });
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// God-mode view of a federated learning round with enriched participant data
class GodModeFederatedRoundInfo {
  /// The base federated learning round
  final federated.FederatedLearningRound round;

  /// List of participants with user and AI personality information
  final List<RoundParticipant> participants;

  /// Performance metrics for this round
  final RoundPerformanceMetrics performanceMetrics;

  /// Detailed explanation of why this learning round exists
  final String learningRationale;

  GodModeFederatedRoundInfo({
    required this.round,
    required this.participants,
    required this.performanceMetrics,
    required this.learningRationale,
  });

  /// Get formatted duration
  String get durationString {
    final duration = DateTime.now().difference(round.createdAt);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  /// Check if round is active
  bool get isActive =>
      round.status == federated.RoundStatus.training ||
      round.status == federated.RoundStatus.aggregating;
}

enum GovernedRuntimeResolutionMode {
  auditOnly,
  heuristicAgentMatch,
  registryExact,
}

class GovernedRuntimeAgentMatch {
  final String userId;
  final String aiSignature;
  final bool isOnline;
  final DateTime lastActive;
  final int aiConnections;
  final String aiStatus;
  final String currentStage;
  final double confidence;
  final String? topPredictedAction;

  GovernedRuntimeAgentMatch({
    required this.userId,
    required this.aiSignature,
    required this.isOnline,
    required this.lastActive,
    required this.aiConnections,
    required this.aiStatus,
    required this.currentStage,
    required this.confidence,
    required this.topPredictedAction,
  });
}

class GovernedRuntimeContext {
  final String runtimeId;
  final GovernanceStratum? stratum;
  final GodModeDashboardData dashboard;
  final UrkGovernedRuntimeBinding? persistedBinding;
  final List<GovernedRuntimeAgentMatch> matchedAgents;
  final List<GovernanceInspectionResponse> inspections;
  final List<BreakGlassGovernanceReceipt> breakGlassReceipts;
  final GovernedRuntimeResolutionMode resolutionMode;

  GovernedRuntimeContext({
    required this.runtimeId,
    required this.stratum,
    required this.dashboard,
    required this.persistedBinding,
    required this.matchedAgents,
    required this.inspections,
    required this.breakGlassReceipts,
    required this.resolutionMode,
  });

  String? get bindingSource => persistedBinding?.source;

  DateTime? get bindingRegisteredAt => persistedBinding?.updatedAt.serverTime;

  bool get hasPersistedBinding => persistedBinding != null;
}

class _InspectionKernelPayload {
  final GovernanceWhoKernelPayload whoKernel;
  final GovernanceWhatKernelPayload whatKernel;
  final GovernanceWhenKernelPayload whenKernel;
  final GovernanceWhereKernelPayload whereKernel;
  final GovernanceWhyKernelPayload whyKernel;
  final GovernanceHowKernelPayload howKernel;
  final GovernanceInspectionPolicyState policyState;
  final List<GovernanceInspectionProvenanceEntry> provenance;

  const _InspectionKernelPayload({
    required this.whoKernel,
    required this.whatKernel,
    required this.whenKernel,
    required this.whereKernel,
    required this.whyKernel,
    required this.howKernel,
    required this.policyState,
    required this.provenance,
  });
}

/// Participant information for a federated learning round
class RoundParticipant {
  /// The node ID participating in the round
  final String nodeId;

  /// The user ID associated with this node
  final String userId;

  /// The AI personality name/archetype for this participant
  final String aiPersonalityName;

  /// Number of contributions (model updates) made
  final int contributionCount;

  /// When this participant joined the round
  final DateTime joinedAt;

  /// Whether the participant is currently active
  final bool isActive;

  RoundParticipant({
    required this.nodeId,
    required this.userId,
    required this.aiPersonalityName,
    required this.contributionCount,
    required this.joinedAt,
    required this.isActive,
  });

  /// Get formatted join time
  String get joinedTimeAgo {
    final duration = DateTime.now().difference(joinedAt);
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    return '${duration.inMinutes}m ago';
  }
}

/// Performance metrics for a federated learning round
class RoundPerformanceMetrics {
  /// Percentage of invited participants who are actively participating
  final double participationRate;

  /// Average model accuracy across all participants
  final double averageAccuracy;

  /// Privacy compliance score (0.0-1.0)
  final double privacyComplianceScore;

  /// Progress towards convergence (0.0-1.0)
  final double convergenceProgress;

  RoundPerformanceMetrics({
    required this.participationRate,
    required this.averageAccuracy,
    required this.privacyComplianceScore,
    required this.convergenceProgress,
  });

  /// Get overall health score
  double get overallHealth =>
      (participationRate +
          averageAccuracy +
          privacyComplianceScore +
          convergenceProgress) /
      4.0;
}
