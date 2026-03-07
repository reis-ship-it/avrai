import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/payment/sales_tax_service.dart';
import 'package:avrai_runtime_os/controllers/event_creation_controller.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/source_intake_orchestrator.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/events/event_published_page.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';

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
  final bool wantsExternalSync;
  final String? sourceUrl;
  final String? sourceLabel;
  final ExternalConnectionMode connectionMode;

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
    this.wantsExternalSync = false,
    this.sourceUrl,
    this.sourceLabel,
    this.connectionMode = ExternalConnectionMode.url,
  });

  @override
  State<EventReviewPage> createState() => _EventReviewPageState();
}

class _EventReviewPageState extends State<EventReviewPage> {
  final _salesTaxService = GetIt.instance<SalesTaxService>();
  final _eventCreationController = GetIt.instance<EventCreationController>();
  final _intakeOrchestrator = GetIt.instance<SourceIntakeOrchestrator>();
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
        title: const Text(
          'Publish Event?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to publish "${widget.title}"? The event will be visible to others.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Event created successfully
      if (mounted && result.event != null) {
        if (widget.wantsExternalSync &&
            ((widget.sourceUrl ?? '').isNotEmpty ||
                (widget.sourceLabel ?? '').isNotEmpty)) {
          final source = ExternalSourceDescriptor(
            id: 'source-${DateTime.now().microsecondsSinceEpoch}',
            ownerUserId: _currentUser!.id,
            sourceProvider: (widget.sourceLabel ?? 'external').trim().isEmpty
                ? 'external'
                : (widget.sourceLabel ?? 'external').trim(),
            sourceUrl: widget.sourceUrl,
            connectionMode: widget.connectionMode,
            entityHint: IntakeEntityType.event,
            sourceLabel: widget.sourceLabel,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            cityCode: result.event!.cityCode,
            localityCode: result.event!.localityCode,
            syncState: ExternalSyncState.pending,
          );
          final reviewItem =
              await _intakeOrchestrator.registerSourceForExistingEntity(
            source: source,
            entityType: IntakeEntityType.event,
            entityId: result.event!.id,
            rawPayload: <String, dynamic>{
              'title': widget.title,
              'description': widget.description,
              'category': widget.category,
              'location': widget.location,
              'startTime': widget.startTime.toIso8601String(),
              'endTime': widget.endTime.toIso8601String(),
              'organizerName': _currentUser!.displayName ?? _currentUser!.email,
              'sourceUrl': widget.sourceUrl,
            },
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  reviewItem == null
                      ? 'Source sync connected. AVRAI will read updates in one direction.'
                      : 'Source saved. AVRAI needs a quick review before trusting updates automatically.',
                ),
                backgroundColor: reviewItem == null
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
              ),
            );
          }
        }

        if (!mounted) {
          return;
        }

        // Navigate to success page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EventPublishedPage(event: result.event!),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to publish event: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
    final expertiseLevel = _currentUser?.getExpertiseLevel(widget.category);

    return AppFlowScaffold(
      title: 'Review Event',
      constrainBody: false,
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.surface,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Your Event',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please review all details before publishing',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Event Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildReviewRow('Title', widget.title),
                  const SizedBox(height: 16),

                  // Description
                  _buildReviewRow('Description', widget.description),
                  const SizedBox(height: 16),

                  // Category & Type
                  Row(
                    children: [
                      Expanded(
                        child: _buildReviewRow('Category', widget.category),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildReviewRow(
                            'Type', _getEventTypeDisplayName(widget.eventType)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date & Time
                  _buildReviewRow(
                    'Date & Time',
                    '${_formatDateTime(widget.startTime)} - ${_formatTime(widget.endTime)}\nDuration: ${_formatDuration(widget.startTime, widget.endTime)}',
                  ),
                  const SizedBox(height: 16),

                  // Location
                  _buildReviewRow('Location', widget.location),
                  const SizedBox(height: 16),

                  // Max Attendees
                  _buildReviewRow(
                      'Max Attendees', widget.maxAttendees.toString()),
                  const SizedBox(height: 16),

                  // Price
                  _buildReviewRow(
                    'Price',
                    widget.price != null && widget.price! > 0
                        ? '\$${widget.price!.toStringAsFixed(2)}'
                        : 'Free',
                  ),
                  const SizedBox(height: 16),

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
                    const SizedBox(height: 16),
                    // Total with Tax
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '\$${((widget.price ?? 0.0) + _salesTax).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Public/Private
                  _buildReviewRow(
                      'Visibility', widget.isPublic ? 'Public' : 'Private'),
                  if (widget.wantsExternalSync) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.sync_alt,
                                color: AppTheme.primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'External Sync',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AVRAI will read updates from ${widget.sourceLabel ?? widget.sourceUrl ?? "your source"} in one direction only. It will never publish changes back out.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if ((widget.sourceUrl ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.sourceUrl!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Expertise Requirements
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.electricGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified,
                                color: AppColors.electricGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Expertise Verified',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          expertiseLevel != null
                              ? 'You have ${expertiseLevel.displayName} level expertise in ${widget.category} (Required: Local level+)'
                              : 'Expertise level will be verified before publishing',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _publishEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.white)
                          : const Text(
                              'Publish Event',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
