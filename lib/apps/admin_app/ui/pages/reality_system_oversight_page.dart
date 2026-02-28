import 'dart:async';

import 'package:avrai/core/models/community/collaborative_activity_metrics.dart';
import 'package:avrai/core/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai/core/services/admin/reality_grouping_audit_service.dart';
import 'package:avrai/core/services/admin/reality_model_checkin_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/apps/admin_app/ui/pages/knot_visualizer_page.dart';
import 'package:avrai/presentation/pages/world_planes/world_planes_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/apps/admin_app/ui/widgets/realtime_agent_globe_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

enum OversightLayer {
  reality,
  universe,
  world,
}

class RealitySystemOversightPage extends StatefulWidget {
  const RealitySystemOversightPage({super.key, required this.layer});

  final OversightLayer layer;

  @override
  State<RealitySystemOversightPage> createState() =>
      _RealitySystemOversightPageState();
}

class _RealitySystemOversightPageState
    extends State<RealitySystemOversightPage> {
  final TextEditingController _checkInController = TextEditingController();
  final List<_CheckInEntry> _checkIns = <_CheckInEntry>[];
  final RealityModelCheckInService _checkInService =
      RealityModelCheckInService();
  final RealityGroupingAuditService _groupingAuditService =
      RealityGroupingAuditService();

  AdminRuntimeGovernanceService? _service;
  SharedPreferencesCompat? _prefs;
  Timer? _liveRefreshTimer;

  bool _isLoading = true;
  bool _isCheckInBusy = false;
  bool _isGeneratingGroups = false;
  String? _error;

  GodModeDashboardData? _dashboardData;
  AggregatePrivacyMetrics? _privacyMetrics;
  CollaborativeActivityMetrics? _collaborativeMetrics;
  List<ClubCommunityData> _clubCommunityData = <ClubCommunityData>[];
  List<UserSearchResult> _users = <UserSearchResult>[];
  List<BusinessAccountData> _businesses = <BusinessAccountData>[];
  List<ActiveAIAgentData> _activeAgents = <ActiveAIAgentData>[];

  Set<String> _approvedGroupings = <String>{};
  List<String> _proposedGroupings = <String>[];
  List<RealityGroupingAuditEvent> _recentAuditEvents =
      <RealityGroupingAuditEvent>[];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _service = GetIt.instance<AdminRuntimeGovernanceService>();
      _prefs = await SharedPreferencesCompat.getInstance();
      await _loadApprovedGroupings();
      await _loadAuditEvents();
      await _load();
      await _generateGroupingProposals();
      _startLiveRefreshLoop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Admin oversight services are unavailable in this environment.';
        _isLoading = false;
      });
    }
  }

  Future<void> _load() async {
    if (_service == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      switch (widget.layer) {
        case OversightLayer.reality:
          final results = await Future.wait<dynamic>([
            _service!.getDashboardData(),
            _service!.getAggregatePrivacyMetrics(),
            _service!.getCollaborativeActivityMetrics(),
          ]);
          if (!mounted) return;
          setState(() {
            _dashboardData = results[0] as GodModeDashboardData;
            _privacyMetrics = results[1] as AggregatePrivacyMetrics;
            _collaborativeMetrics = results[2] as CollaborativeActivityMetrics;
            _isLoading = false;
          });
          break;

        case OversightLayer.universe:
          final results = await Future.wait<dynamic>([
            _service!.getAllClubsAndCommunities(),
            _service!.getAllActiveAIAgents(),
          ]);
          if (!mounted) return;
          setState(() {
            _clubCommunityData = results[0] as List<ClubCommunityData>;
            _activeAgents = results[1] as List<ActiveAIAgentData>;
            _isLoading = false;
          });
          break;

        case OversightLayer.world:
          final results = await Future.wait<dynamic>([
            _service!.getDashboardData(),
            _service!.searchUsers(),
            _service!.getAllBusinessAccounts(),
            _service!.getAllActiveAIAgents(),
          ]);
          if (!mounted) return;
          setState(() {
            _dashboardData = results[0] as GodModeDashboardData;
            _users = results[1] as List<UserSearchResult>;
            _businesses = results[2] as List<BusinessAccountData>;
            _activeAgents = results[3] as List<ActiveAIAgentData>;
            _isLoading = false;
          });
          break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load oversight data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadApprovedGroupings() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final saved =
        prefs.getStringList(_approvedGroupingKey(widget.layer)) ?? <String>[];

    if (!mounted) return;
    setState(() {
      _approvedGroupings = saved.toSet();
    });
  }

  Future<void> _persistApprovedGroupings() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setStringList(
      _approvedGroupingKey(widget.layer),
      _approvedGroupings.toList()..sort(),
    );
  }

  Future<void> _loadAuditEvents() async {
    final events = await _groupingAuditService.getRecentEvents(
      layer: _layerKey(widget.layer),
      limit: 10,
    );
    if (!mounted) return;
    setState(() {
      _recentAuditEvents = events;
    });
  }

  Future<void> _recordGroupingAudit({
    required String action,
    required String grouping,
  }) async {
    await _groupingAuditService.recordEvent(
      layer: _layerKey(widget.layer),
      action: action,
      grouping: grouping,
      actor: 'admin_operator',
      metadata: <String, dynamic>{
        'surface': 'reality_system_oversight',
      },
    );
    await _loadAuditEvents();
  }

  Future<void> _generateGroupingProposals() async {
    if (!mounted) return;

    final observed = _observedGroupingSignals();
    if (observed.isEmpty) {
      setState(() {
        _proposedGroupings = <String>[];
      });
      return;
    }

    setState(() {
      _isGeneratingGroups = true;
    });

    final proposed = await _checkInService.proposeGroupings(
      layer: _layerKey(widget.layer),
      observedTypes: observed,
      approvedGroupings: _approvedGroupings.toList(),
    );

    if (!mounted) return;
    setState(() {
      _proposedGroupings = proposed.where((group) {
        return !_approvedGroupings.contains(group);
      }).toList();
      _isGeneratingGroups = false;
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    _checkInController.dispose();
    super.dispose();
  }

  void _startLiveRefreshLoop() {
    _liveRefreshTimer?.cancel();
    if (widget.layer == OversightLayer.reality) {
      return;
    }

    _liveRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshLiveAgentsOnly(),
    );
  }

  Future<void> _refreshLiveAgentsOnly() async {
    if (!mounted || _service == null) {
      return;
    }

    try {
      final agents = await _service!.getAllActiveAIAgents();
      if (!mounted) return;
      setState(() {
        _activeAgents = agents;
      });
    } catch (_) {
      // Keep existing snapshot if a single live refresh cycle fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: '${_layerLabel(widget.layer)} Oversight',
      actions: [
        IconButton(
          onPressed: _isLoading
              ? null
              : () async {
                  await _load();
                  await _generateGroupingProposals();
                  await _loadAuditEvents();
                },
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _load();
                  await _generateGroupingProposals();
                  await _loadAuditEvents();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _load();
        await _generateGroupingProposals();
        await _loadAuditEvents();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLayerSwitcher(),
          const SizedBox(height: 12),
          _buildPrivacyNoticeCard(context),
          const SizedBox(height: 12),
          _buildDirectionsCard(context),
          const SizedBox(height: 12),
          _buildLayerSnapshot(context),
          if (widget.layer == OversightLayer.universe ||
              widget.layer == OversightLayer.world) ...[
            const SizedBox(height: 12),
            RealtimeAgentGlobeWidget(
              agents: _activeAgents,
              title: '${_layerLabel(widget.layer)} Agent Globe (Live)',
            ),
          ],
          const SizedBox(height: 12),
          _buildGroupingCard(context),
          const SizedBox(height: 12),
          _buildModelCheckInCard(context),
          const SizedBox(height: 12),
          _buildVisualizationCard(context),
        ],
      ),
    );
  }

  Widget _buildLayerSwitcher() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _layerChip(
              context: context,
              layer: OversightLayer.reality,
              route: '/admin/reality-system/reality',
              icon: Icons.psychology_alt,
            ),
            _layerChip(
              context: context,
              layer: OversightLayer.universe,
              route: '/admin/reality-system/universe',
              icon: Icons.groups,
            ),
            _layerChip(
              context: context,
              layer: OversightLayer.world,
              route: '/admin/reality-system/world',
              icon: Icons.public,
            ),
          ],
        ),
      ),
    );
  }

  Widget _layerChip({
    required BuildContext context,
    required OversightLayer layer,
    required String route,
    required IconData icon,
  }) {
    final selected = widget.layer == layer;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => context.go(route),
      label: Text(_layerLabel(layer)),
      avatar: Icon(icon, size: 18),
    );
  }

  Widget _buildPrivacyNoticeCard(BuildContext context) {
    return Card(
      color: AppColors.electricGreen.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.privacy_tip, color: AppColors.electricGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Privacy mode is enforced: only agent identity and aggregate telemetry are visible. '
                'No names, emails, phone numbers, or home addresses are shown in this oversight surface.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionsCard(BuildContext context) {
    final directives = _directivesForLayer(widget.layer);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oversight Directions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...directives.map(
              (directive) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.arrow_right, size: 18),
                    ),
                    Expanded(child: Text(directive)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerSnapshot(BuildContext context) {
    switch (widget.layer) {
      case OversightLayer.reality:
        final systemHealth = _dashboardData?.systemHealth ?? 0;
        final compliance = _privacyMetrics?.meanComplianceRate ?? 0;
        final collaboration = _collaborativeMetrics?.collaborationRate ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reality Model Snapshot',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _progressMetric(
                  label: 'Convictions coherence',
                  value: compliance,
                ),
                _progressMetric(
                  label: 'Knowledge integrity',
                  value: systemHealth,
                ),
                _progressMetric(
                  label: 'Thoughts collaboration alignment',
                  value: collaboration,
                ),
                const SizedBox(height: 8),
                Text(
                  'Planning sessions: ${_collaborativeMetrics?.totalPlanningSessions ?? 0} | Total communications: ${_dashboardData?.totalCommunications ?? 0}',
                ),
              ],
            ),
          ),
        );

      case OversightLayer.universe:
        final clubCount = _clubCommunityData.where((x) => x.isClub).length;
        final communityCount =
            _clubCommunityData.where((x) => !x.isClub).length;
        final totalEvents = _clubCommunityData.fold<int>(
          0,
          (sum, item) => sum + item.eventCount,
        );
        final totalMembers = _clubCommunityData.fold<int>(
          0,
          (sum, item) => sum + item.memberCount,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Universe Model Snapshot',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metricChip('Clubs', '$clubCount'),
                    _metricChip('Communities', '$communityCount'),
                    _metricChip('Events', '$totalEvents'),
                    _metricChip('Members', '$totalMembers'),
                  ],
                ),
                const SizedBox(height: 12),
                if (_clubCommunityData.isEmpty)
                  const Text('No clubs or communities available')
                else
                  ..._clubCommunityData.take(8).map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(item.isClub
                              ? Icons.diversity_3
                              : Icons.hub_outlined),
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.memberCount} members | ${item.eventCount} events | ${item.category}',
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );

      case OversightLayer.world:
        final activeUsers = _dashboardData?.activeUsers ?? 0;
        final totalUsers = _users.length;
        final totalBusinesses = _businesses.length;
        final verifiedBusinesses =
            _businesses.where((b) => b.isVerified).length;
        final totalConnectedExperts = _businesses.fold<int>(
          0,
          (sum, item) => sum + item.connectedExperts,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('World Model Snapshot',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metricChip('Users', '$totalUsers'),
                    _metricChip('Active users', '$activeUsers'),
                    _metricChip('Businesses', '$totalBusinesses'),
                    _metricChip('Verified', '$verifiedBusinesses'),
                    _metricChip('Connected experts', '$totalConnectedExperts'),
                    _metricChip(
                      'Service interactions',
                      '${_dashboardData?.totalCommunications ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Latest agent signatures: ${_users.take(5).map((u) => _safePrefix(u.aiSignature, 10)).join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildGroupingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logical Groupings (Human Oversight)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Reality model learns from approved groupings and proposes new taxonomy clusters for easier understanding.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_approvedGroupings.isEmpty)
              const Text('No approved groupings yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _approvedGroupings.map(
                  (grouping) {
                    return InputChip(
                      label: Text(grouping),
                      selected: true,
                      onDeleted: () async {
                        setState(() {
                          _approvedGroupings.remove(grouping);
                        });
                        await _persistApprovedGroupings();
                        await _recordGroupingAudit(
                          action: 'removed_approval',
                          grouping: grouping,
                        );
                      },
                    );
                  },
                ).toList(),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isGeneratingGroups
                      ? null
                      : () async {
                          await _generateGroupingProposals();
                        },
                  icon: _isGeneratingGroups
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Generate Proposals'),
                ),
                const SizedBox(width: 8),
                Text(
                  'Observed types: ${_observedGroupingSignals().length}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_proposedGroupings.isEmpty)
              const Text('No pending proposals.')
            else
              ..._proposedGroupings.map(
                (grouping) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(grouping)),
                      TextButton(
                        onPressed: () async {
                          setState(() {
                            _approvedGroupings.add(grouping);
                            _proposedGroupings.remove(grouping);
                          });
                          await _persistApprovedGroupings();
                          await _recordGroupingAudit(
                            action: 'approved',
                            grouping: grouping,
                          );
                        },
                        child: const Text('Approve'),
                      ),
                      TextButton(
                        onPressed: () async {
                          setState(() {
                            _proposedGroupings.remove(grouping);
                          });
                          await _recordGroupingAudit(
                            action: 'rejected',
                            grouping: grouping,
                          );
                        },
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Approve to Reality Memory Audit',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_recentAuditEvents.isEmpty)
              const Text('No oversight decisions logged yet.')
            else
              ..._recentAuditEvents.take(6).map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${_formatTime(event.timestamp.toLocal())} | ${event.action} | ${event.grouping} | ${event.actor}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCheckInCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_layerLabel(widget.layer)} Model Check-In',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Runtime-backed conversation with privacy-safe context (agent identity and aggregates only).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _checkInController,
                    decoration: const InputDecoration(
                      hintText:
                          'Ask: What are you planning and preparing next?',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _runCheckIn(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isCheckInBusy ? null : _runCheckIn,
                  child: _isCheckInBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Check In'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_checkIns.isEmpty)
              const Text('No check-ins yet. Start a model conversation above.')
            else
              ..._checkIns.reversed.take(6).map(
                    (entry) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(entry.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text('Admin: ${entry.prompt}'),
                          const SizedBox(height: 4),
                          Text('Model: ${entry.response}'),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Knot + Plane Visualizations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Open dedicated visuals to inspect knot behavior, distribution, and world-plane dynamics.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const KnotVisualizerPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.category),
                  label: const Text('Knot Visualizer'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WorldPlanesPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('World Planes'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/admin/ai2ai'),
                  icon: const Icon(Icons.hub_outlined),
                  label: const Text('AI2AI Dashboard'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/admin/urk-kernels'),
                  icon: const Icon(Icons.settings_suggest),
                  label: const Text('URK Kernel Console'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/admin/research-center'),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Research Center'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: AppColors.grey100,
    );
  }

  Widget _progressMetric({required String label, required double value}) {
    final safeValue = value.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ${(safeValue * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: safeValue),
        ],
      ),
    );
  }

  Future<void> _runCheckIn() async {
    final prompt = _checkInController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isCheckInBusy = true;
    });

    final context = _buildCheckInContext();
    final globalGroupings = await _allApprovedGroupings();

    final response = await _checkInService.checkIn(
      layer: _layerKey(widget.layer),
      prompt: prompt,
      context: context,
      approvedGroupings: globalGroupings,
    );

    if (!mounted) return;
    setState(() {
      _checkIns.add(_CheckInEntry(
        prompt: prompt,
        response: response,
        createdAt: DateTime.now(),
      ));
      _checkInController.clear();
      _isCheckInBusy = false;
    });
  }

  Map<String, dynamic> _buildCheckInContext() {
    switch (widget.layer) {
      case OversightLayer.reality:
        return <String, dynamic>{
          'systemHealth': _dashboardData?.systemHealth ?? 0,
          'privacyCompliance': _privacyMetrics?.meanComplianceRate ?? 0,
          'collaborationRate': _collaborativeMetrics?.collaborationRate ?? 0,
          'totalPlanningSessions':
              _collaborativeMetrics?.totalPlanningSessions ?? 0,
          'approvedGroupings': _approvedGroupings.toList()..sort(),
          'proposedGroupings': _proposedGroupings,
        };
      case OversightLayer.universe:
        return <String, dynamic>{
          'clubsCommunities': _clubCommunityData.length,
          'events': _clubCommunityData.fold<int>(
              0, (sum, item) => sum + item.eventCount),
          'members': _clubCommunityData.fold<int>(
              0, (sum, item) => sum + item.memberCount),
          'activeAgentCount': _activeAgents.length,
          'observedTypes': _observedGroupingSignals(),
          'approvedGroupings': _approvedGroupings.toList()..sort(),
        };
      case OversightLayer.world:
        return <String, dynamic>{
          'users': _users.length,
          'businesses': _businesses.length,
          'verifiedBusinesses': _businesses.where((b) => b.isVerified).length,
          'activeAgentCount': _activeAgents.length,
          'serviceInteractions': _dashboardData?.totalCommunications ?? 0,
          'observedTypes': _observedGroupingSignals(),
          'approvedGroupings': _approvedGroupings.toList()..sort(),
        };
    }
  }

  List<String> _observedGroupingSignals() {
    switch (widget.layer) {
      case OversightLayer.reality:
        return <String>[
          if (_privacyMetrics != null)
            'privacy-compliance:${(_privacyMetrics!.meanComplianceRate * 100).round()}%',
          if (_dashboardData != null)
            'system-health:${(_dashboardData!.systemHealth * 100).round()}%',
          if (_collaborativeMetrics != null)
            'planning-sessions:${_collaborativeMetrics!.totalPlanningSessions}',
        ];
      case OversightLayer.universe:
        return _clubCommunityData
            .map((item) {
              final activityBand = item.eventCount >= 20
                  ? 'high'
                  : item.eventCount >= 5
                      ? 'medium'
                      : 'low';
              return '${item.isClub ? 'club' : 'community'}:${item.category}:$activityBand';
            })
            .toSet()
            .toList()
          ..sort();
      case OversightLayer.world:
        final businessTypes = _businesses
            .map(
              (item) =>
                  '${item.account.businessType}:${item.isVerified ? 'verified' : 'unverified'}',
            )
            .toSet();
        final userStages = _activeAgents
            .map((agent) => 'agent-stage:${agent.currentStage}')
            .toSet();
        return <String>{...businessTypes, ...userStages}.toList()..sort();
    }
  }

  Future<List<String>> _allApprovedGroupings() async {
    final prefs = _prefs;
    if (prefs == null) {
      return _approvedGroupings.toList()..sort();
    }

    final all = <String>{};
    for (final layer in OversightLayer.values) {
      final key = _approvedGroupingKey(layer);
      final groups = prefs.getStringList(key) ?? const <String>[];
      all.addAll(groups);
    }
    if (all.isEmpty) {
      all.addAll(_approvedGroupings);
    }
    return all.toList()..sort();
  }

  String _approvedGroupingKey(OversightLayer layer) {
    return 'admin_reality_system_approved_groupings_${_layerKey(layer)}';
  }

  String _layerKey(OversightLayer layer) {
    switch (layer) {
      case OversightLayer.reality:
        return 'reality';
      case OversightLayer.universe:
        return 'universe';
      case OversightLayer.world:
        return 'world';
    }
  }

  String _layerLabel(OversightLayer layer) {
    switch (layer) {
      case OversightLayer.reality:
        return 'Reality';
      case OversightLayer.universe:
        return 'Universe';
      case OversightLayer.world:
        return 'World';
    }
  }

  List<String> _directivesForLayer(OversightLayer layer) {
    switch (layer) {
      case OversightLayer.reality:
        return const [
          'Keep convictions, knowledge, and thought streams aligned before deployment shifts.',
          'Escalate if compliance or health drops below acceptable thresholds.',
          'Ingest approved universe/world groupings and refine taxonomy proposals with human sign-off.',
        ];
      case OversightLayer.universe:
        return const [
          'Track club/community/event creation velocity and watch for inactive pockets.',
          'Validate member-to-event conversion and continuity of social momentum.',
          'Use 3D globe and model check-ins to understand where and how agent usage is concentrating.',
        ];
      case OversightLayer.world:
        return const [
          'Monitor all created users, businesses, and service surfaces for integrity.',
          'Prioritize verified operations and active participant continuity.',
          'Maintain agent-only identity visibility while auditing usage and service handoffs globally.',
        ];
    }
  }

  String _safePrefix(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength);
  }

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _CheckInEntry {
  const _CheckInEntry({
    required this.prompt,
    required this.response,
    required this.createdAt,
  });

  final String prompt;
  final String response;
  final DateTime createdAt;
}
