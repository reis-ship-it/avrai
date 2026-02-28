import 'package:avrai/core/models/community/collaborative_activity_metrics.dart';
import 'package:avrai/core/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/pages/admin/knot_visualizer_page.dart';
import 'package:avrai/presentation/pages/world_planes/world_planes_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
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

  AdminRuntimeGovernanceService? _service;

  bool _isLoading = true;
  String? _error;

  GodModeDashboardData? _dashboardData;
  AggregatePrivacyMetrics? _privacyMetrics;
  CollaborativeActivityMetrics? _collaborativeMetrics;
  List<ClubCommunityData> _clubCommunityData = <ClubCommunityData>[];
  List<UserSearchResult> _users = <UserSearchResult>[];
  List<BusinessAccountData> _businesses = <BusinessAccountData>[];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _service = GetIt.instance<AdminRuntimeGovernanceService>();
      await _load();
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
          final clubs = await _service!.getAllClubsAndCommunities();
          if (!mounted) return;
          setState(() {
            _clubCommunityData = clubs;
            _isLoading = false;
          });
          break;

        case OversightLayer.world:
          final results = await Future.wait<dynamic>([
            _service!.getDashboardData(),
            _service!.searchUsers(),
            _service!.getAllBusinessAccounts(),
          ]);
          if (!mounted) return;
          setState(() {
            _dashboardData = results[0] as GodModeDashboardData;
            _users = results[1] as List<UserSearchResult>;
            _businesses = results[2] as List<BusinessAccountData>;
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

  @override
  void dispose() {
    _checkInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: '${_layerLabel(widget.layer)} Oversight',
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
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
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
          _buildLayerSwitcher(),
          const SizedBox(height: 12),
          _buildDirectionsCard(context),
          const SizedBox(height: 12),
          _buildLayerSnapshot(context),
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
                  'Latest user IDs: ${_users.take(5).map((u) => _safePrefix(u.userId, 8)).join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
    }
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
              'Use this to query what this model is tracking, planning, and preparing next.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _checkInController,
                    decoration: const InputDecoration(
                      hintText: 'Ask: What are you planning next?',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _runCheckIn(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _runCheckIn,
                  child: const Text('Check In'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_checkIns.isEmpty)
              const Text('No check-ins yet. Start a model conversation above.')
            else
              ..._checkIns.reversed.take(4).map(
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

  void _runCheckIn() {
    final prompt = _checkInController.text.trim();
    if (prompt.isEmpty) return;

    final response = _composeResponse(prompt);

    setState(() {
      _checkIns.add(_CheckInEntry(
        prompt: prompt,
        response: response,
        createdAt: DateTime.now(),
      ));
      _checkInController.clear();
    });
  }

  String _composeResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();

    switch (widget.layer) {
      case OversightLayer.reality:
        final health = ((_dashboardData?.systemHealth ?? 0) * 100).round();
        final compliance =
            ((_privacyMetrics?.meanComplianceRate ?? 0) * 100).round();
        final planningSessions =
            _collaborativeMetrics?.totalPlanningSessions ?? 0;

        if (lowerPrompt.contains('plan') || lowerPrompt.contains('next')) {
          return 'Current focus: stabilize knowledge integrity at $health% and push compliance to >95%. Next prep cycle is centered on $planningSessions planning sessions and tighter conviction checks.';
        }

        return 'Reality oversight status: convictions/compliance at $compliance%, knowledge/system health at $health%. Thought-layer coordination is being monitored through collaborative planning and communications flow.';

      case OversightLayer.universe:
        final count = _clubCommunityData.length;
        final eventCount = _clubCommunityData.fold<int>(
            0, (sum, item) => sum + item.eventCount);

        if (lowerPrompt.contains('risk') || lowerPrompt.contains('issue')) {
          return 'Universe risk scan: watch low-event communities and high-member/low-activity clusters. Current surface includes $count entities and $eventCount events needing continuity checks.';
        }

        return 'Universe status: monitoring clubs, communities, and events for coherence. Current active scope covers $count entities with $eventCount event records, with priority on healthy participation velocity.';

      case OversightLayer.world:
        final users = _users.length;
        final businesses = _businesses.length;
        final activeUsers = _dashboardData?.activeUsers ?? 0;

        if (lowerPrompt.contains('service')) {
          return 'World service posture: $businesses business/service accounts tracked with cross-checks against user activity ($activeUsers active users). Next step is validating handoffs across user-business-service boundaries.';
        }

        return 'World status: users ($users total), businesses/services ($businesses total), and active runtime participation ($activeUsers) are under oversight. Planning is focused on continuity and operational quality across created entities.';
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
          'Record model check-ins so planning intent is auditable and explicit.',
        ];
      case OversightLayer.universe:
        return const [
          'Track club/community/event creation velocity and watch for inactive pockets.',
          'Validate member-to-event conversion and continuity of social momentum.',
          'Use check-ins to confirm why each universe model is prioritizing its next actions.',
        ];
      case OversightLayer.world:
        return const [
          'Monitor all created users, businesses, and service surfaces for integrity.',
          'Prioritize verified operations and active participant continuity.',
          'Run regular check-ins to ensure world models have clear prep and execution direction.',
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
