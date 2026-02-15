/// Action Confirmation Dialog Widget
///
/// Part of Feature Matrix Phase 1: Action Execution UI & Integration
///
/// Displays a confirmation dialog before executing an AI action, showing:
/// - Action type and preview
/// - What will happen when confirmed
/// - Cancel and Confirm options
///
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/ai/action_models.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Dialog widget that shows action preview before execution
///
/// Displays a user-friendly preview of what action will be executed,
/// allowing users to confirm or cancel before the action happens.
class ActionConfirmationDialog extends StatelessWidget {
  /// The action intent to preview
  final ActionIntent intent;

  /// Callback when user confirms the action
  final VoidCallback onConfirm;

  /// Callback when user cancels the action
  final VoidCallback onCancel;

  /// Whether to show confidence level (default: false)
  final bool showConfidence;

  const ActionConfirmationDialog({
    super.key,
    required this.intent,
    required this.onConfirm,
    required this.onCancel,
    this.showConfidence = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.electricGreen,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            'Confirm Action',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionPreview(context),
            if (showConfidence) ...[
              const SizedBox(height: 16),
              _buildConfidenceIndicator(context),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onCancel();
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricGreen,
            foregroundColor: AppColors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Confirm',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  /// Builds the action preview based on intent type
  Widget _buildActionPreview(BuildContext context) {
    if (intent is CreateSpotIntent) {
      return _buildCreateSpotPreview(context, intent as CreateSpotIntent);
    } else if (intent is CreateListIntent) {
      return _buildCreateListPreview(context, intent as CreateListIntent);
    } else if (intent is AddSpotToListIntent) {
      return _buildAddSpotToListPreview(context, intent as AddSpotToListIntent);
    } else {
      return _buildGenericPreview(context);
    }
  }

  /// Builds preview for CreateSpotIntent
  Widget _buildCreateSpotPreview(
      BuildContext context, CreateSpotIntent intent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Create Spot',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        _buildPreviewItem(
          context: context,
          icon: Icons.place,
          label: 'Name',
          value: intent.name,
        ),
        if (intent.description.isNotEmpty)
          _buildPreviewItem(
            context: context,
            icon: Icons.description,
            label: 'Description',
            value: intent.description,
          ),
        _buildPreviewItem(
          context: context,
          icon: Icons.category,
          label: 'Category',
          value: intent.category,
        ),
        if (intent.address != null && intent.address!.isNotEmpty)
          _buildPreviewItem(
            context: context,
            icon: Icons.location_on,
            label: 'Address',
            value: intent.address!,
          ),
        _buildPreviewItem(
          context: context,
          icon: Icons.my_location,
          label: 'Location',
          value:
              '${intent.latitude.toStringAsFixed(4)}, ${intent.longitude.toStringAsFixed(4)}',
        ),
        if (intent.tags.isNotEmpty)
          _buildPreviewItem(
            context: context,
            icon: Icons.label,
            label: 'Tags',
            value: intent.tags.join(', '),
          ),
      ],
    );
  }

  /// Builds preview for CreateListIntent
  Widget _buildCreateListPreview(
      BuildContext context, CreateListIntent intent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Create List',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        _buildPreviewItem(
          context: context,
          icon: Icons.list,
          label: 'Title',
          value: intent.title,
        ),
        if (intent.description.isNotEmpty)
          _buildPreviewItem(
            context: context,
            icon: Icons.description,
            label: 'Description',
            value: intent.description,
          ),
        if (intent.category != null && intent.category!.isNotEmpty)
          _buildPreviewItem(
            context: context,
            icon: Icons.category,
            label: 'Category',
            value: intent.category!,
          ),
        _buildPreviewItem(
          context: context,
          icon: intent.isPublic ? Icons.public : Icons.lock,
          label: 'Visibility',
          value: intent.isPublic ? 'Public' : 'Private',
        ),
        if (intent.tags.isNotEmpty)
          _buildPreviewItem(
            context: context,
            icon: Icons.label,
            label: 'Tags',
            value: intent.tags.join(', '),
          ),
      ],
    );
  }

  /// Builds preview for AddSpotToListIntent
  Widget _buildAddSpotToListPreview(
      BuildContext context, AddSpotToListIntent intent) {
    final spotName = intent.metadata['spotName'] as String? ?? 'Spot';
    final listName = intent.metadata['listName'] as String? ?? 'List';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Add Spot to List',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        _buildPreviewItem(
          context: context,
          icon: Icons.place,
          label: 'Spot',
          value: spotName,
        ),
        _buildPreviewItem(
          context: context,
          icon: Icons.list,
          label: 'List',
          value: listName,
        ),
      ],
    );
  }

  /// Builds generic preview for unknown intent types
  Widget _buildGenericPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Execute Action: ${intent.type}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Are you sure you want to execute this action?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  /// Builds a preview item row
  Widget _buildPreviewItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds confidence indicator
  Widget _buildConfidenceIndicator(BuildContext context) {
    final confidencePercent = (intent.confidence * 100).toInt();
    final confidenceColor = intent.confidence >= 0.8
        ? AppColors.electricGreen
        : intent.confidence >= 0.6
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(kSpaceSm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.grey300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 18,
            color: confidenceColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidence Level',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: intent.confidence,
                        backgroundColor: AppColors.grey300,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(confidenceColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$confidencePercent%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: confidenceColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
