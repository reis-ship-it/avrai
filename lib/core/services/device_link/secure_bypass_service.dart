import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/core/crypto/signal/device_registration_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/device_link/auto_device_link_service.dart';

/// Secure Bypass Service
///
/// Handles device linking when the old device is unavailable
/// (lost, stolen, or broken).
///
/// Phase 26: Multi-Device Sync - Secure Bypass
///
/// **Security Flow:**
/// 1. User re-authenticates with password
/// 2. Optional: Email/SMS verification code
/// 3. All existing device sessions are revoked
/// 4. New device becomes primary
/// 5. Previous devices cannot decrypt new messages
/// 6. Optional: Remote wipe trigger for old devices
///
/// **Important:** This is a high-security operation that requires
/// explicit user consent and additional verification.
class SecureBypassService {
  static const String _logName = 'SecureBypassService';
  static const String _linkRequestsTable = 'device_link_requests';
  static const String _bypassAuditTable = 'device_bypass_audit';

  final SupabaseService _supabaseService;
  final DeviceRegistrationService _deviceRegistrationService;

  SecureBypassService({
    required SupabaseService supabaseService,
    required DeviceRegistrationService deviceRegistrationService,
  })  : _supabaseService = supabaseService,
        _deviceRegistrationService = deviceRegistrationService;

  /// Initiate secure bypass flow
  ///
  /// Creates a bypass request that requires password re-authentication.
  Future<BypassRequest> initiateBypass({
    required String userId,
    required String reason,
  }) async {
    final currentDevice = _deviceRegistrationService.currentDevice;
    if (currentDevice == null) {
      throw StateError('Current device not registered');
    }

    // Generate bypass token
    final bypassToken = _generateBypassToken();
    final tokenHash = _hashToken(bypassToken);

    // Create bypass request
    final response = await _supabaseService.client
        .from(_linkRequestsTable)
        .insert({
          'user_id': userId,
          'requesting_device_id': currentDevice.deviceIdString,
          'approving_device_id': null,
          'link_method': LinkMethod.secureBypass.name,
          'code_hash': tokenHash,
          'status': LinkRequestStatus.pending.name,
          'created_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        })
        .select()
        .single();

    // Log audit event
    await _logBypassAudit(
      userId: userId,
      deviceId: currentDevice.deviceIdString,
      action: 'initiated',
      reason: reason,
    );

    developer.log('Initiated secure bypass: ${response['request_id']}', name: _logName);

    return BypassRequest(
      requestId: response['request_id'] as String,
      userId: userId,
      bypassToken: bypassToken,
      status: BypassStatus.pendingPasswordVerification,
      createdAt: DateTime.now(),
    );
  }

  /// Verify password for secure bypass
  ///
  /// Re-authenticates the user to confirm identity.
  Future<bool> verifyPassword({
    required String email,
    required String password,
    required String bypassRequestId,
  }) async {
    try {
      // Attempt to sign in with provided credentials
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        developer.log('Password verification failed', name: _logName);
        return false;
      }

      // Update bypass request status
      await _supabaseService.client.from(_linkRequestsTable).update({
        'status': 'password_verified',
      }).eq('request_id', bypassRequestId);

      await _logBypassAudit(
        userId: response.user!.id,
        deviceId: _deviceRegistrationService.currentDevice?.deviceIdString ?? '',
        action: 'password_verified',
        reason: null,
      );

      developer.log('Password verified for bypass', name: _logName);
      return true;
    } catch (e) {
      developer.log('Password verification error: $e', name: _logName);
      return false;
    }
  }

  /// Request email verification code (optional extra security)
  Future<bool> requestEmailVerification(String email) async {
    try {
      // Send OTP to email
      await _supabaseService.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      developer.log('Email verification code sent', name: _logName);
      return true;
    } catch (e) {
      developer.log('Failed to send email verification: $e', name: _logName);
      return false;
    }
  }

  /// Verify email OTP code
  Future<bool> verifyEmailCode({
    required String email,
    required String code,
    required String bypassRequestId,
  }) async {
    try {
      final response = await _supabaseService.client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );

      if (response.user == null) {
        return false;
      }

      // Update bypass request
      await _supabaseService.client.from(_linkRequestsTable).update({
        'status': 'email_verified',
      }).eq('request_id', bypassRequestId);

      developer.log('Email code verified for bypass', name: _logName);
      return true;
    } catch (e) {
      developer.log('Email verification failed: $e', name: _logName);
      return false;
    }
  }

