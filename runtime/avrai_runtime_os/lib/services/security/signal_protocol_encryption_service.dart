// Signal Protocol Encryption Service for Phase 14: Signal Protocol Implementation
// Option 1: libsignal-ffi via FFI
// Implements MessageEncryptionService interface using Signal Protocol

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:convert';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_protocol_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_types.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Signal Protocol Encryption Service
///
/// Implements MessageEncryptionService using Signal Protocol.
/// Provides perfect forward secrecy, X3DH key exchange, and Double Ratchet.
///
/// Phase 14: Signal Protocol Implementation - Option 1
class SignalProtocolEncryptionService implements MessageEncryptionService {
  static const String _logName = 'SignalProtocolEncryptionService';

  final SignalProtocolService _signalProtocol;
  final SupabaseService _supabaseService;
  final AtomicClockService _atomicClock;

  SignalProtocolEncryptionService({
    required SignalProtocolService signalProtocol,
    required SupabaseService supabaseService,
    required AtomicClockService atomicClock,
  })  : _signalProtocol = signalProtocol,
        _supabaseService = supabaseService,
        _atomicClock = atomicClock;

  /// Check if Signal Protocol is initialized and ready
  bool get isInitialized => _signalProtocol.isInitialized;

  @override
  EncryptionType get encryptionType => EncryptionType.signalProtocol;

  /// Encrypt a message for a recipient
  ///
  /// Uses Signal Protocol (Double Ratchet) for encryption.
  /// Automatically establishes session if needed via X3DH.
  ///
  /// **Parameters:**
  /// - `plaintext`: Message to encrypt
  /// - `recipientId`: Recipient's Signal address (for user-to-user messaging: auth user id)
  ///
  /// **Returns:**
  /// Encrypted message with Signal Protocol metadata
  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    try {
      // Ensure Signal Protocol is initialized
      if (!_signalProtocol.isInitialized) {
        await _signalProtocol.initialize();
      }

      // Convert plaintext to bytes
      final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

      // Encrypt using Signal Protocol
      final encrypted = await _signalProtocol.encryptMessage(
        plaintext: plaintextBytes,
        recipientId: recipientId,
      );

      // Convert to EncryptedMessage format
      final encryptedBytes = encrypted.toBytes();

      // Phase 14 requirement: timestamps must use AtomicClockService (not DateTime.now()).
      final atomicTimestamp = await _atomicClock.getAtomicTimestamp();

      developer.log(
        'Message encrypted using Signal Protocol for recipient: $recipientId',
        name: _logName,
      );

      return EncryptedMessage(
        encryptedContent: encryptedBytes,
        encryptionType: EncryptionType.signalProtocol,
        metadata: {
          'recipientId': recipientId,
          'timestamp': atomicTimestamp.serverTime.toIso8601String(),
          'atomicTimestamp': atomicTimestamp.toJson(),
          'messageHeaderLength': encrypted.messageHeader?.length ?? 0,
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error encrypting message with Signal Protocol: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Signal Protocol encryption failed: $e');
    }
  }

  /// Decrypt a message from a sender
  ///
  /// Uses Signal Protocol (Double Ratchet) for decryption.
  /// Automatically establishes session if needed via X3DH.
  ///
  /// **Parameters:**
  /// - `encrypted`: Encrypted message
  /// - `senderId`: Sender's Signal address (for user-to-user messaging: auth user id)
  ///
  /// **Returns:**
  /// Decrypted plaintext
  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    try {
      // Ensure Signal Protocol is initialized
      if (!_signalProtocol.isInitialized) {
        await _signalProtocol.initialize();
      }

      // Validate encryption type
      if (encrypted.encryptionType != EncryptionType.signalProtocol) {
        throw Exception(
          'Invalid encryption type: expected SignalProtocol, got ${encrypted.encryptionType}',
        );
      }

      // Get encrypted content
      final encryptedBytes = encrypted.encryptedContent;

      // Parse SignalEncryptedMessage
      final signalEncrypted = SignalEncryptedMessage.fromBytes(encryptedBytes);

      // Decrypt using Signal Protocol
      final plaintextBytes = await _signalProtocol.decryptMessage(
        encrypted: signalEncrypted,
        senderId: senderId,
      );

      // Convert bytes to string
      final plaintext = utf8.decode(plaintextBytes);

      developer.log(
        'Message decrypted using Signal Protocol from sender: $senderId',
        name: _logName,
      );

      return plaintext;
    } catch (e, stackTrace) {
      developer.log(
        'Error decrypting message with Signal Protocol: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Signal Protocol decryption failed: $e');
    }
  }

  /// Initialize Signal Protocol service
  ///
  /// Should be called during app initialization.
  /// Uploads a prekey bundle keyed by the current auth user id.
  Future<void> initialize() async {
    try {
      await _signalProtocol.initialize();

      // Upload prekey bundle to key server
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) {
        throw Exception(
            'No authenticated user found. Cannot upload prekey bundle.');
      }
      await _signalProtocol.uploadPreKeyBundle(currentUser.id);

      developer.log('Signal Protocol encryption service initialized',
          name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing Signal Protocol encryption service: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - allow fallback to AES-256-GCM
      developer.log(
        'Signal Protocol initialization failed, will use fallback encryption',
        name: _logName,
      );
    }
  }
}
