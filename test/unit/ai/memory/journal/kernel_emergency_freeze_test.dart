import 'package:avrai/core/ai/memory/journal/kernel_emergency_freeze.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KernelEmergencyFreeze', () {
    HumanReleasePath releasePath() {
      return HumanReleasePath(
        approverId: 'human-operator-1',
        approverRole: 'safety_officer',
        releaseTicketId: 'rel-123',
        releaseWindowStart: DateTime.utc(2026, 2, 20, 12),
        releaseWindowEnd: DateTime.utc(2026, 2, 20, 14),
      );
    }

    test('validates global freeze with human release path', () {
      final freeze = KernelEmergencyFreeze(
        freezeId: 'freeze-global-1',
        triggerClass: FreezeTriggerClass.safetyViolation,
        freezeScope: FreezeScope.global,
        activatedAt: DateTime.utc(2026, 2, 20, 12, 30),
        requiredHumanReleasePath: releasePath(),
      );

      expect(freeze.isValid, isTrue);
      expect(freeze.requiresManualRelease(), isTrue);
    });

    test('requires kernel id for single-kernel freeze scope', () {
      final invalid = KernelEmergencyFreeze(
        freezeId: 'freeze-single-1',
        triggerClass: FreezeTriggerClass.policyTamperDetected,
        freezeScope: FreezeScope.singleKernel,
        activatedAt: DateTime.utc(2026, 2, 20, 12, 30),
        requiredHumanReleasePath: releasePath(),
      );
      final valid = KernelEmergencyFreeze(
        freezeId: 'freeze-single-2',
        triggerClass: FreezeTriggerClass.policyTamperDetected,
        freezeScope: FreezeScope.singleKernel,
        kernelId: 'kernel-purpose-v2',
        activatedAt: DateTime.utc(2026, 2, 20, 12, 30),
        requiredHumanReleasePath: releasePath(),
      );

      expect(invalid.isValid, isFalse);
      expect(valid.isValid, isTrue);
    });

    test('requires family id for family freeze scope', () {
      final invalid = KernelEmergencyFreeze(
        freezeId: 'freeze-family-1',
        triggerClass: FreezeTriggerClass.modelDriftCritical,
        freezeScope: FreezeScope.family,
        activatedAt: DateTime.utc(2026, 2, 20, 12, 30),
        requiredHumanReleasePath: releasePath(),
      );
      final valid = KernelEmergencyFreeze(
        freezeId: 'freeze-family-2',
        triggerClass: FreezeTriggerClass.modelDriftCritical,
        freezeScope: FreezeScope.family,
        kernelFamily: 'learning',
        activatedAt: DateTime.utc(2026, 2, 20, 12, 30),
        requiredHumanReleasePath: releasePath(),
      );

      expect(invalid.isValid, isFalse);
      expect(valid.isValid, isTrue);
    });

    test('round-trips via JSON', () {
      final freeze = KernelEmergencyFreeze(
        freezeId: 'freeze-global-3',
        triggerClass: FreezeTriggerClass.truthIntegrityFailure,
        freezeScope: FreezeScope.global,
        activatedAt: DateTime.utc(2026, 2, 20, 12, 45),
        requiredHumanReleasePath: releasePath(),
      );

      final decoded = KernelEmergencyFreeze.fromJson(freeze.toJson());

      expect(decoded.freezeId, freeze.freezeId);
      expect(decoded.triggerClass, freeze.triggerClass);
      expect(decoded.freezeScope, freeze.freezeScope);
      expect(decoded.requiredHumanReleasePath.approverRole, 'safety_officer');
      expect(decoded.isValid, isTrue);
    });

    test('throws format exception on unknown enum values', () {
      expect(
        () => KernelEmergencyFreeze.fromJson({
          'freeze_id': 'x',
          'trigger_class': 'unknown_trigger',
          'freeze_scope': 'global',
          'activated_at': DateTime.utc(2026, 2, 20).toIso8601String(),
          'required_human_release_path': {
            'approver_id': 'a',
            'approver_role': 'b',
            'release_ticket_id': 'c',
            'release_window_start': DateTime.utc(2026, 2, 20).toIso8601String(),
            'release_window_end':
                DateTime.utc(2026, 2, 20, 1).toIso8601String(),
          },
        }),
        throwsFormatException,
      );
    });
  });
}
