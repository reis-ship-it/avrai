/// Action Error Dialog Widget
///
/// Part of Feature Matrix Phase 1: Action Execution UI & Integration
///
/// Displays an error dialog when an AI action fails, showing:
/// - Error message (user-friendly)
/// - Optional retry mechanism
/// - Intent context (what failed)
/// - View Details button (shows technical details)
/// - Actionable guidance and alternatives
///
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/ai/action_models.dart';
import 'package:avrai/core/services/misc/action_error_handler.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Dialog widget that shows action failure details
class ActionErrorDialog extends StatefulWidget {
  /// The error message to display
  final String error;

  /// The intent that failed (optional)
  final ActionIntent? intent;

  /// Callback when user dismisses the dialog
  final VoidCallback onDismiss;

  /// Callback when user wants to retry (optional)
  final VoidCallback? onRetry;

  /// Technical error details (optional, shown in View Details)
  final String? technicalDetails;

  const ActionErrorDialog({
    super.key,
    required this.error,
    this.intent,
    required this.onDismiss,
    this.onRetry,
    this.technicalDetails,
  });

  @override
  State<ActionErrorDialog> createState() => _ActionErrorDialogState();
}

class _ActionErrorDialogState extends State<ActionErrorDialog> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    // Use ActionErrorHandler for error categorization and user-friendly messages
    final errorString = widget.technicalDetails ?? widget.error;
    final userFriendlyError = ActionErrorHandler.getUserFriendlyMessage(
      errorString,
      null, // ActionResult not available here
      widget.intent,
    );
    final suggestions = _getSuggestions(errorString, widget.intent);

    // Determine if retry should be available based on error category
    final canRetry = ActionErrorHandler.canRetry(errorString, null);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            'Action Failed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            if (widget.intent != null) ...[
              Container(
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
                      _getIconForIntent(widget.intent!),
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getFailureContext(widget.intent!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              userFriendlyError,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(kSpaceSm),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.electricGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: AppColors.electricGreen,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Suggestions',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...suggestions.map((suggestion) => Padding(
                          padding: const EdgeInsets.only(bottom: kSpaceXxs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
            if (widget.technicalDetails != null || _showDetails) ...[
              const SizedBox(height: 16),
              if (_showDetails) ...[
                Container(
                  padding: const EdgeInsets.all(kSpaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.grey300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Technical Details',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.technicalDetails ?? widget.error,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (widget.technicalDetails != null ||
            widget.error != userFriendlyError)
          TextButton(
            onPressed: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            child: Text(
              _showDetails ? 'Hide Details' : 'View Details',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        TextButton(
          onPressed: () {
            widget.onDismiss();
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
        // Show retry button if retry callback is provided and error is retryable
        if (widget.onRetry != null && canRetry)
          ElevatedButton(
            onPressed: () {
              widget.onRetry!();
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
              'Retry',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
      ],
    );
  }

  String _getFailureContext(ActionIntent intent) {
    if (intent is CreateSpotIntent) {
      return 'Failed to create spot: ${intent.name}';
    } else if (intent is CreateListIntent) {
      return 'Failed to create list: ${intent.title}';
    } else if (intent is AddSpotToListIntent) {
      return 'Failed to add spot to list';
    }
    return 'Failed to execute action';
  }

  IconData _getIconForIntent(ActionIntent intent) {
    if (intent is CreateSpotIntent) {
      return Icons.place;
    } else if (intent is CreateListIntent) {
      return Icons.list;
    } else if (intent is AddSpotToListIntent) {
      return Icons.add_circle_outline;
    }
    return Icons.help_outline;
  }

  // Removed _translateError - now using ActionErrorHandler.getUserFriendlyMessage

  /// Get actionable suggestions based on error and intent
  /// Enhanced with ActionErrorHandler error categorization
  List<String> _getSuggestions(String error, ActionIntent? intent) {
    final suggestions = <String>[];
    final errorCategory = ActionErrorHandler.categorizeError(error, null);

    // Use error category for more accurate suggestions
    switch (errorCategory) {
      case ActionErrorCategory.network:
        suggestions.add('Check your internet connection');
        suggestions.add('Try again in a few moments');
        if (intent != null) {
          suggestions.add('You can try this action again later');
        }
        break;

      case ActionErrorCategory.validation:
        if (intent is CreateSpotIntent) {
          suggestions.add('Make sure the spot name is not empty');
          suggestions.add('Check that the location is valid');
        } else if (intent is CreateListIntent) {
          suggestions.add('Make sure the list name is not empty');
          suggestions.add('Try using a different name');
        } else {
          suggestions.add('Please check your input and try again');
        }
        break;

      case ActionErrorCategory.permission:
        suggestions.add('Check your account permissions');
        suggestions.add('You may need to grant additional permissions');
        break;

      case ActionErrorCategory.notFound:
        if (intent is AddSpotToListIntent) {
          suggestions.add('The spot or list may have been deleted');
          suggestions
              .add('Try creating a new list or selecting a different spot');
        } else {
          suggestions.add('The requested item could not be found');
          suggestions.add('It may have been deleted or moved');
        }
        break;

      case ActionErrorCategory.conflict:
        if (intent is CreateSpotIntent) {
          suggestions.add('A spot with this name may already exist');
          suggestions.add('Try using a different name or location');
        } else if (intent is CreateListIntent) {
          suggestions.add('A list with this name may already exist');
          suggestions.add('Try using a different name');
        } else {
          suggestions.add('This conflicts with existing data');
          suggestions.add('Please check and use different information');
        }
        break;

      case ActionErrorCategory.server:
        suggestions.add('Server may be temporarily unavailable');
        suggestions.add('Try again in a few moments');
        break;

      case ActionErrorCategory.unknown:
        // Generic suggestions
        if (intent != null) {
          suggestions.add('Please try again');
          if (ActionErrorHandler.canRetry(error, null) &&
              widget.onRetry != null) {
            suggestions.add('You can retry this action using the Retry button');
          }
        }
        break;
    }

    return suggestions;
  }
}
