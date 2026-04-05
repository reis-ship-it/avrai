import 'dart:async';

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/research_activity_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResearchCenterPage extends StatefulWidget {
  const ResearchCenterPage({
    super.key,
    this.initialFocus,
    this.initialAttention,
  });

  final String? initialFocus;
  final String? initialAttention;

  @override
  State<ResearchCenterPage> createState() => _ResearchCenterPageState();
}

class _SensitiveActionApproval {
  const _SensitiveActionApproval({
    required this.stepUpProof,
    this.secondOperatorApproval,
  });

  final AdminControlPlaneStepUpProof stepUpProof;
  final AdminControlPlaneSecondOperatorApproval? secondOperatorApproval;
}

class _ResearchCenterPageState extends State<ResearchCenterPage> {
  GovernedAutoresearchSupervisor? _service;
  StreamSubscription<List<ResearchRunState>>? _runsSubscription;

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;
  List<ResearchRunState> _runs = <ResearchRunState>[];
  List<ResearchAlert> _alerts = <ResearchAlert>[];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _runsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferencesCompat.getInstance();
      final resolution =
          await GovernedAutoresearchSupervisorFactory.createDefault(
        prefs: prefs,
      );
      final service = resolution.service;
      _service = service;
      _runsSubscription = service.watchRuns().listen(
        (List<ResearchRunState> runs) async {
          if (!mounted) {
            return;
          }
          final alerts = await service.listAlerts();
          if (!mounted) {
            return;
          }
          setState(() {
            _runs = runs;
            _alerts = alerts;
            _isLoading = false;
            _error = null;
          });
        },
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _error = 'Private autoresearch backend unavailable: $error';
            _isLoading = false;
          });
        },
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Research Center',
      actions: [
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
              const Icon(Icons.lock_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Governed Autoresearch is fail-closed in beta.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('Retry private backend'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.initialFocus != null || widget.initialAttention != null)
            _buildCommandCenterContextCard(context),
          if (widget.initialFocus != null || widget.initialAttention != null)
            const SizedBox(height: 12),
          _buildSecurityBanner(context),
          const SizedBox(height: 12),
          _buildStateSummary(context),
          const SizedBox(height: 12),
          _buildAlertsCard(context),
          const SizedBox(height: 12),
          _buildRunList(context),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Admin Command Center'),
              subtitle: const Text(
                'Return to central admin navigation and oversight controls.',
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
                'Open adjacent runtime oversight surfaces for reality, universe, and world.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.realitySystemReality),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin-Only Governed Autoresearch',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This beta surface is private control-plane only. '
              'Sandbox runs stay off consumer routes, off public ingress, '
              'and out of production mutation paths.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('Human access: admin-only')),
                Chip(label: Text('Lane: sandbox/replay only')),
                Chip(label: Text('Consumer reachability: blocked')),
                Chip(label: Text('Open web: brokered approval only')),
              ],
            ),
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This research surface was opened from the command-center attention queue with carried operator context.',
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

  Widget _buildStateSummary(BuildContext context) {
    int count(ResearchRunLifecycleState state) => _runs
        .where((ResearchRunState run) => run.lifecycleState == state)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
                label:
                    Text('Draft: ${count(ResearchRunLifecycleState.draft)}')),
            Chip(
                label: Text(
                    'Approved: ${count(ResearchRunLifecycleState.approved)}')),
            Chip(
                label:
                    Text('Queued: ${count(ResearchRunLifecycleState.queued)}')),
            Chip(
                label: Text(
                    'Running: ${count(ResearchRunLifecycleState.running)}')),
            Chip(
                label:
                    Text('Paused: ${count(ResearchRunLifecycleState.paused)}')),
            Chip(
                label:
                    Text('Review: ${count(ResearchRunLifecycleState.review)}')),
            Chip(
                label: Text(
                    'Completed: ${count(ResearchRunLifecycleState.completed)}')),
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
              'Governance Alerts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_alerts.isEmpty)
              const Text('No active alerts.')
            else
              ..._alerts.take(8).map((ResearchAlert alert) {
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
                        'Run: ${alert.runId}',
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

  Widget _buildRunList(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Operator Cockpit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Inspect runs, pause, stop, resume, redirect, approve, reject, or explain. '
              'All actions are audited and sandbox-only.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_runs.isEmpty)
              const Text('No governed research runs available.')
            else
              ..._runs
                  .map((ResearchRunState run) => _buildRunCard(context, run)),
          ],
        ),
      ),
    );
  }

  Widget _buildRunCard(BuildContext context, ResearchRunState run) {
    final latestCheckpoint =
        run.checkpoints.isEmpty ? null : run.checkpoints.last;
    final latestAction =
        run.controlActions.isEmpty ? null : run.controlActions.last;
    final latestExplanation = run.latestExplanation;
    final openWebPending = run.approvals.any(
      (ResearchApproval approval) =>
          approval.kind == ResearchApprovalKind.egressOpenWeb &&
          approval.status == ResearchApprovalStatus.pending,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(run.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(run.hypothesis),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Layer: ${_layerLabel(run.layer)}')),
              Chip(label: Text('State: ${_stateLabel(run.lifecycleState)}')),
              Chip(label: Text('Owner: ${run.ownerAgentAlias}')),
              Chip(label: Text('Lane: ${run.lane.name}')),
              Chip(label: Text('Human: ${run.humanAccess.name}')),
              Chip(label: Text('Egress: ${_egressLabel(run, openWebPending)}')),
              if (run.killSwitchActive)
                const Chip(label: Text('Kill switch active')),
            ],
          ),
          const SizedBox(height: 10),
          _buildSection(
            context,
            title: 'Charter',
            body:
                '${run.charter.objective}\nAllowed surfaces: ${run.charter.allowedExperimentSurfaces.join(', ')}\nHard bans: ${run.charter.hardBans.join(', ')}',
          ),
          const SizedBox(height: 8),
          _buildSection(
            context,
            title: 'Explanation',
            body: latestExplanation == null
                ? 'No explanation generated yet.'
                : '${latestExplanation.summary}\nCurrent: ${latestExplanation.currentStep}\nNext: ${latestExplanation.nextStep}\nEvidence: ${latestExplanation.evidenceSummary}',
          ),
          const SizedBox(height: 8),
          _buildSection(
            context,
            title: 'Checkpoint',
            body: latestCheckpoint == null
                ? 'No checkpoints recorded.'
                : '${latestCheckpoint.summary}\nCheckpoint ID: ${latestCheckpoint.id}\nRequires review: ${latestCheckpoint.requiresHumanReview ? 'yes' : 'no'}',
          ),
          const SizedBox(height: 8),
          _buildSection(
            context,
            title: 'Audit',
            body: latestAction == null
                ? 'No control actions yet.'
                : '${latestAction.actorAlias}: ${latestAction.rationale}\nPolicy: ${latestAction.policyVersion} | Model: ${latestAction.modelVersion}',
          ),
          const SizedBox(height: 8),
          if (run.metrics.isNotEmpty)
            Text(
              'Metrics: ${run.metrics.entries.map((entry) => '${entry.key}=${entry.value.toStringAsFixed(2)}').join(' | ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildActionChips(run),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(body, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  List<Widget> _buildActionChips(ResearchRunState run) {
    final openWebPending = run.approvals.any(
      (ResearchApproval approval) =>
          approval.kind == ResearchApprovalKind.egressOpenWeb &&
          approval.status == ResearchApprovalStatus.pending,
    );
    final List<Widget> chips = <Widget>[
      ActionChip(
        avatar: const Icon(Icons.help_outline, size: 16),
        label: const Text('Explain'),
        onPressed: _isUpdating
            ? null
            : () => _handleRunAction(
                  (service) => service.getExplanation(
                    runId: run.id,
                    actorAlias: 'admin_operator',
                  ),
                ),
      ),
    ];

    switch (run.lifecycleState) {
      case ResearchRunLifecycleState.draft:
        chips.addAll(<Widget>[
          ActionChip(
            avatar: const Icon(Icons.verified, size: 16),
            label: const Text('Approve'),
            onPressed: _isUpdating
                ? null
                : () => _handleRunAction(
                      (service) => service.approveCharter(
                        runId: run.id,
                        actorAlias: 'admin_operator',
                      ),
                    ),
          ),
          ActionChip(
            avatar: const Icon(Icons.gpp_bad_outlined, size: 16),
            label: const Text('Reject'),
            onPressed: _isUpdating ? null : () => _rejectRun(run),
          ),
        ]);
        break;
      case ResearchRunLifecycleState.approved:
        chips.add(
          ActionChip(
            avatar: const Icon(Icons.playlist_add_check, size: 16),
            label: const Text('Queue'),
            onPressed: _isUpdating
                ? null
                : () => _handleRunAction(
                      (service) => service.queueRun(
                        runId: run.id,
                        actorAlias: 'admin_operator',
                      ),
                    ),
          ),
        );
        break;
      case ResearchRunLifecycleState.queued:
        chips.addAll(<Widget>[
          ActionChip(
            avatar: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Start'),
            onPressed: _isUpdating
                ? null
                : () => _handleRunAction(
                      (service) => service.startSandboxRun(
                        runId: run.id,
                        actorAlias: 'admin_operator',
                      ),
                    ),
          ),
          ActionChip(
            avatar: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('Stop'),
            onPressed: _isUpdating ? null : () => _stopRun(run),
          ),
        ]);
        break;
      case ResearchRunLifecycleState.running:
        chips.addAll(<Widget>[
          ActionChip(
            avatar: const Icon(Icons.pause, size: 16),
            label: const Text('Pause'),
            onPressed: _isUpdating
                ? null
                : () => _handleRunAction(
                      (service) => service.pauseRun(
                        runId: run.id,
                        actorAlias: 'admin_operator',
                      ),
                    ),
          ),
          if (openWebPending)
            ActionChip(
              avatar: const Icon(Icons.verified_outlined, size: 16),
              label: const Text('Approve open web'),
              onPressed: _isUpdating ? null : () => _approveOpenWeb(run),
            )
          else
            ActionChip(
              avatar: const Icon(Icons.language_outlined, size: 16),
              label: const Text('Request open web'),
              onPressed: _isUpdating ? null : () => _requestOpenWeb(run),
            ),
          if (openWebPending)
            ActionChip(
              avatar: const Icon(Icons.gpp_bad_outlined, size: 16),
              label: const Text('Reject open web'),
              onPressed: _isUpdating ? null : () => _rejectOpenWeb(run),
            ),
          ActionChip(
            avatar: const Icon(Icons.emergency_outlined, size: 16),
            label: const Text('Kill switch'),
            onPressed: _isUpdating ? null : () => _triggerKillSwitch(run),
          ),
          ActionChip(
            avatar: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('Stop'),
            onPressed: _isUpdating ? null : () => _stopRun(run),
          ),
        ]);
        break;
      case ResearchRunLifecycleState.paused:
        chips.addAll(<Widget>[
          ActionChip(
            avatar: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Resume'),
            onPressed: _isUpdating
                ? null
                : () => _handleRunAction(
                      (service) => service.resumeRun(
                        runId: run.id,
                        actorAlias: 'admin_operator',
                      ),
                    ),
          ),
          ActionChip(
            avatar: const Icon(Icons.alt_route, size: 16),
            label: const Text('Redirect'),
            onPressed: _isUpdating ? null : () => _redirectRun(run),
          ),
          ActionChip(
            avatar: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('Stop'),
            onPressed: _isUpdating ? null : () => _stopRun(run),
          ),
        ]);
        break;
      case ResearchRunLifecycleState.review:
        chips.addAll(<Widget>[
          ActionChip(
            avatar: const Icon(Icons.verified, size: 16),
            label: Text(openWebPending ? 'Approve open web' : 'Approve'),
            onPressed: _isUpdating
                ? null
                : () =>
                    openWebPending ? _approveOpenWeb(run) : _approveRun(run),
          ),
          ActionChip(
            avatar: const Icon(Icons.gpp_bad_outlined, size: 16),
            label: Text(openWebPending ? 'Reject open web' : 'Reject'),
            onPressed: _isUpdating
                ? null
                : () =>
                    openWebPending ? _rejectOpenWeb(run) : _rejectReview(run),
          ),
          ActionChip(
            avatar: const Icon(Icons.alt_route, size: 16),
            label: const Text('Redirect'),
            onPressed: _isUpdating ? null : () => _redirectRun(run),
          ),
        ]);
        break;
      case ResearchRunLifecycleState.redirectPending:
        chips.add(
          ActionChip(
            avatar: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('Stop'),
            onPressed: _isUpdating ? null : () => _stopRun(run),
          ),
        );
        break;
      case ResearchRunLifecycleState.stopped:
      case ResearchRunLifecycleState.completed:
      case ResearchRunLifecycleState.failed:
      case ResearchRunLifecycleState.archived:
      case ResearchRunLifecycleState.pausing:
        break;
    }

    return chips;
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
      final runs = await service.listRuns();
      final alerts = await service.listAlerts();
      if (!mounted) {
        return;
      }
      setState(() {
        _runs = runs;
        _alerts = alerts;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _handleRunAction(
    Future<Object?> Function(GovernedAutoresearchSupervisor service) action,
  ) async {
    final service = _service;
    if (service == null || _isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });
    try {
      await action(service);
      await _refresh();
    } on GovernedAutoresearchActionBlockedException catch (error) {
      _showSnack(error.message);
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _rejectRun(ResearchRunState run) async {
    final rationale = await _promptForText(
      title: 'Reject Charter',
      hintText: 'Explain why this charter should be rejected.',
      confirmLabel: 'Reject',
    );
    if (rationale == null || rationale.isEmpty) {
      return;
    }
    await _handleRunAction(
      (service) => service.rejectCharter(
        runId: run.id,
        actorAlias: 'admin_operator',
        rationale: rationale,
      ),
    );
  }

  Future<void> _stopRun(ResearchRunState run) async {
    final rationale = await _promptForText(
      title: 'Stop Run',
      hintText: 'Reason for stopping this run.',
      confirmLabel: 'Stop',
    );
    if (rationale == null) {
      return;
    }
    final approval = await _promptForSensitiveApproval(
      title: 'Stop Run Step-Up',
      confirmLabel: 'Confirm stop',
    );
    if (approval == null) {
      return;
    }
    await _handleRunAction(
      (service) => service.stopRun(
        runId: run.id,
        actorAlias: 'admin_operator',
        rationale: rationale,
        stepUpProof: approval.stepUpProof,
      ),
    );
  }

  Future<void> _redirectRun(ResearchRunState run) async {
    final directive = await _promptForText(
      title: 'Redirect Run',
      hintText: 'Describe the revised research direction.',
      confirmLabel: 'Redirect',
    );
    if (directive == null || directive.isEmpty) {
      return;
    }
    final approval = await _promptForSensitiveApproval(
      title: 'Redirect Run Step-Up',
      confirmLabel: 'Confirm redirect',
    );
    if (approval == null) {
      return;
    }
    await _handleRunAction(
      (service) => service.redirectRun(
        runId: run.id,
        actorAlias: 'admin_operator',
        directive: directive,
        stepUpProof: approval.stepUpProof,
      ),
    );
  }

  Future<void> _requestOpenWeb(ResearchRunState run) async {
    final rationale = await _promptForText(
      title: 'Request Brokered Open-Web Access',
      hintText:
          'Explain why internal evidence is insufficient for this sandbox run.',
      confirmLabel: 'Request',
    );
    if (rationale == null || rationale.isEmpty) {
      return;
    }
    final approval = await _promptForSensitiveApproval(
      title: 'Open-Web Approval Request Step-Up',
      confirmLabel: 'Confirm request',
    );
    if (approval == null) {
      return;
    }
    await _handleRunAction(
      (service) => service.requestOpenWebAccess(
        runId: run.id,
        actorAlias: 'admin_operator',
        ttl: const Duration(hours: 4),
        rationale: rationale,
        stepUpProof: approval.stepUpProof,
      ),
    );
  }

  Future<void> _triggerKillSwitch(ResearchRunState run) async {
    final rationale = await _promptForText(
      title: 'Trigger Kill Switch',
      hintText: 'Document the break-glass reason.',
      confirmLabel: 'Trigger',
    );
    if (rationale == null || rationale.isEmpty) {
      return;
    }
    final approval = await _promptForSensitiveApproval(
      title: 'Kill Switch Dual Approval',
      confirmLabel: 'Trigger',
      requireSecondOperator: true,
    );
    if (approval == null || approval.secondOperatorApproval == null) {
      return;
    }
    await _handleRunAction(
      (service) => service.triggerKillSwitch(
        runId: run.id,
        actorAlias: 'admin_operator',
        rationale: rationale,
        stepUpProof: approval.stepUpProof,
        secondOperatorApproval: approval.secondOperatorApproval,
      ),
    );
  }

  Future<void> _approveRun(ResearchRunState run) async {
    final rationale = await _promptForText(
      title: 'Approve Review Candidate',
      hintText: 'Document why this sandbox candidate is approved.',
      confirmLabel: 'Approve',
    );
    if (rationale == null || rationale.isEmpty) {
      return;
    }
    final approval = await _promptForSensitiveApproval(
      title: 'Promotion Review Dual Approval',
      confirmLabel: 'Approve candidate',
      requireSecondOperator: true,
    );
    if (approval == null || approval.secondOperatorApproval == null) {
      return;
    }
    await _handleRunAction(
      (service) => service.reviewCandidate(
        runId: run.id,
        actorAlias: 'admin_operator',
        approved: true,
        rationale: rationale,
        stepUpProof: approval.stepUpProof,
        secondOperatorApproval: approval.secondOperatorApproval,
      ),
    );
  }

  Future<void> _rejectReview(ResearchRunState run) async {
    final rationale = await _promptForText(
      title: 'Reject Review Candidate',
      hintText: 'Document why this sandbox candidate is rejected.',
      confirmLabel: 'Reject',
    );
    if (rationale == null || rationale.isEmpty) {
      return;
    }
    final approval = await _promptForSensitiveApproval(
      title: 'Review Rejection Step-Up',
      confirmLabel: 'Reject candidate',
    );
    if (approval == null) {
      return;
    }
    await _handleRunAction(
      (service) => service.reviewCandidate(
        runId: run.id,
        actorAlias: 'admin_operator',
        approved: false,
        rationale: rationale,
        stepUpProof: approval.stepUpProof,
      ),
    );
  }

  Future<void> _approveOpenWeb(ResearchRunState run) async {
    final rationale = await _promptForText(
      title: 'Approve Brokered Open-Web Access',
      hintText: 'Record why brokered open-web access is justified.',
      confirmLabel: 'Approve',
    );
    if (rationale == null || rationale.isEmpty) {
      return;
    }
    final approval = await _promptForSensitiveApproval(
      title: 'Open-Web Dual Approval',
      confirmLabel: 'Approve open web',
      requireSecondOperator: true,
    );
    if (approval == null || approval.secondOperatorApproval == null) {
      return;
    }
    final secondOperatorApproval = approval.secondOperatorApproval!;
    await _handleRunAction(
      (service) => service.approveOpenWeb(
        runId: run.id,
        actorAlias: 'admin_operator',
        ttl: const Duration(hours: 4),
        rationale: rationale,
        stepUpProof: approval.stepUpProof,
        secondOperatorApproval: secondOperatorApproval,
      ),
    );
  }

  Future<void> _rejectOpenWeb(ResearchRunState run) async {
    final rationale = await _promptForText(
      title: 'Reject Brokered Open-Web Access',
      hintText: 'Record why open-web access remains blocked.',
      confirmLabel: 'Reject',
    );
    if (rationale == null || rationale.isEmpty) {
      return;
    }
    final approval = await _promptForSensitiveApproval(
      title: 'Open-Web Rejection Step-Up',
      confirmLabel: 'Reject open web',
    );
    if (approval == null) {
      return;
    }
    await _handleRunAction(
      (service) => service.rejectOpenWeb(
        runId: run.id,
        actorAlias: 'admin_operator',
        rationale: rationale,
        stepUpProof: approval.stepUpProof,
      ),
    );
  }

  Future<String?> _promptForText({
    required String title,
    required String hintText,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return value;
  }

  Future<_SensitiveActionApproval?> _promptForSensitiveApproval({
    required String title,
    required String confirmLabel,
    bool requireSecondOperator = false,
  }) async {
    final stepUpController = TextEditingController();
    final secondAliasController = TextEditingController();
    final secondProofController = TextEditingController();
    final approval = await showDialog<_SensitiveActionApproval>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: stepUpController,
                  decoration: const InputDecoration(
                    labelText: 'Step-up proof',
                    hintText: 'Enter step-up MFA proof or challenge token.',
                  ),
                ),
                if (requireSecondOperator) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: secondAliasController,
                    decoration: const InputDecoration(
                      labelText: 'Second operator alias',
                      hintText: 'Distinct admin_operator alias',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: secondProofController,
                    decoration: const InputDecoration(
                      labelText: 'Second operator proof',
                      hintText: 'Second operator approval proof',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final stepUpValue = stepUpController.text.trim();
                if (stepUpValue.isEmpty) {
                  return;
                }
                final secondApproval = requireSecondOperator
                    ? AdminControlPlaneSecondOperatorApproval(
                        actorAlias: secondAliasController.text.trim(),
                        proof: secondProofController.text.trim(),
                        approvedAt: DateTime.now().toUtc(),
                      )
                    : null;
                Navigator.of(dialogContext).pop(
                  _SensitiveActionApproval(
                    stepUpProof: AdminControlPlaneStepUpProof(
                      proof: stepUpValue,
                      issuedAt: DateTime.now().toUtc(),
                    ),
                    secondOperatorApproval: secondApproval,
                  ),
                );
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    stepUpController.dispose();
    secondAliasController.dispose();
    secondProofController.dispose();
    if (approval == null) {
      return null;
    }
    if (requireSecondOperator &&
        (approval.secondOperatorApproval == null ||
            approval.secondOperatorApproval!.actorAlias.trim().isEmpty ||
            approval.secondOperatorApproval!.proof.trim().isEmpty ||
            approval.secondOperatorApproval!.actorAlias == 'admin_operator')) {
      _showSnack('A second distinct admin_operator approval is required.');
      return null;
    }
    return approval;
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        return 'Cross-layer';
    }
  }

  String _stateLabel(ResearchRunLifecycleState state) {
    switch (state) {
      case ResearchRunLifecycleState.draft:
        return 'Draft';
      case ResearchRunLifecycleState.approved:
        return 'Approved';
      case ResearchRunLifecycleState.queued:
        return 'Queued';
      case ResearchRunLifecycleState.running:
        return 'Running';
      case ResearchRunLifecycleState.pausing:
        return 'Pausing';
      case ResearchRunLifecycleState.paused:
        return 'Paused';
      case ResearchRunLifecycleState.review:
        return 'Review';
      case ResearchRunLifecycleState.stopped:
        return 'Stopped';
      case ResearchRunLifecycleState.completed:
        return 'Completed';
      case ResearchRunLifecycleState.failed:
        return 'Failed';
      case ResearchRunLifecycleState.redirectPending:
        return 'Redirect pending';
      case ResearchRunLifecycleState.archived:
        return 'Archived';
    }
  }

  String _egressLabel(ResearchRunState run, bool openWebPending) {
    if (openWebPending) {
      return 'pending approval';
    }
    switch (run.egressMode) {
      case ResearchEgressMode.internalOnly:
        return 'internal only';
      case ResearchEgressMode.brokeredOpenWeb:
        return run.hasApprovedOpenWebAccess
            ? 'brokered approved'
            : 'brokered blocked';
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
