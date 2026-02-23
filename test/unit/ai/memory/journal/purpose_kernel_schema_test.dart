import 'package:avrai/core/ai/memory/journal/purpose_kernel_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurposeKernelSchema', () {
    test('is valid with explicit required goals and safety/legal bounds', () {
      final schema = PurposeKernelSchema(
        kernelId: 'purpose-kernel',
        version: '1.0.0',
        initialGoals: PurposeKernelSchema.requiredInitialGoals,
        issuedAt: DateTime.utc(2026, 2, 20, 10),
      );

      expect(schema.isValid, isTrue);
    });

    test('is invalid when a required goal is missing', () {
      final schema = PurposeKernelSchema(
        kernelId: 'purpose-kernel',
        version: '1.0.0',
        initialGoals: const [
          PurposeGoal.understandHumanCondition,
          PurposeGoal.testAndProveConvictions,
          PurposeGoal.learnFromMistakesAndFixes,
          PurposeGoal.improveUserAndAgentHappiness,
        ],
        issuedAt: DateTime.utc(2026, 2, 20, 10),
      );

      expect(schema.isValid, isFalse);
    });

    test('is invalid when goals include duplicates', () {
      final schema = PurposeKernelSchema(
        kernelId: 'purpose-kernel',
        version: '1.0.0',
        initialGoals: const [
          PurposeGoal.understandHumanCondition,
          PurposeGoal.testAndProveConvictions,
          PurposeGoal.learnFromMistakesAndFixes,
          PurposeGoal.improveUserAndAgentHappiness,
          PurposeGoal.discoverNewGoalsWithinSafetyBounds,
          PurposeGoal.discoverNewGoalsWithinSafetyBounds,
        ],
        issuedAt: DateTime.utc(2026, 2, 20, 10),
      );

      expect(schema.isValid, isFalse);
    });

    test('round-trips via JSON', () {
      final issuedAt = DateTime.utc(2026, 2, 20, 10, 30);
      final schema = PurposeKernelSchema(
        kernelId: 'purpose-kernel',
        version: '1.0.1',
        initialGoals: PurposeKernelSchema.requiredInitialGoals,
        issuedAt: issuedAt,
        metadata: const {'scope': 'phase1'},
      );

      final decoded = PurposeKernelSchema.fromJson(schema.toJson());

      expect(decoded.kernelId, 'purpose-kernel');
      expect(decoded.version, '1.0.1');
      expect(decoded.initialGoals, PurposeKernelSchema.requiredInitialGoals);
      expect(decoded.issuedAt, issuedAt);
      expect(decoded.metadata['scope'], 'phase1');
      expect(decoded.isValid, isTrue);
    });

    test('fromJson throws on unknown goal name', () {
      expect(
        () => PurposeKernelSchema.fromJson({
          'kernel_id': 'purpose-kernel',
          'version': '1.0.0',
          'initial_goals': const ['not_a_goal'],
          'safety_bounded_goal_discovery': true,
          'legal_bounded_goal_discovery': true,
          'issued_at': DateTime.utc(2026, 2, 20).toIso8601String(),
        }),
        throwsFormatException,
      );
    });
  });
}
