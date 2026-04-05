import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_runtime_os/monitoring/connection_monitor.dart';
import 'package:avrai_runtime_os/monitoring/network_analytics.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_temporal_state.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_transport_retention_telemetry_store.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:avrai_admin_app/theme/app_theme.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/realtime_agent_globe_widget.dart';
import 'package:avrai_admin_app/ui/widgets/recommendation_why_preview_card.dart';
import 'package:avrai_admin_app/ui/widgets/admin_collaborative_activity_widget.dart';
import 'package:avrai_admin_app/ui/widgets/connections_list.dart';
import 'package:avrai_admin_app/ui/widgets/forecast_kernel_strength_card.dart';
import 'package:avrai_admin_app/ui/widgets/security_immune_system_card.dart';
import 'package:avrai_admin_app/ui/widgets/learning_metrics_chart.dart';
import 'package:avrai_admin_app/ui/widgets/locality_kernel_diagnostics_card.dart';
import 'package:avrai_admin_app/ui/widgets/mesh_trust_diagnostics_panel.dart';
import 'package:avrai_admin_app/ui/widgets/network_3d_visualization_widget.dart';
import 'package:avrai_admin_app/ui/widgets/network_health_gauge.dart';
import 'package:avrai_admin_app/ui/widgets/performance_issues_list.dart';
import 'package:avrai_admin_app/ui/widgets/planning_truth_surface_card.dart';
import 'package:avrai_admin_app/ui/widgets/privacy_compliance_card.dart';
import 'package:avrai_admin_app/ui/widgets/temporal_kernel_diagnostics_card.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

/// Admin Dashboard for AI2AI Network Monitoring
/// Displays network health, connections, learning metrics, privacy, and performance.
class AI2AIAdminDashboard extends StatefulWidget {
  const AI2AIAdminDashboard({
    super.key,
    this.useThreeJsVisualizations = true,
    this.initialFocus,
    this.initialAttention,
  });

  final bool useThreeJsVisualizations;
  final String? initialFocus;
  final String? initialAttention;

  @override
  State<AI2AIAdminDashboard> createState() => _AI2AIAdminDashboardState();
}

class _AI2AIAdminDashboardState extends State<AI2AIAdminDashboard> {
  NetworkAnalytics? _networkAnalytics;
  ConnectionMonitor? _connectionMonitor;
  AdminRuntimeGovernanceService? _runtimeGovernanceService;
  AtomicClockService? _atomicClockService;
  HeadlessAvraiOsHost? _headlessOsHost;

  StreamSubscription<NetworkHealthReport>? _healthReportSubscription;
  StreamSubscription<ActiveConnectionsOverview>? _connectionsSubscription;
  StreamSubscription<RealTimeMetrics>? _realTimeMetricsSubscription;
  StreamSubscription<CommunicationsSnapshot>? _communicationsSubscription;
  StreamSubscription<MeshTrustDiagnosticsSnapshot>? _meshTrustSubscription;
  StreamSubscription<Ai2AiRendezvousDiagnosticsSnapshot>?
      _rendezvousTrustSubscription;
  StreamSubscription<AmbientSocialLearningDiagnosticsSnapshot>?
      _ambientSocialTrustSubscription;
  StreamSubscription<Ai2AiTransportRetentionSnapshot>?
      _transportRetentionSubscription;
  StreamSubscription<ArtifactLifecycleVisibilitySnapshot>?
      _artifactLifecycleSubscription;
  Timer? _agentRefreshTimer;
  Timer? _meshTickTimer;

