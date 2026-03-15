import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/misc/break_glass_governance_directive.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_break_glass_governance_contract.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_governance_inspection_contract.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_quantum_atomic_time_validity_contract.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governance_inspection_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  group('UrkGovernanceInspectionService', () {
    late SharedPreferencesCompat prefs;
    late UrkGovernanceInspectionService service;

    setUp(() async {
      await cleanupTestStorage();
      prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'urk_governance_inspection_test'),
      );
      service = UrkGovernanceInspectionService(prefs: prefs);
    });

    test('returns approved inspection response with payload when healthy',
        () async {
      final request = GovernanceInspectionRequest(
        requestId: 'req-1',
        actorId: 'human-operator',
        targetRuntimeId: 'runtime-personal-1',
        targetStratum: GovernanceStratum.personal,
        visibilityTier: GovernanceVisibilityTier.summary,
        justification: 'safety review',
        requestedAt: AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          isSynchronized: true,
          serverTime: DateTime.now().toUtc(),
        ),
        isHumanActor: true,
      );

      const snapshot = UrkGovernanceInspectionSnapshot(
        observedGovernanceStrataCoveragePct: 100.0,
        observedSummaryVisibilityCoveragePct: 100.0,
        observedBreakGlassAuditCoveragePct: 100.0,
        observedUnauditedBreakGlassInspections: 0,
        observedHiddenInspectionPaths: 0,
      );
      const policy = UrkGovernanceInspectionPolicy(
        requiredGovernanceStrataCoveragePct: 100.0,
        requiredSummaryVisibilityCoveragePct: 100.0,
        requiredBreakGlassAuditCoveragePct: 100.0,
        maxUnauditedBreakGlassInspections: 0,
        maxHiddenInspectionPaths: 0,
      );

      final response = await service.inspect(
        request: request,
        snapshot: snapshot,
        policy: policy,
        whoKernel: const GovernanceWhoKernelPayload(
          inspectionActorId: 'human-operator',
          isHumanActor: true,
          targetRuntimeId: 'runtime-personal-1',
          targetStratum: 'personal',
          actorLabel: 'human-operator',
          matchedAgents: <GovernanceWhoKernelAgentMatch>[
            GovernanceWhoKernelAgentMatch(
              userId: 'user-1',
              aiSignature: 'sig-1',
              isOnline: true,
            ),
          ],
        ),
        whatKernel: const GovernanceWhatKernelPayload(
          operationalScore: 0.0,
          matchedAgentStates: <GovernanceWhatKernelAgentState>[
            GovernanceWhatKernelAgentState(
              aiStatus: 'healthy',
              currentStage: 'monitoring',
              aiConnections: 3,
              topPredictedAction: 'none',
            ),
          ],
        ),
        whenKernel: const GovernanceWhenKernelPayload(
          requestedAt: '2026-03-06T00:00:00Z',
          requestedAtSynchronized: true,
          quantumAtomicTimeRequired: true,
          clockState: 'synced',
        ),
        whereKernel: const GovernanceWhereKernelPayload(
          runtimeId: 'runtime-personal-1',
          governanceStratum: 'personal',
          resolutionMode: 'auditOnly',
          scope: 'runtime-personal-1',
        ),
        whyKernel: const GovernanceWhyKernelPayload(
          justification: 'safety review',
          convictionTier: 'proven_conviction',
        ),
        howKernel: const GovernanceHowKernelPayload(
          visibilityTier: 'summary',
          inspectionPath: 'governance_inspect',
          auditMode: 'explicit',
          resolutionMode: 'auditOnly',
          failClosedOnPolicyViolation: true,
          governanceChannel: 'test_lane',
        ),
        policyState: const GovernanceInspectionPolicyState(mode: 'normal'),
        provenance: const <GovernanceInspectionProvenanceEntry>[
          GovernanceInspectionProvenanceEntry(
            kind: 'lineage',
            reference: 'lin-1',
          ),
        ],
      );

      expect(response.approved, isTrue);
      expect(response.failureCodes, isEmpty);
      expect(response.payload, isNotNull);
      expect(
        response.payload!.contractVersion,
        GovernanceInspectionPayload.currentContractVersion,
      );
      expect(response.payload!.whyKernel.convictionTier, 'proven_conviction');

      final roundTrip =
          GovernanceInspectionResponse.fromJson(response.toJson());
      expect(
        roundTrip.payload!.contractVersion,
        GovernanceInspectionPayload.currentContractVersion,
      );
      expect(
        roundTrip.payload!.whoKernel.inspectionActorId,
        'human-operator',
      );
      expect(roundTrip.payload!.whoKernel.matchedAgents, hasLength(1));
      expect(roundTrip.payload!.whoKernel.matchedAgents.first.userId, 'user-1');
      expect(roundTrip.payload!.whoKernel.actorLabel, 'human-operator');
      expect(roundTrip.payload!.whatKernel.matchedAgentStates, hasLength(1));
      expect(roundTrip.payload!.whatKernel.operationalScore, 0.0);
      expect(
        roundTrip
            .payload!.whatKernel.matchedAgentStates.first.topPredictedAction,
        'none',
      );
      expect(roundTrip.payload!.whenKernel.clockState, 'synced');
      expect(roundTrip.payload!.whereKernel.scope, 'runtime-personal-1');
      expect(roundTrip.payload!.whyKernel.convictionTier, 'proven_conviction');
      expect(roundTrip.payload!.howKernel.governanceChannel, 'test_lane');
      expect(roundTrip.payload!.policyState.mode, 'normal');
      expect(roundTrip.payload!.provenance, hasLength(1));
      expect(roundTrip.payload!.provenance.first.kind, 'lineage');
      expect(roundTrip.payload!.provenance.first.reference, 'lin-1');
    });

    test('returns blocked break-glass receipt when expired or policy fails',
        () async {
      final now = DateTime.now().toUtc();
      final directive = BreakGlassGovernanceDirective(
        directiveId: 'dir-1',
        actorId: 'human-operator',
        targetRuntimeId: 'runtime-universal-1',
        targetStratum: GovernanceStratum.universal,
        actionType: BreakGlassActionType.highDetailDiagnosticCapture,
        reasonCode: 'serious_anomaly',
        signedDirectiveRef: 'sig-1',
        issuedAt: AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          isSynchronized: true,
          serverTime: now.subtract(const Duration(minutes: 5)),
        ),
        expiresAt: AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          isSynchronized: true,
          serverTime: now.subtract(const Duration(minutes: 1)),
        ),
        requiresDualApproval: true,
      );

      const breakGlassSnapshot = UrkBreakGlassGovernanceSnapshot(
        observedSignedDirectiveCoveragePct: 90.0,
        observedDualApprovalCoveragePct: 100.0,
        observedGovernanceChannelSeparationPct: 100.0,
        observedUnauthorizedBreakGlassActions: 0,
        observedLearningPathTunnelingEvents: 0,
      );
      const breakGlassPolicy = UrkBreakGlassGovernancePolicy(
        requiredSignedDirectiveCoveragePct: 100.0,
        requiredDualApprovalCoveragePct: 100.0,
        requiredGovernanceChannelSeparationPct: 100.0,
        maxUnauthorizedBreakGlassActions: 0,
        maxLearningPathTunnelingEvents: 0,
      );
      const quantumSnapshot = UrkQuantumAtomicTimeValiditySnapshot(
        observedTimestampCoveragePct: 100.0,
        observedHighImpactValidityCoveragePct: 100.0,
        observedReconciliationValidityCoveragePct: 100.0,
        observedMaxUncertaintyWindowMs: 10,
        observedClockRegressionEvents: 0,
      );
      const quantumPolicy = UrkQuantumAtomicTimeValidityPolicy(
        requiredTimestampCoveragePct: 100.0,
        requiredHighImpactValidityCoveragePct: 100.0,
        requiredReconciliationValidityCoveragePct: 100.0,
        maxUncertaintyWindowMs: 15,
        maxClockRegressionEvents: 0,
      );

      final receipt = await service.evaluateDirective(
        directive: directive,
        breakGlassSnapshot: breakGlassSnapshot,
        breakGlassPolicy: breakGlassPolicy,
        quantumTimeSnapshot: quantumSnapshot,
        quantumTimePolicy: quantumPolicy,
      );

      expect(receipt.approved, isFalse);
      expect(
        receipt.failureCodes,
        contains(
          UrkBreakGlassGovernanceFailure
              .signedDirectiveCoverageBelowThreshold.name,
        ),
      );
      expect(receipt.failureCodes, contains('directiveExpired'));
    });

    test('persists and filters recent inspection responses', () async {
      final baseTime = DateTime.utc(2026, 3, 6, 12);
      Future<void> recordInspection({
        required String requestId,
        required String runtimeId,
        required GovernanceStratum stratum,
        required DateTime when,
      }) {
        return service.inspect(
          request: GovernanceInspectionRequest(
            requestId: requestId,
            actorId: 'human-operator',
            targetRuntimeId: runtimeId,
            targetStratum: stratum,
            visibilityTier: GovernanceVisibilityTier.summary,
            justification: 'audit replay',
            requestedAt: AtomicTimestamp.now(
              precision: TimePrecision.millisecond,
              isSynchronized: true,
              serverTime: when,
            ),
            isHumanActor: true,
          ),
          snapshot: const UrkGovernanceInspectionSnapshot(
            observedGovernanceStrataCoveragePct: 100.0,
            observedSummaryVisibilityCoveragePct: 100.0,
            observedBreakGlassAuditCoveragePct: 100.0,
            observedUnauditedBreakGlassInspections: 0,
            observedHiddenInspectionPaths: 0,
          ),
          policy: const UrkGovernanceInspectionPolicy(
            requiredGovernanceStrataCoveragePct: 100.0,
            requiredSummaryVisibilityCoveragePct: 100.0,
            requiredBreakGlassAuditCoveragePct: 100.0,
            maxUnauditedBreakGlassInspections: 0,
            maxHiddenInspectionPaths: 0,
          ),
          whoKernel: GovernanceWhoKernelPayload(
            inspectionActorId: 'human-operator',
            isHumanActor: true,
            targetRuntimeId: runtimeId,
            targetStratum: stratum.name,
          ),
          whatKernel: const GovernanceWhatKernelPayload(),
          whenKernel: GovernanceWhenKernelPayload(
            requestedAt: when.toIso8601String(),
            requestedAtSynchronized: true,
            quantumAtomicTimeRequired: true,
          ),
          whereKernel: GovernanceWhereKernelPayload(
            runtimeId: runtimeId,
            governanceStratum: stratum.name,
            resolutionMode: 'auditOnly',
          ),
          whyKernel: const GovernanceWhyKernelPayload(
            justification: 'audit replay',
          ),
          howKernel: const GovernanceHowKernelPayload(
            visibilityTier: 'summary',
            inspectionPath: 'governance_inspect',
            auditMode: 'explicit',
            resolutionMode: 'auditOnly',
            failClosedOnPolicyViolation: true,
          ),
        );
      }

      await recordInspection(
        requestId: 'req-a',
        runtimeId: 'runtime-personal-1',
        stratum: GovernanceStratum.personal,
        when: baseTime,
      );
      await recordInspection(
        requestId: 'req-b',
        runtimeId: 'runtime-world-1',
        stratum: GovernanceStratum.world,
        when: baseTime.add(const Duration(minutes: 1)),
      );

      final all = await service.listRecentInspectionResponses(limit: 10);
      expect(all, hasLength(2));
      expect(all.first.request.requestId, 'req-b');

      final personalOnly = await service.listRecentInspectionResponses(
        limit: 10,
        stratum: GovernanceStratum.personal,
        runtimeId: 'runtime-personal-1',
      );
      expect(personalOnly, hasLength(1));
      expect(personalOnly.first.request.requestId, 'req-a');
    });

    test('persists and filters recent break-glass receipts', () async {
      final now = DateTime.utc(2026, 3, 6, 14);
      Future<void> recordDirective({
        required String directiveId,
        required String runtimeId,
        required GovernanceStratum stratum,
        required DateTime issuedAt,
      }) {
        return service.evaluateDirective(
          directive: BreakGlassGovernanceDirective(
            directiveId: directiveId,
            actorId: 'human-operator',
            targetRuntimeId: runtimeId,
            targetStratum: stratum,
            actionType: BreakGlassActionType.featureDisable,
            reasonCode: 'attack',
            signedDirectiveRef: 'sig-$directiveId',
            issuedAt: AtomicTimestamp.now(
              precision: TimePrecision.millisecond,
              isSynchronized: true,
              serverTime: issuedAt,
            ),
            expiresAt: AtomicTimestamp.now(
              precision: TimePrecision.millisecond,
              isSynchronized: true,
              serverTime: issuedAt.add(const Duration(minutes: 5)),
            ),
            requiresDualApproval: true,
          ),
          breakGlassSnapshot: const UrkBreakGlassGovernanceSnapshot(
            observedSignedDirectiveCoveragePct: 100.0,
            observedDualApprovalCoveragePct: 100.0,
            observedGovernanceChannelSeparationPct: 100.0,
            observedUnauthorizedBreakGlassActions: 0,
            observedLearningPathTunnelingEvents: 0,
          ),
          breakGlassPolicy: const UrkBreakGlassGovernancePolicy(
            requiredSignedDirectiveCoveragePct: 100.0,
            requiredDualApprovalCoveragePct: 100.0,
            requiredGovernanceChannelSeparationPct: 100.0,
            maxUnauthorizedBreakGlassActions: 0,
            maxLearningPathTunnelingEvents: 0,
          ),
          quantumTimeSnapshot: const UrkQuantumAtomicTimeValiditySnapshot(
            observedTimestampCoveragePct: 100.0,
            observedHighImpactValidityCoveragePct: 100.0,
            observedReconciliationValidityCoveragePct: 100.0,
            observedMaxUncertaintyWindowMs: 10,
            observedClockRegressionEvents: 0,
          ),
          quantumTimePolicy: const UrkQuantumAtomicTimeValidityPolicy(
            requiredTimestampCoveragePct: 100.0,
            requiredHighImpactValidityCoveragePct: 100.0,
            requiredReconciliationValidityCoveragePct: 100.0,
            maxUncertaintyWindowMs: 15,
            maxClockRegressionEvents: 0,
          ),
        );
      }

      await recordDirective(
        directiveId: 'dir-a',
        runtimeId: 'runtime-locality-1',
        stratum: GovernanceStratum.locality,
        issuedAt: now,
      );
      await recordDirective(
        directiveId: 'dir-b',
        runtimeId: 'runtime-universal-1',
        stratum: GovernanceStratum.universal,
        issuedAt: now.add(const Duration(minutes: 1)),
      );

      final all = await service.listRecentBreakGlassReceipts(limit: 10);
      expect(all, hasLength(2));
      expect(all.first.directive.directiveId, 'dir-b');

      final universalOnly = await service.listRecentBreakGlassReceipts(
        limit: 10,
        stratum: GovernanceStratum.universal,
        runtimeId: 'runtime-universal-1',
      );
      expect(universalOnly, hasLength(1));
      expect(universalOnly.first.directive.directiveId, 'dir-b');
    });
  });
}
