import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/controllers/event_attendance_controller.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/payment/checkout_page.dart';
import 'package:avrai/presentation/pages/partnerships/partnership_proposal_page.dart';
import 'package:avrai/presentation/pages/partnerships/partnership_management_page.dart';
import 'package:avrai/presentation/pages/events/cancellation_flow_page.dart';
import 'package:avrai/presentation/pages/events/event_success_dashboard.dart';
import 'package:avrai/presentation/pages/disputes/dispute_submission_page.dart';
import 'package:avrai/presentation/widgets/events/safety_checklist_widget.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/services/fraud/fraud_detection_service.dart';
import 'package:avrai/presentation/widgets/common/page_transitions.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Event Details Page
/// Agent 2: Event Discovery & Hosting UI (Phase 1, Section 1)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Full event information display
/// - Registration button (free events)
/// - Purchase button (paid events)
/// - Share event
/// - Add to calendar
/// - Host information with expertise pins
class EventDetailsPage extends StatefulWidget {
  final ExpertiseEvent event;

  const EventDetailsPage({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final ExpertiseEventService _eventService = ExpertiseEventService();
  final EventAttendanceController _attendanceController =
      GetIt.instance<EventAttendanceController>();
  final PartnershipService _partnershipService =
      GetIt.instance<PartnershipService>();
  final FraudDetectionService _fraudService = FraudDetectionService(
    eventService: ExpertiseEventService(),
  );
  bool _isLoading = false;
  bool _isRegistered = false;
  String? _error;
  ExpertiseEvent? _currentEvent;
  bool _hasPartnerships = false;
  bool _hasFraudFlag = false;
  // ignore: unused_field
  double? _fraudRiskScore;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _checkRegistrationStatus();
    _checkPartnerships();
    _checkFraudStatus();
  }

  Future<void> _checkFraudStatus() async {
    try {
      final fraudScore = await _fraudService.getFraudScore(_currentEvent!.id);
      if (fraudScore != null &&
          (fraudScore.isHighRisk || fraudScore.requiresReview)) {
        setState(() {
          _hasFraudFlag = true;
          _fraudRiskScore = fraudScore.riskScore;
        });
      }
    } catch (e) {
      // Ignore errors - fraud check is optional
    }
  }

  Future<void> _checkPartnerships() async {
    try {
      final partnerships =
          await _partnershipService.getPartnershipsForEvent(_currentEvent!.id);
      setState(() {
        _hasPartnerships = partnerships.isNotEmpty;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  void _checkRegistrationStatus() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.id;
      setState(() {
        _isRegistered = _currentEvent?.attendeeIds.contains(userId) ?? false;
      });
    }
  }

  Future<void> _registerForEvent() async {
    if (_currentEvent == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        setState(() {
          _error = 'Please sign in to register for events';
          _isLoading = false;
        });
        return;
      }

      final user = authState.user;

      // Convert User to UnifiedUser (minimal conversion for now)
      final unifiedUser = UnifiedUser(
        id: user.id,
        email: user.email,
        displayName: user.displayName ?? user.name,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        isOnline: user.isOnline ?? false,
      );

      // Register via EventAttendanceController (handles validation, availability, preferences, etc.)
      final result = await _attendanceController.registerForEvent(
        event: _currentEvent!,
        attendee: unifiedUser,
        quantity: 1,
      );

      if (!result.success) {
        throw Exception(result.error ?? 'Registration failed');
      }

      // Update with result event (has updated attendee count)
      setState(() {
        _currentEvent = result.event ?? _currentEvent;
        _isRegistered = true;
        _isLoading = false;
      });

      if (mounted) {
        context.showSuccess('Successfully registered for event!');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to register: $e';
        _isLoading = false;
      });

      if (mounted) {
        context.showError('Error: $e');
      }
    }
  }

  Future<void> _cancelRegistration() async {
    if (_currentEvent == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      final user = authState.user;

      final unifiedUser = UnifiedUser(
        id: user.id,
        email: user.email,
        displayName: user.displayName ?? user.name,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        isOnline: user.isOnline ?? false,
      );

      await _eventService.cancelRegistration(_currentEvent!, unifiedUser);

      final updatedEvent = _currentEvent!.copyWith(
        attendeeIds:
            _currentEvent!.attendeeIds.where((id) => id != user.id).toList(),
        attendeeCount: _currentEvent!.attendeeCount - 1,
      );

      setState(() {
        _currentEvent = updatedEvent;
        _isRegistered = false;
        _isLoading = false;
      });

      if (mounted) {
        context.showInfo('Registration cancelled');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to cancel registration: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    // Reload event data after cancellation
    try {
      final updatedEvent = await _eventService
          .getEventById(_currentEvent?.id ?? widget.event.id);
      if (updatedEvent != null) {
        setState(() {
          _currentEvent = updatedEvent;
        });
        _checkRegistrationStatus();
      }
    } catch (e) {
      // Ignore errors
    }
  }

  void _handlePurchaseTicket() {
    if (_currentEvent == null) return;

    // Navigate to checkout page with smooth transition
    Navigator.push(
      context,
      PageTransitions.slideFromRight(
        CheckoutPage(event: _currentEvent!),
      ),
    );
  }

  void _shareEvent() {
    if (_currentEvent == null) return;

    final event = _currentEvent!;
    final shareText = '''🎉 ${event.title}

${event.description}

📅 ${_formatDateTime(event.startTime)}
📍 ${event.location ?? 'Location TBD'}
${event.isPaid ? '💰 \$${event.price}' : '🎫 Free'}
👥 ${event.attendeeCount}/${event.maxAttendees} attendees

Hosted by ${event.host.displayName ?? event.host.email}

${event.getEventTypeDisplayName()} - ${event.category}

Join me on avrai!
SPOTS - know you belong.''';

    SharePlus.instance.share(ShareParams(
      text: shareText,
      subject: 'Check out this event: ${event.title}',
    ));
  }

  Future<void> _addToCalendar() async {
    if (_currentEvent == null) return;

    final event = _currentEvent!;
    final startTime = event.startTime;
    final endTime = event.endTime;

    // Format: YYYYMMDDTHHmmssZ
    final startStr = _formatCalendarDate(startTime);
    final endStr = _formatCalendarDate(endTime);

    final title = Uri.encodeComponent(event.title);
    final description = Uri.encodeComponent(event.description);
    final location = Uri.encodeComponent(event.location ?? '');

    // Create Google Calendar URL
    final url = 'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=$title'
        '&dates=$startStr/$endStr'
        '&details=$description'
        '&location=$location';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        context.showError('Could not open calendar');
      }
    }
  }

  String _formatCalendarDate(DateTime dateTime) {
    return '${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}T'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}00Z';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays} days at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
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
    final event = _currentEvent ?? widget.event;
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : null;
    final canRegister = userId != null && event.canUserAttend(userId);

    return AdaptivePlatformPageScaffold(
      title: 'Event Details',
      constrainBody: false,
      backgroundColor: AppColors.background,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareEvent,
          tooltip: 'Share event',
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Event Type Icon and Title
            PortalSurface(
              padding: EdgeInsets.all(context.spacing.lg),
              color: AppColors.surface,
              radius: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: context.radius.xl,
                        backgroundColor:
                            AppColors.electricGreen.withValues(alpha: 0.1),
                        child: Text(
                          event.getEventTypeEmoji(),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      SizedBox(width: context.spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            SizedBox(height: context.spacing.xxs),
                            Text(
                              event.getEventTypeDisplayName(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      _buildStatusBadge(event),
                    ],
                  ),
                  // Fraud Warning (if flagged)
                  if (_hasFraudFlag) ...[
                    SizedBox(height: context.spacing.sm),
                    PortalSurface(
                      padding: EdgeInsets.all(context.spacing.sm),
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderColor: AppTheme.warningColor.withValues(alpha: 0.3),
                      radius: context.radius.sm,
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                              color: AppTheme.warningColor, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This event has been flagged for review. Please exercise caution.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Event Details
            Padding(
              padding: EdgeInsets.all(context.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: context.spacing.xs),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                  ),
                  SizedBox(height: context.spacing.xl),

                  // Date & Time
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Date & Time',
                    value: '${_formatDateTime(event.startTime)}\n'
                        'Duration: ${_formatDuration(event.startTime, event.endTime)}',
                  ),
                  SizedBox(height: context.spacing.md),

                  // Location
                  if (event.location != null)
                    _buildDetailRow(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: event.location!,
                    ),
                  if (event.location != null)
                    SizedBox(height: context.spacing.md),

                  // Price
                  _buildDetailRow(
                    icon: Icons.attach_money,
                    label: 'Price',
                    value: event.isPaid
                        ? '\$${event.price?.toStringAsFixed(2) ?? '0.00'}'
                        : 'Free',
                  ),
                  SizedBox(height: context.spacing.md),

                  // Attendees
                  _buildDetailRow(
                    icon: Icons.people,
                    label: 'Attendees',
                    value: '${event.attendeeCount}/${event.maxAttendees}',
                  ),
                  SizedBox(height: context.spacing.md),

                  // Category
                  _buildDetailRow(
                    icon: Icons.category,
                    label: 'Category',
                    value: event.category,
                  ),
                  SizedBox(height: context.spacing.xl),

                  // Host Information
                  Text(
                    'Host',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: context.spacing.sm),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: context.radius.xl,
                        backgroundColor: AppColors.grey200,
                        child: event.host.photoUrl != null
                            ? Image.network(event.host.photoUrl!)
                            : Text(
                                (event.host.displayName ?? event.host.email)[0]
                                    .toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                      ),
                      SizedBox(width: context.spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.host.displayName ?? event.host.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            if (event.host.expertiseMap
                                .containsKey(event.category)) ...[
                              SizedBox(height: context.spacing.xxs),
                              Text(
                                '${event.category} Expert',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Spots (if event includes spots)
                  if (event.spots.isNotEmpty) ...[
                    SizedBox(height: context.spacing.xl),
                    Text(
                      'Spots',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(height: context.spacing.sm),
                    ...event.spots.map((spot) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: context.spacing.xs),
                        child: ListTile(
                          leading: const Icon(Icons.place,
                              color: AppTheme.primaryColor),
                          title: Text(
                            spot.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                          subtitle: spot.address != null
                              ? Text(
                                  spot.address!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.textSecondary),
                                )
                              : null,
                          tileColor: AppColors.grey100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            // Safety Checklist Section
            SafetyChecklistWidget(
              event: event,
              showAcknowledgment: userId != null && event.host.id == userId,
              readOnly: userId == null || event.host.id != userId,
              onAcknowledged: (acknowledged) {
                // Reload event if acknowledged
                _loadEvents();
              },
            ),

            // Success Dashboard (for completed events, hosts only)
            if (userId != null &&
                event.host.id == userId &&
                event.status == EventStatus.completed) ...[
              Container(
                padding: EdgeInsets.all(context.spacing.lg),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Event Success',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.spacing.sm),
                    Text(
                      'View detailed success metrics and recommendations for this event',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    SizedBox(height: context.spacing.sm),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransitions.slideFromRight(
                            EventSuccessDashboard(event: event),
                          ),
                        );
                      },
                      icon: const Icon(Icons.dashboard),
                      label: Text('View Success Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Partnership Section (for event hosts)
            if (userId != null && _currentEvent!.host.id == userId) ...[
              Container(
                padding: EdgeInsets.all(context.spacing.lg),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.handshake, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Partnerships',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.spacing.sm),
                    if (_hasPartnerships)
                      Text(
                        'This event has partnerships',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      )
                    else
                      Text(
                        'Partner with businesses to co-host this event',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    SizedBox(height: context.spacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppNavigator.pushBuilder(
                                context,
                                builder: (context) => PartnershipProposalPage(
                                  event: _currentEvent!,
                                ),
                              ).then((_) => _checkPartnerships());
                            },
                            icon: const Icon(Icons.add),
                            label: Text(_hasPartnerships
                                ? 'Add Partner'
                                : 'Propose Partnership'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(
                                  color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                        if (_hasPartnerships) ...[
                          SizedBox(width: context.spacing.sm),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                AppNavigator.pushBuilder(
                                  context,
                                  builder: (context) =>
                                      const PartnershipManagementPage(),
                                );
                              },
                              icon: const Icon(Icons.manage_accounts),
                              label: Text('Manage'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            Container(
              padding: EdgeInsets.all(context.spacing.lg),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Registration/Purchase Button
                  if (_isRegistered)
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              // Navigate to cancellation flow for paid events, or cancel directly for free events
                              if (event.isPaid) {
                                Navigator.push(
                                  context,
                                  PageTransitions.slideFromRight(
                                    CancellationFlowPage(
                                      event: event,
                                      isHost: false,
                                    ),
                                  ),
                                ).then((_) => _loadEvents());
                              } else {
                                _cancelRegistration();
                              }
                            },
                      icon: const Icon(Icons.cancel),
                      label: Text(event.isPaid
                          ? 'Cancel Ticket'
                          : 'Cancel Registration'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    )
                  // Host cancellation button
                  else if (userId != null &&
                      event.host.id == userId &&
                      event.status != EventStatus.cancelled)
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                PageTransitions.slideFromRight(
                                  CancellationFlowPage(
                                    event: event,
                                    isHost: true,
                                  ),
                                ),
                              ).then((_) => _loadEvents());
                            },
                      icon: const Icon(Icons.cancel),
                      label: Text('Cancel Event'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    )
                  else if (event.status == EventStatus.cancelled)
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grey400,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text('Event Cancelled'),
                    )
                  else if (event.isFull)
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grey400,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text('Event Full'),
                    )
                  else if (event.isPaid)
                    ElevatedButton.icon(
                      onPressed: _isLoading || !canRegister
                          ? null
                          : _handlePurchaseTicket,
                      icon: const Icon(Icons.payment),
                      label: Text(
                        'Purchase Ticket - \$${event.price?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed:
                          _isLoading || !canRegister ? null : _registerForEvent,
                      icon: const Icon(Icons.event_available),
                      label: Text('Register for Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                  if (_isLoading) ...[
                    SizedBox(height: context.spacing.md),
                    const CircularProgressIndicator(),
                  ],

                  if (_error != null) ...[
                    SizedBox(height: context.spacing.md),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  SizedBox(height: context.spacing.md),

                  // Additional Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addToCalendar,
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Add to Calendar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: context.spacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shareEvent,
                          icon: const Icon(Icons.share),
                          label: Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Dispute Link (for attendees)
                  if (userId != null &&
                      _isRegistered &&
                      event.host.id != userId) ...[
                    SizedBox(height: context.spacing.md),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransitions.slideFromRight(
                            DisputeSubmissionPage(event: event),
                          ),
                        );
                      },
                      icon: const Icon(Icons.gavel),
                      label: Text('Report an Issue'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              SizedBox(height: context.spacing.xxs),
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
    );
  }

  Widget _buildStatusBadge(ExpertiseEvent event) {
    Color badgeColor;
    String badgeText;

    switch (event.status) {
      case EventStatus.upcoming:
        badgeColor = AppColors.electricGreen;
        badgeText = 'Upcoming';
        break;
      case EventStatus.ongoing:
        badgeColor = AppTheme.warningColor;
        badgeText = 'Ongoing';
        break;
      case EventStatus.completed:
        badgeColor = AppColors.grey400;
        badgeText = 'Completed';
        break;
      case EventStatus.cancelled:
        badgeColor = AppColors.error;
        badgeText = 'Cancelled';
        break;
    }

    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: badgeColor.withValues(alpha: 0.3)),
      backgroundColor: badgeColor.withValues(alpha: 0.1),
      label: Text(
        badgeText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
      ),
    );
  }
}
