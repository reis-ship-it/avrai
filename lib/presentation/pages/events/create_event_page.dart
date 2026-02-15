import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/events/event_review_page.dart';
import 'package:avrai/presentation/widgets/events/locality_selection_widget.dart';
import 'package:avrai/presentation/widgets/events/geographic_scope_indicator_widget.dart';
import 'package:avrai/core/services/geographic/geographic_scope_service.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Event Creation Form Page
/// Agent 2: Event Discovery & Hosting UI (Week 3, Task 2.8)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Simple event creation form
/// - Form validation
/// - Expertise verification (Local level+ required)
/// - Integration with ExpertiseEventService
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = ExpertiseEventService();
  final _geographicScopeService = GeographicScopeService();

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  ExpertiseEventType? _selectedEventType;
  DateTime? _startTime;
  DateTime? _endTime;
  final _locationController = TextEditingController();
  String? _selectedLocality; // Geographic scope: locality selection
  int _maxAttendees = 20;
  double? _price;
  bool _isPublic = true;

  // State
  bool _isLoading = false;
  String? _error;
  String? _expertiseError;
  String? _geographicScopeError; // Geographic scope validation error
  UnifiedUser? _currentUser;
  Map<String, ExpertiseLevel>? _userExpertise;

  // Available categories (from user's expertise)
  List<String> _availableCategories = [];

  // Event types
  final List<ExpertiseEventType> _eventTypes = ExpertiseEventType.values;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please sign in to create events';
      });
      return;
    }

    final user = authState.user;

    // Convert User to UnifiedUser
    _currentUser = UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
    );

    // Check if user can host events
    if (!_currentUser!.canHostEvents()) {
      setState(() {
        _expertiseError =
            'You need Local level or higher expertise to host events.\nBuild your expertise first!';
      });
      return;
    }

    // Get user's expertise categories
    setState(() {
      _availableCategories = _currentUser!.getExpertiseCategories();

      // Build expertise map
      _userExpertise = {};
      for (final category in _availableCategories) {
        final level = _currentUser!.getExpertiseLevel(category);
        if (level != null && level.index >= ExpertiseLevel.local.index) {
          _userExpertise![category] = level;
        }
      }

      // Filter categories to only those with Local level+
      _availableCategories = _userExpertise!.keys.toList();

      // Pre-select first category if available
      if (_availableCategories.isNotEmpty) {
        _selectedCategory = _availableCategories.first;
      }
    });
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _startTime ?? DateTime.now().add(const Duration(hours: 1))),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryColor,
                onPrimary: AppColors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (!mounted) return;

      if (time != null) {
        setState(() {
          _startTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );

          // Auto-set end time to 2 hours after start if not set
          if (_endTime == null || _endTime!.isBefore(_startTime!)) {
            _endTime = _startTime!.add(const Duration(hours: 2));
          }
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    if (_startTime == null) {
      if (!mounted) return;
      context.showWarning('Please select start time first');
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime!.add(const Duration(hours: 2)),
      firstDate: _startTime!,
      lastDate: _startTime!.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _endTime ?? _startTime!.add(const Duration(hours: 2))),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryColor,
                onPrimary: AppColors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (!mounted) return;

      if (time != null) {
        final selectedEnd = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        if (selectedEnd.isBefore(_startTime!)) {
          if (!mounted) return;
          context.showError('End time must be after start time');
          return;
        }

        setState(() {
          _endTime = selectedEnd;
        });
      }
    }
  }

  /// Create event directly (bypassing review page)
  ///
  /// Note: Currently unused - event creation happens in EventReviewPage.
  /// Kept for potential future use (e.g., quick create without review).
  // ignore: unused_element
  Future<void> _createEvent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final event = await _eventService.createEvent(
        host: _currentUser!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        eventType: _selectedEventType!,
        startTime: _startTime!,
        endTime: _endTime!,
        location: _locationController.text.trim(),
        maxAttendees: _maxAttendees,
        price: _price,
        isPublic: _isPublic,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Show success and navigate back
        FeedbackPresenter.showSnack(
          context,
          message: 'Event "${event.title}" created successfully!',
          kind: FeedbackKind.success,
        );

        // Navigate back
        Navigator.pop(context, event);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create event: $e';
        _isLoading = false;
      });

      if (mounted) {
        context.showError('Error: $e');
      }
    }
  }

  /// Validate geographic scope using GeographicScopeService
  bool _validateGeographicScope() {
    if (_currentUser == null || _selectedCategory == null) {
      return false;
    }

    // If no locality selected, check if it's required
    if (_selectedLocality == null || _selectedLocality!.isEmpty) {
      setState(() {
        _geographicScopeError = 'Please select a locality for your event.';
      });
      return false;
    }

    try {
      // Use GeographicScopeService to validate
      _geographicScopeService.validateEventLocation(
        userId: _currentUser!.id,
        user: _currentUser!,
        category: _selectedCategory!,
        eventLocality: _selectedLocality!,
      );

      setState(() {
        _geographicScopeError = null;
      });
      return true;
    } catch (e) {
      setState(() {
        _geographicScopeError = e.toString().replaceFirst('Exception: ', '');
      });
      return false;
    }
  }

  void _validateAndProceed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check expertise
    if (_selectedCategory == null ||
        !_currentUser!.hasExpertiseIn(_selectedCategory!)) {
      setState(() {
        _expertiseError =
            'You must have expertise in the selected category to host events.';
      });
      context.showError('Please select a category you have expertise in');
      return;
    }

    // Check expertise level
    final expertiseLevel = _currentUser!.getExpertiseLevel(_selectedCategory!);
    if (expertiseLevel == null ||
        expertiseLevel.index < ExpertiseLevel.local.index) {
      setState(() {
        _expertiseError =
            'You need Local level or higher expertise in $_selectedCategory to host events.';
      });
      context.showError(
        'You need Local level+ expertise in $_selectedCategory to host events',
      );
      return;
    }

    // Validate geographic scope
    if (!_validateGeographicScope()) {
      context.showError(
        _geographicScopeError ?? 'Geographic scope validation failed',
      );
      return;
    }

    // Validate dates
    if (_startTime == null || _endTime == null) {
      context.showError('Please select start and end times');
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      context.showError('End time must be after start time');
      return;
    }

    // Navigate to review page
    AppNavigator.pushBuilder(
      context,
      builder: (context) => EventReviewPage(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        eventType: _selectedEventType!,
        startTime: _startTime!,
        endTime: _endTime!,
        location: _locationController.text.trim(),
        maxAttendees: _maxAttendees,
        price: _price,
        isPublic: _isPublic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_expertiseError != null) {
      return AdaptivePlatformPageScaffold(
        title: 'Create Event',
        constrainBody: false,
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(context.spacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: context.spacing.md),
                Text(
                  'Event Hosting Unlocked',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: context.spacing.md),
                Text(
                  _expertiseError!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AdaptivePlatformPageScaffold(
      title: 'Create Event',
      constrainBody: false,
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expertise Check Display
              if (_selectedCategory != null && _userExpertise != null) ...[
                PortalSurface(
                  padding: EdgeInsets.all(context.spacing.sm),
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
                  radius: context.radius.sm,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.electricGreen, size: 20),
                      SizedBox(width: context.spacing.xs),
                      Expanded(
                        child: Text(
                          'Expertise: ${_userExpertise![_selectedCategory!]?.displayName ?? "Unknown"} level in $_selectedCategory',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.spacing.lg),
              ],

              // Event Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'Enter event title',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Event title is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: context.spacing.md),

              // Event Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your event',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: context.spacing.md),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
                items: _availableCategories.map((category) {
                  final level = _userExpertise![category];
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(category),
                        if (level != null) ...[
                          SizedBox(width: context.spacing.xs),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide.none,
                            backgroundColor:
                                AppColors.electricGreen.withValues(alpha: 0.1),
                            label: Text(
                              level.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.electricGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _expertiseError = null;
                    _geographicScopeError = null;
                    _selectedLocality = null;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: context.spacing.md),

              // Geographic Scope Indicator
              if (_selectedCategory != null && _currentUser != null) ...[
                GeographicScopeIndicatorWidget(
                  user: _currentUser!,
                  category: _selectedCategory!,
                ),
                SizedBox(height: context.spacing.md),
              ],

              // Locality Selection
              if (_selectedCategory != null && _currentUser != null) ...[
                LocalitySelectionWidget(
                  user: _currentUser!,
                  category: _selectedCategory!,
                  selectedLocality: _selectedLocality,
                  errorMessage: _geographicScopeError,
                  onLocalitySelected: (locality) {
                    setState(() {
                      _selectedLocality = locality;
                      _geographicScopeError = null;
                    });
                  },
                ),
                SizedBox(height: context.spacing.md),
              ],

              // Event Type Dropdown
              DropdownButtonFormField<ExpertiseEventType>(
                initialValue: _selectedEventType,
                decoration: InputDecoration(
                  labelText: 'Event Type *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getEventTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Event type is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: context.spacing.md),

              // Start Date/Time
              InkWell(
                onTap: _selectStartTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Start Date & Time *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startTime != null
                        ? '${_formatDate(_startTime!)} at ${_formatTime(_startTime!)}'
                        : 'Select start time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _startTime != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                  ),
                ),
              ),
              SizedBox(height: context.spacing.md),

              // End Date/Time
              InkWell(
                onTap: _selectEndTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date & Time *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _endTime != null
                        ? '${_formatDate(_endTime!)} at ${_formatTime(_endTime!)}'
                        : 'Select end time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _endTime != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                  ),
                ),
              ),
              SizedBox(height: context.spacing.md),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location *',
                  hintText: 'Enter event location',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  suffixIcon: const Icon(Icons.location_on),
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: context.spacing.md),

              // Max Attendees
              TextFormField(
                initialValue: _maxAttendees.toString(),
                decoration: InputDecoration(
                  labelText: 'Max Attendees',
                  hintText: 'Enter max attendees',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed > 0) {
                    _maxAttendees = parsed;
                  }
                },
              ),
              SizedBox(height: context.spacing.md),

              // Price (Optional - if set, event is paid)
              TextFormField(
                initialValue: _price?.toStringAsFixed(2),
                decoration: InputDecoration(
                  labelText: 'Price (Optional)',
                  hintText: 'Leave empty for free event',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  prefixText: '\$ ',
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null && parsed >= 0) {
                    setState(() {
                      _price = parsed > 0 ? parsed : null;
                    });
                  } else {
                    setState(() {
                      _price = null;
                    });
                  }
                },
              ),
              SizedBox(height: context.spacing.md),

              // Public/Private Toggle
              SwitchListTile(
                title: Text('Public Event'),
                subtitle: Text('Anyone can discover this event'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                activeThumbColor: AppTheme.primaryColor,
              ),

              if (_error != null) ...[
                SizedBox(height: context.spacing.md),
                PortalSurface(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.error,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: context.spacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: context.spacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : Text(
                          'Review & Publish',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}
