import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:avrai_runtime_os/services/security/immune_memory_ledger.dart';
import 'package:avrai_runtime_os/services/security/security_kernel_release_gate_service.dart';

class CountermeasurePropagationService {
  CountermeasurePropagationService({
    required GovernanceKernelService governanceKernelService,
    required ImmuneMemoryLedger immuneMemoryLedger,
    SecurityKernelReleaseGateService? securityReleaseGateService,
    DateTime Function()? nowProvider,
  })  : _governanceKernelService = governanceKernelService,
        _immuneMemoryLedger = immuneMemoryLedger,
        _securityReleaseGateService = securityReleaseGateService,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final GovernanceKernelService _governanceKernelService;
  final ImmuneMemoryLedger _immuneMemoryLedger;
  final SecurityKernelReleaseGateService? _securityReleaseGateService;
  final DateTime Function() _nowProvider;
  static const int _maxTargetFanOut = 8;
  static const Duration _defaultAckDeadline = Duration(hours: 6);

  Future<List<CountermeasurePropagationReceipt>> propagateCandidate({
    required CountermeasureBundleCandidate candidate,
    required TruthEvidenceEnvelope evidenceEnvelope,
    List<TruthScopeDescriptor>? targetScopes,
  }) async {
    final review = _governanceKernelService.reviewCountermeasureBundle(
      bundle: candidate.bundle,
      evidenceEnvelope: evidenceEnvelope,
      metadata: const <String, dynamic>{'propagation_mode': 'staged'},
    );
    if (!review.isApproved) {
      throw StateError(
        'Countermeasure propagation rejected by governance: '
        '${review.reasonCodes.join(", ")}',
      );
    }
    final validationReasons = _validateBundleForPropagation(
      candidate: candidate,
      targetScopes: targetScopes,
    );
    if (validationReasons.isNotEmpty) {
      throw StateError(
        'Countermeasure propagation rejected: ${validationReasons.join(", ")}',
      );
    }
    final distinctTargets = <String, TruthScopeDescriptor>{
      for (final scope in (targetScopes ??
          <TruthScopeDescriptor>[candidate.bundle.targetScope]))
        scope.scopeKey: scope,
    };
    if (distinctTargets.length > _maxTargetFanOut) {
      throw StateError(
        'Countermeasure propagation fan-out exceeds bounded maximum of $_maxTargetFanOut targets.',
      );
    }
    final receipts = <CountermeasurePropagationReceipt>[];
    final requiredApprovalsSatisfied = candidate.bundle.requiredApprovals.every(
      candidate.approvalActors.contains,
    );
    for (final scope in distinctTargets.values) {
      final receipt = CountermeasurePropagationReceipt(
        receiptId:
            'receipt_${candidate.candidateId}_${scope.scopeKey.hashCode.abs()}',
        bundleId: candidate.bundle.bundleId,
        targetScope: scope,
        sourceStratum: candidate.bundle.targetScope.governanceStratum,
        targetStratum: scope.governanceStratum,
        activationStage: 'shadow',
        requiredAcknowledgements: candidate.bundle.minimumAcknowledgements,
        acknowledgedCount: 0,
        acknowledgedAt: _nowProvider(),
        driftDetected: false,
        staleNode: false,
        rolledBack: false,
        approvalGranted:
            review.propagationAuthorized && requiredApprovalsSatisfied,
        activationDeadlineAt: _nowProvider().add(_defaultAckDeadline),
        metadata: <String, dynamic>{
          'candidate_id': candidate.candidateId,
          'approved_by': candidate.approvalActors,
          'propagation_authorized': review.propagationAuthorized,
        },
      );
      await _immuneMemoryLedger.recordPropagationReceipt(receipt);
      receipts.add(receipt);
    }
    await _immuneMemoryLedger.upsertBundleCandidate(
      CountermeasureBundleCandidate(
        candidateId: candidate.candidateId,
        status: CountermeasureBundleCandidateStatus.shadowValidated,
        bundle: candidate.bundle,
        createdAt: candidate.createdAt,
        updatedAt: _nowProvider(),
        sourceFindingIds: candidate.sourceFindingIds,
        shadowValidationEvidenceTraceIds: <String>[
          ...candidate.shadowValidationEvidenceTraceIds,
          evidenceEnvelope.traceId,
        ],
        approvalActors: candidate.approvalActors,
        metadata: <String, dynamic>{
          ...candidate.metadata,
          'last_rollout_stage': 'shadow',
        },
      ),
    );
    return receipts;
  }

