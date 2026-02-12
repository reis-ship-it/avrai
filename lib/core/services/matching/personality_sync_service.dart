import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai_core/models/personality_profile.dart';

/// Service for secure cross-device personality profile sync
///
/// **Philosophy Alignment:**
/// - Local-first: Primary storage on-device, cloud is backup
/// - Encrypted: All cloud data encrypted with password-derived keys
/// - User-controlled: Opt-in/opt-out setting
/// - Privacy-preserving: Raw personality data never exposed
///
/// **Security:**
/// - Uses PBKDF2 for key derivation from user password
/// - AES-256-GCM for authenticated encryption
/// - Keys never stored or transmitted
/// - Password only used during login session
class PersonalitySyncService {
  static const String _logName = 'PersonalitySyncService';
  static const AppLogger _logger = AppLogger(
    defaultTag: _logName,
    minimumLevel: LogLevel.debug,
  );

  // PBKDF2 parameters
  static const int _pbkdf2Iterations = 100000; // Recommended for security
  static const int _saltLength = 32; // 32 bytes = 256 bits
  static const int _keyLength = 32; // 32 bytes = 256 bits for AES-256

  final SupabaseService _supabaseService;
  final StorageService _storageService;

  PersonalitySyncService({
    required SupabaseService supabaseService,
    required StorageService storageService,
  })  : _supabaseService = supabaseService,
        _storageService = storageService;