  /// Complete secure bypass (revokes all other devices)
  ///
  /// This is the final step that revokes all existing devices
  /// and makes the current device the primary.
  Future<BypassResult> completeBypass({
    required String bypassRequestId,
    required bool revokeOtherDevices,
    required bool triggerRemoteWipe,
  }) async {
    try {
      final currentDevice = _deviceRegistrationService.currentDevice;
      if (currentDevice == null) {
        throw StateError('Current device not registered');
      }

      // Get list of devices to revoke
      final otherDevices = _deviceRegistrationService.getOtherDevices();
      final revokedDeviceIds = <String>[];

      if (revokeOtherDevices) {
        for (final device in otherDevices) {
          await _deviceRegistrationService.revokeDevice(device.deviceId);
          revokedDeviceIds.add(device.deviceIdString);

          if (triggerRemoteWipe && device.pushToken != null) {
            await _triggerRemoteWipe(device);
          }
        }
      }

      // Mark bypass request as complete
      await _supabaseService.client.from(_linkRequestsTable).update({
        'status': LinkRequestStatus.approved.name,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('request_id', bypassRequestId);

      // Update current device as primary
      await _supabaseService.client.from('user_devices').update({
        'is_primary': true,
      }).eq('device_id', currentDevice.deviceIdString);

      // Log audit
      await _logBypassAudit(
        userId: currentDevice.userId ?? '',
        deviceId: currentDevice.deviceIdString,
        action: 'completed',
        reason: 'Revoked ${revokedDeviceIds.length} devices',
        metadata: {
          'revoked_devices': revokedDeviceIds,
          'remote_wipe': triggerRemoteWipe,
        },
      );

      developer.log(
        'Secure bypass complete: revoked ${revokedDeviceIds.length} devices',
        name: _logName,
      );

      return BypassResult(
        success: true,
        revokedDeviceCount: revokedDeviceIds.length,
        revokedDeviceIds: revokedDeviceIds,
        remoteWipeTriggered: triggerRemoteWipe,
      );
    } catch (e) {
      developer.log('Failed to complete bypass: $e', name: _logName);
      return BypassResult(
        success: false,
        revokedDeviceCount: 0,
        revokedDeviceIds: [],
        remoteWipeTriggered: false,
        error: e.toString(),
      );
    }
  }

  /// Trigger remote wipe for a device
  Future<void> _triggerRemoteWipe(RegisteredDevice device) async {
    try {
      await _supabaseService.client.functions.invoke(
        'trigger-remote-wipe',
        body: {
          'device_id': device.deviceIdString,
          'push_token': device.pushToken,
          'user_id': device.userId ?? '',
        },
      );

      developer.log('Remote wipe triggered for: ${device.deviceIdString}', name: _logName);
    } catch (e) {
      developer.log('Failed to trigger remote wipe: $e', name: _logName);
    }
  }

  /// Log bypass audit event
  Future<void> _logBypassAudit({
    required String userId,
    required String deviceId,
    required String action,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabaseService.client.from(_bypassAuditTable).insert({
        'user_id': userId,
        'device_id': deviceId,
        'action': action,
        'reason': reason,
        'metadata': metadata != null ? jsonEncode(metadata) : null,
        'ip_address': null, // Could get from request headers
        'user_agent': null,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Audit logging should not fail the main operation
      developer.log('Failed to log bypass audit: $e', name: _logName);
    }
  }

  String _generateBypassToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return sha256.convert(utf8.encode('bypass_$timestamp')).toString();
  }

  String _hashToken(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }
}

/// Bypass request status
enum BypassStatus {
  pendingPasswordVerification,
  passwordVerified,
  pendingEmailVerification,
  emailVerified,
  completed,
  cancelled,
}

/// Bypass request model
class BypassRequest {
  final String requestId;
  final String userId;
  final String bypassToken;
  final BypassStatus status;
  final DateTime createdAt;

  BypassRequest({
    required this.requestId,
    required this.userId,
    required this.bypassToken,
    required this.status,
    required this.createdAt,
  });
}

/// Bypass completion result
class BypassResult {
  final bool success;
  final int revokedDeviceCount;
  final List<String> revokedDeviceIds;
  final bool remoteWipeTriggered;
  final String? error;

  BypassResult({
    required this.success,
    required this.revokedDeviceCount,
    required this.revokedDeviceIds,
    required this.remoteWipeTriggered,
    this.error,
  });
}
