import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_dimensions.dart';

import '../signature_confidence_service.dart';
import '../signature_freshness_tracker.dart';

class BundleSignatureInput {
  final String bundleId;
  final String label;
  final String? cityCode;
  final String? localityCode;
  final List<EntitySignature> components;

  const BundleSignatureInput({
    required this.bundleId,
    required this.label,
    required this.components,
    this.cityCode,
    this.localityCode,
  });
}

class BundleSignatureBuilder {
  final SignatureConfidenceService _confidenceService;
  final SignatureFreshnessTracker _freshnessTracker;

  const BundleSignatureBuilder({
    required SignatureConfidenceService confidenceService,
    required SignatureFreshnessTracker freshnessTracker,
  })  : _confidenceService = confidenceService,
        _freshnessTracker = freshnessTracker;

  EntitySignature? build(BundleSignatureInput input, {DateTime? now}) {
    if (input.components.isEmpty) {
      return null;
    }

    final referenceTime = now ?? DateTime.now();
    final dna = SignatureDimensions.weightedBlend(
      input.components.map((component) => component.dna).toList(),
      weights:
          input.components.map((component) => component.confidence).toList(),
    );
    final pheromones = SignatureDimensions.weightedBlend(
      input.components.map((component) => component.pheromones).toList(),
      weights:
          input.components.map((component) => component.freshness).toList(),
    );

    return EntitySignature(
      signatureId: 'bundle:${input.bundleId}',
      entityId: input.bundleId,
      entityKind: SignatureEntityKind.bundle,
      dna: dna,
      pheromones: pheromones,
      confidence: _confidenceService.blend(
        input.components.map((component) => component.confidence),
      ),
      freshness: _freshnessTracker.blend(
        input.components.map((component) => component.freshness),
      ),
      updatedAt: referenceTime,
      cityCode: input.cityCode,
      localityCode: input.localityCode,
      summary: input.label,
      sourceTrace: <SignatureSourceTrace>[
        const SignatureSourceTrace(
          kind: SignatureSourceKind.bundle,
          label: 'combined linked entities',
          weight: 1.0,
        ),
      ],
      bundleEntityIds: input.components
          .map((component) => component.entityId)
          .toList(growable: false),
    );
  }
}
