import 'dart:developer' as developer;

import 'package:avrai/core/crypto/signal/device_registration_service.dart';
import 'package:avrai/core/services/chat/dm_message_store.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai_network/avra_network.dart';

/// Multi-Device Message Service
///
/// Handles encrypting and distributing messages to ALL recipient devices.
/// Each device receives its own encrypted blob that only it can decrypt.
///
/// Phase 26: Multi-Device Sync - Multi-Device Message Delivery
///
/// **Flow:**
/// 1. Sender calls encryptForAllDevices()
/// 2. Service fetches recipient's device list
/// 3. Encrypts message separately for each device's Signal keys
/// 4. Stores device-specific blobs in Supabase
/// 5. Sends single Realtime notification
/// 6. All recipient devices fetch their specific blob
class MultiDeviceMessageService {
  static const String _logName = 'MultiDeviceMessageService';
  static const String _dmMailboxChannelPrefix = 'dm_mailbox:';

  final DeviceRegistrationService _deviceRegistrationService;
  final MessageEncryptionService _encryptionService;
  final DmMessageStore _dmStore;
  final RealtimeBackend _realtimeBackend;
  // ignore: unused_field - Phase 26: device-specific blob storage in Supabase
  final SupabaseService _supabaseService;

  MultiDeviceMessageService({
    required DeviceRegistrationService deviceRegistrationService,
    required MessageEncryptionService encryptionService,
    required DmMessageStore dmStore,
    required RealtimeBackend realtimeBackend,
    required SupabaseService supabaseService,
  })  : _deviceRegistrationService = deviceRegistrationService,
        _encryptionService = encryptionService,
        _dmStore = dmStore,
        _realtimeBackend = realtimeBackend,
        _supabaseService = supabaseService;

