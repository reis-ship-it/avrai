import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/kernel_registry_contract.dart';

void main() {
  group('KernelRegistryContract', () {
    test('registers and reads signed valid manifest', () {
      final registry = KernelRegistryContract();
      registry.register(
        KernelManifest(
          kernelId: 'safety-kernel',
          kind: KernelKind.safety,
          version: '1.0.0',
          signature: 'sig-abc',
          issuedAt: DateTime.utc(2026, 2, 20, 10),
          validUntil: DateTime.utc(2027, 2, 20, 10),
          policy: const {'precedence': 1},
        ),
      );

      final manifest = registry.read(
        KernelKind.safety,
        now: DateTime.utc(2026, 3, 1),
      );

      expect(manifest.kernelId, 'safety-kernel');
      expect(manifest.policy['precedence'], 1);
    });

    test('rejects unsigned or invalid-window manifests', () {
      final registry = KernelRegistryContract();

      expect(
        () => registry.register(
          KernelManifest(
            kernelId: 'truth-kernel',
            kind: KernelKind.truth,
            version: '1.0.0',
            signature: '',
            issuedAt: DateTime.utc(2026, 2, 20),
            validUntil: DateTime.utc(2027, 2, 20),
          ),
        ),
        throwsArgumentError,
      );

      expect(
        () => registry.register(
          KernelManifest(
            kernelId: 'truth-kernel',
            kind: KernelKind.truth,
            version: '1.0.0',
            signature: 'sig-xyz',
            issuedAt: DateTime.utc(2026, 2, 20),
            validUntil: DateTime.utc(2026, 2, 20),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('snapshot only returns manifests valid at requested time', () {
      final registry = KernelRegistryContract();
      registry.register(
        KernelManifest(
          kernelId: 'purpose-kernel',
          kind: KernelKind.purpose,
          version: '1.0.0',
          signature: 'sig-purpose',
          issuedAt: DateTime.utc(2026, 1, 1),
          validUntil: DateTime.utc(2026, 6, 1),
        ),
      );
      registry.register(
        KernelManifest(
          kernelId: 'resource-kernel',
          kind: KernelKind.resource,
          version: '1.0.0',
          signature: 'sig-resource',
          issuedAt: DateTime.utc(2026, 6, 1),
          validUntil: DateTime.utc(2027, 1, 1),
        ),
      );

      final snapshot = registry.snapshot(now: DateTime.utc(2026, 3, 1));
      expect(snapshot.keys, contains(KernelKind.purpose));
      expect(snapshot.keys, isNot(contains(KernelKind.resource)));
    });
  });
}