  Future<CountermeasurePropagationReceipt> acknowledgeReceipt({
    required String receiptId,
    required String actorAlias,
  }) async {
    final existing = _immuneMemoryLedger.propagationReceiptById(receiptId);
    if (existing == null) {
      throw StateError('Unknown propagation receipt: $receiptId');
    }
    final updated = CountermeasurePropagationReceipt(
      receiptId: existing.receiptId,
      bundleId: existing.bundleId,
      targetScope: existing.targetScope,
      sourceStratum: existing.sourceStratum,
      targetStratum: existing.targetStratum,
      activationStage: existing.activationStage == 'shadow'
          ? 'staged'
          : existing.activationStage,
      requiredAcknowledgements: existing.requiredAcknowledgements,
      acknowledgedCount: existing.acknowledgedCount + 1,
      acknowledgedAt: _nowProvider(),
      driftDetected: existing.driftDetected,
      staleNode: false,
      rolledBack: existing.rolledBack,
      approvalGranted: existing.approvalGranted,
      activationDeadlineAt: existing.activationDeadlineAt,
      activatedAt: existing.activatedAt,
      rolledBackAt: existing.rolledBackAt,
      rollbackReason: existing.rollbackReason,
      metadata: <String, dynamic>{
        ...existing.metadata,
        'last_acknowledged_by': actorAlias,
      },
    );
    await _immuneMemoryLedger.recordPropagationReceipt(updated);
    final candidate = _immuneMemoryLedger.bundleCandidateByBundleId(
      existing.bundleId,
    );
    if (candidate != null) {
      await _immuneMemoryLedger.upsertBundleCandidate(
        CountermeasureBundleCandidate(
          candidateId: candidate.candidateId,
          status: CountermeasureBundleCandidateStatus.stagedRollout,
          bundle: candidate.bundle,
          createdAt: candidate.createdAt,
          updatedAt: _nowProvider(),
          sourceFindingIds: candidate.sourceFindingIds,
          shadowValidationEvidenceTraceIds:
              candidate.shadowValidationEvidenceTraceIds,
          approvalActors: candidate.approvalActors,
          metadata: <String, dynamic>{
            ...candidate.metadata,
            'last_rollout_stage': 'staged',
            'last_acknowledged_by': actorAlias,
          },
        ),
      );
    }
    return updated;
  }

  Future<List<CountermeasurePropagationReceipt>> activateBundle(
    String bundleId, {
    String actorAlias = 'security_kernel',
    bool operatorApproved = false,
  }) async {
    final candidate = _immuneMemoryLedger.bundleCandidateByBundleId(bundleId);
    if (candidate == null) {
      throw StateError('Unknown bundle candidate for bundle $bundleId');
    }
    final gateService = _securityReleaseGateService;
    if (gateService != null) {
      final gateDecision = await gateService.evaluateRuntimeBundleActivation(
        bundleId: bundleId,
        scope: candidate.bundle.targetScope,
        actorAlias: actorAlias,
        operatorApproved: operatorApproved,
        metadata: <String, dynamic>{
          'required_approvals': candidate.bundle.requiredApprovals,
          'minimum_acknowledgements': candidate.bundle.minimumAcknowledgements,
        },
      );
      if (!gateDecision.servingAllowed) {
        throw StateError(
          'Runtime bundle activation blocked by security release gate: '
          '${gateDecision.reasonCodes.join(", ")}',
        );
      }
    }
    final receipts = _immuneMemoryLedger.propagationReceiptsForBundle(bundleId);
    if (receipts.isEmpty) {
      return const <CountermeasurePropagationReceipt>[];
    }
    if (receipts.any((entry) => !entry.approvalGranted)) {
      throw StateError('Bundle $bundleId is not approved for activation.');
    }
    if (receipts.any((entry) => entry.driftDetected || entry.staleNode)) {
      throw StateError(
          'Bundle $bundleId cannot activate while drift/stale-node flags are present.');
    }
    if (receipts.any(
      (entry) => entry.acknowledgedCount < entry.requiredAcknowledgements,
    )) {
      throw StateError('Bundle $bundleId lacks required acknowledgements.');
    }

    final now = _nowProvider();
    final updated = <CountermeasurePropagationReceipt>[];
    for (final entry in receipts) {
      final receipt = CountermeasurePropagationReceipt(
        receiptId: entry.receiptId,
        bundleId: entry.bundleId,
        targetScope: entry.targetScope,
        sourceStratum: entry.sourceStratum,
        targetStratum: entry.targetStratum,
        activationStage: 'active',
        requiredAcknowledgements: entry.requiredAcknowledgements,
        acknowledgedCount: entry.acknowledgedCount,
        acknowledgedAt: entry.acknowledgedAt,
        driftDetected: entry.driftDetected,
        staleNode: entry.staleNode,
        rolledBack: false,
        approvalGranted: entry.approvalGranted,
        activationDeadlineAt: entry.activationDeadlineAt,
        activatedAt: now,
        rolledBackAt: entry.rolledBackAt,
        rollbackReason: entry.rollbackReason,
        metadata: entry.metadata,
      );
      await _immuneMemoryLedger.recordPropagationReceipt(receipt);
      updated.add(receipt);
    }
    await _immuneMemoryLedger.upsertBundleCandidate(
      CountermeasureBundleCandidate(
        candidateId: candidate.candidateId,
        status: CountermeasureBundleCandidateStatus.active,
        bundle: candidate.bundle,
        createdAt: candidate.createdAt,
        updatedAt: now,
        sourceFindingIds: candidate.sourceFindingIds,
        shadowValidationEvidenceTraceIds:
            candidate.shadowValidationEvidenceTraceIds,
        approvalActors: candidate.approvalActors,
        metadata: <String, dynamic>{
          ...candidate.metadata,
          'last_rollout_stage': 'active',
        },
      ),
    );
    await _recordLearningMoment(
      bundleId: bundleId,
      truthScope: candidate.bundle.targetScope,
      summary: 'Countermeasure bundle activated after staged rollout.',
      kind: SecurityLearningMomentKind.propagation,
      disposition: SecurityInterventionDisposition.observe,
      metadata: <String, dynamic>{
        'stage': 'active',
        'actor_alias': actorAlias,
      },
    );
    return updated;
  }

