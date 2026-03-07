import 'dart:async';
import 'dart:convert';

import 'package:avrai/apps/admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_runtime_os/services/admin/research_activity_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ResearchCenterPage extends StatefulWidget {
  const ResearchCenterPage({super.key});

  @override
  State<ResearchCenterPage> createState() => _ResearchCenterPageState();
}

class _ResearchCenterPageState extends State<ResearchCenterPage> {
  ResearchActivityService? _service;
  StreamSubscription<List<ResearchProject>>? _projectsSubscription;

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;
  List<ResearchProject> _projects = <ResearchProject>[];
  List<ResearchAlert> _alerts = <ResearchAlert>[];
  String _sourceLabel = 'local mock (v1)';
  bool _isBackendConnected = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferencesCompat.getInstance();
      final resolution =
          await ResearchActivityServiceFactory.createDefault(prefs: prefs);
      final service = resolution.service;
      _service = service;
      _sourceLabel = resolution.sourceLabel;
      _isBackendConnected = resolution.isBackendConnected;
      _projectsSubscription = service.watchProjects().listen(
        (projects) {
          if (!mounted) return;
          setState(() {
            _projects = [...projects]
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            _isLoading = false;
            _error = null;
          });
          _refreshAlerts();
        },
        onError: (Object e) {
          if (!mounted) return;
          setState(() {
            _error = 'Failed to subscribe to research feed: $e';
            _isLoading = false;
          });
        },
      );
      await service.getProjects();
      await _refreshAlerts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to initialize Research Center: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Research Center',
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'json') {
              _showExportDialog(format: 'json');
            } else if (value == 'csv') {
              _showExportDialog(format: 'csv');
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'json',
              child: Text('Export audit JSON'),
            ),
            PopupMenuItem<String>(
              value: 'csv',
              child: Text('Export audit CSV'),
            ),
          ],
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Export research audit',
        ),
        IconButton(
          onPressed: _isUpdating ? null : _refresh,
          icon: _isUpdating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
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
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final realityVisible = _projects
        .where((project) => project.canRoleView('reality_model_primary'))
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _refresh,
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
                    'Shared Research Feed',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Backend-ready interface is active. Current source is local mock storage until internal backend is provisioned.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Projects: ${_projects.length}')),
                      Chip(
                          label: Text(
                              'Reality-visible: ${realityVisible.length}')),
                      Chip(label: Text('Source: $_sourceLabel')),
                      Chip(
                        label: Text(_isBackendConnected
                            ? 'Backend: connected'
                            : 'Backend: pending'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusSummaryCard(context),
          const SizedBox(height: 12),
          _buildAlertsCard(context),
          const SizedBox(height: 12),
          _buildAdminOperatorPanel(context),
          const SizedBox(height: 12),
          _buildRealityModelPanel(context, realityVisible),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Admin Command Center'),
              subtitle: const Text(
                'Return to central admin navigation and oversight controls',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.commandCenter),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.travel_explore),
              title: const Text('Reality System Oversight'),
              subtitle: const Text(
                'Return to Reality/Universe/World oversight pages',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.realitySystemReality),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Runtime Boundary Note'),
              subtitle: const Text(
                'Admin app is control-plane only. Model actions are expected to run via internal backend service APIs with control-action audit logging.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummaryCard(BuildContext context) {
    int count(ResearchStatus status) =>
        _projects.where((project) => project.status == status).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Proposed: ${count(ResearchStatus.proposed)}')),
            Chip(label: Text('Running: ${count(ResearchStatus.running)}')),
            Chip(
                label:
                    Text('Human review: ${count(ResearchStatus.humanReview)}')),
            Chip(label: Text('Paused: ${count(ResearchStatus.paused)}')),
            Chip(label: Text('Completed: ${count(ResearchStatus.completed)}')),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Research Alerts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_alerts.isEmpty)
              const Text('No active alerts')
            else
              ..._alerts.take(8).map((alert) {
                final color = _alertColor(alert.severity);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                    color: color.withValues(alpha: 0.08),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${alert.title} (${alert.severity.name})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(alert.message),
                      const SizedBox(height: 4),
                      Text(
                        'Project: ${alert.projectId}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOperatorPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Operator View',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Review active research, move status, and add operator notes with full oversight context.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_projects.isEmpty)
              const Text('No projects in feed.')
            else
              ..._projects.map((project) => _buildProjectCard(
                    context,
                    project: project,
                    roleLabel: 'admin_operator',
                    canEditStatus: true,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRealityModelPanel(
    BuildContext context,
    List<ResearchProject> realityVisible,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reality Model View',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This mirrors what the reality model can read from research activity. Same feed, role-filtered visibility.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (realityVisible.isEmpty)
              const Text(
                  'No research projects currently visible to reality model.')
            else
              ...realityVisible.map((project) => _buildProjectCard(
                    context,
                    project: project,
                    roleLabel: 'reality_model_primary',
                    canEditStatus: false,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context, {
    required ResearchProject project,
    required String roleLabel,
    required bool canEditStatus,
  }) {
    final metricsText = project.metrics.entries
        .map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}')
        .join(' | ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(project.hypothesis),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Layer: ${_layerLabel(project.layer)}')),
              Chip(label: Text('Status: ${_statusLabel(project.status)}')),
              Chip(
                  label: Text(
                      'Approval: ${_approvalLabel(project.approvalStatus)}')),
              Chip(label: Text('Owner: ${project.ownerAgentId}')),
              Chip(
                  label: Text(
                      'Human approval: ${project.requiresHumanApproval ? 'required' : 'optional'}')),
            ],
          ),
          const SizedBox(height: 6),
          if (project.tags.isNotEmpty) Text('Tags: ${project.tags.join(', ')}'),
          if (metricsText.isNotEmpty) Text('Metrics: $metricsText'),
          if (project.impacts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Impact links: ${project.impacts.length}'),
            ...project.impacts.take(2).map(
                  (impact) => Text(
                    '${impact.entityType}/${impact.entityId} delta=${impact.delta.toStringAsFixed(3)} rollback=${impact.rollbackCheckpointId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
          ],
          const SizedBox(height: 8),
          Text(
            'Recent notes:',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          if (project.log.isEmpty)
            const Text('No notes yet.')
          else
            ...project.log.reversed.take(3).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '${entry.actorId}: ${entry.message}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canEditStatus)
                PopupMenuButton<ResearchStatus>(
                  onSelected: (status) => _updateStatus(
                    projectId: project.id,
                    status: status,
                    actorId: roleLabel,
                  ),
                  itemBuilder: (context) => ResearchStatus.values
                      .map(
                        (status) => PopupMenuItem<ResearchStatus>(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ),
                      )
                      .toList(growable: false),
                  child: const Chip(
                    avatar: Icon(Icons.tune, size: 16),
                    label: Text('Update status'),
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.note_add_outlined, size: 16),
                label:
                    Text(canEditStatus ? 'Add admin note' : 'Add model note'),
                onPressed: () => _appendNote(
                  context: context,
                  projectId: project.id,
                  actorId: roleLabel,
                ),
              ),
              if (canEditStatus && project.requiresHumanApproval)
                ActionChip(
                  avatar: const Icon(Icons.verified, size: 16),
                  label: const Text('Approve'),
                  onPressed: () => _resolveApproval(
                    projectId: project.id,
                    actorId: roleLabel,
                    approved: true,
                  ),
                ),
              if (canEditStatus && project.requiresHumanApproval)
                ActionChip(
                  avatar: const Icon(Icons.gpp_bad_outlined, size: 16),
                  label: const Text('Reject'),
                  onPressed: () => _rejectApprovalDialog(
                    context: context,
                    projectId: project.id,
                    actorId: roleLabel,
                  ),
                ),
              if (canEditStatus)
                ActionChip(
                  avatar: const Icon(Icons.link_outlined, size: 16),
                  label: const Text('Add impact'),
                  onPressed: () => _addImpactDialog(
                    context: context,
                    projectId: project.id,
                    actorId: roleLabel,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _appendNote({
    required BuildContext context,
    required String projectId,
    required String actorId,
  }) async {
    final service = _service;
    if (service == null || _isUpdating) return;

    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Research Note'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Add research observation, direction, concern, or next step.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (message == null || message.isEmpty) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });
    try {
      await service.appendProjectLog(
        projectId: projectId,
        actorId: actorId,
        message: message,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _updateStatus({
    required String projectId,
    required ResearchStatus status,
    required String actorId,
  }) async {
    final service = _service;
    if (service == null || _isUpdating) return;
    setState(() {
      _isUpdating = true;
    });
    try {
      await service.updateProjectStatus(
        projectId: projectId,
        status: status,
        actorId: actorId,
      );
      await service.recordControlAction(
        action: 'admin_status_transition',
        actorId: actorId,
        projectId: projectId,
        details: <String, dynamic>{'status': status.name},
      );
    } on ResearchActionBlockedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    final service = _service;
    if (service == null || _isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });
    try {
      final projects = await service.getProjects();
      final alerts = await service.getAlerts();
      if (!mounted) return;
      setState(() {
        _projects = [...projects]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _alerts = alerts;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _showExportDialog({required String format}) async {
    final payload = format == 'csv' ? _exportAsCsv() : _exportAsJson();
    final title =
        format == 'csv' ? 'Research Audit (CSV)' : 'Research Audit (JSON)';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: SelectableText(payload),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Clipboard.setData(ClipboardData(text: payload));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Research audit export copied to clipboard'),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  String _exportAsJson() {
    final mapped =
        _projects.map((project) => project.toJson()).toList(growable: false);
    return const JsonEncoder.withIndent('  ').convert(mapped);
  }

  String _exportAsCsv() {
    final rows = <String>[
      'project_id,title,layer,status,approval_status,visibility_scope,owner_agent,reality_model_can_view,requires_human_approval,impact_count,updated_at,log_actor,log_message,log_created_at',
    ];

    for (final project in _projects) {
      final log = project.log.isEmpty ? [null] : project.log;
      for (final entry in log) {
        rows.add([
          _escapeCsv(project.id),
          _escapeCsv(project.title),
          _escapeCsv(_layerLabel(project.layer)),
          _escapeCsv(_statusLabel(project.status)),
          _escapeCsv(_approvalLabel(project.approvalStatus)),
          _escapeCsv(project.visibilityScope.name),
          _escapeCsv(project.ownerAgentId),
          _escapeCsv(project.realityModelCanView.toString()),
          _escapeCsv(project.requiresHumanApproval.toString()),
          _escapeCsv(project.impacts.length.toString()),
          _escapeCsv(project.updatedAt.toIso8601String()),
          _escapeCsv(entry?.actorId ?? ''),
          _escapeCsv(entry?.message ?? ''),
          _escapeCsv(entry?.createdAt.toIso8601String() ?? ''),
        ].join(','));
      }
    }
    return rows.join('\n');
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> _resolveApproval({
    required String projectId,
    required String actorId,
    required bool approved,
    String? reason,
  }) async {
    final service = _service;
    if (service == null || _isUpdating) return;
    setState(() {
      _isUpdating = true;
    });
    try {
      await service.resolveApproval(
        projectId: projectId,
        actorId: actorId,
        approved: approved,
        reason: reason,
      );
      await service.recordControlAction(
        action: approved ? 'approve_project' : 'reject_project',
        actorId: actorId,
        projectId: projectId,
        details: <String, dynamic>{'reason': reason},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _rejectApprovalDialog({
    required BuildContext context,
    required String projectId,
    required String actorId,
  }) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Approval'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Rejection reason'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    await _resolveApproval(
      projectId: projectId,
      actorId: actorId,
      approved: false,
      reason: reason,
    );
  }

  Future<void> _addImpactDialog({
    required BuildContext context,
    required String projectId,
    required String actorId,
  }) async {
    final entityType = TextEditingController();
    final entityId = TextEditingController();
    final beforeMetric = TextEditingController();
    final afterMetric = TextEditingController();
    final rollbackId = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Impact Link'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: entityType,
                  decoration: const InputDecoration(labelText: 'Entity type'),
                ),
                TextField(
                  controller: entityId,
                  decoration: const InputDecoration(labelText: 'Entity ID'),
                ),
                TextField(
                  controller: beforeMetric,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Before metric'),
                ),
                TextField(
                  controller: afterMetric,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'After metric'),
                ),
                TextField(
                  controller: rollbackId,
                  decoration: const InputDecoration(
                    labelText: 'Rollback checkpoint ID',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final service = _service;
    if (service == null || _isUpdating) return;

    final before = double.tryParse(beforeMetric.text.trim());
    final after = double.tryParse(afterMetric.text.trim());
    if (before == null || after == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Before/after metrics must be numbers.')),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });
    try {
      await service.addImpactLink(
        projectId: projectId,
        actorId: actorId,
        link: ResearchImpactLink(
          entityType: entityType.text.trim(),
          entityId: entityId.text.trim(),
          beforeMetric: before,
          afterMetric: after,
          rollbackCheckpointId: rollbackId.text.trim(),
          recordedAt: DateTime.now(),
        ),
      );
      await service.recordControlAction(
        action: 'add_impact_link',
        actorId: actorId,
        projectId: projectId,
        details: <String, dynamic>{
          'entityType': entityType.text.trim(),
          'entityId': entityId.text.trim(),
          'rollbackCheckpointId': rollbackId.text.trim(),
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _refreshAlerts() async {
    final service = _service;
    if (service == null) return;
    try {
      final alerts = await service.getAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
      });
    } catch (_) {
      // Keep previous alert snapshot if retrieval fails.
    }
  }

  String _layerLabel(ResearchLayer layer) {
    switch (layer) {
      case ResearchLayer.reality:
        return 'Reality';
      case ResearchLayer.universe:
        return 'Universe';
      case ResearchLayer.world:
        return 'World';
      case ResearchLayer.crossLayer:
        return 'Cross Layer';
    }
  }

  String _statusLabel(ResearchStatus status) {
    switch (status) {
      case ResearchStatus.proposed:
        return 'Proposed';
      case ResearchStatus.running:
        return 'Running';
      case ResearchStatus.humanReview:
        return 'Human Review';
      case ResearchStatus.completed:
        return 'Completed';
      case ResearchStatus.paused:
        return 'Paused';
    }
  }

  String _approvalLabel(ResearchApprovalStatus status) {
    switch (status) {
      case ResearchApprovalStatus.notRequired:
        return 'Not Required';
      case ResearchApprovalStatus.pending:
        return 'Pending';
      case ResearchApprovalStatus.approved:
        return 'Approved';
      case ResearchApprovalStatus.rejected:
        return 'Rejected';
    }
  }

  Color _alertColor(ResearchAlertSeverity severity) {
    switch (severity) {
      case ResearchAlertSeverity.info:
        return AppColors.electricBlue;
      case ResearchAlertSeverity.warning:
        return AppColors.warning;
      case ResearchAlertSeverity.critical:
        return AppColors.error;
    }
  }
}
