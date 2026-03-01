// Signal Protocol Integration for AnonymousCommunicationProtocol
// Phase 14: Signal Protocol Implementation - Option 1
//
// This file contains integration helpers for adding Signal Protocol to AnonymousCommunicationProtocol.
// The actual integration will be done once FFI bindings are complete.

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:convert';
import 'package:avrai_runtime_os/crypto/signal/signal_protocol_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_types.dart';

/// Signal Protocol Integration Helper for AnonymousCommunicationProtocol
///
/// Provides helper methods for integrating Signal Protocol into AnonymousCommunicationProtocol.
///
/// **Note:** This is a preparation file. Actual integration will happen once
/// FFI bindings are complete and Signal Protocol is fully functional.
class AnonymousCommunicationSignalIntegration {
  static const String _logName = 'AnonymousCommunicationSignalIntegration';

  final SignalProtocolService? _signalProtocol;

  AnonymousCommunicationSignalIntegration({
    SignalProtocolService? signalProtocol,
  }) : _signalProtocol = signalProtocol;

  /// Check if Signal Protocol is available and ready
  bool get isAvailable =>
      _signalProtocol != null && _signalProtocol.isInitialized;

  /// Encrypt payload using Signal Protocol (if available)
  ///
  /// Falls back to returning null if Signal Protocol is not available,
  /// allowing caller to use AES-256-GCM fallback.
  ///
  /// **Parameters:**
  /// - `payload`: Payload to encrypt (as Map)
  /// - `recipientAgentId`: Recipient's agent ID (required for Signal Protocol)
  ///
  /// **Returns:**
  /// Base64-encoded encrypted payload if Signal Protocol is available, null otherwise
  Future<String?> encryptPayloadWithSignalProtocol({
    required Map<String, dynamic> payload,
    required String recipientAgentId,
  }) async {
    if (!isAvailable) {
      developer.log(
        'Signal Protocol not available, returning null for fallback',
        name: _logName,
      );
      return null;
    }

    try {
      // Convert payload to JSON bytes
      final payloadJson = jsonEncode(payload);
      final plaintextBytes = Uint8List.fromList(utf8.encode(payloadJson));

      // Encrypt using Signal Protocol
      final encrypted = await _signalProtocol!.encryptMessage(
        plaintext: plaintextBytes,
        recipientId: recipientAgentId,
      );

      // Convert to base64
      final encryptedBytes = encrypted.toBytes();
      final encryptedBase64 = base64Encode(encryptedBytes);

      developer.log(
        'Payload encrypted using Signal Protocol for recipient: $recipientAgentId',
        name: _logName,
      );

      return encryptedBase64;
    } catch (e, stackTrace) {
      developer.log(
        'Error encrypting payload with Signal Protocol, falling back to AES-256-GCM: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null; // Fallback to AES-256-GCM
    }
  }

  /// Decrypt payload using Signal Protocol (if available)
  ///
  /// Falls back to returning null if Signal Protocol is not available,
  /// allowing caller to use AES-256-GCM fallback.
  ///
  /// **Parameters:**
  /// - `encryptedBase64`: Base64-encoded encrypted payload
  /// - `senderAgentId`: Sender's agent ID (required for Signal Protocol)
  ///
  /// **Returns:**
  /// Decrypted payload (as Map) if Signal Protocol is available, null otherwise
  Future<Map<String, dynamic>?> decryptPayloadWithSignalProtocol({
    required String encryptedBase64,
    required String senderAgentId,
  }) async {
    if (!isAvailable) {
      developer.log(
        'Signal Protocol not available, returning null for fallback',
        name: _logName,
      );
      return null;
    }

    try {
      // Decode base64
      final encryptedBytes = base64Decode(encryptedBase64);

      // Parse SignalEncryptedMessage from bytes
      final signalEncrypted = SignalEncryptedMessage.fromBytes(encryptedBytes);

      // Decrypt using Signal Protocol
      final decryptedBytes = await _signalProtocol!.decryptMessage(
        encrypted: signalEncrypted,
        senderId: senderAgentId,
      );

      // Convert bytes to JSON
      final decryptedJson = utf8.decode(decryptedBytes);
      final payload = jsonDecode(decryptedJson) as Map<String, dynamic>;

      developer.log(
        'Payload decrypted using Signal Protocol from sender: $senderAgentId',
        name: _logName,
      );

      return payload;
    } catch (e, stackTrace) {
      developer.log(
        'Error decrypting payload with Signal Protocol, falling back to AES-256-GCM: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null; // Fallback to AES-256-GCM
    }
  }

  /// Initialize Signal Protocol (if available)
  ///
  /// Should be called during AnonymousCommunicationProtocol initialization.
  Future<void> initialize() async {
    if (_signalProtocol != null && !_signalProtocol.isInitialized) {
      try {
        await _signalProtocol.initialize();
        developer.log(
            'Signal Protocol initialized for AnonymousCommunicationProtocol',
            name: _logName);
      } catch (e, stackTrace) {
        developer.log(
          'Error initializing Signal Protocol: $e',
          name: _logName,
          error: e,
          stackTrace: stackTrace,
        );
        // Continue without Signal Protocol (fallback to AES-256-GCM)
      }
    }
  }
}
