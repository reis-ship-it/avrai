import 'dart:async';

import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_operations_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ModerationOperationsPage extends StatefulWidget {
  const ModerationOperationsPage({super.key});

  @override
  State<ModerationOperationsPage> createState() =>
      _ModerationOperationsPageState();
}

class _ModerationOperationsPageState extends State<ModerationOperationsPage> {
  BhamAdminOperationsService? _service;
  AdminAuthService? _authService;
  Timer? _refreshTimer;

  bool _isLoading = true;
  bool _isMutating = false;
  String? _error;
  List<AdminModerationRecord> _queue = const <AdminModerationRecord>[];
  List<GovernanceEvidence> _evidence = const <GovernanceEvidence>[];
  List<BreakGlassGrant> _breakGlassGrants = const <BreakGlassGrant>[];
  List<BreakGlassAuditEvent> _breakGlassAudit = const <BreakGlassAuditEvent>[];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _service = GetIt.instance<BhamAdminOperationsService>();
      _authService = GetIt.instance<AdminAuthService>();
      await _load();
      _refreshTimer =
          Timer.periodic(const Duration(seconds: 20), (_) => _load());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Moderation operations are unavailable: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _load() async {
    final service = _service;
    if (service == null) {
      return;
    }
    try {
      final results = await Future.wait<dynamic>([
        service.listModerationQueue(),
        service.listGovernanceEvidence(),
        service.listBreakGlassGrants(),
        service.listBreakGlassAuditEvents(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _queue = results[0] as List<AdminModerationRecord>;
        _evidence = results[1] as List<GovernanceEvidence>;
        _breakGlassGrants = results[2] as List<BreakGlassGrant>;
        _breakGlassAudit = results[3] as List<BreakGlassAuditEvent>;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load moderation operations: $error';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Moderation Operations',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        IconButton(
          onPressed: _isMutating ? null : _openBreakGlassDialog,
          icon: const Icon(Icons.lock_open_outlined),
          tooltip: 'Start break-glass',
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.warning.withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Human-only intervention lane'),
                  SizedBox(height: 8),
                  Text(
                    'Governance truth controls quarantine, rollback, reset, and break-glass. Behavior truth continues to learn only when not quarantined. Identity reveal is never the default path.',
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
              Chip(label: Text('Queue: ${_queue.length}')),
              Chip(
                  label: Text(
                      'Quarantined: ${_queue.where((item) => item.state == CreationModerationState.quarantined).length}')),
              Chip(label: Text('Evidence: ${_evidence.length}')),
              Chip(
                  label: Text(
                      'Break-glass active: ${_breakGlassGrants.where((grant) => grant.active).length}')),
            ],
          ),
          const SizedBox(height: 12),
          _buildManualActionCard(context),
          const SizedBox(height: 12),
          _buildQueueCard(context),
          const SizedBox(height: 12),
          _buildEvidenceCard(context),
          const SizedBox(height: 12),
          _buildBreakGlassCard(context),
        ],
      ),
    );
  }

  Widget _buildManualActionCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.report_gmailerrorred_outlined),
        title: const Text('Record direct human report'),
        subtitle: const Text(
          'Use this when a support thread or operator report becomes governance evidence.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _isMutating ? null : _openHumanReportDialog,
      ),
    );
  }

  Widget _buildQueueCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flagged content and moderation queue',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_queue.isEmpty)
              const Text('No moderation records exist yet.')
            else
              ..._queue.map((record) => Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _iconForTarget(record.target.type),
                          color: _colorForState(record.state),
                        ),
                        title: Text(record.target.title),
                        subtitle: Text(
                          '${record.target.type.name} • ${record.state.name}'
                          '${record.reason == null ? '' : ' • ${record.reason}'}',
                        ),
                        trailing: PopupMenuButton<ModerationAction>(
                          onSelected: (action) =>
                              _applyAction(record.target, action),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: ModerationAction.flag,
                              child: Text('Flag'),
                            ),
                            PopupMenuItem(
                              value: ModerationAction.pause,
                              child: Text('Pause'),
                            ),
                            PopupMenuItem(
                              value: ModerationAction.quarantine,
                              child: Text('Quarantine'),
                            ),
                            PopupMenuItem(
                              value: ModerationAction.remove,
                              child: Text('Remove'),
                            ),
                            PopupMenuItem(
                              value: ModerationAction.restore,
                              child: Text('Restore'),
                            ),
                            PopupMenuItem(
                              value: ModerationAction.rollback,
                              child: Text('Rollback'),
                            ),
                            PopupMenuItem(
                              value: ModerationAction.reset,
                              child: Text('Reset'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evidence and falsity queue',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_evidence.isEmpty)
              const Text('No governance evidence has been recorded yet.')
            else
              ..._evidence.take(12).map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.policy_outlined),
                    title: Text(item.target.title),
                    subtitle: Text(
                      '${item.reason.name} • ${item.summary}',
                    ),
                    trailing: Text('${(item.confidence * 100).round()}%'),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakGlassCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Break-glass timeline',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_breakGlassAudit.isEmpty)
              const Text('No break-glass events exist yet.')
            else
              ..._breakGlassAudit.take(12).map((event) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      event.eventType == BreakGlassAuditEventType.closed
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                    ),
                    title: Text(event.eventType.name),
                    subtitle: Text(
                      '${event.actorId} • ${_formatDate(event.recordedAtUtc)}',
                    ),
                    trailing: Text(event.grantId.substring(0, 6)),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _applyAction(
    ModerationTargetRef target,
    ModerationAction action,
  ) async {
    final service = _service;
    final auth = _authService;
    if (service == null || auth == null) {
      return;
    }
    setState(() {
      _isMutating = true;
    });
    try {
      await service.applyModerationAction(
        target: target,
        action: action,
        actorId: auth.getCurrentSession()?.username ?? 'admin_operator',
        reason: 'Wave 6 operator action: ${action.name}',
        evidenceReason: action == ModerationAction.flag
            ? QuarantineReason.directHumanReport
            : action == ModerationAction.pause
                ? QuarantineReason.safetyRisk
                : action == ModerationAction.quarantine
                    ? QuarantineReason.maliciousPayload
                    : action == ModerationAction.rollback ||
                            action == ModerationAction.reset
                        ? QuarantineReason.impossibleContradiction
                        : null,
      );
      await _load();
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _openHumanReportDialog() async {
    final targetController = TextEditingController();
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record direct human report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Target ID'),
            ),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Target title'),
            ),
            TextField(
              controller: summaryController,
              decoration: const InputDecoration(labelText: 'Summary'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Record'),
          ),
        ],
      ),
    );
    if (result != true || _service == null || _authService == null) {
      return;
    }
    setState(() {
      _isMutating = true;
    });
    try {
      final target = ModerationTargetRef(
        type: ModerationTargetType.event,
        id: targetController.text.trim(),
        title: titleController.text.trim().isEmpty
            ? 'Reported target'
            : titleController.text.trim(),
      );
      await _service!.recordEvidence(
        target: target,
        reason: QuarantineReason.directHumanReport,
        summary: summaryController.text.trim(),
        source: 'admin_support_report',
        confidence: 0.91,
      );
      await _service!.applyModerationAction(
        target: target,
        action: ModerationAction.flag,
        actorId:
            _authService!.getCurrentSession()?.username ?? 'admin_operator',
        reason: 'Direct human report received through admin lane.',
        evidenceReason: QuarantineReason.directHumanReport,
      );
      await _load();
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _openBreakGlassDialog() async {
    final targetIdsController = TextEditingController();
    final justificationController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start break-glass'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetIdsController,
              decoration: const InputDecoration(
                labelText: 'Target IDs (comma separated)',
              ),
            ),
            TextField(
              controller: justificationController,
              decoration: const InputDecoration(labelText: 'Justification'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (result != true || _service == null) {
      return;
    }
    setState(() {
      _isMutating = true;
    });
    try {
      await _service!.startBreakGlass(
        reasonCode: 'trust_breaking_incident',
        justification: justificationController.text.trim(),
        targetIds: targetIdsController.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
      );
      await _load();
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  IconData _iconForTarget(ModerationTargetType type) {
    switch (type) {
      case ModerationTargetType.user:
        return Icons.person_outline;
      case ModerationTargetType.agent:
        return Icons.smart_toy_outlined;
      case ModerationTargetType.spot:
        return Icons.place_outlined;
      case ModerationTargetType.list:
        return Icons.list_alt_outlined;
      case ModerationTargetType.club:
        return Icons.workspace_premium_outlined;
      case ModerationTargetType.community:
        return Icons.groups_outlined;
      case ModerationTargetType.event:
        return Icons.event_outlined;
    }
  }

  Color _colorForState(CreationModerationState state) {
    switch (state) {
      case CreationModerationState.active:
        return AppColors.electricGreen;
      case CreationModerationState.flagged:
      case CreationModerationState.paused:
        return AppColors.warning;
      case CreationModerationState.quarantined:
      case CreationModerationState.removed:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