  /// Encrypt and send a message to ALL of recipient's devices
  ///
  /// Returns the number of devices the message was sent to.
  Future<MultiDeviceSendResult> sendToAllDevices({
    required String senderUserId,
    required String recipientUserId,
    required String messageId,
    required String message,
    required DateTime timestamp,
  }) async {
    try {
      // Get all active devices for the recipient
      final recipientDevices = await _getRecipientDevices(recipientUserId);

      if (recipientDevices.isEmpty) {
        developer.log(
          'No active devices for recipient: $recipientUserId',
          name: _logName,
        );
        // Fall back to legacy single-device send
        return await _sendToSingleDevice(
          senderUserId: senderUserId,
          recipientUserId: recipientUserId,
          messageId: messageId,
          message: message,
          timestamp: timestamp,
        );
      }

      developer.log(
        'Encrypting message for ${recipientDevices.length} devices',
        name: _logName,
      );

      final successfulDevices = <String>[];
      final failedDevices = <String, String>{};

      // Encrypt and store for each device
      for (final device in recipientDevices) {
        try {
          await _encryptAndStoreForDevice(
            senderUserId: senderUserId,
            recipientUserId: recipientUserId,
            recipientDeviceId: device.deviceIdString,
            recipientDeviceIntId: device.deviceIntId,
            messageId: messageId,
            message: message,
            timestamp: timestamp,
          );
          successfulDevices.add(device.deviceIdString);
        } catch (e) {
          developer.log(
            'Failed to encrypt for device ${device.deviceId}: $e',
            name: _logName,
          );
          failedDevices[device.deviceIdString] = e.toString();
        }
      }

      if (successfulDevices.isEmpty) {
        throw Exception('Failed to encrypt for any recipient device');
      }

      // Send single notification to recipient's inbox
      await _notifyRecipient(
        recipientUserId: recipientUserId,
        messageId: messageId,
      );

      developer.log(
        'Message sent to ${successfulDevices.length}/${recipientDevices.length} devices',
        name: _logName,
      );

      return MultiDeviceSendResult(
        messageId: messageId,
        totalDevices: recipientDevices.length,
        successfulDevices: successfulDevices,
        failedDevices: failedDevices,
      );
    } catch (e, st) {
      developer.log(
        'Multi-device send failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Get all active devices for a user
  Future<List<RegisteredDevice>> _getRecipientDevices(String userId) async {
    try {
      // Load devices from cloud if not already loaded
      final devices = await _deviceRegistrationService.loadDevicesFromCloud(userId);
      return devices.where((d) => d.status == DeviceStatus.active).toList();
    } catch (e) {
      developer.log('Failed to get recipient devices: $e', name: _logName);
      return [];
    }
  }

  /// Encrypt and store message for a specific device
  Future<void> _encryptAndStoreForDevice({
    required String senderUserId,
    required String recipientUserId,
    required String recipientDeviceId,
    required int recipientDeviceIntId,
    required String messageId,
    required String message,
    required DateTime timestamp,
  }) async {
    // Create device-specific transport address
    // Signal Protocol uses (userId, deviceId) tuple
    final deviceAddress = '$recipientUserId:$recipientDeviceIntId';

    // Encrypt using Signal Protocol for this specific device
    final encrypted = await _encryptionService.encrypt(message, deviceAddress);

    if (encrypted.encryptionType != EncryptionType.signalProtocol) {
      throw Exception(
        'Signal Protocol required for multi-device. Got ${encrypted.encryptionType.name}',
      );
    }

    // TODO(Phase 26): Implement device-specific blob storage
    // Currently falling back to standard putDmBlob
    // TODO: Obtain proper agent IDs from AgentIdService
    await _dmStore.putDmBlob(
      messageId: messageId,
      fromUserId: senderUserId,
      toUserId: recipientUserId,
      senderAgentId: senderUserId, // Fallback to userId for now
      recipientAgentId: recipientUserId, // Fallback to userId for now
      encrypted: encrypted,
      sentAt: timestamp,
    );
  }

  /// Legacy fallback for users without device registration
  Future<MultiDeviceSendResult> _sendToSingleDevice({
    required String senderUserId,
    required String recipientUserId,
    required String messageId,
    required String message,
    required DateTime timestamp,
  }) async {
    final encrypted = await _encryptionService.encrypt(message, recipientUserId);

    // TODO: Obtain proper agent IDs from AgentIdService
    await _dmStore.putDmBlob(
      messageId: messageId,
      fromUserId: senderUserId,
      toUserId: recipientUserId,
      senderAgentId: senderUserId, // Fallback to userId for now
      recipientAgentId: recipientUserId, // Fallback to userId for now
      encrypted: encrypted,
      sentAt: timestamp,
    );

    await _notifyRecipient(
      recipientUserId: recipientUserId,
      messageId: messageId,
    );

    return MultiDeviceSendResult(
      messageId: messageId,
      totalDevices: 1,
      successfulDevices: ['legacy'],
      failedDevices: {},
    );
  }

  /// Send notification to recipient's inbox channel
  Future<void> _notifyRecipient({
    required String recipientUserId,
    required String messageId,
  }) async {
    final channel = '$_dmMailboxChannelPrefix$recipientUserId';

    await _realtimeBackend.sendMessage(
      channel,
      RealtimeMessage(
        id: messageId,
        senderId: '', // System notification
        content: messageId, // Payloadless: just the ID
        type: 'dm_notification',
        timestamp: DateTime.now(),
      ),
    );

    developer.log('Notified recipient inbox: $channel', name: _logName);
  }

  /// Fetch and decrypt message for current device
  ///
  /// Call this when receiving a notification. Fetches the device-specific
  /// blob and decrypts it.
  Future<DecryptedMessage?> fetchAndDecryptForDevice({
    required String messageId,
    required String currentUserId,
  }) async {
    final currentDevice = _deviceRegistrationService.currentDevice;
    if (currentDevice == null) {
      developer.log('Current device not registered', name: _logName);
      return null;
    }

    try {
      // TODO(Phase 26): Implement device-specific blob fetch
      // Currently falling back to standard getDmBlob
      final blob = await _dmStore.getDmBlob(messageId);

      if (blob != null) {
        final plaintext = await _encryptionService.decrypt(
          blob.toEncryptedMessage(),
          blob.fromUserId,
        );

        return DecryptedMessage(
          messageId: messageId,
          senderId: blob.fromUserId,
          recipientId: blob.toUserId,
          content: plaintext,
          timestamp: blob.sentAt,
        );
      }

      // Fall back to legacy single blob
      final legacyBlob = await _dmStore.getDmBlob(messageId);
      if (legacyBlob != null && legacyBlob.toUserId == currentUserId) {
        final plaintext = await _encryptionService.decrypt(
          legacyBlob.toEncryptedMessage(),
          legacyBlob.fromUserId,
        );

        return DecryptedMessage(
          messageId: messageId,
          senderId: legacyBlob.fromUserId,
          recipientId: legacyBlob.toUserId,
          content: plaintext,
          timestamp: legacyBlob.sentAt,
        );
      }

      developer.log('No blob found for message: $messageId', name: _logName);
      return null;
    } catch (e, st) {
      developer.log(
        'Failed to fetch/decrypt message: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}

/// Result of multi-device send operation
class MultiDeviceSendResult {
  final String messageId;
  final int totalDevices;
  final List<String> successfulDevices;
  final Map<String, String> failedDevices;

  MultiDeviceSendResult({
    required this.messageId,
    required this.totalDevices,
    required this.successfulDevices,
    required this.failedDevices,
  });

  bool get allSucceeded => failedDevices.isEmpty;
  int get successCount => successfulDevices.length;
  int get failCount => failedDevices.length;
}

/// Decrypted message from multi-device fetch
class DecryptedMessage {
  final String messageId;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime timestamp;

  DecryptedMessage({
    required this.messageId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
  });
}
