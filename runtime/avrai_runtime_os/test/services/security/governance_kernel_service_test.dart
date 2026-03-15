import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import '../../support/fake_kernel_governance.dart';

void main() {
  group('GovernanceKernelService (Knowledge Vectors)', () {
    late GovernanceKernelService kernel;

    setUp(() {
      kernel = buildTestGovernanceKernelService();
    });

    KnowledgeVector createVector({
      required String category,
      required List<double> weights,
      DateTime? timestamp,
    }) {
      return KnowledgeVector(
        senderAgentId: 'test_id',
        insightWeights: weights,
        contextCategory: category,
        timestamp: timestamp ?? DateTime.now(),
      );
    }

    group('Outgoing Interception (Structure & Category Enforcement)', () {
      test('should allow valid vectors from approved categories', () {
        final vector =
            createVector(category: 'spot_affinity', weights: [0.5, -0.2, 0.9]);
        final result = kernel.interceptOutgoing(vector);

        expect(result.isApproved, isTrue);
        expect(result.sanitizedVector, isNotNull);
        expect(
            result.sanitizedVector!.insightWeights, equals([0.5, -0.2, 0.9]));
      });

      test('should reject unauthorized categories (preventing data tunnels)',
          () {
        final vector =
            createVector(category: 'custom_chat_tunnel', weights: [0.1]);
        final result = kernel.interceptOutgoing(vector);

        expect(result.isApproved, isFalse);
        expect(result.rejectionReason, contains('Unauthorized'));
      });

      test('should clamp outgoing weights to prevent extreme values', () {
        final vector = createVector(
            category: 'event_resonance', weights: [0.5, 50.0, -100.0]);
        final result = kernel.interceptOutgoing(vector);

        expect(result.isApproved, isTrue);
        // 50.0 clamps to 1.0, -100.0 clamps to -1.0
        expect(
            result.sanitizedVector!.insightWeights, equals([0.5, 1.0, -1.0]));
      });

      test('should reject excessively large vectors', () {
        final vector = createVector(
          category: 'spot_affinity',
          weights: List.generate(600, (i) => 0.1),
        );
        final result = kernel.interceptOutgoing(vector);

        expect(result.isApproved, isFalse);
        expect(result.rejectionReason, contains('maximum dimensionality'));
      });
    });

    group('Incoming Interception (Poisoning Defense)', () {
      test('should allow normal incoming vectors', () {
        final vector =
            createVector(category: 'spot_affinity', weights: [0.2, -0.8, 0.0]);
        final result = kernel.interceptIncoming(vector);

        expect(result.isApproved, isTrue);
      });

      test('should reject vectors with out-of-bounds weights (Data Poisoning)',
          () {
        final vector =
            createVector(category: 'spot_affinity', weights: [0.5, 2.5]);
        final result = kernel.interceptIncoming(vector);

        expect(result.isApproved, isFalse);
        expect(result.rejectionReason, contains('poisoning attempt'));
      });

      test('should reject expired vectors (Replay Attack)', () {
        final oldTimestamp = DateTime.now().subtract(const Duration(days: 10));
        final vector = createVector(
          category: 'spot_affinity',
          weights: [0.5],
          timestamp: oldTimestamp,
        );
        final result = kernel.interceptIncoming(vector);

        expect(result.isApproved, isFalse);
        expect(result.rejectionReason, contains('expired'));
      });
    });
  });

  group('GovernanceKernelService (Vibe Mutation Scopes)', () {
    late GovernanceKernelService kernel;

    setUp(() {
      kernel = buildTestGovernanceKernelService();
    });

    VibeEvidence evidence() => const VibeEvidence(
          summary: 'test evidence',
          identitySignals: <VibeSignal>[
            VibeSignal(
              key: 'exploration_eagerness',
              kind: VibeSignalKind.identity,
              value: 0.7,
              confidence: 0.8,
              provenance: <String>['test'],
            ),
          ],
          pheromoneSignals: <VibeSignal>[],
          behaviorSignals: <VibeSignal>[],
          affectiveSignals: <VibeSignal>[],
          styleSignals: <VibeSignal>[],
        );

    test('allows supported geographic scope for matching subject', () {
      final decision = kernel.authorizeVibeMutation(
        subjectId: 'locality-agent:bham-downtown',
        governanceScope: 'geographic:locality',
        evidence: evidence(),
      );

      expect(decision.stateWriteAllowed, isTrue);
      expect(decision.governanceScope, 'geographic:locality');
      expect(decision.reasonCodes, contains('governance_approved'));
    });

    test('rejects unsupported scoped mutation scope', () {
      final decision = kernel.authorizeVibeMutation(
        subjectId: 'network:campus-founders',
        governanceScope: 'scoped:community_network',
        evidence: evidence(),
      );

      expect(decision.stateWriteAllowed, isFalse);
      expect(decision.reasonCodes, contains('unsupported_governance_scope'));
    });

    test('rejects subject and scope mismatches for geographic writes', () {
      final decision = kernel.authorizeVibeMutation(
        subjectId: 'city-agent:bham',
        governanceScope: 'geographic:locality',
        evidence: evidence(),
      );

      expect(decision.stateWriteAllowed, isFalse);
      expect(decision.reasonCodes, contains('subject_scope_mismatch'));
    });

    test('allows scoped scene mutation only for scene subjects', () {
      final decision = kernel.authorizeVibeMutation(
        subjectId: 'scene:locality-agent:bham:indie-music',
        governanceScope: 'scoped:scene',
        evidence: evidence(),
      );

      expect(decision.stateWriteAllowed, isTrue);
      expect(decision.reasonCodes, contains('governance_approved'));
    });
  });

  group('GovernanceKernelService (Truth Scope Security)', () {
    late GovernanceKernelService kernel;

    setUp(() {
      kernel = buildTestGovernanceKernelService();
    });

    SecurityScopeChannels buildSecurityScopeChannels({
      GovernanceStratum observationStratum = GovernanceStratum.locality,
      GovernanceStratum? interventionStratum,
      GovernanceStratum? promotionStratum,
      GovernanceStratum? propagationStratum,
      TruthTenantScope tenantScope = TruthTenantScope.avraiNative,
      String? tenantId,
    }) {
      final baseScope = TruthScopeDescriptor.defaultSecurity(
        governanceStratum: observationStratum,
        tenantScope: tenantScope,
        tenantId: tenantId,
        sphereId: 'security_redteam',
        familyId: 'sandbox_countermeasure',
      );
      return SecurityScopeChannels(
        observationScope: baseScope,
        interventionScope: baseScope.copyWith(
          governanceStratum: interventionStratum ?? observationStratum,
        ),
        promotionScope: baseScope.copyWith(
          governanceStratum: promotionStratum ?? observationStratum,
        ),
        propagationScope: baseScope.copyWith(
          governanceStratum: propagationStratum ?? observationStratum,
        ),
      );
    }

    TruthEvidenceEnvelope buildEvidenceEnvelope(TruthScopeDescriptor scope) {
      return TruthEvidenceEnvelope(
        scope: scope,
        traceId: 'trace-1',
        evidenceClass: 'sandbox_redteam',
        privacyLadderTag: 'redacted',
        approvals: const <String>['security_lead', 'mesh_governance'],
      );
    }

    test('authorizes scoped intervention when channels and evidence align', () {
      final scopeChannels = buildSecurityScopeChannels();
      final decision = kernel.authorizeSecurityIntervention(
        actionId: 'quarantine-agent',
        scopeChannels: scopeChannels,
        evidenceEnvelope: buildEvidenceEnvelope(
          scopeChannels.observationScope,
        ),
      );

      expect(decision.isApproved, isTrue);
      expect(
        decision.reasonCodes,
        contains('security_intervention_authorized'),
      );
      expect(
        decision.scopeChannels.observationScope.truthSurfaceKind,
        TruthSurfaceKind.security,
      );
      expect(
        decision.disposition,
        SecurityInterventionDisposition.observe,
      );
    });

    test('rejects intervention when promotion scope widens surveillance', () {
      final scopeChannels = buildSecurityScopeChannels(
        observationStratum: GovernanceStratum.personal,
        promotionStratum: GovernanceStratum.world,
      );
      final decision = kernel.authorizeSecurityIntervention(
        actionId: 'quarantine-agent',
        scopeChannels: scopeChannels,
        evidenceEnvelope: buildEvidenceEnvelope(
          scopeChannels.observationScope,
        ),
      );

      expect(decision.isApproved, isFalse);
      expect(
        decision.reasonCodes,
        contains('promotion_scope_widens_surveillance'),
      );
      expect(
        decision.disposition,
        SecurityInterventionDisposition.hardStop,
      );
    });

    test(
        'uses bounded degrade for credible scoped risk without invariant breach',
        () {
      final scopeChannels = buildSecurityScopeChannels();
      final decision = kernel.authorizeSecurityIntervention(
        actionId: 'shadow-only',
        scopeChannels: scopeChannels,
        evidenceEnvelope: buildEvidenceEnvelope(
          scopeChannels.observationScope,
        ),
        metadata: const <String, dynamic>{
          'confidence': 0.86,
          'recurrence_count': 2,
        },
      );

      expect(decision.isApproved, isTrue);
      expect(
        decision.disposition,
        SecurityInterventionDisposition.boundedDegrade,
      );
    });

    test('approves countermeasure review when evidence and approvals match',
        () {
      final targetScope = TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.locality,
        sphereId: 'security_redteam',
        familyId: 'sandbox_countermeasure',
      );
      final evidenceEnvelope = buildEvidenceEnvelope(targetScope);
      final review = kernel.reviewCountermeasureBundle(
        bundle: SecurityCountermeasureBundle(
          bundleId: 'bundle-1',
          targetScope: targetScope,
          allowedStrata: const <GovernanceStratum>[
            GovernanceStratum.personal,
            GovernanceStratum.locality,
          ],
          tenantScope: TruthTenantScope.avraiNative,
          evidenceEnvelopeTraceIds: const <String>['trace-1'],
          requiredApprovals: const <String>[
            'security_lead',
            'mesh_governance',
          ],
          signature: 'signed-bundle',
          signedBy: 'security_lead',
          signedAt: DateTime.utc(2026, 3, 14, 11),
        ),
        evidenceEnvelope: evidenceEnvelope,
      );

      expect(review.isApproved, isTrue);
      expect(review.propagationAuthorized, isTrue);
      expect(review.reasonCodes, contains('countermeasure_bundle_approved'));
    });

    test('rejects countermeasure review when air gap bypass is requested', () {
      final targetScope = TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.world,
        sphereId: 'security_redteam',
        familyId: 'sandbox_countermeasure',
      );
      final review = kernel.reviewCountermeasureBundle(
        bundle: SecurityCountermeasureBundle(
          bundleId: 'bundle-2',
          targetScope: targetScope,
          allowedStrata: const <GovernanceStratum>[
            GovernanceStratum.world,
          ],
          tenantScope: TruthTenantScope.avraiNative,
          evidenceEnvelopeTraceIds: const <String>['trace-1'],
          requiredApprovals: const <String>['security_lead'],
          metadata: const <String, dynamic>{'bypass_air_gap': true},
        ),
        evidenceEnvelope: buildEvidenceEnvelope(targetScope),
      );

      expect(review.isApproved, isFalse);
      expect(
        review.reasonCodes,
        contains('countermeasure_cannot_bypass_air_gap'),
      );
    });
  });
}
