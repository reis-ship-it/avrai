import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';

/// Secure storage for Signal Protocol session data
///
/// Replaces Sembast storage for cryptographic material with hardware-backed
/// secure storage (iOS Keychain, Android EncryptedSharedPreferences).
///
/// Uses in-memory caching for performance with write-through persistence.
///
/// Phase 26: Multi-Device Storage Migration
class SecureSignalStorage {
  static const String _logName = 'SecureSignalStorage';

  // Storage key prefixes
  static const String _sessionRecordPrefix = 'signal_session_record_';
  static const String _remoteIdentityKeyPrefix = 'signal_remote_identity_';
  static const String _channelBindingHashPrefix = 'signal_channel_hash_';
  static const String _sessionStatePrefix = 'signal_session_state_';
  static const String _sessionIndexKey = 'signal_session_index';

  final FlutterSecureStorage _secureStorage;

  // In-memory caches for performance
  final Map<String, Uint8List> _sessionRecordCache = {};
  final Map<String, Uint8List> _remoteIdentityKeyCache = {};
  final Map<String, Uint8List> _channelBindingHashCache = {};
  final Map<String, Map<String, dynamic>> _sessionStateCache = {};

  // Track which sessions exist (for iteration)
  final Set<String> _sessionIndex = {};

  bool _isWarmed = false;

