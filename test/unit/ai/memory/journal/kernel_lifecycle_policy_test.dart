import 'package:avrai/core/ai/memory/journal/kernel_lifecycle_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KernelLifecyclePolicy', () {
    KernelLifecyclePolicy buildPolicy() {
      return KernelLifecyclePolicy(
        family: KernelFamily.learning,
        direction: LifecycleDirection.upgrade,
        fromVersion: '1.0.0',
        toVersion: '1.1.0',
        rollbackTtl: const Duration(hours: 2),
        changeWindow: SignedChangeWindow(
          startInclusive: DateTime.utc(2026, 2, 20, 12),
          endExclusive: DateTime.utc(2026, 2, 20, 14),
          signerId: 'kernel-governance-bot',
          signatureRef: 'sig-abc-123',
        ),
        compatibilityMatrix: const [
          KernelCompatibilityRule(
            family: KernelFamily.safety,
            supportedVersions: {'2.0.0', '2.0.1'},
          ),
          KernelCompatibilityRule(
            family: KernelFamily.truth,
            supportedVersions: {'3.1.0'},
          ),
        ],
      );
    }

    test('validates contract and enforces signed change window', () {
      final policy = buildPolicy();

      expect(policy.isValid, isTrue);
      expect(policy.isWithinChangeWindow(DateTime.utc(2026, 2, 20, 11, 59)),
          isFalse);
      expect(policy.isWithinChangeWindow(DateTime.utc(2026, 2, 20, 12, 0)),
          isTrue);
      expect(policy.isWithinChangeWindow(DateTime.utc(2026, 2, 20, 13, 59)),
          isTrue);
      expect(policy.isWithinChangeWindow(DateTime.utc(2026, 2, 20, 14, 0)),
          isFalse);
    });

    test('checks compatibility matrix against runtime kernel versions', () {
      final policy = buildPolicy();

      expect(
        policy.isCompatibilitySatisfied({
          KernelFamily.safety: '2.0.1',
          KernelFamily.truth: '3.1.0',
        }),
        isTrue,
      );

      expect(
        policy.isCompatibilitySatisfied({
          KernelFamily.safety: '2.0.2',
          KernelFamily.truth: '3.1.0',
        }),
        isFalse,
      );
    });

    test('round-trips via JSON', () {
      final policy = buildPolicy();
      final decoded = KernelLifecyclePolicy.fromJson(policy.toJson());

      expect(decoded.family, KernelFamily.learning);
      expect(decoded.direction, LifecycleDirection.upgrade);
      expect(decoded.fromVersion, '1.0.0');
      expect(decoded.toVersion, '1.1.0');
      expect(decoded.rollbackTtl, const Duration(hours: 2));
      expect(decoded.changeWindow.signerId, 'kernel-governance-bot');
      expect(decoded.compatibilityMatrix, hasLength(2));
      expect(decoded.isValid, isTrue);
    });

    test('throws format exception for unknown enum names', () {
      expect(
        () => KernelLifecyclePolicy.fromJson({
          'family': 'not_real',
          'direction': 'upgrade',
          'from_version': '1.0.0',
          'to_version': '1.1.0',
          'rollback_ttl_seconds': 10,
          'change_window': {
            'start_inclusive': DateTime.utc(2026, 2, 20, 12).toIso8601String(),
            'end_exclusive': DateTime.utc(2026, 2, 20, 13).toIso8601String(),
            'signer_id': 'x',
            'signature_ref': 'y',
          },
          'compatibility_matrix': const [],
        }),
        throwsFormatException,
      );
    });
  });
}
