import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/core/crypto/signal/device_registration_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/device_link/auto_device_link_service.dart';

/// Numeric Code Service
///
/// Handles device pairing using 9-digit numeric codes.
/// Alternative to same-account login for devices without shared login.
///
/// Phase 26: Multi-Device Sync - Numeric Code Pairing
///
/// **Flow (Existing Device):**
/// 1. User requests pairing code
/// 2. Service generates 9-digit cryptographic random code
/// 3. Displays code with 5-minute expiry countdown
/// 4. Stores code hash in Supabase
///
/// **Flow (New Device):**
/// 1. User enters 9-digit code
/// 2. Service verifies code against Supabase
/// 3. Establishes secure channel
/// 4. Initiates history transfer
class NumericCodeService {
  static const String _logName = 'NumericCodeService';
  static const String _linkRequestsTable = 'device_link_requests';
  static const Duration _codeExpiry = Duration(minutes: 5);
  static const int _codeLength = 9;

  final SupabaseService _supabaseService;
  final DeviceRegistrationService _deviceRegistrationService;

  // Current active code (on device displaying it)
  String? _activeCode;
  DateTime? _codeExpiresAt;
  String? _activeRequestId;

  NumericCodeService({
    required SupabaseService supabaseService,
    required DeviceRegistrationService deviceRegistrationService,
  })  : _supabaseService = supabaseService,
        _deviceRegistrationService = deviceRegistrationService;

