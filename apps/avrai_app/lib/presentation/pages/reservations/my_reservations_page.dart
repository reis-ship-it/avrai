import 'dart:developer' as developer;

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/reservations/reservation_detail_page.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_card_widget.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_operational_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// My Reservations Page
/// Phase 15: Reservation System Implementation
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Display user's reservations
/// - Filter by status
/// - Sort by date
/// - Quick actions (cancel, modify)
class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({
    super.key,
    this.reservationService,
    this.reservationFollowUpPlannerService,
  });

  final ReservationService? reservationService;
  final ReservationOperationalFollowUpPromptPlannerService?
      reservationFollowUpPlannerService;

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ReservationService _reservationService;
  late final ReservationOperationalFollowUpPromptPlannerService
      _reservationFollowUpPlannerService;

  List<Reservation> _pendingReservations = [];
  List<Reservation> _confirmedReservations = [];
  List<Reservation> _cancelledReservations = [];
  List<Reservation> _pastReservations = [];
  List<ReservationOperationalFollowUpPromptPlan> _pendingFollowUpPlans =
      const <ReservationOperationalFollowUpPromptPlan>[];

  bool _isLoading = false;
  String? _error;
  UnifiedUser? _currentUser;
  String? _busyActionKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _reservationService =
        widget.reservationService ?? di.sl<ReservationService>();
    _reservationFollowUpPlannerService =
        widget.reservationFollowUpPlannerService ??
            ReservationOperationalFollowUpPromptPlannerService();
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please sign in to view your reservations';
      });
      return;
    }

    final user = authState.user;
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
      final reservations = await _reservationService.getUserReservations(
        userId: _currentUser!.id,
      );

      final now = DateTime.now();
      final pending = <Reservation>[];
      final confirmed = <Reservation>[];
      final cancelled = <Reservation>[];
      final past = <Reservation>[];

      for (final reservation in reservations) {
        if (reservation.status == ReservationStatus.cancelled) {
          cancelled.add(reservation);
        } else if (reservation.reservationTime.isBefore(now)) {
          past.add(reservation);
        } else if (reservation.status == ReservationStatus.pending) {
          pending.add(reservation);
        } else if (reservation.status == ReservationStatus.confirmed) {
          confirmed.add(reservation);
        }
      }

      pending.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
      confirmed.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
      cancelled.sort((a, b) => b.reservationTime.compareTo(a.reservationTime));
      past.sort((a, b) => b.reservationTime.compareTo(a.reservationTime));

      final pendingFollowUpPlans =
          await _reservationFollowUpPlannerService.listPendingPlans(
        _currentUser!.id,
        limit: 3,
      );

      setState(() {
        _pendingReservations = pending;
        _confirmedReservations = confirmed;
        _cancelledReservations = cancelled;
        _pastReservations = past;
        _pendingFollowUpPlans = pendingFollowUpPlans;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error loading reservations: $e',
        name: 'MyReservationsPage',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = _getUserFriendlyErrorMessage(e);
        _pendingFollowUpPlans =
            const <ReservationOperationalFollowUpPromptPlan>[];
        _isLoading = false;
      });
    }
  }

  List<Reservation> _getReservationsForTab(int index) {
    switch (index) {
      case 0:
        return _pendingReservations;
      case 1:
        return _confirmedReservations;
      case 2:
        return _cancelledReservations;
      case 3:
        return _pastReservations;
      default:
        return [];
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Pending (${_pendingReservations.length})';
      case 1:
        return 'Confirmed (${_confirmedReservations.length})';
      case 2:
        return 'Cancelled (${_cancelledReservations.length})';
      case 3:
        return 'Past (${_pastReservations.length})';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'My Reservations',
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      constrainBody: false,
      actions: [
        Semantics(
          label: 'View reservation analytics',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              context.push('/reservations/analytics');
            },
            tooltip: 'View Analytics',
          ),
        ),
      ],
      materialBottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
        indicatorColor: AppColors.white,
        tabs: [
          Tab(text: _getTabTitle(0)),
          Tab(text: _getTabTitle(1)),
          Tab(text: _getTabTitle(2)),
          Tab(text: _getTabTitle(3)),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: Semantics(
        label: 'Create new reservation',
        button: true,
        child: FloatingActionButton(
          onPressed: () async {
            final result =
                await Navigator.of(context).pushNamed('/reservations/create');
            if (result != null) {
              _loadReservations();
            }
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Semantics(
        label: 'Loading reservations',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Semantics(
        label: 'Error loading reservations: $_error',
        liveRegion: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Retry loading reservations',
                button: true,
                child: ElevatedButton(
                  onPressed: _loadReservations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: List.generate(4, (index) {
        final reservations = _getReservationsForTab(index);
        return RefreshIndicator(
          onRefresh: _loadReservations,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_pendingFollowUpPlans.isNotEmpty) ...[
                _buildReservationFollowUpQueueCard(context),
                const SizedBox(height: 16),
              ],
              if (reservations.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 96),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No reservations',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...reservations.map(
                  (reservation) => ReservationCardWidget(
                    reservation: reservation,
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ReservationDetailPage(
                            reservationId: reservation.id,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadReservations();
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReservationFollowUpQueueCard(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reservation follow-up queue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'These bounded reservation follow-ups clarify what a recent share, transfer, calendar sync, or recurrence change should mean before broader operational learning.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ..._pendingFollowUpPlans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.promptQuestion,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Operation: ${plan.operationKind} • target: ${plan.targetLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Context: ${plan.boundedContext['why'] ?? plan.promptRationale}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _busyActionKey == '${plan.planId}:answer'
                            ? null
                            : () => _handleReservationFollowUpAnswer(
                                  context,
                                  plan,
                                ),
                        child: const Text('Answer now'),
                      ),
                      OutlinedButton(
                        onPressed: _busyActionKey == '${plan.planId}:later'
                            ? null
                            : () => _handleReservationFollowUpLater(plan),
                        child: const Text('Later'),
                      ),
                      TextButton(
                        onPressed: _busyActionKey == '${plan.planId}:dismiss'
                            ? null
                            : () => _handleReservationFollowUpDismiss(plan),
                        child: const Text('Dismiss'),
                      ),
                      TextButton(
                        onPressed:
                            _busyActionKey == '${plan.planId}:dont_ask_again'
                                ? null
                                : () => _handleReservationFollowUpDontAskAgain(
                                      plan,
                                    ),
                        child: const Text("Don't ask again"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReservationFollowUpAnswer(
    BuildContext context,
    ReservationOperationalFollowUpPromptPlan plan,
  ) async {
    final responseText = await _showReservationFollowUpAnswerDialog(
      context,
      plan,
    );
    if (!mounted || responseText == null || responseText.trim().isEmpty) {
      return;
    }

    setState(() {
      _busyActionKey = '${plan.planId}:answer';
    });
    try {
      await _reservationFollowUpPlannerService.completePlanWithResponse(
        ownerUserId: plan.ownerUserId,
        planId: plan.planId,
        responseText: responseText.trim(),
        sourceSurface: 'reservation_in_app_follow_up_queue',
      );
      await _loadReservations();
    } finally {
      if (mounted) {
        setState(() {
          _busyActionKey = null;
        });
      }
    }
  }

  Future<void> _handleReservationFollowUpLater(
    ReservationOperationalFollowUpPromptPlan plan,
  ) async {
    setState(() {
      _busyActionKey = '${plan.planId}:later';
    });
    try {
      await _reservationFollowUpPlannerService.deferPlan(
        ownerUserId: plan.ownerUserId,
        planId: plan.planId,
      );
      await _loadReservations();
    } finally {
      if (mounted) {
        setState(() {
          _busyActionKey = null;
        });
      }
    }
  }

  Future<void> _handleReservationFollowUpDismiss(
    ReservationOperationalFollowUpPromptPlan plan,
  ) async {
    setState(() {
      _busyActionKey = '${plan.planId}:dismiss';
    });
    try {
      await _reservationFollowUpPlannerService.dismissPlan(
        ownerUserId: plan.ownerUserId,
        planId: plan.planId,
      );
      await _loadReservations();
    } finally {
      if (mounted) {
        setState(() {
          _busyActionKey = null;
        });
      }
    }
  }

  Future<void> _handleReservationFollowUpDontAskAgain(
    ReservationOperationalFollowUpPromptPlan plan,
  ) async {
    setState(() {
      _busyActionKey = '${plan.planId}:dont_ask_again';
    });
    try {
      await _reservationFollowUpPlannerService.dontAskAgainForPlan(
        ownerUserId: plan.ownerUserId,
        planId: plan.planId,
      );
      await _loadReservations();
    } finally {
      if (mounted) {
        setState(() {
          _busyActionKey = null;
        });
      }
    }
  }

  Future<String?> _showReservationFollowUpAnswerDialog(
    BuildContext context,
    ReservationOperationalFollowUpPromptPlan plan,
  ) async {
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
                      'Reservation follow-up',
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
                                : () => Navigator.of(context).pop(),
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
    return controller.text.trim();
  }

  /// Get user-friendly error message from exception
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection error. Your reservations are available offline.';
    }
    if (errorString.contains('not found') ||
        errorString.contains('does not exist')) {
      return 'Unable to load reservations. Please try again.';
    }
    return 'Failed to load reservations. Please try again.';
  }
}
