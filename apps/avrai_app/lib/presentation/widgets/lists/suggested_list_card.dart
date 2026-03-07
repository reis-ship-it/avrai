import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/common/undoable_negative_feedback.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';

/// SuggestedListCard - Card displaying an AI-suggested list
///
/// Features:
/// - "AI Suggested" badge
/// - Quality score indicator
/// - "Why this list?" button
/// - Dismiss/save actions with confirmation
///
/// Part of Phase 2.1: Suggested Lists UI Components

class SuggestedListCard extends StatelessWidget {
  /// Quality score threshold for high quality (green indicator)
  static const double highQualityThreshold = 0.7;

  /// Quality score threshold for medium quality (orange indicator)
  static const double mediumQualityThreshold = 0.5;

  final SuggestedList suggestedList;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onSave;
  final VoidCallback? onWhyThisList;
  final VoidCallback? onPin;
  final VoidCallback? onUndoDismiss;

  /// Whether to show confirmation dialog before dismissing
  final bool confirmDismiss;

  const SuggestedListCard({
    super.key,
    required this.suggestedList,
    this.onTap,
    this.onDismiss,
    this.onSave,
    this.onWhyThisList,
    this.onPin,
    this.onUndoDismiss,
    this.confirmDismiss = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: Key(suggestedList.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && confirmDismiss) {
          // Show confirmation for dismiss
          return await _showDismissConfirmation(context);
        }
        return true; // Save doesn't need confirmation
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          unawaited(
            showUndoableNegativeFeedback(
              context: context,
              message: '${suggestedList.title} hidden for now.',
              onOptimisticUpdate: onDismiss,
              onUndo: onUndoDismiss,
              onCommit: _recordNegativePreference,
            ),
          );
        } else {
          onSave?.call();
        }
      },
      background: _buildDismissBackground(
        context,
        icon: Icons.bookmark,
        color: AppColors.success,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildDismissBackground(
        context,
        icon: Icons.close,
        color: AppColors.error,
        alignment: Alignment.centerRight,
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with AI badge, pin indicator, and quality indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAISuggestedBadge(context),
                        if (suggestedList.isPinned) ...[
                          const SizedBox(width: 8),
                          _buildPinnedBadge(context),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onPin != null)
                          IconButton(
                            icon: Icon(
                              suggestedList.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              size: 18,
                            ),
                            onPressed: onPin,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: suggestedList.isPinned ? 'Unpin' : 'Pin',
                          ),
                        const SizedBox(width: 8),
                        _buildQualityIndicator(context),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  suggestedList.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  suggestedList.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Category and place count
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        suggestedList.theme,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${suggestedList.placeCount} places',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // "Why this list?" button
                    if (onWhyThisList != null)
                      TextButton.icon(
                        onPressed: onWhyThisList,
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Why?'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.push_pin,
            size: 12,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Pinned',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestedBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'AI Suggested',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityIndicator(BuildContext context) {
    final quality = suggestedList.qualityScore;
    final colorScheme = Theme.of(context).colorScheme;

    Color indicatorColor;
    if (quality >= highQualityThreshold) {
      indicatorColor = AppColors.success;
    } else if (quality >= mediumQualityThreshold) {
      indicatorColor = AppColors.warning;
    } else {
      indicatorColor = colorScheme.onSurfaceVariant;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: 14,
          color: indicatorColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${(quality * 100).toInt()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: indicatorColor,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  /// Show confirmation dialog before dismissing
  Future<bool> _showDismissConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Dismiss this list?'),
            content: Text(
              'Are you sure you want to dismiss "${suggestedList.title}"? '
              'You can find similar suggestions in your preferences.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildDismissBackground(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color),
    );
  }

  Future<void> _recordNegativePreference() async {
    if (!di.sl.isRegistered<EntitySignatureService>()) {
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }
    await di.sl<EntitySignatureService>().recordNegativePreferenceSignal(
          userId: userId,
          title: suggestedList.title,
          subtitle: suggestedList.description,
          category: suggestedList.theme,
          tags: <String>[
            suggestedList.theme,
            ...suggestedList.triggerReasons,
          ],
          intent: NegativePreferenceIntent.softIgnore,
          entityType: 'suggested_list',
        );
  }
}
