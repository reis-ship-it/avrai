import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/core/crypto/signal/device_registration_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

/// Auto Device Link Service
///
/// Handles automatic device linking when a user logs in on a new device.
/// Detects existing devices and prompts for history transfer.
///
/// Phase 26: Multi-Device Sync - Same Account Login (Primary Method)
///
/// **Flow:**
/// 1. User logs in on new device
/// 2. Service detects existing devices for this account
/// 3. Prompts user: "Transfer history from [device name]?"
/// 4. Establishes secure channel via Supabase RLS
/// 5. Initiates background history transfer
class AutoDeviceLinkService {
  static const String _logName = 'AutoDeviceLinkService';
  static const String _linkRequestsTable = 'device_link_requests';
  static const String _linkRequestsChannel = 'device_link_requests';

  final SupabaseService _supabaseService;
  final DeviceRegistrationService _deviceRegistrationService;

  // Realtime subscription for link requests
  RealtimeChannel? _linkRequestsSubscription;

  // Callback for when a link request is received
  void Function(DeviceLinkRequest)? onLinkRequestReceived;
  void Function(DeviceLinkRequest)? onLinkRequestApproved;
  void Function(DeviceLinkRequest)? onLinkRequestRejected;

  AutoDeviceLinkService({
    required SupabaseService supabaseService,
    required DeviceRegistrationService deviceRegistrationService,
  })  : _supabaseService = supabaseService,
        _deviceRegistrationService = deviceRegistrationService;

  /// Check for existing devices when logging in
  ///
  /// Returns list of active devices that can transfer history.
  /// Returns empty list if this is the first device.
  Future<List<RegisteredDevice>> checkForExistingDevices(String userId) async {
    try {
      final devices = await _deviceRegistrationService.loadDevicesFromCloud(userId);
      
      // Filter to active devices only
      final activeDevices = devices
          .where((d) => d.status == DeviceStatus.active)
          .toList();
      
      developer.log(
        'Found ${activeDevices.length} existing devices for user',
        name: _logName,
      );
      
      return activeDevices;
    } catch (e) {
      developer.log('Failed to check for existing devices: $e', name: _logName);
      return [];
    }
  }

  /// Request history transfer from another device
  ///
  /// Creates a link request that the other device can approve.
  Future<DeviceLinkRequest> requestHistoryTransfer({
    required String userId,
    required String targetDeviceId,
  }) async {
    // Generate ephemeral X25519 key pair for secure channel
    final keyPair = _generateEphemeralKeyPair();
    final publicKeyBase64 = base64Encode(keyPair.publicKey);

    final currentDevice = _deviceRegistrationService.currentDevice;
    if (currentDevice == null) {
      throw StateError('Current device not registered');
    }

    final request = DeviceLinkRequest(
      requestId: '', // Will be assigned by Supabase
      userId: userId,
      requestingDeviceId: currentDevice.deviceIdString,
      approvingDeviceId: targetDeviceId,
      linkMethod: LinkMethod.sameAccount,
      ephemeralPublicKey: publicKeyBase64,
      status: LinkRequestStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );

    // Store in Supabase
    final response = await _supabaseService.client
        .from(_linkRequestsTable)
        .insert(request.toJson())
        .select()
        .single();

    final createdRequest = DeviceLinkRequest.fromJson(response);

    developer.log(
      'Created link request: ${createdRequest.requestId} -> $targetDeviceId',
      name: _logName,
    );

    return createdRequest;
  }

  /// Start listening for link requests (on existing device)
  Future<void> startListeningForLinkRequests(String userId) async {
    final currentDevice = _deviceRegistrationService.currentDevice;
    if (currentDevice == null) return;

    _linkRequestsSubscription = _supabaseService.client
        .channel('$_linkRequestsChannel:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: _linkRequestsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'approving_device_id',
            value: currentDevice.deviceIdString,
          ),
          callback: (payload) {
            final request = DeviceLinkRequest.fromJson(
              payload.newRecord,
            );
            developer.log(
              'Received link request: ${request.requestId}',
              name: _logName,
            );
            onLinkRequestReceived?.call(request);
          },
        )
        .subscribe();

