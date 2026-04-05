import 'dart:async';

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_core/models/community/collaborative_activity_metrics.dart';
import 'package:avrai_core/models/user/language_profile_diagnostics.dart';
import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_conversation_style_hydration_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/reality_grouping_audit_service.dart';
import 'package:avrai_runtime_os/services/admin/reality_model_checkin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/business/business_operator_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/language/language_profile_diagnostics_service.dart';
import 'package:avrai_runtime_os/services/community/community_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/visit_locality_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_operational_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/pages/knot_visualizer_page.dart';
import 'package:avrai_admin_app/ui/pages/world_planes/world_planes_page.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_admin_app/ui/widgets/realtime_agent_globe_widget.dart';
import 'package:avrai_admin_app/ui/widgets/reality_model_contract_status_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

enum OversightLayer {
  reality,
  universe,
  world,
}

class RealitySystemOversightPage extends StatefulWidget {
  const RealitySystemOversightPage({
    super.key,
    required this.layer,
    this.initialFocus,
    this.initialAttention,
    this.governanceService,
    this.replaySimulationService,
    this.signatureHealthService,
    this.languageDiagnosticsService,
    this.conversationStyleHydrationService,
    this.feedbackPromptPlannerService,
    this.eventFeedbackPromptPlannerService,
    this.onboardingFollowUpPlannerService,
    this.correctionFollowUpPlannerService,
    this.communityFollowUpPlannerService,
    this.businessFollowUpPlannerService,
    this.visitLocalityFollowUpPlannerService,
    this.reservationFollowUpPlannerService,
  });

  final OversightLayer layer;
  final String? initialFocus;
  final String? initialAttention;
  final AdminRuntimeGovernanceService? governanceService;
  final ReplaySimulationAdminService? replaySimulationService;
  final SignatureHealthAdminService? signatureHealthService;
  final LanguageProfileDiagnosticsService? languageDiagnosticsService;
  final AdminConversationStyleHydrationService?
      conversationStyleHydrationService;
  final RecommendationFeedbackPromptPlannerService?
      feedbackPromptPlannerService;
  final PostEventFeedbackPromptPlannerService?
      eventFeedbackPromptPlannerService;
  final OnboardingFollowUpPromptPlannerService?
      onboardingFollowUpPlannerService;
  final UserGovernedLearningCorrectionFollowUpPromptPlannerService?
      correctionFollowUpPlannerService;
  final CommunityFollowUpPromptPlannerService? communityFollowUpPlannerService;
  final BusinessOperatorFollowUpPromptPlannerService?
      businessFollowUpPlannerService;
  final VisitLocalityFollowUpPromptPlannerService?
      visitLocalityFollowUpPlannerService;
  final ReservationOperationalFollowUpPromptPlannerService?
      reservationFollowUpPlannerService;

  @override
  State<RealitySystemOversightPage> createState() =>
      _RealitySystemOversightPageState();
}

