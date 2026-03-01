// ignore: dangling_library_doc_comments
// ignore: dangling_library_doc_comments
/// AI2AI Outreach Communication Service
///
/// Service for sending outreach messages through AI2AI network using Signal Protocol.
/// Part of Predictive Proactive Outreach System - Phase 3
///
/// Uses Signal Protocol for end-to-end encryption of all outreach messages.
/// Routes messages through AnonymousCommunicationProtocol for privacy-preserving delivery.

import 'dart:developer' as developer;
import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart';
import 'package:avrai_runtime_os/services/security/hybrid_encryption_service.dart';
import 'package:avrai_runtime_os/services/security/signal_protocol_encryption_service.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Outreach message type
enum OutreachMessageType {
  communityInvitation,
  groupFormation,
  eventCall,
  spotRecommendation,
  friendSuggestion,
  businessEventInvitation,
  businessExpertPartnership,
  businessBusinessPartnership,
  clubMembershipInvitation,
  clubEventInvitation,
  expertLearningOpportunity,
  expertBusinessPartnership,
  listSuggestion,
  expertCuratedList,
}

/// Outreach message result
class OutreachMessageResult {
  /// Whether message was sent successfully
  final bool success;

  /// Message ID (if successful)
  final String? messageId;

  /// Error message (if failed)
  final String? error;

  /// Timestamp when message was sent
  final DateTime timestamp;

  /// Encryption type used
  final EncryptionType encryptionType;

  OutreachMessageResult({
    required this.success,
    this.messageId,
    this.error,
    required this.timestamp,
    required this.encryptionType,
  });
}

/// Service for sending outreach messages through AI2AI network with Signal Protocol
class AI2AIOutreachCommunicationService {
  static const String _logName = 'AI2AIOutreachCommunicationService';

  final AnonymousCommunicationProtocol _ai2aiProtocol;
  final HybridEncryptionService? _hybridEncryption;
  final SignalProtocolEncryptionService? _signalProtocol;
  final AtomicClockService _atomicClock;

  AI2AIOutreachCommunicationService({
    required AnonymousCommunicationProtocol ai2aiProtocol,
    HybridEncryptionService? hybridEncryption,
    SignalProtocolEncryptionService? signalProtocol,
    required AtomicClockService atomicClock,
  })  : _ai2aiProtocol = ai2aiProtocol,
        _hybridEncryption = hybridEncryption,
        _signalProtocol = signalProtocol,
        _atomicClock = atomicClock;