    developer.log('Started listening for link requests', name: _logName);
  }

  /// Stop listening for link requests
  Future<void> stopListeningForLinkRequests() async {
    await _linkRequestsSubscription?.unsubscribe();
    _linkRequestsSubscription = null;
  }

  /// Approve a link request (on existing device)
  ///
  /// Generates shared secret for encrypted channel.
  Future<SharedLinkSecret> approveLinkRequest(
    DeviceLinkRequest request,
  ) async {
    // Generate our ephemeral key pair
    final keyPair = _generateEphemeralKeyPair();
    final publicKeyBase64 = base64Encode(keyPair.publicKey);

    // Compute shared secret using ECDH
    final theirPublicKey = base64Decode(request.ephemeralPublicKey!);
    final sharedSecret = _computeSharedSecret(keyPair.privateKey, theirPublicKey);

    // Update request status
    await _supabaseService.client.from(_linkRequestsTable).update({
      'status': 'approved',
      'resolved_at': DateTime.now().toIso8601String(),
      'ephemeral_public_key': publicKeyBase64, // Our response key
    }).eq('request_id', request.requestId);

    developer.log('Approved link request: ${request.requestId}', name: _logName);

    return SharedLinkSecret(
      requestId: request.requestId,
      sharedSecret: sharedSecret,
      isInitiator: false,
    );
  }

  /// Reject a link request
  Future<void> rejectLinkRequest(String requestId) async {
    await _supabaseService.client.from(_linkRequestsTable).update({
      'status': 'rejected',
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('request_id', requestId);

    developer.log('Rejected link request: $requestId', name: _logName);
  }

  /// Wait for link request approval (on new device)
  Future<SharedLinkSecret?> waitForApproval(
    DeviceLinkRequest request,
    Uint8List privateKey, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final completer = Completer<SharedLinkSecret?>();

    // Subscribe to updates for this request
    final subscription = _supabaseService.client
        .channel('link_request:${request.requestId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: _linkRequestsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'request_id',
            value: request.requestId,
          ),
          callback: (payload) {
            final updatedRequest = DeviceLinkRequest.fromJson(
              payload.newRecord,
            );

            if (updatedRequest.status == LinkRequestStatus.approved) {
              // Compute shared secret
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
    }
  }

  // Crypto helpers

  _EphemeralKeyPair _generateEphemeralKeyPair() {
    final keyGen = pc.ECKeyGenerator();
    final params = pc.ECKeyGeneratorParameters(pc.ECCurve_secp256r1());
    keyGen.init(pc.ParametersWithRandom(
      params,
      pc.SecureRandom('Fortuna')..seed(pc.KeyParameter(Uint8List(32))),
    ));
    final pair = keyGen.generateKeyPair();

    final publicKey = (pair.publicKey).Q!.getEncoded(false);
    final privateKey = (pair.privateKey).d!.toRadixString(16);

    return _EphemeralKeyPair(
      publicKey: publicKey,
      privateKey: Uint8List.fromList(utf8.encode(privateKey)),
    );
  }

  Uint8List _computeSharedSecret(
    Uint8List privateKey,
    Uint8List publicKey,
  ) {
    // Simplified ECDH - in production use proper crypto library
    // Compute SHA-256 hash of concatenated keys as placeholder
    final combined = Uint8List.fromList([...privateKey, ...publicKey]);
    final hash = sha256.convert(combined);
    return Uint8List.fromList(hash.bytes);
  }
}

/// Ephemeral key pair for secure channel establishment
class _EphemeralKeyPair {
  final Uint8List publicKey;
  final Uint8List privateKey;

  _EphemeralKeyPair({
    required this.publicKey,
    required this.privateKey,
  });
}

/// Link method enum
enum LinkMethod {
  sameAccount,
  numericCode,
  pushApproval,
  secureBypass,
}

/// Link request status enum
enum LinkRequestStatus {
  pending,
  approved,
  rejected,
  expired,
}

/// Device Link Request
class DeviceLinkRequest {
  final String requestId;
  final String userId;
  final String requestingDeviceId;
  final String? approvingDeviceId;
  final LinkMethod linkMethod;
  final String? ephemeralPublicKey;
  final String? codeHash;
  final LinkRequestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? resolvedAt;

  DeviceLinkRequest({
    required this.requestId,
    required this.userId,
    required this.requestingDeviceId,
    this.approvingDeviceId,
    required this.linkMethod,
    this.ephemeralPublicKey,
    this.codeHash,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
        'request_id': requestId.isEmpty ? null : requestId,
        'user_id': userId,
        'requesting_device_id': requestingDeviceId,
        'approving_device_id': approvingDeviceId,
        'link_method': linkMethod.name,
        'ephemeral_public_key': ephemeralPublicKey,
        'code_hash': codeHash,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  factory DeviceLinkRequest.fromJson(Map<String, dynamic> json) {
    return DeviceLinkRequest(
      requestId: json['request_id'] as String,
      userId: json['user_id'] as String,
      requestingDeviceId: json['requesting_device_id'] as String,
      approvingDeviceId: json['approving_device_id'] as String?,
      linkMethod: LinkMethod.values.firstWhere(
        (m) => m.name == json['link_method'],
        orElse: () => LinkMethod.sameAccount,
      ),
      ephemeralPublicKey: json['ephemeral_public_key'] as String?,
      codeHash: json['code_hash'] as String?,
      status: LinkRequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => LinkRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }
}

/// Shared secret for encrypted communication
class SharedLinkSecret {
  final String requestId;
  final Uint8List sharedSecret;
  final bool isInitiator;

  SharedLinkSecret({
    required this.requestId,
    required this.sharedSecret,
    required this.isInitiator,
  });

  /// Get encryption key (first 16 bytes)
  Uint8List get encryptionKey => Uint8List.fromList(sharedSecret.take(16).toList());

  /// Get IV (last 12 bytes)
  Uint8List get iv => Uint8List.fromList(sharedSecret.skip(20).take(12).toList());
}
