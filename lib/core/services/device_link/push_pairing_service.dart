import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/core/crypto/signal/device_registration_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/device_link/auto_device_link_service.dart';

/// Push Pairing Service
///
/// Handles device pairing via push notifications.
/// New device sends request, existing devices receive push to approve.
///
/// Phase 26: Multi-Device Sync - Push Notification Pairing
///
/// **Flow:**
/// 1. New device requests link via Supabase
/// 2. Service sends FCM/APNs push to all existing devices
/// 3. User taps notification to approve
/// 4. Approval triggers link establishment
/// 5. History transfer begins
class PushPairingService {
  static const String _logName = 'PushPairingService';
  static const String _linkRequestsTable = 'device_link_requests';
  static const Duration _requestExpiry = Duration(minutes: 10);

  final SupabaseService _supabaseService;
  final DeviceRegistrationService _deviceRegistrationService;

  // Callback for push notifications
  void Function(DeviceLinkRequest)? onPushApprovalRequested;

  PushPairingService({
    required SupabaseService supabaseService,
    required DeviceRegistrationService deviceRegistrationService,
  })  : _supabaseService = supabaseService,
        _deviceRegistrationService = deviceRegistrationService;

  /// Request pairing via push notification (on new device)
  ///
  /// Sends a push to all existing devices requesting approval.
  Future<DeviceLinkRequest> requestPushPairing({
    required String userId,
    required String newDeviceName,
  }) async {
    final currentDevice = _deviceRegistrationService.currentDevice;
    if (currentDevice == null) {
      throw StateError('Current device not registered');
    }

    // Generate ephemeral key for secure channel
    final keyPair = _generateEphemeralKeyPair();
    final publicKeyBase64 = base64Encode(keyPair.publicKey);

    final request = DeviceLinkRequest(
      requestId: '', // Assigned by Supabase
      userId: userId,
      requestingDeviceId: currentDevice.deviceIdString,
      approvingDeviceId: null, // Any device can approve
      linkMethod: LinkMethod.pushApproval,
      ephemeralPublicKey: publicKeyBase64,
      status: LinkRequestStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_requestExpiry),
    );

    // Store request in Supabase (triggers push notification via Edge Function)
    final response = await _supabaseService.client
        .from(_linkRequestsTable)
        .insert(request.toJson())
        .select()
        .single();

    final createdRequest = DeviceLinkRequest.fromJson(response);

    // Trigger push notification to all user's devices
    await _sendPushToAllDevices(
      userId: userId,
      requestId: createdRequest.requestId,
      newDeviceName: newDeviceName,
    );

    developer.log(
      'Push pairing request created: ${createdRequest.requestId}',
      name: _logName,
    );

