import 'dart:async';

import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/governed_run_kernel_service.dart';
import 'package:avrai_runtime_os/services/admin/security_immune_system_admin_service.dart';
import 'package:avrai_runtime_os/services/security/countermeasure_propagation_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class SecurityImmuneSystemPage extends StatefulWidget {
  const SecurityImmuneSystemPage({super.key});

  @override
  State<SecurityImmuneSystemPage> createState() =>
      _SecurityImmuneSystemPageState();
}

class _SecurityImmuneSystemPageState extends State<SecurityImmuneSystemPage> {
  SecurityImmuneSystemAdminService? _service;
  CountermeasurePropagationService? _propagationService;
  GovernedRunKernelService? _governedRunKernel;
  StreamSubscription<SecurityImmuneSystemAdminSnapshot>? _subscription;
  SecurityImmuneSystemAdminSnapshot? _snapshot;
  bool _isLoading = true;
  String? _error;
  String? _activeActionKey;

  String _selectedStratum = 'all';
  String _selectedTenant = 'all';
  String _selectedSphere = 'all';
  String _selectedFamily = 'all';
  String _selectedAgentClass = 'all';

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance.isRegistered<SecurityImmuneSystemAdminService>()
        ? GetIt.instance<SecurityImmuneSystemAdminService>()
        : null;
    _propagationService =
        GetIt.instance.isRegistered<CountermeasurePropagationService>()
            ? GetIt.instance<CountermeasurePropagationService>()
            : null;
    _governedRunKernel = GetIt.instance.isRegistered<GovernedRunKernelService>()
        ? GetIt.instance<GovernedRunKernelService>()
        : null;
    _startWatching();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startWatching() {
    final service = _service;
    if (service == null) {
      setState(() {
        _isLoading = false;
        _error = 'Security immune-system admin service is unavailable.';
      });
      return;
    }
    _subscription = service
        .watchSnapshot(refreshInterval: const Duration(seconds: 10))
        .listen(
      (snapshot) {
        if (!mounted) {
          return;
        }
        setState(() {
          _snapshot = snapshot;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _error = 'Failed to load security immune-system cockpit: $error';
        });
      },
    );
  }

