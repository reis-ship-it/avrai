import 'dart:convert';
import 'dart:async';

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/ui/widgets/reality_model_contract_status_card.dart';
import 'package:avrai_admin_app/ui/widgets/governance_audit_feed_card.dart';
import 'package:avrai_core/models/misc/break_glass_governance_directive.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_core/models/research/governed_autoresearch_models.dart';
import 'package:avrai_admin_app/ui/widgets/realtime_agent_globe_widget.dart';
import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_operations_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/research_activity_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class AdminCommandCenterPage extends StatefulWidget {
  const AdminCommandCenterPage({
    super.key,
    this.governanceService,
    this.opsService,
    this.replaySimulationService,
    this.signatureHealthService,
    this.realityModelStatusService,
    this.researchSupervisor,
    this.headlessOsHost,
    this.showLiveAgentGlobe = true,
  });

  final AdminRuntimeGovernanceService? governanceService;
  final BhamAdminOperationsService? opsService;
  final ReplaySimulationAdminService? replaySimulationService;
  final SignatureHealthAdminService? signatureHealthService;
  final RealityModelStatusService? realityModelStatusService;
  final GovernedAutoresearchSupervisor? researchSupervisor;
  final HeadlessAvraiOsHost? headlessOsHost;
  final bool showLiveAgentGlobe;

  @override
  State<AdminCommandCenterPage> createState() => _AdminCommandCenterPageState();
}

class _AdminCommandCenterPageState extends State<AdminCommandCenterPage> {
  AdminRuntimeGovernanceService? _service;
  BhamAdminOperationsService? _opsService;
  ReplaySimulationAdminService? _replaySimulationService;
  SignatureHealthAdminService? _signatureHealthService;
  RealityModelStatusService? _realityModelStatusService;
  GovernedAutoresearchSupervisor? _researchSupervisor;
  HeadlessAvraiOsHost? _headlessOsHost;
  StreamSubscription<CommunicationsSnapshot>? _communicationsSubscription;
  Timer? _refreshTimer;

