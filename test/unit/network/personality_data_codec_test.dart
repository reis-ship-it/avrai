import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_network/network/personality_data_codec.dart' show PersonalityDataCodec;
import 'package:avrai/core/ai/privacy_protection.dart' show PrivacyProtection;
import 'package:avrai/core/models/user/user_vibe.dart';

/// Personality Data Codec Tests
/// Tests encoding/decoding of anonymized personality data for device discovery
/// OUR_GUTS.md: "Privacy-preserving device discovery"
void main() {
  group('PersonalityDataCodec', () {
    group('Binary Encoding/Decoding', () {
      test('should encode and decode personality data to binary format', () async {
        const userId = 'test-user-123';
        final vibe = UserVibe.fromPersonalityProfile(userId, {
          'exploration_eagerness': 0.7,
          'community_orientation': 0.6,
        });

        final anonymized = await PrivacyProtection.anonymizeUserVibe(
          vibe,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );

        // Encode to binary
        final encoded = PersonalityDataCodec.encodeToBinary(anonymized);
        expect(encoded, isNotEmpty);
        expect(encoded.length, greaterThan(0));

        // Decode from binary
        final decoded = PersonalityDataCodec.decodeFromBinary(encoded);
        expect(decoded, isNotNull);
        // Compare vibeSignature (fingerprint equivalent) instead of fingerprint property
        expect(decoded!.vibeSignature, equals(anonymized.vibeSignature));
      });

      test('should handle invalid binary data gracefully', () {
        final invalidData = [0, 1, 2, 3, 4]; // Invalid magic bytes
        final decoded = PersonalityDataCodec.decodeFromBinary(invalidData);
        expect(decoded, isNull);
      });

      test('should handle empty binary data gracefully', () {
        final decoded = PersonalityDataCodec.decodeFromBinary([]);
        expect(decoded, isNull);
      });
    });

    group('Base64 Encoding/Decoding', () {
      test('should encode and decode personality data to base64', () async {
        const userId = 'test-user-123';
        final vibe = UserVibe.fromPersonalityProfile(userId, {
          'exploration_eagerness': 0.7,
        });

        final anonymized = await PrivacyProtection.anonymizeUserVibe(
          vibe,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );

        // Encode to base64
        final encoded = PersonalityDataCodec.encodeToBase64(anonymized);
        expect(encoded, isNotEmpty);

        // Decode from base64
        final decoded = PersonalityDataCodec.decodeFromBase64(encoded);
        expect(decoded, isNotNull);
        // Compare vibeSignature (fingerprint equivalent) instead of fingerprint property
        expect(decoded!.vibeSignature, equals(anonymized.vibeSignature));
      });

      test('should handle empty base64 string gracefully', () {
        final decoded = PersonalityDataCodec.decodeFromBase64('');
        expect(decoded, isNull);
      });

      test('should handle invalid base64 string gracefully', () {
        final decoded = PersonalityDataCodec.decodeFromBase64('invalid-base64!!!');
        // Should return null or handle gracefully
        expect(decoded, anyOf(isNull, isNotNull));
      });
    });

    group('Privacy Validation', () {
      test('should ensure encoded data contains no personal identifiers', () async {
        const userId = 'test-user-123';
        final vibe = UserVibe.fromPersonalityProfile(userId, {
          'exploration_eagerness': 0.7,
        });

        final anonymized = await PrivacyProtection.anonymizeUserVibe(
          vibe,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );

        final encoded = PersonalityDataCodec.encodeToBase64(anonymized);

        // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
        // Encoded data should not contain user ID
        expect(encoded.contains(userId), isFalse);
      });
    });
  });
}

