import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:typed_data';
import 'package:avrai/core/crypto/key_exchange.dart';

/// Session Key Manager for Forward Secrecy
///
/// Manages session keys with rotation to provide basic forward secrecy.
/// Keys are rotated per session to ensure that compromise of one key doesn't
/// compromise past sessions.
///
/// **Security Features:**
/// - Ephemeral session keys
/// - Key rotation per session
/// - Automatic key expiration
/// - Forward secrecy support
///
/// **Usage:**
/// ```dart
/// final manager = SessionKeyManager();
///
/// // Generate session key
/// final sessionKey = await manager.generateSessionKey('session-123');
///
/// // Rotate key (for forward secrecy)
/// final newKey = await manager.rotateSessionKey('session-123');
///
/// // Get current key
/// final currentKey = manager.getSessionKey('session-123');
///
/// // Delete session (removes all keys)
/// manager.deleteSession('session-123');
/// ```
class SessionKeyManager {
  static const String _logName = 'SessionKeyManager';

  // Session keys storage
  final Map<String, SessionKey> _sessionKeys = {};

  // Key exchange for deriving keys
  final KeyExchange _keyExchange = KeyExchange();

  /// Generate a new session key
  ///
  /// Creates a new ephemeral key for the session. Each session gets its
  /// own unique key, providing isolation between sessions.
  ///
  /// **Parameters:**
  /// - `sessionId`: Unique identifier for the session
  ///
  /// **Returns:**
  /// SessionKey object containing the key and metadata
  Future<SessionKey> generateSessionKey(String sessionId) async {
    try {
      developer.log('Generating session key for: $sessionId', name: _logName);

      // Generate encryption key
      final key = await _keyExchange.generateEncryptionKey();

      final sessionKey = SessionKey(
        key: key,
        createdAt: DateTime.now(),
        sessionId: sessionId,
        rotationCount: 0,
      );

      _sessionKeys[sessionId] = sessionKey;

      developer.log(
        'Session key generated successfully for: $sessionId',
        name: _logName,
      );
      return sessionKey;
    } catch (e, stackTrace) {
      developer.log(
        'Error generating session key: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Rotate session key (for forward secrecy)
  ///
  /// Generates a new key for the session and marks the old key as rotated.
  /// Old keys are not immediately deleted to allow for message decryption
  /// during transition periods, but they should be deleted after a grace period.
  ///
  /// **Parameters:**
  /// - `sessionId`: Session identifier
  ///
  /// **Returns:**
  /// New SessionKey with incremented rotation count
  Future<SessionKey> rotateSessionKey(String sessionId) async {
    try {
      developer.log('Rotating session key for: $sessionId', name: _logName);

      // Get current key
      final currentKey = _sessionKeys[sessionId];
      if (currentKey == null) {
        // No existing key, generate new one
        return generateSessionKey(sessionId);
      }

      // Generate new key
      final newKey = await _keyExchange.generateEncryptionKey();

      // Create new session key with incremented rotation count
      final rotatedKey = SessionKey(
        key: newKey,
        createdAt: DateTime.now(),
        sessionId: sessionId,
        rotationCount: currentKey.rotationCount + 1,
        previousKey: currentKey.key, // Keep reference to old key temporarily
      );

      // Replace old key
      _sessionKeys[sessionId] = rotatedKey;

      developer.log(
        'Session key rotated successfully for: $sessionId (rotation: ${rotatedKey.rotationCount})',
        name: _logName,
      );
      return rotatedKey;
    } catch (e, stackTrace) {
      developer.log(
        'Error rotating session key: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get current session key
  ///
  /// Returns the current active key for the session.
  ///
  /// **Parameters:**
  /// - `sessionId`: Session identifier
  ///
  /// **Returns:**
  /// Current SessionKey, or null if session doesn't exist
  SessionKey? getSessionKey(String sessionId) {
    return _sessionKeys[sessionId];
  }

  /// Get session key or generate if missing
  ///
  /// Convenience method that gets the current key or generates a new one
  /// if the session doesn't exist.
  ///
  /// **Parameters:**
  /// - `sessionId`: Session identifier
  ///
  /// **Returns:**
  /// SessionKey (existing or newly generated)
  Future<SessionKey> getOrGenerateSessionKey(String sessionId) async {
    final existing = getSessionKey(sessionId);
    if (existing != null) {
      return existing;
    }
    return generateSessionKey(sessionId);
  }

  /// Delete session key
  ///
  /// Removes the session and all associated keys. This should be called
  /// when a session ends to ensure forward secrecy.
  ///
  /// **Parameters:**
  /// - `sessionId`: Session identifier
  void deleteSessionKey(String sessionId) {
    _sessionKeys.remove(sessionId);
    developer.log('Session key deleted for: $sessionId', name: _logName);
  }

  /// Check if session exists
  bool hasSession(String sessionId) {
    return _sessionKeys.containsKey(sessionId);
  }

  /// Get all active session IDs
  List<String> getActiveSessions() {
    return _sessionKeys.keys.toList();
  }

  /// Clean up expired sessions
  ///
  /// Removes sessions that are older than the specified duration.
  /// This helps maintain forward secrecy by removing old keys.
  ///
  /// **Parameters:**
  /// - `maxAge`: Maximum age for sessions (default: 24 hours)
  ///
  /// **Returns:**
  /// Number of sessions cleaned up
  int cleanupExpiredSessions({Duration maxAge = const Duration(hours: 24)}) {
    final now = DateTime.now();
    final expiredSessions = <String>[];

    for (final entry in _sessionKeys.entries) {
      final age = now.difference(entry.value.createdAt);
      if (age > maxAge) {
        expiredSessions.add(entry.key);
      }
    }

    for (final sessionId in expiredSessions) {
      deleteSessionKey(sessionId);
    }

    if (expiredSessions.isNotEmpty) {
      developer.log(
        'Cleaned up ${expiredSessions.length} expired sessions',
        name: _logName,
      );
    }

    return expiredSessions.length;
  }

  /// Rotate all active sessions
  ///
  /// Rotates keys for all active sessions. Useful for periodic key rotation
  /// to maintain forward secrecy.
  ///
  /// **Returns:**
  /// Number of sessions rotated
  Future<int> rotateAllSessions() async {
    final sessionIds = getActiveSessions();
    int rotated = 0;

    for (final sessionId in sessionIds) {
      try {
        await rotateSessionKey(sessionId);
        rotated++;
      } catch (e) {
        developer.log(
          'Error rotating session $sessionId: $e',
          name: _logName,
        );
      }
    }

    developer.log('Rotated $rotated sessions', name: _logName);
    return rotated;
  }
}

/// Session key with metadata
class SessionKey {
  /// The encryption key (32 bytes for AES-256)
  final Uint8List key;

  /// When the key was created
  final DateTime createdAt;

  /// Session identifier
  final String sessionId;

  /// Number of times this key has been rotated
  final int rotationCount;

  /// Previous key (for transition period, null after cleanup)
  final Uint8List? previousKey;

  SessionKey({
    required this.key,
    required this.createdAt,
    required this.sessionId,
    required this.rotationCount,
    this.previousKey,
  });

  /// Get key age
  Duration get age => DateTime.now().difference(createdAt);

  /// Check if key is expired
  bool isExpired(Duration maxAge) => age > maxAge;

  /// Get key as base64 string (for storage/transmission)
  String get keyBase64 => base64Encode(key);

  /// Get previous key as base64 string (if available)
  String? get previousKeyBase64 =>
      previousKey != null ? base64Encode(previousKey!) : null;
}

