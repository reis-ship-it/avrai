import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/crypto/key_exchange.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  group('KeyExchange', () {
    late KeyExchange keyExchange;

    setUp(() {
      keyExchange = KeyExchange();
    });

    group('generateSharedSecret', () {
      test('should generate a shared secret', () async {
        final secret = await keyExchange.generateSharedSecret();

        expect(secret, isNotEmpty);
        expect(secret.length, greaterThan(0));
      });

      test('should generate different secrets each time', () async {
        final secret1 = await keyExchange.generateSharedSecret();
        final secret2 = await keyExchange.generateSharedSecret();

        expect(secret1, isNot(equals(secret2)));
      });

      test('should generate base64 encoded secret', () async {
        final secret = await keyExchange.generateSharedSecret();

        // Base64 decode should not throw
        expect(() => base64Decode(secret), returnsNormally);
        
        final decoded = base64Decode(secret);
        expect(decoded.length, equals(32)); // 32 bytes
      });
    });

    group('deriveEncryptionKey', () {
      test('should derive encryption key from shared secret', () async {
        final sharedSecret = await keyExchange.generateSharedSecret();
        final key = await keyExchange.deriveEncryptionKey(sharedSecret);

        expect(key, isNotNull);
        expect(key.length, equals(32)); // 32 bytes for AES-256
      });

      test('should derive same key from same secret and context', () async {
        final sharedSecret = await keyExchange.generateSharedSecret();
        final info = Uint8List.fromList('test-context'.codeUnits);

        final key1 = await keyExchange.deriveEncryptionKey(
          sharedSecret,
          info: info,
        );
        final key2 = await keyExchange.deriveEncryptionKey(
          sharedSecret,
          info: info,
        );

        expect(key1, equals(key2));
      });

      test('should derive different keys with different contexts', () async {
        final sharedSecret = await keyExchange.generateSharedSecret();

        final key1 = await keyExchange.deriveEncryptionKey(
          sharedSecret,
          info: Uint8List.fromList('context1'.codeUnits),
        );
        final key2 = await keyExchange.deriveEncryptionKey(
          sharedSecret,
          info: Uint8List.fromList('context2'.codeUnits),
        );

        expect(key1, isNot(equals(key2)));
      });

      test('should derive keys with custom length', () async {
        final sharedSecret = await keyExchange.generateSharedSecret();

        final key16 = await keyExchange.deriveEncryptionKey(
          sharedSecret,
          keyLength: 16,
        );
        final key32 = await keyExchange.deriveEncryptionKey(
          sharedSecret,
          keyLength: 32,
        );

        expect(key16.length, equals(16));
        expect(key32.length, equals(32));
      });
    });

    group('generateEncryptionKey', () {
      test('should generate encryption key', () async {
        final key = await keyExchange.generateEncryptionKey();

        expect(key, isNotNull);
        expect(key.length, equals(32)); // 32 bytes for AES-256
      });

      test('should generate different keys each time', () async {
        final key1 = await keyExchange.generateEncryptionKey();
        final key2 = await keyExchange.generateEncryptionKey();

        expect(key1, isNot(equals(key2)));
      });
    });

    group('deriveMultipleKeys', () {
      test('should derive multiple keys from shared secret', () async {
        final sharedSecret = await keyExchange.generateSharedSecret();
        final contexts = ['encryption', 'authentication', 'signing'];

        final keys = await keyExchange.deriveMultipleKeys(sharedSecret, contexts);

        expect(keys.length, equals(3));
        expect(keys.containsKey('encryption'), isTrue);
        expect(keys.containsKey('authentication'), isTrue);
        expect(keys.containsKey('signing'), isTrue);

        // All keys should be different
        expect(keys['encryption'], isNot(equals(keys['authentication'])));
        expect(keys['authentication'], isNot(equals(keys['signing'])));
        expect(keys['encryption'], isNot(equals(keys['signing'])));
      });

      test('should derive keys with correct length', () async {
        final sharedSecret = await keyExchange.generateSharedSecret();
        final contexts = ['key1', 'key2'];

        final keys = await keyExchange.deriveMultipleKeys(
          sharedSecret,
          contexts,
          keyLength: 16,
        );

        expect(keys['key1']!.length, equals(16));
        expect(keys['key2']!.length, equals(16));
      });
    });
  });
}