  Future<void> _refresh() async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await service.getSnapshot(limit: 32);
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Failed to load security immune-system cockpit: $error';
      });
    }
  }

  Future<void> _runAction({
    required String actionKey,
    required Future<void> Function() action,
    bool refreshAfter = true,
  }) async {
    if (_activeActionKey != null) {
      return;
    }
    setState(() => _activeActionKey = actionKey);
    try {
      await action();
      if (refreshAfter) {
        await _refresh();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activeActionKey = null);
      }
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _acknowledgeReceipt(
    CountermeasurePropagationReceipt receipt,
  ) async {
    final service = _propagationService;
    if (service == null) {
      throw StateError('Countermeasure propagation service is unavailable.');
    }
    await _runAction(
      actionKey: 'ack:${receipt.receiptId}',
      action: () => service.acknowledgeReceipt(
        receiptId: receipt.receiptId,
        actorAlias: 'admin_operator',
      ),
    );
  }

  Future<void> _activateBundle(
    CountermeasureBundleCandidate candidate,
  ) async {
    final service = _propagationService;
    if (service == null) {
      throw StateError('Countermeasure propagation service is unavailable.');
    }
    final confirmed = await _confirmAction(
      title: 'Activate Bundle',
      body:
          'Activate ${candidate.bundle.bundleId} for ${candidate.bundle.targetScope.scopeKey}? '
          'This keeps rollout inside the shared security release gate.',
      confirmLabel: 'Activate',
    );
    if (!confirmed) {
      return;
    }
    await _runAction(
      actionKey: 'activate:${candidate.bundle.bundleId}',
      action: () => service.activateBundle(
        candidate.bundle.bundleId,
        actorAlias: 'admin_operator',
        operatorApproved: true,
      ),
    );
  }

  Future<void> _rollbackBundle(
    CountermeasureBundleCandidate candidate, {
    required String reason,
    bool falsePositive = false,
  }) async {
    final service = _propagationService;
    if (service == null) {
      throw StateError('Countermeasure propagation service is unavailable.');
    }
    final confirmed = await _confirmAction(
      title: falsePositive ? 'Confirm False Positive' : 'Rollback Bundle',
      body: falsePositive
          ? 'Mark ${candidate.bundle.bundleId} as a false positive and roll it back?'
          : 'Rollback ${candidate.bundle.bundleId} across staged/active scopes?',
      confirmLabel: falsePositive ? 'Confirm Review' : 'Rollback',
    );
    if (!confirmed) {
      return;
    }
    await _runAction(
      actionKey: 'rollback:${candidate.bundle.bundleId}:$reason',
      action: () => service.rollbackBundle(
        bundleId: candidate.bundle.bundleId,
        reason: reason,
        falsePositive: falsePositive,
      ),
    );
  }

  Future<void> _markStale(String bundleId) async {
    final service = _propagationService;
    if (service == null) {
      throw StateError('Countermeasure propagation service is unavailable.');
    }
    await _runAction(
      actionKey: 'stale:$bundleId',
      action: () => service.markStaleReceipts(bundleId: bundleId),
    );
  }

  Future<void> _openGovernedRunDetail(String runId) async {
    final service = _governedRunKernel;
    if (service == null) {
      throw StateError('Governed run kernel service is unavailable.');
    }
    final record = await service.getRun(runId);
    if (!mounted || record == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${record.runKind.name} • ${record.title}'),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailLine('Lifecycle', record.lifecycleState.name),
                _detailLine('Disposition', record.disposition.name),
                _detailLine('Environment', record.environment.name),
                _detailLine('Truth Scope', record.truthScope.scopeKey),
                _detailLine('Authority', record.authorityToken),
                _detailLine(
                  'Approvals',
                  record.requiresAdminApproval ? 'required' : 'not required',
                ),
                if (record.latestSummary?.isNotEmpty == true)
                  _detailLine('Latest Summary', record.latestSummary!),
                const SizedBox(height: 12),
                Text(
                  'Recent Directives',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (record.directives.isEmpty)
                  const Text('No directives recorded.')
                else
                  ...record.directives.take(5).map(
                        (directive) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${directive.kind.name} • ${directive.actorAlias} • ${directive.rationale}',
                          ),
                        ),
                      ),
                const SizedBox(height: 12),
                Text(
                  'Recent Checkpoints',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (record.checkpoints.isEmpty)
                  const Text('No checkpoints recorded.')
                else
                  ...record.checkpoints.take(5).map(
                        (checkpoint) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${checkpoint.state.name} • ${checkpoint.disposition.name} • ${checkpoint.summary}',
                          ),
                        ),
                      ),
                const SizedBox(height: 12),
                Text(
                  'Raw detail escalation remains read-only and requires a governance audit receipt.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Security Immune System',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh security cockpit',
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
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final snapshot = _snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final allScopes = <TruthScopeDescriptor>[
      ...snapshot.recentRuns.map((entry) => entry.truthScope),
      ...snapshot.recentFindings.map((entry) => entry.truthScope),
      ...snapshot.recentMemory.map((entry) => entry.truthScope),
      ...snapshot.recentGovernedRuns.map((entry) => entry.truthScope),
    ];

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(context, snapshot),
          const SizedBox(height: 12),
          _buildFilterCard(context, allScopes),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'Live Campaign Queue',
            child: _buildCampaignList(snapshot),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'Findings Queue',
            child: _buildFindingsList(snapshot),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'Immune Memory Ledger',
            child: _buildMemoryList(snapshot),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'Bundle Promotion Queue',
            child: _buildBundleList(snapshot),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'Propagation and Rollback',
            child: _buildPropagationList(snapshot),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'Scout Health',
            child: _buildScoutList(snapshot),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'False-Positive Review',
            child: _buildFalsePositiveList(snapshot),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            context,
            title: 'Governed Run Oversight',
            child: _buildGovernedRunList(snapshot),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    SecurityImmuneSystemAdminSnapshot snapshot,
  ) {
    final gate = snapshot.releaseGate;
    return Card(
      color: gate.servingAllowed
          ? AppColors.electricGreen.withValues(alpha: 0.08)
          : AppColors.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gate.servingAllowed
                  ? 'Release posture is clear or bounded-degraded'
                  : 'Release posture is blocked',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Raw detail escalation requires governance audit receipt. This surface defaults to compressed truth.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Campaigns', snapshot.campaignCount.toString()),
                _chip('Pending review', snapshot.pendingReviewCount.toString()),
                _chip('Findings', snapshot.findingCount.toString()),
                _chip('Bundles', snapshot.bundleCandidateCount.toString()),
                _chip('Receipts', snapshot.propagationReceiptCount.toString()),
                _chip('Scouts', snapshot.scoutCount.toString()),
                _chip('Autonomy gate',
                    snapshot.blockingAutonomyExpansion ? 'blocked' : 'clear'),
                _chip('Release gate', gate.servingAllowed ? 'allow' : 'block'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Release readiness criteria',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: snapshot.readinessChecks.entries.map((entry) {
                return Chip(
                  avatar: Icon(
                    entry.value
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 18,
                    color: entry.value
                        ? AppColors.electricGreen
                        : AppColors.warning,
                  ),
                  label: Text(_formatCriterionLabel(entry.key)),
                );
              }).toList(),
            ),
            if (gate.reasonCodes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: gate.reasonCodes
                    .map((entry) => Chip(label: Text(entry)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    List<TruthScopeDescriptor> scopes,
  ) {
    final strata = _collectOptions(
      scopes.map((entry) => entry.governanceStratum.name),
    );
    final tenants = _collectOptions(
      scopes.map((entry) => entry.tenantScope.name),
    );
    final spheres = _collectOptions(scopes.map((entry) => entry.sphereId));
    final families = _collectOptions(scopes.map((entry) => entry.familyId));
    final agentClasses = _collectOptions(
      scopes.map((entry) => entry.agentClass.name),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _dropdown(
              label: 'Stratum',
              value: _selectedStratum,
              values: strata,
              onChanged: (value) => setState(() => _selectedStratum = value),
            ),
            _dropdown(
              label: 'Tenant',
              value: _selectedTenant,
              values: tenants,
              onChanged: (value) => setState(() => _selectedTenant = value),
            ),
            _dropdown(
              label: 'Sphere',
              value: _selectedSphere,
              values: spheres,
              onChanged: (value) => setState(() => _selectedSphere = value),
            ),
            _dropdown(
              label: 'Family',
              value: _selectedFamily,
              values: families,
              onChanged: (value) => setState(() => _selectedFamily = value),
            ),
            _dropdown(
              label: 'Agent',
              value: _selectedAgentClass,
              values: agentClasses,
              onChanged: (value) => setState(() => _selectedAgentClass = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignList(SecurityImmuneSystemAdminSnapshot snapshot) {
    final rows =
        snapshot.recentRuns.where((entry) => _matchesScope(entry.truthScope));
    if (rows.isEmpty) {
      return const Text('No campaigns match the current filters.');
    }
    return Column(
      children: rows.take(8).map((run) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${run.laneId} • ${run.name}'),
          subtitle: Text(
            '${run.status.name} • ${run.disposition.name} • coverage ${(run.proofCoverageScore * 100).round()}% • '
            '${run.ownerAlias} / ${run.ownershipArea} • ${run.truthScope.scopeKey}',
          ),
          trailing: run.autoClearEligible
              ? const Icon(Icons.verified_outlined,
                  color: AppColors.electricGreen)
              : const Icon(Icons.error_outline, color: AppColors.warning),
        );
      }).toList(),
    );
  }

  Widget _buildFindingsList(SecurityImmuneSystemAdminSnapshot snapshot) {
    final findings = snapshot.recentFindings
        .where((entry) => _matchesScope(entry.truthScope));
    if (findings.isEmpty) {
      return const Text('No findings match the current filters.');
    }
    return Column(
      children: findings.take(8).map((finding) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(finding.title),
          subtitle: Text(
            '${finding.severity.name} • ${finding.disposition.name} • ${finding.summary}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemoryList(SecurityImmuneSystemAdminSnapshot snapshot) {
    final memory =
        snapshot.recentMemory.where((entry) => _matchesScope(entry.truthScope));
    if (memory.isEmpty) {
      return const Text('No immune-memory records match the current filters.');
    }
    return Column(
      children: memory.take(8).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.signature),
          subtitle: Text(
            '${entry.recurrenceRiskTag} • ${entry.affectedSurfaces.join(", ")}',
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBundleList(SecurityImmuneSystemAdminSnapshot snapshot) {
    final bundles = snapshot.recentBundles
        .where((entry) => _matchesScope(entry.bundle.targetScope));
    if (bundles.isEmpty) {
      return const Text('No bundle candidates match the current filters.');
    }
    return Column(
      children: bundles.take(8).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.bundle.bundleId),
          subtitle: Text(
            '${entry.status.name} • approvals ${entry.approvalActors.length}/${entry.bundle.requiredApprovals.length} • ${entry.bundle.targetScope.scopeKey}',
          ),
          trailing: Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _canActivateBundle(entry, snapshot)
                    ? () => _activateBundle(entry)
                    : null,
                child: const Text('Activate'),
              ),
              TextButton(
                onPressed: _canRollbackBundle(entry, snapshot)
                    ? () => _rollbackBundle(
                          entry,
                          reason: 'operator_requested_rollback',
                        )
                    : null,
                child: const Text('Rollback'),
              ),
              TextButton(
                onPressed: _canConfirmFalsePositive(entry, snapshot)
                    ? () => _rollbackBundle(
                          entry,
                          reason: 'false_positive_review_confirmed',
                          falsePositive: true,
                        )
                    : null,
                child: const Text('False Positive'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPropagationList(SecurityImmuneSystemAdminSnapshot snapshot) {
    final receipts = snapshot.recentPropagationReceipts
        .where((entry) => _matchesScope(entry.targetScope));
    if (receipts.isEmpty) {
      return const Text('No propagation receipts match the current filters.');
    }
    return Column(
      children: receipts.take(8).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.bundleId),
          subtitle: Text(
            '${entry.activationStage} • ack ${entry.acknowledgedCount}/${entry.requiredAcknowledgements} • stale ${entry.staleNode} • rolled back ${entry.rolledBack}',
          ),
          trailing: Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _canAcknowledgeReceipt(entry)
                    ? () => _acknowledgeReceipt(entry)
                    : null,
                child: const Text('Acknowledge'),
              ),
              TextButton(
                onPressed: _canMarkStale(entry)
                    ? () => _markStale(entry.bundleId)
                    : null,
                child: const Text('Mark Stale'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoutList(SecurityImmuneSystemAdminSnapshot snapshot) {
    final scouts =
        snapshot.recentScouts.where((entry) => _matchesScope(entry.truthScope));
    if (scouts.isEmpty) {
      return const Text('No scouts match the current filters.');
    }
    return Column(
      children: scouts.take(8).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.alias),
          subtitle: Text(
            '${entry.truthScope.scopeKey} • active campaigns ${entry.activeCampaignCount} • probe-only ${entry.probeOnly}',
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFalsePositiveList(SecurityImmuneSystemAdminSnapshot snapshot) {
    final learning = snapshot.recentLearningMoments.where(
      (entry) =>
          _matchesScope(entry.truthScope) &&
          (entry.falsePositive ||
              entry.kind == SecurityLearningMomentKind.falsePositive),
    );
    if (learning.isEmpty) {
      return const Text(
          'No false-positive review items match the current filters.');
    }
    return Column(
      children: learning.take(8).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.kind.name),
          subtitle: Text(entry.summary),
        );
      }).toList(),
    );
  }

  Widget _buildGovernedRunList(SecurityImmuneSystemAdminSnapshot snapshot) {
    final runs = snapshot.recentGovernedRuns
        .where((entry) => _matchesScope(entry.truthScope));
    if (runs.isEmpty) {
      return const Text('No governed runs match the current filters.');
    }
    return Column(
      children: runs.take(12).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${entry.runKind.name} • ${entry.title}'),
          subtitle: Text(
            '${entry.disposition.name} • ${entry.lifecycleState.name} • ${entry.truthScope.scopeKey}',
          ),
          trailing: TextButton(
            onPressed: _governedRunKernel == null
                ? null
                : () => _openGovernedRunDetail(entry.id),
            child: const Text('Details'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map(
              (entry) => DropdownMenuItem<String>(
                value: entry,
                child: Text(
                  entry,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }

  Chip _chip(String label, String value) => Chip(label: Text('$label: $value'));

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _formatCriterionLabel(String key) {
    switch (key) {
      case 'critical_lanes_mapped':
        return 'Critical lanes mapped';
      case 'no_missing_proof_coverage':
        return 'No missing proof coverage';
      case 'no_unsigned_active_bundles':
        return 'No unsigned active bundles';
      case 'no_stale_active_rollouts':
        return 'No stale active rollouts';
      case 'no_critical_hard_stops':
        return 'No critical hard stops';
      case 'release_gate_clear_or_approved':
        return 'Release gate clear or approved';
    }
    return key.replaceAll('_', ' ');
  }

  List<CountermeasurePropagationReceipt> _bundleReceipts(
    SecurityImmuneSystemAdminSnapshot snapshot,
    String bundleId,
  ) {
    return snapshot.recentPropagationReceipts
        .where((entry) => entry.bundleId == bundleId)
        .toList(growable: false);
  }

  bool _canActivateBundle(
    CountermeasureBundleCandidate candidate,
    SecurityImmuneSystemAdminSnapshot snapshot,
  ) {
    if (_activeActionKey != null || _propagationService == null) {
      return false;
    }
    if (candidate.status == CountermeasureBundleCandidateStatus.active ||
        candidate.status == CountermeasureBundleCandidateStatus.rolledBack ||
        candidate.status == CountermeasureBundleCandidateStatus.retired) {
      return false;
    }
    final receipts = _bundleReceipts(snapshot, candidate.bundle.bundleId);
    if (receipts.isEmpty) {
      return false;
    }
    return receipts.every(
      (entry) =>
          entry.approvalGranted &&
          !entry.driftDetected &&
          !entry.staleNode &&
          !entry.rolledBack &&
          entry.acknowledgedCount >= entry.requiredAcknowledgements &&
          entry.activationStage != 'active',
    );
  }

  bool _canRollbackBundle(
    CountermeasureBundleCandidate candidate,
    SecurityImmuneSystemAdminSnapshot snapshot,
  ) {
    if (_activeActionKey != null || _propagationService == null) {
      return false;
    }
    return _bundleReceipts(snapshot, candidate.bundle.bundleId).any(
      (entry) => !entry.rolledBack && entry.activationStage == 'active',
    );
  }

  bool _canConfirmFalsePositive(
    CountermeasureBundleCandidate candidate,
    SecurityImmuneSystemAdminSnapshot snapshot,
  ) {
    if (_activeActionKey != null || _propagationService == null) {
      return false;
    }
    return _bundleReceipts(snapshot, candidate.bundle.bundleId)
        .any((entry) => !entry.rolledBack);
  }

  bool _canAcknowledgeReceipt(CountermeasurePropagationReceipt receipt) {
    if (_activeActionKey != null || _propagationService == null) {
      return false;
    }
    return !receipt.rolledBack &&
        !receipt.staleNode &&
        receipt.activationStage != 'active' &&
        receipt.acknowledgedCount < receipt.requiredAcknowledgements;
  }

  bool _canMarkStale(CountermeasurePropagationReceipt receipt) {
    if (_activeActionKey != null || _propagationService == null) {
      return false;
    }
    return !receipt.rolledBack &&
        !receipt.staleNode &&
        receipt.acknowledgedCount < receipt.requiredAcknowledgements;
  }

  List<String> _collectOptions(Iterable<String> values) {
    final unique = values
        .where((entry) => entry.trim().isNotEmpty)
        .toSet()
        .toList(growable: true)
      ..sort();
    return <String>['all', ...unique];
  }

  bool _matchesScope(TruthScopeDescriptor scope) {
    return (_selectedStratum == 'all' ||
            scope.governanceStratum.name == _selectedStratum) &&
        (_selectedTenant == 'all' ||
            scope.tenantScope.name == _selectedTenant) &&
        (_selectedSphere == 'all' || scope.sphereId == _selectedSphere) &&
        (_selectedFamily == 'all' || scope.familyId == _selectedFamily) &&
        (_selectedAgentClass == 'all' ||
            scope.agentClass.name == _selectedAgentClass);
  }
}
