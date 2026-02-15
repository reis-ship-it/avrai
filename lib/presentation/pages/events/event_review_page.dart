import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/payment/sales_tax_service.dart';
import 'package:avrai/core/controllers/event_creation_controller.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/events/event_published_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Event Review Page
/// Agent 2: Event Discovery & Hosting UI (Week 3, Task 2.11)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Display all event details for review
/// - Allow editing before publishing
/// - Show expertise requirements
/// - Publish confirmation
class EventReviewPage extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final ExpertiseEventType eventType;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final int maxAttendees;
  final double? price;
  final bool isPublic;

  const EventReviewPage({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.eventType,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.maxAttendees,
    required this.price,
    required this.isPublic,
  });

  @override
  State<EventReviewPage> createState() => _EventReviewPageState();
}

class _EventReviewPageState extends State<EventReviewPage> {
  final _salesTaxService = GetIt.instance<SalesTaxService>();
  final _eventCreationController = GetIt.instance<EventCreationController>();
  bool _isLoading = false;
  String? _error;
  UnifiedUser? _currentUser;
  bool _isLoadingTax = false;
  double _salesTax = 0.0;
  double _taxRate = 0.0;
  bool _isTaxExempt = false;
  String? _exemptionReason;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _calculateSalesTax();
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final user = authState.user;
    _currentUser = UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
    );
  }

  Future<void> _calculateSalesTax() async {
    if (widget.price == null || widget.price == 0.0) {
      setState(() {
        _salesTax = 0.0;
        _taxRate = 0.0;
        _isTaxExempt = false;
        _exemptionReason = null;
      });
      return;
    }

    setState(() {
      _isLoadingTax = true;
    });

    try {
      final calculation = await _salesTaxService.calculateSalesTaxFromDetails(
        ticketPrice: widget.price!,
        eventType: widget.eventType,
        location: widget.location,
      );

      setState(() {
        _salesTax = calculation.taxAmount;
        _taxRate = calculation.taxRate;
        _isTaxExempt = calculation.isTaxExempt;
        _exemptionReason = calculation.exemptionReason;
        _isLoadingTax = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTax = false;
        // Don't show error, just proceed without tax
        _salesTax = 0.0;
        _taxRate = 0.0;
      });
    }
  }

  Future<void> _publishEvent() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          'Publish Event?',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to publish "${widget.title}"? The event will be visible to others.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true || _currentUser == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Extract locality from location string (format: "Locality, City, State" or "Locality, City")
      final locality = widget.location.contains(',')
          ? widget.location.split(',').first.trim()
          : widget.location.trim();

      // Use EventCreationController for event creation
      final formData = EventFormData(
        title: widget.title,
        description: widget.description,
        category: widget.category,
        eventType: widget.eventType,
        startTime: widget.startTime,
        endTime: widget.endTime,
        location: widget.location,
        locality: locality,
        maxAttendees: widget.maxAttendees,
        price: widget.price,
        isPublic: widget.isPublic,
      );

      final result = await _eventCreationController.createEvent(
        formData: formData,
        host: _currentUser!,
      );

      setState(() {
        _isLoading = false;
      });

      if (!result.isSuccess) {
        // Handle controller validation errors
        final errorMessage = result.error ?? 'Failed to create event';
        setState(() {
          _error = errorMessage;
        });

        if (mounted) {
          context.showError(errorMessage);
        }
        return;
      }

      // Event created successfully
      if (mounted && result.event != null) {
        // Navigate to success page
        AppNavigator.replaceBuilder(
          context,
          builder: (context) => EventPublishedPage(event: result.event!),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to publish event: $e';
        _isLoading = false;
      });

      if (mounted) {
        context.showError('Error: $e');
      }
    }
  }

  String _getEventTypeDisplayName(ExpertiseEventType type) {
    switch (type) {
      case ExpertiseEventType.tour:
        return 'Expert Tour';
      case ExpertiseEventType.workshop:
        return 'Workshop';
      case ExpertiseEventType.tasting:
        return 'Tasting';
      case ExpertiseEventType.meetup:
        return 'Meetup';
      case ExpertiseEventType.walk:
        return 'Curated Walk';
      case ExpertiseEventType.lecture:
        return 'Lecture';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final expertiseLevel = _currentUser?.getExpertiseLevel(widget.category);

    return AdaptivePlatformPageScaffold(
      title: 'Review Event',
      constrainBody: false,
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(context.spacing.lg),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Your Event',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: context.spacing.xs),
                  Text(
                    'Please review all details before publishing',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // Event Details
            Padding(
              padding: EdgeInsets.all(context.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildReviewRow('Title', widget.title),
                  SizedBox(height: context.spacing.md),

                  // Description
                  _buildReviewRow('Description', widget.description),
                  SizedBox(height: context.spacing.md),

                  // Category & Type
                  Row(
                    children: [
                      Expanded(
                        child: _buildReviewRow('Category', widget.category),
                      ),
                      SizedBox(width: context.spacing.md),
                      Expanded(
                        child: _buildReviewRow(
                            'Type', _getEventTypeDisplayName(widget.eventType)),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.md),

                  // Date & Time
                  _buildReviewRow(
                    'Date & Time',
                    '${_formatDateTime(widget.startTime)} - ${_formatTime(widget.endTime)}\nDuration: ${_formatDuration(widget.startTime, widget.endTime)}',
                  ),
                  SizedBox(height: context.spacing.md),

                  // Location
                  _buildReviewRow('Location', widget.location),
                  SizedBox(height: context.spacing.md),

                  // Max Attendees
                  _buildReviewRow(
                      'Max Attendees', widget.maxAttendees.toString()),
                  SizedBox(height: context.spacing.md),

                  // Price
                  _buildReviewRow(
                    'Price',
                    widget.price != null && widget.price! > 0
                        ? '\$${widget.price!.toStringAsFixed(2)}'
                        : 'Free',
                  ),
                  SizedBox(height: context.spacing.md),

                  // Sales Tax (if price is set)
                  if (widget.price != null && widget.price! > 0) ...[
                    if (_isLoadingTax)
                      _buildReviewRow('Sales Tax', 'Calculating...')
                    else if (_isTaxExempt)
                      _buildReviewRow(
                        'Sales Tax',
                        'Tax-Exempt\n${_exemptionReason ?? "Event type is tax-exempt"}',
                      )
                    else
                      _buildReviewRow(
                        'Sales Tax',
                        '${_taxRate.toStringAsFixed(2)}% (\$${_salesTax.toStringAsFixed(2)})',
                      ),
                    SizedBox(height: context.spacing.md),
                    // Total with Tax
                    PortalSurface(
                      padding: EdgeInsets.all(context.spacing.sm),
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                      radius: context.radius.sm,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Price',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '\$${((widget.price ?? 0.0) + _salesTax).toStringAsFixed(2)}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.spacing.md),
                  ],

                  // Public/Private
                  _buildReviewRow(
                      'Visibility', widget.isPublic ? 'Public' : 'Private'),
                  SizedBox(height: context.spacing.xl),

                  // Expertise Requirements
                  PortalSurface(
                    padding: EdgeInsets.all(context.spacing.sm),
                    color: AppColors.electricGreen.withValues(alpha: 0.1),
                    borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
                    radius: context.radius.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified,
                                color: AppColors.electricGreen, size: 20),
                            SizedBox(width: context.spacing.xs),
                            Text(
                              'Expertise Verified',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricGreen,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          expertiseLevel != null
                              ? 'You have ${expertiseLevel.displayName} level expertise in ${widget.category} (Required: Local level+)'
                              : 'Expertise level will be verified before publishing',
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Error Display
            if (_error != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: PortalSurface(
                  padding: EdgeInsets.all(context.spacing.sm),
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderColor: AppColors.error.withValues(alpha: 0.3),
                  radius: context.radius.sm,
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      SizedBox(width: context.spacing.xs),
                      Expanded(
                        child: Text(
                          _error!,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(context.spacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _publishEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: context.spacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(context.radius.md),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.white)
                          : Text(
                              'Publish Event',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: context.spacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding:
                            EdgeInsets.symmetric(vertical: context.spacing.md),
                        side: const BorderSide(color: AppColors.grey300),
                      ),
                      child: const Text('Edit Details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.spacing.xxs),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
