import 'package:flutter/material.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/theme/colors.dart';

/// Widget displaying user's active AI2AI connections
class UserConnectionsDisplay extends StatelessWidget {
  final ActiveConnectionsOverview overview;

  const UserConnectionsDisplay({
    super.key,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Connections',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  label: Text('${overview.totalActiveConnections}'),
                  backgroundColor: AppColors.grey100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (overview.totalActiveConnections == 0)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.link_off,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No active connections',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your AI will discover nearby personalities automatically',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Connection Quality Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Avg Compatibility',
                    '${(overview.aggregateMetrics.averageCompatibility * 100).round()}%',
                  ),
                  _buildStatItem(
                    context,
                    'Avg Duration',
                    '${overview.averageConnectionDuration.inMinutes}min',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (overview.topPerformingConnections.isNotEmpty) ...[
                Text(
                  'Top Connections',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...overview.topPerformingConnections.take(3).map(
                      (connectionId) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.success,
                          child: Icon(
                            Icons.link,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Connection ${connectionId.length > 8 ? connectionId.substring(0, 8) : connectionId}...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          'High performance',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              ),
                        ),
                      ),
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