  /// Generate a new pairing code (on existing device)
  ///
  /// Returns the 9-digit code to display to the user.
  /// Code expires after 5 minutes.
  Future<PairingCode> generateCode() async {
    // Generate cryptographically random 9-digit code
    final code = _generateSecureCode();
    final codeHash = _hashCode(code);
    final expiresAt = DateTime.now().add(_codeExpiry);

    final currentDevice = _deviceRegistrationService.currentDevice;
    if (currentDevice == null) {
      throw StateError('Current device not registered');
    }

    // Store hash in Supabase
    final response = await _supabaseService.client
        .from(_linkRequestsTable)
        .insert({
          'user_id': currentDevice.userId,
          'requesting_device_id': '', // Will be filled by new device
          'approving_device_id': currentDevice.deviceId,
          'link_method': LinkMethod.numericCode.name,
          'code_hash': codeHash,
          'status': LinkRequestStatus.pending.name,
          'created_at': DateTime.now().toIso8601String(),
          'expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();

    _activeCode = code;
    _codeExpiresAt = expiresAt;
    _activeRequestId = response['request_id'] as String;

    developer.log(
      'Generated pairing code (expires in 5 min)',
      name: _logName,
    );

    return PairingCode(
      code: code,
      formattedCode: _formatCode(code),
      expiresAt: expiresAt,
      requestId: _activeRequestId!,
    );
  }

  /// Verify a pairing code (on new device)
  ///
  /// Returns the link request if code is valid, null otherwise.
  Future<DeviceLinkRequest?> verifyCode(String code) async {
    // Remove any formatting
    final cleanCode = code.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanCode.length != _codeLength) {
      developer.log('Invalid code length: ${cleanCode.length}', name: _logName);
      return null;
    }

    final codeHash = _hashCode(cleanCode);

    try {
      // Find matching unexpired request
      final response = await _supabaseService.client
          .from(_linkRequestsTable)
          .select()
          .eq('code_hash', codeHash)
          .eq('status', LinkRequestStatus.pending.name)
          .gt('expires_at', DateTime.now().toIso8601String())
          .limit(1)
          .maybeSingle();

      if (response == null) {
        developer.log('No matching code found', name: _logName);
        return null;
      }

      final request = DeviceLinkRequest.fromJson(response);

      developer.log(
        'Code verified successfully: ${request.requestId}',
        name: _logName,
      );

      return request;
    } catch (e) {
      developer.log('Failed to verify code: $e', name: _logName);
      return null;
    }
  }

  /// Complete pairing after code verification (on new device)
  ///
  /// Updates the request with new device info and generates shared secret.
  Future<SharedLinkSecret?> completePairing(DeviceLinkRequest request) async {
    final currentDevice = _deviceRegistrationService.currentDevice;
    if (currentDevice == null) {
      throw StateError('Current device not registered');
    }

    try {
      // Generate ephemeral key for secure channel
      final keyPair = _generateEphemeralKeyPair();
      final publicKeyBase64 = base64Encode(keyPair.publicKey);

      // Update request with new device info
      await _supabaseService.client
          .from(_linkRequestsTable)
          .update({
            'requesting_device_id': currentDevice.deviceId,
            'ephemeral_public_key': publicKeyBase64,
            'status': LinkRequestStatus.approved.name,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('request_id', request.requestId)
          .select()
          .single();

      // The approving device will respond with their public key
      // For now, derive shared secret from code + our key
      final sharedSecret = _deriveSharedSecret(
        request.codeHash!,
        keyPair.privateKey,
      );

      developer.log('Pairing completed: ${request.requestId}', name: _logName);

      return SharedLinkSecret(
        requestId: request.requestId,
        sharedSecret: sharedSecret,
        isInitiator: true,
      );
    } catch (e) {
      developer.log('Failed to complete pairing: $e', name: _logName);
      return null;
    }
  }

  /// Wait for code to be used (on existing device)
  ///
  /// Returns the shared secret when pairing completes.
  Future<SharedLinkSecret?> waitForCodeUsage({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    if (_activeRequestId == null) {
      return null;
    }

    final completer = Completer<SharedLinkSecret?>();

    // Subscribe to updates for this request
    final subscription = _supabaseService.client
        .channel('code_request:$_activeRequestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: _linkRequestsTable,
          callback: (payload) {
            final updatedRequest = DeviceLinkRequest.fromJson(
              payload.newRecord,
            );

            if (updatedRequest.status == LinkRequestStatus.approved &&
                updatedRequest.ephemeralPublicKey != null) {
              // Derive shared secret
              final theirPublicKey = base64Decode(
                updatedRequest.ephemeralPublicKey!,
              );
              final sharedSecret = _deriveSharedSecret(
                _hashCode(_activeCode!),
                theirPublicKey,
              );

              completer.complete(SharedLinkSecret(
                requestId: _activeRequestId!,
                sharedSecret: sharedSecret,
                isInitiator: false,
              ));
            }
          },
        )
        .subscribe();

    // Set timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    try {
      return await completer.future;
    } finally {
      await subscription.unsubscribe();
      _activeCode = null;
      _codeExpiresAt = null;
      _activeRequestId = null;
    }
  }

  /// Cancel active code
  Future<void> cancelCode() async {
    if (_activeRequestId != null) {
      try {
        await _supabaseService.client.from(_linkRequestsTable).update({
          'status': LinkRequestStatus.expired.name,
        }).eq('request_id', _activeRequestId!);
      } catch (_) {}

      _activeCode = null;
      _codeExpiresAt = null;
      _activeRequestId = null;
    }
  }

  /// Get remaining time for active code
  Duration? get remainingTime {
    if (_codeExpiresAt == null) return null;
    final remaining = _codeExpiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if code is still valid
  bool get isCodeValid {
    if (_activeCode == null || _codeExpiresAt == null) return false;
    return DateTime.now().isBefore(_codeExpiresAt!);
  }

  // Helper methods

  String _generateSecureCode() {
    final random = Random.secure();
    final digits = List.generate(_codeLength, (_) => random.nextInt(10));
    return digits.join();
  }

  String _hashCode(String code) {
    final bytes = utf8.encode(code);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  String _formatCode(String code) {
    // Format as XXX-XXX-XXX for readability
    if (code.length != _codeLength) return code;
    return '${code.substring(0, 3)}-${code.substring(3, 6)}-${code.substring(6, 9)}';
  }

  _EphemeralKeyPair _generateEphemeralKeyPair() {
    // Generate random key pair
    final random = Random.secure();
    final privateKey = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    final publicKey = Uint8List.fromList(
      sha256.convert(privateKey).bytes,
    );
    return _EphemeralKeyPair(publicKey: publicKey, privateKey: privateKey);
  }

  Uint8List _deriveSharedSecret(String codeHash, Uint8List key) {
    final combined = utf8.encode(codeHash) + key;
    final hash = sha256.convert(combined);
    return Uint8List.fromList(hash.bytes);
  }
}

class _EphemeralKeyPair {
  final Uint8List publicKey;
  final Uint8List privateKey;

  _EphemeralKeyPair({required this.publicKey, required this.privateKey});
}

/// Pairing code with expiry info
class PairingCode {
  final String code;
  final String formattedCode;
  final DateTime expiresAt;
  final String requestId;

  PairingCode({
    required this.code,
    required this.formattedCode,
    required this.expiresAt,
    required this.requestId,
  });

  Duration get remainingTime {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isValid => DateTime.now().isBefore(expiresAt);
}
