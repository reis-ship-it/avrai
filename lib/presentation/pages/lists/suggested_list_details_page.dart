import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/ai/perpetual_list/models/models.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// SuggestedListDetailsPage - Detail view for an AI-suggested list
///
/// Features:
/// - Full list details with all places
/// - "Why this list?" explanation section
/// - Save/dismiss actions
/// - Navigate to individual places
///
/// Part of Phase 2.1: Suggested Lists UI Components

class SuggestedListDetailsPage extends StatelessWidget {
  final SuggestedList suggestedList;

  const SuggestedListDetailsPage({
    super.key,
    required this.suggestedList,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Suggested List',
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () => _saveList(context),
          tooltip: 'Save list',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareList(context),
          tooltip: 'Share list',
        ),
      ],
      constrainBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeader(context),

            // Why this list section
            _buildWhyThisListSection(context),

            // Places section
            _buildPlacesSection(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PortalSurface(
      padding: const EdgeInsets.all(kSpaceMdWide),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      borderColor: colorScheme.primaryContainer,
      radius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Suggested badge
          Chip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
            backgroundColor: colorScheme.secondaryContainer,
            labelPadding: EdgeInsets.zero,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI Suggested',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            suggestedList.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            suggestedList.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _buildStat(
                context,
                icon: Icons.location_on_outlined,
                value: '${suggestedList.placeCount}',
                label: 'Places',
              ),
              const SizedBox(width: 24),
              _buildStat(
                context,
                icon: Icons.star_outline,
                value: '${(suggestedList.qualityScore * 100).toInt()}%',
                label: 'Match',
              ),
              const SizedBox(width: 24),
              _buildStat(
                context,
                icon: Icons.category_outlined,
                value: suggestedList.theme,
                label: 'Theme',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWhyThisListSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Map trigger reasons to user-friendly explanations
    final explanations = suggestedList.triggerReasons.map((reason) {
      return _getTriggerReasonExplanation(reason);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(kSpaceMdWide),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Why this list?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...explanations.map((explanation) {
            return Padding(
              padding: const EdgeInsets.only(bottom: kSpaceXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 3,
                    backgroundColor: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      explanation,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getTriggerReasonExplanation(String reason) {
    switch (reason.toLowerCase()) {
      case 'time_based':
        return 'Perfect timing for your usual activities';
      case 'location_change':
        return 'New location detected - explore what\'s nearby';
      case 'ai2ai_insights':
        return 'Based on insights from your AI network';
      case 'personality_drift':
        return 'Your preferences have been evolving';
      case 'poor_engagement':
        return 'We noticed you haven\'t been engaging - here\'s something fresh';
      default:
        return 'Personalized based on your preferences';
    }
  }

  Widget _buildPlacesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(kSpaceMdWide),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Places',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (suggestedList.places.isEmpty)
            PortalSurface(
              padding: const EdgeInsets.all(kSpaceLg),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderColor: colorScheme.outlineVariant,
              radius: 12,
              child: Center(
                child: Text(
                  'No places available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestedList.places.length,
              itemBuilder: (context, index) {
                final place = suggestedList.places[index];
                return PortalSurface(
                  margin: const EdgeInsets.only(bottom: kSpaceSm),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    title: Text(
                      place.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      place.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _navigateToPlace(context, place.id),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(kSpaceMd),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _dismissList(context),
                icon: const Icon(Icons.close),
                label: Text('Not Interested'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: kSpaceSm),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _saveList(context),
                icon: const Icon(Icons.bookmark),
                label: Text('Save List'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: kSpaceSm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveList(BuildContext context) {
    FeedbackPresenter.showSnack(
      context,
      message: 'List saved to your collection',
      kind: FeedbackKind.success,
    );
    Navigator.of(context).pop();
  }

  void _dismissList(BuildContext context) {
    FeedbackPresenter.showSnack(
      context,
      message: 'List dismissed',
      kind: FeedbackKind.warning,
    );
    Navigator.of(context).pop();
  }

  void _shareList(BuildContext context) {
    // TODO(Phase 5.6): Implement sharing
    context.showInfo('Sharing coming soon');
  }

  void _navigateToPlace(BuildContext context, String placeId) {
    // TODO(Phase 2.1): Navigate to place details
    context.showInfo('Navigate to place: $placeId');
  }
}
