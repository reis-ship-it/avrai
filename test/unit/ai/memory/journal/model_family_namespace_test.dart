import 'package:avrai/core/ai/memory/journal/model_family_namespace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModelFamilyNamespaceTag', () {
    test('builds deterministic memory and telemetry scoped keys', () {
      const tag = ModelFamilyNamespaceTag(
        family: ModelFamily.worldModel,
        locality: ModelLocality.local,
        namespaceVersion: 'v1',
      );

      expect(
        tag.scopedMemoryKey('rollback.signature_index'),
        'worldModel.local.v1.memory.rollback.signature_index',
      );
      expect(
        tag.scopedTelemetryKey('query.success_rate'),
        'worldModel.local.v1.telemetry.query.success_rate',
      );
    });

    test('round-trips via JSON', () {
      const tag = ModelFamilyNamespaceTag(
        family: ModelFamily.realityModel,
        locality: ModelLocality.federated,
        namespaceVersion: 'v2',
      );

      final decoded = ModelFamilyNamespaceTag.fromJson(tag.toJson());

      expect(decoded.family, ModelFamily.realityModel);
      expect(decoded.locality, ModelLocality.federated);
      expect(decoded.namespaceVersion, 'v2');
      expect(decoded, tag);
    });
  });

  group('ModelFamilyNamespaceRegistry', () {
    test('requires namespace registration before scoping keys', () {
      final registry = ModelFamilyNamespaceRegistry();

      expect(
        () => registry.scopedMemoryKey(
          family: ModelFamily.universeModel,
          locality: ModelLocality.global,
          key: 'federated.gradient.hash',
        ),
        throwsStateError,
      );
    });

    test('separates memory/telemetry keys by family and locality', () {
      final registry = ModelFamilyNamespaceRegistry(
        seedTags: const [
          ModelFamilyNamespaceTag(
            family: ModelFamily.worldModel,
            locality: ModelLocality.local,
          ),
          ModelFamilyNamespaceTag(
            family: ModelFamily.worldModel,
            locality: ModelLocality.federated,
          ),
        ],
      );

      final localMemory = registry.scopedMemoryKey(
        family: ModelFamily.worldModel,
        locality: ModelLocality.local,
        key: 'journal.window',
      );
      final federatedMemory = registry.scopedMemoryKey(
        family: ModelFamily.worldModel,
        locality: ModelLocality.federated,
        key: 'journal.window',
      );

      expect(localMemory, isNot(equals(federatedMemory)));
      expect(localMemory, 'worldModel.local.v1.memory.journal.window');
      expect(
        registry.scopedTelemetryKey(
          family: ModelFamily.worldModel,
          locality: ModelLocality.federated,
          key: 'rollback.rate',
        ),
        'worldModel.federated.v1.telemetry.rollback.rate',
      );
    });
  });
}