  /// Sync personality profile to cloud (encrypted).
  ///
  /// This method intentionally uses a **positional** signature because multiple
  /// call sites (controllers / legacy code) call `syncToCloud(userId, profile, password)`.
  ///
  /// - `agentId`: Agent/user id (used as the cloud record key)
  /// - `profile`: Personality profile to sync
  /// - `password`: User password for encryption (never stored)
  Future<bool> syncToCloud(
    String agentId,
    PersonalityProfile profile,
    String password,
  ) async {
    try {
      // Cloud sync is opt-in and globally gated.
      // If disabled, do nothing (local-first) and report failure.
      if (!await isCloudSyncEnabled(agentId)) {
        _logger.debug('Cloud sync disabled');
        return false;
      }

      _logger.debug('Starting cloud sync for profile: $agentId');

      // Derive encryption key from password
      final salt = _generateSalt();
      final key = _deriveKey(password, salt);

      // Encrypt profile data
      final encryptedData = await _encryptProfile(profile, key, salt);

      // Store encrypted data in cloud
      final success = await _storeEncryptedData(
        agentId: agentId,
        encryptedData: encryptedData,
      );

      if (success) {
        _logger.debug('Cloud sync successful for profile: $agentId');
      } else {
        _logger.warning('Cloud sync failed for profile: $agentId');
      }

      return success;
    } catch (e, stackTrace) {
      _logger.error(
        'Error during cloud sync: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Sync personality profile from cloud (decrypted)
  ///
  /// [agentId] - Agent ID to sync
  /// [password] - User password for decryption (never stored)
  ///
  /// Returns decrypted profile, or null if sync fails
  Future<PersonalityProfile?> syncFromCloud({
    required String agentId,
    required String password,
  }) async {
    try {
      _logger.debug('Starting cloud sync download for agent: $agentId');

      // Retrieve encrypted data from cloud
      final encryptedData = await _retrieveEncryptedData(agentId: agentId);
      if (encryptedData == null) {
        _logger.debug('No cloud data found for agent: $agentId');
        return null;
      }

      // Extract salt from encrypted data
      final salt = encryptedData['salt'] as Uint8List;
      final encryptedContent = encryptedData['encrypted'] as Uint8List;
      final nonce = encryptedData['nonce'] as Uint8List;

      // Derive decryption key from password
      final key = _deriveKey(password, salt);

      // Decrypt profile data
      final profile = await _decryptProfile(
        encryptedContent: encryptedContent,
        key: key,
        nonce: nonce,
      );

      if (profile != null) {
        _logger.debug('Cloud sync download successful for agent: $agentId');
      } else {
        _logger.warning('Cloud sync download failed for agent: $agentId');
      }

      return profile;
    } catch (e, stackTrace) {
      _logger.error(
        'Error during cloud sync download: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Generate random salt for key derivation
  FortunaRandom _createSeededSecureRandom() {
    // FortunaRandom must be seeded before use; otherwise PointyCastle will throw
    // LateInitializationError for internal AES state.
    final secureRandom = FortunaRandom();
    final seed = Uint8List(32);
    final rng = math.Random.secure();
    for (var i = 0; i < seed.length; i++) {
      seed[i] = rng.nextInt(256);
    }
    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }

  Uint8List _generateSalt() {
    final secureRandom = _createSeededSecureRandom();
    return secureRandom.nextBytes(_saltLength);
  }

  /// Derive encryption key from password using PBKDF2
  Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));

    final passwordBytes = utf8.encode(password);
    return pbkdf2.process(passwordBytes);
  }

  /// Encrypt personality profile
  Future<Map<String, dynamic>> _encryptProfile(
    PersonalityProfile profile,
    Uint8List key,
    Uint8List salt,
  ) async {
    // Serialize profile to JSON
    final profileJson = profile.toJson();
    final profileBytes = utf8.encode(jsonEncode(profileJson));

    // Generate nonce for AES-GCM
    final secureRandom = _createSeededSecureRandom();
    final nonce = secureRandom.nextBytes(12); // 96-bit nonce for GCM

    // Encrypt with AES-256-GCM
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true, // encrypt
        AEADParameters(
          KeyParameter(key),
          128, // mac size
          nonce,
          Uint8List(0), // no additional data
        ),
      );

    final encryptedBytes = cipher.process(profileBytes);

    return {
      'salt': salt,
      'nonce': nonce,
      'encrypted': encryptedBytes,
    };
  }

  /// Decrypt personality profile
  Future<PersonalityProfile?> _decryptProfile({
    required Uint8List encryptedContent,
    required Uint8List key,
    required Uint8List nonce,
  }) async {
    try {
      // Decrypt with AES-256-GCM
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false, // decrypt
          AEADParameters(
            KeyParameter(key),
            128, // mac size
            nonce,
            Uint8List(0), // no additional data
          ),
        );

      final decryptedBytes = cipher.process(encryptedContent);
      final decryptedJson =
          jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>;

      // Deserialize to PersonalityProfile
      return PersonalityProfile.fromJson(decryptedJson);
    } catch (e, stackTrace) {
      _logger.error(
        'Error decrypting profile: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Store encrypted data in cloud
  Future<bool> _storeEncryptedData({
    required String agentId,
    required Map<String, dynamic> encryptedData,
  }) async {
    try {
      // Convert encrypted data to base64 for storage
      final base64Salt = base64Encode(encryptedData['salt'] as Uint8List);
      final base64Nonce = base64Encode(encryptedData['nonce'] as Uint8List);
      final base64Encrypted =
          base64Encode(encryptedData['encrypted'] as Uint8List);

      final dataToStore = {
        'agent_id': agentId,
        'salt': base64Salt,
        'nonce': base64Nonce,
        'encrypted_data': base64Encrypted,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Store in Supabase (using agent_id as key)
      final response = await _supabaseService.client
          .from('personality_sync')
          .upsert(dataToStore);

      return response != null;
    } catch (e, stackTrace) {
      _logger.error(
        'Error storing encrypted data: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Retrieve encrypted data from cloud
  Future<Map<String, dynamic>?> _retrieveEncryptedData({
    required String agentId,
  }) async {
    try {
      // Retrieve from Supabase
      final response = await _supabaseService.client
          .from('personality_sync')
          .select()
          .eq('agent_id', agentId)
          .single();

      if (response.isEmpty) {
        return null;
      }

      // Convert from base64 back to bytes
      final salt = base64Decode(response['salt'] as String);
      final nonce = base64Decode(response['nonce'] as String);
      final encrypted = base64Decode(response['encrypted_data'] as String);

      return {
        'salt': salt,
        'nonce': nonce,
        'encrypted': encrypted,
      };
    } catch (e, stackTrace) {
      _logger.error(
        'Error retrieving encrypted data: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Check if cloud sync is enabled for user
  Future<bool> isCloudSyncEnabled([String? _]) async {
    try {
      final enabled = _storageService.getBool('cloud_sync_enabled');
      return enabled ?? false; // Default to false (opt-in)
    } catch (e) {
      _logger.warning('Error checking cloud sync setting: $e');
      return false;
    }
  }

  /// Legacy API: load/decrypt profile from cloud.
  ///
  /// Many call sites use `loadFromCloud(userId, password)`.
  Future<PersonalityProfile?> loadFromCloud(
    String agentId,
    String password,
  ) async {
    return syncFromCloud(agentId: agentId, password: password);
  }

  /// Legacy API: re-encrypt existing cloud profile with a new password.
  ///
  /// Best-effort:
  /// - If no cloud profile exists, this is a no-op.
  /// - If decryption fails, rethrows to let caller decide whether to block.
  Future<void> reEncryptWithNewPassword(
    String agentId,
    String currentPassword,
    String newPassword,
  ) async {
    final existing = await loadFromCloud(agentId, currentPassword);
    if (existing == null) return;
    await syncToCloud(agentId, existing, newPassword);
  }

  // ------------------------------------------------------------------------
  // Test helpers / legacy helpers
  //
  // Some legacy tests and scripts validate crypto behavior without hitting
  // Supabase. These helpers provide a stable API surface while keeping the
  // production sync flow (salt stored with ciphertext) unchanged.
  // ------------------------------------------------------------------------

  /// Derive a deterministic key from a password + userId (legacy tests).
  ///
  /// Production sync uses a per-record random salt stored with ciphertext, so
  /// callers generally do NOT need to call this. This exists primarily to keep
  /// older tests compiling and to allow deterministic crypto checks.
  Future<Uint8List> deriveKeyFromPassword(
      String password, String userId) async {
    // Create a stable 32-byte salt from userId bytes (repeat/pad as needed).
    final userBytes = utf8.encode(userId);
    final salt = Uint8List(_saltLength);
    for (var i = 0; i < salt.length; i++) {
      salt[i] = userBytes.isEmpty ? i : userBytes[i % userBytes.length];
    }
    return _deriveKey(password, salt);
  }

  /// Encrypt a profile payload for cloud transport (legacy tests).
  ///
  /// Returns a JSON string with base64 fields: `nonce`, `encrypted`.
  Future<String> encryptProfileForCloud(
    PersonalityProfile profile,
    Uint8List key,
  ) async {
    final encrypted = await _encryptProfile(profile, key, Uint8List(0));
    return jsonEncode({
      'nonce': base64Encode(encrypted['nonce'] as Uint8List),
      'encrypted': base64Encode(encrypted['encrypted'] as Uint8List),
    });
  }

  /// Decrypt a profile payload produced by [encryptProfileForCloud] (legacy tests).
  ///
  /// Returns null if decryption fails.
  Future<PersonalityProfile?> decryptProfileFromCloud(
    String payload,
    Uint8List key,
  ) async {
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final nonce = base64Decode(decoded['nonce'] as String);
      final encrypted = base64Decode(decoded['encrypted'] as String);
      return await _decryptProfile(
        encryptedContent: encrypted,
        key: key,
        nonce: nonce,
      );
    } catch (_) {
      return null;
    }
  }

  /// Enable/disable cloud sync
  Future<void> setCloudSyncEnabled(bool enabled) async {
    try {
      await _storageService.setBool('cloud_sync_enabled', enabled);
      _logger.debug('Cloud sync ${enabled ? 'enabled' : 'disabled'}');
    } catch (e, stackTrace) {
      _logger.error(
        'Error setting cloud sync: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
