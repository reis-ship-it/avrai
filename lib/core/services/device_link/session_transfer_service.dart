import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;

import 'package:avrai/core/crypto/signal/secure_signal_storage.dart';
import 'package:avrai/core/services/device_link/auto_device_link_service.dart';

/// Session Transfer Service
///
/// Transfers Signal Protocol session state between devices.
/// Enables old message decryption on new devices.
///
/// Phase 26: Multi-Device Sync - Session Transfer
///
/// **Transfer Modes:**
/// - `sharedIdentity`: Both devices share same Signal identity key
///   - Simpler setup, same identity across devices
///   - All devices can decrypt each other's messages
///   - Less secure (compromise of one = compromise of all)
///
/// - `freshIdentity`: New device gets fresh identity but can decrypt history
///   - More secure (each device has unique identity)
///   - History transferred encrypted with shared secret
///   - New messages require per-device encryption (already implemented)
class SessionTransferService {
  static const String _logName = 'SessionTransferService';

  final SecureSignalStorage _secureStorage;

  SessionTransferService({
    required SecureSignalStorage secureStorage,
  }) : _secureStorage = secureStorage;

  /// Export all session data for transfer (on source device)
  ///
  /// Returns encrypted session bundle that can be sent to new device.
  Future<SessionTransferBundle> exportSessions({
    required SharedLinkSecret sharedSecret,
    required SessionTransferMode mode,
  }) async {
    try {
      developer.log('Exporting sessions in ${mode.name} mode', name: _logName);

      // Export all session data
      final sessionData = await _secureStorage.exportAllData();

      // Convert to JSON
      final jsonString = jsonEncode({
        'mode': mode.name,
        'session_records': sessionData['session_records'],
        'remote_identity_keys': sessionData['remote_identity_keys'],
        'channel_binding_hashes': sessionData['channel_binding_hashes'],
        'session_states': sessionData['session_states'],
        'session_index': sessionData['session_index'],
        'exported_at': DateTime.now().toIso8601String(),
      });

      // Encrypt
      final encrypted = _encrypt(
        Uint8List.fromList(utf8.encode(jsonString)),
        sharedSecret,
      );

      final checksum = sha256.convert(encrypted).toString().substring(0, 16);

      developer.log(
        'Exported ${(sessionData['session_index'] as List?)?.length ?? 0} sessions',
        name: _logName,
      );

      return SessionTransferBundle(
        encryptedData: encrypted,
        mode: mode,
        sessionCount: (sessionData['session_index'] as List?)?.length ?? 0,
        checksum: checksum,
        exportedAt: DateTime.now(),
      );
    } catch (e, st) {
      developer.log(
        'Session export failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Import session data from transfer bundle (on new device)
  ///
  /// Decrypts and imports session state based on transfer mode.
  Future<SessionImportResult> importSessions({
    required SessionTransferBundle bundle,
    required SharedLinkSecret sharedSecret,
  }) async {
    try {
      developer.log(
        'Importing sessions in ${bundle.mode.name} mode',
        name: _logName,
      );

      // Verify checksum
      final computedChecksum =
          sha256.convert(bundle.encryptedData).toString().substring(0, 16);
      if (computedChecksum != bundle.checksum) {
        throw Exception('Session bundle checksum mismatch');
      }

      // Decrypt
      final decrypted = _decrypt(bundle.encryptedData, sharedSecret);
      final jsonString = utf8.decode(decrypted);
      final sessionData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import based on mode
      switch (bundle.mode) {
        case SessionTransferMode.sharedIdentity:
          return await _importSharedIdentity(sessionData);
        case SessionTransferMode.freshIdentity:
          return await _importFreshIdentity(sessionData);
      }
    } catch (e, st) {
      developer.log(
        'Session import failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return SessionImportResult(
        success: false,
        sessionsImported: 0,
        mode: bundle.mode,
        error: e.toString(),
      );
    }
  }

  /// Import with shared identity - full session state shared
  Future<SessionImportResult> _importSharedIdentity(
    Map<String, dynamic> sessionData,
  ) async {
    // Import all session data
    await _secureStorage.importAllData(sessionData);

    final sessionCount =
        (sessionData['session_index'] as List?)?.length ?? 0;

    developer.log(
      'Imported $sessionCount sessions (shared identity)',
      name: _logName,
    );

    return SessionImportResult(
      success: true,
      sessionsImported: sessionCount,
      mode: SessionTransferMode.sharedIdentity,
    );
  }

  /// Import with fresh identity - only import for history decryption
  Future<SessionImportResult> _importFreshIdentity(
    Map<String, dynamic> sessionData,
  ) async {
    // For fresh identity, we only import remote identity keys and session records
    // We do NOT import our own identity key - we'll generate a fresh one

    // Import session records for decrypting old messages
    final sessionRecords =
        sessionData['session_records'] as Map<String, dynamic>?;
    if (sessionRecords != null) {
      for (final entry in sessionRecords.entries) {
        await _secureStorage.importSessionRecord(
          entry.key,
          entry.value as String,
        );
      }
    }

    // Import remote identity keys for verification
    final identityKeys =
        sessionData['remote_identity_keys'] as Map<String, dynamic>?;
    if (identityKeys != null) {
      for (final entry in identityKeys.entries) {
        await _secureStorage.importRemoteIdentityKey(
          entry.key,
          entry.value as String,
        );
      }
    }

    final sessionCount = sessionRecords?.length ?? 0;

    developer.log(
      'Imported $sessionCount sessions for history (fresh identity)',
      name: _logName,
    );

    return SessionImportResult(
      success: true,
      sessionsImported: sessionCount,
      mode: SessionTransferMode.freshIdentity,
      requiresKeyGeneration: true,
    );
  }

  /// Verify session transfer was successful
  Future<bool> verifyTransfer({
    required SessionTransferBundle bundle,
    required SharedLinkSecret sharedSecret,
  }) async {
    try {
      // Quick verification - check session count matches
      final localSessions = _secureStorage.getAllSessionKeys();

      return localSessions.length >= bundle.sessionCount;
    } catch (e) {
      developer.log('Transfer verification failed: $e', name: _logName);
      return false;
    }
  }

  // Encryption helpers (same as history transfer)

  Uint8List _encrypt(Uint8List data, SharedLinkSecret secret) {
    final key = secret.encryptionKey;
    final iv = secret.iv;

    final cipher = pc.GCMBlockCipher(pc.AESEngine());
    cipher.init(
      true,
      pc.AEADParameters(
        pc.KeyParameter(key),
        128,
        iv,
        Uint8List(0),
      ),
    );

    return cipher.process(data);
  }

  Uint8List _decrypt(Uint8List encrypted, SharedLinkSecret secret) {
    final key = secret.encryptionKey;
    final iv = secret.iv;

    final cipher = pc.GCMBlockCipher(pc.AESEngine());
    cipher.init(
      false,
      pc.AEADParameters(
        pc.KeyParameter(key),
        128,
        iv,
        Uint8List(0),
      ),
    );

    return cipher.process(encrypted);
  }
}

/// Session transfer mode
enum SessionTransferMode {
  /// Both devices share same identity key
  sharedIdentity,

  /// New device gets fresh identity, can decrypt history
  freshIdentity,
}

/// Session transfer bundle
class SessionTransferBundle {
  final Uint8List encryptedData;
  final SessionTransferMode mode;
  final int sessionCount;
  final String checksum;
  final DateTime exportedAt;

  SessionTransferBundle({
    required this.encryptedData,
    required this.mode,
    required this.sessionCount,
    required this.checksum,
    required this.exportedAt,
  });

  int get sizeBytes => encryptedData.length;
}

/// Session import result
class SessionImportResult {
  final bool success;
  final int sessionsImported;
  final SessionTransferMode mode;
  final String? error;
  final bool requiresKeyGeneration;

  SessionImportResult({
    required this.success,
    required this.sessionsImported,
    required this.mode,
    this.error,
    this.requiresKeyGeneration = false,
  });
}