  /// Send outreach message via AI2AI network with Signal Protocol encryption
  ///
  /// **Flow:**
  /// 1. Create anonymous payload (no user data)
  /// 2. Encrypt using Signal Protocol (via HybridEncryptionService)
  /// 3. Route through AnonymousCommunicationProtocol
  /// 4. Return result
  ///
  /// **Parameters:**
  /// - `fromAgentId`: Sender's agent ID
  /// - `toAgentId`: Recipient's agent ID
  /// - `messageType`: Type of outreach message
  /// - `payload`: Message payload (must be anonymous, no user data)
  Future<OutreachMessageResult> sendOutreachMessage({
    required String fromAgentId,
    required String toAgentId,
    required OutreachMessageType messageType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      developer.log(
        'Sending AI2AI outreach message: ${messageType.name} from ${fromAgentId.substring(0, 10)}... to ${toAgentId.substring(0, 10)}...',
        name: _logName,
      );

      // 1. Validate payload is anonymous (no user data)
      await _validateAnonymousPayload(payload);

      // 2. Create anonymous payload with message metadata
      final anonymousPayload = {
        ...payload,
        'message_type': messageType.name,
        'from_agent_id': fromAgentId,
        'timestamp': (await _atomicClock.getAtomicTimestamp())
            .serverTime
            .toIso8601String(),
      };

      // 3. Determine MessageType for AnonymousCommunicationProtocol
      final protocolMessageType = _mapToProtocolMessageType(messageType);

      // 4. Send via AnonymousCommunicationProtocol (uses Signal Protocol internally)
      final message = await _ai2aiProtocol.sendEncryptedMessage(
        toAgentId,
        protocolMessageType,
        anonymousPayload,
      );

      // 5. Determine encryption type used
      final encryptionType = await _getEncryptionTypeUsed();

      developer.log(
        '✅ AI2AI outreach message sent successfully: ${message.messageId}, '
        'encryption=${encryptionType.name}',
        name: _logName,
      );

      return OutreachMessageResult(
        success: true,
        messageId: message.messageId,
        timestamp: message.timestamp,
        encryptionType: encryptionType,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to send AI2AI outreach message: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );

      return OutreachMessageResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
        encryptionType: EncryptionType.aes256gcm, // Fallback
      );
    }
  }

  /// Send batch outreach messages
  ///
  /// Sends multiple outreach messages efficiently.
  Future<List<OutreachMessageResult>> sendBatchOutreachMessages({
    required String fromAgentId,
    required List<OutreachBatchItem> messages,
  }) async {
    final results = <OutreachMessageResult>[];

    for (final item in messages) {
      final result = await sendOutreachMessage(
        fromAgentId: fromAgentId,
        toAgentId: item.toAgentId,
        messageType: item.messageType,
        payload: item.payload,
      );
      results.add(result);
    }

    final successCount = results.where((r) => r.success).length;
    developer.log(
      'Batch outreach complete: $successCount/${results.length} successful',
      name: _logName,
    );

    return results;
  }

  /// Check if Signal Protocol is available and initialized
  bool get isSignalProtocolAvailable {
    if (_signalProtocol != null) {
      return _signalProtocol.isInitialized;
    }
    if (_hybridEncryption != null) {
      // HybridEncryptionService will try Signal Protocol first
      return true;
    }
    return false;
  }

  /// Get encryption type that will be used
  Future<EncryptionType> _getEncryptionTypeUsed() async {
    // Check if Signal Protocol is available
    if (_signalProtocol != null && _signalProtocol.isInitialized) {
      return EncryptionType.signalProtocol;
    }

    // HybridEncryptionService will try Signal Protocol first
    if (_hybridEncryption != null &&
        _hybridEncryption.isSignalProtocolAvailable) {
      return EncryptionType.signalProtocol;
    }

    // Fallback to AES-256-GCM
    return EncryptionType.aes256gcm;
  }

  /// Validate payload is anonymous (no user data)
  Future<void> _validateAnonymousPayload(Map<String, dynamic> payload) async {
    // Check for common user data fields
    final forbiddenFields = [
      'user_id',
      'email',
      'phone',
      'name',
      'address',
      'personal_data',
      'user_profile',
    ];

    for (final field in forbiddenFields) {
      if (payload.containsKey(field)) {
        throw ArgumentError(
          'Payload contains forbidden user data field: $field. '
          'Outreach messages must be anonymous.',
        );
      }
    }

    // Validate payload structure
    if (payload.isEmpty) {
      throw ArgumentError('Payload cannot be empty');
    }
  }

  /// Map OutreachMessageType to AnonymousCommunicationProtocol MessageType
  MessageType _mapToProtocolMessageType(OutreachMessageType outreachType) {
    switch (outreachType) {
      case OutreachMessageType.communityInvitation:
      case OutreachMessageType.groupFormation:
      case OutreachMessageType.clubMembershipInvitation:
        return MessageType.discoverySync;

      case OutreachMessageType.eventCall:
      case OutreachMessageType.spotRecommendation:
      case OutreachMessageType.friendSuggestion:
      case OutreachMessageType.listSuggestion:
        return MessageType.recommendationShare;

      case OutreachMessageType.businessEventInvitation:
      case OutreachMessageType.businessExpertPartnership:
      case OutreachMessageType.businessBusinessPartnership:
      case OutreachMessageType.expertLearningOpportunity:
      case OutreachMessageType.expertBusinessPartnership:
      case OutreachMessageType.expertCuratedList:
        return MessageType.trustVerification;

      case OutreachMessageType.clubEventInvitation:
        return MessageType.reputationUpdate;
    }
  }
}

/// Batch outreach message item
class OutreachBatchItem {
  final String toAgentId;
  final OutreachMessageType messageType;
  final Map<String, dynamic> payload;

  OutreachBatchItem({
    required this.toAgentId,
    required this.messageType,
    required this.payload,
  });
}
