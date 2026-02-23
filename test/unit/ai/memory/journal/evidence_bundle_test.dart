import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/evidence_bundle.dart';

void main() {
  group('EvidenceBundle', () {
    test('round-trips deterministic evidence envelope fields', () {
      final bundle = EvidenceBundle(
        evidenceId: 'ev-1',
        sourceUri: 'https://arxiv.org/abs/2602.17632',
        methodClass: EvidenceMethodClass.externalPaper,
        observedAt: DateTime.utc(2026, 2, 20, 14),
        datasetFingerprint: 'sha256:abc123',
        experimentContractId: 'contract-77',
        adoptionVerdict: EvidenceAdoptionVerdict.pending,
        metadata: const {
          'recency_days': 1,
          'confidence': 0.74,
        },
      );

      final decoded = EvidenceBundle.fromJson(bundle.toJson());

      expect(decoded.evidenceId, 'ev-1');
      expect(decoded.sourceUri, 'https://arxiv.org/abs/2602.17632');
      expect(decoded.methodClass, EvidenceMethodClass.externalPaper);
      expect(decoded.observedAt, DateTime.utc(2026, 2, 20, 14));
      expect(decoded.datasetFingerprint, 'sha256:abc123');
      expect(decoded.experimentContractId, 'contract-77');
      expect(decoded.adoptionVerdict, EvidenceAdoptionVerdict.pending);
      expect(decoded.metadata['recency_days'], 1);
      expect(decoded.isValid, isTrue);
    });

    test('marks bundle invalid when required deterministic fields missing', () {
      final invalid = EvidenceBundle(
        evidenceId: '',
        sourceUri: '',
        methodClass: EvidenceMethodClass.internalTelemetry,
        observedAt: DateTime.utc(2026, 2, 20),
        datasetFingerprint: '',
        experimentContractId: '',
        adoptionVerdict: EvidenceAdoptionVerdict.rejected,
      );

      expect(invalid.isValid, isFalse);
    });
  });
}