  Future<List<CountermeasurePropagationReceipt>> rollbackBundle({
    required String bundleId,
    required String reason,
    bool driftDetected = false,
    bool staleNode = false,
    bool falsePositive = false,
  }) async {
    final candidate = _immuneMemoryLedger.bundleCandidateByBundleId(bundleId);
    final receipts = _immuneMemoryLedger.propagationReceiptsForBundle(bundleId);
    final now = _nowProvider();
    final updated = <CountermeasurePropagationReceipt>[];
    for (final entry in receipts) {
      final receipt = CountermeasurePropagationReceipt(
        receiptId: entry.receiptId,
        bundleId: entry.bundleId,
        targetScope: entry.targetScope,
        sourceStratum: entry.sourceStratum,
        targetStratum: entry.targetStratum,
        activationStage: 'rolledBack',
        requiredAcknowledgements: entry.requiredAcknowledgements,
        acknowledgedCount: entry.acknowledgedCount,
        acknowledgedAt: entry.acknowledgedAt,
        driftDetected: driftDetected || entry.driftDetected,
        staleNode: staleNode || entry.staleNode,
        rolledBack: true,
        approvalGranted: entry.approvalGranted,
        activationDeadlineAt: entry.activationDeadlineAt,
        activatedAt: entry.activatedAt,
        rolledBackAt: now,
        rollbackReason: reason,
        metadata: entry.metadata,
      );
      await _immuneMemoryLedger.recordPropagationReceipt(receipt);
      updated.add(receipt);
    }
    if (candidate != null) {
      await _immuneMemoryLedger.upsertBundleCandidate(
        CountermeasureBundleCandidate(
          candidateId: candidate.candidateId,
          status: CountermeasureBundleCandidateStatus.rolledBack,
          bundle: candidate.bundle,
          createdAt: candidate.createdAt,
          updatedAt: now,
          sourceFindingIds: candidate.sourceFindingIds,
          shadowValidationEvidenceTraceIds:
              candidate.shadowValidationEvidenceTraceIds,
          approvalActors: candidate.approvalActors,
          metadata: <String, dynamic>{
            ...candidate.metadata,
            'last_rollout_stage': 'rolledBack',
            'rollback_reason': reason,
          },
        ),
      );
    }
    final truthScope = candidate?.bundle.targetScope ??
        (receipts.isNotEmpty ? receipts.first.targetScope : null);
    if (truthScope != null) {
      await _recordLearningMoment(
        bundleId: bundleId,
        truthScope: truthScope,
        summary: falsePositive
            ? 'Countermeasure bundle rolled back after false-positive review.'
            : 'Countermeasure bundle rolled back: $reason.',
        kind: falsePositive
            ? SecurityLearningMomentKind.falsePositive
            : SecurityLearningMomentKind.rollback,
        disposition: falsePositive
            ? SecurityInterventionDisposition.observe
            : SecurityInterventionDisposition.boundedDegrade,
        falsePositive: falsePositive,
        metadata: <String, dynamic>{
          'rollback_reason': reason,
          'drift_detected': driftDetected,
          'stale_node': staleNode,
        },
      );
    }
    return updated;
  }

