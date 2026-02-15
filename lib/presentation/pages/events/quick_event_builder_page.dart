import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/events/event_template.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/services/events/event_template_service.dart';
import 'package:avrai/core/controllers/event_creation_controller.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/pages/events/event_published_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// OUR_GUTS.md: "The key opens doors to events"
/// Easy Event Hosting - Phase 2: Quick Event Builder
/// Philosophy: 5-7 minutes → 30 seconds (Instagram Stories-like creation)
class QuickEventBuilderPage extends StatefulWidget {
  final UnifiedUser currentUser;
  final EventTemplate? preselectedTemplate;
  final ExpertiseEvent? copyFrom; // For "Host Again" feature
  final bool isBusinessAccount; // For business-only templates

  const QuickEventBuilderPage({
    super.key,
    required this.currentUser,
    this.preselectedTemplate,
    this.copyFrom,
    this.isBusinessAccount = false,
  });

  @override
  State<QuickEventBuilderPage> createState() => _QuickEventBuilderPageState();
}

class _QuickEventBuilderPageState extends State<QuickEventBuilderPage> {
  final _templateService = EventTemplateService();
  late final EventCreationController _eventCreationController;

  int _currentStep = 0;
  EventTemplate? _selectedTemplate;
  DateTime? _selectedDateTime;
  List<Spot> _selectedSpots = [];
  int _maxAttendees = 20;
  double? _price;
  String? _customTitle;
  String? _customDescription;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _eventCreationController = GetIt.instance<EventCreationController>();

    // Pre-select template if provided
    if (widget.preselectedTemplate != null) {
      _selectedTemplate = widget.preselectedTemplate;
      _currentStep = 1; // Skip to date/time selection
    }