  NetworkHealthReport? _healthReport;
  ActiveConnectionsOverview? _connectionsOverview;
  RealTimeMetrics? _realTimeMetrics;
  CommunicationsSnapshot? _communicationsSnapshot;
  MeshTrustDiagnosticsSnapshot? _meshTrustSnapshot;
  Ai2AiRendezvousDiagnosticsSnapshot? _rendezvousTrustSnapshot;
  AmbientSocialLearningDiagnosticsSnapshot? _ambientSocialSnapshot;
  Ai2AiTransportRetentionSnapshot? _transportRetentionSnapshot;
  ArtifactLifecycleVisibilitySnapshot? _artifactLifecycleSnapshot;
  List<ActiveAIAgentData> _activeAgents = <ActiveAIAgentData>[];
  List<GlobeConnectionLink> _topologyLinks = <GlobeConnectionLink>[];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _headlessOsError;
  DateTime? _lastUpdate;
  bool _isStreamConnected = false;
  AtomicTimestamp? _latestAtomicTimestamp;
  MeshTemporalState _meshTemporalState = MeshTemporalState.alignment;
  double _meshTemporalProgress = 0.0;
  // TODO(admin-backend): Move temporal state tracking/lockstep source-of-truth
  // to internal backend service once available. Current implementation is
  // client-side runtime state only (non-persistent).
  String? _lastGlobeTemporalState;
  double? _lastGlobeTemporalProgress;
  DateTime? _lastGlobeTemporalRenderedAt;
  HeadlessAvraiOsHostState? _headlessOsState;
  List<KernelHealthReport> _kernelHealthReports = const <KernelHealthReport>[];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = GetIt.instance<SharedPreferencesCompat>();
      _networkAnalytics = NetworkAnalytics(prefs: prefs);
      _connectionMonitor = ConnectionMonitor(prefs: prefs);
      if (GetIt.instance.isRegistered<AdminRuntimeGovernanceService>()) {
        _runtimeGovernanceService =
            GetIt.instance<AdminRuntimeGovernanceService>();
      }
      if (GetIt.instance.isRegistered<AtomicClockService>()) {
        _atomicClockService = GetIt.instance<AtomicClockService>();
      }
      if (GetIt.instance.isRegistered<HeadlessAvraiOsHost>()) {
        _headlessOsHost = GetIt.instance<HeadlessAvraiOsHost>();
      }
      _setupStreams();
      await _refreshHeadlessKernelHealth();
      await _refreshActiveAgents();
      _setupAgentRefreshTimer();
      _setupMeshTickTimer();
    } catch (e) {
      developer.log('Error initializing services: $e',
          name: 'AI2AIAdminDashboard');
      setState(() {
        _errorMessage = 'Failed to initialize services: $e';
        _isLoading = false;
      });
    }
  }

  void _setupStreams() {
    if (_networkAnalytics == null || _connectionMonitor == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isStreamConnected = true;
    });

    _healthReportSubscription = _networkAnalytics!.streamNetworkHealth().listen(
      (report) {
        setState(() {
          _healthReport = report;
          _lastUpdate = DateTime.now();
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        developer.log('Error in health report stream: $error',
            name: 'AI2AIAdminDashboard');
        setState(() {
          _errorMessage = 'Error loading network health: $error';
          _isLoading = false;
          _isRefreshing = false;
        });
      },
    );

    _connectionsSubscription =
        _connectionMonitor!.streamActiveConnections().listen(
      (overview) {
        setState(() {
          _connectionsOverview = overview;
          _lastUpdate = DateTime.now();
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        developer.log('Error in connections stream: $error',
            name: 'AI2AIAdminDashboard');
        setState(() {
          _errorMessage = 'Error loading connections: $error';
          _isLoading = false;
          _isRefreshing = false;
        });
      },
    );

    _realTimeMetricsSubscription =
        _networkAnalytics!.streamRealTimeMetrics().listen(
      (metrics) {
        setState(() {
          _realTimeMetrics = metrics;
          _lastUpdate = DateTime.now();
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        developer.log('Error in real-time metrics stream: $error',
            name: 'AI2AIAdminDashboard');
        setState(() {
          _errorMessage = 'Error loading real-time metrics: $error';
          _isLoading = false;
          _isRefreshing = false;
        });
      },
    );

    if (_runtimeGovernanceService != null) {
      _communicationsSubscription =
          _runtimeGovernanceService!.watchCommunications().listen(
        (snapshot) {
          setState(() {
            _communicationsSnapshot = snapshot;
            _lastUpdate = DateTime.now();
          });
        },
        onError: (error) {
          developer.log('Error in communications stream: $error',
              name: 'AI2AIAdminDashboard');
        },
      );
      _meshTrustSubscription =
          _runtimeGovernanceService!.watchMeshTrustDiagnostics().listen(
        (snapshot) {
          setState(() {
            _meshTrustSnapshot = snapshot;
            _lastUpdate = DateTime.now();
          });
        },
        onError: (error) {
          developer.log('Error in mesh trust stream: $error',
              name: 'AI2AIAdminDashboard');
        },
      );
      _rendezvousTrustSubscription =
          _runtimeGovernanceService!.watchAi2AiRendezvousDiagnostics().listen(
        (snapshot) {
          setState(() {
            _rendezvousTrustSnapshot = snapshot;
            _lastUpdate = DateTime.now();
          });
        },
        onError: (error) {
          developer.log('Error in rendezvous trust stream: $error',
              name: 'AI2AIAdminDashboard');
        },
      );
      _ambientSocialTrustSubscription = _runtimeGovernanceService!
          .watchAmbientSocialLearningDiagnostics()
          .listen(
        (snapshot) {
          setState(() {
            _ambientSocialSnapshot = snapshot;
            _lastUpdate = DateTime.now();
          });
        },
        onError: (error) {
          developer.log('Error in ambient social trust stream: $error',
              name: 'AI2AIAdminDashboard');
        },
      );
      _transportRetentionSubscription = _runtimeGovernanceService!
          .watchAi2AiTransportRetentionDiagnostics()
          .listen(
        (snapshot) {
          setState(() {
            _transportRetentionSnapshot = snapshot;
            _lastUpdate = DateTime.now();
          });
        },
        onError: (error) {
          developer.log('Error in transport retention stream: $error',
              name: 'AI2AIAdminDashboard');
        },
      );
      _artifactLifecycleSubscription = _runtimeGovernanceService!
          .watchArtifactLifecycleVisibilityDiagnostics()
          .listen(
        (snapshot) {
          setState(() {
            _artifactLifecycleSnapshot = snapshot;
            _lastUpdate = DateTime.now();
          });
        },
        onError: (error) {
          developer.log('Error in lifecycle visibility stream: $error',
              name: 'AI2AIAdminDashboard');
        },
      );
    }
  }

  void _setupAgentRefreshTimer() {
    _agentRefreshTimer?.cancel();
    _agentRefreshTimer = Timer.periodic(
        const Duration(seconds: 20), (_) => _refreshActiveAgents());
  }

  void _setupMeshTickTimer() {
    _meshTickTimer?.cancel();
    _updateMeshTemporalState();
    _meshTickTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => _updateMeshTemporalState());
  }

  Future<void> _updateMeshTemporalState() async {
    final atomicClock = _atomicClockService;
    if (atomicClock == null) {
      return;
    }

    try {
      final timestamp = await atomicClock.getAtomicTimestamp();
      final temporalState = QuantumTemporalStateGenerator.generate(timestamp);
      final phase = temporalState.phaseState;
      if (phase.length < 2) {
        return;
      }

      final angle = _normalizedAngle(phase[0], phase[1]);
      final nextState = _stateForAngle(angle);
      final stateStart = _stateStart(nextState);
      final progress = ((angle - stateStart) / (math.pi / 2)).clamp(0.0, 1.0);

      if (!mounted) return;
      setState(() {
        _latestAtomicTimestamp = timestamp;
        _meshTemporalState = nextState;
        _meshTemporalProgress = progress.toDouble();
      });
    } catch (e) {
      developer.log('Error updating mesh temporal state: $e',
          name: 'AI2AIAdminDashboard');
    }
  }

  Future<void> _refreshActiveAgents() async {
    final service = _runtimeGovernanceService;
    if (service == null) {
      return;
    }

    try {
      final agents = await service.getAllActiveAIAgents();
      if (!mounted) return;
      setState(() {
        _activeAgents = agents;
        _topologyLinks = _buildTopologyLinks(agents);
      });
    } catch (e) {
      developer.log('Error loading active AI agents: $e',
          name: 'AI2AIAdminDashboard');
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      await _refreshHeadlessKernelHealth();
      if (_networkAnalytics != null && _connectionMonitor != null) {
        final healthReport = await _networkAnalytics!.analyzeNetworkHealth();
        final connectionsOverview =
            await _connectionMonitor!.getActiveConnectionsOverview();
        final realTimeMetrics =
            await _networkAnalytics!.collectRealTimeMetrics();

        await _refreshActiveAgents();

        setState(() {
          _healthReport = healthReport;
          _connectionsOverview = connectionsOverview;
          _realTimeMetrics = realTimeMetrics;
          _lastUpdate = DateTime.now();
          _isRefreshing = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      developer.log('Error refreshing dashboard: $e',
          name: 'AI2AIAdminDashboard');
      setState(() {
        _errorMessage = 'Error refreshing: $e';
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshHeadlessKernelHealth() async {
    final host = _headlessOsHost;
    if (host == null) {
      return;
    }

    try {
      final state = await host.start();
      final health = await host.healthCheck();
      if (!mounted) return;
      setState(() {
        _headlessOsState = state;
        _kernelHealthReports = health;
        _headlessOsError = null;
      });
    } catch (e) {
      developer.log('Error refreshing headless OS host: $e',
          name: 'AI2AIAdminDashboard');
      if (!mounted) return;
      setState(() {
        _headlessOsError = 'Headless OS unavailable: $e';
      });
    }
  }

  @override
  void dispose() {
    _healthReportSubscription?.cancel();
    _connectionsSubscription?.cancel();
    _realTimeMetricsSubscription?.cancel();
    _communicationsSubscription?.cancel();
    _meshTrustSubscription?.cancel();
    _rendezvousTrustSubscription?.cancel();
    _ambientSocialTrustSubscription?.cancel();
    _transportRetentionSubscription?.cancel();
    _artifactLifecycleSubscription?.cancel();
    _agentRefreshTimer?.cancel();
    _meshTickTimer?.cancel();
    _connectionMonitor?.disposeStreams();
    _networkAnalytics?.disposeStreams();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'AI2AI Network Dashboard',
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      actions: [
        if (_isStreamConnected)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Live',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        IconButton(
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshDashboard,
          tooltip: 'Refresh Dashboard',
        ),
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading &&
        _healthReport == null &&
        _connectionsOverview == null &&
        _realTimeMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null &&
        _healthReport == null &&
        _connectionsOverview == null &&
        _realTimeMetrics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Dashboard',
              style: TextStyle(fontSize: 18, color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.initialFocus != null || widget.initialAttention != null)
              _buildCommandCenterContextCard(context),
            if (widget.initialFocus != null || widget.initialAttention != null)
              const SizedBox(height: 12),
            if (_lastUpdate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Last update: ${_formatTime(_lastUpdate!)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('Admin Command Center'),
                subtitle: const Text(
                  'Open central oversight navigation across reality, universe, world, mesh, kernel, and research',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AdminRoutePaths.commandCenter),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.hub_outlined),
                title: const Text('URK Kernel Console'),
                subtitle: const Text(
                  'Open kernel governance, activation triggers, and prong/mode coverage',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AdminRoutePaths.urkKernels),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.travel_explore),
                title: const Text('Reality System Oversight'),
                subtitle: const Text(
                  'Open separate Reality, Universe, and World admin pages with model check-ins',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AdminRoutePaths.realitySystemReality),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('Research Center'),
                subtitle: const Text(
                  'Shared admin + reality-model research feed, status, and notes',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AdminRoutePaths.researchCenter),
              ),
            ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _refreshDashboard,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            _buildCommunicationVisualizerSection(),
            const SizedBox(height: 24),
            _buildTrustDiagnosticsSection(),
            const SizedBox(height: 24),
            _buildLiveMeshSection(),
            const SizedBox(height: 24),
            _buildHeadlessKernelSection(context),
            const SizedBox(height: 24),
            const TemporalKernelDiagnosticsCard(),
            const SizedBox(height: 24),
            const ForecastKernelStrengthCard(),
            const SizedBox(height: 24),
            const PlanningTruthSurfaceCard(),
            const SizedBox(height: 24),
            const SecurityImmuneSystemCard(),
            const SizedBox(height: 24),
            LocalityKernelDiagnosticsCard(activeAgents: _activeAgents),
            const SizedBox(height: 24),
            const RecommendationWhyPreviewCard(),
            const SizedBox(height: 24),
            if (_healthReport != null)
              NetworkHealthGauge(healthReport: _healthReport!)
            else if (!_isLoading)
              _buildEmptyState(
                  'Network Health', 'No network health data available'),
            const SizedBox(height: 24),
            if (_connectionsOverview != null)
              ConnectionsList(overview: _connectionsOverview!)
            else if (!_isLoading)
              _buildEmptyState(
                  'Active Connections', 'No connection data available'),
            const SizedBox(height: 24),
            if (_realTimeMetrics != null)
              LearningMetricsChart(metrics: _realTimeMetrics!)
            else if (!_isLoading)
              _buildEmptyState('Learning Metrics', 'No metrics data available'),
            const SizedBox(height: 24),
            if (_healthReport != null)
              PrivacyComplianceCard(
                privacyMetrics: _healthReport!.privacyMetrics,
              ),
            const SizedBox(height: 24),
            if (_healthReport != null)
              PerformanceIssuesList(
                issues: _healthReport!.performanceIssues,
                recommendations: _healthReport!.optimizationRecommendations,
              ),
            const SizedBox(height: 24),
            _buildCollaborativeActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandCenterContextCard(BuildContext context) {
    return Card(
      color: AppColors.electricBlue.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Command Center handoff',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This AI2AI surface was opened from the command-center attention queue with carried operator context.',
              style: TextStyle(color: AppColors.textPrimary),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationVisualizerSection() {
    final throughput =
        (_realTimeMetrics?.connectionThroughput ?? 0).clamp(0.0, 1.0);
    final responsiveness =
        (_realTimeMetrics?.networkResponsiveness ?? 0).clamp(0.0, 1.0);
    final compatibility =
        (_connectionsOverview?.aggregateMetrics.averageCompatibility ?? 0)
            .clamp(0.0, 1.0);

    final communicationHealth =
        ((throughput + responsiveness + compatibility) / 3.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI2AI Communication Visualizer',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Live communication and network accuracy surface with global agent placement via admin_agent_globe.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communication Health ${(communicationHealth * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: communicationHealth),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                          'Active connections: ${_connectionsOverview?.totalActiveConnections ?? 0}'),
                    ),
                    Chip(
                      label: Text(
                          'Messages: ${_communicationsSnapshot?.totalMessages ?? 0}'),
                    ),
                    Chip(
                      label: Text(
                          'Throughput: ${(throughput * 100).toStringAsFixed(0)}%'),
                    ),
                    Chip(
                      label: Text(
                          'Responsiveness: ${(responsiveness * 100).toStringAsFixed(0)}%'),
                    ),
                    Chip(
                      label: Text('Agent nodes: ${_activeAgents.length}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        RealtimeAgentGlobeWidget(
          agents: _activeAgents,
          title: 'AI2AI Agent Globe',
          links: _topologyLinks,
          useThreeJs: widget.useThreeJsVisualizations,
          temporalState: GlobeTemporalStateView(
            currentState: _meshTemporalState.label,
            progress: _meshTemporalProgress,
            states: MeshTemporalState.values
                .map((state) => state.label)
                .toList(growable: false),
          ),
          onTemporalStateRendered: (ack) {
            if (!mounted) return;
            setState(() {
              _lastGlobeTemporalState = ack.state;
              _lastGlobeTemporalProgress = ack.progress;
              _lastGlobeTemporalRenderedAt = ack.renderedAt;
            });
          },
        ),
        const SizedBox(height: 8),
        _buildTemporalLockstepIndicator(),
      ],
    );
  }

  Widget _buildTrustDiagnosticsSection() {
    final meshSnapshot = _meshTrustSnapshot ??
        MeshTrustDiagnosticsSnapshot(
          capturedAtUtc: DateTime.now().toUtc(),
          trustedActiveAnnounceCount: 0,
          rejectedAnnounceCount: 0,
          rejectionReasonCounts: const <String, int>{},
          trustedReplayTriggerCount: 0,
          trustedReplayTriggerSourceCounts: const <String, int>{},
          activeCredentialCount: 0,
          expiringSoonCredentialCount: 0,
          revokedCredentialCount: 0,
        );
    final rendezvousSnapshot = _rendezvousTrustSnapshot ??
        Ai2AiRendezvousDiagnosticsSnapshot(
          capturedAtUtc: DateTime.now().toUtc(),
          activeRendezvousCount: 0,
          releasedTicketCount: 0,
          blockedByConditionCount: 0,
          trustedRouteUnavailableBlockCount: 0,
          peerReceivedCount: 0,
          peerValidatedCount: 0,
          peerConsumedCount: 0,
          peerAppliedCount: 0,
        );
    final ambientSocialSnapshot = _ambientSocialSnapshot ??
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
    final transportRetentionSnapshot = _transportRetentionSnapshot ??
        Ai2AiTransportRetentionSnapshot(
          capturedAtUtc: DateTime.now().toUtc(),
          dmConsumedCount: 0,
          dmFailureCount: 0,
          communityConsumedCount: 0,
          communityFailureCount: 0,
        );
    final artifactLifecycleSnapshot = _artifactLifecycleSnapshot ??
        ArtifactLifecycleVisibilitySnapshot(
          capturedAtUtc: DateTime.now().toUtc(),
          entries: const <ArtifactLifecycleVisibilityEntry>[],
          replayUsesDedicatedProject: false,
          replaySharesProjectWithApp: true,
        );
    return MeshTrustDiagnosticsPanel(
      meshSnapshot: meshSnapshot,
      rendezvousSnapshot: rendezvousSnapshot,
      ambientSocialSnapshot: ambientSocialSnapshot,
      transportRetentionSnapshot: transportRetentionSnapshot,
      lifecycleVisibilitySnapshot: artifactLifecycleSnapshot,
      onRunFieldAcceptanceValidation:
          _runtimeGovernanceService?.canRunControlledTrustValidation == true
              ? _runPrivateMeshFieldAcceptanceValidation
              : null,
      onRunControlledValidation:
          _runtimeGovernanceService?.canRunControlledTrustValidation == true
              ? _runControlledTrustValidation
              : null,
      onRunControlledMultiHopValidation:
          _runtimeGovernanceService?.canRunControlledTrustValidation == true
              ? _runControlledMultiHopValidation
              : null,
      onRunAi2AiPeerTruthValidation:
          _runtimeGovernanceService?.canRunControlledTrustValidation == true
              ? _runAi2AiPeerTruthValidation
              : null,
      onRunAmbientSocialValidation:
          _runtimeGovernanceService?.canRunControlledTrustValidation == true
              ? _runControlledAmbientSocialValidation
              : null,
      onExportRecentProofBundles:
          _runtimeGovernanceService == null ? null : _exportRecentTrustProofs,
    );
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      _runPrivateMeshFieldAcceptanceValidation() async {
    final service = _runtimeGovernanceService;
    if (service == null || !service.canRunControlledTrustValidation) {
      throw StateError('controlled_trust_validation_unavailable');
    }
    final proofs =
        await service.runControlledPrivateMeshFieldAcceptanceValidation();
    if (!mounted) {
      return proofs;
    }
    setState(() {
      _meshTrustSnapshot = MeshTrustDiagnosticsSnapshot(
        capturedAtUtc: DateTime.now().toUtc(),
        trustedActiveAnnounceCount:
            _meshTrustSnapshot?.trustedActiveAnnounceCount ?? 0,
        rejectedAnnounceCount: _meshTrustSnapshot?.rejectedAnnounceCount ?? 0,
        rejectionReasonCounts:
            _meshTrustSnapshot?.rejectionReasonCounts ?? const <String, int>{},
        trustedReplayTriggerCount:
            _meshTrustSnapshot?.trustedReplayTriggerCount ?? 0,
        trustedReplayTriggerSourceCounts:
            _meshTrustSnapshot?.trustedReplayTriggerSourceCounts ??
                const <String, int>{},
        activeCredentialCount: _meshTrustSnapshot?.activeCredentialCount ?? 0,
        expiringSoonCredentialCount:
            _meshTrustSnapshot?.expiringSoonCredentialCount ?? 0,
        revokedCredentialCount: _meshTrustSnapshot?.revokedCredentialCount ?? 0,
        activeAnnounceSourceCounts:
            _meshTrustSnapshot?.activeAnnounceSourceCounts ??
                const <String, int>{},
        rejectedAnnounceSourceCounts:
            _meshTrustSnapshot?.rejectedAnnounceSourceCounts ??
                const <String, int>{},
        recentProofs: proofs,
      );
      _rendezvousTrustSnapshot = Ai2AiRendezvousDiagnosticsSnapshot(
        capturedAtUtc: DateTime.now().toUtc(),
        activeRendezvousCount:
            _rendezvousTrustSnapshot?.activeRendezvousCount ?? 0,
        releasedTicketCount: _rendezvousTrustSnapshot?.releasedTicketCount ?? 0,
        blockedByConditionCount:
            _rendezvousTrustSnapshot?.blockedByConditionCount ?? 0,
        trustedRouteUnavailableBlockCount:
            _rendezvousTrustSnapshot?.trustedRouteUnavailableBlockCount ?? 0,
        peerReceivedCount: _rendezvousTrustSnapshot?.peerReceivedCount ?? 0,
        peerValidatedCount: _rendezvousTrustSnapshot?.peerValidatedCount ?? 0,
        peerConsumedCount: _rendezvousTrustSnapshot?.peerConsumedCount ?? 0,
        peerAppliedCount: _rendezvousTrustSnapshot?.peerAppliedCount ?? 0,
        lastReleaseReason: _rendezvousTrustSnapshot?.lastReleaseReason,
        lastBlockedReason: _rendezvousTrustSnapshot?.lastBlockedReason,
        recentProofs: proofs,
      );
    });
    return proofs;
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      _runControlledTrustValidation() async {
    final service = _runtimeGovernanceService;
    if (service == null || !service.canRunControlledTrustValidation) {
      throw StateError('controlled_trust_validation_unavailable');
    }
    final proofs = await service.runControlledPrivateMeshTrustValidation();
    if (!mounted) {
      return proofs;
    }
    setState(() {
      _meshTrustSnapshot = MeshTrustDiagnosticsSnapshot(
        capturedAtUtc: DateTime.now().toUtc(),
        trustedActiveAnnounceCount:
            _meshTrustSnapshot?.trustedActiveAnnounceCount ?? 0,
        rejectedAnnounceCount: _meshTrustSnapshot?.rejectedAnnounceCount ?? 0,
        rejectionReasonCounts:
            _meshTrustSnapshot?.rejectionReasonCounts ?? const <String, int>{},
        trustedReplayTriggerCount:
            _meshTrustSnapshot?.trustedReplayTriggerCount ?? 0,
        trustedReplayTriggerSourceCounts:
            _meshTrustSnapshot?.trustedReplayTriggerSourceCounts ??
                const <String, int>{},
        activeCredentialCount: _meshTrustSnapshot?.activeCredentialCount ?? 0,
        expiringSoonCredentialCount:
            _meshTrustSnapshot?.expiringSoonCredentialCount ?? 0,
        revokedCredentialCount: _meshTrustSnapshot?.revokedCredentialCount ?? 0,
        activeAnnounceSourceCounts:
            _meshTrustSnapshot?.activeAnnounceSourceCounts ??
                const <String, int>{},
        rejectedAnnounceSourceCounts:
            _meshTrustSnapshot?.rejectedAnnounceSourceCounts ??
                const <String, int>{},
        recentProofs: proofs,
      );
    });
    return proofs;
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      _runControlledMultiHopValidation() async {
    final service = _runtimeGovernanceService;
    if (service == null || !service.canRunControlledTrustValidation) {
      throw StateError('controlled_trust_validation_unavailable');
    }
    final proofs = await service.runControlledPrivateMeshMultiHopValidation();
    if (!mounted) {
      return proofs;
    }
    setState(() {
      _meshTrustSnapshot = MeshTrustDiagnosticsSnapshot(
        capturedAtUtc: DateTime.now().toUtc(),
        trustedActiveAnnounceCount:
            _meshTrustSnapshot?.trustedActiveAnnounceCount ?? 0,
        rejectedAnnounceCount: _meshTrustSnapshot?.rejectedAnnounceCount ?? 0,
        rejectionReasonCounts:
            _meshTrustSnapshot?.rejectionReasonCounts ?? const <String, int>{},
        trustedReplayTriggerCount:
            _meshTrustSnapshot?.trustedReplayTriggerCount ?? 0,
        trustedReplayTriggerSourceCounts:
            _meshTrustSnapshot?.trustedReplayTriggerSourceCounts ??
                const <String, int>{},
        activeCredentialCount: _meshTrustSnapshot?.activeCredentialCount ?? 0,
        expiringSoonCredentialCount:
            _meshTrustSnapshot?.expiringSoonCredentialCount ?? 0,
        revokedCredentialCount: _meshTrustSnapshot?.revokedCredentialCount ?? 0,
        activeAnnounceSourceCounts:
            _meshTrustSnapshot?.activeAnnounceSourceCounts ??
                const <String, int>{},
        rejectedAnnounceSourceCounts:
            _meshTrustSnapshot?.rejectedAnnounceSourceCounts ??
                const <String, int>{},
        recentProofs: proofs,
      );
    });
    return proofs;
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      _runAi2AiPeerTruthValidation() async {
    final service = _runtimeGovernanceService;
    if (service == null || !service.canRunControlledTrustValidation) {
      throw StateError('controlled_trust_validation_unavailable');
    }
    final proofs = await service.runControlledAi2AiPeerTruthValidation();
    if (!mounted) {
      return proofs;
    }
    setState(() {
      _rendezvousTrustSnapshot = Ai2AiRendezvousDiagnosticsSnapshot(
        capturedAtUtc: DateTime.now().toUtc(),
        activeRendezvousCount:
            _rendezvousTrustSnapshot?.activeRendezvousCount ?? 0,
        releasedTicketCount: _rendezvousTrustSnapshot?.releasedTicketCount ?? 0,
        blockedByConditionCount:
            _rendezvousTrustSnapshot?.blockedByConditionCount ?? 0,
        trustedRouteUnavailableBlockCount:
            _rendezvousTrustSnapshot?.trustedRouteUnavailableBlockCount ?? 0,
        peerReceivedCount: _rendezvousTrustSnapshot?.peerReceivedCount ?? 0,
        peerValidatedCount: _rendezvousTrustSnapshot?.peerValidatedCount ?? 0,
        peerConsumedCount: _rendezvousTrustSnapshot?.peerConsumedCount ?? 0,
        peerAppliedCount: _rendezvousTrustSnapshot?.peerAppliedCount ?? 0,
        lastReleaseReason: _rendezvousTrustSnapshot?.lastReleaseReason,
        lastBlockedReason: _rendezvousTrustSnapshot?.lastBlockedReason,
        recentProofs: proofs,
      );
    });
    return proofs;
  }

  Future<List<DomainExecutionFieldScenarioProof>>
      _runControlledAmbientSocialValidation() async {
    final service = _runtimeGovernanceService;
    if (service == null || !service.canRunControlledTrustValidation) {
      throw StateError('controlled_trust_validation_unavailable');
    }
    final proofs = await service.runControlledAmbientSocialValidation();
    if (!mounted) {
      return proofs;
    }
    setState(() {
      _meshTrustSnapshot = MeshTrustDiagnosticsSnapshot(
        capturedAtUtc: DateTime.now().toUtc(),
        trustedActiveAnnounceCount:
            _meshTrustSnapshot?.trustedActiveAnnounceCount ?? 0,
        rejectedAnnounceCount: _meshTrustSnapshot?.rejectedAnnounceCount ?? 0,
        rejectionReasonCounts:
            _meshTrustSnapshot?.rejectionReasonCounts ?? const <String, int>{},
        trustedReplayTriggerCount:
            _meshTrustSnapshot?.trustedReplayTriggerCount ?? 0,
        trustedReplayTriggerSourceCounts:
            _meshTrustSnapshot?.trustedReplayTriggerSourceCounts ??
                const <String, int>{},
        activeCredentialCount: _meshTrustSnapshot?.activeCredentialCount ?? 0,
        expiringSoonCredentialCount:
            _meshTrustSnapshot?.expiringSoonCredentialCount ?? 0,
        revokedCredentialCount: _meshTrustSnapshot?.revokedCredentialCount ?? 0,
        activeAnnounceSourceCounts:
            _meshTrustSnapshot?.activeAnnounceSourceCounts ??
                const <String, int>{},
        rejectedAnnounceSourceCounts:
            _meshTrustSnapshot?.rejectedAnnounceSourceCounts ??
                const <String, int>{},
        recentProofs: proofs,
      );
    });
    return proofs;
  }

  Future<String> _exportRecentTrustProofs() async {
    final service = _runtimeGovernanceService;
    if (service == null) {
      throw StateError('runtime_governance_service_unavailable');
    }
    return service.exportRecentFieldValidationProofs(limit: 8);
  }

  Widget _buildHeadlessKernelSection(BuildContext context) {
    if (_headlessOsHost == null) {
      return _buildEmptyState(
        'Headless OS Kernel Health',
        'No headless AVRAI OS host is registered in this runtime.',
      );
    }

    if (_headlessOsError != null) {
      return _buildEmptyState('Headless OS Kernel Health', _headlessOsError!);
    }

    final state = _headlessOsState;
    if (state == null) {
      return _buildEmptyState(
        'Headless OS Kernel Health',
        'Headless AVRAI OS host has not reported status yet.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Headless OS Kernel Health',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.summary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(state.started ? 'started' : 'stopped'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: state.started
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                  side: BorderSide(
                    color:
                        state.started ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    'started ${state.startedAtUtc.toUtc().toIso8601String()}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                if (state.localityContainedInWhere)
                  const Chip(
                    label: Text('locality in where'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_kernelHealthReports.isEmpty)
              const Text(
                'No kernel health diagnostics available yet.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ..._kernelHealthReports.map(
                (report) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.domain.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(report.status.name),
                      const SizedBox(width: 8),
                      Text(
                        report.authorityLevel.name,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMeshSection() {
    final nodes = _buildMeshNodes(_activeAgents);
    final edges = _buildMeshEdges(nodes, _topologyLinks);
    final density = _meshDensity(nodes.length, edges.length);
    final avgDegree = _averageDegree(nodes.length, edges.length);
    final timestamp = _latestAtomicTimestamp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live AI2AI Mesh (Universal Internal Time)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Realtime mesh view with privacy-safe agent identities and quantum atomic timing states.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: _meshTemporalProgress,
                  minHeight: 6,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label:
                          Text('Temporal state: ${_meshTemporalState.label}'),
                    ),
                    Chip(
                      label: Text('Nodes: ${nodes.length}'),
                    ),
                    Chip(
                      label: Text('Edges: ${edges.length}'),
                    ),
                    Chip(
                      label: Text(
                          'Mesh density: ${(density * 100).toStringAsFixed(1)}%'),
                    ),
                    Chip(
                      label:
                          Text('Avg degree: ${avgDegree.toStringAsFixed(2)}'),
                    ),
                    Chip(
                      label: Text(
                        timestamp == null
                            ? 'Atomic sync: pending'
                            : 'Atomic sync: ${timestamp.isSynchronized ? 'synchronized' : 'device fallback'}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MeshTemporalState.values
                      .map(
                        (state) => Chip(
                          avatar: Icon(
                            state == _meshTemporalState
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 16,
                          ),
                          label: Text(state.label),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  timestamp == null
                      ? 'Waiting for atomic timestamp stream.'
                      : 'Universal internal time: ${timestamp.serverTime.toIso8601String()} (${timestamp.timezoneId}, ${timestamp.precision.name}).',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Network3DVisualizationWidget(
              nodes: nodes,
              edges: edges,
              height: 360,
              width: double.infinity,
              showControls: true,
              useThreeJs: widget.useThreeJsVisualizations,
              onNodeTapped: (agentId) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Agent mesh node: $agentId'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<GlobeConnectionLink> _buildTopologyLinks(
      List<ActiveAIAgentData> agents) {
    if (agents.length < 2) {
      return const <GlobeConnectionLink>[];
    }

    final sorted = [...agents]
      ..sort((a, b) => b.aiConnections.compareTo(a.aiConnections));

    final linkSet = <String>{};
    final links = <GlobeConnectionLink>[];
    final maxEdges = (sorted.length * 2).clamp(4, 90);

    for (int i = 0; i < sorted.length; i++) {
      final source = sorted[i];
      final peers = _closestPeers(source, sorted, 2);

      for (final peer in peers) {
        if (source.aiSignature == peer.aiSignature) {
          continue;
        }

        final ids = [source.aiSignature, peer.aiSignature]..sort();
        final key = '${ids[0]}|${ids[1]}';
        if (linkSet.contains(key)) {
          continue;
        }
        linkSet.add(key);

        final strength = ((source.aiConnections + peer.aiConnections) / 20.0)
            .clamp(0.15, 1.0)
            .toDouble();

        links.add(
          GlobeConnectionLink(
            fromAgentId: source.aiSignature,
            toAgentId: peer.aiSignature,
            strength: strength,
          ),
        );

        if (links.length >= maxEdges) {
          return links;
        }
      }
    }

    return links;
  }

  List<ActiveAIAgentData> _closestPeers(
    ActiveAIAgentData source,
    List<ActiveAIAgentData> agents,
    int maxPeers,
  ) {
    final candidates = agents
        .where((agent) => agent.aiSignature != source.aiSignature)
        .toList();

    candidates.sort((a, b) {
      final da = _distanceScore(source, a);
      final db = _distanceScore(source, b);
      return da.compareTo(db);
    });

    return candidates.take(maxPeers).toList();
  }

  double _distanceScore(ActiveAIAgentData a, ActiveAIAgentData b) {
    final lat = (a.latitude - b.latitude).abs();
    final lng = (a.longitude - b.longitude).abs();
    return lat + lng;
  }

  List<AI2AINetworkNode> _buildMeshNodes(List<ActiveAIAgentData> agents) {
    if (agents.isEmpty) {
      return const <AI2AINetworkNode>[];
    }

    return agents.asMap().entries.map((entry) {
      final index = entry.key;
      final agent = entry.value;
      final position = _meshPositionForAgent(index, agents.length, agent);

      return AI2AINetworkNode(
        userId: _maskedIdentity(agent.aiSignature),
        position: position,
        isCenter: index == 0,
      );
    }).toList();
  }

  List<AI2AINetworkEdge> _buildMeshEdges(
    List<AI2AINetworkNode> nodes,
    List<GlobeConnectionLink> links,
  ) {
    if (nodes.length < 2) {
      return const <AI2AINetworkEdge>[];
    }

    final indexById = <String, int>{};
    for (int i = 0; i < _activeAgents.length && i < nodes.length; i++) {
      indexById[_maskedIdentity(_activeAgents[i].aiSignature)] = i;
    }

    final edges = <AI2AINetworkEdge>[];
    for (final link in links) {
      final from = indexById[_maskedIdentity(link.fromAgentId)];
      final to = indexById[_maskedIdentity(link.toAgentId)];
      if (from == null || to == null || from == to) {
        continue;
      }
      edges.add(
        AI2AINetworkEdge(
          fromIndex: from,
          toIndex: to,
          strength: link.strength,
        ),
      );
    }

    if (edges.isNotEmpty) {
      return edges;
    }

    final fallback = <AI2AINetworkEdge>[];
    for (int i = 0; i < nodes.length - 1; i++) {
      fallback
          .add(AI2AINetworkEdge(fromIndex: i, toIndex: i + 1, strength: 0.35));
    }
    return fallback;
  }

  Vector3 _meshPositionForAgent(
    int index,
    int total,
    ActiveAIAgentData agent,
  ) {
    final normalizedLat = (agent.latitude.clamp(-90.0, 90.0) / 90.0);
    final normalizedLng = (agent.longitude.clamp(-180.0, 180.0) / 180.0);
    final angle = ((index + 1) / (total + 1)) * (2 * math.pi);

    final radius = 2.5 + (agent.aiConnections.clamp(0, 12) / 12.0) * 1.5;
    final x = radius * math.cos(angle) + normalizedLng * 0.9;
    final y = radius * math.sin(angle) + normalizedLat * 0.9;
    final z = (normalizedLat - normalizedLng) * 1.4;
    return Vector3(x, y, z);
  }

  double _normalizedAngle(double cosValue, double sinValue) {
    final angle = math.atan2(sinValue, cosValue);
    return angle >= 0 ? angle : angle + (2 * math.pi);
  }

  MeshTemporalState _stateForAngle(double angle) {
    if (angle < math.pi / 2) {
      return MeshTemporalState.alignment;
    }
    if (angle < math.pi) {
      return MeshTemporalState.expansion;
    }
    if (angle < 3 * math.pi / 2) {
      return MeshTemporalState.stabilization;
    }
    return MeshTemporalState.reflection;
  }

  double _stateStart(MeshTemporalState state) {
    switch (state) {
      case MeshTemporalState.alignment:
        return 0;
      case MeshTemporalState.expansion:
        return math.pi / 2;
      case MeshTemporalState.stabilization:
        return math.pi;
      case MeshTemporalState.reflection:
        return 3 * math.pi / 2;
    }
  }

  double _meshDensity(int nodeCount, int edgeCount) {
    if (nodeCount < 2) {
      return 0.0;
    }
    final maxEdges = nodeCount * (nodeCount - 1) / 2;
    return (edgeCount / maxEdges).clamp(0.0, 1.0).toDouble();
  }

  double _averageDegree(int nodeCount, int edgeCount) {
    if (nodeCount == 0) {
      return 0.0;
    }
    return (2 * edgeCount) / nodeCount;
  }

  String _maskedIdentity(String signature) {
    if (signature.length <= 8) {
      return signature;
    }
    return '${signature.substring(0, 4)}...${signature.substring(signature.length - 4)}';
  }

  Widget _buildTemporalLockstepIndicator() {
    final isAligned = _isTemporalLockstepAligned();
    final color = isAligned ? AppColors.success : AppColors.warning;
    final icon = isAligned ? Icons.sync : Icons.sync_problem;
    final label = isAligned
        ? 'Globe/Mesh lockstep: healthy'
        : 'Globe/Mesh lockstep: drift detected';

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(icon, color: color, size: 18),
        label: Text(label),
      ),
    );
  }

  bool _isTemporalLockstepAligned() {
    final renderedAt = _lastGlobeTemporalRenderedAt;
    final progress = _lastGlobeTemporalProgress;
    if (renderedAt == null ||
        progress == null ||
        _latestAtomicTimestamp == null) {
      return false;
    }

    final freshness =
        DateTime.now().difference(renderedAt) <= const Duration(seconds: 4);
    final sameState = _lastGlobeTemporalState == _meshTemporalState.label;
    final progressDelta = (progress - _meshTemporalProgress).abs();
    return freshness && sameState && progressDelta <= 0.25;
  }

  Widget _buildCollaborativeActivitySection() {
    AdminRuntimeGovernanceService? godModeService;
    try {
      godModeService = GetIt.instance<AdminRuntimeGovernanceService>();
    } catch (e) {
      debugPrint('AdminRuntimeGovernanceService not available: $e');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collaborative Activity Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Privacy-safe aggregate metrics on AI2AI collaborative patterns',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        AdminCollaborativeActivityWidget(
          godModeService: godModeService,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.info_outline,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

enum MeshTemporalState {
  alignment('Alignment Window'),
  expansion('Expansion Window'),
  stabilization('Stabilization Window'),
  reflection('Reflection Window');

  const MeshTemporalState(this.label);
  final String label;
}
