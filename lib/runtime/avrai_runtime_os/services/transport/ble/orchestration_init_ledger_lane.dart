// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai/core/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';

class OrchestrationInitLedgerLane {
  const OrchestrationInitLedgerLane._();

  static void appendInitSkipped(String userId) {
    if (!LedgerAuditV0.isEnabled) return;
    unawaited(LedgerAuditV0.tryAppend(
      domain: LedgerDomainV0.deviceCapability,
      eventType: 'ai2ai_orchestration_init_skipped',
      occurredAt: DateTime.now(),
      entityType: 'user',
      entityId: userId,
      payload: const <String, Object?>{
        'reason': 'discovery_disabled',
      },
    ));
  }

  static void appendInitStarted({
    required String userId,
    required String bleNodeId,
    required bool allowBleSideEffects,
    required bool isTestBinding,
    required bool isWeb,
    required String platform,
  }) {
    if (!LedgerAuditV0.isEnabled) return;
    unawaited(LedgerAuditV0.tryAppend(
      domain: LedgerDomainV0.deviceCapability,
      eventType: 'ai2ai_orchestration_init_started',
      occurredAt: DateTime.now(),
      entityType: 'user',
      entityId: userId,
      payload: <String, Object?>{
        'allow_ble_side_effects': allowBleSideEffects,
        'is_test_binding': isTestBinding,
        'is_web': isWeb,
        'platform': platform,
        'ble_node_id': bleNodeId,
      },
    ));
  }

  static void appendBleForegroundServiceStarted() {
    if (!LedgerAuditV0.isEnabled) return;
    unawaited(LedgerAuditV0.tryAppend(
      domain: LedgerDomainV0.deviceCapability,
      eventType: 'ai2ai_ble_foreground_service_started',
      occurredAt: DateTime.now(),
      payload: const <String, Object?>{
        'platform': 'android',
      },
    ));
  }

  static void appendBleForegroundServiceFailed() {
    if (!LedgerAuditV0.isEnabled) return;
    unawaited(LedgerAuditV0.tryAppend(
      domain: LedgerDomainV0.deviceCapability,
      eventType: 'ai2ai_ble_foreground_service_failed',
      occurredAt: DateTime.now(),
      payload: const <String, Object?>{
        'platform': 'android',
      },
    ));
  }

  static void appendInitCompleted(String userId) {
    if (!LedgerAuditV0.isEnabled) return;
    unawaited(LedgerAuditV0.tryAppend(
      domain: LedgerDomainV0.deviceCapability,
      eventType: 'ai2ai_orchestration_init_completed',
      occurredAt: DateTime.now(),
      entityType: 'user',
      entityId: userId,
      payload: const <String, Object?>{
        'ok': true,
      },
    ));
  }

  static void appendInitFailed(String userId, Object error) {
    if (!LedgerAuditV0.isEnabled) return;
    unawaited(LedgerAuditV0.tryAppend(
      domain: LedgerDomainV0.deviceCapability,
      eventType: 'ai2ai_orchestration_init_failed',
      occurredAt: DateTime.now(),
      entityType: 'user',
      entityId: userId,
      payload: <String, Object?>{
        'error': error.toString(),
      },
    ));
  }
}
