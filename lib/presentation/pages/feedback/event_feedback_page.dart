import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/services/events/post_event_feedback_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Event Feedback Page
///
/// Agent 2: Phase 5, Week 17 - Feedback UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Overall star rating
/// - Category ratings (sliders)
/// - Highlight selection (chips)
/// - Improvement suggestions
/// - Would attend again? (toggle)
/// - Would recommend? (toggle)
/// - Optional comments
/// - Submit button
class EventFeedbackPage extends StatefulWidget {
  final ExpertiseEvent event;

  const EventFeedbackPage({
    super.key,
    required this.event,
  });

  @override
  State<EventFeedbackPage> createState() => _EventFeedbackPageState();
}

class _EventFeedbackPageState extends State<EventFeedbackPage> {
  final PostEventFeedbackService _feedbackService = PostEventFeedbackService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );

  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();

  double _overallRating = 0.0;
  final Map<String, double> _categoryRatings = {
    'organization': 0.0,
    'content_quality': 0.0,
    'venue': 0.0,
    'value_for_money': 0.0,
  };
  final List<String> _selectedHighlights = [];
  final List<String> _selectedImprovements = [];
  bool _wouldAttendAgain = false;
  bool _wouldRecommend = false;
  bool _isSubmitting = false;
  String? _error;

  // Available highlight options
  final List<String> _highlightOptions = [
    'Great organization',
    'Engaging content',
    'Excellent venue',
    'Good value',
    'Friendly host',
    'Well-paced',
    'Interactive',
    'Educational',
    'Fun atmosphere',
    'Networking opportunities',
  ];

  // Available improvement options
  final List<String> _improvementOptions = [
    'Better communication',
    'More preparation',
    'Better venue',
    'More content',
    'Better timing',
    'More interactive',
    'Better organization',
    'More value',
    'Better facilities',
    'More engagement',
  ];

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    if (_overallRating == 0.0) {
      context.showError('Please provide an overall rating');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to submit feedback');
      }

      await _feedbackService.submitFeedback(
        eventId: widget.event.id,
        userId: authState.user.id,
        overallRating: _overallRating,
        categoryRatings: _categoryRatings,
        comments: _commentsController.text.trim().isEmpty
            ? null
            : _commentsController.text.trim(),
        highlights: _selectedHighlights.isEmpty ? null : _selectedHighlights,
        improvements:
            _selectedImprovements.isEmpty ? null : _selectedImprovements,
        wouldAttendAgain: _wouldAttendAgain,
        wouldRecommend: _wouldRecommend,
      );

      if (mounted) {
        Navigator.pop(context);
        context.showSuccess('Thank you for your feedback!');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Event Feedback',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(context.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Info
                _buildEventInfo(),
                SizedBox(height: context.spacing.xl),

                // Overall Rating
                _buildOverallRating(),
                SizedBox(height: context.spacing.xl),

                // Category Ratings
                _buildCategoryRatings(),
                SizedBox(height: context.spacing.xl),

                // Highlights
                _buildHighlights(),
                SizedBox(height: context.spacing.xl),

                // Improvements
                _buildImprovements(),
                SizedBox(height: context.spacing.xl),

                // Would Attend Again / Recommend
                _buildRecommendationToggles(),
                SizedBox(height: context.spacing.xl),

                // Comments
                _buildComments(),
                SizedBox(height: context.spacing.xl),

                // Error Display
                if (_error != null) ...[
                  PortalSurface(
                    padding: EdgeInsets.all(context.spacing.md),
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderColor: AppColors.error.withValues(alpha: 0.3),
                    radius: context.radius.sm,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        SizedBox(width: context.spacing.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.spacing.xl),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    minimumSize: Size(double.infinity, context.spacing.xxl),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text('Submit Feedback'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your experience?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            widget.event.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.xxs),
          Text(
            '${_formatDateTime(widget.event.startTime)} • ${widget.event.location ?? 'Location TBD'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Rating *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = (index + 1).toDouble();
            return GestureDetector(
              onTap: () {
                setState(() {
                  _overallRating = starValue;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.xxs),
                child: Icon(
                  _overallRating >= starValue ? Icons.star : Icons.star_border,
                  size: 48,
                  color: _overallRating >= starValue
                      ? AppTheme.warningColor
                      : AppColors.grey400,
                ),
              ),
            );
          }),
        ),
        if (_overallRating > 0) ...[
          SizedBox(height: context.spacing.xs),
          Center(
            child: Text(
              '${_overallRating.toStringAsFixed(1)} out of 5',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Ratings',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.sm),
        ..._categoryRatings.keys.map((category) {
          return Padding(
            padding: EdgeInsets.only(bottom: context.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getCategoryDisplayName(category),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      _categoryRatings[category]! > 0
                          ? '${_categoryRatings[category]!.toStringAsFixed(1)} / 5.0'
                          : 'Not rated',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.xs),
                Slider(
                  value: _categoryRatings[category]!,
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  label: _categoryRatings[category]! > 0
                      ? _categoryRatings[category]!.toStringAsFixed(1)
                      : null,
                  onChanged: (value) {
                    setState(() {
                      _categoryRatings[category] = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What was great? (Optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _highlightOptions.map((highlight) {
            final isSelected = _selectedHighlights.contains(highlight);
            return FilterChip(
              label: Text(highlight),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedHighlights.add(highlight);
                  } else {
                    _selectedHighlights.remove(highlight);
                  }
                });
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImprovements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What could be better? (Optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _improvementOptions.map((improvement) {
            final isSelected = _selectedImprovements.contains(improvement);
            return FilterChip(
              label: Text(improvement),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedImprovements.add(improvement);
                  } else {
                    _selectedImprovements.remove(improvement);
                  }
                });
              },
              selectedColor: AppTheme.warningColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.warningColor,
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? AppTheme.warningColor
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendationToggles() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.sm,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Would you attend again?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            value: _wouldAttendAgain,
            onChanged: (value) {
              setState(() {
                _wouldAttendAgain = value;
              });
            },
            activeThumbColor: AppTheme.primaryColor,
          ),
          SwitchListTile(
            title: Text(
              'Would you recommend to others?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            value: _wouldRecommend,
            onChanged: (value) {
              setState(() {
                _wouldRecommend = value;
              });
            },
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Comments (Optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        TextFormField(
          controller: _commentsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share any additional thoughts...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'organization':
        return 'Organization';
      case 'content_quality':
        return 'Content Quality';
      case 'venue':
        return 'Venue';
      case 'value_for_money':
        return 'Value for Money';
      default:
        return category;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}
