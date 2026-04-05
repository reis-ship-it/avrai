import 'dart:convert';

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class KernelGraphRunDetailPage extends StatefulWidget {
  const KernelGraphRunDetailPage({
    super.key,
    required this.runId,
    this.signatureHealthService,
  });

  final String runId;
  final SignatureHealthAdminService? signatureHealthService;

  @override
  State<KernelGraphRunDetailPage> createState() =>
      _KernelGraphRunDetailPageState();
}

class _KernelGraphRunDetailPageState extends State<KernelGraphRunDetailPage> {
  KernelGraphRunRecord? _run;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRun();
  }

  Future<void> _loadRun() async {
    final service = widget.signatureHealthService ??
        (GetIt.instance.isRegistered<SignatureHealthAdminService>()
            ? GetIt.instance<SignatureHealthAdminService>()
            : null);
    if (service == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _run = null;
        _isLoading = false;
        _error = 'KernelGraph run services are unavailable.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final run = await service.getKernelGraphRun(widget.runId);
      if (!mounted) {
        return;
      }
      setState(() {
        _run = run;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _run = null;
        _isLoading = false;
        _error = 'Failed to load KernelGraph run: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'KernelGraph Run',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _loadRun,
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
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadRun,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final run = _run;
    if (run == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.find_in_page_outlined, size: 40),
              const SizedBox(height: 12),
              Text(
                'No persisted KernelGraph run was found for `${widget.runId}`.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.go(AdminRoutePaths.signatureHealth),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Open Signature Health'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRun,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(context, run),
          const SizedBox(height: 12),
          if (run.spec != null || run.compiledPlan != null) ...[
            _buildExecutionPolicyCard(context, run),
            const SizedBox(height: 12),
            _buildExecutionShapeCard(context, run),
            const SizedBox(height: 12),
          ],
          _buildDigestCard(context, run),
          const SizedBox(height: 12),
          _buildNodeReceiptsCard(context, run),
          const SizedBox(height: 12),
          if (run.receipt.rollbackDescriptor != null) ...[
            _buildRollbackCard(context, run.receipt.rollbackDescriptor!),
            const SizedBox(height: 12),
          ],
          _buildMetadataCard(
            context,
            title: 'Run metadata',
            data: run.metadata,
          ),
          const SizedBox(height: 12),
          _buildMetadataCard(
            context,
            title: 'Execution metadata',
            data: run.receipt.metadata,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Back to Signature Health'),
              subtitle:
                  const Text('Return to the intake and KernelGraph overview.'),
              onTap: () => context.go(AdminRoutePaths.signatureHealth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, KernelGraphRunRecord run) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        run.graphTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        run.adminDigest.summary,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text(_statusLabel(run.status)),
                  backgroundColor:
                      _statusColor(run.status).withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(_kindLabel(run.kind))),
                Chip(
                  label: Text(
                    '${run.adminDigest.completedNodeCount}/${run.adminDigest.totalNodeCount} nodes',
                  ),
                ),
                if ((run.sourceKind ?? '').isNotEmpty)
                  Chip(
                    label: Text((run.sourceKind ?? '').replaceAll('_', ' ')),
                  ),
                if (run.adminDigest.requiresHumanReview)
                  Chip(
                    label: const Text('Human review required'),
                    backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Run ID', run.runId),
            _infoRow('Spec ID', run.specId),
            _infoRow('Source ID', run.sourceId ?? 'not recorded'),
            _infoRow('Review item ID', run.reviewItemId ?? 'not recorded'),
            _infoRow('Job ID', run.jobId ?? 'not recorded'),
            _infoRow('Owner user', run.ownerUserId ?? 'not recorded'),
            _infoRow('Started', run.startedAt.toIso8601String()),
            _infoRow(
              'Completed',
              run.completedAt?.toIso8601String() ?? 'still running',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionPolicyCard(
    BuildContext context,
    KernelGraphRunRecord run,
  ) {
    final policy =
        run.compiledPlan?.executionPolicy ?? run.spec?.executionPolicy;
    if (policy == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Execution policy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _infoRow('Environment', policy.environment.name),
            _infoRow(
              'Simulation first',
              policy.simulationFirst ? 'required' : 'not required',
            ),
            _infoRow(
              'Human review',
              policy.requiresHumanReview ? 'required' : 'not required',
            ),
            _infoRow(
              'Step budget',
              policy.maxStepCount?.toString() ?? 'unbounded',
            ),
            const SizedBox(height: 8),
            _buildStringChipWrap(
              title: 'Allowed mutable surfaces',
              values: policy.allowedMutableSurfaces,
            ),
            const SizedBox(height: 8),
            _buildMetadataSection(
              context,
              title: 'Policy metadata',
              data: policy.metadata,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionShapeCard(
      BuildContext context, KernelGraphRunRecord run) {
    final spec = run.spec;
    final compiledPlan = run.compiledPlan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Execution shape',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (spec != null) ...[
              Text(
                'Graph spec',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _infoRow('Graph ID', spec.id),
              _infoRow('Version', spec.version),
              _infoRow('Nodes', spec.nodes.length.toString()),
              _infoRow('Edges', spec.edges.length.toString()),
              const SizedBox(height: 8),
              _buildNodeSpecList(context, spec.nodes),
              const SizedBox(height: 8),
              _buildEdgeList(context, spec.edges),
              const SizedBox(height: 8),
              _buildMetadataSection(
                context,
                title: 'Spec metadata',
                data: spec.metadata,
                dense: true,
              ),
            ],
            if (spec != null && compiledPlan != null)
              const SizedBox(height: 12),
            if (compiledPlan != null) ...[
              Text(
                'Compiled plan',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _infoRow('Plan title', compiledPlan.title),
              _infoRow('Version', compiledPlan.version),
              _infoRow('Step count', compiledPlan.steps.length.toString()),
              const SizedBox(height: 8),
              _buildCompiledStepList(context, compiledPlan.steps),
              const SizedBox(height: 8),
              _buildMetadataSection(
                context,
                title: 'Plan metadata',
                data: compiledPlan.metadata,
                dense: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDigestCard(BuildContext context, KernelGraphRunRecord run) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin digest',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(run.adminDigest.summary),
            const SizedBox(height: 12),
            _buildStringChipWrap(
              title: 'Lineage refs',
              values: run.adminDigest.lineageRefs,
            ),
            const SizedBox(height: 12),
            _buildStringChipWrap(
              title: 'Rollback refs',
              values: run.adminDigest.rollbackRefs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeReceiptsCard(
      BuildContext context, KernelGraphRunRecord run) {
    final receipts = run.receipt.nodeReceipts;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Node receipts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (receipts.isEmpty)
              const Text('No node receipts were recorded.')
            else
              ...receipts.map(
                (receipt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(receipt.nodeId),
                    subtitle: Text(receipt.summary),
                    trailing: Chip(
                      label: Text(_nodeStatusLabel(receipt.status)),
                      backgroundColor: _nodeStatusColor(receipt.status)
                          .withValues(alpha: 0.12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('Primitive', receipt.primitiveId),
                            if (_findCompiledStep(run, receipt.nodeId)
                                case final compiledStep?)
                              _infoRow(
                                'Plan step',
                                '${compiledStep.order + 1}. ${compiledStep.label}',
                              ),
                            _infoRow(
                              'Started',
                              receipt.startedAt.toIso8601String(),
                            ),
                            _infoRow(
                              'Completed',
                              receipt.completedAt.toIso8601String(),
                            ),
                            _buildStringChipWrap(
                              title: 'Output refs',
                              values: receipt.outputRefs,
                            ),
                            const SizedBox(height: 8),
                            _buildNodeArtifactDrillDown(
                              context,
                              run: run,
                              receipt: receipt,
                            ),
                            const SizedBox(height: 8),
                            _buildMetadataInspectorSection(
                              context,
                              title: 'Node metadata',
                              data: receipt.metadata,
                              jsonTitle: 'Node metadata JSON',
                            ),
                          ],
                        ),
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

  Widget _buildNodeArtifactDrillDown(
    BuildContext context, {
    required KernelGraphRunRecord run,
    required KernelGraphNodeReceipt receipt,
  }) {
    final specNode = _findSpecNode(run, receipt.nodeId);
    final refs = receipt.outputRefs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artifact drill-down',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (refs.isEmpty)
          const Text('No artifact refs were recorded for this node.')
        else
          ...refs.map(
            (ref) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildArtifactCard(
                context,
                run: run,
                specNode: specNode,
                receipt: receipt,
                artifactRef: ref,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildArtifactCard(
    BuildContext context, {
    required KernelGraphRunRecord run,
    required KernelGraphNodeSpec? specNode,
    required KernelGraphNodeReceipt receipt,
    required String artifactRef,
  }) {
    final artifactLabel = _artifactLabelForRef(run, specNode, artifactRef);
    final artifactRole = _artifactRoleForRef(run, artifactRef);
    final linkTags = _artifactLinkTags(run, artifactRef);
    final payload = _artifactPayloadForRef(specNode, artifactRef);
    final signatureHealthLink =
        _signatureHealthLinkForArtifact(run, artifactRef);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artifactLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(artifactRef),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(artifactRole),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow('Recorded by node', receipt.nodeId),
            if (specNode != null) _infoRow('Graph node label', specNode.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _copyToClipboard(context, 'Artifact ref', artifactRef),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy ref'),
                ),
                if (payload != null)
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(
                      context,
                      'Artifact JSON',
                      const JsonEncoder.withIndent('  ').convert(payload),
                    ),
                    icon: const Icon(Icons.data_object, size: 16),
                    label: const Text('Copy JSON'),
                  ),
                if (signatureHealthLink != null)
                  TextButton.icon(
                    onPressed: () => context.go(signatureHealthLink),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open in Signature Health'),
                  ),
              ],
            ),
            if (linkTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildStringChipWrap(
                title: 'Links',
                values: linkTags,
              ),
            ],
            const SizedBox(height: 8),
            _buildMetadataInspectorSection(
              context,
              title: payload == null
                  ? 'Artifact payload hint'
                  : 'Artifact payload',
              jsonTitle: 'Artifact payload JSON',
              data: payload ??
                  <String, dynamic>{
                    'message':
                        'No persisted payload was found for this artifact ref in the matching node config.',
                  },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeSpecList(
    BuildContext context,
    List<KernelGraphNodeSpec> nodes,
  ) {
    if (nodes.isEmpty) {
      return const Text('No graph nodes were recorded.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes
          .map(
            (node) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(node.label),
                subtitle: Text(node.id),
                trailing: Chip(
                  label: Text(node.primitiveId),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Node ID', node.id),
                        _infoRow('Primitive', node.primitiveId),
                        _infoRow('Required', node.required ? 'yes' : 'no'),
                        _buildMetadataSection(
                          context,
                          title: 'Node config',
                          data: node.config,
                          dense: true,
                        ),
                        const SizedBox(height: 8),
                        _buildMetadataSection(
                          context,
                          title: 'Node metadata',
                          data: node.metadata,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildEdgeList(
    BuildContext context,
    List<KernelGraphEdgeSpec> edges,
  ) {
    if (edges.isEmpty) {
      return const Text('No graph edges were recorded.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edges',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        ...edges.map(
          (edge) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${edge.fromNodeId} -> ${edge.toNodeId}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if ((edge.label ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      edge.label!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                if (edge.metadata.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildMetadataSection(
                    context,
                    title: 'Edge metadata',
                    data: edge.metadata,
                    dense: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompiledStepList(
    BuildContext context,
    List<KernelGraphCompiledStep> steps,
  ) {
    if (steps.isEmpty) {
      return const Text('No compiled steps were recorded.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps
          .map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('${step.order + 1}. ${step.label}'),
                subtitle: Text(step.nodeId),
                trailing: Chip(
                  label: Text(step.primitiveId),
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Order', (step.order + 1).toString()),
                        _infoRow('Node ID', step.nodeId),
                        _infoRow('Primitive', step.primitiveId),
                        _buildMetadataSection(
                          context,
                          title: 'Step config',
                          data: step.config,
                          dense: true,
                        ),
                        const SizedBox(height: 8),
                        _buildMetadataSection(
                          context,
                          title: 'Step metadata',
                          data: step.metadata,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildRollbackCard(
    BuildContext context,
    KernelGraphRollbackDescriptor descriptor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rollback descriptor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _infoRow('Rollback ID', descriptor.id),
            _infoRow('Strategy', descriptor.strategy),
            const SizedBox(height: 8),
            _buildStringChipWrap(title: 'Refs', values: descriptor.refs),
            const SizedBox(height: 8),
            _buildMetadataCard(
              context,
              title: 'Rollback metadata',
              data: descriptor.metadata,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(
    BuildContext context, {
    required String title,
    required Map<String, dynamic> data,
    bool dense = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildMetadataRows(data, dense: dense),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(
    BuildContext context, {
    required String title,
    required Map<String, dynamic> data,
    bool dense = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildMetadataRows(data, dense: dense),
      ],
    );
  }

  Widget _buildMetadataInspectorSection(
    BuildContext context, {
    required String title,
    required String jsonTitle,
    required Map<String, dynamic> data,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (data.isEmpty)
          const Text('No metadata recorded.')
        else ...[
          Text(
            _metadataPreview(data),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildJsonExpansion(
            context,
            title: jsonTitle,
            data: data,
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataRows(
    Map<String, dynamic> data, {
    bool dense = false,
  }) {
    if (data.isEmpty) {
      return const Text('No metadata recorded.');
    }
    final entries = data.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return Column(
      children: entries
          .map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: dense ? 6 : 10),
              child: _infoRow(
                entry.key,
                _stringify(entry.value),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildJsonExpansion(
    BuildContext context, {
    required String title,
    required Map<String, dynamic> data,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text('${data.length} field${data.length == 1 ? '' : 's'}'),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(data),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  KernelGraphNodeSpec? _findSpecNode(
    KernelGraphRunRecord run,
    String nodeId,
  ) {
    for (final node in run.spec?.nodes ?? const <KernelGraphNodeSpec>[]) {
      if (node.id == nodeId) {
        return node;
      }
    }
    return null;
  }

  KernelGraphCompiledStep? _findCompiledStep(
    KernelGraphRunRecord run,
    String nodeId,
  ) {
    for (final step
        in run.compiledPlan?.steps ?? const <KernelGraphCompiledStep>[]) {
      if (step.nodeId == nodeId) {
        return step;
      }
    }
    return null;
  }

  String _artifactLabelForRef(
    KernelGraphRunRecord run,
    KernelGraphNodeSpec? specNode,
    String artifactRef,
  ) {
    final payload = _artifactPayloadForRef(specNode, artifactRef);
    final role = _artifactRoleForRef(run, artifactRef);
    final configKey = _artifactConfigKeyForRef(specNode, artifactRef);
    if ((payload?['title'] ?? '').toString().isNotEmpty) {
      return payload!['title'].toString();
    }
    if ((payload?['sourceLabel'] ?? '').toString().isNotEmpty) {
      return payload!['sourceLabel'].toString();
    }
    if ((payload?['summary'] ?? '').toString().isNotEmpty) {
      return payload!['summary'].toString();
    }
    if (configKey != null) {
      return '${_titleCase(configKey)} artifact';
    }
    return '${_titleCase(role)} artifact';
  }

  String _artifactRoleForRef(KernelGraphRunRecord run, String artifactRef) {
    if (artifactRef == run.sourceId) {
      return 'source';
    }
    if (artifactRef == run.jobId) {
      return 'job';
    }
    if (artifactRef == run.reviewItemId) {
      return 'review';
    }
    if (run.adminDigest.lineageRefs.contains(artifactRef)) {
      return 'lineage';
    }
    if (run.receipt.rollbackDescriptor?.refs.contains(artifactRef) ?? false) {
      return 'rollback';
    }
    return 'artifact';
  }

  String? _signatureHealthLinkForArtifact(
    KernelGraphRunRecord run,
    String artifactRef,
  ) {
    final role = _artifactRoleForRef(run, artifactRef);
    if (role != 'source' && role != 'job' && role != 'review') {
      return null;
    }
    return AdminRoutePaths.signatureHealthFocusLink(
      focus: artifactRef,
      attention: role,
    );
  }

  List<String> _artifactLinkTags(KernelGraphRunRecord run, String artifactRef) {
    final tags = <String>[];
    if (artifactRef == run.sourceId) {
      tags.add('matches run source');
    }
    if (artifactRef == run.jobId) {
      tags.add('matches run job');
    }
    if (artifactRef == run.reviewItemId) {
      tags.add('matches run review item');
    }
    if (run.adminDigest.lineageRefs.contains(artifactRef)) {
      tags.add('lineage ref');
    }
    if (run.adminDigest.rollbackRefs.contains(artifactRef)) {
      tags.add('admin rollback ref');
    }
    if (run.receipt.rollbackDescriptor?.refs.contains(artifactRef) ?? false) {
      tags.add('receipt rollback ref');
    }
    return tags;
  }

  String? _artifactConfigKeyForRef(
    KernelGraphNodeSpec? specNode,
    String artifactRef,
  ) {
    if (specNode == null) {
      return null;
    }
    for (final entry in specNode.config.entries) {
      if (entry.value is Map) {
        final map = Map<String, dynamic>.from(entry.value as Map);
        if (map['id']?.toString() == artifactRef) {
          return entry.key;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _artifactPayloadForRef(
    KernelGraphNodeSpec? specNode,
    String artifactRef,
  ) {
    if (specNode == null) {
      return null;
    }
    for (final entry in specNode.config.entries) {
      if (entry.value is Map) {
        final map = Map<String, dynamic>.from(entry.value as Map);
        if (map['id']?.toString() == artifactRef) {
          return map;
        }
      }
    }
    return null;
  }

  String _titleCase(String value) {
    final normalized = value.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) {
      return value;
    }
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String label,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  String _metadataPreview(
    Map<String, dynamic> data, {
    int maxEntries = 3,
  }) {
    final entries = data.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final previewEntries = entries.take(maxEntries).map((entry) {
      return '${entry.key}: ${_inlinePreview(entry.value)}';
    }).toList(growable: false);
    final remaining = entries.length - previewEntries.length;
    if (remaining > 0) {
      previewEntries.add('+$remaining more');
    }
    return previewEntries.join(' | ');
  }

  String _inlinePreview(Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalized.length <= 48) {
        return normalized;
      }
      return '${normalized.substring(0, 45)}...';
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    if (value is List) {
      return '${value.length} item${value.length == 1 ? '' : 's'}';
    }
    if (value is Map) {
      return '${value.length} field${value.length == 1 ? '' : 's'}';
    }
    return value.toString();
  }

  Widget _buildStringChipWrap({
    required String title,
    required List<String> values,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        if (values.isEmpty)
          const Text('None recorded.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) => Chip(label: Text(value))).toList(),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  String _statusLabel(KernelGraphRunStatus status) {
    return switch (status) {
      KernelGraphRunStatus.queued => 'queued',
      KernelGraphRunStatus.running => 'running',
      KernelGraphRunStatus.completed => 'completed',
      KernelGraphRunStatus.failed => 'failed',
    };
  }

  Color _statusColor(KernelGraphRunStatus status) {
    return switch (status) {
      KernelGraphRunStatus.completed => AppColors.success,
      KernelGraphRunStatus.running => AppColors.accent,
      KernelGraphRunStatus.queued => AppColors.warning,
      KernelGraphRunStatus.failed => AppColors.error,
    };
  }

  String _kindLabel(KernelGraphKind kind) {
    return switch (kind) {
      KernelGraphKind.learningIntake => 'learning intake',
      KernelGraphKind.governedRun => 'governed run',
      KernelGraphKind.securityCampaign => 'security campaign',
      KernelGraphKind.autoresearch => 'autoresearch',
      KernelGraphKind.adminProjection => 'admin projection',
    };
  }

  String _nodeStatusLabel(KernelGraphNodeStatus status) {
    return switch (status) {
      KernelGraphNodeStatus.pending => 'pending',
      KernelGraphNodeStatus.running => 'running',
      KernelGraphNodeStatus.completed => 'completed',
      KernelGraphNodeStatus.failed => 'failed',
    };
  }

  Color _nodeStatusColor(KernelGraphNodeStatus status) {
    return switch (status) {
      KernelGraphNodeStatus.pending => AppColors.warning,
      KernelGraphNodeStatus.running => AppColors.accent,
      KernelGraphNodeStatus.completed => AppColors.success,
      KernelGraphNodeStatus.failed => AppColors.error,
    };
  }

  String _stringify(Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    if (value is List || value is Map) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }
}
