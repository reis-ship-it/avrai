import 'dart:typed_data';

import 'package:avrai/core/crypto/signal/ai_agent_fingerprint_service.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:get_it/get_it.dart';

class ConnectionIdentityBindingResult {
  const ConnectionIdentityBindingResult({
    this.handshakeHash,
    this.localAgentFingerprint,
    this.remoteAgentFingerprint,
  });

  final Uint8List? handshakeHash;
  final String? localAgentFingerprint;
  final String? remoteAgentFingerprint;
}

class ConnectionIdentityBindingLane {
  const ConnectionIdentityBindingLane._();

  static Future<ConnectionIdentityBindingResult> collect({
    required SignalKeyManager? signalKeyManager,
    required String remoteAgentId,
    required String connectionId,
    required AppLogger logger,
    required String logName,
  }) async {
    Uint8List? handshakeHash;
    String? localAgentFingerprint;
    String? remoteAgentFingerprint;

    try {
      final sl = GetIt.instance;

      if (signalKeyManager != null) {
        try {
          final localIdentityKeyPair =
              await signalKeyManager.getOrGenerateIdentityKeyPair();
          final localFingerprint =
              AIAgentFingerprintService.generateFingerprintFromKeyPair(
                  localIdentityKeyPair);
          localAgentFingerprint = localFingerprint.hexString;
          logger.debug(
            'Generated local AI agent fingerprint: ${localFingerprint.displayFormat.substring(0, 20)}...',
            tag: logName,
          );
        } catch (e) {
          logger.debug(
            'Failed to generate local fingerprint: $e',
            tag: logName,
          );
        }

        try {
          final remotePreKeyBundle =
              await signalKeyManager.fetchPreKeyBundle(remoteAgentId);
          final remoteFingerprint =
              AIAgentFingerprintService.generateFingerprintFromBundle(
                  remotePreKeyBundle);
          remoteAgentFingerprint = remoteFingerprint.hexString;
          logger.debug(
            'Generated remote AI agent fingerprint: ${remoteFingerprint.displayFormat.substring(0, 20)}...',
            tag: logName,
          );
        } catch (e) {
          logger.debug(
            'Failed to generate remote fingerprint: $e (will be set on first message)',
            tag: logName,
          );
        }
      }

      if (sl.isRegistered<SignalSessionManager>()) {
        final sessionManager = sl<SignalSessionManager>();
        handshakeHash = await sessionManager.getChannelBindingHash(remoteAgentId);
        if (handshakeHash != null) {
          logger.debug(
            'Channel binding hash extracted for connection: $connectionId',
            tag: logName,
          );
        }
      }
    } catch (e) {
      logger.debug(
        'Failed to extract fingerprints/channel binding hash: $e (will be set on first message)',
        tag: logName,
      );
    }

    return ConnectionIdentityBindingResult(
      handshakeHash: handshakeHash,
      localAgentFingerprint: localAgentFingerprint,
      remoteAgentFingerprint: remoteAgentFingerprint,
    );
  }
}