  Future<List<CountermeasurePropagationReceipt>> markStaleReceipts({
    required String bundleId,
  }) async {
    final receipts = _immuneMemoryLedger.propagationReceiptsForBundle(bundleId);
    final now = _nowProvider();
    final updated = <CountermeasurePropagationReceipt>[];
    for (final entry in receipts) {
      final isStale = entry.activationDeadlineAt != null &&
          now.isAfter(entry.activationDeadlineAt!) &&
          entry.acknowledgedCount < entry.requiredAcknowledgements &&
          !entry.rolledBack;
      if (!isStale) {
        continue;
      }
      final receipt = CountermeasurePropagationReceipt(
        receiptId: entry.receiptId,
        bundleId: entry.bundleId,
        targetScope: entry.targetScope,
        sourceStratum: entry.sourceStratum,
        targetStratum: entry.targetStratum,
        activationStage: entry.activationStage,
        requiredAcknowledgements: entry.requiredAcknowledgements,
        acknowledgedCount: entry.acknowledgedCount,
        acknowledgedAt: entry.acknowledgedAt,
        driftDetected: entry.driftDetected,
        staleNode: true,
        rolledBack: entry.rolledBack,
        approvalGranted: entry.approvalGranted,
        activationDeadlineAt: entry.activationDeadlineAt,
        activatedAt: entry.activatedAt,
        rolledBackAt: entry.rolledBackAt,
        rollbackReason: entry.rollbackReason,
        metadata: entry.metadata,
      );
      await _immuneMemoryLedger.recordPropagationReceipt(receipt);
      updated.add(receipt);
    }
    if (updated.isEmpty) {
      return updated;
    }
    return rollbackBundle(
      bundleId: bundleId,
      reason: 'stale_node_threshold_exceeded',
      staleNode: true,
    );
  }

  Future<List<CountermeasurePropagationReceipt>> markDriftDetected({
    required String bundleId,
    String reason = 'drift_detected',
  }) {
    return rollbackBundle(
      bundleId: bundleId,
      reason: reason,
      driftDetected: true,
    );
  }

  List<String> _validateBundleForPropagation({
    required CountermeasureBundleCandidate candidate,
    List<TruthScopeDescriptor>? targetScopes,
  }) {
    final reasons = <String>[];
    final bundle = candidate.bundle;
    if ((bundle.signature ?? '').isEmpty || bundle.signedAt == null) {
      reasons.add('bundle_unsigned');
    }
    if (bundle.expiresAt != null && _nowProvider().isAfter(bundle.expiresAt!)) {
      reasons.add('bundle_expired');
    }
    if (bundle.requiredApprovals.any(
      (entry) => !candidate.approvalActors.contains(entry),
    )) {
      reasons.add('required_approvals_missing');
    }
    final scopes = targetScopes ?? <TruthScopeDescriptor>[bundle.targetScope];
    for (final scope in scopes) {
      if (scope.tenantScope != bundle.tenantScope ||
          (scope.tenantId ?? '') != (bundle.tenantId ?? '')) {
        reasons.add('tenant_scope_expansion');
        break;
      }
      if (!bundle.allowedStrata.contains(scope.governanceStratum)) {
        reasons.add('stratum_not_allowed');
        break;
      }
    }
    return reasons;
  }

  Future<void> _recordLearningMoment({
    required String bundleId,
    required TruthScopeDescriptor truthScope,
    required String summary,
    required SecurityLearningMomentKind kind,
    required SecurityInterventionDisposition disposition,
    bool falsePositive = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return _immuneMemoryLedger.recordLearningMoment(
      SecurityLearningMoment(
        id: 'bundle_${bundleId}_${kind.name}_${_nowProvider().millisecondsSinceEpoch}',
        truthScope: truthScope,
        runId: 'bundle:$bundleId',
        kind: kind,
        disposition: disposition,
        summary: summary,
        createdAt: _nowProvider(),
        evidenceTraceIds: <String>[bundleId],
        recurrenceCount: 0,
        falsePositive: falsePositive,
        metadata: <String, dynamic>{
          'bundle_id': bundleId,
          ...metadata,
        },
      ),
    );
  }
}
