// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:convert';

import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/misc/break_glass_governance_directive.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_break_glass_governance_contract.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_governance_inspection_contract.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_quantum_atomic_time_validity_contract.dart';
import 'package:avrai_runtime_os/services/admin/audit_log_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class UrkGovernanceInspectionService {
  UrkGovernanceInspectionService({
    AuditLogService? auditLogService,
    SharedPreferencesCompat? prefs,
    UrkGovernanceInspectionValidator governanceInspectionValidator =
        const UrkGovernanceInspectionValidator(),
    UrkBreakGlassGovernanceValidator breakGlassGovernanceValidator =
        const UrkBreakGlassGovernanceValidator(),
    UrkQuantumAtomicTimeValidityValidator quantumAtomicTimeValidityValidator =
        const UrkQuantumAtomicTimeValidityValidator(),
  })  : _auditLogService = auditLogService ?? AuditLogService(),
        _prefs = prefs,
        _governanceInspectionValidator = governanceInspectionValidator,
        _breakGlassGovernanceValidator = breakGlassGovernanceValidator,
        _quantumAtomicTimeValidityValidator =
            quantumAtomicTimeValidityValidator;

  static const String _inspectionAuditKey =
      'urk_governance_inspection_audit_v1';
  static const String _breakGlassReceiptKey =
      'urk_break_glass_receipt_audit_v1';
  static const int _maxStoredArtifacts = 200;

  final AuditLogService _auditLogService;
  final SharedPreferencesCompat? _prefs;
  final UrkGovernanceInspectionValidator _governanceInspectionValidator;
  final UrkBreakGlassGovernanceValidator _breakGlassGovernanceValidator;
  final UrkQuantumAtomicTimeValidityValidator
      _quantumAtomicTimeValidityValidator;

  Future<GovernanceInspectionResponse> inspect({
    required GovernanceInspectionRequest request,
    required UrkGovernanceInspectionSnapshot snapshot,
    required UrkGovernanceInspectionPolicy policy,
    required GovernanceWhoKernelPayload whoKernel,
    required GovernanceWhatKernelPayload whatKernel,
    required GovernanceWhenKernelPayload whenKernel,
    required GovernanceWhereKernelPayload whereKernel,
    required GovernanceWhyKernelPayload whyKernel,
    required GovernanceHowKernelPayload howKernel,
    GovernanceInspectionPolicyState policyState =
        const GovernanceInspectionPolicyState(),
    List<GovernanceInspectionProvenanceEntry> provenance =
        const <GovernanceInspectionProvenanceEntry>[],
  }) async {
    final validationResult = _governanceInspectionValidator.validate(
      snapshot: snapshot,
      policy: policy,
    );
    final auditRef =
        'gov_inspect_${request.targetRuntimeId}_${request.requestId}';
    final respondedAt = AtomicTimestamp.now(
      precision: TimePrecision.millisecond,
      isSynchronized: request.requestedAt.isSynchronized,
      serverTime: DateTime.now().toUtc(),
    );

    final response = GovernanceInspectionResponse(
      request: request,
      approved: validationResult.isPassing,
      auditRef: auditRef,
      respondedAt: respondedAt,
      failureCodes: validationResult.failures.map((e) => e.name).toList(),
      payload: validationResult.isPassing
          ? GovernanceInspectionPayload(
              whoKernel: whoKernel,
              whatKernel: whatKernel,
              whenKernel: whenKernel,
              whereKernel: whereKernel,
              whyKernel: whyKernel,
              howKernel: howKernel,
              policyState: policyState,
              provenance: provenance,
            )
          : null,
    );

    await _auditLogService.logSecurityEvent(
      'governance_inspect',
      request.actorId,
      response.approved ? 'approved' : 'blocked',
      metadata: <String, dynamic>{
        'auditRef': auditRef,
        'targetRuntimeId': request.targetRuntimeId,
        'targetStratum': request.targetStratum.name,
        'visibilityTier': request.visibilityTier.name,
        'isHumanActor': request.isHumanActor,
        'failureCodes': response.failureCodes,
      },
    );

    await _appendArtifact(
      storageKey: _inspectionAuditKey,
      artifactJson: response.toJson(),
    );

    return response;
  }

  Future<BreakGlassGovernanceReceipt> evaluateDirective({
    required BreakGlassGovernanceDirective directive,
    required UrkBreakGlassGovernanceSnapshot breakGlassSnapshot,
    required UrkBreakGlassGovernancePolicy breakGlassPolicy,
    required UrkQuantumAtomicTimeValiditySnapshot quantumTimeSnapshot,
    required UrkQuantumAtomicTimeValidityPolicy quantumTimePolicy,
  }) async {
    final breakGlassResult = _breakGlassGovernanceValidator.validate(
      snapshot: breakGlassSnapshot,
      policy: breakGlassPolicy,
    );
    final quantumTimeResult = _quantumAtomicTimeValidityValidator.validate(
      snapshot: quantumTimeSnapshot,
      policy: quantumTimePolicy,
    );

    final failureCodes = <String>[
      ...breakGlassResult.failures.map((e) => e.name),
      ...quantumTimeResult.failures.map((e) => e.name),
    ];
    final isExpired = directive.expiresAt.isBefore(
      AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        isSynchronized: directive.issuedAt.isSynchronized,
        serverTime: DateTime.now().toUtc(),
      ),
    );
    if (isExpired) {
      failureCodes.add('directiveExpired');
    }

    final auditRef =
        'break_glass_${directive.targetRuntimeId}_${directive.directiveId}';
    final evaluatedAt = AtomicTimestamp.now(
      precision: TimePrecision.millisecond,
      isSynchronized: directive.issuedAt.isSynchronized,
      serverTime: DateTime.now().toUtc(),
    );

    final receipt = BreakGlassGovernanceReceipt(
      directive: directive,
      approved: failureCodes.isEmpty,
      auditRef: auditRef,
      evaluatedAt: evaluatedAt,
      failureCodes: failureCodes,
    );

    await _auditLogService.logSecurityEvent(
      'break_glass_directive',
      directive.actorId,
      receipt.approved ? 'approved' : 'blocked',
      metadata: <String, dynamic>{
        'auditRef': auditRef,
        'targetRuntimeId': directive.targetRuntimeId,
        'targetStratum': directive.targetStratum.name,
        'actionType': directive.actionType.name,
        'requiresDualApproval': directive.requiresDualApproval,
        'failureCodes': receipt.failureCodes,
      },
    );

    await _appendArtifact(
      storageKey: _breakGlassReceiptKey,
      artifactJson: receipt.toJson(),
    );

    return receipt;
  }

  Future<List<GovernanceInspectionResponse>> listRecentInspectionResponses({
    int limit = 25,
    GovernanceStratum? stratum,
    String? runtimeId,
  }) async {
    final artifacts = await _readArtifacts(
      storageKey: _inspectionAuditKey,
      decoder: (decoded) => GovernanceInspectionResponse.fromJson(decoded),
    );
    final filtered = artifacts.where((response) {
      if (stratum != null && response.request.targetStratum != stratum) {
        return false;
      }
      if (runtimeId != null && response.request.targetRuntimeId != runtimeId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) =>
          b.respondedAt.serverTime.compareTo(a.respondedAt.serverTime));
    if (filtered.length <= limit) {
      return filtered;
    }
    return filtered.sublist(0, limit);
  }

  Future<List<BreakGlassGovernanceReceipt>> listRecentBreakGlassReceipts({
    int limit = 25,
    GovernanceStratum? stratum,
    String? runtimeId,
  }) async {
    final artifacts = await _readArtifacts(
      storageKey: _breakGlassReceiptKey,
      decoder: (decoded) => BreakGlassGovernanceReceipt.fromJson(decoded),
    );
    final filtered = artifacts.where((receipt) {
      if (stratum != null && receipt.directive.targetStratum != stratum) {
        return false;
      }
      if (runtimeId != null && receipt.directive.targetRuntimeId != runtimeId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) =>
          b.evaluatedAt.serverTime.compareTo(a.evaluatedAt.serverTime));
    if (filtered.length <= limit) {
      return filtered;
    }
    return filtered.sublist(0, limit);
  }

  Future<void> _appendArtifact({
    required String storageKey,
    required Map<String, dynamic> artifactJson,
  }) async {
    final prefs = await _resolvePrefs();
    if (prefs == null) {
      return;
    }
    final existing = prefs.getStringList(storageKey) ?? const <String>[];
    final next = <String>[...existing, jsonEncode(artifactJson)];
    final capped = next.length <= _maxStoredArtifacts
        ? next
        : next.sublist(next.length - _maxStoredArtifacts);
    await prefs.setStringList(storageKey, capped);
  }

  Future<List<T>> _readArtifacts<T>({
    required String storageKey,
    required T Function(Map<String, dynamic> decoded) decoder,
  }) async {
    final prefs = await _resolvePrefs();
    if (prefs == null) {
      return <T>[];
    }
    final raw = prefs.getStringList(storageKey) ?? const <String>[];
    final artifacts = <T>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        artifacts.add(decoder(decoded));
      } catch (_) {
        // Best effort; invalid entries should not block audit replay.
      }
    }
    return artifacts;
  }

  Future<SharedPreferencesCompat?> _resolvePrefs() async {
    if (_prefs != null) {
      return _prefs;
    }
    try {
      return await SharedPreferencesCompat.getInstance();
    } catch (_) {
      return null;
    }
  }
}
