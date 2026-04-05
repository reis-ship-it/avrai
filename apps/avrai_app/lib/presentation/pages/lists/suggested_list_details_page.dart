import 'dart:async';

import 'package:flutter/material.dart';

import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';
import 'package:avrai/presentation/services/suggested_list_feedback_service.dart';
import 'package:avrai/presentation/services/suggested_list_interaction_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/common/undoable_negative_feedback.dart';

/// SuggestedListDetailsPage - Detail view for an AI-suggested list
///
/// Features:
/// - Full list details with all places
/// - "Why this list?" explanation section
/// - Save/dismiss actions
/// - Navigate to individual places
///
/// Part of Phase 2.1: Suggested Lists UI Components

class SuggestedListDetailsPage extends StatefulWidget {
  final SuggestedList suggestedList;

  const SuggestedListDetailsPage({
    super.key,
    required this.suggestedList,
  });

  @override
  State<SuggestedListDetailsPage> createState() =>
      _SuggestedListDetailsPageState();
}

class _SuggestedListDetailsPageState extends State<SuggestedListDetailsPage> {
  @override
  void initState() {
    super.initState();
    unawaited(
      recordSuggestedListView(
        suggestedList: widget.suggestedList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
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
    final suggestedList = widget.suggestedList;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Suggested badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
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
    final suggestedList = widget.suggestedList;

    // Map trigger reasons to user-friendly explanations
    final explanations = suggestedList.triggerReasons.map((reason) {
      return _getTriggerReasonExplanation(reason);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
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
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
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
    final suggestedList = widget.suggestedList;

    return Padding(
      padding: const EdgeInsets.all(20),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
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
                return AppSurface(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _dismissList(context),
                icon: const Icon(Icons.close),
                label: const Text('Not Interested'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _saveList(context),
                icon: const Icon(Icons.bookmark),
                label: const Text('Save List'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveList(BuildContext context) {
    unawaited(
      recordSuggestedListSave(
        suggestedList: widget.suggestedList,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('List saved to your collection'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  void _dismissList(BuildContext context) {
    unawaited(
      showUndoableNegativeFeedback(
        context: context,
        message: 'List dismissed',
        onCommit: _recordNegativePreference,
      ),
    );
    Navigator.of(context).pop();
  }

  void _shareList(BuildContext context) {
    // TODO(Phase 5.6): Implement sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToPlace(BuildContext context, String placeId) {
    // TODO(Phase 2.1): Navigate to place details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to place: $placeId'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _recordNegativePreference() async {
    await commitSuggestedListNegativeFeedback(
      suggestedList: widget.suggestedList,
      intent: NegativePreferenceIntent.hardNotInterested,
    );
  }
}
