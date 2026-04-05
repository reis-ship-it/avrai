import 'dart:async';

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class SignatureSourceHealthPage extends StatefulWidget {
  const SignatureSourceHealthPage({
    super.key,
    this.initialFocus,
    this.initialAttention,
  });

  final String? initialFocus;
  final String? initialAttention;

  @override
  State<SignatureSourceHealthPage> createState() =>
      _SignatureSourceHealthPageState();
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

class _SignatureSourceHealthPageState extends State<SignatureSourceHealthPage> {
  static const String _reviewQueueSortPriority = 'priority';
  static const String _reviewQueueSortAlerts = 'alerts';
  static const String _reviewQueueSortProvenance = 'provenance';
  static const String _reviewQueueSortRegressing = 'regressing';
  static const String _reviewQueueSortActive = 'active';
  static const String _reviewQueueSortRecent = 'recent';

  SignatureHealthAdminService? _service;
  StreamSubscription<SignatureHealthSnapshot>? _subscription;
  SignatureHealthSnapshot? _snapshot;
  final Set<String> _resolvingReviewItemIds = <String>{};
  final Set<String> _resolvingPropagationTargetIds = <String>{};
  final Set<String> _resolvingTruthReviewSourceIds = <String>{};
  final Set<String> _resolvingUpdateCandidateSourceIds = <String>{};
  final Set<String> _startingUpdateSimulationSourceIds = <String>{};
  final Set<String> _resolvingDownstreamRepropagationSourceIds = <String>{};
  final Set<String> _acknowledgingLabAlertTargetKeys = <String>{};
  final Set<String> _updatingLabAlertStateTargetKeys = <String>{};
  _VisibleLabTargetBulkAction? _activeBulkAlertAction;
  String? _selectedReviewQueueEnvironmentId;
  String? _selectedReviewQueueTargetKey;
  String _reviewQueueSortMode = _reviewQueueSortPriority;
  bool _isLoading = true;
  String? _error;

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
    _init();
  }

  Future<void> _init() async {
    try {
      _service = GetIt.instance<SignatureHealthAdminService>();
      _subscription = _service!.watchSnapshot().listen(
        (snapshot) {
          if (!mounted) {
            return;
          }
          setState(() {
            _snapshot = snapshot;
            _isLoading = false;
            _error = null;
          });
        },
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _error = 'Failed to load signature health: $error';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Signature health services are unavailable: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await service.getSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Refresh failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acknowledgeLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
    required String alertSeverityCode,
  }) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _acknowledgingLabAlertTargetKeys.add(targetKey);
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
        _snapshot = snapshot;
        _error = null;
        _acknowledgingLabAlertTargetKeys.remove(targetKey);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Alert acknowledgment failed: $e';
        _acknowledgingLabAlertTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _escalateLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
    required String alertSeverityCode,
  }) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _updatingLabAlertStateTargetKeys.add(targetKey);
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
        _snapshot = snapshot;
        _error = null;
        _updatingLabAlertStateTargetKeys.remove(targetKey);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Alert escalation failed: $e';
        _updatingLabAlertStateTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _snoozeLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
    required String alertSeverityCode,
  }) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _updatingLabAlertStateTargetKeys.add(targetKey);
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
        _snapshot = snapshot;
        _error = null;
        _updatingLabAlertStateTargetKeys.remove(targetKey);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Alert snooze failed: $e';
        _updatingLabAlertStateTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _clearEscalatedLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
  }) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _updatingLabAlertStateTargetKeys.add(targetKey);
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
        _snapshot = snapshot;
        _error = null;
        _updatingLabAlertStateTargetKeys.remove(targetKey);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Alert de-escalation failed: $e';
        _updatingLabAlertStateTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _unsnoozeLabTargetAlert({
    required String targetKey,
    required String environmentId,
    required String? variantId,
  }) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _updatingLabAlertStateTargetKeys.add(targetKey);
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
        _snapshot = snapshot;
        _error = null;
        _updatingLabAlertStateTargetKeys.remove(targetKey);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Alert unsnooze failed: $e';
        _updatingLabAlertStateTargetKeys.remove(targetKey);
      });
    }
  }

  Future<void> _applyBulkVisibleLabTargetAlertAction({
    required _VisibleLabTargetBulkAction action,
    required List<_VisibleLabTargetAlertTarget> targets,
  }) async {
    final service = _service;
    if (service == null || targets.isEmpty) {
      return;
    }
    final targetKeys = targets.map((target) => target.targetKey).toList();
    setState(() {
      _activeBulkAlertAction = action;
      switch (action) {
        case _VisibleLabTargetBulkAction.acknowledge:
          _acknowledgingLabAlertTargetKeys.addAll(targetKeys);
        case _VisibleLabTargetBulkAction.escalate:
        case _VisibleLabTargetBulkAction.snooze:
        case _VisibleLabTargetBulkAction.clearEscalation:
        case _VisibleLabTargetBulkAction.unsnooze:
          _updatingLabAlertStateTargetKeys.addAll(targetKeys);
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
        _snapshot = latestSnapshot ?? _snapshot;
        _error = null;
        _activeBulkAlertAction = null;
        _acknowledgingLabAlertTargetKeys.removeAll(targetKeys);
        _updatingLabAlertStateTargetKeys.removeAll(targetKeys);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = switch (action) {
          _VisibleLabTargetBulkAction.acknowledge =>
            'Alert acknowledgment failed: $e',
          _VisibleLabTargetBulkAction.escalate => 'Alert escalation failed: $e',
          _VisibleLabTargetBulkAction.snooze => 'Alert snooze failed: $e',
          _VisibleLabTargetBulkAction.clearEscalation =>
            'Alert de-escalation failed: $e',
          _VisibleLabTargetBulkAction.unsnooze => 'Alert unsnooze failed: $e',
        };
        _activeBulkAlertAction = null;
        _acknowledgingLabAlertTargetKeys.removeAll(targetKeys);
        _updatingLabAlertStateTargetKeys.removeAll(targetKeys);
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

  Future<void> _resolveReviewItem(
    SignatureHealthReviewQueueItem item,
    SignatureHealthReviewResolution resolution,
  ) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _resolvingReviewItemIds.add(item.id);
    });
    try {
      final result = await service.resolveReviewItem(
        reviewItemId: item.id,
        resolution: resolution,
      );
      if (!mounted) {
        return;
      }
      final learningOutcomePath = result.learningOutcomeJsonPath;
      final executionQueuePath = result.executionQueueJsonPath;
      final learningExecutionPath = result.learningExecutionJsonPath;
      final upwardPlanPath = result.hierarchySynthesisPlanJsonPath;
      final upwardOutcomePath = result.hierarchySynthesisOutcomeJsonPath;
      final upwardHandoffPath = result.realityModelAgentHandoffJsonPath;
      final upwardRealityModelOutcomePath =
          result.realityModelAgentOutcomeJsonPath;
      final upwardTruthReviewPath = result.realityModelTruthReviewJsonPath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolution == SignatureHealthReviewResolution.approved
                ? (upwardTruthReviewPath != null
                    ? 'Review accepted and truth/conviction review saved: $upwardTruthReviewPath'
                    : upwardRealityModelOutcomePath != null
                        ? 'Review accepted and reality-model-agent outcome saved: $upwardRealityModelOutcomePath'
                        : upwardHandoffPath != null
                            ? 'Review accepted and reality-model-agent handoff saved: $upwardHandoffPath'
                            : upwardOutcomePath != null
                                ? 'Review accepted and hierarchy synthesis outcome saved: $upwardOutcomePath'
                                : upwardPlanPath != null
                                    ? 'Review accepted and upward hierarchy synthesis queued: $upwardPlanPath'
                                    : learningOutcomePath != null
                                        ? 'Review accepted and reality-model learning outcome saved: $learningOutcomePath'
                                        : learningExecutionPath != null
                                            ? 'Review accepted and queued for reality-model learning: $learningExecutionPath'
                                            : executionQueuePath != null
                                                ? 'Review accepted and queued for execution: $executionQueuePath'
                                                : 'Review accepted: ${item.title}')
                : 'Review rejected: ${item.title}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review resolution failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingReviewItemIds.remove(item.id);
        });
      }
    }
  }

  Future<void> _resolvePropagationTarget(
    SignatureHealthLearningOutcomeItem item,
    SignatureHealthPropagationTarget target,
    SignatureHealthPropagationResolution resolution,
  ) async {
    final service = _service;
    if (service == null) {
      return;
    }
    final resolvingKey = '${item.sourceId}:${target.targetId}';
    setState(() {
      _resolvingPropagationTargetIds.add(resolvingKey);
    });
    try {
      final result = await service.resolvePropagationTarget(
        sourceId: item.sourceId,
        targetId: target.targetId,
        resolution: resolution,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolution == SignatureHealthPropagationResolution.approved
                ? (result.propagationReceiptJsonPath != null
                    ? 'Propagation executed locally: ${result.propagationReceiptJsonPath}'
                    : 'Propagation target approved: ${target.targetId}')
                : 'Propagation target rejected: ${target.targetId}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Propagation resolution failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingPropagationTargetIds.remove(resolvingKey);
        });
      }
    }
  }

  Future<void> _resolveTruthReview(
    SignatureHealthUpwardLearningItem item,
    SignatureHealthTruthReviewResolution resolution,
  ) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _resolvingTruthReviewSourceIds.add(item.sourceId);
    });
    try {
      final result = await service.resolveTruthReview(
        sourceId: item.sourceId,
        resolution: resolution,
      );
      if (!mounted) {
        return;
      }
      final candidatePath = result.realityModelUpdateCandidateJsonPath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switch (resolution) {
              SignatureHealthTruthReviewResolution.promoteToUpdateCandidate =>
                candidatePath != null
                    ? 'Truth review promoted to update candidate: $candidatePath'
                    : 'Truth review promoted for bounded reality-model update review.',
              SignatureHealthTruthReviewResolution.holdForMoreEvidence =>
                'Truth review held for additional evidence: ${item.sourceId}',
              SignatureHealthTruthReviewResolution.rejectIntegration =>
                'Truth review rejected for integration: ${item.sourceId}',
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Truth-review resolution failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingTruthReviewSourceIds.remove(item.sourceId);
        });
      }
    }
  }

  Future<void> _resolveRealityModelUpdateCandidate(
    SignatureHealthUpwardLearningItem item,
    SignatureHealthRealityModelUpdateResolution resolution,
  ) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _resolvingUpdateCandidateSourceIds.add(item.sourceId);
    });
    try {
      final result = await service.resolveRealityModelUpdateCandidate(
        sourceId: item.sourceId,
        resolution: resolution,
      );
      if (!mounted) {
        return;
      }
      final outcomePath = result.realityModelUpdateOutcomeJsonPath;
      final decisionPath = result.realityModelUpdateDecisionJsonPath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switch (resolution) {
              SignatureHealthRealityModelUpdateResolution
                    .approveBoundedUpdate =>
                outcomePath != null
                    ? 'Reality-model update approved and bounded outcome saved: $outcomePath'
                    : decisionPath != null
                        ? 'Reality-model update approved: $decisionPath'
                        : 'Reality-model update approved for bounded local execution.',
              SignatureHealthRealityModelUpdateResolution.holdForMoreEvidence =>
                'Reality-model update candidate held for more evidence: ${item.sourceId}',
              SignatureHealthRealityModelUpdateResolution.rejectUpdate =>
                'Reality-model update candidate rejected: ${item.sourceId}',
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reality-model update resolution failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingUpdateCandidateSourceIds.remove(item.sourceId);
        });
      }
    }
  }

  Future<void> _startRealityModelUpdateValidationSimulation(
    SignatureHealthUpwardLearningItem item,
  ) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _startingUpdateSimulationSourceIds.add(item.sourceId);
    });
    try {
      final result = await service.startRealityModelUpdateValidationSimulation(
        sourceId: item.sourceId,
      );
      if (!mounted) {
        return;
      }
      final requestPath = result.realityModelUpdateSimulationRequestJsonPath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requestPath != null
                ? 'Validation simulation queued for supervisor daemon: $requestPath'
                : 'Validation simulation approved for daemon start.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validation simulation start failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _startingUpdateSimulationSourceIds.remove(item.sourceId);
        });
      }
    }
  }

  Future<void> _resolveDownstreamRepropagationReview(
    SignatureHealthUpwardLearningItem item,
    SignatureHealthDownstreamRepropagationResolution resolution,
  ) async {
    final service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _resolvingDownstreamRepropagationSourceIds.add(item.sourceId);
    });
    try {
      final result =
          await service.resolveRealityModelUpdateDownstreamRepropagation(
        sourceId: item.sourceId,
        resolution: resolution,
      );
      if (!mounted) {
        return;
      }
      final outcomePath =
          result.realityModelUpdateDownstreamRepropagationOutcomeJsonPath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolution ==
                    SignatureHealthDownstreamRepropagationResolution.approve
                ? (outcomePath != null
                    ? 'Downstream re-propagation approved: $outcomePath'
                    : 'Downstream re-propagation approved for bounded follow-on lanes.')
                : 'Downstream re-propagation rejected: ${item.sourceId}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downstream re-propagation resolution failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingDownstreamRepropagationSourceIds.remove(item.sourceId);
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Signature + Source Health',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      body: _buildBody(context),
    );
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

  String _chatObservationOutcomeLabel(
    GovernedLearningChatObservationOutcome? outcome,
  ) {
    return switch (outcome) {
      GovernedLearningChatObservationOutcome.pending => 'pending',
      GovernedLearningChatObservationOutcome.acknowledged => 'acknowledged',
      GovernedLearningChatObservationOutcome.requestedFollowUp =>
        'requested follow-up',
      GovernedLearningChatObservationOutcome.correctedRecord =>
        'corrected record',
      GovernedLearningChatObservationOutcome.forgotRecord => 'forgot record',
      GovernedLearningChatObservationOutcome.stoppedUsingSignal =>
        'stopped using signal',
      null => 'none',
    };
  }

  String _chatObservationValidationLabel(
    GovernedLearningChatObservationValidationStatus? status,
  ) {
    return switch (status) {
      GovernedLearningChatObservationValidationStatus.pending => 'pending',
      GovernedLearningChatObservationValidationStatus
            .validatedBySurfacedAdoption =>
        'validated by surfaced adoption',
      null => 'none',
    };
  }

  String _chatObservationGovernanceLabel(
    GovernedLearningChatObservationGovernanceStatus? status,
  ) {
    return switch (status) {
      GovernedLearningChatObservationGovernanceStatus.pending => 'pending',
      GovernedLearningChatObservationGovernanceStatus.reinforcedByGovernance =>
        'reinforced by governance',
      GovernedLearningChatObservationGovernanceStatus.constrainedByGovernance =>
        'constrained by governance',
      GovernedLearningChatObservationGovernanceStatus.overruledByGovernance =>
        'overruled by governance',
      null => 'none',
    };
  }

  String _chatObservationAttentionLabel(
    GovernedLearningChatObservationAttentionStatus? status,
  ) {
    return switch (status) {
      GovernedLearningChatObservationAttentionStatus.pending =>
        'pending attention',
      GovernedLearningChatObservationAttentionStatus.clearedByGovernance =>
        'attention cleared by governance',
      GovernedLearningChatObservationAttentionStatus.satisfiedByGovernance =>
        'attention satisfied by governance',
      null => 'none',
    };
  }

  String _chatObservationStageLabel(String? stage) {
    return switch (stage) {
      'upward_learning_review' => 'upward learning review',
      'reality_model_truth_review' => 'reality-model truth review',
      'reality_model_update_review' => 'reality-model update review',
      null || '' => 'unknown stage',
      _ => stage.replaceAll('_', ' '),
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
    if (!hasVisibleBoundedAlerts || _service == null) {
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
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.summary,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            historyLabel,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.textSecondary),
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
    final isBusy = _acknowledgingLabAlertTargetKeys.contains(targetKey);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            onPressed: isBusy
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
    final isBusy = _updatingLabAlertStateTargetKeys.contains(targetKey);
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
            onPressed: isBusy
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
            onPressed: isBusy
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

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live signature + intake health',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This surface groups imported sources by health category so operators can spot weak confidence, stale pheromones, fallback-heavy ranking, and review queues before launch quality drifts.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _kpiChip('Strong', snapshot.overview.strongCount),
                      _kpiChip('Weak', snapshot.overview.weakDataCount),
                      _kpiChip('Stale', snapshot.overview.staleCount),
                      _kpiChip('Fallback', snapshot.overview.fallbackCount),
                      _kpiChip('Review', snapshot.overview.reviewNeededCount),
                      _kpiChip('Bundle', snapshot.overview.bundleCount),
                      _kpiChip('Review queue', snapshot.reviewQueueCount),
                      _kpiChip(
                        'KG runs',
                        snapshot.overview.kernelGraphRecentCount,
                      ),
                      _kpiChip(
                        'KG failed',
                        snapshot.overview.kernelGraphFailedCount,
                      ),
                      _kpiChip(
                          'Soft ignore', snapshot.overview.softIgnoreCount),
                      _kpiChip(
                        'Hard reject',
                        snapshot.overview.hardNotInterestedCount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_hasFocusHandoff) ...[
            const SizedBox(height: 12),
            _buildFocusHandoffCard(context, snapshot),
          ],
          const SizedBox(height: 12),
          _buildFeedbackIntentSection(context, snapshot),
          const SizedBox(height: 12),
          _buildFeedbackTrendSection(context, snapshot),
          const SizedBox(height: 12),
          _buildKernelGraphRunSection(context, snapshot),
          const SizedBox(height: 12),
          _buildReviewQueueSection(context, snapshot),
          const SizedBox(height: 12),
          _buildBoundedReviewQueueSection(context, snapshot),
          const SizedBox(height: 12),
          _buildLearningOutcomeSection(context, snapshot),
          const SizedBox(height: 12),
          _buildUpwardLearningSection(context, snapshot),
          const SizedBox(height: 12),
          _buildRouteCard(
            context,
            title: 'Back to Command Center',
            subtitle: 'Return to the operator overview shell.',
            route: AdminRoutePaths.commandCenter,
          ),
          const SizedBox(height: 12),
          ...SignatureHealthCategory.values.map(
              (category) => _buildCategorySection(context, snapshot, category)),
          const SizedBox(height: 12),
          _buildGroupedSection(
            context,
            title: 'Grouped by Entity Type',
            grouped: snapshot.byEntityType,
          ),
          const SizedBox(height: 12),
          _buildGroupedSection(
            context,
            title: 'Grouped by Provider',
            grouped: snapshot.byProvider,
          ),
          const SizedBox(height: 12),
          _buildGroupedSection(
            context,
            title: 'Grouped by Metro',
            grouped: snapshot.byMetro,
          ),
          const SizedBox(height: 12),
          _buildRecordsTable(snapshot.sourceRecords),
        ],
      ),
    );
  }

  bool get _hasFocusHandoff {
    final focus = widget.initialFocus?.trim();
    return focus != null && focus.isNotEmpty;
  }

  Widget _buildFocusHandoffCard(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final focus = widget.initialFocus!.trim();
    final attention = widget.initialAttention?.trim();
    final matchingSourceRows =
        snapshot.records.where((record) => record.sourceId == focus).length;
    final matchingReviewItems = snapshot.reviewItems
        .where((item) => item.id == focus || item.sourceId == focus)
        .length;
    final matchingKernelGraphRuns = snapshot.kernelGraphRuns
        .where(
          (run) =>
              run.runId == focus ||
              run.sourceId == focus ||
              run.jobId == focus ||
              run.reviewItemId == focus,
        )
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.my_location, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Focused artifact handoff',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Signature Health was opened from a related artifact link. Use this handoff to inspect matching source, review, and KernelGraph sections for `$focus`.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.signatureHealth),
                  icon: const Icon(Icons.close),
                  label: const Text('Clear focus'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Focus: $focus')),
                if (attention != null && attention.isNotEmpty)
                  Chip(label: Text('Attention: $attention')),
                Chip(label: Text('Source rows: $matchingSourceRows')),
                Chip(label: Text('Review items: $matchingReviewItems')),
                Chip(label: Text('KG runs: $matchingKernelGraphRuns')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningOutcomeSection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final items = snapshot.learningOutcomeItems;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reality-Model Learning Outcomes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              items.isEmpty
                  ? 'No local learning outcomes are currently available for downstream propagation review.'
                  : 'Accepted simulation-training items now show the canonical post-learning chain: simulation -> reality-model learning outcome -> admin evidence refresh -> supervisor feedback -> domain propagation delta(s).',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No learning outcomes yet.')
            else
              ...items.take(6).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${item.cityCode.toUpperCase()} • ${item.environmentId}',
                            ),
                            subtitle: Text(
                              '${item.summary}\nPathway: ${item.learningPathway}\nOutcome: ${item.outcomeStatus}\nSource: ${item.sourceId}',
                            ),
                            trailing: item.hasReadyTargets
                                ? Chip(
                                    label: const Text('Propagation ready'),
                                    backgroundColor: AppColors.success
                                        .withValues(alpha: 0.12),
                                  )
                                : Chip(
                                    label: const Text('No ready targets'),
                                    backgroundColor: AppColors.grey100,
                                  ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              const Chip(label: Text('Simulation')),
                              const Chip(label: Text('Learning outcome')),
                              if (item.adminEvidenceRefreshSummary != null ||
                                  item.adminEvidenceRefreshSnapshotJsonPath !=
                                      null)
                                const Chip(
                                    label: Text('Admin evidence refresh')),
                              if (item.supervisorFeedbackSummary != null ||
                                  item.supervisorLearningFeedbackStateJsonPath !=
                                      null)
                                const Chip(label: Text('Supervisor feedback')),
                              Chip(
                                label: Text(
                                  'Domain deltas ${item.propagationTargets.length}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Post-learning chain',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Simulation -> reality-model learning outcome -> admin evidence refresh -> supervisor feedback -> domain propagation delta(s)',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => context
                                    .go(AdminRoutePaths.worldSimulationLab),
                                icon: const Icon(Icons.science_outlined),
                                label: const Text('Open World Simulation Lab'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => context.go(
                                  AdminRoutePaths.realitySystemRealityFocusLink(
                                    focus: item.environmentId,
                                    attention:
                                        'learning_outcome:${item.sourceId}',
                                  ),
                                ),
                                icon: const Icon(Icons.psychology_alt_outlined),
                                label: const Text('Open Reality Oversight'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (item.learningOutcomeJsonPath != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Learning outcome: ${item.learningOutcomeJsonPath}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          if (item.downstreamPropagationPlanJsonPath != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Propagation plan: ${item.downstreamPropagationPlanJsonPath}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          if (item.adminEvidenceRefreshSnapshotJsonPath != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Admin evidence refresh: ${item.adminEvidenceRefreshSnapshotJsonPath}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          if (item.adminEvidenceRefreshSummary != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                item.adminEvidenceRefreshSummary!.summary,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Requests: ${item.adminEvidenceRefreshSummary!.requestCount} • Recommendations: ${item.adminEvidenceRefreshSummary!.recommendationCount}'
                                '${item.adminEvidenceRefreshSummary!.averageConfidence == null ? '' : ' • Avg confidence: ${item.adminEvidenceRefreshSummary!.averageConfidence}'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                          if (item.supervisorLearningFeedbackStateJsonPath !=
                              null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Supervisor feedback state: ${item.supervisorLearningFeedbackStateJsonPath}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          if (item.supervisorFeedbackSummary != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                item.supervisorFeedbackSummary!.feedbackSummary,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Supervisor recommendation: ${_recommendationLabel(item.supervisorFeedbackSummary!.boundedRecommendation)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Bounded recommendation: ${item.supervisorFeedbackSummary!.boundedRecommendation}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                          ...item.propagationTargets.take(6).map((target) {
                            final resolvingKey =
                                '${item.sourceId}:${target.targetId}';
                            final isResolving = _resolvingPropagationTargetIds
                                .contains(resolvingKey);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${target.targetId} • ${target.propagationKind}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${target.reason}\nStatus: ${target.status}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                  if (target.receiptJsonPath != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Receipt: ${target.receiptJsonPath}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                  if (target.laneArtifactJsonPath != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lane artifact: ${target.laneArtifactJsonPath}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                  if (target.hierarchyDomainDeltaSummary !=
                                      null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      target
                                          .hierarchyDomainDeltaSummary!.summary,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bounded use: ${target.hierarchyDomainDeltaSummary!.boundedUse}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Requests: ${target.hierarchyDomainDeltaSummary!.requestCount} • Recommendations: ${target.hierarchyDomainDeltaSummary!.recommendationCount}'
                                      '${target.hierarchyDomainDeltaSummary!.averageConfidence == null ? '' : ' • Avg confidence: ${target.hierarchyDomainDeltaSummary!.averageConfidence}'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                  if (target
                                          .personalAgentPersonalizationSummary !=
                                      null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      target
                                          .personalAgentPersonalizationSummary!
                                          .summary,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Personalization mode: ${target.personalAgentPersonalizationSummary!.personalizationMode}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bounded use: ${target.personalAgentPersonalizationSummary!.boundedUse}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: isResolving ||
                                                !target.isReadyForReview
                                            ? null
                                            : () => _resolvePropagationTarget(
                                                  item,
                                                  target,
                                                  SignatureHealthPropagationResolution
                                                      .approved,
                                                ),
                                        icon: const Icon(
                                            Icons.check_circle_outline),
                                        label: Text(
                                          isResolving
                                              ? 'Saving'
                                              : 'Approve propagation',
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: isResolving ||
                                                !target.isReadyForReview
                                            ? null
                                            : () => _resolvePropagationTarget(
                                                  item,
                                                  target,
                                                  SignatureHealthPropagationResolution
                                                      .rejected,
                                                ),
                                        icon: const Icon(Icons.cancel_outlined),
                                        label: Text(
                                          isResolving
                                              ? 'Saving'
                                              : 'Reject propagation',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpwardLearningSection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final items = snapshot.upwardLearningItems;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upward Learning Handoffs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              items.isEmpty
                  ? 'No accepted upward learning reviews are currently staged for hierarchy synthesis and reality-model-agent review.'
                  : 'Accepted personal-agent and AI2AI reviews now preserve the upward chain through hierarchy synthesis and into a local reality-model-agent outcome.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No upward handoffs yet.')
            else
              ...items.take(6).map(
                (item) {
                  final isResolvingTruthReview =
                      _resolvingTruthReviewSourceIds.contains(item.sourceId);
                  final isResolvingUpdateCandidate =
                      _resolvingUpdateCandidateSourceIds.contains(
                    item.sourceId,
                  );
                  final isStartingValidationSimulation =
                      _startingUpdateSimulationSourceIds.contains(
                    item.sourceId,
                  );
                  final isResolvingDownstreamRepropagation =
                      _resolvingDownstreamRepropagationSourceIds.contains(
                    item.sourceId,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${item.sourceKind} • ${item.cityCode.toUpperCase()}',
                          ),
                          subtitle: Text(
                            '${item.summary}\nDirection: ${item.learningDirection}\nPathway: ${item.learningPathway}\nConviction: ${item.convictionTier}\nStatus: ${item.status}',
                          ),
                          trailing: Chip(
                            label: Text(
                              item.realityModelAgentOutcomeJsonPath != null
                                  ? 'Reality-model outcome ready'
                                  : 'Upward handoff ready',
                            ),
                            backgroundColor:
                                AppColors.accent.withValues(alpha: 0.12),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const Chip(label: Text('Personal/AI2AI intake')),
                            const Chip(label: Text('Hierarchy synthesis')),
                            const Chip(
                              label: Text('Reality-model-agent handoff'),
                            ),
                            if (item.needsChatAttention)
                              Chip(
                                avatar: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                ),
                                label: Text(
                                  item.chatObservationSummary!
                                              .requestedFollowUpCount >
                                          0
                                      ? 'Chat follow-up pressure'
                                      : 'Chat correction pressure',
                                ),
                                backgroundColor:
                                    AppColors.warning.withValues(alpha: 0.14),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upward chain',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personal or AI2AI intake -> hierarchy synthesis -> reality-model agent',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        if (item.hierarchyPath.isNotEmpty)
                          Text(
                            'Hierarchy path: ${item.hierarchyPath.join(' -> ')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.upwardDomainHints.isNotEmpty)
                          Text(
                            'Domain hints: ${item.upwardDomainHints.join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.upwardReferencedEntities.isNotEmpty)
                          Text(
                            'Referenced entities: ${item.upwardReferencedEntities.join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.upwardQuestions.isNotEmpty)
                          Text(
                            'Questions: ${item.upwardQuestions.join(' | ')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.followUpPromptQuestion?.trim().isNotEmpty ??
                            false)
                          Text(
                            'Follow-up prompt: ${item.followUpPromptQuestion!.trim()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.followUpResponseText?.trim().isNotEmpty ??
                            false)
                          Text(
                            'Follow-up answer: ${item.followUpResponseText!.trim()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.followUpCompletionMode?.trim().isNotEmpty ??
                            false)
                          Text(
                            'Follow-up completion: ${item.followUpCompletionMode!.trim()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.chatObservationSummary != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Chat loop',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Observations: ${item.chatObservationSummary!.totalCount} • ack ${item.chatObservationSummary!.acknowledgedCount} • follow-up ${item.chatObservationSummary!.requestedFollowUpCount} • corrected ${item.chatObservationSummary!.correctedCount}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Latest chat outcome: ${_chatObservationOutcomeLabel(item.chatObservationSummary!.latestOutcome)} • validation ${_chatObservationValidationLabel(item.chatObservationSummary!.latestValidationStatus)} • governance ${_chatObservationGovernanceLabel(item.chatObservationSummary!.latestGovernanceStatus)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            'Open pressure: follow-up ${item.chatObservationSummary!.openRequestedFollowUpCount} • corrected ${item.chatObservationSummary!.openCorrectedCount} • forgot ${item.chatObservationSummary!.openForgotCount} • stop using ${item.chatObservationSummary!.openStoppedUsingCount} • latest attention ${_chatObservationAttentionLabel(item.chatObservationSummary!.latestAttentionStatus)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          if (item.chatObservationSummary!
                                  .latestAttentionDispositionSummary
                                  ?.trim()
                                  .isNotEmpty ??
                              false)
                            Text(
                              'Attention disposition: ${item.chatObservationSummary!.latestAttentionDispositionSummary!.trim()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          if (item.chatObservationSummary!.latestQuestion
                                  ?.trim()
                                  .isNotEmpty ??
                              false)
                            Text(
                              'Latest chat question: ${item.chatObservationSummary!.latestQuestion!.trim()}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (item.chatObservationSummary!.latestFocus
                                  ?.trim()
                                  .isNotEmpty ??
                              false)
                            Text(
                              'Latest chat focus: ${item.chatObservationSummary!.latestFocus!.trim()}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (item.chatObservationSummary!.latestGovernanceStage
                                  ?.trim()
                                  .isNotEmpty ??
                              false)
                            Text(
                              'Latest governance stage: ${_chatObservationStageLabel(item.chatObservationSummary!.latestGovernanceStage)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (item.chatObservationSummary!
                                  .latestGovernanceReason
                                  ?.trim()
                                  .isNotEmpty ??
                              false)
                            Text(
                              'Latest governance reason: ${item.chatObservationSummary!.latestGovernanceReason!.trim()}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                        if (item.upwardSignalTags.isNotEmpty)
                          Text(
                            'Signal tags: ${item.upwardSignalTags.join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.upwardPreferenceSignals.isNotEmpty)
                          Text(
                            'Preference signals: ${_formatPreferenceSignals(item.upwardPreferenceSignals)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.hierarchySynthesisPlanJsonPath != null)
                          Text(
                            'Hierarchy synthesis plan: ${item.hierarchySynthesisPlanJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.hierarchySynthesisOutcomeJsonPath != null)
                          Text(
                            'Hierarchy synthesis outcome: ${item.hierarchySynthesisOutcomeJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelAgentHandoffJsonPath != null)
                          Text(
                            'Reality-model-agent handoff: ${item.realityModelAgentHandoffJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelAgentOutcomeJsonPath != null)
                          Text(
                            'Reality-model-agent outcome: ${item.realityModelAgentOutcomeJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelTruthReviewJsonPath != null)
                          Text(
                            'Truth/conviction review: ${item.realityModelTruthReviewJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.truthIntegrationStatus != null)
                          Text(
                            'Truth integration status: ${item.truthIntegrationStatus}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.truthReviewResolution != null)
                          Text(
                            'Truth review resolution: ${item.truthReviewResolution}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateCandidateJsonPath != null)
                          Text(
                            'Reality-model update candidate: ${item.realityModelUpdateCandidateJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.updateCandidateResolution != null)
                          Text(
                            'Update candidate resolution: ${item.updateCandidateResolution}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateDecisionJsonPath != null)
                          Text(
                            'Reality-model update decision: ${item.realityModelUpdateDecisionJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateOutcomeJsonPath != null)
                          Text(
                            'Reality-model update outcome: ${item.realityModelUpdateOutcomeJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateAdminBriefJsonPath != null)
                          Text(
                            'Admin dashboard brief: ${item.realityModelUpdateAdminBriefJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateSupervisorBriefJsonPath !=
                            null)
                          Text(
                            'Supervisor/daemon brief: ${item.realityModelUpdateSupervisorBriefJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateSimulationSuggestionJsonPath !=
                            null)
                          Text(
                            'Validation simulation suggestion: ${item.realityModelUpdateSimulationSuggestionJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateSimulationRequestJsonPath !=
                            null)
                          Text(
                            'Validation simulation request: ${item.realityModelUpdateSimulationRequestJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateSimulationOutcomeJsonPath !=
                            null)
                          Text(
                            'Validation simulation outcome: ${item.realityModelUpdateSimulationOutcomeJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateDownstreamRepropagationReviewJsonPath !=
                            null)
                          Text(
                            'Downstream re-propagation review: ${item.realityModelUpdateDownstreamRepropagationReviewJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateDownstreamRepropagationDecisionJsonPath !=
                            null)
                          Text(
                            'Downstream re-propagation decision: ${item.realityModelUpdateDownstreamRepropagationDecisionJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateDownstreamRepropagationOutcomeJsonPath !=
                            null)
                          Text(
                            'Downstream re-propagation outcome: ${item.realityModelUpdateDownstreamRepropagationOutcomeJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateDownstreamRepropagationPlanJsonPath !=
                            null)
                          Text(
                            'Downstream re-propagation plan: ${item.realityModelUpdateDownstreamRepropagationPlanJsonPath}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.downstreamRepropagationResolution != null)
                          Text(
                            'Downstream re-propagation resolution: ${item.downstreamRepropagationResolution}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.downstreamRepropagationReleasedTargetIds
                            .isNotEmpty)
                          Text(
                            'Released follow-on lanes: ${item.downstreamRepropagationReleasedTargetIds.join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.realityModelUpdateDownstreamRepropagationPlanJsonPath !=
                            null)
                          Text(
                            'This released lane set is visible through the shared Signature Health snapshot, so admin, supervisor, and assistant observers can all inspect the same bounded follow-on plan.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => context.go(
                                AdminRoutePaths.realitySystemWorldFocusLink(
                                  focus: item.environmentId,
                                  attention:
                                      'upward_learning_handoff:${item.sourceId}',
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open reality-model lane'),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'signatureSourceHealthPromoteTruthReviewButton',
                              ),
                              onPressed: isResolvingTruthReview ||
                                      !item.isReadyForTruthReview
                                  ? null
                                  : () => _resolveTruthReview(
                                        item,
                                        SignatureHealthTruthReviewResolution
                                            .promoteToUpdateCandidate,
                                      ),
                              icon: const Icon(Icons.upgrade_outlined),
                              label: Text(
                                isResolvingTruthReview
                                    ? 'Saving'
                                    : 'Promote to update candidate',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'signatureSourceHealthHoldTruthReviewButton',
                              ),
                              onPressed: isResolvingTruthReview ||
                                      !item.isReadyForTruthReview
                                  ? null
                                  : () => _resolveTruthReview(
                                        item,
                                        SignatureHealthTruthReviewResolution
                                            .holdForMoreEvidence,
                                      ),
                              icon: const Icon(Icons.hourglass_bottom),
                              label: Text(
                                isResolvingTruthReview
                                    ? 'Saving'
                                    : 'Hold for evidence',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'signatureSourceHealthRejectTruthReviewButton',
                              ),
                              onPressed: isResolvingTruthReview ||
                                      !item.isReadyForTruthReview
                                  ? null
                                  : () => _resolveTruthReview(
                                        item,
                                        SignatureHealthTruthReviewResolution
                                            .rejectIntegration,
                                      ),
                              icon: const Icon(Icons.block_outlined),
                              label: Text(
                                isResolvingTruthReview
                                    ? 'Saving'
                                    : 'Reject integration',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'signatureSourceHealthApproveUpdateCandidateButton',
                              ),
                              onPressed: isResolvingUpdateCandidate ||
                                      !item.isReadyForUpdateDecision
                                  ? null
                                  : () => _resolveRealityModelUpdateCandidate(
                                        item,
                                        SignatureHealthRealityModelUpdateResolution
                                            .approveBoundedUpdate,
                                      ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(
                                isResolvingUpdateCandidate
                                    ? 'Saving'
                                    : 'Approve bounded update',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'signatureSourceHealthHoldUpdateCandidateButton',
                              ),
                              onPressed: isResolvingUpdateCandidate ||
                                      !item.isReadyForUpdateDecision
                                  ? null
                                  : () => _resolveRealityModelUpdateCandidate(
                                        item,
                                        SignatureHealthRealityModelUpdateResolution
                                            .holdForMoreEvidence,
                                      ),
                              icon: const Icon(Icons.pause_circle_outline),
                              label: Text(
                                isResolvingUpdateCandidate
                                    ? 'Saving'
                                    : 'Hold update',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'signatureSourceHealthRejectUpdateCandidateButton',
                              ),
                              onPressed: isResolvingUpdateCandidate ||
                                      !item.isReadyForUpdateDecision
                                  ? null
                                  : () => _resolveRealityModelUpdateCandidate(
                                        item,
                                        SignatureHealthRealityModelUpdateResolution
                                            .rejectUpdate,
                                      ),
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(
                                isResolvingUpdateCandidate
                                    ? 'Saving'
                                    : 'Reject update',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'signatureSourceHealthStartValidationSimulationButton',
                              ),
                              onPressed: isStartingValidationSimulation ||
                                      !item.isReadyForValidationSimulationStart
                                  ? null
                                  : () =>
                                      _startRealityModelUpdateValidationSimulation(
                                        item,
                                      ),
                              icon: const Icon(Icons.play_circle_outline),
                              label: Text(
                                isStartingValidationSimulation
                                    ? 'Starting'
                                    : 'Approve validation simulation start',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'signatureSourceHealthApproveDownstreamRepropagationButton',
                              ),
                              onPressed: isResolvingDownstreamRepropagation ||
                                      !item
                                          .isReadyForDownstreamRepropagationDecision
                                  ? null
                                  : () => _resolveDownstreamRepropagationReview(
                                        item,
                                        SignatureHealthDownstreamRepropagationResolution
                                            .approve,
                                      ),
                              icon: const Icon(Icons.redo_outlined),
                              label: Text(
                                isResolvingDownstreamRepropagation
                                    ? 'Saving'
                                    : 'Approve downstream re-propagation',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'signatureSourceHealthRejectDownstreamRepropagationButton',
                              ),
                              onPressed: isResolvingDownstreamRepropagation ||
                                      !item
                                          .isReadyForDownstreamRepropagationDecision
                                  ? null
                                  : () => _resolveDownstreamRepropagationReview(
                                        item,
                                        SignatureHealthDownstreamRepropagationResolution
                                            .reject,
                                      ),
                              icon: const Icon(Icons.block_outlined),
                              label: Text(
                                isResolvingDownstreamRepropagation
                                    ? 'Saving'
                                    : 'Reject downstream re-propagation',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoundedReviewQueueSection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final candidates = List<SignatureHealthBoundedReviewCandidate>.from(
      snapshot.boundedReviewCandidates,
    )..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    final downgradedTargets = snapshot.labTargetActionItems
        .where((item) => !item.isBoundedReviewCandidate)
        .toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    final reviewQueueEnvironmentLabels = _reviewQueueEnvironmentLabels(
      candidates,
      downgradedTargets,
    );
    final selectedReviewQueueEnvironmentId = reviewQueueEnvironmentLabels
            .containsKey(_selectedReviewQueueEnvironmentId)
        ? _selectedReviewQueueEnvironmentId
        : null;
    final servedBasisSummaries = _filterServedBasisSummaries(
      snapshot.servedBasisSummaries,
      selectedReviewQueueEnvironmentId,
    );
    final familyRestageIntakeReviewSummaries =
        _filterFamilyRestageIntakeReviewSummaries(
      snapshot.familyRestageIntakeReviewSummaries,
      selectedReviewQueueEnvironmentId,
    );
    final environmentFilteredCandidates = _filterActiveBoundedReviewCandidates(
      candidates,
      selectedReviewQueueEnvironmentId,
    );
    final environmentFilteredDowngradedTargets = _filterDowngradedLabTargets(
      downgradedTargets,
      selectedReviewQueueEnvironmentId,
    );
    final reviewQueueTargetLabels = _reviewQueueTargetLabels(
      environmentFilteredCandidates,
      environmentFilteredDowngradedTargets,
    );
    final selectedReviewQueueTargetKey =
        reviewQueueTargetLabels.containsKey(_selectedReviewQueueTargetKey)
            ? _selectedReviewQueueTargetKey
            : null;
    final filteredCandidates = _rankActiveBoundedReviewCandidates(
      _filterActiveBoundedReviewCandidatesByTarget(
        environmentFilteredCandidates,
        selectedReviewQueueTargetKey,
      ),
      _reviewQueueSortMode,
    );
    final filteredDowngradedTargets = _rankDowngradedLabTargets(
      _filterDowngradedLabTargetsByTarget(
        environmentFilteredDowngradedTargets,
        selectedReviewQueueTargetKey,
      ),
      _reviewQueueSortMode,
    );
    final visibleBoundedAlertTargets = _visibleUnacknowledgedBoundedAlerts(
      filteredCandidates,
      filteredDowngradedTargets,
    );
    final visibleOperatorActionableBoundedAlertTargets =
        _visibleOperatorActionableBoundedAlerts(
      filteredCandidates,
      filteredDowngradedTargets,
    );
    final visibleEscalatedBoundedAlertTargets = _visibleEscalatedBoundedAlerts(
      filteredCandidates,
      filteredDowngradedTargets,
    );
    final visibleSnoozedBoundedAlertTargets = _visibleSnoozedBoundedAlerts(
      filteredCandidates,
      filteredDowngradedTargets,
    );
    final hasVisibleBoundedAlerts = _hasVisibleBoundedAlerts(
      filteredCandidates,
      filteredDowngradedTargets,
    );
    return Card(
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hydration: ${_servedBasisStatusLabel(summary.latestStateHydrationStatus)} • Readiness: ${_servedBasisStatusLabel(summary.latestStatePromotionReadiness)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          if ((summary.cityPackStructuralRef ?? '').isNotEmpty)
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
                          if ((summary.latestStateRevalidationReceiptRef ?? '')
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
                                AdminRoutePaths.worldSimulationLabFocusLink(
                                  focus: summary.environmentId,
                                  attention:
                                      _servedBasisRecoveryAttention(summary),
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open recovery review in lab'),
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
                              style: Theme.of(context).textTheme.titleSmall,
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
                                    if ((summary.followUpReviewItemId ?? '')
                                        .isNotEmpty)
                                      'Follow-up review item: ${summary.followUpReviewItemId}',
                                    if ((summary.followUpQueueJsonPath ?? '')
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
                                (summary.followUpResolutionArtifactRef ?? '')
                                    .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  [
                                    if ((summary.followUpResolutionStatus ?? '')
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
                            if ((summary.restageResolutionReviewItemId ?? '')
                                    .isNotEmpty ||
                                (summary.restageResolutionQueueJsonPath ?? '')
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
                            if ((summary.restageExecutionQueueStatus ?? '')
                                    .isNotEmpty ||
                                (summary.restageExecutionQueueJsonPath ?? '')
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
                            if ((summary.restageExecutionResolutionStatus ?? '')
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
                            if ((summary.restageApplicationQueueStatus ?? '')
                                    .isNotEmpty ||
                                (summary.restageApplicationQueueJsonPath ?? '')
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
                                    if ((summary.restageApplyQueueStatus ?? '')
                                        .isNotEmpty)
                                      'Apply queue: ${summary.restageApplyQueueStatus}',
                                    if ((summary.restageApplyReviewItemId ?? '')
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
                            if ((summary.restageApplyResolutionStatus ?? '')
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
                            const SizedBox(height: 8),
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
                                AdminRoutePaths.worldSimulationLabFocusLink(
                                  focus: summary.environmentId,
                                  attention: 'family_restage_intake_review',
                                ),
                              ),
                              icon: const Icon(Icons.playlist_add_check),
                              label: const Text('Open intake review in lab'),
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
            Text(
              candidates.isNotEmpty && downgradedTargets.isNotEmpty
                  ? 'Persisted World Simulation Lab decisions are grouped here by current routing posture, so active bounded-review candidates and downgraded watch/iterate targets remain visible together.'
                  : candidates.isNotEmpty
                      ? 'Persisted World Simulation Lab decisions surface here so bounded review candidates are visible before they become downstream propagation approvals.'
                      : downgradedTargets.isNotEmpty
                          ? 'No target is currently in the active bounded-review queue, but downgraded watch/iterate targets are still preserved here so operators can see the latest routing posture.'
                          : 'No World Simulation Lab targets are currently marked for bounded review.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Within each queue, higher-risk routing posture and stronger runtime regression signals rise first.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
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
                      selected: selectedReviewQueueEnvironmentId == entry.key,
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
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
                      selected: selectedReviewQueueTargetKey == entry.key,
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (filteredCandidates.length + filteredDowngradedTargets.length >
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
            if (filteredCandidates.isNotEmpty ||
                filteredDowngradedTargets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _reviewQueueEscalationSummary(
                  filteredCandidates,
                  filteredDowngradedTargets,
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
              snapshot.generatedAt,
            ),
            if (candidates.isEmpty && downgradedTargets.isEmpty) ...[
              const SizedBox(height: 12),
              const Text('No bounded review candidates yet.')
            ] else ...[
              if (candidates.isNotEmpty) ...[
                const SizedBox(height: 12),
                ExpansionTile(
                  key: PageStorageKey<String>(
                    'signature_source_health_active_bounded_review_candidates_${selectedReviewQueueEnvironmentId ?? 'all'}',
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
                        ? '${filteredCandidates.length} visible'
                        : '${filteredCandidates.length} visible for ${reviewQueueEnvironmentLabels[selectedReviewQueueEnvironmentId]}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  children: [
                    const SizedBox(height: 8),
                    if (filteredCandidates.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No active bounded-review candidates match the current environment filter.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ...filteredCandidates.take(6).map(
                            (candidate) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${candidate.cityCode.toUpperCase()} • ${candidate.displayName}',
                                    ),
                                    subtitle: Text(
                                      'Target: ${candidate.targetLabel}\nSuggested reason: ${candidate.suggestedReason.isEmpty ? 'No reason recorded.' : candidate.suggestedReason}',
                                    ),
                                    trailing: Chip(
                                      label: const Text(
                                          'Bounded review candidate'),
                                      backgroundColor: AppColors.warning
                                          .withValues(alpha: 0.12),
                                    ),
                                  ),
                                  Text(
                                    'Latest lab outcome: ${_boundedReviewOutcomeLabel(candidate.latestOutcomeDisposition)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Current routing posture: ${_labTargetActionLabel(candidate.selectedAction)} • Operator ${candidate.acceptedSuggestion ? 'accepted the suggested route' : 'overrode the suggested route'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                  ),
                                  if (_boundedReviewRerunStatusLabel(
                                          candidate) !=
                                      null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Latest rerun: ${_boundedReviewRerunStatusLabel(candidate)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                    ),
                                  if (_labTargetTrendHistoryLabel(
                                          candidate.trendSummary) !=
                                      null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _labTargetTrendHistoryLabel(
                                            candidate.trendSummary)!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                    ),
                                  if (candidate.trendSummary != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        candidate
                                            .trendSummary!.runtimeTrendSummary,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                    ),
                                  if (candidate.trendSummary != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        candidate
                                            .trendSummary!.runtimeDeltaSummary,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                    ),
                                  if (candidate.trendSummary != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        candidate
                                            .trendSummary!.outcomeTrendSummary,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                    ),
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
                                    targetKey:
                                        _boundedReviewTargetKey(candidate),
                                    environmentId: candidate.environmentId,
                                    variantId: candidate.variantId,
                                    boundedAlertSummary:
                                        candidate.boundedAlertSummary,
                                    isCurrentAlertAcknowledged: candidate
                                        .isCurrentBoundedAlertAcknowledged,
                                    alertAcknowledgedAt:
                                        candidate.alertAcknowledgedAt,
                                  ),
                                  _buildLabTargetAlertOperatorStateRow(
                                    context: context,
                                    targetKey:
                                        _boundedReviewTargetKey(candidate),
                                    environmentId: candidate.environmentId,
                                    variantId: candidate.variantId,
                                    boundedAlertSummary:
                                        candidate.boundedAlertSummary,
                                    isCurrentAlertEscalated: candidate
                                        .isCurrentBoundedAlertEscalated,
                                    alertEscalatedAt:
                                        candidate.alertEscalatedAt,
                                    isCurrentAlertSnoozed:
                                        candidate.isCurrentBoundedAlertSnoozed,
                                    alertSnoozedUntil:
                                        candidate.alertSnoozedUntil,
                                    snapshotGeneratedAt: snapshot.generatedAt,
                                  ),
                                  _buildLabTargetProvenanceEmphasisSection(
                                    context,
                                    candidate.provenanceEmphasisSummary,
                                  ),
                                  _buildLabTargetProvenanceHistorySection(
                                    context,
                                    candidate.provenanceHistorySummary,
                                  ),
                                  if ((candidate.cityPackStructuralRef ?? '')
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'City-pack structural ref: ${candidate.cityPackStructuralRef}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.textSecondary),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => context.go(
                                            AdminRoutePaths.worldSimulationLab),
                                        icon:
                                            const Icon(Icons.science_outlined),
                                        label: const Text(
                                            'Open World Simulation Lab'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => context.go(
                                          AdminRoutePaths
                                              .realitySystemRealityFocusLink(
                                            focus: candidate.environmentId,
                                            attention:
                                                'bounded_review_candidate:${candidate.variantId ?? 'base_run'}',
                                          ),
                                        ),
                                        icon: const Icon(
                                            Icons.psychology_alt_outlined),
                                        label:
                                            const Text('Open bounded review'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ],
              if (downgradedTargets.isNotEmpty) ...[
                const SizedBox(height: 12),
                ExpansionTile(
                  key: PageStorageKey<String>(
                    'signature_source_health_downgraded_lab_targets_${selectedReviewQueueEnvironmentId ?? 'all'}',
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
                        ? '${filteredDowngradedTargets.length} visible'
                        : '${filteredDowngradedTargets.length} visible for ${reviewQueueEnvironmentLabels[selectedReviewQueueEnvironmentId]}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  children: [
                    const SizedBox(height: 8),
                    if (filteredDowngradedTargets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No downgraded targets match the current environment filter.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ...filteredDowngradedTargets.take(6).map(
                            (target) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${target.cityCode.toUpperCase()} • ${target.displayName}',
                                    ),
                                    subtitle: Text(
                                      'Target: ${target.targetLabel}\nCurrent routing posture: ${_labTargetActionLabel(target.selectedAction)}',
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        _labTargetActionLabel(
                                            target.selectedAction),
                                      ),
                                      backgroundColor:
                                          AppColors.grey200.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Operator ${target.acceptedSuggestion ? 'accepted the suggested route' : 'overrode the suggested route'} for this target. It is not currently queued for bounded review.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Suggested reason: ${target.suggestedReason.isEmpty ? 'No reason recorded.' : target.suggestedReason}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Latest lab outcome: ${_boundedReviewOutcomeLabel(target.latestOutcomeDisposition)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                  if (_labTargetActionRerunStatusLabel(
                                          target) !=
                                      null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Latest rerun: ${_labTargetActionRerunStatusLabel(target)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if (_labTargetTrendHistoryLabel(
                                          target.trendSummary) !=
                                      null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _labTargetTrendHistoryLabel(
                                            target.trendSummary)!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if (target.trendSummary != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        target
                                            .trendSummary!.runtimeTrendSummary,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if (target.trendSummary != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        target
                                            .trendSummary!.runtimeDeltaSummary,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  if (target.trendSummary != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        target
                                            .trendSummary!.outcomeTrendSummary,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  _buildLabTargetProvenanceDeltaSection(
                                    context,
                                    target.provenanceDeltaSummary,
                                  ),
                                  _buildLabTargetBoundedAlertSection(
                                    context,
                                    target.boundedAlertSummary,
                                  ),
                                  _buildLabTargetAlertAcknowledgmentRow(
                                    context: context,
                                    targetKey:
                                        _labTargetActionTargetKey(target),
                                    environmentId: target.environmentId,
                                    variantId: target.variantId,
                                    boundedAlertSummary:
                                        target.boundedAlertSummary,
                                    isCurrentAlertAcknowledged: target
                                        .isCurrentBoundedAlertAcknowledged,
                                    alertAcknowledgedAt:
                                        target.alertAcknowledgedAt,
                                  ),
                                  _buildLabTargetAlertOperatorStateRow(
                                    context: context,
                                    targetKey:
                                        _labTargetActionTargetKey(target),
                                    environmentId: target.environmentId,
                                    variantId: target.variantId,
                                    boundedAlertSummary:
                                        target.boundedAlertSummary,
                                    isCurrentAlertEscalated:
                                        target.isCurrentBoundedAlertEscalated,
                                    alertEscalatedAt: target.alertEscalatedAt,
                                    isCurrentAlertSnoozed:
                                        target.isCurrentBoundedAlertSnoozed,
                                    alertSnoozedUntil: target.alertSnoozedUntil,
                                    snapshotGeneratedAt: snapshot.generatedAt,
                                  ),
                                  _buildLabTargetProvenanceEmphasisSection(
                                    context,
                                    target.provenanceEmphasisSummary,
                                  ),
                                  _buildLabTargetProvenanceHistorySection(
                                    context,
                                    target.provenanceHistorySummary,
                                  ),
                                  if ((target.cityPackStructuralRef ?? '')
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'City-pack structural ref: ${target.cityPackStructuralRef}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => context.go(
                                            AdminRoutePaths.worldSimulationLab),
                                        icon:
                                            const Icon(Icons.science_outlined),
                                        label: const Text(
                                            'Open World Simulation Lab'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => context.go(
                                          AdminRoutePaths
                                              .realitySystemRealityFocusLink(
                                            focus: target.environmentId,
                                          ),
                                        ),
                                        icon: const Icon(
                                            Icons.psychology_alt_outlined),
                                        label: const Text(
                                            'Open Reality Oversight'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
    SignatureHealthCategory category,
  ) {
    final records =
        snapshot.byCategory[category] ?? const <SignatureHealthRecord>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              records.isEmpty
                  ? 'No sources currently grouped here.'
                  : '${records.length} sources currently grouped here.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...records.take(6).map(
                  (record) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(record.sourceLabel ?? record.sourceId),
                    subtitle: Text(record.summary),
                    trailing: Text(
                      '${(record.confidence * 100).round()}% / ${(record.freshness * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedSection(
    BuildContext context, {
    required String title,
    required Map<String, List<SignatureHealthRecord>> grouped,
  }) {
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries
                  .map((entry) =>
                      Chip(label: Text('${entry.key}: ${entry.value.length}')))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewQueueSection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final reviewItems = snapshot.reviewItems;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Queue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              reviewItems.isEmpty
                  ? 'No intake reviews are currently queued.'
                  : 'Local-first intake reviews waiting on operator attention, including simulation-training candidates and upward learning reviews.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (reviewItems.isEmpty)
              const Text('Queue is clear.')
            else
              ...reviewItems.take(6).map(
                (item) {
                  final isResolving = _resolvingReviewItemIds.contains(item.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.title),
                          subtitle: Text(
                            _buildReviewQueueSummary(item),
                          ),
                          trailing: item.isSimulationTrainingIntake
                              ? Chip(
                                  label: const Text('Simulation training'),
                                  backgroundColor:
                                      AppColors.accent.withValues(alpha: 0.12),
                                )
                              : item.isUpwardLearningReview
                                  ? Chip(
                                      label: const Text('Upward learning'),
                                      backgroundColor: AppColors.accent
                                          .withValues(alpha: 0.12),
                                    )
                                  : Text(
                                      item.targetType,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: item.isSimulationTrainingIntake
                                  ? () => context.go(
                                        AdminRoutePaths
                                            .realitySystemRealityFocusLink(
                                          focus: item.environmentId,
                                          attention:
                                              'simulation_training_intake:${item.sourceId}',
                                        ),
                                      )
                                  : item.isUpwardLearningReview
                                      ? () => context.go(
                                            AdminRoutePaths
                                                .realitySystemWorldFocusLink(
                                              focus: item.environmentId,
                                              attention:
                                                  'upward_learning_review:${item.sourceId}',
                                            ),
                                          )
                                      : null,
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open reality lane'),
                            ),
                            OutlinedButton.icon(
                              onPressed: isResolving
                                  ? null
                                  : () => _resolveReviewItem(
                                        item,
                                        SignatureHealthReviewResolution
                                            .approved,
                                      ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(
                                isResolving ? 'Saving' : 'Accept',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: isResolving
                                  ? null
                                  : () => _resolveReviewItem(
                                        item,
                                        SignatureHealthReviewResolution
                                            .rejected,
                                      ),
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(
                                isResolving ? 'Saving' : 'Reject',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKernelGraphRunSection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final runs = snapshot.kernelGraphRuns;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent KernelGraph runs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              runs.isEmpty
                  ? 'No persisted KernelGraph runs are available yet for this operator surface.'
                  : 'Recent compiled runtime intake graphs, persisted as receipts and digests so operators can inspect the bounded workflow lane without reopening raw storage.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (runs.isEmpty)
              const Text('KernelGraph run ledger is empty.')
            else
              ...runs.take(6).map(
                    (run) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(run.graphTitle),
                            subtitle: Text(run.adminDigest.summary),
                            trailing: Chip(
                              label: Text(_kernelGraphStatusLabel(run.status)),
                              backgroundColor:
                                  _kernelGraphStatusColor(run.status)
                                      .withValues(alpha: 0.12),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(_kernelGraphKindLabel(run.kind)),
                              ),
                              Chip(
                                label: Text(
                                  '${run.adminDigest.completedNodeCount}/${run.adminDigest.totalNodeCount} nodes',
                                ),
                              ),
                              if ((run.sourceKind ?? '').isNotEmpty)
                                Chip(
                                  label: Text(
                                    (run.sourceKind ?? '').replaceAll('_', ' '),
                                  ),
                                ),
                              if (run.adminDigest.requiresHumanReview)
                                Chip(
                                  label: const Text('Human review'),
                                  backgroundColor:
                                      AppColors.warning.withValues(alpha: 0.12),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Run ${run.runId} | source ${run.sourceId ?? 'unknown'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => context.go(
                              AdminRoutePaths.kernelGraphRunDetail(run.runId),
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open details'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _kernelGraphStatusLabel(KernelGraphRunStatus status) {
    return switch (status) {
      KernelGraphRunStatus.queued => 'queued',
      KernelGraphRunStatus.running => 'running',
      KernelGraphRunStatus.completed => 'completed',
      KernelGraphRunStatus.failed => 'failed',
    };
  }

  Color _kernelGraphStatusColor(KernelGraphRunStatus status) {
    return switch (status) {
      KernelGraphRunStatus.completed => AppColors.success,
      KernelGraphRunStatus.running => AppColors.accent,
      KernelGraphRunStatus.queued => AppColors.warning,
      KernelGraphRunStatus.failed => AppColors.error,
    };
  }

  String _kernelGraphKindLabel(KernelGraphKind kind) {
    return switch (kind) {
      KernelGraphKind.learningIntake => 'learning intake',
      KernelGraphKind.governedRun => 'governed run',
      KernelGraphKind.securityCampaign => 'security campaign',
      KernelGraphKind.autoresearch => 'autoresearch',
      KernelGraphKind.adminProjection => 'admin projection',
    };
  }

  String _buildReviewQueueSummary(SignatureHealthReviewQueueItem item) {
    final parts = <String>[
      item.summary,
      'Source: ${item.sourceId}',
      'Environment: ${item.environmentId}',
    ];
    if (item.suggestedTrainingUse != null &&
        item.suggestedTrainingUse!.isNotEmpty) {
      parts.add('Training use: ${item.suggestedTrainingUse}');
    }
    if (item.intakeFlowRefs.isNotEmpty) {
      parts.add('Intake flows: ${item.intakeFlowRefs.join(', ')}');
    }
    if (item.cityPackStructuralRef != null &&
        item.cityPackStructuralRef!.isNotEmpty) {
      parts.add('City-pack structural ref: ${item.cityPackStructuralRef}');
    }
    if (item.sidecarRefs.isNotEmpty) {
      parts.add('Sidecars: ${item.sidecarRefs.join(', ')}');
    }
    if (item.trainingManifestJsonPath != null &&
        item.trainingManifestJsonPath!.isNotEmpty) {
      parts.add('Manifest: ${item.trainingManifestJsonPath}');
    }
    if (item.isUpwardLearningReview) {
      if (item.sourceKind != null && item.sourceKind!.isNotEmpty) {
        parts.add('Source kind: ${item.sourceKind}');
      }
      if (item.convictionTier != null && item.convictionTier!.isNotEmpty) {
        parts.add('Conviction tier: ${item.convictionTier}');
      }
      if (item.hierarchyPath.isNotEmpty) {
        parts.add('Hierarchy path: ${item.hierarchyPath.join(' -> ')}');
      }
      if (item.upwardDomainHints.isNotEmpty) {
        parts.add('Domain hints: ${item.upwardDomainHints.join(', ')}');
      }
      if (item.upwardReferencedEntities.isNotEmpty) {
        parts.add(
          'Referenced entities: ${item.upwardReferencedEntities.join(', ')}',
        );
      }
      if (item.upwardQuestions.isNotEmpty) {
        parts.add('Questions: ${item.upwardQuestions.join(' | ')}');
      }
      if (item.followUpPromptQuestion?.trim().isNotEmpty ?? false) {
        parts.add('Follow-up prompt: ${item.followUpPromptQuestion!.trim()}');
      }
      if (item.followUpResponseText?.trim().isNotEmpty ?? false) {
        parts.add('Follow-up answer: ${item.followUpResponseText!.trim()}');
      }
      if (item.followUpCompletionMode?.trim().isNotEmpty ?? false) {
        parts.add(
          'Follow-up completion: ${item.followUpCompletionMode!.trim()}',
        );
      }
      if (item.upwardSignalTags.isNotEmpty) {
        parts.add('Signal tags: ${item.upwardSignalTags.join(', ')}');
      }
      if (item.upwardPreferenceSignals.isNotEmpty) {
        parts.add(
          'Preference signals: ${_formatPreferenceSignals(item.upwardPreferenceSignals)}',
        );
      }
    }
    return parts.join('\n');
  }

  String _formatPreferenceSignals(List<Map<String, dynamic>> signals) {
    return signals.map((signal) {
      final kind = signal['kind']?.toString().trim();
      final value = signal['value']?.toString().trim();
      if (kind != null &&
          kind.isNotEmpty &&
          value != null &&
          value.isNotEmpty) {
        return '$kind=$value';
      }
      if (kind != null && kind.isNotEmpty) {
        return kind;
      }
      if (value != null && value.isNotEmpty) {
        return value;
      }
      return 'signal';
    }).join(', ');
  }

  Widget _buildFeedbackIntentSection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final grouped = snapshot.feedbackByIntent;
    final softIgnore =
        grouped['soft_ignore'] ?? const <SignatureHealthRecord>[];
    final hardReject =
        grouped['hard_not_interested'] ?? const <SignatureHealthRecord>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live feedback intent',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tracks whether users are softly passing for now or explicitly rejecting recommendations.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _kpiChip('Soft ignore', softIgnore.length),
                _kpiChip('Hard reject', hardReject.length),
              ],
            ),
            if (snapshot.feedbackRecords.isEmpty) ...[
              const SizedBox(height: 12),
              const Text('No live feedback telemetry captured yet.'),
            ] else ...[
              const SizedBox(height: 12),
              ...snapshot.feedbackRecords.take(8).map(
                    (record) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(record.sourceLabel ?? record.categoryLabel),
                      subtitle: Text(record.summary),
                      trailing: Text(record.categoryLabel),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackTrendSection(
    BuildContext context,
    SignatureHealthSnapshot snapshot,
  ) {
    final trendRows = snapshot.buildFeedbackTrendRows();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback trend by entity type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Shows where soft passes or hard rejections are clustering across the last 24 hours, 7 days, and 30 days.',
            ),
            if (trendRows.isEmpty) ...[
              const SizedBox(height: 12),
              const Text('No feedback trend data available yet.'),
            ] else ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Entity type')),
                    DataColumn(label: Text('24h')),
                    DataColumn(label: Text('7d')),
                    DataColumn(label: Text('30d')),
                  ],
                  rows: trendRows.take(8).map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(row.entityType)),
                        for (final window
                            in SignatureHealthSnapshot.feedbackTrendWindows)
                          DataCell(
                            _trendCell(row.countsByWindow[window.label]!),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trendCell(FeedbackTrendCount count) {
    return Text('${count.softIgnoreCount}/${count.hardNotInterestedCount}');
  }

  Widget _buildRecordsTable(List<SignatureHealthRecord> records) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entity Health Table',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Source')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Entity')),
                  DataColumn(label: Text('Provider')),
                  DataColumn(label: Text('Metro')),
                  DataColumn(label: Text('Confidence')),
                  DataColumn(label: Text('Freshness')),
                ],
                rows: records
                    .take(20)
                    .map(
                      (record) => DataRow(
                        cells: [
                          DataCell(Text(record.sourceLabel ?? record.sourceId)),
                          DataCell(Text(record.healthCategory.label)),
                          DataCell(Text(record.entityType)),
                          DataCell(Text(record.provider)),
                          DataCell(Text(record.metroLabel)),
                          DataCell(
                              Text('${(record.confidence * 100).round()}%')),
                          DataCell(
                              Text('${(record.freshness * 100).round()}%')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.dashboard_customize_outlined),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      ),
    );
  }

  Widget _kpiChip(String label, int value) {
    return Chip(label: Text('$label: $value'));
  }
}
