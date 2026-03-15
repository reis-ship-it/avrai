import 'dart:async';

import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_operations_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class LaunchSafetyPage extends StatefulWidget {
  const LaunchSafetyPage({super.key});

  @override
  State<LaunchSafetyPage> createState() => _LaunchSafetyPageState();
}

class _LaunchSafetyPageState extends State<LaunchSafetyPage> {
  BhamAdminOperationsService? _opsService;
  AdminRuntimeGovernanceService? _governanceService;
  Timer? _refreshTimer;

  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;
  AdminHealthSnapshot? _health;
  LaunchGateAdminMetrics? _metrics;
  GodModeDashboardData? _dashboard;
  BhamLaunchGateReport? _report;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _opsService = GetIt.instance<BhamAdminOperationsService>();
      _governanceService = GetIt.instance<AdminRuntimeGovernanceService>();
      await _load();
      _refreshTimer =
          Timer.periodic(const Duration(seconds: 20), (_) => _load());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Launch safety surface is unavailable: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _load() async {
    final ops = _opsService;
    final governance = _governanceService;
    if (ops == null || governance == null) {
      return;
    }
    try {
      final dashboard = await governance.getDashboardData();
      final platformCounts = <String, int>{
        'ios':
            dashboard.authMix.lastSignInPlatformCounts.totalCounts['ios'] ?? 0,
        'android':
            dashboard.authMix.lastSignInPlatformCounts.totalCounts['android'] ??
                0,
      };
      final health =
          await ops.getHealthSnapshot(platformHealth: platformCounts);
      final metrics =
          await ops.getLaunchGateMetrics(platformHealth: platformCounts);
      final report = await ops.buildLaunchGateReport(
        platformHealth: platformCounts,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
        _health = health;
        _metrics = metrics;
        _report = report;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load launch safety data: $error';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _exportSnapshot() async {
    final ops = _opsService;
    final dashboard = _dashboard;
    if (ops == null || dashboard == null || _isExporting) {
      return;
    }

    final platformCounts = <String, int>{
      'ios': dashboard.authMix.lastSignInPlatformCounts.totalCounts['ios'] ?? 0,
      'android':
          dashboard.authMix.lastSignInPlatformCounts.totalCounts['android'] ??
              0,
    };

    setState(() {
      _isExporting = true;
    });

    try {
      final file = await ops.exportLaunchSnapshot(
        platformHealth: platformCounts,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Launch snapshot exported to ${file.path}'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export launch snapshot: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Launch Safety',
      actions: [
        IconButton(
          onPressed: _isLoading || _isExporting ? null : _exportSnapshot,
          icon: _isExporting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          tooltip: 'Export launch snapshot',
        ),
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
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final health = _health;
    final metrics = _metrics;
    final dashboard = _dashboard;
    final report = _report;
    if (health == null ||
        metrics == null ||
        dashboard == null ||
        report == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: health.adminAvailable
                ? AppColors.electricGreen.withValues(alpha: 0.08)
                : AppColors.error.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    health.adminAvailable
                        ? 'Wave 6 admin availability is passing'
                        : 'Wave 6 admin availability is blocked',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    health.deviceStatusLabel ??
                        'Admin session/device health is unavailable.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                          label:
                              Text('Active users: ${dashboard.activeUsers}')),
                      Chip(
                          label: Text(
                              'System health: ${(dashboard.systemHealth * 100).round()}%')),
                      Chip(
                          label: Text(
                              'Route health: ${(health.routeDeliveryHealth * 100).round()}%')),
                      Chip(
                          label: Text(
                              'Break-glass: ${health.openBreakGlassCount}')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: _statusColor(report.status).withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wave 7 launch gate: ${_statusLabel(report.status)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is the canonical BHAM launch-readiness report. Targeted Wave 6 verification no longer counts as sufficient signoff on its own.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          'Critical flows: ${report.criticalFlowChecks.where((item) => item.status == BhamFlowCheckStatus.pass).length}/${report.criticalFlowChecks.length} pass',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Fallback alerts: ${report.fallbackStates.where((item) => item.status != BhamFallbackStatus.healthy).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Expansion gates blocked/manual: ${report.expansionGates.where((item) => item.status != BhamLaunchGateStatus.pass).length}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Launch gate metrics',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _metricRow('Admin availability',
                      metrics.availability ? 'Pass' : 'Fail'),
                  _metricRow('Moderation queue size',
                      '${metrics.moderationQueueHealth}'),
                  _metricRow('Quarantine count', '${metrics.quarantineCount}'),
                  _metricRow(
                      'Falsity/reset count', '${metrics.falsityResetCount}'),
                  _metricRow('Break-glass count', '${metrics.breakGlassCount}'),
                  _metricRow(
                    'Route delivery health',
                    '${(metrics.routeDeliveryHealth * 100).round()}%',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('iOS vs Android health split',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _metricRow(
                      'iOS sign-ins', '${metrics.platformHealth['ios'] ?? 0}'),
                  _metricRow(
                    'Android sign-ins',
                    '${metrics.platformHealth['android'] ?? 0}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(context, report),
          const SizedBox(height: 12),
          _buildCriticalFlowsCard(context, report),
          const SizedBox(height: 12),
          _buildExpansionGatesCard(context, report),
          const SizedBox(height: 12),
          _buildBlockersCard(context, report),
          const SizedBox(height: 12),
          Card(
            color: AppColors.warning.withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explicit Wave 5 carry note'),
                  SizedBox(height: 8),
                  Text(
                    'Wave 5 emitted communication summaries, route receipts, and delivery failures into runtime. Wave 6 closes that gap by rendering those contracts in the standalone admin app as launch-blocking surfaces.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildFallbackCard(BuildContext context, BhamLaunchGateReport report) {
    final items = report.fallbackStates;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fallback and pause state',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _fallbackIcon(item.status),
                  color: _statusColor(_mapFallbackToGateStatus(item.status)),
                ),
                title: Text(_fallbackLabel(item.area)),
                subtitle: Text(item.summary),
                trailing: Text(_fallbackStatusLabel(item.status)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalFlowsCard(
    BuildContext context,
    BhamLaunchGateReport report,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Critical flow matrix',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...report.criticalFlowChecks.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.status == BhamFlowCheckStatus.pass
                      ? Icons.task_alt
                      : item.status == BhamFlowCheckStatus.blocked
                          ? Icons.block
                          : Icons.pending_actions,
                  color: item.status == BhamFlowCheckStatus.pass
                      ? AppColors.electricGreen
                      : item.status == BhamFlowCheckStatus.blocked
                          ? AppColors.error
                          : AppColors.warning,
                ),
                title: Text(item.label),
                subtitle: Text(item.evidenceSummary),
                trailing: Text(item.source),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionGatesCard(
    BuildContext context,
    BhamLaunchGateReport report,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expansion gate evidence',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...report.expansionGates.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.status == BhamLaunchGateStatus.pass
                      ? Icons.check_circle_outline
                      : item.status == BhamLaunchGateStatus.blocked
                          ? Icons.gpp_bad_outlined
                          : Icons.rule_folder_outlined,
                  color: _statusColor(item.status),
                ),
                title: Text(item.description),
                subtitle: Text(item.summary),
                trailing: Text(_statusLabel(item.status)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockersCard(BuildContext context, BhamLaunchGateReport report) {
    final blockers = report.unresolvedBlockers;
    return Card(
      color: blockers.isEmpty
          ? AppColors.electricGreen.withValues(alpha: 0.08)
          : AppColors.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              blockers.isEmpty ? 'No unresolved blockers' : 'Launch blockers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (blockers.isEmpty)
              const Text('Wave 7 currently has no explicit blockers recorded.')
            else
              ...blockers.map(
                (blocker) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $blocker'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BhamLaunchGateStatus status) {
    switch (status) {
      case BhamLaunchGateStatus.pass:
        return 'Pass';
      case BhamLaunchGateStatus.passWithPause:
        return 'Pass with pause';
      case BhamLaunchGateStatus.blocked:
        return 'Blocked';
      case BhamLaunchGateStatus.manualReviewRequired:
        return 'Manual review';
    }
  }

  Color _statusColor(BhamLaunchGateStatus status) {
    switch (status) {
      case BhamLaunchGateStatus.pass:
        return AppColors.electricGreen;
      case BhamLaunchGateStatus.passWithPause:
        return AppColors.warning;
      case BhamLaunchGateStatus.blocked:
        return AppColors.error;
      case BhamLaunchGateStatus.manualReviewRequired:
        return AppColors.warning;
    }
  }

  String _fallbackLabel(BhamFallbackArea area) {
    switch (area) {
      case BhamFallbackArea.onDeviceSlm:
        return 'On-device language';
      case BhamFallbackArea.ai2aiLocalExchange:
        return 'AI2AI local exchange';
      case BhamFallbackArea.backgroundSensing:
        return 'Background sensing';
      case BhamFallbackArea.offlineRecommendationQuality:
        return 'Offline recommendation quality';
      case BhamFallbackArea.adminObservability:
        return 'Admin observability';
      case BhamFallbackArea.publicCreation:
        return 'Public creation';
      case BhamFallbackArea.localityLearning:
        return 'Locality learning';
      case BhamFallbackArea.directUserCompatibility:
        return 'Direct user compatibility';
    }
  }

  String _fallbackStatusLabel(BhamFallbackStatus status) {
    switch (status) {
      case BhamFallbackStatus.healthy:
        return 'Healthy';
      case BhamFallbackStatus.degraded:
        return 'Degraded';
      case BhamFallbackStatus.paused:
        return 'Paused';
      case BhamFallbackStatus.blocked:
        return 'Blocked';
      case BhamFallbackStatus.manualReviewRequired:
        return 'Manual review';
    }
  }

  IconData _fallbackIcon(BhamFallbackStatus status) {
    switch (status) {
      case BhamFallbackStatus.healthy:
        return Icons.check_circle_outline;
      case BhamFallbackStatus.degraded:
        return Icons.warning_amber_outlined;
      case BhamFallbackStatus.paused:
        return Icons.pause_circle_outline;
      case BhamFallbackStatus.blocked:
        return Icons.block;
      case BhamFallbackStatus.manualReviewRequired:
        return Icons.pending_actions;
    }
  }

  BhamLaunchGateStatus _mapFallbackToGateStatus(BhamFallbackStatus status) {
    switch (status) {
      case BhamFallbackStatus.healthy:
        return BhamLaunchGateStatus.pass;
      case BhamFallbackStatus.degraded:
      case BhamFallbackStatus.paused:
        return BhamLaunchGateStatus.passWithPause;
      case BhamFallbackStatus.blocked:
        return BhamLaunchGateStatus.blocked;
      case BhamFallbackStatus.manualReviewRequired:
        return BhamLaunchGateStatus.manualReviewRequired;
    }
  }
}
