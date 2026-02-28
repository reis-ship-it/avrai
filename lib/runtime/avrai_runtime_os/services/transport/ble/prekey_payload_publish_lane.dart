// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_network/avra_network.dart';

class PrekeyPayloadPublishLane {
  const PrekeyPayloadPublishLane._();

  static Future<void> publishIfAvailable({
    required SignalKeyManager? signalKeyManager,
    required String localBleNodeId,
    required AppLogger logger,
    required String logName,
  }) async {
    if (signalKeyManager == null) return;
    try {
      final bundle = await signalKeyManager.generatePreKeyBundle();
      final payloadJson = <String, dynamic>{
        'version': 1,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'node_id': localBleNodeId,
        'prekey_bundle': _signalPreKeyBundleToJson(bundle),
      };
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadJson)));
      final ok = await BlePeripheral.updatePreKeyPayload(payload: bytes);
      if (ok) {
        logger.info('Published Signal prekey payload over BLE', tag: logName);
        if (LedgerAuditV0.isEnabled) {
          unawaited(LedgerAuditV0.tryAppend(
            domain: LedgerDomainV0.deviceCapability,
            eventType: 'ai2ai_ble_prekey_payload_published',
            occurredAt: DateTime.now(),
            payload: <String, Object?>{
              'ok': true,
              'bytes_len': bytes.length,
              'schema_version': 1,
            },
          ));
        }
      } else {
        logger.warn('Failed to publish Signal prekey payload over BLE',
            tag: logName);
        if (LedgerAuditV0.isEnabled) {
          unawaited(LedgerAuditV0.tryAppend(
            domain: LedgerDomainV0.deviceCapability,
            eventType: 'ai2ai_ble_prekey_payload_publish_failed',
            occurredAt: DateTime.now(),
            payload: <String, Object?>{
              'ok': false,
              'bytes_len': bytes.length,
              'schema_version': 1,
            },
          ));
        }
      }
    } catch (e) {
      logger.warn('Error publishing Signal prekey payload over BLE: $e',
          tag: logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_ble_prekey_payload_publish_error',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'error': e.toString(),
          },
        ));
      }
    }
  }

  static Map<String, dynamic> _signalPreKeyBundleToJson(SignalPreKeyBundle bundle) {
    return <String, dynamic>{
      'preKeyId': bundle.preKeyId,
      'signedPreKey': bundle.signedPreKey.toList(),
      'signedPreKeyId': bundle.signedPreKeyId,
      'signature': bundle.signature.toList(),
      'identityKey': bundle.identityKey.toList(),
      'oneTimePreKey': bundle.oneTimePreKey?.toList(),
      'oneTimePreKeyId': bundle.oneTimePreKeyId,
      'registrationId': bundle.registrationId,
      'deviceId': bundle.deviceId,
      'kyberPreKeyId': bundle.kyberPreKeyId,
      'kyberPreKey': bundle.kyberPreKey?.toList(),
      'kyberPreKeySignature': bundle.kyberPreKeySignature?.toList(),
    };
  }
}
