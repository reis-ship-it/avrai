import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/services/events/post_event_feedback_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Partner Rating Page
///
/// Agent 2: Phase 5, Week 17 - Feedback UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Rate each partner individually
/// - Professionalism, communication, reliability ratings
/// - Would partner again?
/// - Positive feedback
/// - Improvement suggestions
class PartnerRatingPage extends StatefulWidget {
  final ExpertiseEvent event;
  final String partnerId;
  final String partnershipRole; // 'host', 'venue', 'sponsor', etc.

  const PartnerRatingPage({
    super.key,
    required this.event,
    required this.partnerId,
    required this.partnershipRole,
  });

  @override
  State<PartnerRatingPage> createState() => _PartnerRatingPageState();
}

class _PartnerRatingPageState extends State<PartnerRatingPage> {
  final PostEventFeedbackService _feedbackService = PostEventFeedbackService(
    eventService: GetIt.instance<ExpertiseEventService>(),
    partnershipService: GetIt.instance<PartnershipService>(),
  );

  final _formKey = GlobalKey<FormState>();
  final _positivesController = TextEditingController();
  final _improvementsController = TextEditingController();

  double _overallRating = 0.0;
  double _professionalism = 0.0;
  double _communication = 0.0;
  double _reliability = 0.0;
  double _wouldPartnerAgain = 0.0;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _positivesController.dispose();
    _improvementsController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
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
        throw Exception('Please sign in to submit a rating');
      }

      // Get partnership ID (simplified - in production, get from partnership service)
      // ignore: unused_local_variable - Reserved for future partnership tracking
      String partnershipId =
          'partnership_${widget.event.id}_${widget.partnerId}';
      try {
        final partnerships = await GetIt.instance<PartnershipService>()
            .getPartnershipsForEvent(widget.event.id);
        final partnership = partnerships.firstWhere(
          (p) =>
              p.userId == widget.partnerId || p.businessId == widget.partnerId,
        );
        partnershipId = partnership.id;
      } catch (e) {
        // Use default partnership ID if not found
      }

      await _feedbackService.submitPartnerRating(
        eventId: widget.event.id,
        raterId: authState.user.id,
        ratedId: widget.partnerId,
        partnershipRole: widget.partnershipRole,
        overallRating: _overallRating,
        professionalism: _professionalism,
        communication: _communication,
        reliability: _reliability,
        wouldPartnerAgain: _wouldPartnerAgain,
        positives: _positivesController.text.trim().isEmpty
            ? null
            : _positivesController.text.trim(),
        improvements: _improvementsController.text.trim().isEmpty
            ? null
            : _improvementsController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        context.showSuccess('Thank you for your rating!');
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
      title: 'Rate Partner',
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
                // Partner Info
                _buildPartnerInfo(),
                SizedBox(height: context.spacing.xl),

                // Overall Rating
                _buildOverallRating(),
                SizedBox(height: context.spacing.xl),

                // Detailed Ratings
                _buildDetailedRatings(),
                SizedBox(height: context.spacing.xl),

                // Would Partner Again
                _buildWouldPartnerAgain(),
                SizedBox(height: context.spacing.xl),

                // Positive Feedback
                _buildPositives(),
                SizedBox(height: context.spacing.xl),

                // Improvement Suggestions
                _buildImprovements(),
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
                  onPressed: _isSubmitting ? null : _submitRating,
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
                      : Text('Submit Rating'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerInfo() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate Your Partner',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            'Event: ${widget.event.title}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: context.spacing.xxs),
          Text(
            'Role: ${_getRoleDisplayName(widget.partnershipRole)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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

  Widget _buildDetailedRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Ratings',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.sm),
        _buildRatingSlider('Professionalism', _professionalism, (value) {
          setState(() {
            _professionalism = value;
          });
        }),
        SizedBox(height: context.spacing.md),
        _buildRatingSlider('Communication', _communication, (value) {
          setState(() {
            _communication = value;
          });
        }),
        SizedBox(height: context.spacing.md),
        _buildRatingSlider('Reliability', _reliability, (value) {
          setState(() {
            _reliability = value;
          });
        }),
      ],
    );
  }

  Widget _buildRatingSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              value > 0 ? '${value.toStringAsFixed(1)} / 5.0' : 'Not rated',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.xs),
        Slider(
          value: value,
          min: 0.0,
          max: 5.0,
          divisions: 10,
          label: value > 0 ? value.toStringAsFixed(1) : null,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildWouldPartnerAgain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Would you partner again? *',
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
                  _wouldPartnerAgain = starValue;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.xxs),
                child: Icon(
                  _wouldPartnerAgain >= starValue
                      ? Icons.star
                      : Icons.star_border,
                  size: 40,
                  color: _wouldPartnerAgain >= starValue
                      ? AppColors.electricGreen
                      : AppColors.grey400,
                ),
              ),
            );
          }),
        ),
        if (_wouldPartnerAgain > 0) ...[
          SizedBox(height: context.spacing.xs),
          Center(
            child: Text(
              _getWouldPartnerAgainText(_wouldPartnerAgain),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPositives() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Positive Feedback (Optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        TextFormField(
          controller: _positivesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What did they do well?',
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

  Widget _buildImprovements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Improvement Suggestions (Optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        TextFormField(
          controller: _improvementsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What could be improved?',
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

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'host':
        return 'Host';
      case 'venue':
        return 'Venue';
      case 'sponsor':
        return 'Sponsor';
      case 'business':
        return 'Business Partner';
      default:
        return role;
    }
  }

  String _getWouldPartnerAgainText(double rating) {
    if (rating >= 4.5) return 'Definitely yes';
    if (rating >= 3.5) return 'Probably yes';
    if (rating >= 2.5) return 'Maybe';
    if (rating >= 1.5) return 'Probably not';
    return 'Definitely not';
  }
}
