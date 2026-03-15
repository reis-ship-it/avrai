import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_resolution_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';
import 'package:avrai_runtime_os/services/prediction/partner_outcome_receipt_ledger.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';

class PartnerPrivateForecastAccessException implements Exception {
  const PartnerPrivateForecastAccessException(this.message);

  final String message;

  @override
  String toString() => 'PartnerPrivateForecastAccessException($message)';
}

class PartnerPrivateForecastResult {
  const PartnerPrivateForecastResult({
    required this.partnerId,
    required this.scope,
    required this.projection,
  });

  final String partnerId;
  final TruthScopeDescriptor scope;
  final ForecastGovernanceProjection projection;
}

class PartnerPrivateForecastService {
  PartnerPrivateForecastService({
    required ForecastGovernanceProjectionService projectionService,
    required ForecastResolutionService resolutionService,
    required ForecastSkillLedger skillLedger,
    PartnerOutcomeReceiptLedger? receiptLedger,
    TruthScopeRegistry truthScopeRegistry = const TruthScopeRegistry(),
  })  : _projectionService = projectionService,
        _resolutionService = resolutionService,
        _skillLedger = skillLedger,
        _receiptLedger = receiptLedger ?? PartnerOutcomeReceiptLedger(),
        _truthScopeRegistry = truthScopeRegistry;

  final ForecastGovernanceProjectionService _projectionService;
  final ForecastResolutionService _resolutionService;
  final ForecastSkillLedger _skillLedger;
  final PartnerOutcomeReceiptLedger _receiptLedger;
  final TruthScopeRegistry _truthScopeRegistry;

  Future<PartnerPrivateForecastResult> evaluatePartnerForecast({
    required String partnerId,
    required ForecastKernelRequest request,
    required ReplayYearCompletenessScore replayYearScore,
    List<GroundTruthOverrideRecord> overrideRecords =
        const <GroundTruthOverrideRecord>[],
  }) async {
    final scope = _truthScopeRegistry.normalizeForecastScope(
      scope: request.truthScope,
      metadata: request.metadata,
      familyId: request.forecastFamilyId,
    );
    _validatePartnerScope(partnerId: partnerId, scope: scope);

    final normalizedRequest = ForecastKernelRequest(
      forecastId: request.forecastId,
      subjectId: request.subjectId,
      replayEnvelope: request.replayEnvelope,
      runContext: request.runContext,
      targetWindow: request.targetWindow,
      evidenceWindow: request.evidenceWindow,
      forecastFamilyId: request.forecastFamilyId,
      outcomeKind: request.outcomeKind,
      decisionSpec: request.decisionSpec,
      truthScope: scope,
      metadata: <String, dynamic>{
        ...request.metadata,
        'truth_scope': scope.toJson(),
        'tenant_scope': scope.tenantScope.name,
        'tenant_id': scope.tenantId,
      },
    );

    final projection = await _projectionService.evaluateForecast(
      request: normalizedRequest,
      replayYearScore: replayYearScore,
      overrideRecords: overrideRecords,
    );
    return PartnerPrivateForecastResult(
      partnerId: partnerId,
      scope: scope,
      projection: projection,
    );
  }

  Future<bool> recordPartnerOutcomeReceipt(
    PartnerOutcomeReceipt receipt,
  ) async {
    final issued = _skillLedger.issuedForecastById(receipt.forecastId);
    if (issued == null) {
      throw PartnerPrivateForecastAccessException(
        'No issued forecast found for receipt ${receipt.forecastId}.',
      );
    }
    final normalizedScope = _truthScopeRegistry.normalizeForecastScope(
      scope: receipt.scope,
      metadata: receipt.metadata,
      familyId: issued.forecastFamilyId,
    );
    _validatePartnerScope(partnerId: receipt.tenantId, scope: normalizedScope);
    if (receipt.signerId.trim().isEmpty || receipt.signature.trim().isEmpty) {
      throw const PartnerPrivateForecastAccessException(
        'Partner outcome receipts must include a signer and signature.',
      );
    }
    if (receipt.idempotencyKey.trim().isEmpty) {
      throw const PartnerPrivateForecastAccessException(
        'Partner outcome receipts require a stable idempotency key.',
      );
    }
    if (issued.truthScope.scopeKey != normalizedScope.scopeKey) {
      throw const PartnerPrivateForecastAccessException(
        'Receipt scope does not match the issued forecast truth scope.',
      );
    }
    if (issued.truthScope.tenantId != receipt.tenantId) {
      throw PartnerPrivateForecastAccessException(
        'Receipt tenant does not match issued forecast tenant.',
      );
    }
    final normalizedReceipt = PartnerOutcomeReceipt(
      tenantId: receipt.tenantId,
      scope: normalizedScope,
      forecastId: receipt.forecastId,
      subjectId: receipt.subjectId,
      outcomeKind: receipt.outcomeKind,
      resolvedAt: receipt.resolvedAt,
      actualOutcomeLabel: receipt.actualOutcomeLabel,
      actualOutcomeValue: receipt.actualOutcomeValue,
      signerId: receipt.signerId,
      signature: receipt.signature,
      idempotencyKey: receipt.idempotencyKey,
      metadata: receipt.metadata,
    );
    final recorded = await _receiptLedger.recordReceipt(normalizedReceipt);
    if (!recorded) {
      return false;
    }

    await _resolutionService.recordResolution(
      ForecastResolutionRecord(
        resolutionId:
            '${normalizedReceipt.forecastId}:${normalizedReceipt.idempotencyKey}',
        forecastId: normalizedReceipt.forecastId,
        forecastFamilyId: issued.forecastFamilyId,
        subjectId: normalizedReceipt.subjectId,
        outcomeKind: normalizedReceipt.outcomeKind,
        resolvedAt: normalizedReceipt.resolvedAt,
        actualOutcomeLabel: normalizedReceipt.actualOutcomeLabel,
        actualOutcomeValue: normalizedReceipt.actualOutcomeValue,
        sphereId: issued.sphereId,
        truthScope: normalizedReceipt.scope,
        metadata: <String, dynamic>{
          ...normalizedReceipt.metadata,
          'partner_signer_id': normalizedReceipt.signerId,
          'partner_signature': normalizedReceipt.signature,
        },
      ),
    );
    return true;
  }

  void _validatePartnerScope({
    required String partnerId,
    required TruthScopeDescriptor scope,
  }) {
    if (partnerId.startsWith('outside_buyer_')) {
      throw const PartnerPrivateForecastAccessException(
        'Outside-buyer credentials cannot access partner-private forecasting.',
      );
    }
    if (scope.truthSurfaceKind != TruthSurfaceKind.forecast) {
      throw const PartnerPrivateForecastAccessException(
        'Partner-private forecasting requires a forecast truth surface.',
      );
    }
    if (scope.tenantScope != TruthTenantScope.trustedPartnerPrivate) {
      throw const PartnerPrivateForecastAccessException(
        'Partner-private forecasting requires trusted partner private scope.',
      );
    }
    if (scope.tenantId != partnerId) {
      throw PartnerPrivateForecastAccessException(
        'Partner scope tenant mismatch for $partnerId.',
      );
    }
  }
}