  SecureSignalStorage({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Warm caches from secure storage
  ///
  /// Call during app initialization to load all session data into memory.
  /// This enables synchronous access for native FFI callbacks.
  Future<void> warmCaches() async {
    if (_isWarmed) return;

    try {
      developer.log('Warming Signal secure storage caches...', name: _logName);

      // Load session index
      final indexJson = await _secureStorage.read(key: _sessionIndexKey);
      if (indexJson != null && indexJson.isNotEmpty) {
        try {
          final list = jsonDecode(indexJson) as List;
          _sessionIndex.addAll(list.cast<String>());
        } catch (_) {
          // Corrupted index, will rebuild
        }
      }

      // Load all session records
      for (final sessionKey in _sessionIndex) {
        await _loadSessionRecord(sessionKey);
        await _loadRemoteIdentityKey(sessionKey);
        await _loadChannelBindingHash(sessionKey);
        await _loadSessionState(sessionKey);
      }

      _isWarmed = true;
      developer.log(
        'Signal secure storage warmed: ${_sessionIndex.length} sessions',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Failed to warm Signal secure storage: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  // ============================================================
  // SESSION RECORDS
  // ============================================================

  /// Get session record bytes (synchronous, from cache)
  Uint8List? getSessionRecordBytes(String sessionKey) {
    return _sessionRecordCache[sessionKey];
  }

  /// Store session record bytes
  Future<void> storeSessionRecordBytes(
    String sessionKey,
    Uint8List bytes,
  ) async {
    // Update cache immediately
    _sessionRecordCache[sessionKey] = bytes;

    // Track session
    await _addToSessionIndex(sessionKey);

    // Persist to secure storage
    try {
      await _secureStorage.write(
        key: '$_sessionRecordPrefix$sessionKey',
        value: base64Encode(bytes),
      );
    } catch (e) {
      developer.log(
        'Failed to persist session record: $e',
        name: _logName,
      );
    }
  }

  /// Delete session record
  Future<void> deleteSessionRecord(String sessionKey) async {
    _sessionRecordCache.remove(sessionKey);

    try {
      await _secureStorage.delete(key: '$_sessionRecordPrefix$sessionKey');
    } catch (_) {}
  }

  /// Get all session records
  Map<String, Uint8List> getAllSessionRecords() {
    return Map.from(_sessionRecordCache);
  }

  Future<void> _loadSessionRecord(String sessionKey) async {
    try {
      final b64 = await _secureStorage.read(
        key: '$_sessionRecordPrefix$sessionKey',
      );
      if (b64 != null && b64.isNotEmpty) {
        _sessionRecordCache[sessionKey] = base64Decode(b64);
      }
    } catch (_) {}
  }

  // ============================================================
  // REMOTE IDENTITY KEYS
  // ============================================================

  /// Get remote identity key bytes (synchronous, from cache)
  Uint8List? getRemoteIdentityKeyBytes(String sessionKey) {
    return _remoteIdentityKeyCache[sessionKey];
  }

  /// Store remote identity key bytes
  Future<void> storeRemoteIdentityKeyBytes(
    String sessionKey,
    Uint8List bytes,
  ) async {
    _remoteIdentityKeyCache[sessionKey] = bytes;

    await _addToSessionIndex(sessionKey);

    try {
      await _secureStorage.write(
        key: '$_remoteIdentityKeyPrefix$sessionKey',
        value: base64Encode(bytes),
      );
    } catch (e) {
      developer.log(
        'Failed to persist remote identity key: $e',
        name: _logName,
      );
    }
  }

  /// Delete remote identity key
  Future<void> deleteRemoteIdentityKey(String sessionKey) async {
    _remoteIdentityKeyCache.remove(sessionKey);

    try {
      await _secureStorage.delete(key: '$_remoteIdentityKeyPrefix$sessionKey');
    } catch (_) {}
  }

  /// Get all remote identity keys
  Map<String, Uint8List> getAllRemoteIdentityKeys() {
    return Map.from(_remoteIdentityKeyCache);
  }

  Future<void> _loadRemoteIdentityKey(String sessionKey) async {
    try {
      final b64 = await _secureStorage.read(
        key: '$_remoteIdentityKeyPrefix$sessionKey',
      );
      if (b64 != null && b64.isNotEmpty) {
        _remoteIdentityKeyCache[sessionKey] = base64Decode(b64);
      }
    } catch (_) {}
  }

  // ============================================================
  // CHANNEL BINDING HASHES
  // ============================================================

  /// Get channel binding hash (synchronous, from cache)
  Uint8List? getChannelBindingHash(String sessionKey) {
    return _channelBindingHashCache[sessionKey];
  }

  /// Store channel binding hash
  Future<void> storeChannelBindingHash(
    String sessionKey,
    Uint8List hash,
  ) async {
    _channelBindingHashCache[sessionKey] = hash;

    await _addToSessionIndex(sessionKey);

    try {
      await _secureStorage.write(
        key: '$_channelBindingHashPrefix$sessionKey',
        value: base64Encode(hash),
      );
    } catch (e) {
      developer.log(
        'Failed to persist channel binding hash: $e',
        name: _logName,
      );
    }
  }

  /// Delete channel binding hash
  Future<void> deleteChannelBindingHash(String sessionKey) async {
    _channelBindingHashCache.remove(sessionKey);

    try {
      await _secureStorage.delete(
        key: '$_channelBindingHashPrefix$sessionKey',
      );
    } catch (_) {}
  }

  Future<void> _loadChannelBindingHash(String sessionKey) async {
    try {
      final b64 = await _secureStorage.read(
        key: '$_channelBindingHashPrefix$sessionKey',
      );
      if (b64 != null && b64.isNotEmpty) {
        _channelBindingHashCache[sessionKey] = base64Decode(b64);
      }
    } catch (_) {}
  }

  // ============================================================
  // SESSION STATE (High-level session info)
  // ============================================================

  /// Get session state
  Map<String, dynamic>? getSessionState(String sessionKey) {
    return _sessionStateCache[sessionKey];
  }

  /// Store session state
  Future<void> storeSessionState(
    String sessionKey,
    Map<String, dynamic> state,
  ) async {
    _sessionStateCache[sessionKey] = state;

    await _addToSessionIndex(sessionKey);

    try {
      await _secureStorage.write(
        key: '$_sessionStatePrefix$sessionKey',
        value: jsonEncode(state),
      );
    } catch (e) {
      developer.log(
        'Failed to persist session state: $e',
        name: _logName,
      );
    }
  }

  /// Delete session state
  Future<void> deleteSessionState(String sessionKey) async {
    _sessionStateCache.remove(sessionKey);

    try {
      await _secureStorage.delete(key: '$_sessionStatePrefix$sessionKey');
    } catch (_) {}
  }

  /// Get all session states
  Map<String, Map<String, dynamic>> getAllSessionStates() {
    return Map.from(_sessionStateCache);
  }

  Future<void> _loadSessionState(String sessionKey) async {
    try {
      final json = await _secureStorage.read(
        key: '$_sessionStatePrefix$sessionKey',
      );
      if (json != null && json.isNotEmpty) {
        _sessionStateCache[sessionKey] =
            jsonDecode(json) as Map<String, dynamic>;
      }
    } catch (_) {}
  }

  // ============================================================
  // SESSION INDEX MANAGEMENT
  // ============================================================

  /// Get all session keys
  Set<String> getAllSessionKeys() {
    return Set.from(_sessionIndex);
  }

  /// Check if session exists
  bool hasSession(String sessionKey) {
    return _sessionIndex.contains(sessionKey);
  }

  Future<void> _addToSessionIndex(String sessionKey) async {
    if (_sessionIndex.add(sessionKey)) {
      await _persistSessionIndex();
    }
  }

  Future<void> _removeFromSessionIndex(String sessionKey) async {
    if (_sessionIndex.remove(sessionKey)) {
      await _persistSessionIndex();
    }
  }

  Future<void> _persistSessionIndex() async {
    try {
      await _secureStorage.write(
        key: _sessionIndexKey,
        value: jsonEncode(_sessionIndex.toList()),
      );
    } catch (_) {}
  }

  // ============================================================
  // FULL SESSION MANAGEMENT
  // ============================================================

  /// Delete all data for a session
  Future<void> deleteSession(String sessionKey) async {
    await deleteSessionRecord(sessionKey);
    await deleteRemoteIdentityKey(sessionKey);
    await deleteChannelBindingHash(sessionKey);
    await deleteSessionState(sessionKey);
    await _removeFromSessionIndex(sessionKey);
  }

  /// Delete all sessions (for logout/reset)
  Future<void> deleteAllSessions() async {
    final keys = Set<String>.from(_sessionIndex);

    for (final key in keys) {
      await deleteSession(key);
    }

    _sessionRecordCache.clear();
    _remoteIdentityKeyCache.clear();
    _channelBindingHashCache.clear();
    _sessionStateCache.clear();
    _sessionIndex.clear();

    await _persistSessionIndex();
  }

  /// Get session count
  int get sessionCount => _sessionIndex.length;

  /// Check if caches are warmed
  bool get isWarmed => _isWarmed;

  // ============================================================
  // MIGRATION HELPERS
  // ============================================================

  /// Import session record from legacy storage (Sembast migration)
  Future<void> importSessionRecord(
    String sessionKey,
    String base64Data,
  ) async {
    try {
      final bytes = base64Decode(base64Data);
      await storeSessionRecordBytes(sessionKey, bytes);
    } catch (e) {
      developer.log(
        'Failed to import session record: $e',
        name: _logName,
      );
    }
  }

  /// Import remote identity key from legacy storage
  Future<void> importRemoteIdentityKey(
    String sessionKey,
    String base64Data,
  ) async {
    try {
      final bytes = base64Decode(base64Data);
      await storeRemoteIdentityKeyBytes(sessionKey, bytes);
    } catch (e) {
      developer.log(
        'Failed to import remote identity key: $e',
        name: _logName,
      );
    }
  }

  /// Export all data for backup/transfer
  Future<Map<String, dynamic>> exportAllData() async {
    final export = <String, dynamic>{
      'session_records': <String, String>{},
      'remote_identity_keys': <String, String>{},
      'channel_binding_hashes': <String, String>{},
      'session_states': _sessionStateCache,
      'session_index': _sessionIndex.toList(),
    };

    for (final entry in _sessionRecordCache.entries) {
      (export['session_records'] as Map<String, String>)[entry.key] =
          base64Encode(entry.value);
    }

    for (final entry in _remoteIdentityKeyCache.entries) {
      (export['remote_identity_keys'] as Map<String, String>)[entry.key] =
          base64Encode(entry.value);
    }

    for (final entry in _channelBindingHashCache.entries) {
      (export['channel_binding_hashes'] as Map<String, String>)[entry.key] =
          base64Encode(entry.value);
    }

    return export;
  }

  /// Import all data from backup/transfer
  Future<void> importAllData(Map<String, dynamic> data) async {
    // Import session records
    final sessionRecords = data['session_records'] as Map<String, dynamic>?;
    if (sessionRecords != null) {
      for (final entry in sessionRecords.entries) {
        await importSessionRecord(entry.key, entry.value as String);
      }
    }

    // Import remote identity keys
    final identityKeys = data['remote_identity_keys'] as Map<String, dynamic>?;
    if (identityKeys != null) {
      for (final entry in identityKeys.entries) {
        await importRemoteIdentityKey(entry.key, entry.value as String);
      }
    }

    // Import channel binding hashes
    final hashes = data['channel_binding_hashes'] as Map<String, dynamic>?;
    if (hashes != null) {
      for (final entry in hashes.entries) {
        try {
          final bytes = base64Decode(entry.value as String);
          await storeChannelBindingHash(entry.key, bytes);
        } catch (_) {}
      }
    }

    // Import session states
    final states = data['session_states'] as Map<String, dynamic>?;
    if (states != null) {
      for (final entry in states.entries) {
        await storeSessionState(
          entry.key,
          entry.value as Map<String, dynamic>,
        );
      }
    }
  }
}
