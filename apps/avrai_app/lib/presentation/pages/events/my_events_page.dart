import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_prompt_planner_service.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/expertise/expertise_event_widget.dart';
import 'package:avrai/presentation/pages/events/event_details_page.dart';
import 'package:avrai/presentation/pages/events/cancellation_flow_page.dart';
import 'package:avrai/presentation/pages/feedback/event_feedback_page.dart';
import 'package:avrai/presentation/widgets/common/page_transitions.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

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
  const MyEventsPage({
    super.key,
    this.eventService,
    this.eventFeedbackPromptPlannerService,
  });

  final ExpertiseEventService? eventService;
  final PostEventFeedbackPromptPlannerService?
      eventFeedbackPromptPlannerService;

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ExpertiseEventService _eventService;
  late final PostEventFeedbackPromptPlannerService _promptPlannerService;

  List<ExpertiseEvent> _hostedEvents = [];
  List<ExpertiseEvent> _attendingEvents = [];
  List<ExpertiseEvent> _pastEvents = [];
  List<PostEventFeedbackPromptPlan> _pendingPromptPlans =
      const <PostEventFeedbackPromptPlan>[];

  bool _isLoading = false;
  String? _error;
  UnifiedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _eventService = widget.eventService ?? ExpertiseEventService();
    _promptPlannerService = widget.eventFeedbackPromptPlannerService ??
        PostEventFeedbackPromptPlannerService();
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
      final pendingPlans = await _promptPlannerService.listPendingPlans(
        _currentUser!.id,
        limit: 3,
      );

      setState(() {
        _hostedEvents = upcomingHosted;
        _attendingEvents = upcomingAttending;
        _pastEvents = uniquePastEvents.values.toList()
          ..sort((a, b) =>
              b.startTime.compareTo(a.startTime)); // Most recent first
        _pendingPromptPlans = pendingPlans;
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
    return AppFlowScaffold(
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
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
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
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: const Text('Retry'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event creation coming soon'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hostedEvents.length,
      itemBuilder: (context, index) {
        final event = _hostedEvents[index];
        return ExpertiseEventWidget(
          event: event,
          currentUser: _currentUser,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailsPage(event: event),
              ),
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
      padding: const EdgeInsets.all(16),
      itemCount: _attendingEvents.length,
      itemBuilder: (context, index) {
        final event = _attendingEvents[index];
        return ExpertiseEventWidget(
          event: event,
          currentUser: _currentUser,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailsPage(event: event),
              ),
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
    if (_pastEvents.isEmpty && _pendingPromptPlans.isEmpty) {
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
      padding: const EdgeInsets.all(16),
      itemCount: _pastEvents.length + (_pendingPromptPlans.isEmpty ? 0 : 1),
      itemBuilder: (context, index) {
        if (_pendingPromptPlans.isNotEmpty && index == 0) {
          return _buildFollowUpQueueCard();
        }
        final eventIndex = index - (_pendingPromptPlans.isNotEmpty ? 1 : 0);
        final event = _pastEvents[eventIndex];
        return AppSurface(
          margin: const EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(event: event),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatPastDate(event.startTime)} • ${event.category}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.grey400.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.host.id == _currentUser?.id
                              ? 'Hosted'
                              : 'Attended',
                          style: const TextStyle(
                            fontSize: 12,
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
                    style: const TextStyle(
                      fontSize: 14,
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
                        style: const TextStyle(
                          fontSize: 12,
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (event.status == EventStatus.completed) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          PageTransitions.slideFromRight(
                            EventFeedbackPage(event: event),
                          ),
                        );
                        await _loadEvents();
                      },
                      icon: const Icon(Icons.feedback),
                      label: const Text('Leave Feedback'),
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

  Widget _buildFollowUpQueueCard() {
    return AppSurface(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Follow-up queue',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'These bounded event follow-ups help AVRAI learn what changed after the event instead of only storing the first reaction.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          for (final plan in _pendingPromptPlans) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.grey400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.promptQuestion,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Why this now: ${plan.boundedContext['why'] ?? plan.promptRationale}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => _answerPromptPlan(plan),
                        child: const Text('Answer now'),
                      ),
                      OutlinedButton(
                        onPressed: () => _deferPromptPlan(plan),
                        child: const Text('Later'),
                      ),
                      TextButton(
                        onPressed: () => _dismissPromptPlan(plan),
                        child: const Text('Dismiss'),
                      ),
                      TextButton(
                        onPressed: () => _dontAskAgainPromptPlan(plan),
                        child: const Text("Don't ask again"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _answerPromptPlan(PostEventFeedbackPromptPlan plan) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event follow-up',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      plan.promptQuestion,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Why this now: ${plan.boundedContext['why'] ?? plan.promptRationale}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 3,
                      autofocus: true,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Add a bounded answer here',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: controller.text.trim().isEmpty
                                ? null
                                : () async {
                                    await _promptPlannerService
                                        .completePlanWithResponse(
                                      ownerUserId: plan.ownerUserId,
                                      planId: plan.planId,
                                      responseText: controller.text.trim(),
                                      sourceSurface:
                                          'event_feedback_in_app_follow_up',
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                            child: const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted) {
      return;
    }
    await _loadEvents();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Saved your bounded event follow-up answer for later learning review.',
        ),
      ),
    );
  }

  Future<void> _deferPromptPlan(PostEventFeedbackPromptPlan plan) async {
    await _promptPlannerService.deferPlan(
      ownerUserId: plan.ownerUserId,
      planId: plan.planId,
    );
    await _loadEvents();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kept this event follow-up in the queue for later.'),
      ),
    );
  }

  Future<void> _dismissPromptPlan(PostEventFeedbackPromptPlan plan) async {
    await _promptPlannerService.dismissPlan(
      ownerUserId: plan.ownerUserId,
      planId: plan.planId,
    );
    await _loadEvents();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed this bounded event follow-up from the queue.'),
      ),
    );
  }

  Future<void> _dontAskAgainPromptPlan(PostEventFeedbackPromptPlan plan) async {
    await _promptPlannerService.dontAskAgainForPlan(
      ownerUserId: plan.ownerUserId,
      planId: plan.planId,
    );
    await _loadEvents();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'AVRAI will stop asking this bounded event follow-up for that event.',
        ),
      ),
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
        padding: const EdgeInsets.all(32),
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
