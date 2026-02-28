import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/theme/colors.dart';

/// Widget displaying personality evolution timeline
class EvolutionTimelineWidget extends StatelessWidget {
  final PersonalityProfile profile;

  const EvolutionTimelineWidget({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = profile.learningHistory['evolution_milestones'] as List<DateTime>? ?? [];
    final totalInteractions = profile.learningHistory['total_interactions'] as int? ?? 0;
    final successfulConnections = profile.learningHistory['successful_ai2ai_connections'] as int? ?? 0;

    return Card(
      elevation: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
            Text(
              'Evolution Timeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Generation',
                  '${profile.evolutionGeneration}',
                ),
                _buildStatItem(
                  context,
                  'Interactions',
                  '$totalInteractions',
                ),
                _buildStatItem(
                  context,
                  'Connections',
                  '$successfulConnections',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Timeline
            if (milestones.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.timeline,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No evolution milestones yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Milestones will appear as your personality evolves',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...milestones.reversed.take(10).map((milestone) => _buildTimelineItem(
                context,
                milestone,
                milestones.indexOf(milestone) == milestones.length - 1,
              )),
            // Created date
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Created: ${_formatDate(profile.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.update, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Last Updated: ${_formatDate(profile.lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
                ],
              ),
            ),
          );
        },
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
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, DateTime milestone, bool isLatest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLatest ? AppColors.success : AppColors.grey400,
                  border: Border.all(
                    color: AppColors.white,
                    width: 2,
                  ),
                ),
              ),
              if (!isLatest)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.grey300,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evolution Milestone',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(milestone),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

