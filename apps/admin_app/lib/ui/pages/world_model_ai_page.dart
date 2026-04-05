import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_admin_app/ui/widgets/reality_model_contract_status_card.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class WorldModelAiPage extends StatefulWidget {
  const WorldModelAiPage({
    super.key,
    this.signatureHealthService,
    this.signatureHealthSnapshot,
  });

  final SignatureHealthAdminService? signatureHealthService;
  final SignatureHealthSnapshot? signatureHealthSnapshot;

  @override
  State<WorldModelAiPage> createState() => _WorldModelAiPageState();
}

class _VisibleLabTargetAlertTarget {
  const _VisibleLabTargetAlertTarget({
    required this.targetKey,
    required this.environmentId,
    required this.variantId,
    required this.alertSeverityCode,
    this.alertSnoozedUntil,
  });

  final String targetKey;
  final String environmentId;
  final String? variantId;
  final String alertSeverityCode;
  final DateTime? alertSnoozedUntil;
}

enum _VisibleLabTargetBulkAction {
  acknowledge,
  escalate,
  snooze,
  clearEscalation,
  unsnooze,
}

class _WorldModelAiPageState extends State<WorldModelAiPage> {
  static const String _reviewQueueSortPriority = 'priority';
  static const String _reviewQueueSortAlerts = 'alerts';
  static const String _reviewQueueSortProvenance = 'provenance';
  static const String _reviewQueueSortRegressing = 'regressing';
  static const String _reviewQueueSortActive = 'active';
  static const String _reviewQueueSortRecent = 'recent';

  SignatureHealthSnapshot? _signatureHealthSnapshot;
  String? _signatureHealthError;
  String? _selectedReviewQueueEnvironmentId;
  String? _selectedReviewQueueTargetKey;
  String _reviewQueueSortMode = _reviewQueueSortPriority;
  final Set<String> _acknowledgingAlertTargetKeys = <String>{};
  final Set<String> _updatingAlertStateTargetKeys = <String>{};
  _VisibleLabTargetBulkAction? _activeBulkAlertAction;

