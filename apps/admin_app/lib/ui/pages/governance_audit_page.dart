import 'dart:async';

import 'package:avrai_admin_app/ui/widgets/governance_audit_feed_card.dart';
import 'package:avrai_core/models/misc/break_glass_governance_directive.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

enum GovernanceAuditArtifactType {
  inspection,
  breakGlass,
}

class GovernanceAuditPage extends StatefulWidget {
  const GovernanceAuditPage({
    super.key,
    this.initialRuntimeId,
    this.initialStratum,
    this.initialArtifactType,
  });

  final String? initialRuntimeId;
  final String? initialStratum;
  final String? initialArtifactType;

  @override
  State<GovernanceAuditPage> createState() => _GovernanceAuditPageState();
}

class _GovernanceAuditPageState extends State<GovernanceAuditPage> {
  AdminRuntimeGovernanceService? _service;
  Timer? _refreshTimer;

  bool _isLoading = true;
  String? _error;
  DateTime? _lastRefreshAt;
  GovernanceStratum? _selectedStratum;
  GovernanceAuditArtifactType _selectedArtifactType =
      GovernanceAuditArtifactType.inspection;
  String? _selectedRuntimeId;
  String? _selectedAuditRef;
  GovernedRuntimeContext? _runtimeContext;
  List<GovernanceInspectionResponse> _inspections =
      <GovernanceInspectionResponse>[];
  List<BreakGlassGovernanceReceipt> _receipts = <BreakGlassGovernanceReceipt>[];

  @override
  void initState() {
    super.initState();
    _selectedRuntimeId = widget.initialRuntimeId?.trim();
    _selectedStratum = _parseStratum(widget.initialStratum);
    _selectedArtifactType = _parseArtifactType(widget.initialArtifactType);
    _init();
  }

