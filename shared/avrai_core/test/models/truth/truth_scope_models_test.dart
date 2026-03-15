import 'package:avrai_core/avra_core.dart';
import 'package:test/test.dart';

void main() {
  group('TruthScopeDescriptor', () {
    test('round-trips and produces stable canonical scope keys', () {
      const scope = TruthScopeDescriptor(
        governanceStratum: GovernanceStratum.locality,
        truthSurfaceKind: TruthSurfaceKind.forecast,
        tenantScope: TruthTenantScope.trustedPartnerPrivate,
        tenantId: 'Partner Alpha',
        agentClass: TruthAgentClass.partner,
        sphereId: 'Venue Demand',
        familyId: 'Attendance Family',
      );

      final decoded = TruthScopeDescriptor.fromJson(scope.toJson());

      expect(
        decoded.scopeKey,
        'locality|forecast|trustedPartnerPrivate|partner_alpha|partner|venue_demand|attendance_family',
      );
      expect(decoded.scopeKey, scope.scopeKey);
      expect(decoded.tenantId, 'Partner Alpha');
    });

    test('normalizes legacy forecast metadata into typed scope', () {
      const registry = TruthScopeRegistry();
      final scope = registry.normalizeForecastScope(
        metadata: const <String, dynamic>{
          'governance_stratum': 'locality',
          'tenant_scope': 'trustedPartnerPrivate',
          'tenant_id': 'partner_alpha',
          'agent_class': 'partner',
          'forecast_sphere_id': 'partner_demand',
        },
        familyId: 'attendance_family',
      );

      expect(scope.truthSurfaceKind, TruthSurfaceKind.forecast);
      expect(scope.tenantScope, TruthTenantScope.trustedPartnerPrivate);
      expect(scope.tenantId, 'partner_alpha');
      expect(scope.agentClass, TruthAgentClass.partner);
      expect(scope.sphereId, 'partner_demand');
      expect(scope.familyId, 'attendance_family');
    });

    test('normalizes planning metadata into typed scope', () {
      const registry = TruthScopeRegistry();
      final scope = registry.normalizePlanningScope(
        metadata: const <String, dynamic>{
          'governance_stratum': 'locality',
          'agent_class': 'organizer',
          'planning_sphere_id': 'event_planning_locality',
        },
        familyId: 'creator_event_prep_human',
      );

      expect(scope.truthSurfaceKind, TruthSurfaceKind.planning);
      expect(scope.governanceStratum, GovernanceStratum.locality);
      expect(scope.agentClass, TruthAgentClass.organizer);
      expect(scope.sphereId, 'event_planning_locality');
      expect(scope.familyId, 'creator_event_prep_human');
    });

    test('normalizes research and healing metadata into typed scope', () {
      const registry = TruthScopeRegistry();
      final researchScope = registry.normalizeResearchScope(
        metadata: const <String, dynamic>{
          'governance_stratum': 'world',
          'research_sphere_id': 'autoresearch_world',
        },
        familyId: 'governed_autoresearch',
      );
      final healingScope = registry.normalizeHealingScope(
        metadata: const <String, dynamic>{
          'governance_stratum': 'world',
          'healing_sphere_id': 'self_healing_runtime',
        },
        familyId: 'self_heal_kernel',
      );

      expect(researchScope.truthSurfaceKind, TruthSurfaceKind.research);
      expect(researchScope.sphereId, 'autoresearch_world');
      expect(healingScope.truthSurfaceKind, TruthSurfaceKind.healing);
      expect(healingScope.sphereId, 'self_healing_runtime');
    });
  });

  group('Truth evidence and partner outcome receipts', () {
    const scope = TruthScopeDescriptor.defaultSecurity(
      governanceStratum: GovernanceStratum.locality,
      sphereId: 'security_redteam',
      familyId: 'sandbox_countermeasure',
    );

    test('truth evidence envelope round-trips', () {
      const envelope = TruthEvidenceEnvelope(
        scope: scope,
        traceId: 'trace-1',
        evidenceClass: 'sandbox_redteam',
        privacyLadderTag: 'redacted',
        sourceRefs: <String>['sandbox-run-1'],
        approvals: <String>['security_lead'],
        rollbackRefs: <String>['rollback-1'],
      );

      final decoded = TruthEvidenceEnvelope.fromJson(envelope.toJson());

      expect(decoded.scope.scopeKey, scope.scopeKey);
      expect(decoded.approvals, contains('security_lead'));
      expect(decoded.rollbackRefs, contains('rollback-1'));
    });

    test('partner outcome receipt round-trips with signed metadata', () {
      final receipt = PartnerOutcomeReceipt(
        tenantId: 'partner_alpha',
        scope: const TruthScopeDescriptor.defaultForecast(
          governanceStratum: GovernanceStratum.locality,
          tenantScope: TruthTenantScope.trustedPartnerPrivate,
          tenantId: 'partner_alpha',
          agentClass: TruthAgentClass.partner,
          sphereId: 'partner_demand',
          familyId: 'attendance_family',
        ),
        forecastId: 'forecast-1',
        subjectId: 'venue:saturn',
        outcomeKind: ForecastOutcomeKind.binary,
        resolvedAt: DateTime.utc(2025, 4, 3, 12),
        actualOutcomeLabel: 'positive',
        signerId: 'signer-1',
        signature: 'signed-receipt',
        idempotencyKey: 'receipt-1',
        metadata: const <String, dynamic>{'channel': 'partner_api'},
      );

      final decoded = PartnerOutcomeReceipt.fromJson(receipt.toJson());

      expect(decoded.scope.scopeKey, receipt.scope.scopeKey);
      expect(decoded.actualOutcomeLabel, 'positive');
      expect(decoded.metadata['channel'], 'partner_api');
    });
  });
}