  String _relativeWindowFromSnapshot(DateTime reference, DateTime target) {
    final delta = target.difference(reference).abs();
    if (delta.inMinutes < 60) {
      final minutes = delta.inMinutes <= 0 ? 1 : delta.inMinutes;
      return '${minutes}m';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours}h';
    }
    if (delta.inDays < 7) {
      return '${delta.inDays}d';
    }
    return '7d+';
  }

  String? _relativeAlertStateLabel(
    DateTime? timestamp,
    DateTime? snapshotGeneratedAt, {
    required bool future,
  }) {
    if (timestamp == null || snapshotGeneratedAt == null) {
      return null;
    }
    final window = _relativeWindowFromSnapshot(
      snapshotGeneratedAt.toUtc(),
      timestamp.toUtc(),
    );
    return future
        ? '$window after this snapshot'
        : '$window before this snapshot';
  }

  @override
  void initState() {
    super.initState();
    _signatureHealthSnapshot = widget.signatureHealthSnapshot;
    if (_signatureHealthSnapshot == null) {
      _loadSignatureHealthSnapshot();
    }
  }

  Future<void> _loadSignatureHealthSnapshot() async {
    final service = _signatureHealthService();
    if (service == null) {
      return;
    }
    try {
      final snapshot = await service.getSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthSnapshot = snapshot;
        _signatureHealthError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthError = error.toString();
      });
    }
  }

  SignatureHealthAdminService? _signatureHealthService() =>
      widget.signatureHealthService ??
      (GetIt.instance.isRegistered<SignatureHealthAdminService>()
          ? GetIt.instance<SignatureHealthAdminService>()
          : null);

  Future<void> _acknowledgeLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
    required String alertSeverityCode,
  }) async {
    final service = _signatureHealthService();
    if (service == null) {
      return;
    }
    setState(() {
      _acknowledgingAlertTargetKeys.add(targetKey);
    });
    try {
      final snapshot = await service.acknowledgeLabTargetAlert(
        environmentId: environmentId,
        variantId: variantId,
        alertSeverityCode: alertSeverityCode,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthSnapshot = snapshot;
        _signatureHealthError = null;
        _acknowledgingAlertTargetKeys.remove(targetKey);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthError = error.toString();
        _acknowledgingAlertTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _escalateLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
    required String alertSeverityCode,
  }) async {
    final service = _signatureHealthService();
    if (service == null) {
      return;
    }
    setState(() {
      _updatingAlertStateTargetKeys.add(targetKey);
    });
    try {
      final snapshot = await service.escalateLabTargetAlert(
        environmentId: environmentId,
        variantId: variantId,
        alertSeverityCode: alertSeverityCode,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthSnapshot = snapshot;
        _signatureHealthError = null;
        _updatingAlertStateTargetKeys.remove(targetKey);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthError = error.toString();
        _updatingAlertStateTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _snoozeLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
    required String alertSeverityCode,
  }) async {
    final service = _signatureHealthService();
    if (service == null) {
      return;
    }
    setState(() {
      _updatingAlertStateTargetKeys.add(targetKey);
    });
    try {
      final snapshot = await service.snoozeLabTargetAlert(
        environmentId: environmentId,
        variantId: variantId,
        alertSeverityCode: alertSeverityCode,
        snoozedUntilUtc: DateTime.now().toUtc().add(const Duration(hours: 24)),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthSnapshot = snapshot;
        _signatureHealthError = null;
        _updatingAlertStateTargetKeys.remove(targetKey);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthError = error.toString();
        _updatingAlertStateTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _clearEscalatedLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
  }) async {
    final service = _signatureHealthService();
    if (service == null) {
      return;
    }
    setState(() {
      _updatingAlertStateTargetKeys.add(targetKey);
    });
    try {
      final snapshot = await service.clearEscalatedLabTargetAlert(
        environmentId: environmentId,
        variantId: variantId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthSnapshot = snapshot;
        _signatureHealthError = null;
        _updatingAlertStateTargetKeys.remove(targetKey);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthError = error.toString();
        _updatingAlertStateTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _unsnoozeLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
  }) async {
    final service = _signatureHealthService();
    if (service == null) {
      return;
    }
    setState(() {
      _updatingAlertStateTargetKeys.add(targetKey);
    });
    try {
      final snapshot = await service.unsnoozeLabTargetAlert(
        environmentId: environmentId,
        variantId: variantId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthSnapshot = snapshot;
        _signatureHealthError = null;
        _updatingAlertStateTargetKeys.remove(targetKey);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthError = error.toString();
        _updatingAlertStateTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _applyBulkVisibleLabTargetAlertAction({
    required _VisibleLabTargetBulkAction action,
    required List<_VisibleLabTargetAlertTarget> targets,
  }) async {
    if (targets.isEmpty) {
      return;
    }
    final service = _signatureHealthService();
    if (service == null) {
      return;
    }
    final targetKeys = targets.map((target) => target.targetKey).toList();
    setState(() {
      _activeBulkAlertAction = action;
      switch (action) {
        case _VisibleLabTargetBulkAction.acknowledge:
          _acknowledgingAlertTargetKeys.addAll(targetKeys);
        case _VisibleLabTargetBulkAction.escalate:
        case _VisibleLabTargetBulkAction.snooze:
        case _VisibleLabTargetBulkAction.clearEscalation:
        case _VisibleLabTargetBulkAction.unsnooze:
          _updatingAlertStateTargetKeys.addAll(targetKeys);
      }
    });
    try {
      SignatureHealthSnapshot? latestSnapshot;
      for (final target in targets) {
        switch (action) {
          case _VisibleLabTargetBulkAction.acknowledge:
            latestSnapshot = await service.acknowledgeLabTargetAlert(
              environmentId: target.environmentId,
              variantId: target.variantId,
              alertSeverityCode: target.alertSeverityCode,
            );
          case _VisibleLabTargetBulkAction.escalate:
            latestSnapshot = await service.escalateLabTargetAlert(
              environmentId: target.environmentId,
              variantId: target.variantId,
              alertSeverityCode: target.alertSeverityCode,
            );
          case _VisibleLabTargetBulkAction.snooze:
            latestSnapshot = await service.snoozeLabTargetAlert(
              environmentId: target.environmentId,
              variantId: target.variantId,
              alertSeverityCode: target.alertSeverityCode,
              snoozedUntilUtc:
                  DateTime.now().toUtc().add(const Duration(hours: 24)),
            );
          case _VisibleLabTargetBulkAction.clearEscalation:
            latestSnapshot = await service.clearEscalatedLabTargetAlert(
              environmentId: target.environmentId,
              variantId: target.variantId,
            );
          case _VisibleLabTargetBulkAction.unsnooze:
            latestSnapshot = await service.unsnoozeLabTargetAlert(
              environmentId: target.environmentId,
              variantId: target.variantId,
            );
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthSnapshot = latestSnapshot ?? _signatureHealthSnapshot;
        _signatureHealthError = null;
        _activeBulkAlertAction = null;
        _acknowledgingAlertTargetKeys.removeAll(targetKeys);
        _updatingAlertStateTargetKeys.removeAll(targetKeys);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureHealthError = error.toString();
        _activeBulkAlertAction = null;
        _acknowledgingAlertTargetKeys.removeAll(targetKeys);
        _updatingAlertStateTargetKeys.removeAll(targetKeys);
      });
    }
  }

  Future<void> _acknowledgeVisibleLabTargetAlerts(
    List<_VisibleLabTargetAlertTarget> targets,
  ) async {
    await _applyBulkVisibleLabTargetAlertAction(
      action: _VisibleLabTargetBulkAction.acknowledge,
      targets: targets,
    );
  }

  Future<void> _escalateVisibleLabTargetAlerts(
    List<_VisibleLabTargetAlertTarget> targets,
  ) async {
    await _applyBulkVisibleLabTargetAlertAction(
      action: _VisibleLabTargetBulkAction.escalate,
      targets: targets,
    );
  }

  Future<void> _snoozeVisibleLabTargetAlerts(
    List<_VisibleLabTargetAlertTarget> targets,
  ) async {
    await _applyBulkVisibleLabTargetAlertAction(
      action: _VisibleLabTargetBulkAction.snooze,
      targets: targets,
    );
  }

  Future<void> _clearEscalatedVisibleLabTargetAlerts(
    List<_VisibleLabTargetAlertTarget> targets,
  ) async {
    await _applyBulkVisibleLabTargetAlertAction(
      action: _VisibleLabTargetBulkAction.clearEscalation,
      targets: targets,
    );
  }

  Future<void> _unsnoozeVisibleLabTargetAlerts(
    List<_VisibleLabTargetAlertTarget> targets,
  ) async {
    await _applyBulkVisibleLabTargetAlertAction(
      action: _VisibleLabTargetBulkAction.unsnooze,
      targets: targets,
    );
  }

  SignatureHealthLearningOutcomeItem? _latestSupervisorLearningOutcome() {
    final snapshot = _signatureHealthSnapshot;
    if (snapshot == null) {
      return null;
    }
    final items = snapshot.learningOutcomeItems
        .where((item) => item.supervisorFeedbackSummary != null)
        .toList(growable: false);
    if (items.isEmpty) {
      return null;
    }
    items.sort((left, right) {
      final leftUpdated =
          left.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightUpdated =
          right.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightUpdated.compareTo(leftUpdated);
    });
    return items.first;
  }

  List<SignatureHealthBoundedReviewCandidate> _activeBoundedReviewCandidates() {
    final snapshot = _signatureHealthSnapshot;
    if (snapshot == null || snapshot.boundedReviewCandidates.isEmpty) {
      return const <SignatureHealthBoundedReviewCandidate>[];
    }
    final items = List<SignatureHealthBoundedReviewCandidate>.from(
      snapshot.boundedReviewCandidates,
    )..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return items;
  }

  List<SignatureHealthLabTargetActionItem> _downgradedLabTargetActions() {
    final snapshot = _signatureHealthSnapshot;
    if (snapshot == null || snapshot.labTargetActionItems.isEmpty) {
      return const <SignatureHealthLabTargetActionItem>[];
    }
    final items = snapshot.labTargetActionItems
        .where((item) => !item.isBoundedReviewCandidate)
        .toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return items;
  }

  Map<String, String> _reviewQueueEnvironmentLabels(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> downgradedTargets,
  ) {
    final labels = <String, String>{};
    for (final candidate in candidates) {
      labels.putIfAbsent(candidate.environmentId, () => candidate.displayName);
    }
    for (final item in downgradedTargets) {
      labels.putIfAbsent(item.environmentId, () => item.displayName);
    }
    final sortedEntries = labels.entries.toList(growable: false)
      ..sort((left, right) {
        final labelComparison = left.value.compareTo(right.value);
        if (labelComparison != 0) {
          return labelComparison;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, String>.fromEntries(sortedEntries);
  }

  List<SignatureHealthBoundedReviewCandidate>
      _filterActiveBoundedReviewCandidates(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    String? environmentId,
  ) {
    if (environmentId == null) {
      return candidates;
    }
    return candidates
        .where((candidate) => candidate.environmentId == environmentId)
        .toList(growable: false);
  }

  List<SignatureHealthLabTargetActionItem> _filterDowngradedLabTargets(
    List<SignatureHealthLabTargetActionItem> items,
    String? environmentId,
  ) {
    if (environmentId == null) {
      return items;
    }
    return items
        .where((item) => item.environmentId == environmentId)
        .toList(growable: false);
  }

  String _boundedReviewTargetKey(
    SignatureHealthBoundedReviewCandidate candidate,
  ) {
    return '${candidate.environmentId}::${candidate.variantId ?? 'base_run'}';
  }

  String _labTargetActionTargetKey(SignatureHealthLabTargetActionItem item) {
    return '${item.environmentId}::${item.variantId ?? 'base_run'}';
  }

  Map<String, String> _reviewQueueTargetLabels(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> downgradedTargets,
  ) {
    final labels = <String, String>{};
    for (final candidate in candidates) {
      labels.putIfAbsent(
        _boundedReviewTargetKey(candidate),
        () => candidate.targetLabel,
      );
    }
    for (final item in downgradedTargets) {
      labels.putIfAbsent(
        _labTargetActionTargetKey(item),
        () => item.targetLabel,
      );
    }
    final sortedEntries = labels.entries.toList(growable: false)
      ..sort((left, right) {
        final labelComparison = left.value.compareTo(right.value);
        if (labelComparison != 0) {
          return labelComparison;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, String>.fromEntries(sortedEntries);
  }

  List<SignatureHealthBoundedReviewCandidate>
      _filterActiveBoundedReviewCandidatesByTarget(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    String? targetKey,
  ) {
    if (targetKey == null) {
      return candidates;
    }
    return candidates
        .where((candidate) => _boundedReviewTargetKey(candidate) == targetKey)
        .toList(growable: false);
  }

  List<SignatureHealthLabTargetActionItem> _filterDowngradedLabTargetsByTarget(
    List<SignatureHealthLabTargetActionItem> items,
    String? targetKey,
  ) {
    if (targetKey == null) {
      return items;
    }
    return items
        .where((item) => _labTargetActionTargetKey(item) == targetKey)
        .toList(growable: false);
  }

  List<SignatureHealthPropagationTarget> _preferredPropagationTargets(
    SignatureHealthLearningOutcomeItem learningOutcome,
  ) {
    final prioritizedTargets = learningOutcome.propagationTargets
        .where(
          (target) =>
              target.hierarchyDomainDeltaSummary != null ||
              target.personalAgentPersonalizationSummary != null,
        )
        .take(10)
        .toList(growable: false);
    if (prioritizedTargets.isNotEmpty) {
      return prioritizedTargets;
    }
    if (learningOutcome.propagationTargets.isEmpty) {
      return const <SignatureHealthPropagationTarget>[];
    }
    return <SignatureHealthPropagationTarget>[
      learningOutcome.propagationTargets.first,
    ];
  }

  String _recommendationLabel(String boundedRecommendation) {
    switch (boundedRecommendation) {
      case 'prefer_similar_reality_model_learning_candidates':
        return 'Prefer similar learning candidates';
      case 'allow_bounded_retry_with_operator_visibility':
        return 'Allow bounded retry with visibility';
      case 'review_before_similar_candidate_scheduling':
        return 'Review before similar scheduling';
      default:
        return 'Hold for operator review';
    }
  }

  String _boundedReviewOutcomeLabel(String? raw) {
    return switch (raw) {
      'accepted' => 'accepted',
      'denied' => 'denied',
      'draft' => 'draft',
      _ => 'not yet labeled',
    };
  }

  String? _boundedReviewRerunStatusLabel(
    SignatureHealthBoundedReviewCandidate candidate,
  ) {
    final jobStatus = candidate.latestRerunJobStatus;
    if (jobStatus != null && jobStatus.isNotEmpty) {
      return switch (jobStatus) {
        'queued' => 'job queued',
        'running' => 'job running',
        'completed' => 'job completed',
        'failed' => 'job failed',
        _ => jobStatus,
      };
    }
    final requestStatus = candidate.latestRerunRequestStatus;
    if (requestStatus != null && requestStatus.isNotEmpty) {
      return switch (requestStatus) {
        'queued' => 'request queued',
        'running' => 'request running',
        'completed' => 'request completed',
        'failed' => 'request failed',
        _ => requestStatus,
      };
    }
    return null;
  }

  String _labTargetActionLabel(String raw) {
    return switch (raw) {
      'keep_iterating' => 'keep iterating',
      'watch_closely' => 'watch closely',
      'candidate_for_bounded_review' => 'candidate for bounded review',
      _ => raw.replaceAll('_', ' '),
    };
  }

  String? _labTargetActionRerunStatusLabel(
    SignatureHealthLabTargetActionItem item,
  ) {
    final jobStatus = item.latestRerunJobStatus;
    if (jobStatus != null && jobStatus.isNotEmpty) {
      return switch (jobStatus) {
        'queued' => 'job queued',
        'running' => 'job running',
        'completed' => 'job completed',
        'failed' => 'job failed',
        _ => jobStatus,
      };
    }
    final requestStatus = item.latestRerunRequestStatus;
    if (requestStatus != null && requestStatus.isNotEmpty) {
      return switch (requestStatus) {
        'queued' => 'request queued',
        'running' => 'request running',
        'completed' => 'request completed',
        'failed' => 'request failed',
        _ => requestStatus,
      };
    }
    return null;
  }

  String _labTargetActionDecisionMode(SignatureHealthLabTargetActionItem item) {
    return item.acceptedSuggestion
        ? 'accepted the suggested route'
        : 'overrode the suggested route';
  }

  int _labTrendSeverityRank(String? severityCode) {
    return switch (severityCode) {
      'regressing' => 0,
      'mixed' => 1,
      'low_confidence' => 2,
      'no_evidence' => 3,
      'stable' => 4,
      'improving' => 5,
      _ => 6,
    };
  }

  int _labTargetActionRank(String action) {
    return switch (action) {
      'candidate_for_bounded_review' => 0,
      'watch_closely' => 1,
      'keep_iterating' => 2,
      _ => 3,
    };
  }

  int _labTargetCompletedRerunCount(
    SignatureHealthLabTargetTrendSummary? summary,
  ) =>
      summary?.completedRerunCount ?? 0;

  String _reviewQueueSortModeLabel(String mode) {
    return switch (mode) {
      _reviewQueueSortPriority => 'Priority',
      _reviewQueueSortAlerts => 'Bounded alerts',
      _reviewQueueSortProvenance => 'Provenance churn',
      _reviewQueueSortRegressing => 'Most regressing',
      _reviewQueueSortActive => 'Most active',
      _reviewQueueSortRecent => 'Recently changed',
      _ => mode,
    };
  }

  String _labTrendSeverityLabel(String? severityCode) {
    return switch (severityCode) {
      'regressing' => 'regressing',
      'mixed' => 'mixed drift',
      'low_confidence' => 'low confidence',
      'no_evidence' => 'no evidence',
      'stable' => 'stable',
      'improving' => 'improving',
      _ => 'unknown',
    };
  }

  int _labProvenanceChurnRank(
    SignatureHealthLabTargetProvenanceEmphasisSummary? summary,
  ) {
    return switch (summary?.severityCode) {
      'high_churn' => 0,
      'elevated_churn' => 1,
      'targeted_change' => 2,
      'stable' => 3,
      _ => 4,
    };
  }

  String? _labProvenanceChurnLabel(
    SignatureHealthLabTargetProvenanceEmphasisSummary? summary,
  ) {
    return switch (summary?.severityCode) {
      'high_churn' => 'high',
      'elevated_churn' => 'elevated',
      'targeted_change' => 'targeted',
      'stable' => 'stable',
      _ => null,
    };
  }

  int _labBoundedAlertRank(
    SignatureHealthLabTargetBoundedAlertSummary? summary,
  ) {
    return switch (summary?.severityCode) {
      'spiking' => 0,
      'elevated' => 1,
      'watch' => 2,
      _ => 3,
    };
  }

  String? _labBoundedAlertLabel(
    SignatureHealthLabTargetBoundedAlertSummary? summary,
  ) {
    return switch (summary?.severityCode) {
      'spiking' => 'spiking',
      'elevated' => 'elevated',
      'watch' => 'watch',
      _ => null,
    };
  }

  String _servedBasisStatusLabel(String raw) {
    return switch (raw) {
      'replay_grounded_seed_basis' => 'replay-grounded seed basis',
      'latest_state_served_basis' => 'latest-state served basis',
      'expired_latest_state_served_basis' =>
        'expired latest-state served basis',
      'latest_state_basis_served_revalidated' =>
        'latest-state basis served and revalidated',
      'latest_state_basis_served_expired' =>
        'latest-state served basis expired',
      'expired_basis_ready_for_restore_review' =>
        'expired basis ready for restore review',
      'expired_basis_restage_required_confirmed' =>
        'expired basis restage required confirmed',
      'latest_state_basis_restored_after_review' =>
        'latest-state basis restored after review',
      'ready_for_bounded_served_basis_restore' =>
        'ready for bounded served-basis restore',
      'restage_required_before_served_basis_reuse' =>
        'restage required before served-basis reuse',
      'restage_required_confirmed' => 'restage required confirmed',
      'restored_after_review' => 'restored after review',
      'served_basis_revalidated_current' => 'served basis revalidated current',
      _ => raw.replaceAll('_', ' '),
    };
  }

  String? _servedBasisRecoveryAttention(
    SignatureHealthServedBasisSummary summary,
  ) {
    if (summary.latestStatePromotionReadiness ==
        'ready_for_bounded_served_basis_restore') {
      return 'served_basis_recovery:restore_review';
    }
    if (summary.latestStateRecoveryDecisionStatus ==
            'restage_required_confirmed' ||
        summary.latestStatePromotionReadiness ==
            'restage_required_before_served_basis_reuse') {
      return 'served_basis_recovery:restage_required';
    }
    return null;
  }

  String _evidenceFamilyLabel(String raw) {
    return switch (raw) {
      'app_observations' => 'app observations',
      'runtime_os_locality_state' => 'runtime/OS locality state',
      'governed_reality_model_outputs' => 'governed reality-model outputs',
      _ => raw.replaceAll('_', ' '),
    };
  }

  List<SignatureHealthServedBasisSummary> _filterServedBasisSummaries(
    List<SignatureHealthServedBasisSummary> summaries,
    String? environmentId,
  ) {
    if (environmentId == null) {
      return summaries;
    }
    return summaries
        .where((summary) => summary.environmentId == environmentId)
        .toList(growable: false);
  }

  List<SignatureHealthFamilyRestageIntakeReviewSummary>
      _filterFamilyRestageIntakeReviewSummaries(
    List<SignatureHealthFamilyRestageIntakeReviewSummary> summaries,
    String? environmentId,
  ) {
    if (environmentId == null) {
      return summaries;
    }
    return summaries
        .where((summary) => summary.environmentId == environmentId)
        .toList(growable: false);
  }

  List<SignatureHealthBoundedReviewCandidate>
      _rankActiveBoundedReviewCandidates(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    String sortMode,
  ) {
    final ranked = List<SignatureHealthBoundedReviewCandidate>.from(candidates);
    ranked.sort((left, right) {
      final actionCompare = _labTargetActionRank(left.selectedAction)
          .compareTo(_labTargetActionRank(right.selectedAction));
      final trendCompare = _labTrendSeverityRank(
        left.trendSummary?.runtimeTrendSeverityCode,
      ).compareTo(
        _labTrendSeverityRank(right.trendSummary?.runtimeTrendSeverityCode),
      );
      final provenanceCompare = _labProvenanceChurnRank(
        left.provenanceEmphasisSummary,
      ).compareTo(_labProvenanceChurnRank(right.provenanceEmphasisSummary));
      final boundedAlertCompare = _labBoundedAlertRank(
        left.boundedAlertSummary,
      ).compareTo(_labBoundedAlertRank(right.boundedAlertSummary));
      final activeCompare = _labTargetCompletedRerunCount(right.trendSummary)
          .compareTo(_labTargetCompletedRerunCount(left.trendSummary));
      final recentCompare = right.updatedAt.compareTo(left.updatedAt);
      switch (sortMode) {
        case _reviewQueueSortAlerts:
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (actionCompare != 0) {
            return actionCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          if (provenanceCompare != 0) {
            return provenanceCompare;
          }
          return recentCompare;
        case _reviewQueueSortProvenance:
          if (provenanceCompare != 0) {
            return provenanceCompare;
          }
          if (actionCompare != 0) {
            return actionCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          return recentCompare;
        case _reviewQueueSortRegressing:
          if (trendCompare != 0) {
            return trendCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (actionCompare != 0) {
            return actionCompare;
          }
          return recentCompare;
        case _reviewQueueSortActive:
          if (activeCompare != 0) {
            return activeCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          if (actionCompare != 0) {
            return actionCompare;
          }
          return recentCompare;
        case _reviewQueueSortRecent:
          if (recentCompare != 0) {
            return recentCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          return actionCompare;
        case _reviewQueueSortPriority:
        default:
          if (actionCompare != 0) {
            return actionCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          if (provenanceCompare != 0) {
            return provenanceCompare;
          }
          return recentCompare;
      }
    });
    return ranked;
  }

  List<SignatureHealthLabTargetActionItem> _rankDowngradedLabTargets(
    List<SignatureHealthLabTargetActionItem> targets,
    String sortMode,
  ) {
    final ranked = List<SignatureHealthLabTargetActionItem>.from(targets);
    ranked.sort((left, right) {
      final actionCompare = _labTargetActionRank(left.selectedAction)
          .compareTo(_labTargetActionRank(right.selectedAction));
      final trendCompare = _labTrendSeverityRank(
        left.trendSummary?.runtimeTrendSeverityCode,
      ).compareTo(
        _labTrendSeverityRank(right.trendSummary?.runtimeTrendSeverityCode),
      );
      final provenanceCompare = _labProvenanceChurnRank(
        left.provenanceEmphasisSummary,
      ).compareTo(_labProvenanceChurnRank(right.provenanceEmphasisSummary));
      final boundedAlertCompare = _labBoundedAlertRank(
        left.boundedAlertSummary,
      ).compareTo(_labBoundedAlertRank(right.boundedAlertSummary));
      final activeCompare = _labTargetCompletedRerunCount(right.trendSummary)
          .compareTo(_labTargetCompletedRerunCount(left.trendSummary));
      final recentCompare = right.updatedAt.compareTo(left.updatedAt);
      switch (sortMode) {
        case _reviewQueueSortAlerts:
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (actionCompare != 0) {
            return actionCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          if (provenanceCompare != 0) {
            return provenanceCompare;
          }
          return recentCompare;
        case _reviewQueueSortProvenance:
          if (provenanceCompare != 0) {
            return provenanceCompare;
          }
          if (actionCompare != 0) {
            return actionCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          return recentCompare;
        case _reviewQueueSortRegressing:
          if (trendCompare != 0) {
            return trendCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (actionCompare != 0) {
            return actionCompare;
          }
          return recentCompare;
        case _reviewQueueSortActive:
          if (activeCompare != 0) {
            return activeCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          if (actionCompare != 0) {
            return actionCompare;
          }
          return recentCompare;
        case _reviewQueueSortRecent:
          if (recentCompare != 0) {
            return recentCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          return actionCompare;
        case _reviewQueueSortPriority:
        default:
          if (actionCompare != 0) {
            return actionCompare;
          }
          if (boundedAlertCompare != 0) {
            return boundedAlertCompare;
          }
          if (trendCompare != 0) {
            return trendCompare;
          }
          if (provenanceCompare != 0) {
            return provenanceCompare;
          }
          return recentCompare;
      }
    });
    return ranked;
  }

  String? _highestVisibleRuntimeRiskLabel(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> targets,
  ) {
    String? selectedCode;
    var selectedRank = 999;
    for (final candidate in candidates) {
      final code = candidate.trendSummary?.runtimeTrendSeverityCode;
      final rank = _labTrendSeverityRank(code);
      if (rank < selectedRank) {
        selectedRank = rank;
        selectedCode = code;
      }
    }
    for (final target in targets) {
      final code = target.trendSummary?.runtimeTrendSeverityCode;
      final rank = _labTrendSeverityRank(code);
      if (rank < selectedRank) {
        selectedRank = rank;
        selectedCode = code;
      }
    }
    if (selectedCode == null) {
      return null;
    }
    return _labTrendSeverityLabel(selectedCode);
  }

  String? _highestVisibleProvenanceChurnLabel(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> targets,
  ) {
    String? selectedCode;
    var selectedRank = 999;
    for (final candidate in candidates) {
      final code = candidate.provenanceEmphasisSummary?.severityCode;
      final rank = _labProvenanceChurnRank(candidate.provenanceEmphasisSummary);
      if (rank < selectedRank) {
        selectedRank = rank;
        selectedCode = code;
      }
    }
    for (final target in targets) {
      final code = target.provenanceEmphasisSummary?.severityCode;
      final rank = _labProvenanceChurnRank(target.provenanceEmphasisSummary);
      if (rank < selectedRank) {
        selectedRank = rank;
        selectedCode = code;
      }
    }
    return _labProvenanceChurnLabel(
      selectedCode == null
          ? null
          : SignatureHealthLabTargetProvenanceEmphasisSummary(
              severityCode: selectedCode,
              summary: '',
            ),
    );
  }

  String? _highestVisibleBoundedAlertLabel(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> targets,
  ) {
    String? selectedCode;
    var selectedRank = 999;
    for (final candidate in candidates) {
      final code = candidate.boundedAlertSummary?.severityCode;
      final rank = _labBoundedAlertRank(candidate.boundedAlertSummary);
      if (rank < selectedRank) {
        selectedRank = rank;
        selectedCode = code;
      }
    }
    for (final target in targets) {
      final code = target.boundedAlertSummary?.severityCode;
      final rank = _labBoundedAlertRank(target.boundedAlertSummary);
      if (rank < selectedRank) {
        selectedRank = rank;
        selectedCode = code;
      }
    }
    return _labBoundedAlertLabel(
      selectedCode == null
          ? null
          : SignatureHealthLabTargetBoundedAlertSummary(
              severityCode: selectedCode,
              summary: '',
            ),
    );
  }

  String _reviewQueueEscalationSummary(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> targets,
  ) {
    final visibleLaneCount = candidates.length + targets.length;
    final highestRisk = _highestVisibleRuntimeRiskLabel(candidates, targets);
    final highestProvenanceChurn = _highestVisibleProvenanceChurnLabel(
      candidates,
      targets,
    );
    final highestBoundedAlert = _highestVisibleBoundedAlertLabel(
      candidates,
      targets,
    );
    final summaryBits = <String>[
      '$visibleLaneCount visible lanes',
      '${candidates.length} active bounded review candidate${candidates.length == 1 ? '' : 's'}',
      if (highestRisk != null) 'highest runtime risk: $highestRisk',
      if (highestProvenanceChurn != null)
        'highest provenance churn: $highestProvenanceChurn',
      if (highestBoundedAlert != null)
        'highest bounded alert: $highestBoundedAlert',
      'sort: ${_reviewQueueSortModeLabel(_reviewQueueSortMode)}',
    ];
    return 'Escalation summary: ${summaryBits.join(' • ')}.';
  }

  List<_VisibleLabTargetAlertTarget> _visibleUnacknowledgedBoundedAlerts(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> targets,
  ) {
    final requests = <_VisibleLabTargetAlertTarget>[];
    for (final candidate in candidates) {
      final alert = candidate.boundedAlertSummary;
      if (alert == null || candidate.isCurrentBoundedAlertAcknowledged) {
        continue;
      }
      requests.add(
        _VisibleLabTargetAlertTarget(
          targetKey: _boundedReviewTargetKey(candidate),
          environmentId: candidate.environmentId,
          variantId: candidate.variantId,
          alertSeverityCode: alert.severityCode,
          alertSnoozedUntil: candidate.alertSnoozedUntil,
        ),
      );
    }
    for (final target in targets) {
      final alert = target.boundedAlertSummary;
      if (alert == null || target.isCurrentBoundedAlertAcknowledged) {
        continue;
      }
      requests.add(
        _VisibleLabTargetAlertTarget(
          targetKey: _labTargetActionTargetKey(target),
          environmentId: target.environmentId,
          variantId: target.variantId,
          alertSeverityCode: alert.severityCode,
          alertSnoozedUntil: target.alertSnoozedUntil,
        ),
      );
    }
    return requests;
  }

  List<_VisibleLabTargetAlertTarget> _visibleOperatorActionableBoundedAlerts(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> targets,
  ) {
    final requests = <_VisibleLabTargetAlertTarget>[];
    for (final candidate in candidates) {
      final alert = candidate.boundedAlertSummary;
      if (alert == null ||
          candidate.isCurrentBoundedAlertEscalated ||
          candidate.isCurrentBoundedAlertSnoozed) {
        continue;
      }
      requests.add(
        _VisibleLabTargetAlertTarget(
          targetKey: _boundedReviewTargetKey(candidate),
          environmentId: candidate.environmentId,
          variantId: candidate.variantId,
          alertSeverityCode: alert.severityCode,
          alertSnoozedUntil: candidate.alertSnoozedUntil,
        ),
      );
    }
    for (final target in targets) {
      final alert = target.boundedAlertSummary;
      if (alert == null ||
          target.isCurrentBoundedAlertEscalated ||
          target.isCurrentBoundedAlertSnoozed) {
        continue;
      }
      requests.add(
        _VisibleLabTargetAlertTarget(
          targetKey: _labTargetActionTargetKey(target),
          environmentId: target.environmentId,
          variantId: target.variantId,
          alertSeverityCode: alert.severityCode,
          alertSnoozedUntil: target.alertSnoozedUntil,
        ),
      );
    }
    return requests;
  }

  List<_VisibleLabTargetAlertTarget> _visibleEscalatedBoundedAlerts(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> targets,
  ) {
    final requests = <_VisibleLabTargetAlertTarget>[];
    for (final candidate in candidates) {
      final alert = candidate.boundedAlertSummary;
      if (alert == null || !candidate.isCurrentBoundedAlertEscalated) {
        continue;
      }
      requests.add(
        _VisibleLabTargetAlertTarget(
          targetKey: _boundedReviewTargetKey(candidate),
          environmentId: candidate.environmentId,
          variantId: candidate.variantId,
          alertSeverityCode: alert.severityCode,
          alertSnoozedUntil: candidate.alertSnoozedUntil,
        ),
      );
    }
    for (final target in targets) {
      final alert = target.boundedAlertSummary;
      if (alert == null || !target.isCurrentBoundedAlertEscalated) {
        continue;
      }
      requests.add(
        _VisibleLabTargetAlertTarget(
          targetKey: _labTargetActionTargetKey(target),
          environmentId: target.environmentId,
          variantId: target.variantId,
          alertSeverityCode: alert.severityCode,
          alertSnoozedUntil: target.alertSnoozedUntil,
        ),
      );
    }
    return requests;
  }

  List<_VisibleLabTargetAlertTarget> _visibleSnoozedBoundedAlerts(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> targets,
  ) {
    final requests = <_VisibleLabTargetAlertTarget>[];
    for (final candidate in candidates) {
      final alert = candidate.boundedAlertSummary;
      if (alert == null || !candidate.isCurrentBoundedAlertSnoozed) {
        continue;
      }
      requests.add(
        _VisibleLabTargetAlertTarget(
          targetKey: _boundedReviewTargetKey(candidate),
          environmentId: candidate.environmentId,
          variantId: candidate.variantId,
          alertSeverityCode: alert.severityCode,
          alertSnoozedUntil: candidate.alertSnoozedUntil,
        ),
      );
    }
    for (final target in targets) {
      final alert = target.boundedAlertSummary;
      if (alert == null || !target.isCurrentBoundedAlertSnoozed) {
        continue;
      }
      requests.add(
        _VisibleLabTargetAlertTarget(
          targetKey: _labTargetActionTargetKey(target),
          environmentId: target.environmentId,
          variantId: target.variantId,
          alertSeverityCode: alert.severityCode,
          alertSnoozedUntil: target.alertSnoozedUntil,
        ),
      );
    }
    return requests;
  }

  bool _hasVisibleBoundedAlerts(
    List<SignatureHealthBoundedReviewCandidate> candidates,
    List<SignatureHealthLabTargetActionItem> targets,
  ) {
    for (final candidate in candidates) {
      if (candidate.boundedAlertSummary != null) {
        return true;
      }
    }
    for (final target in targets) {
      if (target.boundedAlertSummary != null) {
        return true;
      }
    }
    return false;
  }

  Widget _buildVisibleBoundedAlertBulkActionRow(
    BuildContext context,
    List<_VisibleLabTargetAlertTarget> visibleTargetsNeedingAcknowledgment,
    List<_VisibleLabTargetAlertTarget> visibleTargetsNeedingOperatorState,
    List<_VisibleLabTargetAlertTarget> visibleEscalatedTargets,
    List<_VisibleLabTargetAlertTarget> visibleSnoozedTargets,
    bool hasVisibleBoundedAlerts,
    DateTime? snapshotGeneratedAt,
  ) {
    if (!hasVisibleBoundedAlerts || _signatureHealthService() == null) {
      return const SizedBox.shrink();
    }
    final acknowledgmentCount = visibleTargetsNeedingAcknowledgment.length;
    final operatorStateCount = visibleTargetsNeedingOperatorState.length;
    final escalatedCount = visibleEscalatedTargets.length;
    final snoozedCount = visibleSnoozedTargets.length;
    final nextSnoozeExpiry = visibleSnoozedTargets
        .map((target) => target.alertSnoozedUntil)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (selected, current) => selected == null || current.isBefore(selected)
              ? current
              : selected,
        );
    final hasBulkActions = acknowledgmentCount > 0 ||
        operatorStateCount > 0 ||
        escalatedCount > 0 ||
        snoozedCount > 0;
    final summary = <String>[
      if (acknowledgmentCount == 0)
        'all visible bounded alerts are already acknowledged'
      else
        '$acknowledgmentCount visible bounded alert${acknowledgmentCount == 1 ? '' : 's'} still need acknowledgment',
      if (operatorStateCount == 0)
        'all visible bounded alerts already have escalation or snooze state'
      else
        '$operatorStateCount visible bounded alert lane${operatorStateCount == 1 ? '' : 's'} still allow bulk escalate/snooze management',
      if (escalatedCount > 0)
        '$escalatedCount visible alert lane${escalatedCount == 1 ? '' : 's'} can be de-escalated',
      if (snoozedCount > 0)
        '$snoozedCount visible alert lane${snoozedCount == 1 ? '' : 's'} can be unsnoozed',
    ].join(' • ');
    final isBulkAcknowledging =
        _activeBulkAlertAction == _VisibleLabTargetBulkAction.acknowledge;
    final isBulkEscalating =
        _activeBulkAlertAction == _VisibleLabTargetBulkAction.escalate;
    final isBulkSnoozing =
        _activeBulkAlertAction == _VisibleLabTargetBulkAction.snooze;
    final isBulkClearingEscalation =
        _activeBulkAlertAction == _VisibleLabTargetBulkAction.clearEscalation;
    final isBulkUnsnoozing =
        _activeBulkAlertAction == _VisibleLabTargetBulkAction.unsnooze;
    final isBulkBusy = _activeBulkAlertAction != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          '${summary[0].toUpperCase()}${summary.substring(1)} under the current queue filters.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (escalatedCount > 0 || snoozedCount > 0) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (escalatedCount > 0)
                Chip(
                  avatar: const Icon(Icons.priority_high_outlined, size: 18),
                  label: Text(
                    escalatedCount == 1
                        ? '1 escalated visible lane'
                        : '$escalatedCount escalated visible lanes',
                  ),
                  backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                ),
              if (snoozedCount > 0)
                Chip(
                  avatar: const Icon(Icons.snooze_outlined, size: 18),
                  label: Text(
                    snoozedCount == 1
                        ? '1 snoozed visible lane'
                        : '$snoozedCount snoozed visible lanes',
                  ),
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                ),
            ],
          ),
          if (nextSnoozeExpiry != null) ...[
            const SizedBox(height: 8),
            Text(
              'Next unsnooze: ${nextSnoozeExpiry.toUtc().toIso8601String()}'
              '${_relativeAlertStateLabel(nextSnoozeExpiry, snapshotGeneratedAt, future: true) == null ? '' : ' (${_relativeAlertStateLabel(nextSnoozeExpiry, snapshotGeneratedAt, future: true)})'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
        if (hasBulkActions) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (acknowledgmentCount > 0)
                OutlinedButton.icon(
                  onPressed: isBulkBusy
                      ? null
                      : () => _acknowledgeVisibleLabTargetAlerts(
                            visibleTargetsNeedingAcknowledgment,
                          ),
                  icon: isBulkAcknowledging
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.visibility_outlined),
                  label: Text(
                    isBulkAcknowledging
                        ? 'Saving visible alert state...'
                        : acknowledgmentCount == 1
                            ? 'Mark 1 visible alert seen'
                            : 'Mark $acknowledgmentCount visible alerts seen',
                  ),
                ),
              if (operatorStateCount > 0)
                OutlinedButton.icon(
                  onPressed: isBulkBusy
                      ? null
                      : () => _escalateVisibleLabTargetAlerts(
                            visibleTargetsNeedingOperatorState,
                          ),
                  icon: isBulkEscalating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.priority_high_outlined),
                  label: Text(
                    isBulkEscalating
                        ? 'Escalating visible alert lanes...'
                        : operatorStateCount == 1
                            ? 'Escalate 1 visible alert lane'
                            : 'Escalate $operatorStateCount visible alert lanes',
                  ),
                ),
              if (operatorStateCount > 0)
                OutlinedButton.icon(
                  onPressed: isBulkBusy
                      ? null
                      : () => _snoozeVisibleLabTargetAlerts(
                            visibleTargetsNeedingOperatorState,
                          ),
                  icon: isBulkSnoozing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.snooze_outlined),
                  label: Text(
                    isBulkSnoozing
                        ? 'Snoozing visible alert lanes...'
                        : operatorStateCount == 1
                            ? 'Snooze 1 visible alert lane'
                            : 'Snooze $operatorStateCount visible alert lanes',
                  ),
                ),
              if (escalatedCount > 0)
                OutlinedButton.icon(
                  onPressed: isBulkBusy
                      ? null
                      : () => _clearEscalatedVisibleLabTargetAlerts(
                            visibleEscalatedTargets,
                          ),
                  icon: isBulkClearingEscalation
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_downward_outlined),
                  label: Text(
                    isBulkClearingEscalation
                        ? 'Clearing visible escalations...'
                        : escalatedCount == 1
                            ? 'Clear escalation on 1 visible lane'
                            : 'Clear escalation on $escalatedCount visible lanes',
                  ),
                ),
              if (snoozedCount > 0)
                OutlinedButton.icon(
                  onPressed: isBulkBusy
                      ? null
                      : () => _unsnoozeVisibleLabTargetAlerts(
                            visibleSnoozedTargets,
                          ),
                  icon: isBulkUnsnoozing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    isBulkUnsnoozing
                        ? 'Unsnoozing visible alert lanes...'
                        : snoozedCount == 1
                            ? 'Unsnooze 1 visible alert lane'
                            : 'Unsnooze $snoozedCount visible alert lanes',
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String? _labTargetTrendHistoryLabel(
    SignatureHealthLabTargetTrendSummary? summary,
  ) {
    if (summary == null) {
      return null;
    }
    if (summary.completedRerunCount <= 0) {
      return 'Lane history: no completed reruns tracked yet.';
    }
    if (summary.completedRerunCount == 1) {
      return 'Lane history: 1 completed rerun tracked.';
    }
    return 'Lane history: ${summary.completedRerunCount} completed reruns tracked.';
  }

  Widget _buildLabTargetProvenanceDeltaSection(
    BuildContext context,
    SignatureHealthLabTargetProvenanceDeltaSummary? summary,
  ) {
    if (summary == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          summary.summary,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (summary.details.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Latest provenance delta',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          ...summary.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $detail',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _labTargetProvenanceHistoryLabel(
    SignatureHealthLabTargetProvenanceHistorySummary? summary,
  ) {
    if (summary == null) {
      return null;
    }
    if (summary.sampleCount <= 0) {
      return null;
    }
    if (summary.sampleCount == 1) {
      return 'Provenance history: 1 persisted sample tracked.';
    }
    return 'Provenance history: ${summary.sampleCount} persisted samples tracked.';
  }

  Widget _buildLabTargetProvenanceHistorySection(
    BuildContext context,
    SignatureHealthLabTargetProvenanceHistorySummary? summary,
  ) {
    final historyLabel = _labTargetProvenanceHistoryLabel(summary);
    if (historyLabel == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          historyLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (summary!.entries.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Recent provenance changes',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          ...summary.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  ...entry.details.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $detail',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabTargetProvenanceEmphasisSection(
    BuildContext context,
    SignatureHealthLabTargetProvenanceEmphasisSummary? summary,
  ) {
    if (summary == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        summary.summary,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  Widget _buildLabTargetBoundedAlertSection(
    BuildContext context,
    SignatureHealthLabTargetBoundedAlertSummary? summary,
  ) {
    if (summary == null) {
      return const SizedBox.shrink();
    }
    final color = switch (summary.severityCode) {
      'spiking' => AppColors.error,
      'elevated' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        summary.summary,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildLabTargetAlertAcknowledgmentRow({
    required BuildContext context,
    required String targetKey,
    required String environmentId,
    required String? variantId,
    required SignatureHealthLabTargetBoundedAlertSummary? boundedAlertSummary,
    required bool isCurrentAlertAcknowledged,
    required DateTime? alertAcknowledgedAt,
  }) {
    if (boundedAlertSummary == null) {
      return const SizedBox.shrink();
    }
    if (isCurrentAlertAcknowledged) {
      final stamp = alertAcknowledgedAt?.toUtc().toIso8601String() ?? 'unknown';
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Alert acknowledged: $stamp',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }
    final serviceAvailable = _signatureHealthService() != null;
    final isBusy = _acknowledgingAlertTargetKeys.contains(targetKey);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            onPressed: !serviceAvailable || isBusy
                ? null
                : () => _acknowledgeLabTargetAlert(
                      targetKey: targetKey,
                      environmentId: environmentId,
                      variantId: variantId,
                      alertSeverityCode: boundedAlertSummary.severityCode,
                    ),
            avatar: isBusy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_outlined, size: 18),
            label: Text(isBusy ? 'Saving alert state...' : 'Mark alert seen'),
          ),
        ],
      ),
    );
  }

  Widget _buildLabTargetAlertOperatorStateRow({
    required BuildContext context,
    required String targetKey,
    required String environmentId,
    required String? variantId,
    required SignatureHealthLabTargetBoundedAlertSummary? boundedAlertSummary,
    required bool isCurrentAlertEscalated,
    required DateTime? alertEscalatedAt,
    required bool isCurrentAlertSnoozed,
    required DateTime? alertSnoozedUntil,
    required DateTime? snapshotGeneratedAt,
  }) {
    if (boundedAlertSummary == null) {
      return const SizedBox.shrink();
    }
    final serviceAvailable = _signatureHealthService() != null;
    final isBusy = _updatingAlertStateTargetKeys.contains(targetKey);
    if (isCurrentAlertEscalated) {
      final stamp = alertEscalatedAt?.toUtc().toIso8601String() ?? 'unknown';
      final relativeLabel = _relativeAlertStateLabel(
        alertEscalatedAt,
        snapshotGeneratedAt,
        future: false,
      );
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Alert lane escalated: $stamp'
              '${relativeLabel == null ? '' : ' ($relativeLabel)'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            ActionChip(
              onPressed: isBusy
                  ? null
                  : () => _clearEscalatedLabTargetAlert(
                        targetKey: targetKey,
                        environmentId: environmentId,
                        variantId: variantId,
                      ),
              avatar: isBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_downward_outlined, size: 18),
              label:
                  Text(isBusy ? 'Saving alert state...' : 'Clear escalation'),
            ),
          ],
        ),
      );
    }
    if (isCurrentAlertSnoozed) {
      final stamp = alertSnoozedUntil?.toUtc().toIso8601String() ?? 'unknown';
      final relativeLabel = _relativeAlertStateLabel(
        alertSnoozedUntil,
        snapshotGeneratedAt,
        future: true,
      );
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Alert snoozed until: $stamp'
              '${relativeLabel == null ? '' : ' ($relativeLabel)'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            ActionChip(
              onPressed: isBusy
                  ? null
                  : () => _unsnoozeLabTargetAlert(
                        targetKey: targetKey,
                        environmentId: environmentId,
                        variantId: variantId,
                      ),
              avatar: isBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text(isBusy ? 'Saving alert state...' : 'Unsnooze'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            onPressed: !serviceAvailable || isBusy
                ? null
                : () => _escalateLabTargetAlert(
                      targetKey: targetKey,
                      environmentId: environmentId,
                      variantId: variantId,
                      alertSeverityCode: boundedAlertSummary.severityCode,
                    ),
            avatar: isBusy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.priority_high_outlined, size: 18),
            label: Text(isBusy ? 'Saving alert state...' : 'Escalate lane'),
          ),
          ActionChip(
            onPressed: !serviceAvailable || isBusy
                ? null
                : () => _snoozeLabTargetAlert(
                      targetKey: targetKey,
                      environmentId: environmentId,
                      variantId: variantId,
                      alertSeverityCode: boundedAlertSummary.severityCode,
                    ),
            avatar: const Icon(Icons.snooze_outlined, size: 18),
            label: const Text('Snooze 24h'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBoundedReviewCandidateCard(
    BuildContext context,
    SignatureHealthBoundedReviewCandidate candidate,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${candidate.cityCode.toUpperCase()} • ${candidate.displayName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text('Target: ${candidate.targetLabel}'),
          ),
          const SizedBox(height: 12),
          Text(
            '${candidate.targetLabel} is currently an active bounded-review candidate from World Simulation Lab.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suggested reason: ${candidate.suggestedReason.isEmpty ? 'No reason recorded.' : candidate.suggestedReason}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current routing posture: ${_labTargetActionLabel(candidate.selectedAction)} • Operator ${candidate.acceptedSuggestion ? 'accepted the suggested route' : 'overrode the suggested route'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Latest lab outcome: ${_boundedReviewOutcomeLabel(candidate.latestOutcomeDisposition)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (_boundedReviewRerunStatusLabel(candidate) != null) ...[
            const SizedBox(height: 4),
            Text(
              'Latest rerun: ${_boundedReviewRerunStatusLabel(candidate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (_labTargetTrendHistoryLabel(candidate.trendSummary) != null) ...[
            const SizedBox(height: 4),
            Text(
              _labTargetTrendHistoryLabel(candidate.trendSummary)!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              candidate.trendSummary!.runtimeTrendSummary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              candidate.trendSummary!.runtimeDeltaSummary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              candidate.trendSummary!.outcomeTrendSummary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          _buildLabTargetProvenanceDeltaSection(
            context,
            candidate.provenanceDeltaSummary,
          ),
          _buildLabTargetBoundedAlertSection(
            context,
            candidate.boundedAlertSummary,
          ),
          _buildLabTargetAlertAcknowledgmentRow(
            context: context,
            targetKey: _boundedReviewTargetKey(candidate),
            environmentId: candidate.environmentId,
            variantId: candidate.variantId,
            boundedAlertSummary: candidate.boundedAlertSummary,
            isCurrentAlertAcknowledged:
                candidate.isCurrentBoundedAlertAcknowledged,
            alertAcknowledgedAt: candidate.alertAcknowledgedAt,
          ),
          _buildLabTargetAlertOperatorStateRow(
            context: context,
            targetKey: _boundedReviewTargetKey(candidate),
            environmentId: candidate.environmentId,
            variantId: candidate.variantId,
            boundedAlertSummary: candidate.boundedAlertSummary,
            isCurrentAlertEscalated: candidate.isCurrentBoundedAlertEscalated,
            alertEscalatedAt: candidate.alertEscalatedAt,
            isCurrentAlertSnoozed: candidate.isCurrentBoundedAlertSnoozed,
            alertSnoozedUntil: candidate.alertSnoozedUntil,
            snapshotGeneratedAt: _signatureHealthSnapshot?.generatedAt,
          ),
          _buildLabTargetProvenanceEmphasisSection(
            context,
            candidate.provenanceEmphasisSummary,
          ),
          _buildLabTargetProvenanceHistorySection(
            context,
            candidate.provenanceHistorySummary,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go(AdminRoutePaths.worldSimulationLab),
                icon: const Icon(Icons.science_outlined),
                label: const Text('Open World Simulation Lab'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  AdminRoutePaths.realitySystemRealityFocusLink(
                    focus: candidate.environmentId,
                    attention:
                        'bounded_review_candidate:${candidate.variantId ?? 'base_run'}',
                  ),
                ),
                icon: const Icon(Icons.psychology_alt_outlined),
                label: const Text('Open bounded review'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDowngradedLabTargetCard(
    BuildContext context,
    SignatureHealthLabTargetActionItem item,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.cityCode.toUpperCase()} • ${item.displayName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text('Target: ${item.targetLabel}'),
          ),
          const SizedBox(height: 12),
          Text(
            '${item.targetLabel} is not currently in the active bounded-review queue.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current routing posture: ${_labTargetActionLabel(item.selectedAction)} • Operator ${_labTargetActionDecisionMode(item)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Suggested reason: ${item.suggestedReason.isEmpty ? 'No reason recorded.' : item.suggestedReason}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Latest lab outcome: ${_boundedReviewOutcomeLabel(item.latestOutcomeDisposition)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (_labTargetActionRerunStatusLabel(item) != null) ...[
            const SizedBox(height: 4),
            Text(
              'Latest rerun: ${_labTargetActionRerunStatusLabel(item)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (_labTargetTrendHistoryLabel(item.trendSummary) != null) ...[
            const SizedBox(height: 4),
            Text(
              _labTargetTrendHistoryLabel(item.trendSummary)!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              item.trendSummary!.runtimeTrendSummary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              item.trendSummary!.runtimeDeltaSummary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              item.trendSummary!.outcomeTrendSummary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          _buildLabTargetProvenanceDeltaSection(
            context,
            item.provenanceDeltaSummary,
          ),
          _buildLabTargetBoundedAlertSection(
            context,
            item.boundedAlertSummary,
          ),
          _buildLabTargetAlertAcknowledgmentRow(
            context: context,
            targetKey: _labTargetActionTargetKey(item),
            environmentId: item.environmentId,
            variantId: item.variantId,
            boundedAlertSummary: item.boundedAlertSummary,
            isCurrentAlertAcknowledged: item.isCurrentBoundedAlertAcknowledged,
            alertAcknowledgedAt: item.alertAcknowledgedAt,
          ),
          _buildLabTargetAlertOperatorStateRow(
            context: context,
            targetKey: _labTargetActionTargetKey(item),
            environmentId: item.environmentId,
            variantId: item.variantId,
            boundedAlertSummary: item.boundedAlertSummary,
            isCurrentAlertEscalated: item.isCurrentBoundedAlertEscalated,
            alertEscalatedAt: item.alertEscalatedAt,
            isCurrentAlertSnoozed: item.isCurrentBoundedAlertSnoozed,
            alertSnoozedUntil: item.alertSnoozedUntil,
            snapshotGeneratedAt: _signatureHealthSnapshot?.generatedAt,
          ),
          _buildLabTargetProvenanceEmphasisSection(
            context,
            item.provenanceEmphasisSummary,
          ),
          _buildLabTargetProvenanceHistorySection(
            context,
            item.provenanceHistorySummary,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go(AdminRoutePaths.worldSimulationLab),
                icon: const Icon(Icons.science_outlined),
                label: const Text('Open World Simulation Lab'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  AdminRoutePaths.realitySystemRealityFocusLink(
                    focus: item.environmentId,
                  ),
                ),
                icon: const Icon(Icons.psychology_alt_outlined),
                label: const Text('Open Reality Oversight'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropagationTargetSummary(
    BuildContext context,
    SignatureHealthPropagationTarget target,
  ) {
    final delta = target.hierarchyDomainDeltaSummary;
    final personalization = target.personalAgentPersonalizationSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${target.targetId} • ${target.propagationKind}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          target.reason,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (delta != null) ...[
          const SizedBox(height: 4),
          Text(
            'Domain propagation delta • ${delta.domainId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(delta.summary, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            'Bounded use: ${delta.boundedUse}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Domain delta: ${delta.jsonPath ?? 'missing'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (delta.downstreamConsumerSummary != null) ...[
            const SizedBox(height: 4),
            Text(
              'Domain consumer • ${delta.downstreamConsumerSummary!.consumerId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              delta.downstreamConsumerSummary!.summary,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Targeted systems: ${delta.downstreamConsumerSummary!.targetedSystems.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
        if (personalization != null) ...[
          const SizedBox(height: 4),
          Text(
            'Personal-agent personalization • ${personalization.domainId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            personalization.summary,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Personalization mode: ${personalization.personalizationMode}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bounded use: ${personalization.boundedUse}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Personalization delta: ${personalization.jsonPath ?? 'missing'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final supervisorOutcome = _latestSupervisorLearningOutcome();
    final supervisorFeedback = supervisorOutcome?.supervisorFeedbackSummary;
    final activeBoundedReviewCandidates = _activeBoundedReviewCandidates();
    final downgradedLabTargets = _downgradedLabTargetActions();
    final reviewQueueEnvironmentLabels = _reviewQueueEnvironmentLabels(
      activeBoundedReviewCandidates,
      downgradedLabTargets,
    );
    final selectedReviewQueueEnvironmentId = reviewQueueEnvironmentLabels
            .containsKey(_selectedReviewQueueEnvironmentId)
        ? _selectedReviewQueueEnvironmentId
        : null;
    final servedBasisSummaries = _filterServedBasisSummaries(
      _signatureHealthSnapshot?.servedBasisSummaries ??
          const <SignatureHealthServedBasisSummary>[],
      selectedReviewQueueEnvironmentId,
    );
    final familyRestageIntakeReviewSummaries =
        _filterFamilyRestageIntakeReviewSummaries(
      _signatureHealthSnapshot?.familyRestageIntakeReviewSummaries ??
          const <SignatureHealthFamilyRestageIntakeReviewSummary>[],
      selectedReviewQueueEnvironmentId,
    );
    final environmentFilteredActiveBoundedReviewCandidates =
        _filterActiveBoundedReviewCandidates(
      activeBoundedReviewCandidates,
      selectedReviewQueueEnvironmentId,
    );
    final environmentFilteredDowngradedLabTargets = _filterDowngradedLabTargets(
      downgradedLabTargets,
      selectedReviewQueueEnvironmentId,
    );
    final reviewQueueTargetLabels = _reviewQueueTargetLabels(
      environmentFilteredActiveBoundedReviewCandidates,
      environmentFilteredDowngradedLabTargets,
    );
    final selectedReviewQueueTargetKey =
        reviewQueueTargetLabels.containsKey(_selectedReviewQueueTargetKey)
            ? _selectedReviewQueueTargetKey
            : null;
    final filteredActiveBoundedReviewCandidates =
        _rankActiveBoundedReviewCandidates(
      _filterActiveBoundedReviewCandidatesByTarget(
        environmentFilteredActiveBoundedReviewCandidates,
        selectedReviewQueueTargetKey,
      ),
      _reviewQueueSortMode,
    );
    final filteredDowngradedLabTargets = _rankDowngradedLabTargets(
      _filterDowngradedLabTargetsByTarget(
        environmentFilteredDowngradedLabTargets,
        selectedReviewQueueTargetKey,
      ),
      _reviewQueueSortMode,
    );
    final visibleBoundedAlertTargets = _visibleUnacknowledgedBoundedAlerts(
      filteredActiveBoundedReviewCandidates,
      filteredDowngradedLabTargets,
    );
    final visibleOperatorActionableBoundedAlertTargets =
        _visibleOperatorActionableBoundedAlerts(
      filteredActiveBoundedReviewCandidates,
      filteredDowngradedLabTargets,
    );
    final visibleEscalatedBoundedAlertTargets = _visibleEscalatedBoundedAlerts(
      filteredActiveBoundedReviewCandidates,
      filteredDowngradedLabTargets,
    );
    final visibleSnoozedBoundedAlertTargets = _visibleSnoozedBoundedAlerts(
      filteredActiveBoundedReviewCandidates,
      filteredDowngradedLabTargets,
    );
    final hasVisibleBoundedAlerts = _hasVisibleBoundedAlerts(
      filteredActiveBoundedReviewCandidates,
      filteredDowngradedLabTargets,
    );
    return AppFlowScaffold(
      title: 'Reality Model',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin-only reality-model oversight',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reality-model reasoning, locality context, and research guidance are now an admin/operator surface. They are intentionally disconnected from the BHAM consumer shell.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      Chip(label: Text('Admin boundary')),
                      Chip(label: Text('Research + oversight')),
                      Chip(label: Text('Not in consumer beta gate')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const RealityModelContractStatusCard(
            surfaceLabel: 'Reality Model',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supervisor Learning Posture',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (supervisorOutcome == null)
                    Text(
                      _signatureHealthError == null
                          ? 'No bounded supervisor learning feedback is currently available.'
                          : 'Supervisor learning feedback is unavailable: $_signatureHealthError',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    )
                  else ...[
                    Text(
                      '${supervisorOutcome.cityCode.toUpperCase()} • ${supervisorOutcome.environmentId}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            _recommendationLabel(
                              supervisorFeedback!.boundedRecommendation,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Requests ${supervisorFeedback.requestCount}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Recommendations ${supervisorFeedback.recommendationCount}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      supervisorFeedback.feedbackSummary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bounded recommendation: ${supervisorFeedback.boundedRecommendation}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (supervisorOutcome.propagationTargets.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Governed downstream targets: ${supervisorOutcome.propagationTargets.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                    if (supervisorOutcome.adminEvidenceRefreshSummary !=
                        null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Admin Evidence Refresh',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        supervisorOutcome.adminEvidenceRefreshSummary!.summary,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Admin evidence refresh: ${supervisorOutcome.adminEvidenceRefreshSummary!.jsonPath ?? 'missing'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                    if (_preferredPropagationTargets(supervisorOutcome)
                        .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Governed Post-Learning Chain',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ..._preferredPropagationTargets(supervisorOutcome).map(
                        (target) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPropagationTargetSummary(
                            context,
                            target,
                          ),
                        ),
                      ),
                      if (supervisorOutcome.propagationTargets.length >
                          _preferredPropagationTargets(supervisorOutcome)
                              .length)
                        Text(
                          'Additional governed targets: ${supervisorOutcome.propagationTargets.length - _preferredPropagationTargets(supervisorOutcome).length}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go(AdminRoutePaths.worldSimulationLab),
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Open World Simulation Lab'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go(AdminRoutePaths.realitySystemReality),
                          icon: const Icon(Icons.psychology_alt_outlined),
                          label: const Text('Open Reality Oversight'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (servedBasisSummaries.isNotEmpty) ...[
                    Text(
                      'Living City-Pack Basis',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...servedBasisSummaries.take(2).map(
                          (summary) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${summary.cityCode.toUpperCase()} • ${summary.displayName}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Basis: ${_servedBasisStatusLabel(summary.currentBasisStatus)} • Revalidation: ${_servedBasisStatusLabel(summary.latestStateRevalidationStatus)} • Recovery: ${_servedBasisStatusLabel(summary.latestStateRecoveryDecisionStatus)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hydration: ${_servedBasisStatusLabel(summary.latestStateHydrationStatus)} • Readiness: ${_servedBasisStatusLabel(summary.latestStatePromotionReadiness)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                if ((summary.cityPackStructuralRef ?? '')
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'City-pack structural ref: ${summary.cityPackStructuralRef}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                if ((summary.latestStateRevalidationReceiptRef ??
                                            '')
                                        .isNotEmpty ||
                                    (summary.latestStateRecoveryDecisionArtifactRef ??
                                            '')
                                        .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      [
                                        if ((summary.latestStateRevalidationReceiptRef ??
                                                '')
                                            .isNotEmpty)
                                          'Revalidation receipt: ${summary.latestStateRevalidationReceiptRef}',
                                        if ((summary.latestStateRecoveryDecisionArtifactRef ??
                                                '')
                                            .isNotEmpty)
                                          'Recovery artifact: ${summary.latestStateRecoveryDecisionArtifactRef}',
                                      ].join(' • '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                if (_servedBasisRecoveryAttention(summary) !=
                                    null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Shared review surfaces only mirror this posture. Restore/restage remains lab-only.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => context.go(
                                      AdminRoutePaths
                                          .worldSimulationLabFocusLink(
                                        focus: summary.environmentId,
                                        attention:
                                            _servedBasisRecoveryAttention(
                                                summary),
                                      ),
                                    ),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text(
                                      'Open recovery review in lab',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    if (familyRestageIntakeReviewSummaries.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Family Restage Intake Follow-up',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...familyRestageIntakeReviewSummaries.take(2).map(
                            (summary) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${summary.cityCode.toUpperCase()} • ${summary.displayName}',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_evidenceFamilyLabel(summary.evidenceFamily)} • ${_servedBasisStatusLabel(summary.queueStatus)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Restage target: ${summary.restageTargetSummary}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  if ((summary.restageIntakeReviewItemId ?? '')
                                          .isNotEmpty ||
                                      (summary.restageIntakeQueueJsonPath ?? '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageIntakeReviewItemId ??
                                                  '')
                                              .isNotEmpty)
                                            'Intake review item: ${summary.restageIntakeReviewItemId}',
                                          if ((summary.restageIntakeQueueJsonPath ??
                                                  '')
                                              .isNotEmpty)
                                            'Queue artifact: ${summary.restageIntakeQueueJsonPath}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.followUpReviewItemId ?? '')
                                          .isNotEmpty ||
                                      (summary.followUpQueueJsonPath ?? '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.followUpReviewItemId ??
                                                  '')
                                              .isNotEmpty)
                                            'Follow-up review item: ${summary.followUpReviewItemId}',
                                          if ((summary.followUpQueueJsonPath ??
                                                  '')
                                              .isNotEmpty)
                                            'Follow-up queue artifact: ${summary.followUpQueueJsonPath}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.followUpResolutionStatus ?? '')
                                          .isNotEmpty ||
                                      (summary.followUpResolutionArtifactRef ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.followUpResolutionStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Follow-up resolution: ${summary.followUpResolutionStatus}',
                                          if ((summary.followUpResolutionArtifactRef ??
                                                  '')
                                              .isNotEmpty)
                                            'Follow-up resolution artifact: ${summary.followUpResolutionArtifactRef}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageResolutionReviewItemId ??
                                              '')
                                          .isNotEmpty ||
                                      (summary.restageResolutionQueueJsonPath ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageResolutionReviewItemId ??
                                                  '')
                                              .isNotEmpty)
                                            'Resolution review item: ${summary.restageResolutionReviewItemId}',
                                          if ((summary.restageResolutionQueueJsonPath ??
                                                  '')
                                              .isNotEmpty)
                                            'Resolution queue artifact: ${summary.restageResolutionQueueJsonPath}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageResolutionResolutionStatus ??
                                              '')
                                          .isNotEmpty ||
                                      (summary.restageResolutionResolutionArtifactRef ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageResolutionResolutionStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Resolution outcome: ${summary.restageResolutionResolutionStatus}',
                                          if ((summary.restageResolutionResolutionArtifactRef ??
                                                  '')
                                              .isNotEmpty)
                                            'Resolution outcome artifact: ${summary.restageResolutionResolutionArtifactRef}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageExecutionQueueStatus ??
                                              '')
                                          .isNotEmpty ||
                                      (summary.restageExecutionQueueJsonPath ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageExecutionQueueStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Execution queue: ${summary.restageExecutionQueueStatus}',
                                          if ((summary.restageExecutionReviewItemId ??
                                                  '')
                                              .isNotEmpty)
                                            'Execution review item: ${summary.restageExecutionReviewItemId}',
                                          if ((summary.restageExecutionQueueJsonPath ??
                                                  '')
                                              .isNotEmpty)
                                            'Execution queue artifact: ${summary.restageExecutionQueueJsonPath}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageExecutionResolutionStatus ??
                                              '')
                                          .isNotEmpty ||
                                      (summary.restageExecutionResolutionArtifactRef ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageExecutionResolutionStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Execution outcome: ${summary.restageExecutionResolutionStatus}',
                                          if ((summary.restageExecutionResolutionArtifactRef ??
                                                  '')
                                              .isNotEmpty)
                                            'Execution outcome artifact: ${summary.restageExecutionResolutionArtifactRef}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageApplicationQueueStatus ??
                                              '')
                                          .isNotEmpty ||
                                      (summary.restageApplicationQueueJsonPath ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageApplicationQueueStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Application queue: ${summary.restageApplicationQueueStatus}',
                                          if ((summary.restageApplicationReviewItemId ??
                                                  '')
                                              .isNotEmpty)
                                            'Application review item: ${summary.restageApplicationReviewItemId}',
                                          if ((summary.restageApplicationQueueJsonPath ??
                                                  '')
                                              .isNotEmpty)
                                            'Application queue artifact: ${summary.restageApplicationQueueJsonPath}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageApplicationResolutionStatus ??
                                              '')
                                          .isNotEmpty ||
                                      (summary.restageApplicationResolutionArtifactRef ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageApplicationResolutionStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Application outcome: ${summary.restageApplicationResolutionStatus}',
                                          if ((summary.restageApplicationResolutionArtifactRef ??
                                                  '')
                                              .isNotEmpty)
                                            'Application outcome artifact: ${summary.restageApplicationResolutionArtifactRef}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageApplyQueueStatus ?? '')
                                          .isNotEmpty ||
                                      (summary.restageApplyQueueJsonPath ?? '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageApplyQueueStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Apply queue: ${summary.restageApplyQueueStatus}',
                                          if ((summary.restageApplyReviewItemId ??
                                                  '')
                                              .isNotEmpty)
                                            'Apply review item: ${summary.restageApplyReviewItemId}',
                                          if ((summary.restageApplyQueueJsonPath ??
                                                  '')
                                              .isNotEmpty)
                                            'Apply queue artifact: ${summary.restageApplyQueueJsonPath}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageApplyResolutionStatus ??
                                              '')
                                          .isNotEmpty ||
                                      (summary.restageApplyResolutionArtifactRef ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageApplyResolutionStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Apply outcome: ${summary.restageApplyResolutionStatus}',
                                          if ((summary.restageApplyResolutionArtifactRef ??
                                                  '')
                                              .isNotEmpty)
                                            'Apply outcome artifact: ${summary.restageApplyResolutionArtifactRef}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageServedBasisUpdateQueueStatus ??
                                              '')
                                          .isNotEmpty ||
                                      (summary.restageServedBasisUpdateQueueJsonPath ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageServedBasisUpdateQueueStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Served-basis update queue: ${summary.restageServedBasisUpdateQueueStatus}',
                                          if ((summary.restageServedBasisUpdateReviewItemId ??
                                                  '')
                                              .isNotEmpty)
                                            'Served-basis update review item: ${summary.restageServedBasisUpdateReviewItemId}',
                                          if ((summary.restageServedBasisUpdateQueueJsonPath ??
                                                  '')
                                              .isNotEmpty)
                                            'Served-basis update queue artifact: ${summary.restageServedBasisUpdateQueueJsonPath}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if ((summary.restageServedBasisUpdateResolutionStatus ??
                                              '')
                                          .isNotEmpty ||
                                      (summary.restageServedBasisUpdateResolutionArtifactRef ??
                                              '')
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if ((summary.restageServedBasisUpdateResolutionStatus ??
                                                  '')
                                              .isNotEmpty)
                                            'Served-basis update outcome: ${summary.restageServedBasisUpdateResolutionStatus}',
                                          if ((summary.restageServedBasisUpdateResolutionArtifactRef ??
                                                  '')
                                              .isNotEmpty)
                                            'Served-basis update outcome artifact: ${summary.restageServedBasisUpdateResolutionArtifactRef}',
                                        ].join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Shared review surfaces only mirror this intake, follow-up queue, resolved posture, resolution queue, execution queue, execution outcome, application queue, application outcome, apply queue, apply outcome, served-basis update queue, and served-basis update outcome. Family restage decisions remain lab-only.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => context.go(
                                      AdminRoutePaths
                                          .worldSimulationLabFocusLink(
                                        focus: summary.environmentId,
                                        attention:
                                            'family_restage_intake_review',
                                      ),
                                    ),
                                    icon: const Icon(Icons.playlist_add_check),
                                    label:
                                        const Text('Open intake review in lab'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    const Divider(height: 24),
                  ],
                  Text(
                    'World Simulation Lab Review Queue',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (activeBoundedReviewCandidates.isEmpty &&
                      downgradedLabTargets.isEmpty)
                    Text(
                      'No World Simulation Lab target is currently marked for bounded review.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    )
                  else ...[
                    Text(
                      activeBoundedReviewCandidates.isNotEmpty &&
                              downgradedLabTargets.isNotEmpty
                          ? 'Active bounded-review candidates and downgraded watch/iterate targets are both shown here so review posture stays visible across multiple simulation lanes.'
                          : activeBoundedReviewCandidates.isNotEmpty
                              ? 'Active bounded-review candidates from World Simulation Lab are grouped here for operator handoff into Reality Oversight.'
                              : 'No target is currently in the active bounded-review queue, but downgraded watch/iterate targets are still grouped here so their latest routing posture stays visible.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Within each queue, higher-risk routing posture and stronger runtime regression signals rise first.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (reviewQueueEnvironmentLabels.length > 1) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Filter by simulation environment',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All environments'),
                            selected: selectedReviewQueueEnvironmentId == null,
                            onSelected: (_) {
                              setState(() {
                                _selectedReviewQueueEnvironmentId = null;
                                _selectedReviewQueueTargetKey = null;
                              });
                            },
                          ),
                          ...reviewQueueEnvironmentLabels.entries.map(
                            (entry) => ChoiceChip(
                              label: Text(entry.value),
                              selected:
                                  selectedReviewQueueEnvironmentId == entry.key,
                              onSelected: (_) {
                                setState(() {
                                  _selectedReviewQueueEnvironmentId = entry.key;
                                  _selectedReviewQueueTargetKey = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (selectedReviewQueueEnvironmentId != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Showing queue posture for ${reviewQueueEnvironmentLabels[selectedReviewQueueEnvironmentId]}.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                    if (selectedReviewQueueEnvironmentId != null &&
                        reviewQueueTargetLabels.length > 1) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Filter by target lane',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All target lanes'),
                            selected: selectedReviewQueueTargetKey == null,
                            onSelected: (_) {
                              setState(() {
                                _selectedReviewQueueTargetKey = null;
                              });
                            },
                          ),
                          ...reviewQueueTargetLabels.entries.map(
                            (entry) => ChoiceChip(
                              label: Text(entry.value),
                              selected:
                                  selectedReviewQueueTargetKey == entry.key,
                              onSelected: (_) {
                                setState(() {
                                  _selectedReviewQueueTargetKey = entry.key;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (selectedReviewQueueTargetKey != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Showing target lane ${reviewQueueTargetLabels[selectedReviewQueueTargetKey]}.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                    if (filteredActiveBoundedReviewCandidates.length +
                            filteredDowngradedLabTargets.length >
                        1) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Sort queue by',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final sortMode in <String>[
                            _reviewQueueSortPriority,
                            _reviewQueueSortAlerts,
                            _reviewQueueSortProvenance,
                            _reviewQueueSortRegressing,
                            _reviewQueueSortActive,
                            _reviewQueueSortRecent,
                          ])
                            ChoiceChip(
                              label: Text(_reviewQueueSortModeLabel(sortMode)),
                              selected: _reviewQueueSortMode == sortMode,
                              onSelected: (_) {
                                setState(() {
                                  _reviewQueueSortMode = sortMode;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                    if (filteredActiveBoundedReviewCandidates.isNotEmpty ||
                        filteredDowngradedLabTargets.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _reviewQueueEscalationSummary(
                          filteredActiveBoundedReviewCandidates,
                          filteredDowngradedLabTargets,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    _buildVisibleBoundedAlertBulkActionRow(
                      context,
                      visibleBoundedAlertTargets,
                      visibleOperatorActionableBoundedAlertTargets,
                      visibleEscalatedBoundedAlertTargets,
                      visibleSnoozedBoundedAlertTargets,
                      hasVisibleBoundedAlerts,
                      _signatureHealthSnapshot?.generatedAt,
                    ),
                    if (activeBoundedReviewCandidates.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ExpansionTile(
                        key: PageStorageKey<String>(
                          'world_model_ai_active_bounded_review_candidates_${selectedReviewQueueEnvironmentId ?? 'all'}',
                        ),
                        initiallyExpanded: true,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(
                          'Active bounded review candidates',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          selectedReviewQueueEnvironmentId == null
                              ? '${filteredActiveBoundedReviewCandidates.length} visible'
                              : '${filteredActiveBoundedReviewCandidates.length} visible for ${reviewQueueEnvironmentLabels[selectedReviewQueueEnvironmentId]}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        children: [
                          const SizedBox(height: 8),
                          if (filteredActiveBoundedReviewCandidates.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'No active bounded-review candidates match the current environment filter.',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            )
                          else
                            ...filteredActiveBoundedReviewCandidates
                                .take(3)
                                .map(
                                  (candidate) =>
                                      _buildActiveBoundedReviewCandidateCard(
                                    context,
                                    candidate,
                                  ),
                                ),
                        ],
                      ),
                    ],
                    if (downgradedLabTargets.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ExpansionTile(
                        key: PageStorageKey<String>(
                          'world_model_ai_downgraded_lab_targets_${selectedReviewQueueEnvironmentId ?? 'all'}',
                        ),
                        initiallyExpanded: true,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(
                          'Tracked downgraded targets',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          selectedReviewQueueEnvironmentId == null
                              ? '${filteredDowngradedLabTargets.length} visible'
                              : '${filteredDowngradedLabTargets.length} visible for ${reviewQueueEnvironmentLabels[selectedReviewQueueEnvironmentId]}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        children: [
                          const SizedBox(height: 8),
                          if (filteredDowngradedLabTargets.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'No downgraded targets match the current environment filter.',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            )
                          else
                            ...filteredDowngradedLabTargets.take(3).map(
                                  (item) => _buildDowngradedLabTargetCard(
                                    context,
                                    item,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.travel_explore_outlined),
              title: const Text('World Simulation Lab'),
              subtitle: const Text(
                'Boot any registered simulation environment, compare variants, and record accepted or denied lab outcomes before training.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.worldSimulationLab),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.psychology_alt_outlined),
              title: const Text('Reality Oversight'),
              subtitle: const Text(
                'Inspect locality, universe, and world-layer oversight surfaces.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.realitySystemReality),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Research Center'),
              subtitle: const Text(
                'Review research feed, alerts, and operator-facing reality-model work.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.researchCenter),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Communications'),
              subtitle: const Text(
                'Inspect pseudonymous route, delivery, and support summaries.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.communications),
            ),
          ),
        ],
      ),
    );
  }
}
