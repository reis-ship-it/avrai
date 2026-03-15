import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';
import 'package:pointycastle/export.dart';

class MeshCustodySealedPayload {
  const MeshCustodySealedPayload({
    required this.encryptedBlob,
    required this.encryptionKeyId,
    required this.algorithm,
    required this.version,
  });

  final String encryptedBlob;
  final String encryptionKeyId;
  final String algorithm;
  final int version;
}

class MeshCustodyOpenedPayload {
  const MeshCustodyOpenedPayload({
    required this.payload,
    required this.payloadContext,
  });

  final Map<String, dynamic> payload;
  final Map<String, dynamic> payloadContext;
}

class MeshCustodyPayloadProtectionService {
  MeshCustodyPayloadProtectionService({
    FlutterSecureStorage? secureStorage,
    String keyAlias = 'mesh_custody_payload_key_v1',
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            ),
        _keyAlias = keyAlias;

  static const String _logName = 'MeshCustodyPayloadProtectionService';
  static const String _algorithm = 'aes256gcm';
  static const int _version = 1;
  static final Map<String, String> _inMemoryKeyStore = <String, String>{};

  final FlutterSecureStorage _secureStorage;
  final String _keyAlias;

  Future<MeshCustodySealedPayload> seal({
    required String entryId,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> payloadContext,
  }) async {
    final key = await _getOrGenerateKey();
    final plaintext = utf8.encode(
      jsonEncode(<String, dynamic>{
        'payload': payload,
        'payload_context': payloadContext,
        'version': _version,
      }),
    );
    final combined = _encryptAes256Gcm(
      plaintext: Uint8List.fromList(plaintext),
      key: key,
      aad: _buildAdditionalData(entryId),
    );
    return MeshCustodySealedPayload(
      encryptedBlob: base64Encode(combined),
      encryptionKeyId: _buildKeyId(key),
      algorithm: _algorithm,
      version: _version,
    );
  }

  Future<MeshCustodyOpenedPayload> open({
    required String entryId,
    required String encryptedBlob,
    required String? encryptionKeyId,
  }) async {
    final key = await _getKey();
    if (key == null) {
      throw StateError(
        'Mesh custody payload key unavailable for entry $entryId',
      );
    }

    final resolvedKeyId = _buildKeyId(key);
    if (encryptionKeyId != null &&
        encryptionKeyId.isNotEmpty &&
        encryptionKeyId != resolvedKeyId) {
      developer.log(
        'Mesh custody key id mismatch for $entryId; attempting decrypt with current key',
        name: _logName,
      );
    }

    final decrypted = _decryptAes256Gcm(
      encrypted: base64Decode(encryptedBlob),
      key: key,
      aad: _buildAdditionalData(entryId),
    );
    final document = jsonDecode(utf8.decode(decrypted));
    return MeshCustodyOpenedPayload(
      payload: Map<String, dynamic>.from(
        document['payload'] as Map? ?? const <String, dynamic>{},
      ),
      payloadContext: Map<String, dynamic>.from(
        document['payload_context'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  Future<Uint8List> _getOrGenerateKey() async {
    final cachedKey = _inMemoryKeyStore[_keyAlias];
    if (cachedKey != null) {
      return base64Decode(cachedKey);
    }

    String? storedKey;
    try {
      storedKey = await _secureStorage.read(key: _keyAlias);
    } catch (_) {
      storedKey = _inMemoryKeyStore[_keyAlias];
    }
    if (storedKey != null && storedKey.isNotEmpty) {
      _inMemoryKeyStore[_keyAlias] = storedKey;
      return base64Decode(storedKey);
    }

    final key = _generateKey();
    final encodedKey = base64Encode(key);
    _inMemoryKeyStore[_keyAlias] = encodedKey;
    try {
      await _secureStorage.write(key: _keyAlias, value: encodedKey);
    } catch (_) {
      // In-memory fallback already holds the key for this process.
    }
    return key;
  }

  Future<Uint8List?> _getKey() async {
    final cachedKey = _inMemoryKeyStore[_keyAlias];
    if (cachedKey != null) {
      return base64Decode(cachedKey);
    }

    try {
      final storedKey = await _secureStorage.read(key: _keyAlias);
      if (storedKey == null || storedKey.isEmpty) {
        return null;
      }
      _inMemoryKeyStore[_keyAlias] = storedKey;
      return base64Decode(storedKey);
    } catch (_) {
      return null;
    }
  }

  Uint8List _generateKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  String _buildKeyId(Uint8List key) {
    final digest = sha256.convert(<int>[...utf8.encode(_keyAlias), ...key]);
    return base64Encode(digest.bytes)
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '')
        .substring(0, 24);
  }

  Uint8List _buildAdditionalData(String entryId) {
    return Uint8List.fromList(
      utf8.encode('mesh_custody:$entryId:v$_version'),
    );
  }

  Uint8List _encryptAes256Gcm({
    required Uint8List plaintext,
    required Uint8List key,
    required Uint8List aad,
  }) {
    final iv = Uint8List(12);
    final rng = Random.secure();
    for (var i = 0; i < iv.length; i++) {
      iv[i] = rng.nextInt(256);
    }

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          128,
          iv,
          aad,
        ),
      );

    final ciphertextWithTag = cipher.process(plaintext);
    final combined = Uint8List(iv.length + ciphertextWithTag.length);
    combined.setRange(0, iv.length, iv);
    combined.setRange(iv.length, combined.length, ciphertextWithTag);
    return combined;
  }

  Uint8List _decryptAes256Gcm({
    required Uint8List encrypted,
    required Uint8List key,
    required Uint8List aad,
  }) {
    if (encrypted.length < 12 + 16) {
      throw StateError('Mesh custody payload blob is too short to decrypt');
    }

    final iv = Uint8List.sublistView(encrypted, 0, 12);
    final ciphertextWithTag = Uint8List.sublistView(encrypted, 12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          128,
          iv,
          aad,
        ),
      );
    return cipher.process(ciphertextWithTag);
  }
}
