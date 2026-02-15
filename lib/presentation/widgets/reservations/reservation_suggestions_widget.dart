/// Reservation Suggestions Widget
///
/// Phase 6.2: AI-Powered Reservation Suggestions
///
/// Widget displaying AI-powered reservation recommendations:
/// - AI suggests spots/events to reserve based on:
///   - User preferences (from PersonalityLearning)
///   - Past reservations (from ReservationService)
///   - Personality profile (from PersonalityLearning)
///   - Time patterns (analyzed from past reservations)
///   - Community activity (via AISearchSuggestionsService)
///
/// Uses AppColors/AppTheme for 100% design token compliance.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/core/services/reservation/reservation_recommendation_service.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Widget displaying AI-powered reservation suggestions
class ReservationSuggestionsWidget extends StatefulWidget {
  /// User ID to show suggestions for
  final String userId;

  /// Reservation recommendation service
  final ReservationRecommendationService recommendationService;

  /// Maximum number of suggestions to display
  final int maxSuggestions;

  /// Callback when a suggestion is selected
  final Function(ReservationRecommendation)? onSuggestionSelected;

  const ReservationSuggestionsWidget({
    super.key,
    required this.userId,
    required this.recommendationService,
    this.maxSuggestions = 5,
    this.onSuggestionSelected,
  });

  @override
  State<ReservationSuggestionsWidget> createState() =>
      _ReservationSuggestionsWidgetState();
}

class _ReservationSuggestionsWidgetState
    extends State<ReservationSuggestionsWidget> {
  List<ReservationRecommendation>? _suggestions;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final suggestions =
          await widget.recommendationService.getAIPoweredReservations(
        userId: widget.userId,
        limit: widget.maxSuggestions,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load suggestions: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    if (_isLoading) {
      return Semantics(
        label: 'Loading reservation suggestions',
        child: Card(
          margin: EdgeInsets.only(bottom: spacing.md),
          child: Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Semantics(
        label: 'Error loading suggestions',
        child: Card(
          margin: EdgeInsets.only(bottom: spacing.md),
          child: Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadSuggestions,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_suggestions == null || _suggestions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'AI-powered reservation suggestions',
      child: Card(
        margin: EdgeInsets.only(bottom: spacing.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              ..._suggestions!.map((suggestion) => _buildSuggestionCard(
                    suggestion,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'AI Suggestions for You',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(ReservationRecommendation suggestion) {
    final spacing = context.spacing;
    return Card(
      margin: EdgeInsets.only(bottom: spacing.sm),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (widget.onSuggestionSelected != null) {
            widget.onSuggestionSelected!(suggestion);
          } else {
            // Default: navigate to reservation creation
            context.push(
              '/reservations/create',
              extra: {
                'type': suggestion.type,
                'targetId': suggestion.targetId,
                'targetTitle': suggestion.title,
              },
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(spacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  // Compatibility score badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSpaceXs,
                      vertical: kSpaceXxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(suggestion.compatibility * 100).toStringAsFixed(0)}% match',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                    ),
                  ),
                ],
              ),
              if (suggestion.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  suggestion.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (suggestion.aiReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(spacing.xs),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.aiReason!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (suggestion.recommendedTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(suggestion.recommendedTime!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (widget.onSuggestionSelected != null) {
                        widget.onSuggestionSelected!(suggestion);
                      } else {
                        context.push(
                          '/reservations/create',
                          extra: {
                            'type': suggestion.type,
                            'targetId': suggestion.targetId,
                            'targetTitle': suggestion.title,
                          },
                        );
                      }
                    },
                    icon: const Icon(Icons.event_available, size: 16),
                    label: Text('Reserve'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(dateTime.weekday)} at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.month}/${dateTime.day} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}