  Future<void> _init() async {
    try {
      _service = GetIt.instance<AdminRuntimeGovernanceService>();
      await _load();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _load(),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            'Governance audit services are unavailable in this environment.';
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
        service.listRecentGovernanceInspections(
          limit: 25,
          stratum: _selectedStratum,
          runtimeId: _selectedRuntimeId,
        ),
        service.listRecentBreakGlassReceipts(
          limit: 25,
          stratum: _selectedStratum,
          runtimeId: _selectedRuntimeId,
        ),
        if (_selectedRuntimeId != null && _selectedRuntimeId!.isNotEmpty)
          service.getGovernedRuntimeContext(
            runtimeId: _selectedRuntimeId!,
            stratum: _selectedStratum,
          )
        else
          Future<GovernedRuntimeContext?>.value(null),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _inspections = results[0] as List<GovernanceInspectionResponse>;
        _receipts = results[1] as List<BreakGlassGovernanceReceipt>;
        _runtimeContext = results[2] as GovernedRuntimeContext?;
        _selectedAuditRef = _resolveSelectedAuditRef(
          inspections: _inspections,
          receipts: _receipts,
          current: _selectedAuditRef,
          preferredType: _selectedArtifactType,
        );
        _lastRefreshAt = DateTime.now();
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load governance audit data: $error';
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
      title: 'Governance Audit',
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
                    'Human Oversight Lane',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inspectable audit surface for personal, locality, world, and universal agents across the OS governance kernels: who, what, when, where, why, and how. This view is for governed observation and incident review, not silent model mutation.',
                  ),
                  if (_lastRefreshAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last refresh: ${_formatTimestamp(_lastRefreshAt!)}',
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
            color: AppColors.warning.withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.rule_folder_outlined, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Early-launch visibility stays explicit and audited. Inspection and break-glass history remain separate from ordinary learning paths, and kernel-level observation must stay structured as who/what/when/where/why/how rather than hidden operator access.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Governance stratum',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedStratum == null,
                onSelected: (_) => _setStratum(null),
              ),
              ...GovernanceStratum.values.map(
                (stratum) => ChoiceChip(
                  label: Text(_labelForStratum(stratum)),
                  selected: _selectedStratum == stratum,
                  onSelected: (_) => _setStratum(stratum),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Artifact type',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Inspections'),
                selected: _selectedArtifactType ==
                    GovernanceAuditArtifactType.inspection,
                onSelected: (_) => _setArtifactType(
                  GovernanceAuditArtifactType.inspection,
                ),
              ),
              ChoiceChip(
                label: const Text('Break-glass'),
                selected: _selectedArtifactType ==
                    GovernanceAuditArtifactType.breakGlass,
                onSelected: (_) => _setArtifactType(
                  GovernanceAuditArtifactType.breakGlass,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedRuntimeId != null && _selectedRuntimeId!.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.filter_alt_outlined),
                title: Text('Filtered runtime: $_selectedRuntimeId'),
                subtitle: const Text(
                  'Drill-down active. Clear to return to the full audit feed.',
                ),
                trailing: TextButton(
                  onPressed: _clearRuntimeFilter,
                  child: const Text('Clear'),
                ),
              ),
            ),
          if (_selectedRuntimeId != null && _selectedRuntimeId!.isNotEmpty)
            const SizedBox(height: 12),
          GovernanceAuditFeedCard(
            inspections: _inspections,
            receipts: _receipts,
            title: 'Persisted Governance Artifacts',
            subtitle:
                'Tap a row to inspect the governed runtime, timing, visibility tier, and policy outcome in detail.',
            onInspectionTap: _selectInspection,
            onBreakGlassTap: _selectBreakGlass,
          ),
          const SizedBox(height: 12),
          _buildSelectedArtifactDetail(context),
        ],
      ),
    );
  }

  Widget _buildSelectedArtifactDetail(BuildContext context) {
    final inspection = _selectedInspection;
    final receipt = _selectedReceipt;
    if (inspection == null && receipt == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select an audit artifact to inspect its runtime, stratum, timing, justification, and policy outcome.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      );
    }

    final isInspection = inspection != null;
    final title = isInspection ? 'Inspection Detail' : 'Break-Glass Detail';
    final runtimeId = isInspection
        ? inspection.request.targetRuntimeId
        : receipt!.directive.targetRuntimeId;
    final stratum = isInspection
        ? inspection.request.targetStratum.name
        : receipt!.directive.targetStratum.name;
    final primaryTime = isInspection
        ? inspection.respondedAt.serverTime
        : receipt!.evaluatedAt.serverTime;

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
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$runtimeId • $stratum • ${_formatTimestamp(primaryTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _focusRuntime(runtimeId),
                  icon: const Icon(Icons.filter_center_focus_outlined),
                  label: const Text('Focus runtime'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailRow(
              context,
              'Audit ref',
              isInspection ? inspection.auditRef : receipt!.auditRef,
            ),
            _detailRow(
              context,
              'Approval',
              isInspection
                  ? (inspection.approved ? 'approved' : 'blocked')
                  : (receipt!.approved ? 'approved' : 'blocked'),
            ),
            if (isInspection) ...[
              _detailRow(
                context,
                'Actor',
                inspection.request.actorId,
              ),
              _detailRow(
                context,
                'Visibility',
                inspection.request.visibilityTier.name,
              ),
              _detailRow(
                context,
                'Justification',
                inspection.request.justification,
              ),
              if (inspection.failureCodes.isNotEmpty)
                _detailRow(
                  context,
                  'Failure codes',
                  inspection.failureCodes.join(', '),
                ),
              if (inspection.payload != null) ...[
                _detailMap(context, 'Who kernel',
                    inspection.payload!.whoKernel.toJson()),
                _detailMap(context, 'What kernel',
                    inspection.payload!.whatKernel.toJson()),
                _detailMap(context, 'When kernel',
                    inspection.payload!.whenKernel.toJson()),
                _detailMap(context, 'Where kernel',
                    inspection.payload!.whereKernel.toJson()),
                _detailMap(context, 'Why kernel',
                    inspection.payload!.whyKernel.toJson()),
                _detailMap(context, 'How kernel',
                    inspection.payload!.howKernel.toJson()),
                _detailMap(
                  context,
                  'Policy state',
                  inspection.payload!.policyState.toJson(),
                ),
                _detailList(
                  context,
                  'Provenance refs',
                  inspection.payload!.provenance
                      .map(
                        (entry) => entry.subject == null
                            ? '${entry.kind}: ${entry.reference}'
                            : '${entry.kind}: ${entry.reference} '
                                '(${entry.subject})',
                      )
                      .toList(growable: false),
                ),
              ],
            ] else ...[
              _detailRow(
                context,
                'Actor',
                receipt!.directive.actorId,
              ),
              _detailRow(
                context,
                'Action type',
                receipt.directive.actionType.name,
              ),
              _detailRow(
                context,
                'Reason code',
                receipt.directive.reasonCode,
              ),
              _detailRow(
                context,
                'Signed directive ref',
                receipt.directive.signedDirectiveRef,
              ),
              _detailRow(
                context,
                'Dual approval',
                receipt.directive.requiresDualApproval
                    ? 'required'
                    : 'not required',
              ),
              _detailRow(
                context,
                'Expires at',
                _formatTimestamp(receipt.directive.expiresAt.serverTime),
              ),
              if (receipt.failureCodes.isNotEmpty)
                _detailRow(
                  context,
                  'Failure codes',
                  receipt.failureCodes.join(', '),
                ),
            ],
            const SizedBox(height: 8),
            _buildLinkedRuntimeContext(context, runtimeId),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedRuntimeContext(BuildContext context, String runtimeId) {
    final contextData = _runtimeContext;
    final dashboard = contextData?.dashboard;
    final relatedAgents =
        contextData?.matchedAgents ?? const <GovernedRuntimeAgentMatch>[];
    final relatedInspectionCount = contextData?.inspections.length ??
        _inspections
            .where((item) => item.request.targetRuntimeId == runtimeId)
            .length;
    final relatedBreakGlassCount = contextData?.breakGlassReceipts.length ??
        _receipts
            .where((item) => item.directive.targetRuntimeId == runtimeId)
            .length;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grey100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Linked Runtime Context',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _contextPill(
                'Runtime artifacts',
                '${relatedInspectionCount + relatedBreakGlassCount}',
              ),
              _contextPill('Inspection records', '$relatedInspectionCount'),
              _contextPill('Break-glass records', '$relatedBreakGlassCount'),
              _contextPill(
                'Matched live agents',
                '${relatedAgents.length}',
                accent: AppColors.electricGreen,
              ),
              if (dashboard != null)
                _contextPill(
                  'System health',
                  '${(dashboard.systemHealth * 100).round()}%',
                ),
              if (dashboard != null)
                _contextPill(
                  'Active connections',
                  '${dashboard.activeConnections}',
                ),
              if (dashboard != null)
                _contextPill(
                  'Total communications',
                  '${dashboard.totalCommunications}',
                ),
              if (contextData?.hasPersistedBinding ?? false)
                _contextPill(
                  'Binding origin',
                  _bindingOriginLabel(contextData!.bindingSource),
                  accent: AppColors.warning,
                ),
              if (contextData?.bindingRegisteredAt != null)
                _contextPill(
                  'Registered',
                  _formatTimestamp(contextData!.bindingRegisteredAt!),
                ),
              if (contextData != null)
                _contextPill(
                  'Resolution',
                  _resolutionModeLabel(contextData.resolutionMode),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (contextData?.hasPersistedBinding ?? false) ...[
            _detailRow(
              context,
              'Binding origin',
              _bindingOriginLabel(contextData!.bindingSource),
            ),
            _detailRow(
              context,
              'Binding source key',
              contextData.bindingSource ?? 'unknown',
            ),
            if (contextData.bindingRegisteredAt != null)
              _detailRow(
                context,
                'Binding registered',
                _formatTimestamp(contextData.bindingRegisteredAt!),
              ),
            _detailRow(
              context,
              'Resolution mode',
              _resolutionModeLabel(contextData.resolutionMode),
            ),
            const SizedBox(height: 8),
          ],
          if (relatedAgents.isEmpty)
            Text(
              contextData?.resolutionMode ==
                      GovernedRuntimeResolutionMode.auditOnly
                  ? 'No live agent matched this runtime identifier in the current admin surface. Oversight remains audit-grounded here, with system-level context shown above.'
                  : 'No live agent matched this runtime identifier in the current admin surface. Oversight remains audit-grounded here, with system-level context shown above.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          else if (contextData?.resolutionMode ==
              GovernedRuntimeResolutionMode.registryExact) ...[
            Text(
              'Runtime resolved through persisted governed-runtime binding.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.electricGreen,
                  ),
            ),
            const SizedBox(height: 8),
            ...relatedAgents.map(
              (agent) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    agent.isOnline ? Icons.circle : Icons.circle_outlined,
                    color: agent.isOnline
                        ? AppColors.electricGreen
                        : AppColors.textSecondary,
                  ),
                  title: Text(agent.aiSignature),
                  subtitle: Text(
                    '${agent.aiStatus} • stage ${agent.currentStage} • last active ${_formatTimestamp(agent.lastActive)}',
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      'connections ${agent.aiConnections}\n'
                      'top action ${agent.topPredictedAction ?? 'none'}',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ] else
            ...relatedAgents.map(
              (agent) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    agent.isOnline ? Icons.circle : Icons.circle_outlined,
                    color: agent.isOnline
                        ? AppColors.electricGreen
                        : AppColors.textSecondary,
                  ),
                  title: Text(agent.aiSignature),
                  subtitle: Text(
                    '${agent.aiStatus} • stage ${agent.currentStage} • last active ${_formatTimestamp(agent.lastActive)}',
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      'connections ${agent.aiConnections}\n'
                      'top action ${agent.topPredictedAction ?? 'none'}',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _detailMap(
    BuildContext context,
    String label,
    Map<String, dynamic> value,
  ) {
    final text = value.isEmpty
        ? 'none'
        : value.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');
    return _detailRow(context, label, text);
  }

  Widget _detailList(BuildContext context, String label, List<String> value) {
    final text = value.isEmpty ? 'none' : value.join('\n');
    return _detailRow(context, label, text);
  }

  Widget _contextPill(String label, String value, {Color? accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (accent ?? AppColors.grey200).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }

  void _setStratum(GovernanceStratum? value) {
    if (_selectedStratum == value) {
      return;
    }
    setState(() {
      _selectedStratum = value;
      _isLoading = true;
    });
    unawaited(_load());
  }

  void _setArtifactType(GovernanceAuditArtifactType value) {
    if (_selectedArtifactType == value) {
      return;
    }
    setState(() {
      _selectedArtifactType = value;
      _selectedAuditRef = _resolveSelectedAuditRef(
        inspections: _inspections,
        receipts: _receipts,
        current: null,
        preferredType: value,
      );
    });
  }

  void _selectInspection(GovernanceInspectionResponse value) {
    setState(() {
      _selectedArtifactType = GovernanceAuditArtifactType.inspection;
      _selectedAuditRef = value.auditRef;
    });
  }

  void _selectBreakGlass(BreakGlassGovernanceReceipt value) {
    setState(() {
      _selectedArtifactType = GovernanceAuditArtifactType.breakGlass;
      _selectedAuditRef = value.auditRef;
    });
  }

  void _focusRuntime(String runtimeId) {
    setState(() {
      _selectedRuntimeId = runtimeId;
      _isLoading = true;
    });
    unawaited(_load());
  }

  void _clearRuntimeFilter() {
    if (_selectedRuntimeId == null) {
      return;
    }
    setState(() {
      _selectedRuntimeId = null;
      _isLoading = true;
    });
    unawaited(_load());
  }

  GovernanceInspectionResponse? get _selectedInspection {
    if (_selectedArtifactType != GovernanceAuditArtifactType.inspection) {
      return null;
    }
    final selected =
        _inspections.where((item) => item.auditRef == _selectedAuditRef);
    if (selected.isNotEmpty) {
      return selected.first;
    }
    return _inspections.isEmpty ? null : _inspections.first;
  }

  BreakGlassGovernanceReceipt? get _selectedReceipt {
    if (_selectedArtifactType != GovernanceAuditArtifactType.breakGlass) {
      return null;
    }
    final selected =
        _receipts.where((item) => item.auditRef == _selectedAuditRef);
    if (selected.isNotEmpty) {
      return selected.first;
    }
    return _receipts.isEmpty ? null : _receipts.first;
  }

  String? _resolveSelectedAuditRef({
    required List<GovernanceInspectionResponse> inspections,
    required List<BreakGlassGovernanceReceipt> receipts,
    required String? current,
    required GovernanceAuditArtifactType preferredType,
  }) {
    final inspectionMatch = inspections.any((item) => item.auditRef == current);
    if (preferredType == GovernanceAuditArtifactType.inspection &&
        inspectionMatch) {
      return current;
    }
    final receiptMatch = receipts.any((item) => item.auditRef == current);
    if (preferredType == GovernanceAuditArtifactType.breakGlass &&
        receiptMatch) {
      return current;
    }
    if (preferredType == GovernanceAuditArtifactType.inspection &&
        inspections.isNotEmpty) {
      return inspections.first.auditRef;
    }
    if (preferredType == GovernanceAuditArtifactType.breakGlass &&
        receipts.isNotEmpty) {
      return receipts.first.auditRef;
    }
    if (inspections.isNotEmpty) {
      _selectedArtifactType = GovernanceAuditArtifactType.inspection;
      return inspections.first.auditRef;
    }
    if (receipts.isNotEmpty) {
      _selectedArtifactType = GovernanceAuditArtifactType.breakGlass;
      return receipts.first.auditRef;
    }
    return null;
  }

  GovernanceStratum? _parseStratum(String? raw) {
    final normalized = raw?.trim();
    for (final value in GovernanceStratum.values) {
      if (value.name == normalized) {
        return value;
      }
    }
    return null;
  }

  GovernanceAuditArtifactType _parseArtifactType(String? raw) {
    switch (raw?.trim()) {
      case 'breakGlass':
        return GovernanceAuditArtifactType.breakGlass;
      case 'inspection':
      default:
        return GovernanceAuditArtifactType.inspection;
    }
  }

  String _labelForStratum(GovernanceStratum value) {
    switch (value) {
      case GovernanceStratum.personal:
        return 'Personal';
      case GovernanceStratum.locality:
        return 'Locality';
      case GovernanceStratum.world:
        return 'World';
      case GovernanceStratum.universal:
        return 'Universal';
    }
  }

  String _bindingOriginLabel(String? source) {
    switch (source) {
      case 'agent_initialization_bootstrap':
        return 'Personal bootstrap';
      case 'agent_initialization_locality_seed':
        return 'Locality seed during onboarding';
      case 'locality_homebase_seed':
        return 'Locality homebase activation';
      case 'reality_model_checkin_runtime':
        return 'World/universal oversight runtime';
      case null:
      case '':
        return 'Unknown';
      default:
        return source.replaceAll('_', ' ');
    }
  }

  String _resolutionModeLabel(GovernedRuntimeResolutionMode mode) {
    switch (mode) {
      case GovernedRuntimeResolutionMode.auditOnly:
        return 'Audit only';
      case GovernedRuntimeResolutionMode.heuristicAgentMatch:
        return 'Heuristic live match';
      case GovernedRuntimeResolutionMode.registryExact:
        return 'Exact registry match';
    }
  }
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
