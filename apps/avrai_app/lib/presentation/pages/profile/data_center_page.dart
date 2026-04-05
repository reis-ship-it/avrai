import 'dart:developer' as developer;

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/settings/privacy_settings_page.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_core/models/reality/user_visible_governed_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/community/community_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/visit_locality_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_control_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_signal_policy_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_usage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DataCenterPage extends StatefulWidget {
  static const String focusRecordQueryParam = 'focus_record';
  static const String focusEntityQueryParam = 'focus_entity';

  const DataCenterPage({
    super.key,
    this.projectionService,
    this.controlService,
    this.onboardingFollowUpPlannerService,
    this.correctionFollowUpPlannerService,
    this.communityFollowUpPlannerService,
    this.visitLocalityFollowUpPlannerService,
    this.feedbackService,
    this.focusEnvelopeId,
    this.focusEntityTitle,
  });

  final UserGovernedLearningProjectionService? projectionService;
  final UserGovernedLearningControlService? controlService;
  final OnboardingFollowUpPromptPlannerService?
      onboardingFollowUpPlannerService;
  final UserGovernedLearningCorrectionFollowUpPromptPlannerService?
      correctionFollowUpPlannerService;
  final CommunityFollowUpPromptPlannerService? communityFollowUpPlannerService;
  final VisitLocalityFollowUpPromptPlannerService?
      visitLocalityFollowUpPlannerService;
  final RecommendationFeedbackService? feedbackService;
  final String? focusEnvelopeId;
  final String? focusEntityTitle;

  static String routeLocation({
    String? focusEnvelopeId,
    String? focusEntityTitle,
  }) {
    final queryParameters = <String, String>{
      if (focusEnvelopeId?.trim().isNotEmpty ?? false)
        focusRecordQueryParam: focusEnvelopeId!.trim(),
      if (focusEntityTitle?.trim().isNotEmpty ?? false)
        focusEntityQueryParam: focusEntityTitle!.trim(),
    };
    return Uri(
      path: '/profile/data-center',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }

  @override
  State<DataCenterPage> createState() => _DataCenterPageState();
}

class _DataCenterPageState extends State<DataCenterPage> {
  static const List<String> _knownSurfacedRecommendationLanes = <String>[
    'events_personalized',
    'explore_events',
    'explore_spots',
  ];

  static const String _logName = 'DataCenterPage';

  UserGovernedLearningProjectionService? _projectionService;
  UserGovernedLearningControlService? _controlService;
  OnboardingFollowUpPromptPlannerService? _onboardingFollowUpPlannerService;
  UserGovernedLearningCorrectionFollowUpPromptPlannerService?
      _correctionFollowUpPlannerService;
  CommunityFollowUpPromptPlannerService? _communityFollowUpPlannerService;
  VisitLocalityFollowUpPromptPlannerService?
      _visitLocalityFollowUpPlannerService;
  RecommendationFeedbackService? _feedbackService;
  late Future<_DataCenterLoadResult> _future;
  String? _busyActionKey;
  String? _highlightedRecordEnvelopeId;
  final Map<String, GlobalKey> _recordKeys = <String, GlobalKey>{};
  bool _initialFocusApplied = false;

  @override
  void initState() {
    super.initState();
    _projectionService = widget.projectionService ?? _tryResolveProjection();
    _controlService = widget.controlService ?? _tryResolveControlService();
    _onboardingFollowUpPlannerService =
        widget.onboardingFollowUpPlannerService ??
            _tryResolveOnboardingFollowUpPlannerService();
    _correctionFollowUpPlannerService =
        widget.correctionFollowUpPlannerService ??
            _tryResolveCorrectionFollowUpPlannerService();
    _communityFollowUpPlannerService = widget.communityFollowUpPlannerService ??
        _tryResolveCommunityFollowUpPlannerService();
    _visitLocalityFollowUpPlannerService =
        widget.visitLocalityFollowUpPlannerService ??
            _tryResolveVisitLocalityFollowUpPlannerService();
    _feedbackService = widget.feedbackService ?? _tryResolveFeedbackService();
    _future = _load();
  }

  UserGovernedLearningProjectionService? _tryResolveProjection() {
    try {
      if (GetIt.instance
          .isRegistered<UserGovernedLearningProjectionService>()) {
        return GetIt.instance<UserGovernedLearningProjectionService>();
      }
      if (GetIt.instance.isRegistered<UniversalIntakeRepository>()) {
        final signalPolicyService = GetIt.instance
                .isRegistered<UserGovernedLearningSignalPolicyService>()
            ? GetIt.instance<UserGovernedLearningSignalPolicyService>()
            : null;
        return UserGovernedLearningProjectionService(
          intakeRepository: GetIt.instance<UniversalIntakeRepository>(),
          signalPolicyService: signalPolicyService,
          adoptionService:
              GetIt.instance.isRegistered<UserGovernedLearningAdoptionService>()
                  ? GetIt.instance<UserGovernedLearningAdoptionService>()
                  : null,
          usageService:
              GetIt.instance.isRegistered<UserGovernedLearningUsageService>()
                  ? GetIt.instance<UserGovernedLearningUsageService>()
                  : null,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to resolve UserGovernedLearningProjectionService',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  CommunityFollowUpPromptPlannerService?
      _tryResolveCommunityFollowUpPlannerService() {
    try {
      if (GetIt.instance
          .isRegistered<CommunityFollowUpPromptPlannerService>()) {
        return GetIt.instance<CommunityFollowUpPromptPlannerService>();
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to resolve CommunityFollowUpPromptPlannerService',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  OnboardingFollowUpPromptPlannerService?
      _tryResolveOnboardingFollowUpPlannerService() {
    try {
      if (GetIt.instance
          .isRegistered<OnboardingFollowUpPromptPlannerService>()) {
        return GetIt.instance<OnboardingFollowUpPromptPlannerService>();
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to resolve OnboardingFollowUpPromptPlannerService',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  UserGovernedLearningControlService? _tryResolveControlService() {
    try {
      if (GetIt.instance.isRegistered<UserGovernedLearningControlService>()) {
        return GetIt.instance<UserGovernedLearningControlService>();
      }
      if (!GetIt.instance.isRegistered<UniversalIntakeRepository>() ||
          !GetIt.instance.isRegistered<GovernedUpwardLearningIntakeService>() ||
          !GetIt.instance.isRegistered<AgentIdService>()) {
        return null;
      }
      final signalPolicyService =
          GetIt.instance.isRegistered<UserGovernedLearningSignalPolicyService>()
              ? GetIt.instance<UserGovernedLearningSignalPolicyService>()
              : GetIt.instance.isRegistered<StorageService>()
                  ? UserGovernedLearningSignalPolicyService(
                      storageService: GetIt.instance<StorageService>(),
                    )
                  : null;
      if (signalPolicyService == null) {
        return null;
      }
      return UserGovernedLearningControlService(
        intakeRepository: GetIt.instance<UniversalIntakeRepository>(),
        governedUpwardLearningIntakeService:
            GetIt.instance<GovernedUpwardLearningIntakeService>(),
        agentIdService: GetIt.instance<AgentIdService>(),
        signalPolicyService: signalPolicyService,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to resolve UserGovernedLearningControlService',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  UserGovernedLearningCorrectionFollowUpPromptPlannerService?
      _tryResolveCorrectionFollowUpPlannerService() {
    try {
      if (GetIt.instance.isRegistered<
          UserGovernedLearningCorrectionFollowUpPromptPlannerService>()) {
        return GetIt.instance<
            UserGovernedLearningCorrectionFollowUpPromptPlannerService>();
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to resolve UserGovernedLearningCorrectionFollowUpPromptPlannerService',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  VisitLocalityFollowUpPromptPlannerService?
      _tryResolveVisitLocalityFollowUpPlannerService() {
    try {
      if (GetIt.instance
          .isRegistered<VisitLocalityFollowUpPromptPlannerService>()) {
        return GetIt.instance<VisitLocalityFollowUpPromptPlannerService>();
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to resolve VisitLocalityFollowUpPromptPlannerService',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  RecommendationFeedbackService? _tryResolveFeedbackService() {
    try {
      if (GetIt.instance.isRegistered<RecommendationFeedbackService>()) {
        return GetIt.instance<RecommendationFeedbackService>();
      }
      return RecommendationFeedbackService();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to resolve RecommendationFeedbackService',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  Future<_DataCenterLoadResult> _load() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const _DataCenterLoadResult.unauthenticated();
    }

    final projectionService = _projectionService;
    if (projectionService == null) {
      return const _DataCenterLoadResult.unavailable();
    }

    final explanation = await projectionService.buildChatExplanation(
      ownerUserId: authState.user.id,
      maxRecords: 20,
    );
    final records = await projectionService.listVisibleRecords(
      ownerUserId: authState.user.id,
      limit: 20,
    );
    final onboardingFollowUpPlans =
        await _onboardingFollowUpPlannerService?.listPendingPlans(
              authState.user.id,
              limit: 3,
            ) ??
            const <OnboardingFollowUpPromptPlan>[];
    final correctionFollowUpPlans =
        await _correctionFollowUpPlannerService?.listPendingPlans(
              authState.user.id,
              limit: 3,
            ) ??
            const <UserGovernedLearningCorrectionFollowUpPlan>[];
    final communityFollowUpPlans =
        await _communityFollowUpPlannerService?.listPendingPlans(
              authState.user.id,
              limit: 3,
            ) ??
            const <CommunityFollowUpPromptPlan>[];
    final visitLocalityFollowUpPlans =
        await _visitLocalityFollowUpPlannerService?.listPendingPlans(
              authState.user.id,
              limit: 3,
            ) ??
            const <VisitLocalityFollowUpPromptPlan>[];
    final feedbackEvents =
        (await _feedbackService?.listEvents(authState.user.id) ??
                const <RecommendationFeedbackEvent>[])
            .take(6)
            .toList(growable: false);

    return _DataCenterLoadResult(
      explanation: UserGovernedLearningExplanation(
        summary: explanation.summary,
        details: explanation.details,
        records: records,
        suggestedActions: explanation.suggestedActions,
      ),
      pendingOnboardingFollowUpPlans: onboardingFollowUpPlans,
      pendingCorrectionFollowUpPlans: correctionFollowUpPlans,
      pendingCommunityFollowUpPlans: communityFollowUpPlans,
      pendingVisitLocalityFollowUpPlans: visitLocalityFollowUpPlans,
      feedbackEvents: feedbackEvents,
      isAuthenticated: true,
      serviceAvailable: true,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Data Center',
      constrainBody: false,
      body: FutureBuilder<_DataCenterLoadResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data ?? const _DataCenterLoadResult();
          if (!result.isAuthenticated) {
            return _buildMessageState(
              title: 'Sign in to view your data center',
              body:
                  'This page shows the same governed learning records AVRAI can explain in chat, but in a structured control surface.',
            );
          }
          if (!result.serviceAvailable) {
            return _buildMessageState(
              title: 'Governed learning ledger unavailable',
              body:
                  'AVRAI can show this page once the local governed learning projection is available on this device.',
            );
          }

          final explanation = result.explanation;
          final records = explanation.records;
          final onboardingFollowUpPlans = result.pendingOnboardingFollowUpPlans;
          final correctionFollowUpPlans = result.pendingCorrectionFollowUpPlans;
          final communityFollowUpPlans = result.pendingCommunityFollowUpPlans;
          final visitLocalityFollowUpPlans =
              result.pendingVisitLocalityFollowUpPlans;
          final feedbackEvents = result.feedbackEvents;
          final pendingReviewCount =
              records.where((record) => record.requiresHumanReview).length;

          _maybeApplyInitialFocus(records);

          return RefreshIndicator(
            onRefresh: () async {
              await _reload();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Governed Learning',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chat is the mouth. This page is the ledger. It shows the same recent governed learning records AVRAI can explain conversationally, but with more structure and control context.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMetricChip(
                            context,
                            icon: Icons.layers_outlined,
                            label: '${records.length} recent records',
                          ),
                          _buildMetricChip(
                            context,
                            icon: Icons.shield_outlined,
                            label: '$pendingReviewCount pending review',
                          ),
                          if (records.isNotEmpty)
                            _buildMetricChip(
                              context,
                              icon: Icons.schedule_outlined,
                              label:
                                  'Latest ${_formatDateTime(records.first.stagedAtUtc)}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (onboardingFollowUpPlans.isNotEmpty) ...[
                  _buildOnboardingFollowUpQueueCard(
                    context,
                    onboardingFollowUpPlans,
                  ),
                  const SizedBox(height: 12),
                ],
                if (correctionFollowUpPlans.isNotEmpty) ...[
                  _buildCorrectionFollowUpQueueCard(
                    context,
                    correctionFollowUpPlans,
                  ),
                  const SizedBox(height: 12),
                ],
                if (communityFollowUpPlans.isNotEmpty) ...[
                  _buildCommunityFollowUpQueueCard(
                    context,
                    communityFollowUpPlans,
                  ),
                  const SizedBox(height: 12),
                ],
                if (visitLocalityFollowUpPlans.isNotEmpty) ...[
                  _buildVisitLocalityFollowUpQueueCard(
                    context,
                    visitLocalityFollowUpPlans,
                  ),
                  const SizedBox(height: 12),
                ],
                if (feedbackEvents.isNotEmpty) ...[
                  _buildRecentFeedbackCard(
                    context,
                    feedbackEvents,
                    records,
                  ),
                  const SizedBox(height: 12),
                ],
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        explanation.summary,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (explanation.details.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...explanation.details.take(4).map(
                              (detail) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(detail)),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Control surface',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can ask in chat for more detail, corrections, or forgetting. Global privacy and learning controls remain in settings.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => context.go('/chat/agent'),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Ask in chat'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PrivacySettingsPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.privacy_tip_outlined),
                            label: const Text('Privacy settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recent records',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (records.isEmpty)
                  _buildMessageState(
                    title: 'No governed learning records yet',
                    body:
                        'When AVRAI learns from your explicit behavior, corrections, or preference signals, the latest records will appear here.',
                    includeScaffold: false,
                  )
                else
                  ...records.map((record) => _buildRecordCard(context, record)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    UserVisibleGovernedLearningRecord record,
  ) {
    final theme = Theme.of(context);
    final isBusy = _busyActionKey?.startsWith('${record.envelopeId}:') ?? false;
    final isHighlighted = _highlightedRecordEnvelopeId == record.envelopeId;
    return AppSurface(
      key: _recordKeyFor(record.envelopeId),
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      color:
          isHighlighted ? AppTheme.primaryColor.withValues(alpha: 0.08) : null,
      borderColor: isHighlighted ? AppTheme.primaryColor : null,
      child: ExpansionTile(
        leading: Icon(
          record.requiresHumanReview
              ? Icons.shield_outlined
              : Icons.check_circle_outline,
          color: record.requiresHumanReview
              ? AppTheme.primaryColor
              : AppColors.success,
        ),
        title: Text(
          record.title.isNotEmpty ? record.title : record.safeSummary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${record.sourceLabel} • ${_formatDateTime(record.stagedAtUtc)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              record.safeSummary,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDetailChip(
                label: _humanizeConvictionTier(record.convictionTier),
                icon: Icons.insights_outlined,
              ),
              _buildDetailChip(
                label: record.requiresHumanReview
                    ? 'bounded behind human review'
                    : 'available to your local runtime',
                icon: Icons.admin_panel_settings_outlined,
              ),
              if (record.kernelGraphStatus != null)
                _buildDetailChip(
                  label: 'graph ${record.kernelGraphStatus!.name}',
                  icon: Icons.device_hub_outlined,
                ),
              _buildDetailChip(
                label: record.sourceProvider,
                icon: Icons.storage_outlined,
              ),
              if (record.futureSignalUseBlocked)
                _buildDetailChip(
                  label: 'future use blocked',
                  icon: Icons.block_outlined,
                ),
              if (record.currentAdoptionStatus != null)
                _buildDetailChip(
                  label: _humanizeAdoptionStatus(
                    record.currentAdoptionStatus!,
                    pendingSurfaces: record.pendingSurfaces,
                    surfacedSurfaces: record.surfacedSurfaces,
                  ),
                  icon: _iconForAdoptionStatus(record.currentAdoptionStatus!),
                ),
              for (final surface in record.pendingSurfaces)
                _buildDetailChip(
                  label: 'queued for ${_humanizeLearningSurface(surface)}',
                  icon: Icons.schedule_outlined,
                ),
              for (final surface in record.surfacedSurfaces)
                _buildDetailChip(
                  label: 'active in ${_humanizeLearningSurface(surface)}',
                  icon: Icons.auto_graph_outlined,
                ),
              for (final surface in _inactiveLearningSurfaces(record))
                _buildDetailChip(
                  label:
                      'not yet active in ${_humanizeLearningSurface(surface)}',
                  icon: Icons.radio_button_unchecked,
                ),
              if (record.usageCount > 0)
                _buildDetailChip(
                  label:
                      'used ${record.usageCount} time${record.usageCount == 1 ? '' : 's'}',
                  icon: Icons.history_toggle_off_outlined,
                ),
              if (_latestGovernanceStatus(record) case final governanceStatus?)
                _buildDetailChip(
                  label: _humanizeGovernanceStatus(governanceStatus),
                  icon: _iconForGovernanceStatus(governanceStatus),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _buildAdoptionSummary(record),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (record.firstSurfacedAtUtc != null) ...[
            const SizedBox(height: 8),
            Text(
              'First surfaced: ${_formatDateTime(record.firstSurfacedAtUtc!)}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (_buildGovernanceSummary(record)
              case final governanceSummary?) ...[
            const SizedBox(height: 8),
            Text(
              governanceSummary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (record.appliedDomains.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTokenSection(
              context,
              title: 'Applied domains',
              values: record.appliedDomains,
            ),
          ],
          if (record.domainHints.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTokenSection(
              context,
              title: 'Domains',
              values: record.domainHints,
            ),
          ],
          if (record.referencedEntities.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTokenSection(
              context,
              title: 'Entities',
              values: record.referencedEntities,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'In chat you can ask for more detail, correct this, forget it, or tell AVRAI to stop using this signal type for learning.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (record.availableActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (record.availableActions.contains(
                  UserGovernedLearningAction.correctRecord,
                ))
                  OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => _handleCorrectRecord(context, record),
                    icon: isBusy &&
                            _busyActionKey == '${record.envelopeId}:correct'
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_outlined),
                    label: const Text('Correct'),
                  ),
                if (record.availableActions.contains(
                  UserGovernedLearningAction.forgetRecord,
                ))
                  OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => _handleForgetRecord(context, record),
                    icon: isBusy &&
                            _busyActionKey == '${record.envelopeId}:forget'
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text('Forget'),
                  ),
                if (record.availableActions.contains(
                  UserGovernedLearningAction.stopUsingSignal,
                ))
                  OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => _handleStopUsingSignal(context, record),
                    icon: isBusy &&
                            _busyActionKey == '${record.envelopeId}:stop'
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_outlined),
                    label: const Text('Stop using this signal'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnboardingFollowUpQueueCard(
    BuildContext context,
    List<OnboardingFollowUpPromptPlan> plans,
  ) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onboarding follow-up queue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'These bounded follow-ups clarify what your original onboarding should mean before broader personal learning hardens.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...plans.map(
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
                    'Homebase: ${plan.homebase?.trim().isNotEmpty == true ? plan.homebase!.trim() : 'not set'}'
                    '${plan.questionnaireVersion?.trim().isNotEmpty == true ? ' • ${plan.questionnaireVersion!.trim()}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Context: ${plan.boundedContext['why'] ?? plan.sourceSurface}',
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
                            : () => _handleOnboardingFollowUpAnswer(
                                  context,
                                  plan,
                                ),
                        child: const Text('Answer now'),
                      ),
                      OutlinedButton(
                        onPressed: _busyActionKey == '${plan.planId}:later'
                            ? null
                            : () => _handleOnboardingFollowUpLater(plan),
                        child: const Text('Later'),
                      ),
                      TextButton(
                        onPressed: _busyActionKey == '${plan.planId}:dismiss'
                            ? null
                            : () => _handleOnboardingFollowUpDismiss(plan),
                        child: const Text('Dismiss'),
                      ),
                      TextButton(
                        onPressed: _busyActionKey ==
                                '${plan.planId}:dont_ask_again'
                            ? null
                            : () => _handleOnboardingFollowUpDontAskAgain(plan),
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

  Widget _buildCorrectionFollowUpQueueCard(
    BuildContext context,
    List<UserGovernedLearningCorrectionFollowUpPlan> plans,
  ) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Correction follow-up queue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'These bounded follow-ups clarify whether a correction should apply durably or only in a narrower situation before broader learning.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...plans.map(
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
                    'Earlier correction: ${plan.correctionText}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: ${plan.targetSummary}',
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
                            : () => _handleCorrectionFollowUpAnswer(
                                  context,
                                  plan,
                                ),
                        child: const Text('Answer now'),
                      ),
                      OutlinedButton(
                        onPressed: _busyActionKey == '${plan.planId}:later'
                            ? null
                            : () => _handleCorrectionFollowUpLater(plan),
                        child: const Text('Later'),
                      ),
                      TextButton(
                        onPressed: _busyActionKey == '${plan.planId}:dismiss'
                            ? null
                            : () => _handleCorrectionFollowUpDismiss(plan),
                        child: const Text('Dismiss'),
                      ),
                      TextButton(
                        onPressed:
                            _busyActionKey == '${plan.planId}:dont_ask_again'
                                ? null
                                : () => _handleCorrectionFollowUpDontAskAgain(
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

  Widget _buildVisitLocalityFollowUpQueueCard(
    BuildContext context,
    List<VisitLocalityFollowUpPromptPlan> plans,
  ) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visit and locality follow-up queue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'These bounded follow-ups clarify what a recent visit or locality observation should mean before broader behavioral learning.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...plans.map(
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
                    'Observed: ${plan.observationKind} • target: ${plan.targetLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Context: ${plan.boundedContext['why'] ?? plan.sourceSurface}',
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
                            : () => _handleVisitLocalityFollowUpAnswer(
                                  context,
                                  plan,
                                ),
                        child: const Text('Answer now'),
                      ),
                      OutlinedButton(
                        onPressed: _busyActionKey == '${plan.planId}:later'
                            ? null
                            : () => _handleVisitLocalityFollowUpLater(plan),
                        child: const Text('Later'),
                      ),
                      TextButton(
                        onPressed: _busyActionKey == '${plan.planId}:dismiss'
                            ? null
                            : () => _handleVisitLocalityFollowUpDismiss(plan),
                        child: const Text('Dismiss'),
                      ),
                      TextButton(
                        onPressed: _busyActionKey ==
                                '${plan.planId}:dont_ask_again'
                            ? null
                            : () => _handleVisitLocalityFollowUpDontAskAgain(
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

  Widget _buildCommunityFollowUpQueueCard(
    BuildContext context,
    List<CommunityFollowUpPromptPlan> plans,
  ) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community follow-up queue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'These bounded follow-ups clarify what a recent community action or validation should mean before broader community learning.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...plans.map(
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
                    'Kind: ${plan.followUpKind} • target: ${plan.targetLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Context: ${plan.boundedContext['why'] ?? plan.sourceSurface}',
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
                            : () => _handleCommunityFollowUpAnswer(
                                  context,
                                  plan,
                                ),
                        child: const Text('Answer now'),
                      ),
                      OutlinedButton(
                        onPressed: _busyActionKey == '${plan.planId}:later'
                            ? null
                            : () => _handleCommunityFollowUpLater(plan),
                        child: const Text('Later'),
                      ),
                      TextButton(
                        onPressed: _busyActionKey == '${plan.planId}:dismiss'
                            ? null
                            : () => _handleCommunityFollowUpDismiss(plan),
                        child: const Text('Dismiss'),
                      ),
                      TextButton(
                        onPressed:
                            _busyActionKey == '${plan.planId}:dont_ask_again'
                                ? null
                                : () => _handleCommunityFollowUpDontAskAgain(
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

  Widget _buildRecentFeedbackCard(
    BuildContext context,
    List<RecommendationFeedbackEvent> events,
    List<UserVisibleGovernedLearningRecord> records,
  ) {
    final theme = Theme.of(context);
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent recommendation feedback',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This keeps the actual explanation wording you saw when you reacted to a recommendation, so your feedback history stays aligned with the surfaced reason.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...events.map(
            (event) {
              final explanation = _preferredAttributionContext(
                event.attribution,
              );
              final recommendationRoutePath = _routePathForEntity(event.entity);
              final relatedRecord = _findRelatedRecordForFeedback(
                event,
                records,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.entity.title,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_humanizeFeedbackAction(event.action)} • ${event.sourceSurface} • ${_formatDateTime(event.occurredAtUtc)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (explanation != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        explanation,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (relatedRecord != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Linked governed record: ${relatedRecord.title}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (recommendationRoutePath != null ||
                        relatedRecord != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (recommendationRoutePath != null)
                            OutlinedButton.icon(
                              onPressed: () => context.go(
                                recommendationRoutePath,
                              ),
                              icon: const Icon(Icons.open_in_new_outlined),
                              label: const Text('Open recommendation'),
                            ),
                          if (relatedRecord != null)
                            TextButton.icon(
                              onPressed: () => _jumpToRecord(
                                relatedRecord.envelopeId,
                              ),
                              icon: const Icon(Icons.arrow_downward_outlined),
                              label: const Text('Jump to related record'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleCorrectRecord(
    BuildContext context,
    UserVisibleGovernedLearningRecord record,
  ) async {
    final ownerUserId = _currentUserId;
    final controlService = _controlService;
    if (ownerUserId == null || controlService == null) {
      _showSnackBar(
        'AVRAI cannot submit a correction from this device yet.',
      );
      return;
    }
    final correctionText = await _promptForCorrection(context, record);
    if (correctionText == null) {
      return;
    }
    await _runRecordAction(
      envelopeId: record.envelopeId,
      action: 'correct',
      onRun: () => controlService.submitCorrection(
        ownerUserId: ownerUserId,
        envelopeId: record.envelopeId,
        correctionText: correctionText,
      ),
      onSuccess: (result) {
        if (result == null) {
          _showSnackBar('AVRAI could not stage that correction.');
          return;
        }
        _showSnackBar('Correction staged for governed review.');
      },
    );
  }

  Future<void> _handleForgetRecord(
    BuildContext context,
    UserVisibleGovernedLearningRecord record,
  ) async {
    final ownerUserId = _currentUserId;
    final controlService = _controlService;
    if (ownerUserId == null || controlService == null) {
      _showSnackBar('AVRAI cannot forget this record from this device yet.');
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Forget this record?'),
            content: Text(
              'This will remove "${record.safeSummary}" from the user-facing ledger and stop showing it in chat explanations.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Forget'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    await _runRecordAction(
      envelopeId: record.envelopeId,
      action: 'forget',
      onRun: () => controlService.forgetRecord(
        ownerUserId: ownerUserId,
        envelopeId: record.envelopeId,
      ),
      onSuccess: (forgotten) {
        _showSnackBar(
          forgotten
              ? 'Record forgotten from your visible ledger.'
              : 'AVRAI could not find that record to forget.',
        );
      },
    );
  }

  Future<void> _handleStopUsingSignal(
    BuildContext context,
    UserVisibleGovernedLearningRecord record,
  ) async {
    final ownerUserId = _currentUserId;
    final controlService = _controlService;
    if (ownerUserId == null || controlService == null) {
      _showSnackBar(
        'AVRAI cannot change signal-use policy from this device yet.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Stop using this signal?'),
            content: Text(
              'Future ${_humanizeConvictionTier(record.convictionTier)} signals from ${record.sourceProvider} will no longer be used for governed learning.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Stop using signal'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    await _runRecordAction(
      envelopeId: record.envelopeId,
      action: 'stop',
      onRun: () => controlService.stopUsingSignal(
        ownerUserId: ownerUserId,
        envelopeId: record.envelopeId,
      ),
      onSuccess: (stopped) {
        _showSnackBar(
          stopped
              ? 'Future matching signals will be blocked from governed learning.'
              : 'AVRAI could not update that signal policy.',
        );
      },
    );
  }

  Future<void> _handleOnboardingFollowUpAnswer(
    BuildContext context,
    OnboardingFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _onboardingFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot capture that onboarding follow-up from this device yet.',
      );
      return;
    }
    final responseText = await _promptForFollowUpResponse(
      context,
      title: 'Onboarding follow-up',
      promptQuestion: plan.promptQuestion,
      supportingText: plan.homebase?.trim().isNotEmpty == true
          ? 'Original onboarding context around ${plan.homebase!.trim()}.'
          : 'Original onboarding context from your declared preferences.',
    );
    if (responseText == null) {
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'answer',
      onRun: () => planner.completePlanWithResponse(
        ownerUserId: ownerUserId,
        planId: plan.planId,
        responseText: responseText,
        sourceSurface: 'data_center_follow_up_queue',
      ),
      onSuccess: (_) {
        _showSnackBar('Bounded onboarding follow-up captured.');
      },
    );
  }

  Future<void> _handleOnboardingFollowUpLater(
    OnboardingFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _onboardingFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar('AVRAI cannot defer that follow-up from this device yet.');
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'later',
      onRun: () => planner.deferPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('Onboarding follow-up deferred.');
      },
    );
  }

  Future<void> _handleOnboardingFollowUpDismiss(
    OnboardingFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _onboardingFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot dismiss that follow-up from this device yet.',
      );
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'dismiss',
      onRun: () => planner.dismissPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('Onboarding follow-up dismissed.');
      },
    );
  }

  Future<void> _handleOnboardingFollowUpDontAskAgain(
    OnboardingFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _onboardingFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot update that follow-up preference from this device yet.',
      );
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'dont_ask_again',
      onRun: () => planner.dontAskAgainForPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('AVRAI will stop asking that onboarding follow-up.');
      },
    );
  }

  Future<void> _handleCorrectionFollowUpAnswer(
    BuildContext context,
    UserGovernedLearningCorrectionFollowUpPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _correctionFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot capture that correction follow-up from this device yet.',
      );
      return;
    }
    final responseText = await _promptForFollowUpResponse(
      context,
      title: 'Correction follow-up',
      promptQuestion: plan.promptQuestion,
      supportingText: 'Earlier correction: ${plan.correctionText}',
    );
    if (responseText == null) {
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'answer',
      onRun: () => planner.completePlanWithResponse(
        ownerUserId: ownerUserId,
        planId: plan.planId,
        responseText: responseText,
        sourceSurface: 'data_center_follow_up_queue',
      ),
      onSuccess: (_) {
        _showSnackBar('Bounded correction follow-up captured.');
      },
    );
  }

  Future<void> _handleCorrectionFollowUpLater(
    UserGovernedLearningCorrectionFollowUpPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _correctionFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar('AVRAI cannot defer that follow-up from this device yet.');
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'later',
      onRun: () => planner.deferPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('Correction follow-up deferred.');
      },
    );
  }

  Future<void> _handleCorrectionFollowUpDismiss(
    UserGovernedLearningCorrectionFollowUpPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _correctionFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot dismiss that follow-up from this device yet.',
      );
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'dismiss',
      onRun: () => planner.dismissPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('Correction follow-up dismissed.');
      },
    );
  }

  Future<void> _handleCorrectionFollowUpDontAskAgain(
    UserGovernedLearningCorrectionFollowUpPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _correctionFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot update that follow-up preference from this device yet.',
      );
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'dont_ask_again',
      onRun: () => planner.dontAskAgainForPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('AVRAI will stop asking that correction follow-up.');
      },
    );
  }

  Future<void> _handleVisitLocalityFollowUpAnswer(
    BuildContext context,
    VisitLocalityFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _visitLocalityFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot capture that behavior follow-up from this device yet.',
      );
      return;
    }
    final responseText = await _promptForFollowUpResponse(
      context,
      title: 'Behavior follow-up',
      promptQuestion: plan.promptQuestion,
      supportingText:
          'Observed ${plan.observationKind} around ${plan.targetLabel}.',
    );
    if (responseText == null) {
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'answer',
      onRun: () => planner.completePlanWithResponse(
        ownerUserId: ownerUserId,
        planId: plan.planId,
        responseText: responseText,
        sourceSurface: 'data_center_follow_up_queue',
      ),
      onSuccess: (_) {
        _showSnackBar('Bounded behavior follow-up captured.');
      },
    );
  }

  Future<void> _handleCommunityFollowUpAnswer(
    BuildContext context,
    CommunityFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _communityFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot capture that community follow-up from this device yet.',
      );
      return;
    }
    final responseText = await _promptForFollowUpResponse(
      context,
      title: 'Community follow-up',
      promptQuestion: plan.promptQuestion,
      supportingText:
          'Earlier ${plan.followUpKind} signal around ${plan.targetLabel}.',
    );
    if (responseText == null) {
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'answer',
      onRun: () => planner.completePlanWithResponse(
        ownerUserId: ownerUserId,
        planId: plan.planId,
        responseText: responseText,
        sourceSurface: 'data_center_follow_up_queue',
      ),
      onSuccess: (_) {
        _showSnackBar('Bounded community follow-up captured.');
      },
    );
  }

  Future<void> _handleVisitLocalityFollowUpLater(
    VisitLocalityFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _visitLocalityFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar('AVRAI cannot defer that follow-up from this device yet.');
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'later',
      onRun: () => planner.deferPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('Behavior follow-up deferred.');
      },
    );
  }

  Future<void> _handleCommunityFollowUpLater(
    CommunityFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _communityFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar('AVRAI cannot defer that follow-up from this device yet.');
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'later',
      onRun: () => planner.deferPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('Community follow-up deferred.');
      },
    );
  }

  Future<void> _handleVisitLocalityFollowUpDismiss(
    VisitLocalityFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _visitLocalityFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot dismiss that follow-up from this device yet.',
      );
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'dismiss',
      onRun: () => planner.dismissPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('Behavior follow-up dismissed.');
      },
    );
  }

  Future<void> _handleVisitLocalityFollowUpDontAskAgain(
    VisitLocalityFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _visitLocalityFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot update that follow-up preference from this device yet.',
      );
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'dont_ask_again',
      onRun: () => planner.dontAskAgainForPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('AVRAI will stop asking that behavior follow-up.');
      },
    );
  }

  Future<void> _handleCommunityFollowUpDismiss(
    CommunityFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _communityFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot dismiss that follow-up from this device yet.',
      );
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'dismiss',
      onRun: () => planner.dismissPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('Community follow-up dismissed.');
      },
    );
  }

  Future<void> _handleCommunityFollowUpDontAskAgain(
    CommunityFollowUpPromptPlan plan,
  ) async {
    final ownerUserId = _currentUserId;
    final planner = _communityFollowUpPlannerService;
    if (ownerUserId == null || planner == null) {
      _showSnackBar(
        'AVRAI cannot update that follow-up preference from this device yet.',
      );
      return;
    }
    await _runRecordAction(
      envelopeId: plan.planId,
      action: 'dont_ask_again',
      onRun: () => planner.dontAskAgainForPlan(
        ownerUserId: ownerUserId,
        planId: plan.planId,
      ),
      onSuccess: (_) {
        _showSnackBar('AVRAI will stop asking that community follow-up.');
      },
    );
  }

  Future<void> _runRecordAction<T>({
    required String envelopeId,
    required String action,
    required Future<T> Function() onRun,
    required void Function(T result) onSuccess,
  }) async {
    setState(() {
      _busyActionKey = '$envelopeId:$action';
    });
    try {
      final result = await onRun();
      onSuccess(result);
      await _reload();
    } catch (error, stackTrace) {
      developer.log(
        'Failed record action: $action',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      _showSnackBar('AVRAI could not complete that action right now.');
    } finally {
      if (mounted) {
        setState(() {
          _busyActionKey = null;
        });
      }
    }
  }

  Future<String?> _promptForCorrection(
    BuildContext context,
    UserVisibleGovernedLearningRecord record,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Correct this record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What should AVRAI change about this learning record?',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                record.safeSummary,
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Describe the correction',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Submit correction'),
          ),
        ],
      ),
    );
    _disposeControllerAfterFrame(controller);
    if (result == null || result.trim().isEmpty) {
      return null;
    }
    return result.trim();
  }

  Future<String?> _promptForFollowUpResponse(
    BuildContext context, {
    required String title,
    required String promptQuestion,
    String? supportingText,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                promptQuestion,
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              if (supportingText?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Text(
                  supportingText!.trim(),
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Describe the scope or situation',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    _disposeControllerAfterFrame(controller);
    if (result == null || result.trim().isEmpty) {
      return null;
    }
    return result.trim();
  }

  void _disposeControllerAfterFrame(TextEditingController controller) {
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      controller.dispose();
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _jumpToRecord(String envelopeId) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _highlightedRecordEnvelopeId = envelopeId;
    });
    final recordContext = _recordKeyFor(envelopeId).currentContext;
    if (recordContext == null) {
      _showSnackBar(
          'AVRAI could not locate that governed record on this page.');
      return;
    }
    await Scrollable.ensureVisible(
      recordContext,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  void _maybeApplyInitialFocus(
      List<UserVisibleGovernedLearningRecord> records) {
    if (_initialFocusApplied || records.isEmpty) {
      return;
    }
    final focusTarget = _resolveFocusedRecord(records);
    _initialFocusApplied = true;
    if (focusTarget == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToRecord(focusTarget.envelopeId);
    });
  }

  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return null;
    }
    return authState.user.id;
  }

  Widget _buildTokenSection(
    BuildContext context, {
    required String title,
    required List<String> values,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => Chip(
                  label: Text(value),
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildMetricChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required String label,
    required IconData icon,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildMessageState({
    required String title,
    required String body,
    bool includeScaffold = true,
  }) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    if (!includeScaffold) {
      return content;
    }
    return content;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().add_jm().format(dateTime.toLocal());
  }

  String _humanizeConvictionTier(String value) {
    switch (value) {
      case 'personal_agent_human_observation':
        return 'personal human observation';
      case 'explicit_correction_signal':
        return 'explicit correction signal';
      case 'recommendation_feedback_correction_signal':
        return 'recommendation feedback correction';
      case 'ai2ai_peer_signal':
        return 'AI2AI peer signal';
      case 'ai2ai_explicit_correction_signal':
        return 'AI2AI explicit correction';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  String _humanizeAdoptionStatus(
    GovernedLearningAdoptionStatus status, {
    List<String> pendingSurfaces = const <String>[],
    List<String> surfacedSurfaces = const <String>[],
  }) {
    switch (status) {
      case GovernedLearningAdoptionStatus.acceptedForLearning:
        return 'accepted into governed learning';
      case GovernedLearningAdoptionStatus.queuedForSurfaceRefresh:
        final surface = pendingSurfaces.isEmpty
            ? null
            : _humanizeLearningSurface(pendingSurfaces.first);
        return surface == null
            ? 'queued for surfaced use'
            : 'queued for $surface';
      case GovernedLearningAdoptionStatus.firstSurfacedOnSurface:
        final surface = surfacedSurfaces.isEmpty
            ? null
            : _humanizeLearningSurface(surfacedSurfaces.first);
        return surface == null
            ? 'active in surfaced recommendations'
            : 'active in $surface';
    }
  }

  IconData _iconForAdoptionStatus(GovernedLearningAdoptionStatus status) {
    switch (status) {
      case GovernedLearningAdoptionStatus.acceptedForLearning:
        return Icons.check_circle_outline;
      case GovernedLearningAdoptionStatus.queuedForSurfaceRefresh:
        return Icons.schedule_outlined;
      case GovernedLearningAdoptionStatus.firstSurfacedOnSurface:
        return Icons.auto_graph_outlined;
    }
  }

  GovernedLearningChatObservationGovernanceStatus? _latestGovernanceStatus(
    UserVisibleGovernedLearningRecord record,
  ) {
    for (final observation in record.recentChatObservations) {
      if (observation.governanceStatus !=
          GovernedLearningChatObservationGovernanceStatus.pending) {
        return observation.governanceStatus;
      }
    }
    return null;
  }

  String _humanizeGovernanceStatus(
    GovernedLearningChatObservationGovernanceStatus status,
  ) {
    switch (status) {
      case GovernedLearningChatObservationGovernanceStatus.pending:
        return 'governance pending';
      case GovernedLearningChatObservationGovernanceStatus
            .reinforcedByGovernance:
        return 'hierarchy reinforced';
      case GovernedLearningChatObservationGovernanceStatus
            .constrainedByGovernance:
        return 'hierarchy constrained';
      case GovernedLearningChatObservationGovernanceStatus
            .overruledByGovernance:
        return 'hierarchy overruled';
    }
  }

  IconData _iconForGovernanceStatus(
    GovernedLearningChatObservationGovernanceStatus status,
  ) {
    switch (status) {
      case GovernedLearningChatObservationGovernanceStatus.pending:
        return Icons.hourglass_empty_outlined;
      case GovernedLearningChatObservationGovernanceStatus
            .reinforcedByGovernance:
        return Icons.gavel_outlined;
      case GovernedLearningChatObservationGovernanceStatus
            .constrainedByGovernance:
        return Icons.rule_outlined;
      case GovernedLearningChatObservationGovernanceStatus
            .overruledByGovernance:
        return Icons.cancel_outlined;
    }
  }

  String _humanizeLearningSurface(String surface) {
    switch (surface.trim()) {
      case 'events_personalized':
        return 'personalized events';
      case 'explore_events':
        return 'explore events';
      case 'explore_spots':
        return 'explore spots';
      default:
        return surface.replaceAll('_', ' ');
    }
  }

  String _buildAdoptionSummary(UserVisibleGovernedLearningRecord record) {
    if (record.futureSignalUseBlocked) {
      return 'Future matching signals are blocked, so this record remains visible for inspection without further learning expansion.';
    }
    final inactive = _inactiveLearningSurfaces(record)
        .map(_humanizeLearningSurface)
        .toList(growable: false);
    if (record.surfacedSurfaces.isNotEmpty) {
      final surfaced = _joinHumanList(
        record.surfacedSurfaces.map(_humanizeLearningSurface).toList(),
      );
      final pending = record.pendingSurfaces.isEmpty
          ? null
          : _joinHumanList(
              record.pendingSurfaces.map(_humanizeLearningSurface).toList(),
            );
      if (record.lastUsedAtUtc != null) {
        final tail = <String>[
          if (pending != null) 'It is also queued for $pending.',
          if (inactive.isNotEmpty)
            'It is not yet active in ${_joinHumanList(inactive)}.',
        ].join(' ');
        return 'This record is active in $surfaced. Last visible use: ${_formatDateTime(record.lastUsedAtUtc!)}.${tail.isEmpty ? '' : ' $tail'}';
      }
      final tail = <String>[
        if (pending != null) 'It is also queued for $pending.',
        if (inactive.isNotEmpty)
          'It is not yet active in ${_joinHumanList(inactive)}.',
      ].join(' ');
      return 'This record is active in $surfaced.${tail.isEmpty ? '' : ' $tail'}';
    }
    if (record.pendingSurfaces.isNotEmpty) {
      final pending = _joinHumanList(
        record.pendingSurfaces.map(_humanizeLearningSurface).toList(),
      );
      final inactiveTail = inactive.isNotEmpty
          ? ' It is not yet active in ${_joinHumanList(inactive)}.'
          : '';
      return 'This record has been accepted and is queued for $pending. You should notice the effect there once that surface refreshes.$inactiveTail';
    }
    if (record.currentAdoptionStatus ==
        GovernedLearningAdoptionStatus.acceptedForLearning) {
      final inactiveTail = inactive.isNotEmpty
          ? ' It is not yet active in ${_joinHumanList(inactive)}.'
          : '';
      return 'This record has been accepted into governed learning, but no surfaced recommendation lane is queued for it yet.$inactiveTail';
    }
    if (record.usageCount > 0) {
      return record.lastUsedAtUtc == null
          ? 'This record has already influenced surfaced recommendations.'
          : 'This record has already influenced surfaced recommendations. Last visible use: ${_formatDateTime(record.lastUsedAtUtc!)}.';
    }
    return 'This specific record has not shown up in a surfaced recommendation yet.';
  }

  String? _buildGovernanceSummary(UserVisibleGovernedLearningRecord record) {
    for (final observation in record.recentChatObservations) {
      if (observation.governanceStatus ==
          GovernedLearningChatObservationGovernanceStatus.pending) {
        continue;
      }
      final stage = _humanizeGovernanceStage(observation.governanceStage);
      final stageTail = stage == null ? '' : ' during $stage';
      switch (observation.governanceStatus) {
        case GovernedLearningChatObservationGovernanceStatus.pending:
          continue;
        case GovernedLearningChatObservationGovernanceStatus
              .reinforcedByGovernance:
          return 'A later governance review reinforced this record$stageTail.';
        case GovernedLearningChatObservationGovernanceStatus
              .constrainedByGovernance:
          return 'A later governance review constrained this record$stageTail and held it for more evidence.';
        case GovernedLearningChatObservationGovernanceStatus
              .overruledByGovernance:
          return 'A later governance review overruled broader integration for this record$stageTail.';
      }
    }
    return null;
  }

  String? _humanizeGovernanceStage(String? stage) {
    switch ((stage ?? '').trim()) {
      case 'upward_learning_review':
        return 'upward learning review';
      case 'reality_model_truth_review':
        return 'reality-model truth review';
      case 'reality_model_update_review':
        return 'bounded reality-model update review';
      default:
        final normalized = (stage ?? '').trim();
        if (normalized.isEmpty) {
          return null;
        }
        return normalized.replaceAll('_', ' ');
    }
  }

  List<String> _inactiveLearningSurfaces(
    UserVisibleGovernedLearningRecord record,
  ) {
    final activeOrPending = <String>{
      ...record.surfacedSurfaces.map((surface) => surface.trim()),
      ...record.pendingSurfaces.map((surface) => surface.trim()),
    };
    return _knownSurfacedRecommendationLanes
        .where((surface) => !activeOrPending.contains(surface.trim()))
        .toList(growable: false);
  }

  String _joinHumanList(List<String> values) {
    final filtered = values
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (filtered.isEmpty) {
      return '';
    }
    if (filtered.length == 1) {
      return filtered.first;
    }
    if (filtered.length == 2) {
      return '${filtered.first} and ${filtered.last}';
    }
    return '${filtered.sublist(0, filtered.length - 1).join(', ')}, and ${filtered.last}';
  }

  String _humanizeFeedbackAction(RecommendationFeedbackAction action) {
    switch (action) {
      case RecommendationFeedbackAction.save:
        return 'saved';
      case RecommendationFeedbackAction.dismiss:
        return 'dismissed';
      case RecommendationFeedbackAction.moreLikeThis:
        return 'asked for more like this';
      case RecommendationFeedbackAction.lessLikeThis:
        return 'asked for less like this';
      case RecommendationFeedbackAction.whyDidYouShowThis:
        return 'asked why this was shown';
      case RecommendationFeedbackAction.meaningful:
        return 'marked meaningful';
      case RecommendationFeedbackAction.fun:
        return 'marked fun';
      case RecommendationFeedbackAction.opened:
        return 'opened';
    }
  }

  GlobalKey _recordKeyFor(String envelopeId) {
    return _recordKeys.putIfAbsent(
      envelopeId,
      () => GlobalKey(debugLabel: 'data-center-record-$envelopeId'),
    );
  }

  String? _routePathForEntity(DiscoveryEntityReference entity) {
    final routePath = entity.routePath?.trim();
    if (routePath?.isNotEmpty ?? false) {
      return routePath;
    }
    final entityId = entity.id.trim();
    if (entityId.isEmpty) {
      return null;
    }
    switch (entity.type) {
      case DiscoveryEntityType.spot:
        return '/spot/$entityId';
      case DiscoveryEntityType.list:
        return '/list/$entityId';
      case DiscoveryEntityType.event:
        return '/event/$entityId';
      case DiscoveryEntityType.club:
        return '/club/$entityId';
      case DiscoveryEntityType.community:
        return '/community/$entityId';
    }
  }

  UserVisibleGovernedLearningRecord? _findRelatedRecordForFeedback(
    RecommendationFeedbackEvent event,
    List<UserVisibleGovernedLearningRecord> records,
  ) {
    final normalizedTitle = _normalizeLedgerText(event.entity.title);
    final normalizedSurface = _normalizeLedgerText(event.sourceSurface);
    final normalizedRecommendationSource = _normalizeLedgerText(
      event.attribution?.recommendationSource ?? '',
    );
    UserVisibleGovernedLearningRecord? bestMatch;
    var bestScore = 0;
    for (final record in records) {
      var score = 0;
      if (record.referencedEntities.any(
        (value) => _normalizeLedgerText(value) == normalizedTitle,
      )) {
        score += 10;
      }
      if (_normalizeLedgerText(record.safeSummary).contains(normalizedTitle)) {
        score += 6;
      }
      if (_normalizeLedgerText(record.title).contains(normalizedTitle)) {
        score += 4;
      }
      if (_normalizeLedgerText(record.sourceProvider)
          .contains('recommendation_feedback')) {
        score += 3;
      }
      if (_normalizeLedgerText(record.sourceLabel).contains('recommendation')) {
        score += 2;
      }
      if (normalizedRecommendationSource.isNotEmpty &&
          _normalizeLedgerText(record.safeSummary)
              .contains(normalizedRecommendationSource)) {
        score += 1;
      }
      if (normalizedSurface.isNotEmpty &&
          _normalizeLedgerText(record.safeSummary)
              .contains(normalizedSurface)) {
        score += 1;
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = record;
      }
    }
    return bestScore >= 6 ? bestMatch : null;
  }

  UserVisibleGovernedLearningRecord? _resolveFocusedRecord(
    List<UserVisibleGovernedLearningRecord> records,
  ) {
    final focusEnvelopeId = widget.focusEnvelopeId?.trim();
    if (focusEnvelopeId?.isNotEmpty ?? false) {
      for (final record in records) {
        if (record.envelopeId == focusEnvelopeId) {
          return record;
        }
      }
    }
    final normalizedFocusEntity = _normalizeLedgerText(
      widget.focusEntityTitle ?? '',
    );
    if (normalizedFocusEntity.isEmpty) {
      return null;
    }
    UserVisibleGovernedLearningRecord? bestMatch;
    var bestScore = 0;
    for (final record in records) {
      var score = 0;
      if (record.referencedEntities.any(
        (value) => _normalizeLedgerText(value) == normalizedFocusEntity,
      )) {
        score += 10;
      }
      if (_normalizeLedgerText(record.title).contains(normalizedFocusEntity)) {
        score += 6;
      }
      if (_normalizeLedgerText(record.safeSummary)
          .contains(normalizedFocusEntity)) {
        score += 4;
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = record;
      }
    }
    return bestScore >= 4 ? bestMatch : null;
  }

  String _normalizeLedgerText(String value) {
    return value.trim().toLowerCase();
  }

  String? _preferredAttributionContext(RecommendationAttribution? attribution) {
    if (attribution == null) {
      return null;
    }
    final headline = attribution.why.trim();
    final details = (attribution.whyDetails ?? '').trim();
    if (_isEvidenceBackedExplanation(headline)) {
      return headline;
    }
    if (details.isNotEmpty) {
      return details;
    }
    return headline.isEmpty ? null : headline;
  }

  bool _isEvidenceBackedExplanation(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return normalized.startsWith('a recent signal that ') ||
        normalized.startsWith('a recent ') &&
            (normalized.contains('boosted this recommendation') ||
                normalized.contains('helped boost this spot'));
  }
}

class _DataCenterLoadResult {
  const _DataCenterLoadResult({
    this.explanation = const UserGovernedLearningExplanation(summary: ''),
    this.pendingOnboardingFollowUpPlans =
        const <OnboardingFollowUpPromptPlan>[],
    this.pendingCorrectionFollowUpPlans =
        const <UserGovernedLearningCorrectionFollowUpPlan>[],
    this.pendingCommunityFollowUpPlans = const <CommunityFollowUpPromptPlan>[],
    this.pendingVisitLocalityFollowUpPlans =
        const <VisitLocalityFollowUpPromptPlan>[],
    this.feedbackEvents = const <RecommendationFeedbackEvent>[],
    this.isAuthenticated = false,
    this.serviceAvailable = false,
  });

  const _DataCenterLoadResult.unauthenticated()
      : explanation = const UserGovernedLearningExplanation(summary: ''),
        pendingOnboardingFollowUpPlans = const <OnboardingFollowUpPromptPlan>[],
        pendingCorrectionFollowUpPlans =
            const <UserGovernedLearningCorrectionFollowUpPlan>[],
        pendingCommunityFollowUpPlans = const <CommunityFollowUpPromptPlan>[],
        pendingVisitLocalityFollowUpPlans =
            const <VisitLocalityFollowUpPromptPlan>[],
        feedbackEvents = const <RecommendationFeedbackEvent>[],
        isAuthenticated = false,
        serviceAvailable = true;

  const _DataCenterLoadResult.unavailable()
      : explanation = const UserGovernedLearningExplanation(summary: ''),
        pendingOnboardingFollowUpPlans = const <OnboardingFollowUpPromptPlan>[],
        pendingCorrectionFollowUpPlans =
            const <UserGovernedLearningCorrectionFollowUpPlan>[],
        pendingCommunityFollowUpPlans = const <CommunityFollowUpPromptPlan>[],
        pendingVisitLocalityFollowUpPlans =
            const <VisitLocalityFollowUpPromptPlan>[],
        feedbackEvents = const <RecommendationFeedbackEvent>[],
        isAuthenticated = true,
        serviceAvailable = false;

  final UserGovernedLearningExplanation explanation;
  final List<OnboardingFollowUpPromptPlan> pendingOnboardingFollowUpPlans;
  final List<UserGovernedLearningCorrectionFollowUpPlan>
      pendingCorrectionFollowUpPlans;
  final List<CommunityFollowUpPromptPlan> pendingCommunityFollowUpPlans;
  final List<VisitLocalityFollowUpPromptPlan> pendingVisitLocalityFollowUpPlans;
  final List<RecommendationFeedbackEvent> feedbackEvents;
  final bool isAuthenticated;
  final bool serviceAvailable;
}