    return createdRequest;
  }

  /// Send push notification to all existing devices
  Future<void> _sendPushToAllDevices({
    required String userId,
    required String requestId,
    required String newDeviceName,
  }) async {
    try {
      // Get all devices with push tokens
      final devices = _deviceRegistrationService.getActiveDevices();
      final currentDeviceId = _deviceRegistrationService.currentDevice?.deviceId;

      final devicesWithTokens = devices
          .where((d) =>
              d.deviceId != currentDeviceId &&

              d.pushToken != null &&
              d.pushToken!.isNotEmpty)
          .toList();

      if (devicesWithTokens.isEmpty) {
        developer.log('No devices with push tokens found', name: _logName);
        return;
      }

      // Call Supabase Edge Function to send push
      await _supabaseService.client.functions.invoke(
        'send-device-link-push',
        body: {
          'user_id': userId,
          'request_id': requestId,
          'new_device_name': newDeviceName,
          'push_tokens': devicesWithTokens.map((d) => d.pushToken).toList(),
        },
      );

      developer.log(
        'Push sent to ${devicesWithTokens.length} devices',
        name: _logName,
      );
    } catch (e) {
      developer.log('Failed to send push notifications: $e', name: _logName);
    }
  }

  /// Handle push notification tap (on existing device)
  ///
  /// Call this when user taps the device pairing notification.
  Future<DeviceLinkRequest?> handlePushNotificationTap(
    String requestId,
  ) async {
    try {
      final response = await _supabaseService.client
          .from(_linkRequestsTable)
          .select()
          .eq('request_id', requestId)
          .eq('status', LinkRequestStatus.pending.name)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response == null) {
        developer.log('Push request not found or expired', name: _logName);
        return null;
      }

      return DeviceLinkRequest.fromJson(response);
    } catch (e) {
      developer.log('Failed to handle push tap: $e', name: _logName);
      return null;
    }
  }

  /// Approve push pairing request (on existing device)
  Future<SharedLinkSecret?> approvePushRequest(
    DeviceLinkRequest request,
  ) async {
    try {
      final currentDevice = _deviceRegistrationService.currentDevice;
      if (currentDevice == null) {
        throw StateError('Current device not registered');
      }

      // Generate our ephemeral key
      final keyPair = _generateEphemeralKeyPair();
      final publicKeyBase64 = base64Encode(keyPair.publicKey);

      // Compute shared secret
      final theirPublicKey = base64Decode(request.ephemeralPublicKey!);
      final sharedSecret = _computeSharedSecret(
        keyPair.privateKey,
        theirPublicKey,
      );

      // Update request
      await _supabaseService.client.from(_linkRequestsTable).update({
        'approving_device_id': currentDevice.deviceIdString,
        'ephemeral_public_key': publicKeyBase64,
        'status': LinkRequestStatus.approved.name,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('request_id', request.requestId);

      developer.log(
        'Approved push pairing: ${request.requestId}',
        name: _logName,
      );

      return SharedLinkSecret(
        requestId: request.requestId,
        sharedSecret: sharedSecret,
        isInitiator: false,
      );
    } catch (e) {
      developer.log('Failed to approve push request: $e', name: _logName);
      return null;
    }
  }

  /// Reject push pairing request
  Future<void> rejectPushRequest(String requestId) async {
    try {
      await _supabaseService.client.from(_linkRequestsTable).update({
        'status': LinkRequestStatus.rejected.name,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('request_id', requestId);

      developer.log('Rejected push pairing: $requestId', name: _logName);
    } catch (e) {
      developer.log('Failed to reject push request: $e', name: _logName);
    }
  }

  /// Wait for push approval (on new device)
  Future<SharedLinkSecret?> waitForPushApproval(
    DeviceLinkRequest request,
    Uint8List privateKey, {
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final completer = Completer<SharedLinkSecret?>();

    final subscription = _supabaseService.client
        .channel('push_request:${request.requestId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: _linkRequestsTable,
          callback: (payload) {
            final updatedRequest = DeviceLinkRequest.fromJson(
              payload.newRecord,
            );

            if (updatedRequest.status == LinkRequestStatus.approved) {
              final theirPublicKey = base64Decode(
                updatedRequest.ephemeralPublicKey!,
              );
              final sharedSecret = _computeSharedSecret(
                privateKey,
                theirPublicKey,
              );

              completer.complete(SharedLinkSecret(
                requestId: request.requestId,
                sharedSecret: sharedSecret,
                isInitiator: true,
              ));
            } else if (updatedRequest.status == LinkRequestStatus.rejected) {
              completer.complete(null);
            }
          },
        )
        .subscribe();

    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    try {
      return await completer.future;
    } finally {
      await subscription.unsubscribe();
    }
  }

  // Crypto helpers

  _EphemeralKeyPair _generateEphemeralKeyPair() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final privateKey = Uint8List.fromList(
      sha256.convert(utf8.encode('private_$random')).bytes,
    );
    final publicKey = Uint8List.fromList(
      sha256.convert(privateKey).bytes,
    );
    return _EphemeralKeyPair(publicKey: publicKey, privateKey: privateKey);
  }

  Uint8List _computeSharedSecret(Uint8List privateKey, Uint8List publicKey) {
    final combined = Uint8List.fromList([...privateKey, ...publicKey]);
    return Uint8List.fromList(sha256.convert(combined).bytes);
  }
}

class _EphemeralKeyPair {
  final Uint8List publicKey;
  final Uint8List privateKey;

  _EphemeralKeyPair({required this.publicKey, required this.privateKey});
}
