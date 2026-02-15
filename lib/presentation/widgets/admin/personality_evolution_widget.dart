import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/contextual_personality.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// OUR_GUTS.md: "Your doors stay yours"
/// Phase 3: Admin UI for Contextual Personality Visualization
/// ADMIN ONLY - Shows personality evolution timeline and context layers
class PersonalityEvolutionWidget extends StatelessWidget {
  final PersonalityProfile profile;
  final bool showDetailed;

  const PersonalityEvolutionWidget({
    super.key,
    required this.profile,
    this.showDetailed = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (profile.isInTransition) _buildTransitionAlert(context),
            const SizedBox(height: 16),
            _buildCoreVsCurrentComparison(context),
            const SizedBox(height: 24),
            _buildContextualLayers(context),
            const SizedBox(height: 24),
            _buildEvolutionTimeline(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_outline, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          'Personality Evolution',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const Spacer(),
        _buildEvolutionBadge(context),
      ],
    );
  }

  Widget _buildEvolutionBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Gen ${profile.evolutionGeneration}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTransitionAlert(BuildContext context) {
    if (!profile.isInTransition || profile.activeTransition == null) {
      return const SizedBox.shrink();
    }

    final transition = profile.activeTransition!;

    return Container(
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: transition.isAuthentic
            ? AppColors.electricGreen.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: transition.isAuthentic
              ? AppColors.electricGreen
              : AppColors.warning,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            transition.isAuthentic ? Icons.check_circle : Icons.warning,
            color: transition.isAuthentic
                ? AppColors.electricGreen
                : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transition.isAuthentic
                      ? 'Authentic Transition In Progress'
                      : 'Monitoring Personality Changes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: transition.isAuthentic
                            ? AppColors.electricGreen
                            : AppColors.warning,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Authenticity: ${(transition.authenticityScore * 100).round()}% | '
                  'Consistency: ${(transition.consistency * 100).round()}%',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreVsCurrentComparison(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Core vs Current Personality',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        ...VibeConstants.coreDimensions.take(6).map((dimension) {
          final coreValue = profile.corePersonality[dimension] ?? 0.5;
          final currentValue = profile.dimensions[dimension] ?? 0.5;
          final diff = currentValue - coreValue;

          return Padding(
            padding: EdgeInsets.only(bottom: context.spacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDimensionName(dimension),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    if (diff.abs() > 0.1)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacing.xs,
                          vertical: context.spacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: diff > 0
                              ? AppColors.electricGreen.withValues(alpha: 0.2)
                              : AppColors.grey600.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: diff > 0
                                        ? AppColors.electricGreen
                                        : AppColors.grey600,
                                  ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    // Core (baseline)
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: coreValue,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Current (overlay)
                    SizedBox(
                      height: 20,
                      child: FractionallySizedBox(
                        widthFactor: currentValue,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLegendItem(
                context, 'Core', AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(width: 16),
            _buildLegendItem(context, 'Current', AppColors.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildContextualLayers(BuildContext context) {
    if (profile.contexts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contextual Layers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: 12),
          Text(
            'No contextual adaptations yet',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contextual Layers',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        ...profile.contexts.entries.map((entry) {
          return _buildContextCard(context, entry.value);
        }),
      ],
    );
  }

  Widget _buildContextCard(
      BuildContext context, ContextualPersonality personalityContext) {
    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getContextIcon(personalityContext.contextType),
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatContextType(personalityContext.contextType),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const Spacer(),
                Text(
                  '${(personalityContext.adaptationWeight * 100).round()}% blend',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${personalityContext.adaptedDimensions.length} adapted dimensions • '
              'Updated ${personalityContext.updateCount} times',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionTimeline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolution Timeline',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        ...profile.evolutionTimeline.reversed.map((phase) {
          return _buildPhaseCard(context, phase);
        }),
      ],
    );
  }

  Widget _buildPhaseCard(BuildContext context, LifePhase phase) {
    final isCurrent = phase.phaseId == profile.currentPhaseId;

    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      color: isCurrent
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCurrent ? Icons.timeline : Icons.history,
                  size: 20,
                  color:
                      isCurrent ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phase.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.xs,
                      vertical: context.spacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CURRENT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatPhaseDate(phase),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (phase.dominantTraits.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: phase.dominantTraits.map((trait) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.xs,
                      vertical: context.spacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDimensionName(trait),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDimensionName(String dimension) {
    return dimension
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatContextType(PersonalityContextType type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }

  IconData _getContextIcon(PersonalityContextType type) {
    switch (type) {
      case PersonalityContextType.work:
        return Icons.work;
      case PersonalityContextType.social:
        return Icons.people;
      case PersonalityContextType.exploration:
        return Icons.explore;
      case PersonalityContextType.location:
        return Icons.location_on;
      case PersonalityContextType.activity:
        return Icons.sports_basketball;
      case PersonalityContextType.general:
        return Icons.home;
    }
  }

  String _formatPhaseDate(LifePhase phase) {
    final startFormatted = _formatDate(phase.startDate);
    if (phase.endDate == null) {
      return '$startFormatted - Present (${phase.duration.inDays} days)';
    }
    final endFormatted = _formatDate(phase.endDate!);
    return '$startFormatted - $endFormatted (${phase.duration.inDays} days)';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