class _RealitySystemOversightPageState
    extends State<RealitySystemOversightPage> {
  final TextEditingController _checkInController = TextEditingController();
  final List<_CheckInEntry> _checkIns = <_CheckInEntry>[];
  final RealityModelCheckInService _checkInService =
      RealityModelCheckInService();
  final RealityGroupingAuditService _groupingAuditService =
      RealityGroupingAuditService();

  AdminRuntimeGovernanceService? _service;
  ReplaySimulationAdminService? _replaySimulationService;
  SignatureHealthAdminService? _signatureHealthService;
  LanguageProfileDiagnosticsService? _languageDiagnosticsService;
  AdminConversationStyleHydrationService? _conversationStyleHydrationService;
  RecommendationFeedbackPromptPlannerService? _feedbackPromptPlannerService;
  PostEventFeedbackPromptPlannerService? _eventFeedbackPromptPlannerService;
  OnboardingFollowUpPromptPlannerService? _onboardingFollowUpPlannerService;
  UserGovernedLearningCorrectionFollowUpPromptPlannerService?
      _correctionFollowUpPlannerService;
  CommunityFollowUpPromptPlannerService? _communityFollowUpPlannerService;
  BusinessOperatorFollowUpPromptPlannerService? _businessFollowUpPlannerService;
  VisitLocalityFollowUpPromptPlannerService?
      _visitLocalityFollowUpPlannerService;
  ReservationOperationalFollowUpPromptPlannerService?
      _reservationFollowUpPlannerService;
  SharedPreferencesCompat? _prefs;
  Timer? _liveRefreshTimer;

  bool _isLoading = true;
  bool _isCheckInBusy = false;
  bool _isExportingReplayBundle = false;
  bool _isSharingReplayBundle = false;
  bool _isStagingReplayTrainingCandidate = false;
  bool _isQueueingReplayTrainingIntake = false;
  bool _isUpdatingBoundedReviewTargetAction = false;
  bool _isGeneratingGroups = false;
  String? _error;

  GodModeDashboardData? _dashboardData;
  AggregatePrivacyMetrics? _privacyMetrics;
  CollaborativeActivityMetrics? _collaborativeMetrics;
  List<ClubCommunityData> _clubCommunityData = <ClubCommunityData>[];
  List<UserSearchResult> _users = <UserSearchResult>[];
  List<BusinessAccountData> _businesses = <BusinessAccountData>[];
  List<ActiveAIAgentData> _activeAgents = <ActiveAIAgentData>[];

  Set<String> _approvedGroupings = <String>{};
  List<String> _proposedGroupings = <String>[];
  List<RealityGroupingAuditEvent> _recentAuditEvents =
      <RealityGroupingAuditEvent>[];
  ReplaySimulationAdminSnapshot? _replaySnapshot;
  SignatureHealthSnapshot? _signatureHealthSnapshot;
  ReplaySimulationLearningBundleExport? _lastReplayBundleExport;
  ReplaySimulationRealityModelShareReport? _lastReplayShareReport;
  ReplaySimulationTrainingCandidateExport? _lastReplayTrainingCandidateExport;
  ReplaySimulationTrainingIntakeQueueExport?
      _lastReplayTrainingIntakeQueueExport;
  List<ReplaySimulationAdminEnvironmentDescriptor> _replayEnvironments =
      const <ReplaySimulationAdminEnvironmentDescriptor>[];
  String? _selectedReplayEnvironmentId;
  final Set<String> _checkInFeedbackBusyEntryIds = <String>{};
  LanguageProfileDiagnosticsSnapshot? _operatorLanguageDiagnostics;
  AdminConversationStyleSessionSnapshot? _adminConversationStyleSnapshot;
  List<RecommendationFeedbackPromptPlan> _recentFeedbackPromptPlans =
      const <RecommendationFeedbackPromptPlan>[];
  List<PostEventFeedbackPromptPlan> _recentEventFeedbackPromptPlans =
      const <PostEventFeedbackPromptPlan>[];
  List<OnboardingFollowUpPromptPlan> _recentOnboardingFollowUpPlans =
      const <OnboardingFollowUpPromptPlan>[];
  List<UserGovernedLearningCorrectionFollowUpPlan>
      _recentCorrectionFollowUpPlans =
      const <UserGovernedLearningCorrectionFollowUpPlan>[];
  List<CommunityFollowUpPromptPlan> _recentCommunityFollowUpPlans =
      const <CommunityFollowUpPromptPlan>[];
  List<BusinessOperatorFollowUpPromptPlan> _recentBusinessFollowUpPlans =
      const <BusinessOperatorFollowUpPromptPlan>[];
  List<VisitLocalityFollowUpPromptPlan> _recentVisitLocalityFollowUpPlans =
      const <VisitLocalityFollowUpPromptPlan>[];
  List<ReservationOperationalFollowUpPromptPlan>
      _recentReservationFollowUpPlans =
      const <ReservationOperationalFollowUpPromptPlan>[];
  int _realityModelStatusRefreshSeed = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _service = widget.governanceService ??
          GetIt.instance<AdminRuntimeGovernanceService>();
      _replaySimulationService = widget.replaySimulationService ??
          ReplaySimulationAdminService(
            intakeRepository:
                GetIt.instance.isRegistered<UniversalIntakeRepository>()
                    ? GetIt.instance<UniversalIntakeRepository>()
                    : null,
          );
      _signatureHealthService = widget.signatureHealthService ??
          (GetIt.instance.isRegistered<SignatureHealthAdminService>()
              ? GetIt.instance<SignatureHealthAdminService>()
              : null);
      _languageDiagnosticsService = widget.languageDiagnosticsService ??
          (GetIt.instance.isRegistered<LanguageProfileDiagnosticsService>()
              ? GetIt.instance<LanguageProfileDiagnosticsService>()
              : LanguageProfileDiagnosticsService());
      _conversationStyleHydrationService = widget
              .conversationStyleHydrationService ??
          (GetIt.instance.isRegistered<AdminConversationStyleHydrationService>()
              ? GetIt.instance<AdminConversationStyleHydrationService>()
              : null);
      _feedbackPromptPlannerService = widget.feedbackPromptPlannerService ??
          (GetIt.instance
                  .isRegistered<RecommendationFeedbackPromptPlannerService>()
              ? GetIt.instance<RecommendationFeedbackPromptPlannerService>()
              : null);
      _eventFeedbackPromptPlannerService = widget
              .eventFeedbackPromptPlannerService ??
          (GetIt.instance.isRegistered<PostEventFeedbackPromptPlannerService>()
              ? GetIt.instance<PostEventFeedbackPromptPlannerService>()
              : null);
      _onboardingFollowUpPlannerService = widget
              .onboardingFollowUpPlannerService ??
          (GetIt.instance.isRegistered<OnboardingFollowUpPromptPlannerService>()
              ? GetIt.instance<OnboardingFollowUpPromptPlannerService>()
              : null);
      _correctionFollowUpPlannerService = widget
              .correctionFollowUpPlannerService ??
          (GetIt.instance.isRegistered<
                  UserGovernedLearningCorrectionFollowUpPromptPlannerService>()
              ? GetIt.instance<
                  UserGovernedLearningCorrectionFollowUpPromptPlannerService>()
              : null);
      _communityFollowUpPlannerService = widget
              .communityFollowUpPlannerService ??
          (GetIt.instance.isRegistered<CommunityFollowUpPromptPlannerService>()
              ? GetIt.instance<CommunityFollowUpPromptPlannerService>()
              : null);
      _businessFollowUpPlannerService = widget.businessFollowUpPlannerService ??
          (GetIt.instance
                  .isRegistered<BusinessOperatorFollowUpPromptPlannerService>()
              ? GetIt.instance<BusinessOperatorFollowUpPromptPlannerService>()
              : null);
      _visitLocalityFollowUpPlannerService =
          widget.visitLocalityFollowUpPlannerService ??
              (GetIt.instance
                      .isRegistered<VisitLocalityFollowUpPromptPlannerService>()
                  ? GetIt.instance<VisitLocalityFollowUpPromptPlannerService>()
                  : null);
      _reservationFollowUpPlannerService =
          widget.reservationFollowUpPlannerService ??
              (GetIt.instance.isRegistered<
                      ReservationOperationalFollowUpPromptPlannerService>()
                  ? GetIt.instance<
                      ReservationOperationalFollowUpPromptPlannerService>()
                  : null);
      _prefs = await SharedPreferencesCompat.getInstance();
      _replayEnvironments = _replaySimulationService?.listEnvironments() ??
          const <ReplaySimulationAdminEnvironmentDescriptor>[];
      _selectedReplayEnvironmentId = _resolveReplayEnvironmentId(
        currentSelection: _selectedReplayEnvironmentId,
        environments: _replayEnvironments,
      );
      await _loadApprovedGroupings();
      await _loadAuditEvents();
      await _load();
      await _loadOperatorLanguageDiagnostics();
      await _loadAdminConversationStyleSession();
      await _loadRecentFeedbackPromptPlans();
      await _loadRecentEventFeedbackPromptPlans();
      await _loadRecentOnboardingFollowUpPlans();
      await _loadRecentCorrectionFollowUpPlans();
      await _loadRecentCommunityFollowUpPlans();
      await _loadRecentBusinessFollowUpPlans();
      await _loadRecentVisitLocalityFollowUpPlans();
      await _loadRecentReservationFollowUpPlans();
      await _generateGroupingProposals();
      _startLiveRefreshLoop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Admin oversight services are unavailable in this environment.';
        _isLoading = false;
      });
    }
  }

  Future<void> _load() async {
    if (_service == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _realityModelStatusRefreshSeed++;
    });

    try {
      switch (widget.layer) {
        case OversightLayer.reality:
          final results = await Future.wait<dynamic>([
            _service!.getDashboardData(),
            _service!.getAggregatePrivacyMetrics(),
            _service!.getCollaborativeActivityMetrics(),
            _replaySimulationService?.getSnapshot(
                  environmentId: _selectedReplayEnvironmentId,
                ) ??
                Future<ReplaySimulationAdminSnapshot?>.value(null),
            _signatureHealthService?.getSnapshot() ??
                Future<SignatureHealthSnapshot?>.value(null),
          ]);
          if (!mounted) return;
          setState(() {
            _dashboardData = results[0] as GodModeDashboardData;
            _privacyMetrics = results[1] as AggregatePrivacyMetrics;
            _collaborativeMetrics = results[2] as CollaborativeActivityMetrics;
            _replaySnapshot = results[3] as ReplaySimulationAdminSnapshot?;
            _signatureHealthSnapshot = results[4] as SignatureHealthSnapshot?;
            _isLoading = false;
          });
          break;

        case OversightLayer.universe:
          final results = await Future.wait<dynamic>([
            _service!.getAllClubsAndCommunities(),
            _service!.getAllActiveAIAgents(),
          ]);
          if (!mounted) return;
          setState(() {
            _clubCommunityData = results[0] as List<ClubCommunityData>;
            _activeAgents = results[1] as List<ActiveAIAgentData>;
            _isLoading = false;
          });
          break;

        case OversightLayer.world:
          final results = await Future.wait<dynamic>([
            _service!.getDashboardData(),
            _service!.searchUsers(),
            _service!.getAllBusinessAccounts(),
            _service!.getAllActiveAIAgents(),
          ]);
          if (!mounted) return;
          setState(() {
            _dashboardData = results[0] as GodModeDashboardData;
            _users = results[1] as List<UserSearchResult>;
            _businesses = results[2] as List<BusinessAccountData>;
            _activeAgents = results[3] as List<ActiveAIAgentData>;
            _isLoading = false;
          });
          break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load oversight data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadApprovedGroupings() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final saved =
        prefs.getStringList(_approvedGroupingKey(widget.layer)) ?? <String>[];

    if (!mounted) return;
    setState(() {
      _approvedGroupings = saved.toSet();
    });
  }

  Future<void> _persistApprovedGroupings() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setStringList(
      _approvedGroupingKey(widget.layer),
      _approvedGroupings.toList()..sort(),
    );
  }

  Future<void> _loadAuditEvents() async {
    final events = await _groupingAuditService.getRecentEvents(
      layer: _layerKey(widget.layer),
      limit: 10,
    );
    if (!mounted) return;
    setState(() {
      _recentAuditEvents = events;
    });
  }

  Future<void> _recordGroupingAudit({
    required String action,
    required String grouping,
  }) async {
    await _groupingAuditService.recordEvent(
      layer: _layerKey(widget.layer),
      action: action,
      grouping: grouping,
      actor: 'admin_operator',
      metadata: <String, dynamic>{
        'surface': 'reality_system_oversight',
      },
    );
    await _loadAuditEvents();
  }

  Future<void> _generateGroupingProposals() async {
    if (!mounted) return;

    final observed = _observedGroupingSignals();
    if (observed.isEmpty) {
      setState(() {
        _proposedGroupings = <String>[];
      });
      return;
    }

    setState(() {
      _isGeneratingGroups = true;
    });

    final proposed = await _checkInService.proposeGroupings(
      layer: _layerKey(widget.layer),
      observedTypes: observed,
      approvedGroupings: _approvedGroupings.toList(),
    );

    if (!mounted) return;
    setState(() {
      _proposedGroupings = proposed.where((group) {
        return !_approvedGroupings.contains(group);
      }).toList();
      _isGeneratingGroups = false;
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    _checkInController.dispose();
    super.dispose();
  }

  void _startLiveRefreshLoop() {
    _liveRefreshTimer?.cancel();
    if (widget.layer == OversightLayer.reality) {
      return;
    }

    _liveRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshLiveAgentsOnly(),
    );
  }

  Future<void> _refreshLiveAgentsOnly() async {
    if (!mounted || _service == null) {
      return;
    }

    try {
      final agents = await _service!.getAllActiveAIAgents();
      if (!mounted) return;
      setState(() {
        _activeAgents = agents;
      });
    } catch (_) {
      // Keep existing snapshot if a single live refresh cycle fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: '${_layerLabel(widget.layer)} Oversight',
      actions: [
        IconButton(
          onPressed: _isLoading
              ? null
              : () async {
                  await _load();
                  await _generateGroupingProposals();
                  await _loadAuditEvents();
                  await _loadOperatorLanguageDiagnostics();
                  await _loadAdminConversationStyleSession();
                  await _loadRecentFeedbackPromptPlans();
                  await _loadRecentEventFeedbackPromptPlans();
                  await _loadRecentCorrectionFollowUpPlans();
                  await _loadRecentCommunityFollowUpPlans();
                  await _loadRecentBusinessFollowUpPlans();
                  await _loadRecentVisitLocalityFollowUpPlans();
                  await _loadRecentReservationFollowUpPlans();
                },
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _load();
                  await _generateGroupingProposals();
                  await _loadAuditEvents();
                  await _loadOperatorLanguageDiagnostics();
                  await _loadAdminConversationStyleSession();
                  await _loadRecentFeedbackPromptPlans();
                  await _loadRecentEventFeedbackPromptPlans();
                  await _loadRecentCorrectionFollowUpPlans();
                  await _loadRecentCommunityFollowUpPlans();
                  await _loadRecentBusinessFollowUpPlans();
                  await _loadRecentVisitLocalityFollowUpPlans();
                  await _loadRecentReservationFollowUpPlans();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _load();
        await _generateGroupingProposals();
        await _loadAuditEvents();
        await _loadOperatorLanguageDiagnostics();
        await _loadAdminConversationStyleSession();
        await _loadRecentFeedbackPromptPlans();
        await _loadRecentEventFeedbackPromptPlans();
        await _loadRecentCorrectionFollowUpPlans();
        await _loadRecentCommunityFollowUpPlans();
        await _loadRecentBusinessFollowUpPlans();
        await _loadRecentVisitLocalityFollowUpPlans();
        await _loadRecentReservationFollowUpPlans();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.initialFocus != null || widget.initialAttention != null)
            _buildCommandCenterContextCard(context),
          if (widget.initialFocus != null || widget.initialAttention != null)
            const SizedBox(height: 12),
          _buildLayerSwitcher(),
          const SizedBox(height: 12),
          _buildPrivacyNoticeCard(context),
          const SizedBox(height: 12),
          _buildDirectionsCard(context),
          const SizedBox(height: 12),
          RealityModelContractStatusCard(
            surfaceLabel: _layerLabel(widget.layer),
            refreshSeed: _realityModelStatusRefreshSeed,
          ),
          const SizedBox(height: 12),
          _buildLayerSnapshot(context),
          if (widget.layer == OversightLayer.reality) ...[
            const SizedBox(height: 12),
            _buildReplaySimulationLearningCard(context),
          ],
          if (widget.layer == OversightLayer.universe ||
              widget.layer == OversightLayer.world) ...[
            const SizedBox(height: 12),
            RealtimeAgentGlobeWidget(
              agents: _activeAgents,
              title: '${_layerLabel(widget.layer)} Agent Globe (Live)',
            ),
          ],
          const SizedBox(height: 12),
          _buildGroupingCard(context),
          const SizedBox(height: 12),
          _buildModelCheckInCard(context),
          const SizedBox(height: 12),
          _buildOperatorLanguageDiagnosticsCard(context),
          const SizedBox(height: 12),
          _buildAdminConversationStyleCard(context),
          const SizedBox(height: 12),
          _buildFeedbackPromptPlansCard(context),
          const SizedBox(height: 12),
          _buildEventFeedbackPromptPlansCard(context),
          const SizedBox(height: 12),
          _buildOnboardingFollowUpPlansCard(context),
          const SizedBox(height: 12),
          _buildCorrectionFollowUpPlansCard(context),
          const SizedBox(height: 12),
          _buildCommunityFollowUpPlansCard(context),
          const SizedBox(height: 12),
          _buildBusinessFollowUpPlansCard(context),
          const SizedBox(height: 12),
          _buildVisitLocalityFollowUpPlansCard(context),
          const SizedBox(height: 12),
          _buildReservationFollowUpPlansCard(context),
          const SizedBox(height: 12),
          _buildVisualizationCard(context),
        ],
      ),
    );
  }

  Widget _buildCommandCenterContextCard(BuildContext context) {
    final boundedReviewCandidate = _selectedReplayBoundedReviewCandidate();
    return Card(
      color: AppColors.electricBlue.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Command Center handoff',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This ${widget.layer.name} oversight lane was opened from the command-center attention queue with carried operator context.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.initialFocus != null &&
                    widget.initialFocus!.isNotEmpty)
                  Chip(label: Text('Focus: ${widget.initialFocus}')),
                if (widget.initialAttention != null &&
                    widget.initialAttention!.isNotEmpty)
                  Chip(label: Text('Attention: ${widget.initialAttention}')),
                if (boundedReviewCandidate != null &&
                    _initialBoundedReviewTargetId() != null)
                  Chip(
                    label: Text(
                      'Review target: ${boundedReviewCandidate.targetLabel}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerSwitcher() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _layerChip(
              context: context,
              layer: OversightLayer.reality,
              route: AdminRoutePaths.realitySystemReality,
              icon: Icons.psychology_alt,
            ),
            _layerChip(
              context: context,
              layer: OversightLayer.universe,
              route: AdminRoutePaths.realitySystemUniverse,
              icon: Icons.groups,
            ),
            _layerChip(
              context: context,
              layer: OversightLayer.world,
              route: AdminRoutePaths.realitySystemWorld,
              icon: Icons.public,
            ),
          ],
        ),
      ),
    );
  }

  Widget _layerChip({
    required BuildContext context,
    required OversightLayer layer,
    required String route,
    required IconData icon,
  }) {
    final selected = widget.layer == layer;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => context.go(route),
      label: Text(_layerLabel(layer)),
      avatar: Icon(icon, size: 18),
    );
  }

  Widget _buildPrivacyNoticeCard(BuildContext context) {
    return Card(
      color: AppColors.electricGreen.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.privacy_tip, color: AppColors.electricGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Privacy mode is enforced: only agent identity and aggregate telemetry are visible. '
                'No names, emails, phone numbers, or home addresses are shown in this oversight surface.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionsCard(BuildContext context) {
    final directives = _directivesForLayer(widget.layer);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oversight Directions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...directives.map(
              (directive) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.arrow_right, size: 18),
                    ),
                    Expanded(child: Text(directive)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerSnapshot(BuildContext context) {
    switch (widget.layer) {
      case OversightLayer.reality:
        final systemHealth = _dashboardData?.systemHealth ?? 0;
        final compliance = _privacyMetrics?.meanComplianceRate ?? 0;
        final collaboration = _collaborativeMetrics?.collaborationRate ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reality Model Snapshot',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _progressMetric(
                  label: 'Convictions coherence',
                  value: compliance,
                ),
                _progressMetric(
                  label: 'Knowledge integrity',
                  value: systemHealth,
                ),
                _progressMetric(
                  label: 'Thoughts collaboration alignment',
                  value: collaboration,
                ),
                const SizedBox(height: 8),
                Text(
                  'Planning sessions: ${_collaborativeMetrics?.totalPlanningSessions ?? 0} | Total communications: ${_dashboardData?.totalCommunications ?? 0}',
                ),
              ],
            ),
          ),
        );

      case OversightLayer.universe:
        final clubCount = _clubCommunityData.where((x) => x.isClub).length;
        final communityCount =
            _clubCommunityData.where((x) => !x.isClub).length;
        final totalEvents = _clubCommunityData.fold<int>(
          0,
          (sum, item) => sum + item.eventCount,
        );
        final totalMembers = _clubCommunityData.fold<int>(
          0,
          (sum, item) => sum + item.memberCount,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Universe Model Snapshot',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metricChip('Clubs', '$clubCount'),
                    _metricChip('Communities', '$communityCount'),
                    _metricChip('Events', '$totalEvents'),
                    _metricChip('Members', '$totalMembers'),
                  ],
                ),
                const SizedBox(height: 12),
                if (_clubCommunityData.isEmpty)
                  const Text('No clubs or communities available')
                else
                  ..._clubCommunityData.take(8).map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(item.isClub
                              ? Icons.diversity_3
                              : Icons.hub_outlined),
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.memberCount} members | ${item.eventCount} events | ${item.category}',
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );

      case OversightLayer.world:
        final activeUsers = _dashboardData?.activeUsers ?? 0;
        final totalUsers = _users.length;
        final totalBusinesses = _businesses.length;
        final verifiedBusinesses =
            _businesses.where((b) => b.isVerified).length;
        final totalConnectedExperts = _businesses.fold<int>(
          0,
          (sum, item) => sum + item.connectedExperts,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('World Model Snapshot',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metricChip('Users', '$totalUsers'),
                    _metricChip('Active users', '$activeUsers'),
                    _metricChip('Businesses', '$totalBusinesses'),
                    _metricChip('Verified', '$verifiedBusinesses'),
                    _metricChip('Connected experts', '$totalConnectedExperts'),
                    _metricChip(
                      'Service interactions',
                      '${_dashboardData?.totalCommunications ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Latest agent signatures: ${_users.take(5).map((u) => _safePrefix(u.aiSignature, 10)).join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildReplaySimulationLearningCard(BuildContext context) {
    if (widget.layer != OversightLayer.reality) {
      return const SizedBox.shrink();
    }
    final replay = _replaySnapshot;
    if (replay == null) {
      return const SizedBox.shrink();
    }
    final selectedEnvironment = _selectedReplayEnvironment();
    final foundation = replay.foundation;
    final readiness = replay.learningReadiness;
    final learningOutcome = _selectedReplayLearningOutcome();
    final upwardLearningItem = _selectedReplayUpwardLearningItem();
    final boundedReviewCandidate = _selectedReplayBoundedReviewCandidate();
    final openedFromBoundedReviewQueue =
        _initialBoundedReviewTargetId() != null &&
            boundedReviewCandidate != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulation Learning Bundle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_replayEnvironments.length > 1) ...[
              DropdownButtonFormField<String>(
                key: const Key('oversightReplayEnvironmentSelector'),
                initialValue: _selectedReplayEnvironmentId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Simulation environment',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _replayEnvironments.map((environment) {
                  return DropdownMenuItem<String>(
                    value: environment.environmentId,
                    child: Text(
                      '${environment.displayName} (${environment.cityCode.toUpperCase()} ${environment.replayYear})',
                    ),
                  );
                }).toList(growable: false),
                onChanged: _isLoading ? null : _onReplayEnvironmentSelected,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Simulation environment ${selectedEnvironment?.displayName ?? replay.environmentId} (${replay.cityCode.toUpperCase()} ${replay.replayYear}) is grounded in the generic simulation intake/training stack and can be exported locally for reality-model review.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip('Training grade', readiness.trainingGrade),
                _metricChip(
                  'Kernel states',
                  '${foundation.activeKernelCount}/${foundation.kernelStates.length}',
                ),
                _metricChip(
                  'Request previews',
                  readiness.requestPreviews.length.toString(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Simulation basis: ${foundation.simulationMode}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              foundation.intakeFlowRefs.isEmpty
                  ? 'No explicit intake flow refs were attached to this simulation.'
                  : 'Intake flows: ${foundation.intakeFlowRefs.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if ((foundation.metadata['cityPackStructuralRef']
                        ?.toString()
                        .trim() ??
                    '')
                .isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'City-pack structural ref: ${foundation.metadata['cityPackStructuralRef']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              foundation.sidecarRefs.isEmpty
                  ? 'No sidecar refs recorded.'
                  : 'Sidecars: ${foundation.sidecarRefs.join(' • ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suggested training use: ${readiness.suggestedTrainingUse}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              readiness.shareWithRealityModelAllowed
                  ? 'This simulation is strong enough to package for bounded reality-model learning and deeper training review.'
                  : 'This simulation should remain local-review-first until the listed gaps are addressed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: readiness.shareWithRealityModelAllowed
                        ? AppColors.success
                        : AppColors.warning,
                  ),
            ),
            if (readiness.reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...readiness.reasons.take(3).map(
                    (reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $reason',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
            ],
            if (openedFromBoundedReviewQueue) ...[
              const SizedBox(height: 12),
              Text(
                'Active bounded review target',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${boundedReviewCandidate.targetLabel} was carried in from World Simulation Lab and is now the active bounded-review target for this simulation environment.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Operator decision: ${boundedReviewCandidate.acceptedSuggestion ? 'accepted suggestion' : 'overrode suggestion'} • Selected action: ${_boundedReviewActionLabel(boundedReviewCandidate.selectedAction)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if ((boundedReviewCandidate.cityPackStructuralRef ?? '')
                  .isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'City-pack structural ref: ${boundedReviewCandidate.cityPackStructuralRef}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              if (boundedReviewCandidate.latestOutcomeDisposition != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Latest lab outcome: ${_boundedReviewOutcomeLabel(boundedReviewCandidate.latestOutcomeDisposition)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              if (_boundedReviewRerunStatusLabel(
                    boundedReviewCandidate.latestRerunRequestStatus,
                    boundedReviewCandidate.latestRerunJobStatus,
                  ) !=
                  null) ...[
                const SizedBox(height: 4),
                Text(
                  'Latest rerun: ${_boundedReviewRerunStatusLabel(boundedReviewCandidate.latestRerunRequestStatus, boundedReviewCandidate.latestRerunJobStatus)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _isUpdatingBoundedReviewTargetAction
                        ? null
                        : () => _updateBoundedReviewTargetAction(
                              candidate: boundedReviewCandidate,
                              selectedAction: 'candidate_for_bounded_review',
                            ),
                    icon: const Icon(Icons.task_alt_outlined),
                    label: Text(
                      _isUpdatingBoundedReviewTargetAction
                          ? 'Saving review posture'
                          : 'Keep candidate for bounded review',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isUpdatingBoundedReviewTargetAction
                        ? null
                        : () => _updateBoundedReviewTargetAction(
                              candidate: boundedReviewCandidate,
                              selectedAction: 'watch_closely',
                            ),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Watch closely instead'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isUpdatingBoundedReviewTargetAction
                        ? null
                        : () => _updateBoundedReviewTargetAction(
                              candidate: boundedReviewCandidate,
                              selectedAction: 'keep_iterating',
                            ),
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Keep iterating instead'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isUpdatingBoundedReviewTargetAction
                        ? null
                        : () => context.go(AdminRoutePaths.worldSimulationLab),
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Open World Simulation Lab'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'These actions write back to the exact environment/target decision that opened this bounded review, so Reality Oversight does not lose the carried World Simulation Lab context.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (readiness.requestPreviews.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Reality-model request previews',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...readiness.requestPreviews.take(2).map(
                    (preview) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${preview.request.domain.toWireValue()} • ${preview.request.localityCode} • ${preview.rationale}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
            ],
            if (_lastReplayBundleExport != null) ...[
              const SizedBox(height: 12),
              Text(
                'Local bundle: ${_lastReplayBundleExport!.bundleRoot}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (_lastReplayShareReport != null) ...[
              const SizedBox(height: 8),
              Text(
                'Reality-model review: ${_lastReplayShareReport!.reviewJsonPath}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (_lastReplayTrainingCandidateExport != null) ...[
              const SizedBox(height: 8),
              Text(
                'Training candidate: ${_lastReplayTrainingCandidateExport!.trainingManifestJsonPath}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (_lastReplayTrainingIntakeQueueExport != null) ...[
              const SizedBox(height: 8),
              Text(
                'Training intake queue: ${_lastReplayTrainingIntakeQueueExport!.queueJsonPath}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (learningOutcome != null) ...[
              const SizedBox(height: 12),
              Text(
                'Post-learning evidence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (learningOutcome.adminEvidenceRefreshSummary != null)
                Text(
                  learningOutcome.adminEvidenceRefreshSummary!.summary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (learningOutcome.adminEvidenceRefreshSummary != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Admin evidence refresh: ${learningOutcome.adminEvidenceRefreshSummary!.jsonPath}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Requests: ${learningOutcome.adminEvidenceRefreshSummary!.requestCount} • Recommendations: ${learningOutcome.adminEvidenceRefreshSummary!.recommendationCount}'
                  '${learningOutcome.adminEvidenceRefreshSummary!.averageConfidence == null ? '' : ' • Avg confidence: ${learningOutcome.adminEvidenceRefreshSummary!.averageConfidence}'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              if (learningOutcome.supervisorFeedbackSummary != null) ...[
                const SizedBox(height: 8),
                Text(
                  learningOutcome.supervisorFeedbackSummary!.feedbackSummary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Supervisor feedback: ${learningOutcome.supervisorFeedbackSummary!.jsonPath}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bounded recommendation: ${learningOutcome.supervisorFeedbackSummary!.boundedRecommendation}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              if (upwardLearningItem != null &&
                  upwardLearningItem
                          .realityModelUpdateDownstreamRepropagationPlanJsonPath !=
                      null) ...[
                const SizedBox(height: 8),
                Text(
                  'Validated upward re-propagation release',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'A real-world upward conviction for ${upwardLearningItem.cityCode.toUpperCase()} cleared bounded validation and reopened governed follow-on lanes for this oversight context.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Re-propagation plan: ${upwardLearningItem.realityModelUpdateDownstreamRepropagationPlanJsonPath}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                ..._buildUpwardSignalEvidenceLines(
                  context,
                  upwardLearningItem,
                ),
                if (upwardLearningItem
                    .downstreamRepropagationReleasedTargetIds.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Released lanes: ${upwardLearningItem.downstreamRepropagationReleasedTargetIds.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'This same bounded release is visible to operator, supervisor, and assistant observers through the shared Signature Health oversight state.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              if (boundedReviewCandidate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Bounded review routing',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${boundedReviewCandidate.targetLabel} is explicitly marked as a candidate for bounded review for this simulation environment.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Operator decision: ${boundedReviewCandidate.acceptedSuggestion ? 'accepted suggestion' : 'overrode suggestion'} • Suggested reason: ${boundedReviewCandidate.suggestedReason.isEmpty ? 'No reason recorded.' : boundedReviewCandidate.suggestedReason}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (boundedReviewCandidate.latestOutcomeDisposition !=
                    null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Latest lab outcome: ${_boundedReviewOutcomeLabel(boundedReviewCandidate.latestOutcomeDisposition)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                if (_boundedReviewRerunStatusLabel(
                      boundedReviewCandidate.latestRerunRequestStatus,
                      boundedReviewCandidate.latestRerunJobStatus,
                    ) !=
                    null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Latest rerun: ${_boundedReviewRerunStatusLabel(boundedReviewCandidate.latestRerunRequestStatus, boundedReviewCandidate.latestRerunJobStatus)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
              if (learningOutcome.propagationTargets.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Governed downstream propagation',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Simulation -> reality-model learning outcome -> admin evidence refresh -> supervisor feedback -> domain propagation delta',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                ..._preferredPropagationTargets(learningOutcome).map(
                  (target) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildPropagationTargetSummary(context, target),
                  ),
                ),
                if (learningOutcome.propagationTargets.length >
                    _preferredPropagationTargets(learningOutcome).length) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Additional governed targets: ${learningOutcome.propagationTargets.length - _preferredPropagationTargets(learningOutcome).length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isExportingReplayBundle
                      ? null
                      : _exportReplayLearningBundle,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                    _isExportingReplayBundle
                        ? 'Exporting bundle'
                        : 'Export local bundle',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isSharingReplayBundle ||
                          !readiness.shareWithRealityModelAllowed
                      ? null
                      : _shareReplayLearningBundle,
                  icon: const Icon(Icons.psychology_alt),
                  label: Text(
                    _isSharingReplayBundle
                        ? 'Sharing to reality model'
                        : 'Share to reality model',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isStagingReplayTrainingCandidate ||
                          !readiness.shareWithRealityModelAllowed
                      ? null
                      : _stageReplayTrainingCandidate,
                  icon: const Icon(Icons.school_outlined),
                  label: Text(
                    _isStagingReplayTrainingCandidate
                        ? 'Staging deeper training'
                        : 'Stage deeper training candidate',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isQueueingReplayTrainingIntake ||
                          !readiness.shareWithRealityModelAllowed
                      ? null
                      : _queueReplayTrainingIntake,
                  icon: const Icon(Icons.playlist_add_check_circle_outlined),
                  label: Text(
                    _isQueueingReplayTrainingIntake
                        ? 'Queueing deeper training intake'
                        : 'Queue deeper training intake',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SignatureHealthLearningOutcomeItem? _selectedReplayLearningOutcome() {
    final snapshot = _signatureHealthSnapshot;
    final replay = _replaySnapshot;
    if (snapshot == null || replay == null) {
      return null;
    }
    for (final item in snapshot.learningOutcomeItems) {
      if (item.environmentId == replay.environmentId) {
        return item;
      }
    }
    return null;
  }

  SignatureHealthUpwardLearningItem? _selectedReplayUpwardLearningItem() {
    final snapshot = _signatureHealthSnapshot;
    final replay = _replaySnapshot;
    if (snapshot == null || replay == null) {
      return null;
    }
    SignatureHealthUpwardLearningItem? cityFallback;
    for (final item in snapshot.upwardLearningItems) {
      if (item.environmentId == replay.environmentId) {
        return item;
      }
      if (item.cityCode == replay.cityCode && cityFallback == null) {
        cityFallback = item;
      }
    }
    return cityFallback;
  }

  SignatureHealthBoundedReviewCandidate?
      _selectedReplayBoundedReviewCandidate() {
    final snapshot = _signatureHealthSnapshot;
    final replay = _replaySnapshot;
    if (snapshot == null || replay == null) {
      return null;
    }
    final requestedTargetId = _initialBoundedReviewTargetId();
    SignatureHealthBoundedReviewCandidate? fallback;
    for (final candidate in snapshot.boundedReviewCandidates) {
      if (candidate.environmentId == replay.environmentId) {
        if (requestedTargetId != null) {
          if (requestedTargetId == 'base_run' && candidate.targetsBaseRun) {
            return candidate;
          }
          if (candidate.variantId == requestedTargetId) {
            return candidate;
          }
        }
        fallback ??= candidate;
      }
    }
    return fallback;
  }

  String? _initialBoundedReviewTargetId() {
    final rawAttention = widget.initialAttention?.trim();
    if (rawAttention == null || rawAttention.isEmpty) {
      return null;
    }
    const prefix = 'bounded_review_candidate:';
    if (!rawAttention.startsWith(prefix)) {
      return null;
    }
    final targetId = rawAttention.substring(prefix.length).trim();
    if (targetId.isEmpty) {
      return null;
    }
    return targetId;
  }

  List<Widget> _buildUpwardSignalEvidenceLines(
    BuildContext context,
    SignatureHealthUpwardLearningItem item,
  ) {
    final lines = <String>[
      if (item.upwardDomainHints.isNotEmpty)
        'Domain hints: ${item.upwardDomainHints.join(', ')}',
      if (item.upwardReferencedEntities.isNotEmpty)
        'Referenced entities: ${item.upwardReferencedEntities.join(', ')}',
      if (item.upwardQuestions.isNotEmpty)
        'Questions: ${item.upwardQuestions.join(' | ')}',
      if (item.followUpPromptQuestion?.trim().isNotEmpty ?? false)
        'Follow-up prompt: ${item.followUpPromptQuestion!.trim()}',
      if (item.followUpResponseText?.trim().isNotEmpty ?? false)
        'Follow-up answer: ${item.followUpResponseText!.trim()}',
      if (item.followUpCompletionMode?.trim().isNotEmpty ?? false)
        'Follow-up completion: ${item.followUpCompletionMode!.trim()}',
      if (item.upwardSignalTags.isNotEmpty)
        'Signal tags: ${item.upwardSignalTags.join(', ')}',
      if (item.upwardPreferenceSignals.isNotEmpty)
        'Preference signals: ${_formatPreferenceSignals(item.upwardPreferenceSignals)}',
    ];
    if (lines.isEmpty) {
      return const <Widget>[];
    }
    return lines
        .map(
          (line) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              line,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        )
        .toList(growable: false);
  }

  String _formatPreferenceSignals(List<Map<String, dynamic>> signals) {
    return signals
        .map(
          (signal) => [
            signal['kind'],
            signal['value'],
            if (signal['weight'] != null) 'w:${signal['weight']}',
          ].whereType<Object>().join(':'),
        )
        .join(', ');
  }

  String _boundedReviewActionLabel(String raw) {
    return switch (raw) {
      'keep_iterating' => 'keep iterating',
      'watch_closely' => 'watch closely',
      'candidate_for_bounded_review' => 'candidate for bounded review',
      _ => raw.replaceAll('_', ' '),
    };
  }

  String _boundedReviewOutcomeLabel(String? raw) {
    return switch (raw) {
      'accepted' => 'accepted',
      'denied' => 'denied',
      'draft' => 'draft',
      _ => 'not yet labeled',
    };
  }

  String? _boundedReviewRerunStatusLabel(
    String? requestStatus,
    String? jobStatus,
  ) {
    if (jobStatus != null && jobStatus.isNotEmpty) {
      return switch (jobStatus) {
        'queued' => 'job queued',
        'running' => 'job running',
        'completed' => 'job completed',
        'failed' => 'job failed',
        _ => jobStatus,
      };
    }
    if (requestStatus != null && requestStatus.isNotEmpty) {
      return switch (requestStatus) {
        'queued' => 'request queued',
        'running' => 'request running',
        'completed' => 'request completed',
        'failed' => 'request failed',
        _ => requestStatus,
      };
    }
    return null;
  }

  Future<void> _updateBoundedReviewTargetAction({
    required SignatureHealthBoundedReviewCandidate candidate,
    required String selectedAction,
  }) async {
    final replaySimulationService = _replaySimulationService;
    if (replaySimulationService == null ||
        _isUpdatingBoundedReviewTargetAction) {
      return;
    }
    setState(() {
      _isUpdatingBoundedReviewTargetAction = true;
    });
    try {
      await replaySimulationService.recordLabTargetActionDecision(
        environmentId: candidate.environmentId,
        variantId: candidate.targetsBaseRun ? null : candidate.variantId,
        suggestedAction: candidate.suggestedAction,
        suggestedReason: candidate.suggestedReason,
        selectedAction: selectedAction,
      );
      if (!mounted) {
        return;
      }
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bounded review target updated: ${candidate.targetLabel} will now ${_boundedReviewActionMutationSummary(selectedAction)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update bounded review target: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingBoundedReviewTargetAction = false;
        });
      }
    }
  }

  String _boundedReviewActionMutationSummary(String selectedAction) {
    return switch (selectedAction) {
      'candidate_for_bounded_review' => 'stay queued for bounded review',
      'watch_closely' => 'stay on the watch-closely lane',
      'keep_iterating' => 'move back to the keep-iterating lane',
      _ => _boundedReviewActionLabel(selectedAction),
    };
  }

  List<SignatureHealthPropagationTarget> _preferredPropagationTargets(
    SignatureHealthLearningOutcomeItem learningOutcome,
  ) {
    final prioritizedTargets = learningOutcome.propagationTargets
        .where(
          (target) =>
              target.hierarchyDomainDeltaSummary != null ||
              target.personalAgentPersonalizationSummary != null,
        )
        .take(10)
        .toList(growable: false);
    if (prioritizedTargets.isNotEmpty) {
      return prioritizedTargets;
    }
    if (learningOutcome.propagationTargets.isEmpty) {
      return const <SignatureHealthPropagationTarget>[];
    }
    return <SignatureHealthPropagationTarget>[
      learningOutcome.propagationTargets.first,
    ];
  }

  Widget _buildPropagationTargetSummary(
    BuildContext context,
    SignatureHealthPropagationTarget target,
  ) {
    final delta = target.hierarchyDomainDeltaSummary;
    final personalization = target.personalAgentPersonalizationSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${target.targetId} • ${target.propagationKind}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          target.reason,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (delta != null) ...[
          const SizedBox(height: 4),
          Text(
            'Domain propagation delta • ${delta.domainId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            delta.summary,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Bounded use: ${delta.boundedUse}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Requests: ${delta.requestCount} • Recommendations: ${delta.recommendationCount}'
            '${delta.averageConfidence == null ? '' : ' • Avg confidence: ${delta.averageConfidence}'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (delta.jsonPath != null) ...[
            const SizedBox(height: 4),
            Text(
              'Domain delta: ${delta.jsonPath}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (delta.downstreamConsumerSummary != null) ...[
            const SizedBox(height: 4),
            Text(
              'Domain consumer • ${delta.downstreamConsumerSummary!.consumerId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              delta.downstreamConsumerSummary!.summary,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Targeted systems: ${delta.downstreamConsumerSummary!.targetedSystems.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (delta.downstreamConsumerSummary!.jsonPath != null) ...[
              const SizedBox(height: 4),
              Text(
                'Consumer artifact: ${delta.downstreamConsumerSummary!.jsonPath}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ],
        if (personalization != null) ...[
          const SizedBox(height: 4),
          Text(
            'Personal-agent personalization • ${personalization.domainId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            personalization.summary,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Personalization mode: ${personalization.personalizationMode}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bounded use: ${personalization.boundedUse}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Requests: ${personalization.requestCount} • Recommendations: ${personalization.recommendationCount}'
            '${personalization.averageConfidence == null ? '' : ' • Avg confidence: ${personalization.averageConfidence}'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (personalization.jsonPath != null) ...[
            const SizedBox(height: 4),
            Text(
              'Personalization delta: ${personalization.jsonPath}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
        if (target.laneArtifactJsonPath != null) ...[
          const SizedBox(height: 4),
          Text(
            'Lane artifact: ${target.laneArtifactJsonPath}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logical Groupings (Human Oversight)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Reality model learns from approved groupings and proposes new taxonomy clusters for easier understanding.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_approvedGroupings.isEmpty)
              const Text('No approved groupings yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _approvedGroupings.map(
                  (grouping) {
                    return InputChip(
                      label: Text(grouping),
                      selected: true,
                      onDeleted: () async {
                        setState(() {
                          _approvedGroupings.remove(grouping);
                        });
                        await _persistApprovedGroupings();
                        await _recordGroupingAudit(
                          action: 'removed_approval',
                          grouping: grouping,
                        );
                      },
                    );
                  },
                ).toList(),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isGeneratingGroups
                      ? null
                      : () async {
                          await _generateGroupingProposals();
                        },
                  icon: _isGeneratingGroups
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Generate Proposals'),
                ),
                const SizedBox(width: 8),
                Text(
                  'Observed types: ${_observedGroupingSignals().length}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_proposedGroupings.isEmpty)
              const Text('No pending proposals.')
            else
              ..._proposedGroupings.map(
                (grouping) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(grouping)),
                      TextButton(
                        onPressed: () async {
                          setState(() {
                            _approvedGroupings.add(grouping);
                            _proposedGroupings.remove(grouping);
                          });
                          await _persistApprovedGroupings();
                          await _recordGroupingAudit(
                            action: 'approved',
                            grouping: grouping,
                          );
                        },
                        child: const Text('Approve'),
                      ),
                      TextButton(
                        onPressed: () async {
                          setState(() {
                            _proposedGroupings.remove(grouping);
                          });
                          await _recordGroupingAudit(
                            action: 'rejected',
                            grouping: grouping,
                          );
                        },
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Approve to Reality Memory Audit',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_recentAuditEvents.isEmpty)
              const Text('No oversight decisions logged yet.')
            else
              ..._recentAuditEvents.take(6).map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${_formatTime(event.timestamp.toLocal())} | ${event.action} | ${event.grouping} | ${event.actor}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCheckInCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_layerLabel(widget.layer)} Model Check-In',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Runtime-backed conversation with privacy-safe context (agent identity and aggregates only).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _checkInController,
                    decoration: const InputDecoration(
                      hintText:
                          'Ask: What are you planning and preparing next?',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _runCheckIn(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isCheckInBusy ? null : _runCheckIn,
                  child: _isCheckInBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Check In'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_checkIns.isEmpty)
              const Text('No check-ins yet. Start a model conversation above.')
            else
              ..._checkIns.reversed.take(6).map(
                (entry) {
                  final feedbackBusy =
                      _checkInFeedbackBusyEntryIds.contains(entry.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.grey300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(entry.createdAt),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text('Admin: ${entry.prompt}'),
                        const SizedBox(height: 4),
                        Text('Model: ${entry.response}'),
                        if (entry.contract != null ||
                            entry.evaluation != null ||
                            entry.explanation != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (entry.contract != null)
                                _metricChip(
                                  'Contract',
                                  entry.contract!.version,
                                ),
                              if (entry.evaluation != null)
                                _metricChip(
                                  'Score',
                                  '${(entry.evaluation!.score * 100).round()}%',
                                ),
                              if (entry.evaluation != null)
                                _metricChip(
                                  'Confidence',
                                  '${(entry.evaluation!.confidence * 100).round()}%',
                                ),
                              if (entry.evaluation != null)
                                _metricChip(
                                  'Domain',
                                  _realityModelDomainLabel(
                                    entry.evaluation!.domain,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (entry.explanation != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Reality model: ${entry.explanation!.summary}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (entry.explanation!.highlights.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Highlights: ${entry.explanation!.highlights.join(' | ')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ],
                        if (entry.approvedResponse != null &&
                            entry.approvedResponse != entry.response) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Approved rewrite: ${entry.approvedResponse}',
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (entry.feedbackState ==
                            _CheckInFeedbackState.pending)
                          Row(
                            children: [
                              FilledButton.tonal(
                                onPressed: feedbackBusy
                                    ? null
                                    : () => _approveCheckIn(entry),
                                child: feedbackBusy
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Approve'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: feedbackBusy
                                    ? null
                                    : () => _rewriteCheckIn(entry),
                                child: const Text('Rewrite'),
                              ),
                            ],
                          )
                        else
                          Chip(
                            label: Text(
                              _feedbackStatusLabel(entry.feedbackState),
                            ),
                            backgroundColor: AppColors.grey100,
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Knot + Plane Visualizations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Open dedicated visuals to inspect knot behavior, distribution, and world-plane dynamics.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const KnotVisualizerPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.category),
                  label: const Text('Knot Visualizer'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WorldPlanesPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('World Planes'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.commandCenter),
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  label: const Text('Command Center'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.ai2ai),
                  icon: const Icon(Icons.hub_outlined),
                  label: const Text('AI2AI Dashboard'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.urkKernels),
                  icon: const Icon(Icons.settings_suggest),
                  label: const Text('URK Kernel Console'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.researchCenter),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Research Center'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorLanguageDiagnosticsCard(BuildContext context) {
    final diagnostics = _operatorLanguageDiagnostics;
    if (diagnostics == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operator Language Diagnostics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'No operator language profile yet. Run a check-in or approve a rewrite to start local governance learning.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final profile = diagnostics.profile;
    final correctionEvents = diagnostics.recentEvents
        .where((event) => event.isGovernanceFeedback)
        .take(3)
        .toList(growable: false);
    final recentEvents =
        diagnostics.recentEvents.take(3).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operator Language Diagnostics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This profile learns from governance prompts and approved rewrites using sanitized artifacts only.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip('Messages', profile.messageCount.toString()),
                _metricChip(
                  'Confidence',
                  '${(profile.learningConfidence * 100).round()}%',
                ),
                _metricChip(
                  'Operator',
                  diagnostics.displayRef,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDiagnosticsSignalWrap(
              context,
              title: 'Top vocabulary',
              values: diagnostics
                  .topVocabulary(limit: 6)
                  .map((entry) => entry.key)
                  .toList(growable: false),
            ),
            if (diagnostics.topPhrases(limit: 4).isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDiagnosticsSignalWrap(
                context,
                title: 'Common phrases',
                values: diagnostics
                    .topPhrases(limit: 4)
                    .map((entry) => entry.key)
                    .toList(growable: false),
              ),
            ],
            if (correctionEvents.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recent corrections',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...correctionEvents.map(
                (event) => _buildDiagnosticsEventRow(
                  context,
                  event: event,
                ),
              ),
            ],
            if (recentEvents.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recent learning',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...recentEvents.map(
                (event) => _buildDiagnosticsEventRow(
                  context,
                  event: event,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminConversationStyleCard(BuildContext context) {
    final snapshot = _adminConversationStyleSnapshot;
    if (snapshot == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Conversation Style Session',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'No active admin conversation-style session has been hydrated yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Conversation Style Session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This session is hydrated from login onward so supervisor, assistant, and daemon-facing admin surfaces can start with bounded operator style context immediately.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip('Operator', snapshot.operatorToken),
                _metricChip('Status', snapshot.status),
                _metricChip(
                  'Confidence',
                  '${(snapshot.learningConfidence * 100).round()}%',
                ),
                _metricChip('Messages', snapshot.messageCount.toString()),
                _metricChip(
                  'Adaptive',
                  snapshot.readyForAdaptation ? 'ready' : 'warming',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Mouth guidance: ${snapshot.mouthGuidance}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (snapshot.topVocabulary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Top vocabulary: ${snapshot.topVocabulary.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (snapshot.topPhrases.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Top phrases: ${snapshot.topPhrases.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (snapshot.recentLearningScopes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Recent scopes: ${snapshot.recentLearningScopes.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackPromptPlansCard(BuildContext context) {
    final plans = _recentFeedbackPromptPlans;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bounded Feedback Prompt Plans',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Structured recommendation feedback now produces bounded follow-up prompt plans that admin can inspect before in-app queueing or assistant execution.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plans.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No bounded feedback prompt plans have been staged yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...plans.take(3).map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.promptQuestion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${plan.ownerUserId} • ${plan.action.name} • ${plan.entity.type.name}:${plan.entity.title}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Priority: ${plan.priority} • Channel hint: ${plan.channelHint}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Why/how/where: ${plan.boundedContext['why']} • ${plan.boundedContext['how']} • ${plan.boundedContext['where']}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventFeedbackPromptPlansCard(BuildContext context) {
    final plans = _recentEventFeedbackPromptPlans;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bounded Event Follow-Up Plans',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Structured post-event feedback now produces bounded follow-up prompt plans that admin can inspect before event-side in-app queueing or assistant execution.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plans.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No bounded event follow-up plans have been staged yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...plans.take(3).map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.promptQuestion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${plan.ownerUserId} • event:${plan.eventTitle}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Priority: ${plan.priority} • Channel hint: ${plan.channelHint}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Why/how/where: ${plan.boundedContext['why']} • ${plan.boundedContext['how']} • ${plan.boundedContext['where']}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionFollowUpPlansCard(BuildContext context) {
    final plans = _recentCorrectionFollowUpPlans;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bounded Correction Follow-Up Plans',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Structured explicit corrections now produce bounded scope-follow-up plans that admin can inspect before Data Center queueing or assistant execution.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plans.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No bounded correction follow-up plans have been staged yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...plans.take(3).map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.promptQuestion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${plan.ownerUserId} • target:${plan.targetSummary}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Correction: ${plan.correctionText}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Priority: ${plan.priority} • Channel hint: ${plan.channelHint}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingFollowUpPlansCard(BuildContext context) {
    final plans = _recentOnboardingFollowUpPlans;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bounded Onboarding Follow-Up Plans',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Structured onboarding now produces bounded clarification plans that admin can inspect before Data Center queueing or assistant execution.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plans.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No bounded onboarding follow-up plans have been staged yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...plans.take(3).map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.promptQuestion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${plan.ownerUserId} • homebase:${plan.homebase?.trim().isNotEmpty == true ? plan.homebase!.trim() : 'not set'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Priority: ${plan.priority} • Channel hint: ${plan.channelHint}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Why/how/where: ${plan.boundedContext['why']} • ${plan.boundedContext['how']} • ${plan.boundedContext['where'] ?? 'unknown'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisitLocalityFollowUpPlansCard(BuildContext context) {
    final plans = _recentVisitLocalityFollowUpPlans;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bounded Visit & Locality Follow-Up Plans',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Runtime-captured visits and passive locality observations now produce bounded behavioral follow-up plans that admin can inspect before Data Center queueing or assistant execution.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plans.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No bounded visit or locality follow-up plans have been staged yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...plans.take(3).map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.promptQuestion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${plan.ownerUserId} • kind:${plan.observationKind} • target:${plan.targetLabel}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Priority: ${plan.priority} • Channel hint: ${plan.channelHint}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityFollowUpPlansCard(BuildContext context) {
    final plans = _recentCommunityFollowUpPlans;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bounded Community Follow-Up Plans',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Community coordination and validation signals now produce bounded follow-up plans that admin can inspect before Data Center queueing or assistant execution.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plans.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No bounded community follow-up plans have been staged yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...plans.take(3).map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.promptQuestion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${plan.ownerUserId} • kind:${plan.followUpKind} • target:${plan.targetLabel}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Priority: ${plan.priority} • Channel hint: ${plan.channelHint}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessFollowUpPlansCard(BuildContext context) {
    final plans = _recentBusinessFollowUpPlans;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bounded Business Follow-Up Plans',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Structured business profile create/update signals now produce bounded follow-up plans that admin can inspect before business-dashboard queue execution.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plans.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No bounded business follow-up plans have been staged yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...plans.take(3).map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.promptQuestion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${plan.ownerUserId} • business:${plan.businessName} • action:${plan.action}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Priority: ${plan.priority} • Channel hint: ${plan.channelHint}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Why/how/where: ${plan.boundedContext['why']} • ${plan.boundedContext['how']} • ${plan.boundedContext['where'] ?? 'unknown'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReservationFollowUpPlansCard(BuildContext context) {
    final plans = _recentReservationFollowUpPlans;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bounded Reservation Follow-Up Plans',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Reservation sharing, transfer, calendar sync, and recurrence signals now produce bounded follow-up plans that admin can inspect before reservation-page queueing or assistant execution.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plans.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No bounded reservation follow-up plans have been staged yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...plans.take(3).map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.promptQuestion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${plan.ownerUserId} • operation:${plan.operationKind} • target:${plan.targetLabel}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Priority: ${plan.priority} • Channel hint: ${plan.channelHint}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Why/how/where: ${plan.boundedContext['why'] ?? 'unknown'} • ${plan.boundedContext['how'] ?? plan.sourceSurface} • ${plan.boundedContext['where'] ?? 'reservation'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsSignalWrap(
    BuildContext context, {
    required String title,
    required List<String> values,
  }) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => Chip(
                  label: Text(value),
                  backgroundColor: AppColors.grey100,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildDiagnosticsEventRow(
    BuildContext context, {
    required LanguageLearningEvent event,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_languageScopeLabel(event.learningScope)} | ${_formatTime(event.timestamp.toLocal())}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(event.summary),
          if (event.vocabularySample.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Signals: ${event.vocabularySample.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: AppColors.grey100,
    );
  }

  Widget _progressMetric({required String label, required double value}) {
    final safeValue = value.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ${(safeValue * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: safeValue),
        ],
      ),
    );
  }

  Future<void> _runCheckIn() async {
    final prompt = _checkInController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isCheckInBusy = true;
    });

    final context = _buildCheckInContext();
    final globalGroupings = await _allApprovedGroupings();

    final result = await _checkInService.runCheckIn(
      layer: _layerKey(widget.layer),
      prompt: prompt,
      context: context,
      approvedGroupings: globalGroupings,
    );

    if (!mounted) return;
    setState(() {
      _checkIns.add(_CheckInEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        prompt: prompt,
        response: result.response,
        createdAt: result.createdAtUtc.toLocal(),
        contract: result.contract,
        evaluation: result.evaluation,
        trace: result.trace,
        explanation: result.explanation,
      ));
      _checkInController.clear();
      _isCheckInBusy = false;
    });
    await _loadOperatorLanguageDiagnostics();
    await _loadAdminConversationStyleSession();
  }

  Future<void> _approveCheckIn(_CheckInEntry entry) async {
    await _recordCheckInFeedback(
      entry: entry,
      approvedResponse: entry.response,
      feedbackState: _CheckInFeedbackState.approved,
    );
  }

  Future<void> _rewriteCheckIn(_CheckInEntry entry) async {
    final rewritten = await _promptForRewrittenResponse(entry);
    if (!mounted || rewritten == null) {
      return;
    }
    await _recordCheckInFeedback(
      entry: entry,
      approvedResponse: rewritten,
      feedbackState: _CheckInFeedbackState.rewritten,
    );
  }

  Future<void> _recordCheckInFeedback({
    required _CheckInEntry entry,
    required String approvedResponse,
    required _CheckInFeedbackState feedbackState,
  }) async {
    final trimmedApprovedResponse = approvedResponse.trim();
    if (trimmedApprovedResponse.isEmpty) {
      return;
    }

    setState(() {
      _checkInFeedbackBusyEntryIds.add(entry.id);
    });

    try {
      await _checkInService.recordCheckInFeedback(
        layer: _layerKey(widget.layer),
        prompt: entry.prompt,
        modelResponse: entry.response,
        approvedResponse: trimmedApprovedResponse,
        outcome: feedbackState == _CheckInFeedbackState.approved
            ? CheckInFeedbackOutcome.accepted
            : CheckInFeedbackOutcome.rewritten,
        context: _buildCheckInContext(),
      );

      if (!mounted) return;
      setState(() {
        final index =
            _checkIns.indexWhere((candidate) => candidate.id == entry.id);
        if (index == -1) {
          return;
        }
        _checkIns[index] = _checkIns[index].copyWith(
          approvedResponse: trimmedApprovedResponse,
          feedbackState: feedbackState,
        );
      });
      await _loadOperatorLanguageDiagnostics();
      await _loadAdminConversationStyleSession();
    } finally {
      if (mounted) {
        setState(() {
          _checkInFeedbackBusyEntryIds.remove(entry.id);
        });
      }
    }
  }

  Future<String?> _promptForRewrittenResponse(_CheckInEntry entry) async {
    final controller = TextEditingController(
      text: entry.approvedResponse ?? entry.response,
    );
    final rewritten = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rewrite Check-In Response'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Approved response',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save Rewrite'),
          ),
        ],
      ),
    );
    controller.dispose();
    return rewritten;
  }

  Map<String, dynamic> _buildCheckInContext() {
    final adminActor = _resolveAdminActor();
    final adminUserId = _resolveAdminUserId();
    switch (widget.layer) {
      case OversightLayer.reality:
        return <String, dynamic>{
          if (adminActor != null) 'operatorId': adminActor,
          if (adminUserId != null) 'operatorUserId': adminUserId,
          'systemHealth': _dashboardData?.systemHealth ?? 0,
          'privacyCompliance': _privacyMetrics?.meanComplianceRate ?? 0,
          'collaborationRate': _collaborativeMetrics?.collaborationRate ?? 0,
          'totalPlanningSessions':
              _collaborativeMetrics?.totalPlanningSessions ?? 0,
          'approvedGroupings': _approvedGroupings.toList()..sort(),
          'proposedGroupings': _proposedGroupings,
        };
      case OversightLayer.universe:
        return <String, dynamic>{
          if (adminActor != null) 'operatorId': adminActor,
          if (adminUserId != null) 'operatorUserId': adminUserId,
          'clubsCommunities': _clubCommunityData.length,
          'events': _clubCommunityData.fold<int>(
              0, (sum, item) => sum + item.eventCount),
          'members': _clubCommunityData.fold<int>(
              0, (sum, item) => sum + item.memberCount),
          'activeAgentCount': _activeAgents.length,
          'observedTypes': _observedGroupingSignals(),
          'approvedGroupings': _approvedGroupings.toList()..sort(),
        };
      case OversightLayer.world:
        return <String, dynamic>{
          if (adminActor != null) 'operatorId': adminActor,
          if (adminUserId != null) 'operatorUserId': adminUserId,
          'users': _users.length,
          'businesses': _businesses.length,
          'verifiedBusinesses': _businesses.where((b) => b.isVerified).length,
          'activeAgentCount': _activeAgents.length,
          'serviceInteractions': _dashboardData?.totalCommunications ?? 0,
          'observedTypes': _observedGroupingSignals(),
          'approvedGroupings': _approvedGroupings.toList()..sort(),
        };
    }
  }

  Future<void> _loadOperatorLanguageDiagnostics() async {
    final languageDiagnosticsService = _languageDiagnosticsService;
    if (languageDiagnosticsService == null) {
      return;
    }
    final profileRef = _checkInService.resolveGovernanceProfileRef(
      layer: _layerKey(widget.layer),
      context: _buildCheckInContext(),
    );
    final diagnostics =
        await languageDiagnosticsService.getDiagnosticsForProfileRef(
      profileRef,
      recentEventLimit: 6,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _operatorLanguageDiagnostics = diagnostics;
    });
  }

  Future<void> _loadAdminConversationStyleSession() async {
    final service = _conversationStyleHydrationService;
    if (service == null) {
      return;
    }
    final snapshot = await service.hydrateForCurrentSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _adminConversationStyleSnapshot = snapshot;
    });
  }

  Future<void> _loadRecentFeedbackPromptPlans() async {
    final service = _feedbackPromptPlannerService;
    if (service == null) {
      return;
    }
    final plans = await service.listRecentPlans(limit: 6);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentFeedbackPromptPlans = plans;
    });
  }

  Future<void> _loadRecentEventFeedbackPromptPlans() async {
    final service = _eventFeedbackPromptPlannerService;
    if (service == null) {
      return;
    }
    final plans = await service.listRecentPlans(limit: 6);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentEventFeedbackPromptPlans = plans;
    });
  }

  Future<void> _loadRecentCorrectionFollowUpPlans() async {
    final service = _correctionFollowUpPlannerService;
    if (service == null) {
      return;
    }
    final plans = await service.listRecentPlans(limit: 6);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentCorrectionFollowUpPlans = plans;
    });
  }

  Future<void> _loadRecentOnboardingFollowUpPlans() async {
    final service = _onboardingFollowUpPlannerService;
    if (service == null) {
      return;
    }
    final plans = await service.listRecentPlans(limit: 6);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentOnboardingFollowUpPlans = plans;
    });
  }

  Future<void> _loadRecentCommunityFollowUpPlans() async {
    final service = _communityFollowUpPlannerService;
    if (service == null) {
      return;
    }
    final plans = await service.listRecentPlans(limit: 6);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentCommunityFollowUpPlans = plans;
    });
  }

  Future<void> _loadRecentBusinessFollowUpPlans() async {
    final service = _businessFollowUpPlannerService;
    if (service == null) {
      return;
    }
    final plans = await service.listRecentPlans(limit: 6);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentBusinessFollowUpPlans = plans;
    });
  }

  Future<void> _loadRecentVisitLocalityFollowUpPlans() async {
    final service = _visitLocalityFollowUpPlannerService;
    if (service == null) {
      return;
    }
    final plans = await service.listRecentPlans(limit: 6);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentVisitLocalityFollowUpPlans = plans;
    });
  }

  Future<void> _loadRecentReservationFollowUpPlans() async {
    final service = _reservationFollowUpPlannerService;
    if (service == null) {
      return;
    }
    final plans = await service.listRecentPlans(limit: 6);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentReservationFollowUpPlans = plans;
    });
  }

  String _languageScopeLabel(String scope) {
    switch (scope) {
      case 'governance_feedback_rewrite':
        return 'Approved rewrite';
      case 'governance_feedback_acceptance':
        return 'Approved response';
      case 'governance':
        return 'Governance prompt';
      default:
        return scope.replaceAll('_', ' ');
    }
  }

  List<String> _observedGroupingSignals() {
    switch (widget.layer) {
      case OversightLayer.reality:
        return <String>[
          if (_privacyMetrics != null)
            'privacy-compliance:${(_privacyMetrics!.meanComplianceRate * 100).round()}%',
          if (_dashboardData != null)
            'system-health:${(_dashboardData!.systemHealth * 100).round()}%',
          if (_collaborativeMetrics != null)
            'planning-sessions:${_collaborativeMetrics!.totalPlanningSessions}',
        ];
      case OversightLayer.universe:
        return _clubCommunityData
            .map((item) {
              final activityBand = item.eventCount >= 20
                  ? 'high'
                  : item.eventCount >= 5
                      ? 'medium'
                      : 'low';
              return '${item.isClub ? 'club' : 'community'}:${item.category}:$activityBand';
            })
            .toSet()
            .toList()
          ..sort();
      case OversightLayer.world:
        final businessTypes = _businesses
            .map(
              (item) =>
                  '${item.account.businessType}:${item.isVerified ? 'verified' : 'unverified'}',
            )
            .toSet();
        final userStages = _activeAgents
            .map((agent) => 'agent-stage:${agent.currentStage}')
            .toSet();
        return <String>{...businessTypes, ...userStages}.toList()..sort();
    }
  }

  String? _resolveReplayEnvironmentId({
    required String? currentSelection,
    required List<ReplaySimulationAdminEnvironmentDescriptor> environments,
  }) {
    if (environments.isEmpty) {
      return null;
    }
    if (currentSelection != null &&
        environments.any(
          (environment) => environment.environmentId == currentSelection,
        )) {
      return currentSelection;
    }
    final focusedEnvironmentId = widget.initialFocus?.trim();
    if (focusedEnvironmentId != null &&
        focusedEnvironmentId.isNotEmpty &&
        environments.any(
          (environment) => environment.environmentId == focusedEnvironmentId,
        )) {
      return focusedEnvironmentId;
    }
    return environments.first.environmentId;
  }

  ReplaySimulationAdminEnvironmentDescriptor? _selectedReplayEnvironment() {
    final environmentId = _selectedReplayEnvironmentId;
    if (environmentId == null) {
      return null;
    }
    for (final environment in _replayEnvironments) {
      if (environment.environmentId == environmentId) {
        return environment;
      }
    }
    return null;
  }

  Future<void> _onReplayEnvironmentSelected(String? environmentId) async {
    if (!mounted ||
        environmentId == null ||
        environmentId == _selectedReplayEnvironmentId) {
      return;
    }
    setState(() {
      _selectedReplayEnvironmentId = environmentId;
      _lastReplayBundleExport = null;
      _lastReplayShareReport = null;
      _lastReplayTrainingCandidateExport = null;
      _lastReplayTrainingIntakeQueueExport = null;
    });
    await _load();
  }

  Future<void> _exportReplayLearningBundle() async {
    final replaySimulationService = _replaySimulationService;
    if (replaySimulationService == null) {
      return;
    }
    setState(() {
      _isExportingReplayBundle = true;
    });
    try {
      final export = await replaySimulationService.exportLearningBundle(
        environmentId: _selectedReplayEnvironmentId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastReplayBundleExport = export;
        _isExportingReplayBundle = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Simulation bundle exported to ${export.bundleRoot}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isExportingReplayBundle = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulation bundle export failed: $error'),
        ),
      );
    }
  }

  Future<void> _shareReplayLearningBundle() async {
    final replaySimulationService = _replaySimulationService;
    final readiness = _replaySnapshot?.learningReadiness;
    if (replaySimulationService == null ||
        readiness == null ||
        !readiness.shareWithRealityModelAllowed) {
      return;
    }
    setState(() {
      _isSharingReplayBundle = true;
    });
    try {
      final report =
          await replaySimulationService.shareLearningBundleWithRealityModel(
        environmentId: _selectedReplayEnvironmentId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastReplayShareReport = report;
        _isSharingReplayBundle = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bounded reality-model review saved to ${report.reviewJsonPath}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSharingReplayBundle = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reality-model sharing failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _stageReplayTrainingCandidate() async {
    final replaySimulationService = _replaySimulationService;
    final readiness = _replaySnapshot?.learningReadiness;
    if (replaySimulationService == null ||
        readiness == null ||
        !readiness.shareWithRealityModelAllowed) {
      return;
    }
    setState(() {
      _isStagingReplayTrainingCandidate = true;
    });
    try {
      final export = await replaySimulationService.stageDeeperTrainingCandidate(
        environmentId: _selectedReplayEnvironmentId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastReplayTrainingCandidateExport = export;
        _isStagingReplayTrainingCandidate = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Training candidate manifest saved to ${export.trainingManifestJsonPath}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isStagingReplayTrainingCandidate = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Training candidate staging failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _queueReplayTrainingIntake() async {
    final replaySimulationService = _replaySimulationService;
    final readiness = _replaySnapshot?.learningReadiness;
    if (replaySimulationService == null ||
        readiness == null ||
        !readiness.shareWithRealityModelAllowed) {
      return;
    }
    setState(() {
      _isQueueingReplayTrainingIntake = true;
    });
    try {
      final export = await replaySimulationService.queueDeeperTrainingIntake(
        environmentId: _selectedReplayEnvironmentId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastReplayTrainingIntakeQueueExport = export;
        _isQueueingReplayTrainingIntake = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Training intake queue saved to ${export.queueJsonPath}'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isQueueingReplayTrainingIntake = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Training intake queue failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<List<String>> _allApprovedGroupings() async {
    final prefs = _prefs;
    if (prefs == null) {
      return _approvedGroupings.toList()..sort();
    }

    final all = <String>{};
    for (final layer in OversightLayer.values) {
      final key = _approvedGroupingKey(layer);
      final groups = prefs.getStringList(key) ?? const <String>[];
      all.addAll(groups);
    }
    if (all.isEmpty) {
      all.addAll(_approvedGroupings);
    }
    return all.toList()..sort();
  }

  String _approvedGroupingKey(OversightLayer layer) {
    return 'admin_reality_system_approved_groupings_${_layerKey(layer)}';
  }

  String _layerKey(OversightLayer layer) {
    switch (layer) {
      case OversightLayer.reality:
        return 'reality';
      case OversightLayer.universe:
        return 'universe';
      case OversightLayer.world:
        return 'world';
    }
  }

  String _layerLabel(OversightLayer layer) {
    switch (layer) {
      case OversightLayer.reality:
        return 'Reality';
      case OversightLayer.universe:
        return 'Universe';
      case OversightLayer.world:
        return 'World';
    }
  }

  List<String> _directivesForLayer(OversightLayer layer) {
    switch (layer) {
      case OversightLayer.reality:
        return const [
          'Keep convictions, knowledge, and thought streams aligned before deployment shifts.',
          'Escalate if compliance or health drops below acceptable thresholds.',
          'Ingest approved universe/world groupings and refine taxonomy proposals with human sign-off.',
        ];
      case OversightLayer.universe:
        return const [
          'Track club/community/event creation velocity and watch for inactive pockets.',
          'Validate member-to-event conversion and continuity of social momentum.',
          'Use 3D globe and model check-ins to understand where and how agent usage is concentrating.',
        ];
      case OversightLayer.world:
        return const [
          'Monitor all created users, businesses, and service surfaces for integrity.',
          'Prioritize verified operations and active participant continuity.',
          'Maintain agent-only identity visibility while auditing usage and service handoffs globally.',
        ];
    }
  }

  String _safePrefix(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength);
  }

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String? _resolveAdminActor() {
    try {
      if (GetIt.instance.isRegistered<AdminAuthService>()) {
        final session = GetIt.instance<AdminAuthService>().getCurrentSession();
        final username = session?.username.trim();
        if (username != null && username.isNotEmpty) {
          return 'admin:$username';
        }
      }
    } catch (_) {
      // Best effort only.
    }
    return null;
  }

  String? _resolveAdminUserId() {
    try {
      if (GetIt.instance.isRegistered<SupabaseService>()) {
        final userId = GetIt.instance<SupabaseService>().currentUser?.id.trim();
        if (userId != null && userId.isNotEmpty) {
          return userId;
        }
      }
    } catch (_) {
      // Best effort only.
    }
    return null;
  }

  String _feedbackStatusLabel(_CheckInFeedbackState state) {
    switch (state) {
      case _CheckInFeedbackState.pending:
        return 'Pending feedback';
      case _CheckInFeedbackState.approved:
        return 'Approved for learning';
      case _CheckInFeedbackState.rewritten:
        return 'Rewrite saved for learning';
    }
  }

  String _realityModelDomainLabel(RealityModelDomain domain) {
    switch (domain) {
      case RealityModelDomain.place:
        return 'Place';
      case RealityModelDomain.event:
        return 'Event';
      case RealityModelDomain.community:
        return 'Community';
      case RealityModelDomain.list:
        return 'List';
      case RealityModelDomain.business:
        return 'Business';
      case RealityModelDomain.locality:
        return 'Locality';
    }
  }
}

enum _CheckInFeedbackState {
  pending,
  approved,
  rewritten,
}

class _CheckInEntry {
  const _CheckInEntry({
    required this.id,
    required this.prompt,
    required this.response,
    required this.createdAt,
    this.contract,
    this.evaluation,
    this.trace,
    this.explanation,
    this.approvedResponse,
    this.feedbackState = _CheckInFeedbackState.pending,
  });

  final String id;
  final String prompt;
  final String response;
  final DateTime createdAt;
  final RealityModelContract? contract;
  final RealityModelEvaluation? evaluation;
  final RealityDecisionTrace? trace;
  final RealityModelExplanation? explanation;
  final String? approvedResponse;
  final _CheckInFeedbackState feedbackState;

  _CheckInEntry copyWith({
    String? approvedResponse,
    _CheckInFeedbackState? feedbackState,
  }) {
    return _CheckInEntry(
      id: id,
      prompt: prompt,
      response: response,
      createdAt: createdAt,
      contract: contract,
      evaluation: evaluation,
      trace: trace,
      explanation: explanation,
      approvedResponse: approvedResponse ?? this.approvedResponse,
      feedbackState: feedbackState ?? this.feedbackState,
    );
  }
}
