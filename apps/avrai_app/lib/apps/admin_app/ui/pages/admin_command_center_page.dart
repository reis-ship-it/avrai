import 'dart:async';

import 'package:avrai/apps/admin_app/navigation/admin_route_paths.dart';
import 'package:avrai/apps/admin_app/ui/widgets/governance_audit_feed_card.dart';
import 'package:avrai_core/models/misc/break_glass_governance_directive.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai/apps/admin_app/ui/widgets/realtime_agent_globe_widget.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class AdminCommandCenterPage extends StatefulWidget {
  const AdminCommandCenterPage({super.key});

  @override
  State<AdminCommandCenterPage> createState() => _AdminCommandCenterPageState();
}

class _AdminCommandCenterPageState extends State<AdminCommandCenterPage> {
  AdminRuntimeGovernanceService? _service;
  StreamSubscription<CommunicationsSnapshot>? _communicationsSubscription;
  Timer? _refreshTimer;

  bool _isLoading = true;
  String? _error;
  DateTime? _lastRefreshAt;
  GodModeDashboardData? _dashboardData;
  CommunicationsSnapshot? _communicationsSnapshot;
  List<ActiveAIAgentData> _activeAgents = <ActiveAIAgentData>[];
  List<GovernanceInspectionResponse> _recentInspections =
      <GovernanceInspectionResponse>[];
  List<BreakGlassGovernanceReceipt> _recentBreakGlassReceipts =
      <BreakGlassGovernanceReceipt>[];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _service = GetIt.instance<AdminRuntimeGovernanceService>();
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
    if (service == null) return;
    try {
      final results = await Future.wait<dynamic>([
        service.getDashboardData(),
        service.getAllActiveAIAgents(),
        service.listRecentGovernanceInspections(limit: 4),
        service.listRecentBreakGlassReceipts(limit: 4),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboardData = results[0] as GodModeDashboardData;
        _activeAgents = results[1] as List<ActiveAIAgentData>;
        _recentInspections = results[2] as List<GovernanceInspectionResponse>;
        _recentBreakGlassReceipts =
            results[3] as List<BreakGlassGovernanceReceipt>;
        _lastRefreshAt = DateTime.now();
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
            color: AppColors.electricGreen.withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip, color: AppColors.electricGreen),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Privacy mode enforced: admin views expose agent identity and aggregate telemetry only. Direct user PII is not rendered in this command center.',
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
                'System health',
                '${(((dashboard?.systemHealth ?? 0) * 100).round())}%',
              ),
            ],
          ),
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
          RealtimeAgentGlobeWidget(
            agents: _activeAgents,
            title: 'Admin Agent Globe (Live)',
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
