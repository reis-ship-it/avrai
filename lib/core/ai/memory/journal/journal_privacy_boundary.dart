class JournalStoragePolicy {
  final bool encryptionAtRestEnabled;
  final String keyId;

  const JournalStoragePolicy({
    required this.encryptionAtRestEnabled,
    required this.keyId,
  });

  bool get allowsLocalPlaintext {
    return encryptionAtRestEnabled && keyId.trim().isNotEmpty;
  }
}

class FederatedDpPolicy {
  final double epsilon;
  final int minKAnonymity;
  final bool allowRawJournalText;

  const FederatedDpPolicy({
    required this.epsilon,
    this.minKAnonymity = 10,
    this.allowRawJournalText = false,
  });

  bool get isValid {
    return epsilon > 0 && minKAnonymity >= 2 && !allowRawJournalText;
  }
}

class JournalPrivacyBoundary {
  const JournalPrivacyBoundary({
    required this.storagePolicy,
    required this.dpPolicy,
  });

  final JournalStoragePolicy storagePolicy;
  final FederatedDpPolicy dpPolicy;

  bool canPersistLocalJournals() {
    return storagePolicy.allowsLocalPlaintext;
  }

  Map<String, Object?> toFederatedSafeSummary(
    Map<String, Object?> journalEntry,
  ) {
    if (!dpPolicy.isValid) {
      throw StateError('Invalid DP policy for federated journaling');
    }

    final safe = <String, Object?>{
      'entry_id': journalEntry['entry_id'],
      'event_type': journalEntry['event_type'],
      'source': journalEntry['source'],
      'confidence': _asDouble(journalEntry['confidence']) ?? 0.0,
      'timestamp': journalEntry['timestamp'],
      'dp_epsilon': dpPolicy.epsilon,
      'k_anonymity_min': dpPolicy.minKAnonymity,
      'contains_raw_text': false,
    };

    final metadata = journalEntry['metadata'];
    if (metadata is Map) {
      final stripped = <String, Object?>{};
      for (final entry in metadata.entries) {
        final key = '${entry.key}'.toLowerCase();
        if (key.contains('text') || key.contains('summary')) {
          continue;
        }
        stripped['${entry.key}'] = entry.value as Object?;
      }
      safe['metadata'] = stripped;
    } else {
      safe['metadata'] = const <String, Object?>{};
    }

    return safe;
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