    // Pre-fill from existing event (Copy/Host Again)
    if (widget.copyFrom != null) {
      _prefillFromEvent(widget.copyFrom!);
    }
  }

  void _prefillFromEvent(ExpertiseEvent event) {
    // Find matching template
    final templates = _templateService.getAllTemplates();
    _selectedTemplate = templates.firstWhere(
      (t) => t.category == event.category && t.eventType == event.eventType,
      orElse: () => templates.first,
    );

    // Copy spots and settings
    _selectedSpots = event.spots;
    _maxAttendees = event.maxAttendees;
    _price = event.price;
    _customTitle = event.title;
    _customDescription = event.description;

    // Auto-suggest next available time (next weekend)
    _selectedDateTime = _suggestNextWeekend();
  }

  DateTime _suggestNextWeekend() {
    final now = DateTime.now();
    var saturday =
        now.add(Duration(days: (DateTime.saturday - now.weekday) % 7));
    if (saturday.isBefore(now)) {
      saturday = saturday.add(const Duration(days: 7));
    }
    return DateTime(
        saturday.year, saturday.month, saturday.day, 10, 0); // 10 AM Saturday
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Create Event',
      constrainBody: false,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_currentStep > 0)
          TextButton(
            onPressed: _canGoBack && !_isLoading ? _previousStep : null,
            child: Text('Back',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.primaryColor)),
          ),
      ],
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return PortalSurface(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xl,
        vertical: context.spacing.md,
      ),
      color: AppColors.surface,
      radius: 0,
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(
                right: index < 3 ? context.spacing.xs : kSpaceNone,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: ColoredBox(
                  color: isCompleted || isActive
                      ? AppTheme.primaryColor
                      : AppColors.grey300,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildTemplateSelection();
      case 1:
        return _buildDateTimeSelection();
      case 2:
        return _buildSpotSelection();
      case 3:
        return _buildReviewPublish();
      default:
        return const SizedBox();
    }
  }

  // ========================================================================
  // STEP 1: TEMPLATE SELECTION
  // ========================================================================

  Widget _buildTemplateSelection() {
    // Filter templates based on account type
    final templates = widget.isBusinessAccount
        ? _templateService.getBusinessTemplates()
        : _templateService.getExpertTemplates();

    return ListView(
      padding: EdgeInsets.all(context.spacing.xl),
      children: [
        Text(
          'Choose Event Type',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Pick a template to get started quickly',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        SizedBox(height: context.spacing.xl),
        ...templates.map((template) => _buildTemplateCard(template)),
      ],
    );
  }

  Widget _buildTemplateCard(EventTemplate template) {
    final isSelected = _selectedTemplate?.id == template.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = template;
          _maxAttendees = template.defaultMaxAttendees;
          _price = template.suggestedPrice;
        });
      },
      child: PortalSurface(
        margin: EdgeInsets.only(bottom: context.spacing.md),
        padding: EdgeInsets.all(context.spacing.md),
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppColors.surface,
        borderColor: isSelected ? AppTheme.primaryColor : AppColors.grey300,
        radius: context.radius.md,
        child: Row(
          children: [
            CircleAvatar(
              radius: context.radius.xl,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: Text(
                template.icon,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            SizedBox(width: context.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: context.spacing.xxs),
                  Text(
                    '${template.defaultDuration.inHours}h • ${template.recommendedSpotCount} spots • ${template.getPriceDisplay()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (template.tags.isNotEmpty) ...[
                    SizedBox(height: context.spacing.xs),
                    Wrap(
                      spacing: 6,
                      children: template.tags.take(3).map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          side: BorderSide.none,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.2),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: kSpaceXxs,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppTheme.primaryColor, size: 28),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // STEP 2: DATE & TIME SELECTION
  // ========================================================================

  Widget _buildDateTimeSelection() {
    return ListView(
      padding: EdgeInsets.all(context.spacing.xl),
      children: [
        Text(
          'When?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Choose date and time for your event',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        SizedBox(height: context.spacing.xxl),

        // Quick date options
        Text(
          'Quick Options',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.md),
        _buildQuickDateOption('This Weekend', _suggestNextWeekend()),
        _buildQuickDateOption(
            'Next Weekend', _suggestNextWeekend().add(const Duration(days: 7))),

        SizedBox(height: context.spacing.xxl),

        // Custom date picker
        ElevatedButton.icon(
          onPressed: _pickCustomDateTime,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _selectedDateTime == null
                ? 'Choose Custom Date'
                : 'Selected: ${_formatDateTime(_selectedDateTime!)}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            padding: EdgeInsets.all(context.spacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.grey300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDateOption(String label, DateTime dateTime) {
    final isSelected = _selectedDateTime != null &&
        _selectedDateTime!.year == dateTime.year &&
        _selectedDateTime!.month == dateTime.month &&
        _selectedDateTime!.day == dateTime.day;

    return GestureDetector(
      onTap: () => setState(() => _selectedDateTime = dateTime),
      child: PortalSurface(
        margin: EdgeInsets.only(bottom: context.spacing.sm),
        padding: EdgeInsets.all(context.spacing.lg),
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppColors.surface,
        borderColor: isSelected ? AppTheme.primaryColor : AppColors.grey300,
        radius: context.radius.md,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    _formatDateTime(dateTime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );
      if (!mounted) return;

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final weekday =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month ${dt.day} at $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  // ========================================================================
  // STEP 3: SPOT SELECTION (Simplified for now)
  // ========================================================================

  Widget _buildSpotSelection() {
    return ListView(
      padding: EdgeInsets.all(context.spacing.xl),
      children: [
        Text(
          'Choose Spots',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Select ${_selectedTemplate?.recommendedSpotCount ?? 3} spots for your event',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        SizedBox(height: context.spacing.xxl),

        // Placeholder for spot selection
        // In full implementation, this would show user's spots in category
        Center(
          child: Column(
            children: [
              Icon(Icons.location_on,
                  size: 64,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5)),
              SizedBox(height: context.spacing.md),
              Text(
                'Spot selection UI coming soon',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                'For now, spots will be selected automatically',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // STEP 4: REVIEW & PUBLISH
  // ========================================================================

  Widget _buildReviewPublish() {
    if (_selectedTemplate == null || _selectedDateTime == null) {
      return const Center(child: Text('Missing information'));
    }

    final event = _templateService.createEventFromTemplate(
      template: _selectedTemplate!,
      host: widget.currentUser,
      startTime: _selectedDateTime!,
      selectedSpots: _selectedSpots,
      customTitle: _customTitle,
      customDescription: _customDescription,
      customMaxAttendees: _maxAttendees,
      customPrice: _price,
    );

    return ListView(
      padding: EdgeInsets.all(context.spacing.xl),
      children: [
        Text(
          'Review & Publish',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Everything look good?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        SizedBox(height: context.spacing.xxl),

        // Event preview card
        PortalSurface(
          padding: EdgeInsets.all(context.spacing.lg),
          color: AppColors.surface,
          borderColor: AppColors.grey300,
          radius: context.radius.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _selectedTemplate!.icon,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.md),
              _buildInfoRow(
                  Icons.calendar_today, _formatDateTime(event.startTime)),
              _buildInfoRow(Icons.schedule,
                  '${_selectedTemplate!.defaultDuration.inHours} hours'),
              _buildInfoRow(
                  Icons.people, 'Max ${event.maxAttendees} attendees'),
              if (event.price != null)
                _buildInfoRow(
                    Icons.attach_money, '\$${event.price!.toStringAsFixed(0)}'),
              SizedBox(height: context.spacing.md),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          SizedBox(width: context.spacing.sm),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // NAVIGATION
  // ========================================================================

  Widget _buildNavigationBar() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.xl),
      color: AppColors.surface,
      radius: 0,
      elevation: 0.35,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              PortalSurface(
                margin: EdgeInsets.only(bottom: context.spacing.sm),
                padding: EdgeInsets.all(context.spacing.sm),
                color: AppColors.error.withValues(alpha: 0.1),
                borderColor: AppColors.error.withValues(alpha: 0.3),
                radius: context.radius.sm,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    SizedBox(width: context.spacing.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed && !_isLoading ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: context.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 3 ? 'Publish Event' : 'Continue',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedTemplate != null;
      case 1:
        return _selectedDateTime != null;
      case 2:
        return true; // Spots optional for now
      case 3:
        return true;
      default:
        return false;
    }
  }

  bool get _canGoBack => _currentStep > 0;

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _publishEvent();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _publishEvent() async {
    if (_selectedTemplate == null || _selectedDateTime == null) {
      setState(() {
        _error = 'Please complete all required steps';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create event from template
      final templateEvent = _templateService.createEventFromTemplate(
        template: _selectedTemplate!,
        host: widget.currentUser,
        startTime: _selectedDateTime!,
        selectedSpots: _selectedSpots,
        customTitle: _customTitle,
        customDescription: _customDescription,
        customMaxAttendees: _maxAttendees,
        customPrice: _price,
      );

      // Use EventCreationController for event creation
      final formData = EventFormData(
        title: templateEvent.title,
        description: templateEvent.description,
        category: templateEvent.category,
        eventType: templateEvent.eventType,
        startTime: templateEvent.startTime,
        endTime: templateEvent.endTime,
        spots: templateEvent.spots,
        location: templateEvent.location,
        latitude: templateEvent.latitude,
        longitude: templateEvent.longitude,
        maxAttendees: templateEvent.maxAttendees,
        price: templateEvent.price,
        isPublic: templateEvent.isPublic,
      );

      final result = await _eventCreationController.createEvent(
        formData: formData,
        host: widget.currentUser,
      );

      setState(() {
        _isLoading = false;
      });

      if (!result.isSuccess) {
        setState(() {
          _error = result.error ?? 'Failed to publish event';
        });

        if (mounted) {
          context.showError(_error!);
        }
        return;
      }

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
}
