// Knot Evolution Tab
//
// Admin tab for tracking knot evolution
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 9: Admin Knot Visualizer

import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/admin/knot_admin_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Tab for tracking knot evolution
class KnotEvolutionTab extends StatefulWidget {
  const KnotEvolutionTab({super.key});

  @override
  State<KnotEvolutionTab> createState() => _KnotEvolutionTabState();
}

class _KnotEvolutionTabState extends State<KnotEvolutionTab> {
  final _knotAdminService = GetIt.instance<KnotAdminService>();
  Map<String, dynamic>? _evolutionData;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedAgentId;
  DateTime? _selectedTimeRange;

  @override
  void initState() {
    super.initState();
    _loadEvolutionData();
  }

  Future<void> _loadEvolutionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _knotAdminService.getEvolutionTracking(
        agentId: _selectedAgentId,
        timeRange: _selectedTimeRange,
      );

      setState(() {
        _evolutionData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(kSpaceMd),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Agent ID (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Enter agent ID to track specific user',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedAgentId = value.isEmpty ? null : value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _loadEvolutionData,
                child: Text('Load'),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadEvolutionData,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text('Error: $_errorMessage'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadEvolutionData,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _evolutionData == null
                        ? Center(child: Text('No evolution data available'))
                        : _buildEvolutionContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildEvolutionContent() {
    final data = _evolutionData!;

    // Check if this is agent-specific or aggregate data
    if (data.containsKey('snapshots')) {
      return _buildAgentEvolutionTimeline(data);
    } else {
      return _buildAggregateEvolution(data);
    }
  }

  Widget _buildAgentEvolutionTimeline(Map<String, dynamic> data) {
    final snapshots = data['snapshots'] as List<dynamic>;
    final agentId = data['agentId'] as String? ?? 'Unknown';

    if (snapshots.isEmpty) {
      return Center(
        child: Text('No evolution snapshots available for this agent'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(kSpaceMd),
      children: [
        // Header
        PortalSurface(
          child: Padding(
            padding: const EdgeInsets.all(kSpaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evolution Timeline',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                    'Agent ID: ${agentId.length > 20 ? "${agentId.substring(0, 20)}..." : agentId}'),
                Text('Total Snapshots: ${snapshots.length}'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Timeline
        ...snapshots.asMap().entries.map((entry) {
          final index = entry.key;
          final snapshot = entry.value as Map<String, dynamic>;
          final timestamp = DateTime.parse(snapshot['timestamp'] as String);
          final crossingNumber = snapshot['crossingNumber'] as int;
          final writhe = snapshot['writhe'] as int;
          final complexity = snapshot['complexity'] as num;

          return PortalSurface(
            margin: const EdgeInsets.only(bottom: kSpaceXs),
            child: Padding(
              padding: const EdgeInsets.all(kSpaceMd),
              child: Row(
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      const CircleAvatar(
                        radius: 6,
                        backgroundColor: AppColors.primary,
                      ),
                      if (index < snapshots.length - 1)
                        Container(
                          width: 2,
                          height: 40,
                          color: AppColors.grey300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Snapshot data
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTimestamp(timestamp),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMetricChip(
                                'Crossings', crossingNumber.toString()),
                            const SizedBox(width: 8),
                            _buildMetricChip('Writhe', writhe.toString()),
                            const SizedBox(width: 8),
                            _buildMetricChip(
                                'Complexity', complexity.toStringAsFixed(1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAggregateEvolution(Map<String, dynamic> data) {
    return ListView(
      padding: const EdgeInsets.all(kSpaceMd),
      children: [
        PortalSurface(
          child: Padding(
            padding: const EdgeInsets.all(kSpaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aggregate Evolution Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  'Total Users Tracked',
                  '${data['totalUsersTracked'] ?? 0}',
                  Icons.people,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Average Snapshots per User',
                  (data['averageSnapshotsPerUser'] as num? ?? 0.0)
                      .toStringAsFixed(1),
                  Icons.timeline,
                ),
                const SizedBox(height: 16),
                if ((data['evolutionTrends'] as List?)?.isEmpty ?? true)
                  Text('No evolution trends available')
                else
                  ...(data['evolutionTrends'] as List<dynamic>)
                      .map((trend) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: kSpaceXxs),
                            child: Text('• ${trend['description'] ?? 'Trend'}'),
                          )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
      backgroundColor: AppColors.grey100,
      label: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
