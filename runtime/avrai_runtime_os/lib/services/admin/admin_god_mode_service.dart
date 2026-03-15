// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';

export 'admin_runtime_governance_service.dart'
    show
        AdminRuntimeGovernanceService,
        UserDataSnapshot,
        AIDataSnapshot,
        CommunicationsSnapshot,
        MeshTrustDiagnosticsSnapshot,
        Ai2AiRendezvousDiagnosticsSnapshot,
        UserProgressData,
        UserPredictionsData,
        PredictionAction,
        JourneyStep,
        UserSearchResult,
        GodModeDashboardData,
        AggregatePrivacyMetrics,
        AuthMixSummary,
        AuthMixBucket,
        BusinessAccountData,
        ClubCommunityData,
        ActiveAIAgentData,
        GodModeFederatedRoundInfo,
        RoundParticipant,
        RoundPerformanceMetrics;

/// Deprecated compatibility alias for legacy admin callers.
///
/// New code should depend on [AdminRuntimeGovernanceService] directly.
@Deprecated(
  'Use AdminRuntimeGovernanceService directly. '
  'AdminGodModeService remains only as a temporary BHAM beta compatibility alias.',
)
class AdminGodModeService extends AdminRuntimeGovernanceService {
  AdminGodModeService({
    required super.authService,
    required super.communicationService,
    required super.businessService,
    super.clubService,
    super.communityService,
    required super.predictiveAnalytics,
    required super.connectionMonitor,
    super.chatAnalyzer,
    super.supabaseService,
    super.expertiseService,
    super.networkAnalytics,
    super.networkActivityMonitor,
    super.federatedLearningSystem,
    super.meshRouteLedger,
    super.meshCustodyOutbox,
    super.meshAnnounceLedger,
    super.meshInterfaceRegistry,
    super.meshRuntimeStateFrameService,
    super.ai2aiRuntimeStateFrameService,
    super.ai2aiRendezvousScheduler,
    super.ambientSocialRealityLearningService,
    super.meshCredentialRefreshService,
    super.meshRevocationStore,
    super.backgroundWakeRunRecordStore,
    super.fieldScenarioProofStore,
    super.fieldScenarioRunner,
    super.governedRuntimeRegistryService,
    super.governanceInspectionService,
  }) : super();
}
