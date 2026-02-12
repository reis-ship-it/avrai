// Fabric Evolution Timeline Widget
// 
// Widget for displaying fabric evolution over time
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'package:flutter/material.dart';
import 'package:avrai_knot/models/knot/fabric_evolution.dart';

/// Widget for visualizing fabric evolution timeline
class FabricEvolutionTimeline extends StatelessWidget {
  final List<FabricEvolution> evolutionHistory;
  
  const FabricEvolutionTimeline({
    super.key,
    required this.evolutionHistory,
  });
  
  @override
  Widget build(BuildContext context) {
    if (evolutionHistory.isEmpty) {
      return const Center(
        child: Text('No evolution history available'),
      );
    }
    
    return ListView.builder(
      itemCount: evolutionHistory.length,
      itemBuilder: (context, index) {
        final evolution = evolutionHistory[index];
        return TimelineEvent(
          evolution: evolution,
          isLast: index == evolutionHistory.length - 1,
        );
      },
    );
  }
}

/// Widget for a single timeline event
class TimelineEvent extends StatelessWidget {
  final FabricEvolution evolution;
  final bool isLast;
  
  const TimelineEvent({
    super.key,
    required this.evolution,
    required this.isLast,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStabilityColor(evolution.stabilityChange),
                border: Border.all(color: Colors.grey, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Event content
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTimestamp(evolution.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${evolution.changeCount} changes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        evolution.stabilityImproved
                            ? Icons.trending_up
                            : evolution.stabilityDeclined
                                ? Icons.trending_down
                                : Icons.trending_flat,
                        size: 16,
                        color: _getStabilityColor(evolution.stabilityChange),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stability: ${(evolution.stabilityChange * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStabilityColor(evolution.stabilityChange),
                        ),
                      ),
                    ],
                  ),
                  if (evolution.changes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: evolution.changes.take(3).map((change) {
                        return Chip(
                          label: Text(
                            change.description,
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getStabilityColor(double stabilityChange) {
    if (stabilityChange > 0.05) {
      return Colors.green;
    } else if (stabilityChange < -0.05) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.month}/${timestamp.day}/${timestamp.year} '
           '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
