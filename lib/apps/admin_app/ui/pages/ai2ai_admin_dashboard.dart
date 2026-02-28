import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/monitoring/network_analytics.dart';
import 'package:avrai/core/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/apps/admin_app/ui/widgets/realtime_agent_globe_widget.dart';
import 'package:avrai/apps/admin_app/ui/widgets/admin_collaborative_activity_widget.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/ai2ai/connections_list.dart';
import 'package:avrai/presentation/widgets/ai2ai/learning_metrics_chart.dart';
import 'package:avrai/presentation/widgets/ai2ai/network_health_gauge.dart';
import 'package:avrai/presentation/widgets/ai2ai/performance_issues_list.dart';
import 'package:avrai/presentation/widgets/ai2ai/privacy_compliance_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Admin Dashboard for AI2AI Network Monitoring
/// Displays network health, connections, learning metrics, privacy, and performance.
class AI2AIAdminDashboard extends StatefulWidget {
  const AI2AIAdminDashboard({super.key});

  @override
  State<AI2AIAdminDashboard> createState() => _AI2AIAdminDashboardState();
}

class _AI2AIAdminDashboardState extends State<AI2AIAdminDashboard> {
  NetworkAnalytics? _networkAnalytics;
  ConnectionMonitor? _connectionMonitor;
  AdminRuntimeGovernanceService? _runtimeGovernanceService;

  StreamSubscription<NetworkHealthReport>? _healthReportSubscription;
  StreamSubscription<ActiveConnectionsOverview>? _connectionsSubscription;
  StreamSubscription<RealTimeMetrics>? _realTimeMetricsSubscription;
  StreamSubscription<CommunicationsSnapshot>? _communicationsSubscription;
  Timer? _agentRefreshTimer;

  NetworkHealthReport? _healthReport;
  ActiveConnectionsOverview? _connectionsOverview;
  RealTimeMetrics? _realTimeMetrics;
  CommunicationsSnapshot? _communicationsSnapshot;
  List<ActiveAIAgentData> _activeAgents = <ActiveAIAgentData>[];
  List<GlobeConnectionLink> _topologyLinks = <GlobeConnectionLink>[];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  DateTime? _lastUpdate;
  bool _isStreamConnected = false;

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
      _setupStreams();
      await _refreshActiveAgents();
      _setupAgentRefreshTimer();
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
    }
  }

  void _setupAgentRefreshTimer() {
    _agentRefreshTimer?.cancel();
    _agentRefreshTimer = Timer.periodic(
        const Duration(seconds: 20), (_) => _refreshActiveAgents());
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

  @override
  void dispose() {
    _healthReportSubscription?.cancel();
    _connectionsSubscription?.cancel();
    _realTimeMetricsSubscription?.cancel();
    _communicationsSubscription?.cancel();
    _agentRefreshTimer?.cancel();
    _connectionMonitor?.disposeStreams();
    _networkAnalytics?.disposeStreams();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
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
                leading: const Icon(Icons.hub_outlined),
                title: const Text('URK Kernel Console'),
                subtitle: const Text(
                  'Open kernel governance, activation triggers, and prong/mode coverage',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/admin/urk-kernels'),
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
                onTap: () => context.go('/admin/reality-system/reality'),
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
