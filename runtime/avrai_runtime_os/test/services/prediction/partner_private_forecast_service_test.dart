import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_resolution_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';
import 'package:avrai_runtime_os/services/prediction/partner_outcome_receipt_ledger.dart';
import 'package:avrai_runtime_os/services/prediction/partner_private_forecast_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/forecast/baseline_forecast_kernel.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';

void main() {
  TemporalInstant buildInstant(DateTime time) {
    return TemporalInstant(
      referenceTime: time.toUtc(),
      civilTime: time,
      timezoneId: 'America/Chicago',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'test',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: time.microsecondsSinceEpoch,
    );
  }

  ReplayYearCompletenessScore buildScore(double score) {
    return ReplayYearCompletenessScore(
      year: 2025,
      eventCoverage: score,
      venueCoverage: score,
      communityCoverage: score,
      recurrenceFidelity: score,
      temporalCertainty: score,
      trustQuality: score,
      overallScore: score,
    );
  }

  ForecastKernelRequest buildPartnerRequest(String partnerId) {
    final instant = buildInstant(DateTime.utc(2025, 4, 1, 18));
    final truthScope = TruthScopeDescriptor.defaultForecast(
      governanceStratum: GovernanceStratum.locality,
      tenantScope: TruthTenantScope.trustedPartnerPrivate,
      tenantId: partnerId,
      agentClass: TruthAgentClass.partner,
      sphereId: 'partner_demand',
      familyId: 'tenant_private_attendance',
    );
    return ForecastKernelRequest(
      forecastId: 'partner-forecast-1',
      subjectId: 'venue:saturn',
      replayEnvelope: ReplayTemporalEnvelope(
        envelopeId: 'env-1',
        subjectId: 'venue:saturn',
        observedAt: instant,
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.historicalImport,
          source: 'partner_feed',
        ),
        uncertainty: const TemporalUncertainty(
          window: Duration(minutes: 10),
          confidence: 0.87,
        ),
        temporalAuthoritySource: 'when_kernel',
        branchId: 'branch-a',
        runId: 'run-1',
        metadata: const <String, dynamic>{'demand_signal': 0.91},
      ),
      runContext: const MonteCarloRunContext(
        canonicalReplayYear: 2025,
        replayYear: 2025,
        branchId: 'branch-a',
        runId: 'run-1',
        seed: 9,
        divergencePolicy: 'none',
      ),
      targetWindow: TemporalInterval(start: instant, end: instant),
      evidenceWindow: TemporalInterval(start: instant, end: instant),
      forecastFamilyId: 'tenant_private_attendance',
      truthScope: truthScope,
      metadata: <String, dynamic>{
        'truth_scope': truthScope.toJson(),
        'tenant_scope': TruthTenantScope.trustedPartnerPrivate.name,
        'tenant_id': partnerId,
        'agent_class': TruthAgentClass.partner.name,
        'forecast_sphere_id': 'partner_demand',
      },
    );
  }

  group('PartnerPrivateForecastService', () {
    late ForecastSkillLedger skillLedger;
    late PartnerPrivateForecastService service;

    setUp(() {
      skillLedger = ForecastSkillLedger(
        nowProvider: () => DateTime.utc(2025, 4, 2, 12),
      );
      final projectionService = ForecastGovernanceProjectionService(
        forecastKernel: const BaselineForecastKernel(),
        temporalKernel: SystemTemporalKernel(
          clockSource:
              FixedClockSource(buildInstant(DateTime.utc(2026, 3, 10, 12))),
        ),
        skillLedger: skillLedger,
      );
      service = PartnerPrivateForecastService(
        projectionService: projectionService,
        resolutionService: ForecastResolutionService(skillLedger: skillLedger),
        skillLedger: skillLedger,
        receiptLedger: PartnerOutcomeReceiptLedger(),
      );
    });

    test('evaluates a tenant-private partner forecast with scoped governance',
        () async {
      const partnerId = 'partner_alpha';
      final result = await service.evaluatePartnerForecast(
        partnerId: partnerId,
        request: buildPartnerRequest(partnerId),
        replayYearScore: buildScore(0.86),
      );

      expect(result.partnerId, partnerId);
      expect(result.scope.tenantScope, TruthTenantScope.trustedPartnerPrivate);
      expect(result.scope.tenantId, partnerId);
      expect(
        result.projection.result.truthScope?.scopeKey,
        result.scope.scopeKey,
      );
      expect(
        skillLedger
            .issuedForecastById('partner-forecast-1')
            ?.truthScope
            .scopeKey,
        result.scope.scopeKey,
      );
    });

    test('rejects outside-buyer credentials for partner-private forecasts',
        () async {
      await expectLater(
        service.evaluatePartnerForecast(
          partnerId: 'outside_buyer_marketplace',
          request: buildPartnerRequest('outside_buyer_marketplace'),
          replayYearScore: buildScore(0.80),
        ),
        throwsA(
          isA<PartnerPrivateForecastAccessException>().having(
            (error) => error.message,
            'message',
            contains('Outside-buyer credentials'),
          ),
        ),
      );
    });

    test('records signed partner outcome receipts idempotently', () async {
      const partnerId = 'partner_alpha';
      final result = await service.evaluatePartnerForecast(
        partnerId: partnerId,
        request: buildPartnerRequest(partnerId),
        replayYearScore: buildScore(0.86),
      );
      final receipt = PartnerOutcomeReceipt(
        tenantId: partnerId,
        scope: result.scope,
        forecastId: result.projection.result.claim.claimId,
        subjectId: 'venue:saturn',
        outcomeKind: ForecastOutcomeKind.binary,
        resolvedAt: DateTime.utc(2025, 4, 3, 12),
        actualOutcomeLabel: 'positive',
        signerId: 'partner_signer_1',
        signature: 'signed-receipt',
        idempotencyKey: 'receipt-1',
      );

      final recorded = await service.recordPartnerOutcomeReceipt(receipt);
      final duplicate = await service.recordPartnerOutcomeReceipt(receipt);
      final issuedRecord = skillLedger
          .issuedForecastById(result.projection.result.claim.claimId)!;
      final resolvedRecords = skillLedger.resolvedRecordsForBucketKeys(
        <String>[issuedRecord.bucketKey],
      );

      expect(recorded, isTrue);
      expect(duplicate, isFalse);
      expect(resolvedRecords, hasLength(1));
      expect(resolvedRecords.single.resolution.truthScope?.tenantId, partnerId);
    });

    test('rejects unsigned partner outcome receipts', () async {
      const partnerId = 'partner_alpha';
      final result = await service.evaluatePartnerForecast(
        partnerId: partnerId,
        request: buildPartnerRequest(partnerId),
        replayYearScore: buildScore(0.86),
      );

      await expectLater(
        service.recordPartnerOutcomeReceipt(
          PartnerOutcomeReceipt(
            tenantId: partnerId,
            scope: result.scope,
            forecastId: result.projection.result.claim.claimId,
            subjectId: 'venue:saturn',
            outcomeKind: ForecastOutcomeKind.binary,
            resolvedAt: DateTime.utc(2025, 4, 3, 12),
            actualOutcomeLabel: 'positive',
            signerId: 'partner_signer_1',
            signature: '',
            idempotencyKey: 'receipt-unsigned',
          ),
        ),
        throwsA(
          isA<PartnerPrivateForecastAccessException>().having(
            (error) => error.message,
            'message',
            contains('must include a signer and signature'),
          ),
        ),
      );
    });
  });
}
