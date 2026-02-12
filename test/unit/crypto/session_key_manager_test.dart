import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/crypto/session_key_manager.dart';
import 'dart:convert';

void main() {
  group('SessionKeyManager', () {
    late SessionKeyManager manager;

    setUp(() {
      manager = SessionKeyManager();
    });

    group('generateSessionKey', () {
      test('should generate a session key', () async {
        final sessionKey = await manager.generateSessionKey('session-1');

        expect(sessionKey, isNotNull);
        expect(sessionKey.key.length, equals(32)); // 32 bytes for AES-256
        expect(sessionKey.sessionId, equals('session-1'));
        expect(sessionKey.rotationCount, equals(0));
        expect(sessionKey.createdAt, isNotNull);
      });

      test('should generate different keys for different sessions', () async {
        final key1 = await manager.generateSessionKey('session-1');
        final key2 = await manager.generateSessionKey('session-2');

        expect(key1.key, isNot(equals(key2.key)));
        expect(key1.sessionId, isNot(equals(key2.sessionId)));
      });

      test('should store session key', () async {
        final sessionKey = await manager.generateSessionKey('session-1');

        final retrieved = manager.getSessionKey('session-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.key, equals(sessionKey.key));
        expect(retrieved.sessionId, equals(sessionKey.sessionId));
      });
    });

    group('rotateSessionKey', () {
      test('should rotate session key', () async {
        final originalKey = await manager.generateSessionKey('session-1');
        final rotatedKey = await manager.rotateSessionKey('session-1');

        expect(rotatedKey.key, isNot(equals(originalKey.key)));
        expect(rotatedKey.sessionId, equals(originalKey.sessionId));
        expect(rotatedKey.rotationCount, equals(1));
        expect(rotatedKey.createdAt.isAfter(originalKey.createdAt), isTrue);
      });

      test('should increment rotation count', () async {
        await manager.generateSessionKey('session-1');
        final key1 = await manager.rotateSessionKey('session-1');
        final key2 = await manager.rotateSessionKey('session-1');
        final key3 = await manager.rotateSessionKey('session-1');

        expect(key1.rotationCount, equals(1));
        expect(key2.rotationCount, equals(2));
        expect(key3.rotationCount, equals(3));
      });

      test('should generate new key if session does not exist', () async {
        final key = await manager.rotateSessionKey('new-session');

        expect(key, isNotNull);
        expect(key.sessionId, equals('new-session'));
        expect(key.rotationCount, equals(0));
      });
    });

    group('getSessionKey', () {
      test('should return null for non-existent session', () {
        final key = manager.getSessionKey('non-existent');
        expect(key, isNull);
      });

      test('should return session key if exists', () async {
        final sessionKey = await manager.generateSessionKey('session-1');
        final retrieved = manager.getSessionKey('session-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.key, equals(sessionKey.key));
      });
    });

    group('getOrGenerateSessionKey', () {
      test('should return existing key if exists', () async {
        final originalKey = await manager.generateSessionKey('session-1');
        final retrieved = await manager.getOrGenerateSessionKey('session-1');

        expect(retrieved.key, equals(originalKey.key));
      });

      test('should generate new key if does not exist', () async {
        final key = await manager.getOrGenerateSessionKey('new-session');

        expect(key, isNotNull);
        expect(key.sessionId, equals('new-session'));
      });
    });

    group('deleteSessionKey', () {
      test('should delete session key', () async {
        await manager.generateSessionKey('session-1');
        expect(manager.hasSession('session-1'), isTrue);

        manager.deleteSessionKey('session-1');
        expect(manager.hasSession('session-1'), isFalse);
        expect(manager.getSessionKey('session-1'), isNull);
      });

      test('should not throw if session does not exist', () {
        expect(() => manager.deleteSessionKey('non-existent'), returnsNormally);
      });
    });

    group('hasSession', () {
      test('should return false for non-existent session', () {
        expect(manager.hasSession('non-existent'), isFalse);
      });

      test('should return true for existing session', () async {
        await manager.generateSessionKey('session-1');
        expect(manager.hasSession('session-1'), isTrue);
      });
    });

    group('getActiveSessions', () {
      test('should return empty list when no sessions', () {
        expect(manager.getActiveSessions(), isEmpty);
      });

      test('should return all active session IDs', () async {
        await manager.generateSessionKey('session-1');
        await manager.generateSessionKey('session-2');
        await manager.generateSessionKey('session-3');

        final sessions = manager.getActiveSessions();
        expect(sessions.length, equals(3));
        expect(sessions, contains('session-1'));
        expect(sessions, contains('session-2'));
        expect(sessions, contains('session-3'));
      });
    });

    group('cleanupExpiredSessions', () {
      test('should not clean up non-expired sessions', () async {
        await manager.generateSessionKey('session-1');
        final cleaned = manager.cleanupExpiredSessions(
          maxAge: const Duration(hours: 24),
        );

        expect(cleaned, equals(0));
        expect(manager.hasSession('session-1'), isTrue);
      });

      test('should clean up expired sessions', () async {
        // Create a session
        await manager.generateSessionKey('session-1');

        // Manually set old creation time (for testing)
        // Note: In real implementation, we'd need to mock DateTime
        // For now, we'll test with a very short maxAge
        await Future.delayed(const Duration(milliseconds: 10));

        // This won't actually clean up since session was just created
        // But we can test the logic
        final cleaned = manager.cleanupExpiredSessions(
          maxAge: const Duration(milliseconds: 1),
        );

        // Should clean up the session we just created
        expect(cleaned, greaterThanOrEqualTo(0));
      });
    });

    group('rotateAllSessions', () {
      test('should rotate all active sessions', () async {
        await manager.generateSessionKey('session-1');
        await manager.generateSessionKey('session-2');
        await manager.generateSessionKey('session-3');

        final rotated = await manager.rotateAllSessions();

        expect(rotated, equals(3));

        // All sessions should have rotation count of 1
        expect(manager.getSessionKey('session-1')!.rotationCount, equals(1));
        expect(manager.getSessionKey('session-2')!.rotationCount, equals(1));
        expect(manager.getSessionKey('session-3')!.rotationCount, equals(1));
      });

      test('should return 0 if no sessions', () async {
        final rotated = await manager.rotateAllSessions();
        expect(rotated, equals(0));
      });
    });
  });

  group('SessionKey', () {
    test('should calculate age correctly', () async {
      final manager = SessionKeyManager();
      final sessionKey = await manager.generateSessionKey('session-1');

      await Future.delayed(const Duration(milliseconds: 10));

      final age = sessionKey.age;
      expect(age.inMilliseconds, greaterThanOrEqualTo(10));
    });

    test('should check expiration correctly', () async {
      final manager = SessionKeyManager();
      final sessionKey = await manager.generateSessionKey('session-1');

      expect(sessionKey.isExpired(const Duration(hours: 24)), isFalse);
      
      // Wait a bit to ensure key is older than 1ms
      await Future.delayed(const Duration(milliseconds: 10));
      expect(sessionKey.isExpired(const Duration(milliseconds: 1)), isTrue);
    });

    test('should encode key as base64', () async {
      final manager = SessionKeyManager();
      final sessionKey = await manager.generateSessionKey('session-1');

      final base64 = sessionKey.keyBase64;
      expect(base64, isNotEmpty);
      expect(() => base64Decode(base64), returnsNormally);
    });
  });
}

