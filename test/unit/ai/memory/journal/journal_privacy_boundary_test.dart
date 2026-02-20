import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/journal_privacy_boundary.dart';

void main() {
  group('JournalPrivacyBoundary', () {
    test('allows local plaintext journals only with encryption at rest', () {
      const boundaryAllowed = JournalPrivacyBoundary(
        storagePolicy: JournalStoragePolicy(
          encryptionAtRestEnabled: true,
          keyId: 'device-key-1',
        ),
        dpPolicy: FederatedDpPolicy(epsilon: 1.0),
      );
      const boundaryBlocked = JournalPrivacyBoundary(
        storagePolicy: JournalStoragePolicy(
          encryptionAtRestEnabled: false,
          keyId: '',
        ),
        dpPolicy: FederatedDpPolicy(epsilon: 1.0),
      );

      expect(boundaryAllowed.canPersistLocalJournals(), isTrue);
      expect(boundaryBlocked.canPersistLocalJournals(), isFalse);
    });

    test('produces DP-safe federated summary without raw journal text', () {
      const boundary = JournalPrivacyBoundary(
        storagePolicy: JournalStoragePolicy(
          encryptionAtRestEnabled: true,
          keyId: 'device-key-1',
        ),
        dpPolicy: FederatedDpPolicy(epsilon: 0.7, minKAnonymity: 12),
      );

      final summary = boundary.toFederatedSafeSummary({
        'entry_id': 'hist-1',
        'event_type': 'rollback',
        'source': 'model_lifecycle',
        'confidence': 0.82,
        'timestamp': DateTime.utc(2026, 2, 20).toIso8601String(),
        'summary': 'raw detail should never leave device',
        'metadata': {
          'cohort': 'city_tier_2',
          'failure_signature_id': 'sig-22',
          'free_text_note': 'sensitive',
        },
      });

      expect(summary['contains_raw_text'], isFalse);
      expect(summary['dp_epsilon'], 0.7);
      expect(summary['k_anonymity_min'], 12);
      expect(summary['summary'], isNull);
      final metadata = summary['metadata'] as Map<String, Object?>;
      expect(metadata.containsKey('free_text_note'), isFalse);
      expect(metadata['cohort'], 'city_tier_2');
      expect(metadata['failure_signature_id'], 'sig-22');
    });

    test('rejects invalid DP policy that permits raw text', () {
      const boundary = JournalPrivacyBoundary(
        storagePolicy: JournalStoragePolicy(
          encryptionAtRestEnabled: true,
          keyId: 'device-key-1',
        ),
        dpPolicy: FederatedDpPolicy(
          epsilon: 0.5,
          allowRawJournalText: true,
        ),
      );

      expect(
        () => boundary.toFederatedSafeSummary(const {
          'entry_id': 'a',
          'event_type': 'experiment',
        }),
        throwsStateError,
      );
    });
  });
}