  bool _isLoading = true;
  bool _isExportingFieldProofs = false;
  bool _isExportingReplayBundle = false;
  bool _isSharingReplayBundle = false;
  bool _isStagingReplayTrainingCandidate = false;
  bool _isQueueingReplayTrainingIntake = false;
  bool _isRunningControlledValidation = false;
  String? _error;
  DateTime? _lastRefreshAt;
  int _realityModelStatusRefreshSeed = 0;
  GodModeDashboardData? _dashboardData;
  CommunicationsSnapshot? _communicationsSnapshot;
  List<ActiveAIAgentData> _activeAgents = <ActiveAIAgentData>[];
  List<GovernanceInspectionResponse> _recentInspections =
      <GovernanceInspectionResponse>[];
  List<BreakGlassGovernanceReceipt> _recentBreakGlassReceipts =
      <BreakGlassGovernanceReceipt>[];
  AdminHealthSnapshot? _healthSnapshot;
  LaunchGateAdminMetrics? _launchMetrics;
  MeshTrustDiagnosticsSnapshot? _meshTrustSnapshot;
  Ai2AiRendezvousDiagnosticsSnapshot? _rendezvousSnapshot;
  AmbientSocialLearningDiagnosticsSnapshot? _ambientSocialSnapshot;
  ReplaySimulationAdminSnapshot? _replaySnapshot;
  SignatureHealthSnapshot? _signatureHealthSnapshot;
  ReplaySimulationLearningBundleExport? _lastReplayBundleExport;
  ReplaySimulationRealityModelShareReport? _lastReplayShareReport;
  ReplaySimulationTrainingCandidateExport? _lastReplayTrainingCandidateExport;
  ReplaySimulationTrainingIntakeQueueExport?
      _lastReplayTrainingIntakeQueueExport;
  _CommandCenterKernelSnapshot? _kernelSnapshot;
  _CommandCenterResearchSnapshot? _researchSnapshot;
  List<ReplaySimulationAdminEnvironmentDescriptor> _replayEnvironments =
      const <ReplaySimulationAdminEnvironmentDescriptor>[];
  String? _selectedReplayEnvironmentId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _service = widget.governanceService ??
          GetIt.instance<AdminRuntimeGovernanceService>();
      _opsService =
          widget.opsService ?? GetIt.instance<BhamAdminOperationsService>();
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
      _realityModelStatusService = widget.realityModelStatusService ??
          (GetIt.instance.isRegistered<RealityModelStatusService>()
              ? GetIt.instance<RealityModelStatusService>()
              : RealityModelStatusService());
      _researchSupervisor = widget.researchSupervisor;
      _headlessOsHost = widget.headlessOsHost ??
          (GetIt.instance.isRegistered<HeadlessAvraiOsHost>()
              ? GetIt.instance<HeadlessAvraiOsHost>()
              : null);
      _replayEnvironments = _replaySimulationService?.listEnvironments() ??
          const <ReplaySimulationAdminEnvironmentDescriptor>[];
      _selectedReplayEnvironmentId = _resolveReplayEnvironmentId(
        currentSelection: _selectedReplayEnvironmentId,
        environments: _replayEnvironments,
      );
      _communicationsSubscription = _service!.watchCommunications().listen(
        (snapshot) {
          if (!mounted) return;
          setState(() {
            _communicationsSnapshot = snapshot;
          });
        },
      );
      await _load();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _load(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Command center services are unavailable in this environment.';
        _isLoading = false;
      });
    }
  }

  Future<void> _load() async {
    final service = _service;
    final opsService = _opsService;
    final replaySimulationService = _replaySimulationService;
    if (service == null ||
        opsService == null ||
        replaySimulationService == null) {
      return;
    }
    try {
      final dashboard = await service.getDashboardData();
      final platformHealth = <String, int>{
        'ios':
            dashboard.authMix.lastSignInPlatformCounts.totalCounts['ios'] ?? 0,
        'android':
            dashboard.authMix.lastSignInPlatformCounts.totalCounts['android'] ??
                0,
      };
      final results = await Future.wait<dynamic>([
        Future<dynamic>.value(dashboard),
        service.getAllActiveAIAgents(),
        service.listRecentGovernanceInspections(limit: 4),
        service.listRecentBreakGlassReceipts(limit: 4),
        opsService.getHealthSnapshot(platformHealth: platformHealth),
        opsService.getLaunchGateMetrics(platformHealth: platformHealth),
        service.getMeshTrustDiagnosticsSnapshot(),
        service.getAi2AiRendezvousDiagnosticsSnapshot(),
        service.getAmbientSocialLearningDiagnosticsSnapshot(),
        replaySimulationService.getSnapshot(
          environmentId: _selectedReplayEnvironmentId,
        ),
        _signatureHealthService?.getSnapshot() ??
            Future<SignatureHealthSnapshot?>.value(null),
        _loadKernelSnapshot(),
        _loadResearchSnapshot(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboardData = results[0] as GodModeDashboardData;
        _activeAgents = results[1] as List<ActiveAIAgentData>;
        _recentInspections = results[2] as List<GovernanceInspectionResponse>;
        _recentBreakGlassReceipts =
            results[3] as List<BreakGlassGovernanceReceipt>;
        _healthSnapshot = results[4] as AdminHealthSnapshot;
        _launchMetrics = results[5] as LaunchGateAdminMetrics;
        _meshTrustSnapshot = results[6] as MeshTrustDiagnosticsSnapshot;
        _rendezvousSnapshot = results[7] as Ai2AiRendezvousDiagnosticsSnapshot;
        _ambientSocialSnapshot =
            results[8] as AmbientSocialLearningDiagnosticsSnapshot;
        _replaySnapshot = results[9] as ReplaySimulationAdminSnapshot;
        _signatureHealthSnapshot = results[10] as SignatureHealthSnapshot?;
        _kernelSnapshot = results[11] as _CommandCenterKernelSnapshot;
        _researchSnapshot = results[12] as _CommandCenterResearchSnapshot;
        _lastRefreshAt = DateTime.now();
        _realityModelStatusRefreshSeed++;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load command center data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _communicationsSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Admin Command Center',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _load,
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
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final dashboard = _dashboardData;
    final health = _healthSnapshot;
    final streamCount = _communicationsSnapshot?.totalMessages ?? 0;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unified Oversight Surface',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reality, Universe, World, AI2AI mesh, URK kernel governance, and shared research oversight in one operator control plane.',
                  ),
                  if (_lastRefreshAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last refresh: ${_lastRefreshAt!.toLocal()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: (health?.adminAvailable ?? false)
                ? AppColors.electricGreen.withValues(alpha: 0.08)
                : AppColors.warning.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    (health?.adminAvailable ?? false)
                        ? Icons.privacy_tip
                        : Icons.warning_amber_rounded,
                    color: (health?.adminAvailable ?? false)
                        ? AppColors.electricGreen
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (health?.adminAvailable ?? false)
                          ? 'Privacy mode enforced: admin views expose agent identity and aggregate telemetry only. Direct user PII is not rendered in this command center.'
                          : 'Wave 6 launch safety is blocked until admin session, device gate, and internal-use agreement all pass.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip('Active agents', '${_activeAgents.length}'),
              _metricChip('Active users', '${dashboard?.activeUsers ?? 0}'),
              _metricChip('Service communications',
                  '${dashboard?.totalCommunications ?? 0}'),
              _metricChip('Stream records', '$streamCount'),
              _metricChip(
                'Launch gate',
                (health?.adminAvailable ?? false) ? 'pass' : 'blocked',
              ),
              _metricChip(
                'Route health',
                '${((((health?.routeDeliveryHealth ?? 0) * 100)).round())}%',
              ),
              _metricChip(
                'iOS/Android',
                '${dashboard?.authMix.lastSignInPlatformCounts.totalCounts['ios'] ?? 0}/${dashboard?.authMix.lastSignInPlatformCounts.totalCounts['android'] ?? 0}',
              ),
              _metricChip(
                'System health',
                '${(((dashboard?.systemHealth ?? 0) * 100).round())}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAttentionQueueCard(context),
          const SizedBox(height: 12),
          GovernanceAuditFeedCard(
            inspections: _recentInspections,
            receipts: _recentBreakGlassReceipts,
            title: 'Governance Audit Snapshot',
            subtitle:
                'Recent human-visible inspection and break-glass events across governed agent layers.',
            onOpenPressed: () => context.go(AdminRoutePaths.governanceAudit),
            onInspectionTap: (item) => context.go(
              AdminRoutePaths.governanceAuditRuntimeLink(
                runtimeId: item.request.targetRuntimeId,
                stratum: item.request.targetStratum.name,
                artifactType: 'inspection',
              ),
            ),
            onBreakGlassTap: (item) => context.go(
              AdminRoutePaths.governanceAuditRuntimeLink(
                runtimeId: item.directive.targetRuntimeId,
                stratum: item.directive.targetStratum.name,
                artifactType: 'breakGlass',
              ),
            ),
          ),
          const SizedBox(height: 12),
          RealityModelContractStatusCard(
            surfaceLabel: 'Command center',
            service: _realityModelStatusService,
            refreshSeed: _realityModelStatusRefreshSeed,
          ),
          const SizedBox(height: 12),
          _buildOversightCockpitCard(context),
          const SizedBox(height: 12),
          _buildMeshHealthCard(context),
          const SizedBox(height: 12),
          _buildTemporalReplayCard(context),
          const SizedBox(height: 12),
          _buildKernelAndResearchCard(context),
          const SizedBox(height: 12),
          if (widget.showLiveAgentGlobe)
            RealtimeAgentGlobeWidget(
              agents: _activeAgents,
              title: 'Admin Agent Globe (Live)',
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Agent Globe (Live)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Live globe disabled for this environment. Use the AI2AI dashboard when a webview-capable runtime is available.',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (_launchMetrics != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wave 6 launch evidence',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Moderation queue: ${_launchMetrics!.moderationQueueHealth} • Quarantine: ${_launchMetrics!.quarantineCount} • Falsity/reset: ${_launchMetrics!.falsityResetCount} • Break-glass: ${_launchMetrics!.breakGlassCount}',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildNavCard(
            context,
            icon: Icons.visibility_outlined,
            title: 'Governance Audit',
            subtitle:
                'Recent inspections, break-glass receipts, and human oversight history',
            route: AdminRoutePaths.governanceAudit,
          ),
          _buildNavCard(
            context,
            icon: Icons.psychology_alt,
            title: 'Reality Oversight',
            subtitle: 'Convictions, knowledge, thoughts, planning, check-ins',
            route: AdminRoutePaths.realitySystemReality,
          ),
          _buildNavCard(
            context,
            icon: Icons.groups,
            title: 'Universe Oversight',
            subtitle: 'Clubs, communities, events, groupings, globe map',
            route: AdminRoutePaths.realitySystemUniverse,
          ),
          _buildNavCard(
            context,
            icon: Icons.public,
            title: 'World Oversight',
            subtitle: 'Users, businesses, services, groupings, globe map',
            route: AdminRoutePaths.realitySystemWorld,
          ),
          _buildNavCard(
            context,
            icon: Icons.hub_outlined,
            title: 'AI2AI Mesh Dashboard',
            subtitle:
                'Live mesh state, temporal slices, comm health and topology',
            route: AdminRoutePaths.ai2ai,
          ),
          _buildNavCard(
            context,
            icon: Icons.chat_outlined,
            title: 'Communications Oversight',
            subtitle:
                'Support threads, route winners, delivery failures, direct-match outcomes',
            route: AdminRoutePaths.communications,
          ),
          _buildNavCard(
            context,
            icon: Icons.gpp_maybe_outlined,
            title: 'Moderation Operations',
            subtitle:
                'Flagged content, quarantine, rollback/reset, and break-glass timeline',
            route: AdminRoutePaths.moderation,
          ),
          _buildNavCard(
            context,
            icon: Icons.travel_explore,
            title: 'Creation Explorer',
            subtitle:
                'Event/list/community/club explorer with moderation state',
            route: AdminRoutePaths.explorer,
          ),
          _buildNavCard(
            context,
            icon: Icons.feedback_outlined,
            title: 'Beta Feedback Inbox',
            subtitle: 'Pseudonymous tester feedback and launch friction triage',
            route: AdminRoutePaths.betaFeedback,
          ),
          _buildNavCard(
            context,
            icon: Icons.verified_user_outlined,
            title: 'Launch Safety',
            subtitle:
                'Admin availability, route delivery health, quarantine and platform split',
            route: AdminRoutePaths.launchSafety,
          ),
          _buildNavCard(
            context,
            icon: Icons.monitor_heart_outlined,
            title: 'Signature + Source Health',
            subtitle:
                'Live categories for strong, weak, stale, fallback, review, and bundles',
            route: AdminRoutePaths.signatureHealth,
          ),
          _buildNavCard(
            context,
            icon: Icons.settings_suggest,
            title: 'URK Kernel Console',
            subtitle: 'Control-plane governance, thresholds, and policy events',
            route: AdminRoutePaths.urkKernels,
          ),
          _buildNavCard(
            context,
            icon: Icons.science_outlined,
            title: 'Research Center',
            subtitle:
                'Shared admin/reality research feed and status transitions',
            route: AdminRoutePaths.researchCenter,
          ),
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

  Future<void> _runControlledValidation() async {
    final service = _service;
    if (service == null || _isRunningControlledValidation) {
      return;
    }
    setState(() {
      _isRunningControlledValidation = true;
    });
    try {
      final proofs =
          await service.runControlledPrivateMeshFieldAcceptanceValidation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Controlled validation completed with ${proofs.length} proofs.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Controlled validation failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRunningControlledValidation = false;
        });
      }
    }
  }

  Future<void> _exportFieldProofs() async {
    final service = _service;
    if (service == null || _isExportingFieldProofs) {
      return;
    }
    setState(() {
      _isExportingFieldProofs = true;
    });
    try {
      final exported = service.exportRecentFieldValidationProofs(limit: 8);
      final proofCount = _countExportedProofs(exported);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Prepared field-proof export bundle with $proofCount proofs.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Field-proof export failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingFieldProofs = false;
        });
      }
    }
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
      if (!mounted) return;
      setState(() {
        _lastReplayBundleExport = export;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Simulation learning bundle exported to ${export.bundleRoot}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulation bundle export failed: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingReplayBundle = false;
        });
      }
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
      if (!mounted) return;
      setState(() {
        _lastReplayShareReport = report;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bounded reality-model review saved to ${report.reviewJsonPath}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reality-model sharing failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharingReplayBundle = false;
        });
      }
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
      if (!mounted) return;
      setState(() {
        _lastReplayTrainingCandidateExport = export;
        _lastReplayShareReport = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Training candidate manifest saved to ${export.trainingManifestJsonPath}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Training candidate staging failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStagingReplayTrainingCandidate = false;
        });
      }
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
      if (!mounted) return;
      setState(() {
        _lastReplayTrainingIntakeQueueExport = export;
        _lastReplayTrainingCandidateExport = null;
        _lastReplayShareReport = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Training intake queue saved to ${export.queueJsonPath}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Training intake queue failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isQueueingReplayTrainingIntake = false;
        });
      }
    }
  }

  int _countExportedProofs(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final proofs = decoded['proofs'];
        if (proofs is List<dynamic>) {
          return proofs.length;
        }
      }
    } catch (_) {}
    return 0;
  }

  String? _resolveReplayEnvironmentId({
    required String? currentSelection,
    required List<ReplaySimulationAdminEnvironmentDescriptor> environments,
  }) {
    if (currentSelection != null &&
        environments.any(
          (environment) => environment.environmentId == currentSelection,
        )) {
      return currentSelection;
    }
    if (environments.isEmpty) {
      return null;
    }
    return environments.first.environmentId;
  }

  ReplaySimulationAdminEnvironmentDescriptor? _selectedReplayEnvironment() {
    final environmentId = _selectedReplayEnvironmentId;
    if (environmentId == null) {
      return _replayEnvironments.isEmpty ? null : _replayEnvironments.first;
    }
    for (final environment in _replayEnvironments) {
      if (environment.environmentId == environmentId) {
        return environment;
      }
    }
    return _replayEnvironments.isEmpty ? null : _replayEnvironments.first;
  }

  Future<void> _onReplayEnvironmentSelected(String? environmentId) async {
    if (environmentId == null ||
        environmentId == _selectedReplayEnvironmentId) {
      return;
    }
    setState(() {
      _selectedReplayEnvironmentId = environmentId;
      _lastReplayBundleExport = null;
      _lastReplayShareReport = null;
      _lastReplayTrainingCandidateExport = null;
      _lastReplayTrainingIntakeQueueExport = null;
      _isLoading = true;
    });
    await _load();
  }

  Future<_CommandCenterKernelSnapshot> _loadKernelSnapshot() async {
    final host = _headlessOsHost;
    if (host == null) {
      return const _CommandCenterKernelSnapshot(
        available: false,
        started: false,
        startedSummary: 'Headless AVRAI OS host is not registered.',
      );
    }
    try {
      final state = await host.start();
      final reports = await host.healthCheck();
      final healthyCount = reports
          .where((report) => report.status == KernelHealthStatus.healthy)
          .length;
      final headlessReadyCount =
          reports.where((report) => report.headlessReady).length;
      final authoritativeCount = reports
          .where(
            (report) =>
                report.authorityLevel == KernelAuthorityLevel.authoritative,
          )
          .length;
      return _CommandCenterKernelSnapshot(
        available: true,
        started: state.started,
        startedSummary: state.summary,
        reports: reports,
        healthyCount: healthyCount,
        headlessReadyCount: headlessReadyCount,
        authoritativeCount: authoritativeCount,
      );
    } catch (error) {
      return _CommandCenterKernelSnapshot(
        available: false,
        started: false,
        startedSummary: 'Headless AVRAI OS unavailable: $error',
      );
    }
  }

  Future<_CommandCenterResearchSnapshot> _loadResearchSnapshot() async {
    try {
      final supervisor =
          _researchSupervisor ?? await _resolveResearchSupervisor();
      final runs = await supervisor.listRuns();
      final alerts = await supervisor.listAlerts();
      final runningCount = runs
          .where(
              (run) => run.lifecycleState == ResearchRunLifecycleState.running)
          .length;
      final queuedCount = runs
          .where(
              (run) => run.lifecycleState == ResearchRunLifecycleState.queued)
          .length;
      final reviewCount = runs
          .where(
              (run) => run.lifecycleState == ResearchRunLifecycleState.review)
          .length;
      final criticalCount = alerts
          .where((alert) => alert.severity == ResearchAlertSeverity.critical)
          .length;
      return _CommandCenterResearchSnapshot(
        available: true,
        runCount: runs.length,
        runningCount: runningCount,
        queuedCount: queuedCount,
        reviewCount: reviewCount,
        alertCount: alerts.length,
        criticalAlertCount: criticalCount,
        topRun: runs.isEmpty ? null : runs.first,
        topAlert: alerts.isEmpty ? null : alerts.first,
      );
    } catch (error) {
      return _CommandCenterResearchSnapshot(
        available: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<GovernedAutoresearchSupervisor> _resolveResearchSupervisor() async {
    final prefs = GetIt.instance.isRegistered<SharedPreferencesCompat>()
        ? GetIt.instance<SharedPreferencesCompat>()
        : await SharedPreferencesCompat.getInstance();
    final resolution =
        await GovernedAutoresearchSupervisorFactory.createDefault(
      prefs: prefs,
    );
    return resolution.service;
  }

  Widget _buildOversightCockpitCard(BuildContext context) {
    final dashboard = _dashboardData;
    final health = _healthSnapshot;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oversight Cockpit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Reality, Universe, and World oversight share one operator launch surface. Use the cards below for fast lane selection, then drill into the dedicated page for detailed evidence and intervention.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip(
                  'Reality',
                  '${(((dashboard?.systemHealth ?? 0) * 100)).round()}% health',
                ),
                _metricChip(
                  'Universe',
                  '${_activeAgents.length} active agents',
                ),
                _metricChip(
                  'World',
                  '${dashboard?.activeUsers ?? 0} active users',
                ),
                _metricChip(
                  'Businesses',
                  '${dashboard?.totalBusinessAccounts ?? 0}',
                ),
                _metricChip(
                  'Launch gate',
                  (health?.adminAvailable ?? false) ? 'pass' : 'blocked',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go(AdminRoutePaths.realitySystemReality),
                  icon: const Icon(Icons.psychology_alt),
                  label: const Text('Reality'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go(AdminRoutePaths.realitySystemUniverse),
                  icon: const Icon(Icons.groups),
                  label: const Text('Universe'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go(AdminRoutePaths.realitySystemWorld),
                  icon: const Icon(Icons.public),
                  label: const Text('World'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionQueueCard(BuildContext context) {
    final items = _buildAttentionItems();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Needs Attention',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'One shared operator queue synthesized from launch safety, mesh, replay, kernel, and governed research state.',
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'No urgent operator actions are currently surfaced.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.icon,
                              size: 18,
                              color: item.color,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.detail,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (item.route != null && item.actionLabel != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: OutlinedButton.icon(
                              onPressed: () => context.go(item.route!),
                              icon:
                                  Icon(item.actionIcon ?? Icons.chevron_right),
                              label: Text(item.actionLabel!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  List<_CommandCenterAttentionItem> _buildAttentionItems() {
    final items = <_CommandCenterAttentionItem>[];
    final health = _healthSnapshot;
    final mesh = _meshTrustSnapshot;
    final replay = _replaySnapshot;
    final learningOutcome = _selectedReplayLearningOutcome();
    final kernel = _kernelSnapshot;
    final research = _researchSnapshot;

    if (health != null && !health.adminAvailable) {
      items.add(
        _CommandCenterAttentionItem(
          title: 'Launch safety is blocked',
          detail:
              'Admin availability, device approval, or internal-use gating is preventing safe launch posture.',
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          route: AdminRoutePaths.launchSafetyFocusLink(
            focus: 'launch_gate',
            attention: 'launch_safety_blocked',
          ),
          actionLabel: 'Open launch safety',
          actionIcon: Icons.verified_user_outlined,
        ),
      );
    }
    if (mesh != null && mesh.rejectedAnnounceCount > 0) {
      items.add(
        _CommandCenterAttentionItem(
          title: 'Rejected mesh announces detected',
          detail:
              '${mesh.rejectedAnnounceCount} announces were rejected and may need credential or route review.',
          icon: Icons.hub_outlined,
          color: AppColors.warning,
          route: AdminRoutePaths.ai2AiFocusLink(
            focus: 'mesh_rejects',
            attention: 'mesh_rejected_announces',
          ),
          actionLabel: 'Open AI2AI lane',
          actionIcon: Icons.hub_outlined,
        ),
      );
    }
    if (replay != null && replay.contradictions.isNotEmpty) {
      final lead = replay.localityOverlays.isEmpty
          ? null
          : replay.localityOverlays.first;
      items.add(
        _CommandCenterAttentionItem(
          title: 'Replay contradiction hotspot is active',
          detail: lead == null
              ? '${replay.contradictions.length} contradictions need review.'
              : '${replay.contradictions.length} contradictions are led by ${lead.displayName} (${lead.attentionBand}).',
          icon: Icons.travel_explore,
          color: AppColors.warning,
          route: AdminRoutePaths.realitySystemRealityFocusLink(
            focus: 'contradictions',
            attention: 'replay_contradiction_hotspot',
          ),
          actionLabel: 'Open reality lane',
          actionIcon: Icons.psychology_alt,
        ),
      );
    }
    final supervisorFeedback = learningOutcome?.supervisorFeedbackSummary;
    final boundedReviewCandidate = _selectedReplayBoundedReviewCandidate();
    if (learningOutcome != null && supervisorFeedback != null) {
      items.add(
        _buildSupervisorFeedbackAttentionItem(
          learningOutcome: learningOutcome,
          feedback: supervisorFeedback,
        ),
      );
    }
    if (boundedReviewCandidate != null) {
      items.add(
        _buildBoundedReviewCandidateAttentionItem(
          candidate: boundedReviewCandidate,
        ),
      );
    }
    if (kernel != null && !kernel.available) {
      items.add(
        _CommandCenterAttentionItem(
          title: 'Headless kernel is unavailable',
          detail: kernel.startedSummary,
          icon: Icons.settings_suggest,
          color: AppColors.error,
          route: AdminRoutePaths.urkKernelsFocusLink(
            view: 'governance',
            focus: 'kernel_availability',
            attention: 'headless_kernel_unavailable',
          ),
          actionLabel: 'Open kernel console',
          actionIcon: Icons.settings_suggest,
        ),
      );
    }
    if (research != null) {
      if (!research.available) {
        items.add(
          _CommandCenterAttentionItem(
            title: 'Research backend is unavailable',
            detail: research.errorMessage ??
                'Governed research status could not be loaded.',
            icon: Icons.science_outlined,
            color: AppColors.warning,
            route: AdminRoutePaths.researchCenterFocusLink(
              focus: 'backend',
              attention: 'research_backend_unavailable',
            ),
            actionLabel: 'Open research center',
            actionIcon: Icons.science_outlined,
          ),
        );
      } else if (research.criticalAlertCount > 0) {
        items.add(
          _CommandCenterAttentionItem(
            title: 'Critical sandbox research alert',
            detail:
                '${research.criticalAlertCount} critical alerts are active${research.topAlert == null ? '' : ': ${research.topAlert!.title}.'}',
            icon: Icons.science_outlined,
            color: AppColors.error,
            route: AdminRoutePaths.researchCenterFocusLink(
              focus: 'alerts',
              attention: 'research_critical_alert',
            ),
            actionLabel: 'Review research alerts',
            actionIcon: Icons.science_outlined,
          ),
        );
      }
    }

    return items.take(5).toList(growable: false);
  }

  _CommandCenterAttentionItem _buildSupervisorFeedbackAttentionItem({
    required SignatureHealthLearningOutcomeItem learningOutcome,
    required SignatureHealthSupervisorFeedbackSummary feedback,
  }) {
    final recommendation = feedback.boundedRecommendation;
    final cityCode = learningOutcome.cityCode.toUpperCase();
    switch (recommendation) {
      case 'prefer_similar_reality_model_learning_candidates':
        return _CommandCenterAttentionItem(
          title: 'Supervisor sees a reusable simulation pattern',
          detail:
              '$cityCode learning outcome is strong enough to reuse as bounded guidance for similar simulation candidates. Review the lab before broadening retries.',
          icon: Icons.auto_awesome,
          color: AppColors.warning,
          route: AdminRoutePaths.worldSimulationLab,
          actionLabel: 'Open world simulation lab',
          actionIcon: Icons.science_outlined,
        );
      case 'allow_bounded_retry_with_operator_visibility':
        return _CommandCenterAttentionItem(
          title: 'Supervisor allows a bounded simulation retry',
          detail:
              '$cityCode learning outcome supports another operator-visible iteration. Retry posture stays bounded and should remain review-first.',
          icon: Icons.refresh,
          color: AppColors.warning,
          route: AdminRoutePaths.worldSimulationLab,
          actionLabel: 'Open world simulation lab',
          actionIcon: Icons.science_outlined,
        );
      case 'review_before_similar_candidate_scheduling':
        return _CommandCenterAttentionItem(
          title: 'Supervisor wants review before similar scheduling',
          detail:
              '$cityCode learning outcome is not strong enough for similar-candidate scheduling without another operator pass.',
          icon: Icons.pending_actions,
          color: AppColors.warning,
          route: AdminRoutePaths.worldSimulationLab,
          actionLabel: 'Review simulation lab',
          actionIcon: Icons.science_outlined,
        );
      default:
        return _CommandCenterAttentionItem(
          title: 'Supervisor feedback is waiting on operator review',
          detail:
              '$cityCode learning outcome remains bounded. Review the simulation lab before any further retry or propagation posture changes.',
          icon: Icons.hourglass_top,
          color: AppColors.warning,
          route: AdminRoutePaths.worldSimulationLab,
          actionLabel: 'Open world simulation lab',
          actionIcon: Icons.science_outlined,
        );
    }
  }

  _CommandCenterAttentionItem _buildBoundedReviewCandidateAttentionItem({
    required SignatureHealthBoundedReviewCandidate candidate,
  }) {
    final cityCode = candidate.cityCode.toUpperCase();
    final outcomeLabel =
        _boundedReviewOutcomeLabel(candidate.latestOutcomeDisposition);
    final rerunStatus = _boundedReviewRerunStatusLabel(
      candidate.latestRerunRequestStatus,
      candidate.latestRerunJobStatus,
    );
    return _CommandCenterAttentionItem(
      title: 'Simulation target is ready for bounded review',
      detail:
          '$cityCode ${candidate.targetLabel} is marked as a bounded-review candidate. Latest outcome: $outcomeLabel.${rerunStatus == null ? '' : ' Latest rerun: $rerunStatus.'}',
      icon: Icons.rule_folder_outlined,
      color: AppColors.warning,
      route: AdminRoutePaths.realitySystemRealityFocusLink(
        focus: candidate.environmentId,
        attention:
            'bounded_review_candidate:${candidate.variantId ?? 'base_run'}',
      ),
      actionLabel: 'Open bounded review',
      actionIcon: Icons.psychology_alt,
    );
  }

  Widget _buildMeshHealthCard(BuildContext context) {
    final mesh = _meshTrustSnapshot;
    final rendezvous = _rendezvousSnapshot;
    final ambient = _ambientSocialSnapshot;
    if (mesh == null || rendezvous == null || ambient == null) {
      return const SizedBox.shrink();
    }

    final blockedReason = (rendezvous.lastBlockedReason ?? '').trim().isEmpty
        ? 'none'
        : rendezvous.lastBlockedReason!.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI2AI Mesh Health',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Private-mesh trust, rendezvous release posture, and ambient-learning activity summarized in one operator snapshot.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip(
                  'Trusted announce',
                  mesh.trustedActiveAnnounceCount.toString(),
                ),
                _metricChip(
                  'Rejected announce',
                  mesh.rejectedAnnounceCount.toString(),
                ),
                _metricChip(
                  'Replay triggers',
                  mesh.trustedReplayTriggerCount.toString(),
                ),
                _metricChip(
                  'Active rendezvous',
                  rendezvous.activeRendezvousCount.toString(),
                ),
                _metricChip(
                  'Peer applied',
                  rendezvous.peerAppliedCount.toString(),
                ),
                _metricChip(
                  'Ambient promotions',
                  ambient.confirmedInteractionPromotionCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Last blocked reason: $blockedReason',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Latest nearby peers: ${ambient.latestNearbyPeerCount} • Confirmed interactive peers: ${ambient.latestConfirmedInteractivePeerCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.ai2ai),
                  icon: const Icon(Icons.hub_outlined),
                  label: const Text('Open AI2AI'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.communications),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Open comms'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.urkKernels),
                  icon: const Icon(Icons.settings_suggest),
                  label: const Text('Open URK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemporalReplayCard(BuildContext context) {
    final replay = _replaySnapshot;
    if (replay == null) {
      return const SizedBox.shrink();
    }
    final selectedEnvironment = _selectedReplayEnvironment();

    final leadScenario =
        replay.scenarios.isEmpty ? null : replay.scenarios.first;
    final leadOverlay =
        replay.localityOverlays.isEmpty ? null : replay.localityOverlays.first;
    final foundation = replay.foundation;
    final readiness = replay.learningReadiness;
    final activeKernelCount = foundation.activeKernelCount;
    final learningOutcome = _selectedReplayLearningOutcome();
    final upwardLearningItem = _selectedReplayUpwardLearningItem();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulation Snapshot',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_replayEnvironments.length > 1) ...[
              DropdownButtonFormField<String>(
                key: const Key('replayEnvironmentSelector'),
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
              'Simulation environment ${selectedEnvironment?.displayName ?? replay.environmentId} (${replay.cityCode.toUpperCase()} ${replay.replayYear}) is staged for contradiction review, truth receipts, and locality attention overlays.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip(
                  'Environments',
                  _replayEnvironments.length.toString(),
                ),
                _metricChip(
                  'Scenario packets',
                  replay.scenarios.length.toString(),
                ),
                _metricChip(
                  'Comparisons',
                  replay.comparisons.length.toString(),
                ),
                _metricChip(
                  'Truth receipts',
                  replay.receipts.length.toString(),
                ),
                _metricChip(
                  'Contradictions',
                  replay.contradictions.length.toString(),
                ),
                _metricChip(
                  'Locality overlays',
                  replay.localityOverlays.length.toString(),
                ),
                _metricChip(
                  'Training grade',
                  readiness.trainingGrade,
                ),
                _metricChip(
                  'Kernel states',
                  '$activeKernelCount/${foundation.kernelStates.length}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Simulation basis: ${foundation.simulationMode}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              foundation.intakeFlowRefs.isEmpty
                  ? 'No explicit intake flow refs were attached to this environment.'
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
              readiness.shareWithRealityModelAllowed
                  ? 'This simulation is strong enough to package as bounded reality-model evidence/training review.'
                  : 'This simulation remains local-review-first and should not be shared with the reality model until the listed gaps are addressed.',
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
            if (leadScenario != null) ...[
              const SizedBox(height: 12),
              Text(
                'Lead scenario: ${leadScenario.name}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                leadScenario.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (leadOverlay != null) ...[
              const SizedBox(height: 12),
              Text(
                'Highest-attention locality: ${leadOverlay.displayName} (${leadOverlay.localityCode})',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Pressure ${leadOverlay.pressureBand} • Attention ${leadOverlay.attentionBand} • Sensitivity ${leadOverlay.branchSensitivity.toStringAsFixed(2)} • Contradictions ${leadOverlay.contradictionCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (leadOverlay.primarySignals.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Signals: ${leadOverlay.primarySignals.join(' • ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
            if (_lastReplayBundleExport != null) ...[
              const SizedBox(height: 12),
              Text(
                'Local output: ${_lastReplayBundleExport!.bundleRoot}',
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
                  'A real-world upward conviction for ${upwardLearningItem.cityCode.toUpperCase()} completed bounded reality-model validation and reopened governed lower-tier follow-on lanes.',
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
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go(AdminRoutePaths.realitySystemReality),
                  icon: const Icon(Icons.psychology_alt),
                  label: const Text('Reality lane'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.researchCenter),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Research lane'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.ai2ai),
                  icon: const Icon(Icons.hub_outlined),
                  label: const Text('Mesh context'),
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

  SignatureHealthBoundedReviewCandidate?
      _selectedReplayBoundedReviewCandidate() {
    final snapshot = _signatureHealthSnapshot;
    final replay = _replaySnapshot;
    if (snapshot == null || replay == null) {
      return null;
    }
    for (final candidate in snapshot.boundedReviewCandidates) {
      if (candidate.environmentId == replay.environmentId) {
        return candidate;
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

  Widget _buildKernelAndResearchCard(BuildContext context) {
    final kernel = _kernelSnapshot;
    final research = _researchSnapshot;
    final proofCount = <String>{
      ...?_meshTrustSnapshot?.recentProofs.map((proof) => proof.scenario.name),
      ...?_rendezvousSnapshot?.recentProofs.map((proof) => proof.scenario.name),
    }.length;
    final headlessRunCount =
        ((_meshTrustSnapshot?.recentHeadlessRuns.length ?? 0) +
            (_rendezvousSnapshot?.recentHeadlessRuns.length ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kernel + Sandbox Research',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Headless kernel readiness, recent controlled proof activity, and governed sandbox research status in one command-center summary.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip(
                  'Kernel health',
                  kernel == null
                      ? 'loading'
                      : kernel.available
                          ? '${kernel.healthyCount}/${kernel.reports.length} healthy'
                          : 'unavailable',
                ),
                _metricChip(
                  'Headless ready',
                  kernel == null
                      ? 'loading'
                      : kernel.available
                          ? '${kernel.headlessReadyCount}/${kernel.reports.length}'
                          : '0',
                ),
                _metricChip(
                  'Authoritative',
                  kernel == null
                      ? 'loading'
                      : kernel.available
                          ? kernel.authoritativeCount.toString()
                          : '0',
                ),
                _metricChip('Field proofs', proofCount.toString()),
                _metricChip('Headless runs', headlessRunCount.toString()),
                _metricChip(
                  'Research runs',
                  research == null
                      ? 'loading'
                      : research.available
                          ? research.runCount.toString()
                          : 'unavailable',
                ),
                _metricChip(
                  'Critical alerts',
                  research == null
                      ? 'loading'
                      : research.available
                          ? research.criticalAlertCount.toString()
                          : '0',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (kernel != null)
              Text(
                kernel.startedSummary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kernel.available
                          ? AppColors.textSecondary
                          : AppColors.warning,
                    ),
              ),
            if (research != null) ...[
              const SizedBox(height: 6),
              Text(
                research.available
                    ? _buildResearchSummaryText(research)
                    : 'Research backend unavailable: ${research.errorMessage}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: research.available
                          ? AppColors.textSecondary
                          : AppColors.warning,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunningControlledValidation
                      ? null
                      : _runControlledValidation,
                  icon: _isRunningControlledValidation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(
                    _isRunningControlledValidation
                        ? 'Running validation'
                        : 'Run controlled validation',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _isExportingFieldProofs ? null : _exportFieldProofs,
                  icon: _isExportingFieldProofs
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(
                    _isExportingFieldProofs
                        ? 'Exporting proofs'
                        : 'Export field proofs',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.urkKernels),
                  icon: const Icon(Icons.settings_suggest),
                  label: const Text('Kernel console'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.researchCenter),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Research center'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.ai2ai),
                  icon: const Icon(Icons.hub_outlined),
                  label: const Text('Proof lane'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildResearchSummaryText(_CommandCenterResearchSnapshot research) {
    final topRun = research.topRun;
    final topAlert = research.topAlert;
    final parts = <String>[
      '${research.runningCount} running',
      '${research.queuedCount} queued',
      '${research.reviewCount} in review',
    ];
    if (topRun != null) {
      parts.add('Lead run: ${topRun.title}');
    }
    if (topAlert != null) {
      parts.add('Top alert: ${topAlert.title}');
    }
    return parts.join(' • ');
  }

  Widget _buildNavCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      ),
    );
  }
}

class _CommandCenterKernelSnapshot {
  const _CommandCenterKernelSnapshot({
    required this.available,
    required this.started,
    required this.startedSummary,
    this.reports = const <KernelHealthReport>[],
    this.healthyCount = 0,
    this.headlessReadyCount = 0,
    this.authoritativeCount = 0,
  });

  final bool available;
  final bool started;
  final String startedSummary;
  final List<KernelHealthReport> reports;
  final int healthyCount;
  final int headlessReadyCount;
  final int authoritativeCount;
}

class _CommandCenterResearchSnapshot {
  const _CommandCenterResearchSnapshot({
    required this.available,
    this.runCount = 0,
    this.runningCount = 0,
    this.queuedCount = 0,
    this.reviewCount = 0,
    this.alertCount = 0,
    this.criticalAlertCount = 0,
    this.topRun,
    this.topAlert,
    this.errorMessage,
  });

  final bool available;
  final int runCount;
  final int runningCount;
  final int queuedCount;
  final int reviewCount;
  final int alertCount;
  final int criticalAlertCount;
  final ResearchRunState? topRun;
  final ResearchAlert? topAlert;
  final String? errorMessage;
}

class _CommandCenterAttentionItem {
  const _CommandCenterAttentionItem({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    this.route,
    this.actionLabel,
    this.actionIcon,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final String? route;
  final String? actionLabel;
  final IconData? actionIcon;
}
