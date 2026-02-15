import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/expertise/expertise_event_widget.dart';
import 'package:avrai/presentation/pages/events/event_details_page.dart';
import 'package:avrai/presentation/pages/events/cancellation_flow_page.dart';
import 'package:avrai/presentation/pages/feedback/event_feedback_page.dart';
import 'package:avrai/presentation/widgets/common/page_transitions.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// My Events Page
/// Agent 2: Event Discovery & Hosting UI (Phase 1, Section 1)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Tab 1: Hosting (events user is hosting)
/// - Tab 2: Attending (events user is registered for)
/// - Tab 3: Past (past events - hosted or attended)
class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExpertiseEventService _eventService = ExpertiseEventService();

  List<ExpertiseEvent> _hostedEvents = [];
  List<ExpertiseEvent> _attendingEvents = [];
  List<ExpertiseEvent> _pastEvents = [];

  bool _isLoading = false;
  String? _error;
  UnifiedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please sign in to view your events';
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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load hosted events
      final hosted = await _eventService.getEventsByHost(_currentUser!);

      // Load attending events
      final attending = await _eventService.getEventsByAttendee(_currentUser!);

      // Separate past events
      final now = DateTime.now();
      final pastHosted = hosted.where((e) => e.endTime.isBefore(now)).toList();
      final pastAttending =
          attending.where((e) => e.endTime.isBefore(now)).toList();
      final allPastEvents = [...pastHosted, ...pastAttending];

      // Remove duplicates (if user hosted and attended same event)
      final uniquePastEvents = <String, ExpertiseEvent>{};
      for (final event in allPastEvents) {
        uniquePastEvents[event.id] = event;
      }

      // Filter out past events from hosted and attending
      final upcomingHosted =
          hosted.where((e) => e.endTime.isAfter(now)).toList();
      final upcomingAttending =
          attending.where((e) => e.endTime.isAfter(now)).toList();

      setState(() {
        _hostedEvents = upcomingHosted;
        _attendingEvents = upcomingAttending;
        _pastEvents = uniquePastEvents.values.toList()
          ..sort((a, b) =>
              b.startTime.compareTo(a.startTime)); // Most recent first
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'My Events',
      constrainBody: false,
      backgroundColor: AppColors.background,
      materialBottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
        indicatorColor: AppColors.white,
        tabs: const [
          Tab(text: 'Hosting', icon: Icon(Icons.event)),
          Tab(text: 'Attending', icon: Icon(Icons.event_available)),
          Tab(text: 'Past', icon: Icon(Icons.history)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        color: AppColors.electricGreen,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildHostedEventsTab(),
        _buildAttendingEventsTab(),
        _buildPastEventsTab(),
      ],
    );
  }

  Widget _buildHostedEventsTab() {
    if (_hostedEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy,
        title: 'No Hosted Events',
        message:
            'You haven\'t hosted any upcoming events yet.\nCreate your first event to get started!',
        actionLabel: 'Create Event',
        onAction: () {
          // TODO: Navigate to create event page (Week 3)
          context.showWarning('Event creation coming soon');
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(kSpaceMd),
      itemCount: _hostedEvents.length,
      itemBuilder: (context, index) {
        final event = _hostedEvents[index];
        return ExpertiseEventWidget(
          event: event,
          currentUser: _currentUser,
          onTap: () {
            AppNavigator.pushBuilder(
              context,
              builder: (context) => EventDetailsPage(event: event),
            );
          },
          onCancel: () {
            // Navigate to cancellation flow for host
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
        );
      },
    );
  }

  Widget _buildAttendingEventsTab() {
    if (_attendingEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available,
        title: 'No Upcoming Events',
        message:
            'You\'re not registered for any upcoming events.\nBrowse events to find something interesting!',
        actionLabel: 'Browse Events',
        onAction: () {
          Navigator.pop(context); // Go back to browse page
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(kSpaceMd),
      itemCount: _attendingEvents.length,
      itemBuilder: (context, index) {
        final event = _attendingEvents[index];
        return ExpertiseEventWidget(
          event: event,
          currentUser: _currentUser,
          onTap: () {
            AppNavigator.pushBuilder(
              context,
              builder: (context) => EventDetailsPage(event: event),
            );
          },
          onCancel: () {
            // Navigate to cancellation flow
            Navigator.push(
              context,
              PageTransitions.slideFromRight(
                CancellationFlowPage(
                  event: event,
                  isHost: false,
                ),
              ),
            ).then((_) => _loadEvents());
          },
        );
      },
    );
  }

  Widget _buildPastEventsTab() {
    if (_pastEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Past Events',
        message:
            'You haven\'t hosted or attended any events yet.\nYour event history will appear here!',
        actionLabel: null,
        onAction: null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(kSpaceMd),
      itemCount: _pastEvents.length,
      itemBuilder: (context, index) {
        final event = _pastEvents[index];
        return PortalSurface(
          margin: const EdgeInsets.only(bottom: kSpaceMd),
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              AppNavigator.pushBuilder(
                context,
                builder: (context) => EventDetailsPage(event: event),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(kSpaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                            const SizedBox(height: 4),
                            Text(
                              '${_formatPastDate(event.startTime)} • ${event.category}',
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
                      Chip(
                        side: BorderSide.none,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        backgroundColor:
                            AppColors.grey400.withValues(alpha: 0.1),
                        label: Text(
                          event.host.id == _currentUser?.id
                              ? 'Hosted'
                              : 'Attended',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${event.attendeeCount} ${event.attendeeCount == 1 ? 'attendee' : 'attendees'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (event.location != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Feedback button for past events
                  if (event.status == EventStatus.completed) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransitions.slideFromRight(
                            EventFeedbackPage(event: event),
                          ),
                        );
                      },
                      icon: const Icon(Icons.feedback),
                      label: Text('Leave Feedback'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSpaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: kSpaceLg, vertical: kSpaceSm),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPastDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
