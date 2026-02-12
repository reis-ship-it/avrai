// Hybrid Encryption Service for Phase 14: Signal Protocol Implementation
// Tries Signal Protocol first, falls back to AES-256-GCM if Signal Protocol is unavailable

import 'dart:developer' as developer;
import 'package:avrai/core/services/security/message_encryption_service.dart';
import 'package:avrai/core/services/security/signal_protocol_encryption_service.dart';
import 'package:avrai/core/services/security/message_encryption_service.dart' as aes;

/// Hybrid Encryption Service
/// 
/// Tries Signal Protocol first, falls back to AES-256-GCM if Signal Protocol is unavailable.
/// This provides a smooth migration path from AES-256-GCM to Signal Protocol.
/// 
/// Phase 14: Signal Protocol Implementation - Option 1
class HybridEncryptionService implements MessageEncryptionService {
  static const String _logName = 'HybridEncryptionService';
  
  final SignalProtocolEncryptionService? _signalProtocolService;
  final aes.AES256GCMEncryptionService _aes256GCMService;
  
  HybridEncryptionService({
    SignalProtocolEncryptionService? signalProtocolService,
    aes.AES256GCMEncryptionService? aes256GCMService,
  }) : _signalProtocolService = signalProtocolService,
       _aes256GCMService = aes256GCMService ?? aes.AES256GCMEncryptionService();
  
  @override
  EncryptionType get encryptionType {
    // Return Signal Protocol if available and initialized, otherwise AES-256-GCM
    if (_signalProtocolService != null && _signalProtocolService.isInitialized) {
      return EncryptionType.signalProtocol;
    }
    return EncryptionType.aes256gcm;
  }
  
  /// Check if Signal Protocol is available and ready
  bool get isSignalProtocolAvailable {
    return _signalProtocolService != null && _signalProtocolService.isInitialized;
  }
  
  /// Encrypt a message for a recipient
  /// 
  /// Tries Signal Protocol first, falls back to AES-256-GCM if Signal Protocol fails.
  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    // Try Signal Protocol first if available
    if (_signalProtocolService != null) {
      try {
        // Check if Signal Protocol is initialized
        if (!_signalProtocolService.isInitialized) {
          developer.log(
            'Signal Protocol not initialized, falling back to AES-256-GCM',
            name: _logName,
          );
          return await _aes256GCMService.encrypt(plaintext, recipientId);
        }
        
        // Try Signal Protocol encryption
        final encrypted = await _signalProtocolService.encrypt(plaintext, recipientId);
        
        developer.log(
          'Message encrypted using Signal Protocol for recipient: $recipientId',
          name: _logName,
        );
        
        return encrypted;
      } catch (e, stackTrace) {
        developer.log(
          'Signal Protocol encryption failed, falling back to AES-256-GCM: $e',
          name: _logName,
          error: e,
          stackTrace: stackTrace,
        );
        // Fall back to AES-256-GCM
        return await _aes256GCMService.encrypt(plaintext, recipientId);
      }
    }
    
    // No Signal Protocol available, use AES-256-GCM
    developer.log(
      'Signal Protocol not available, using AES-256-GCM for recipient: $recipientId',
      name: _logName,
    );
    
    return await _aes256GCMService.encrypt(plaintext, recipientId);
  }
  
  /// Decrypt a message from a sender
  /// 
  /// Tries Signal Protocol first, falls back to AES-256-GCM if Signal Protocol fails.
  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    // Check encryption type
    if (encrypted.encryptionType == EncryptionType.signalProtocol) {
      // Try Signal Protocol decryption
      if (_signalProtocolService != null) {
        try {
          // Check if Signal Protocol is initialized
          if (!_signalProtocolService.isInitialized) {
            developer.log(
              'Signal Protocol not initialized, cannot decrypt Signal Protocol message',
              name: _logName,
            );
            throw Exception('Signal Protocol not initialized');
          }
          
          final decrypted = await _signalProtocolService.decrypt(encrypted, senderId);
          
          developer.log(
            'Message decrypted using Signal Protocol from sender: $senderId',
            name: _logName,
          );
          
          return decrypted;
        } catch (e, stackTrace) {
          developer.log(
            'Signal Protocol decryption failed: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          rethrow; // Don't fall back - if it's Signal Protocol encrypted, we need Signal Protocol to decrypt
        }
      } else {
        throw Exception('Signal Protocol service not available, cannot decrypt Signal Protocol message');
      }
    } else {
      // Use AES-256-GCM decryption
      developer.log(
        'Decrypting AES-256-GCM message from sender: $senderId',
        name: _logName,
      );
      
      return await _aes256GCMService.decrypt(encrypted, senderId);
    }
  }
}
