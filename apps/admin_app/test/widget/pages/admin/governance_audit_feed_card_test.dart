import 'package:avrai_admin_app/ui/widgets/governance_audit_feed_card.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/misc/break_glass_governance_directive.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GovernanceAuditFeedCard', () {
    testWidgets('renders governance audit metrics and entries', (tester) async {
      final now = DateTime.utc(2026, 3, 6, 18, 30);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GovernanceAuditFeedCard(
              inspections: [
                GovernanceInspectionResponse(
                  request: GovernanceInspectionRequest(
                    requestId: 'req-1',
                    actorId: 'admin-1',
                    targetRuntimeId: 'runtime-world-1',
                    targetStratum: GovernanceStratum.world,
                    visibilityTier: GovernanceVisibilityTier.summary,
                    justification: 'pattern review',
                    requestedAt: AtomicTimestamp.now(
                      precision: TimePrecision.millisecond,
                      isSynchronized: true,
                      serverTime: now,
                    ),
                    isHumanActor: true,
                  ),
                  approved: true,
                  auditRef: 'audit-1',
                  respondedAt: AtomicTimestamp.now(
                    precision: TimePrecision.millisecond,
                    isSynchronized: true,
                    serverTime: now,
                  ),
                  failureCodes: const <String>[],
                  payload: GovernanceInspectionPayload(
                    whoKernel: const GovernanceWhoKernelPayload(
                      inspectionActorId: 'admin',
                      isHumanActor: true,
                      targetRuntimeId: 'runtime-1',
                      targetStratum: 'personal',
                      actorLabel: 'admin',
                    ),
                    whatKernel: const GovernanceWhatKernelPayload(
                      operationalScore: 0.1,
                    ),
                    whenKernel: const GovernanceWhenKernelPayload(
                      requestedAt: '2026-03-06T00:00:00Z',
                      requestedAtSynchronized: true,
                      quantumAtomicTimeRequired: true,
                      clockState: 'synced',
                    ),
                    whereKernel: const GovernanceWhereKernelPayload(
                      runtimeId: 'runtime-1',
                      governanceStratum: 'personal',
                      resolutionMode: 'auditOnly',
                      scope: 'runtime',
                    ),
                    whyKernel: const GovernanceWhyKernelPayload(
                      justification: 'review',
                      convictionTier: 'high',
                    ),
                    howKernel: const GovernanceHowKernelPayload(
                      visibilityTier: 'summary',
                      inspectionPath: 'review',
                      auditMode: 'explicit',
                      resolutionMode: 'auditOnly',
                      failClosedOnPolicyViolation: true,
                      governanceChannel: 'feed',
                    ),
                    policyState:
                        const GovernanceInspectionPolicyState(mode: 'normal'),
                    provenance: const <GovernanceInspectionProvenanceEntry>[
                      GovernanceInspectionProvenanceEntry(
                        kind: 'lineage',
                        reference: 'line-1',
                      ),
                    ],
                  ),
                ),
              ],
              receipts: [
                BreakGlassGovernanceReceipt(
                  directive: BreakGlassGovernanceDirective(
                    directiveId: 'bg-1',
                    actorId: 'admin-2',
                    targetRuntimeId: 'runtime-universal-1',
                    targetStratum: GovernanceStratum.universal,
                    actionType: BreakGlassActionType.featureDisable,
                    reasonCode: 'incident',
                    signedDirectiveRef: 'sig-1',
                    issuedAt: AtomicTimestamp.now(
                      precision: TimePrecision.millisecond,
                      isSynchronized: true,
                      serverTime: now,
                    ),
                    expiresAt: AtomicTimestamp.now(
                      precision: TimePrecision.millisecond,
                      isSynchronized: true,
                      serverTime: now.add(const Duration(minutes: 5)),
                    ),
                    requiresDualApproval: true,
                  ),
                  approved: false,
                  auditRef: 'audit-2',
                  evaluatedAt: AtomicTimestamp.now(
                    precision: TimePrecision.millisecond,
                    isSynchronized: true,
                    serverTime: now.add(const Duration(minutes: 1)),
                  ),
                  failureCodes: const <String>['directiveExpired'],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Governance Audit Feed'), findsOneWidget);
      expect(find.textContaining('Inspections: 1'), findsOneWidget);
      expect(find.textContaining('Break-glass receipts: 1'), findsOneWidget);
      expect(find.textContaining('world • runtime-world-1'), findsOneWidget);
      expect(find.textContaining('featureDisable • runtime-universal-1'),
          findsOneWidget);
      expect(find.text('directiveExpired'), findsOneWidget);
    });

    testWidgets('invokes row callbacks for inspections and break-glass items',
        (tester) async {
      final now = DateTime.utc(2026, 3, 6, 18, 30);
      String? selectedRuntime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GovernanceAuditFeedCard(
              inspections: [
                GovernanceInspectionResponse(
                  request: GovernanceInspectionRequest(
                    requestId: 'req-tap',
                    actorId: 'admin-1',
                    targetRuntimeId: 'runtime-personal-1',
                    targetStratum: GovernanceStratum.personal,
                    visibilityTier: GovernanceVisibilityTier.summary,
                    justification: 'tap',
                    requestedAt: AtomicTimestamp.now(
                      precision: TimePrecision.millisecond,
                      isSynchronized: true,
                      serverTime: now,
                    ),
                    isHumanActor: true,
                  ),
                  approved: true,
                  auditRef: 'audit-tap-1',
                  respondedAt: AtomicTimestamp.now(
                    precision: TimePrecision.millisecond,
                    isSynchronized: true,
                    serverTime: now,
                  ),
                  failureCodes: const <String>[],
                ),
              ],
              receipts: [
                BreakGlassGovernanceReceipt(
                  directive: BreakGlassGovernanceDirective(
                    directiveId: 'bg-tap',
                    actorId: 'admin-2',
                    targetRuntimeId: 'runtime-universal-9',
                    targetStratum: GovernanceStratum.universal,
                    actionType: BreakGlassActionType.featureDisable,
                    reasonCode: 'incident',
                    signedDirectiveRef: 'sig-tap',
                    issuedAt: AtomicTimestamp.now(
                      precision: TimePrecision.millisecond,
                      isSynchronized: true,
                      serverTime: now,
                    ),
                    expiresAt: AtomicTimestamp.now(
                      precision: TimePrecision.millisecond,
                      isSynchronized: true,
                      serverTime: now.add(const Duration(minutes: 5)),
                    ),
                    requiresDualApproval: true,
                  ),
                  approved: true,
                  auditRef: 'audit-tap-2',
                  evaluatedAt: AtomicTimestamp.now(
                    precision: TimePrecision.millisecond,
                    isSynchronized: true,
                    serverTime: now,
                  ),
                  failureCodes: const <String>[],
                ),
              ],
              onInspectionTap: (item) {
                selectedRuntime = item.request.targetRuntimeId;
              },
              onBreakGlassTap: (item) {
                selectedRuntime = item.directive.targetRuntimeId;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('personal • runtime-personal-1'));
      await tester.pump();
      expect(selectedRuntime, 'runtime-personal-1');

      await tester
          .tap(find.textContaining('featureDisable • runtime-universal-9'));
      await tester.pump();
      expect(selectedRuntime, 'runtime-universal-9');
    });

    testWidgets('renders empty state without artifacts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GovernanceAuditFeedCard(
              inspections: <GovernanceInspectionResponse>[],
              receipts: <BreakGlassGovernanceReceipt>[],
            ),
          ),
        ),
      );

      expect(
          find.text('No governance artifacts recorded yet.'), findsOneWidget);
    });
  });
}
