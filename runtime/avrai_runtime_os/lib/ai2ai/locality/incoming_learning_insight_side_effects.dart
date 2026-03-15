// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';

class IncomingLearningInsightSideEffects {
  const IncomingLearningInsightSideEffects._();

  static String emitSuccess({
    required String insightId,
    required String sender,
    required String originId,
    required int hop,
    required bool applied,
    required double learningQuality,
    required int deltaDimensionsCount,
    required void Function() forwardGossip,
  }) {
    final eventType =
        applied ? 'ai2ai_learning_applied' : 'ai2ai_learning_buffered';
    if (LedgerAuditV0.isEnabled) {
      unawaited(LedgerAuditV0.tryAppend(
        domain: LedgerDomainV0.deviceCapability,
        eventType: eventType,
        occurredAt: DateTime.now(),
        payload: <String, Object?>{
          'insight_id': insightId,
          'sender_device_id': sender,
          'origin_id': originId,
          'hop': hop,
          'applied': applied,
          'schema_version': 1,
          'learning_quality': learningQuality,
          'delta_dimensions_count': deltaDimensionsCount,
        },
      ));
    }

    forwardGossip();
    return eventType;
  }

  static void emitFailure({
    required Object error,
    required String senderDeviceId,
    required AppLogger logger,
    required String logTag,
  }) {
    logger.debug(
      'Failed to apply incoming learning insight: $error',
      tag: logTag,
    );
    if (!LedgerAuditV0.isEnabled) return;

    unawaited(LedgerAuditV0.tryAppend(
      domain: LedgerDomainV0.deviceCapability,
      eventType: 'ai2ai_learning_insight_receive_failed',
      occurredAt: DateTime.now(),
      payload: <String, Object?>{
        'sender_device_id': senderDeviceId,
        'error': error.toString(),
      },
    ));
  }
}
